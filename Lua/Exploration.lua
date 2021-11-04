GlobalVar("g_MapSectors", {}) -- Deprecated
GlobalVar("g_ExplorationQueue", {}) -- Deprecated
GlobalVar("g_InitialSector", false) -- Deprecated
GlobalVar("g_MapArea", false) -- Deprecated
GlobalVar("g_ExplorationNotificationShown", false)
GlobalVar("DeepSectorsScanned", 0)

DefineClass.Exploration = {
	MapSectors = {},
	ExplorationQueue = {},
	ExplorationNotificationShown = false,
	InitialSector = false,
	MapArea = false,
	DialogType = "",
}

SectorStatusToDisplay = {
	["unexplored"] = T(976, "Unexplored"),
	["scanned"] = T(977, "Scanned"),
	["deep scanned"] = T(978, "Deep Scanned"),
	["deep available"] = T(979, "<em>Scanned, scan again for deep deposits and Anomalies</em>"),
}

DefineClass.RevealedMapSector = {
	__parents = { "Object" },
	
	flags = { gofPermanent = true },
	
	properties = {
		{ id = "status", editor = "text", default = "unexplored", no_edit = true },
		{ id = "sector_x", editor = "number", default = 0, no_edit = true },
		{ id = "sector_y", editor = "number", default = 0, no_edit = true },
	},
}

function RevealedMapSector:GameInit()
	local city = UICity
	if self:GetMapID() ~= city.map_id then
		return
	end
	if self.sector_x > 0 and self.sector_y > 0 and #city.MapSectors > 0 and self.status ~= "unexplored" then
		--printf("loaded map sector %s: %s", city.MapSectors[self.sector_x][self.sector_y].id, self.status)
		local sector = city.MapSectors[self.sector_x][self.sector_y]
		if sector.status == "unexplored" or sector.status == "scanned" and self.status == "deep scanned" then
			sector.revealed_obj = self
			sector:Scan(self.status)
		end
	end
end

local function GoToOverview()
	local dlg = GetInGameInterface()
	if dlg and dlg.mode ~= "overview" then
		dlg:SetMode("overview")
	end
end

local function GoToSector(obj, params)
	local sector = UICity.MapSectors[params.x][params.y]
	ViewObjectMars(sector.area:Center())
end

function UnexploredSectorsExist(city)
	local can_scan
	local fully_scanned = true

	local sectors = city.MapSectors
	if not sectors then return can_scan, false end
	
	for x = 1, const.SectorCount do
		local sectors = sectors[x]
		if not sectors then return can_scan, false end
		
		for y = 1, const.SectorCount do
			local sector = sectors[y]
			if sector:CanBeScanned() then
				can_scan = true
			end
			if sector.status ~= "deep scanned" then
				fully_scanned = false
			end
		end
	end
	return can_scan, fully_scanned
end

local function SetSectorSubsurfaceDepositsVisibleExpiration(sector, expiration)
	local function show_markers(markers)
		if not markers then
			return
		end
		
		for _, marker in ipairs(markers) do
			if IsValid(marker.placed_obj) then
				marker.placed_obj:SetVisibilityExpiration(expiration)
			end
		end
	end
	
	show_markers(sector.markers.subsurface)
	show_markers(sector.markers.deep)
end

local function AddSectorScannedNotification(sector, status, old_status)
	Sleep(10) -- allow newly placed deposits to GameInit properly
	
	local texts = {}
	sector:GatherDiscoveredDepositsTexts(texts, "short", "new")
	
	local results
	if #texts == 0 then
		results = T(980, "No resources")
	else		
		results = table.concat(texts, " ")
	end
	
	DeepSectorsScanned = DeepSectorsScanned + (status == "deep scanned" and 1 or 0)
	
	AddOnScreenNotification("SectorScanned", GoToSector, {name = sector.display_name, results = results, x = sector.col, y = sector.row}, nil, sector.city.map_id)
	Msg("SectorScanned", status, sector.col, sector.row)
	local research_points = GetMissionSponsor().research_points_per_explored_sector or 0
	if research_points > 0 and GameTime() > 100 then
		GrantResearchPoints(research_points)
	end
	local expiration = OnScreenNotificationPresets["SectorScanned"].expiration
	SetSectorSubsurfaceDepositsVisibleExpiration(sector, expiration)
	
	sector.revealed_surf = nil
	sector.revealed_deep = nil
end

DefineClass.MapSector = {
	__parents = { "Object" },
	
	id = false, -- A0 - J9
	display_name = false,
	area = false, -- aabb
	status = "unexplored", -- "unexplored", "scanned", "deep scanned"
	blocked_status = false,
	blocked_scanner = false,
	exp_resources = false, -- list of expected resources, based on terrain features (not an actual list of available resources)	
	markers = false, -- list of markers to spawn deposits when scanned, per category (terrain/surface, subsurface, deep)
	deposits = false, -- actual resources available in placed deposits per category per type
	notify_thread = false,
	
	row = false,
	col = false,
	
	scan_time = 0,
	scan_progress = 0,
	
	decal = false,
	queue_text = false,
	play_ratio = 0,
	revealed_obj = false,
	scan_obj = false,
	
	revealed_surf = false,
	revealed_deep = false,	
}

function MapSector:GetDisplayName()
	return Untranslated(self.display_name)
end

function MapSector:CanBeScanned()
	if self:HasBlockers() then
		return false
	end
	if self.status == "deep scanned" then
		return false
	end
	if self.status == "unexplored" then
		return true
	end
	
	return g_Consts.DeepScanAvailable ~= 0
end


function Exploration:CheckScanAvailability()
	-- scan availability notification
	local can_scan, fully_scanned = UnexploredSectorsExist(self)
	if not can_scan then
		RemoveOnScreenNotification("SectorScanAvailable", self.map_id)
	end
	if fully_scanned then
		GetRealm(self):MapDelete(true, "OrbitalProbe")
	end
	RefreshSectorInfopanel(self.ExplorationQueue[1])
end

local function OnDepositsSpawned()
	if GetInGameInterfaceMode() == "overview" then
		GetInGameInterfaceModeDlg():ScaleSmallObjects(0, "up")
	end
	Msg("DepositsSpawned")
end

function MapSector:HasBlockers()
	for _, marker in ipairs(self.markers.block or empty_table) do
		local deposit = marker.is_placed and marker:PlaceDeposit()
		if deposit and deposit:IsExplorationBlocked() then
			return true
		end
	end
end

function MapSector:HasMarkersOfType(class, list)
	if not list then
		for t, markers in pairs(self.markers) do
			if self:HasMarkersOfType(class, markers) then
				return true
			end
		end
		return false
	end
	for _, marker in ipairs(list) do
		if IsKindOf(marker, class) then
			return true
		end
	end
end
	
function MapSector:Scan(status, scanner)
	if status == "unexplored" or status == self.status then
		return
	end
	self.scan_progress = 0
	
	-- exploration queue
	self:RemoveFromQueue()
	DelayedCall(0, self.city.CheckScanAvailability, self.city)
	
	if RevealDeposits(self.markers.block, self.deposits.block) > 0 then
		Msg("ExplorationBlockerSpawned")
	end
	if self:HasBlockers() then
		self.blocked_status = status
		self.blocked_scanner = scanner
		self:UpdateDecal()
		RefreshSectorInfopanel(self)
		return
	end
	self.blocked_status = nil
	self.blocked_scanner = nil
	
	-- save map compatibility	
	self.revealed_obj = self.revealed_obj or RevealedMapSector:new({sector_x = self.col, sector_y = self.row}, self:GetMapID())
	self.revealed_obj.status = status
	self.revealed_surf = {}
	self.revealed_deep = {}
	
	-- spawn deposits
	local placed = 0
	if self.status == "unexplored" then
		placed = placed + RevealDeposits(self.markers.surface, self.deposits.surface, nil, self.revealed_surf)
		placed = placed + RevealDeposits(self.markers.subsurface, self.deposits.subsurface, nil, self.revealed_deep)
	end
	if status == "deep scanned" then	
		placed = placed + RevealDeposits(self.markers.deep, self.deposits.deep, nil, self.revealed_deep)
	elseif status == "scanned" and scanner == "probe" and GetMissionSponsor().id == "BlueSun" then
		placed = placed + RevealDeposits(self.markers.deep, self.deposits.deep, "PreciousMetals", self.revealed_deep)
	end	
	if placed > 0 then
		DelayedCall(0, OnDepositsSpawned) --@ end of current tick
	end

	-- update status
	local old_status = self.status
	self.status = status

	-- visuals
	self:UpdateDecal()
	
	-- scan notification & results
	if IsExplorationAvailable_Queue(self.city) then
		DeleteThread(self.notify_thread)
		self.notify_thread = CreateGameTimeThread(AddSectorScannedNotification, self, status, old_status)
		RefreshSectorInfopanel(self)
	end
end

function MapSector:GetTowerBoost(city)
	if not IsValid(self) then
		assert(false, "Invalid sector")
		return 0
	end
	local best
	local max_range = const.SensorTowerScanBoostMaxRange
	local min_range = const.SensorTowerScanBoostMinRange
	local boost = 0
	for _, tower in ipairs(city.labels.SensorTower or empty_table) do
		if tower.working then
			boost = boost + 1
			best = IsCloser2D(self, tower, best or max_range) and tower or best
		end
	end
	boost = Min(boost * const.SensorTowerCumulativeScanBoost, const.SensorTowerCumulativeScanBoostMax)
	if best then
		boost = boost + MulDivRound(const.SensorTowerScanBoostMax, 
			Min(max_range - min_range, max_range - self:GetDist2D(best)), 
			max_range - min_range)
	end
	return boost
end

function MapSector:RemoveFromQueue()
	if self.queue_text then
		DoneObject(self.queue_text)
		self.queue_text = nil
	end
	
	local idx = table.find(self.city.ExplorationQueue, self)
	if idx then
		table.remove(self.city.ExplorationQueue, idx)		
		if idx == 1 then
			self:SetScanFx(false)
			if #self.city.ExplorationQueue > 0 and GetInGameInterfaceMode() == "overview" then
				self.city.ExplorationQueue[1]:SetScanFx(true)
			end			
		end
		ShowExploration_Queue(self.city)
	end
end

function MapSector:SetScanFx(enable, initial)
	if enable and not IsValid(self.scan_obj) then
		local map_id = self:GetMapID()
		self.scan_obj = PlaceParticlesIn("SensorTower_Sector_Scan", map_id)
		self.scan_obj:SetPos(self:GetPos())
		if not initial then
			PlayFX({
				actionFXClass = "SectorScan",
				actionFXMoment = "start",
				action_map_id = map_id,
			})
		end
	elseif not enable then
		if IsValid(self.scan_obj) then
			DoneObject(self.scan_obj)
			self.scan_obj = nil
		end
	end		
end

function MapSector:UpdateDecal()
	if IsValid(self.decal) then
		DoneObject(self.decal)
		self.decal = nil		
	end
	if self:HasBlockers() then
		self.decal = PlaceObjectIn("SectorUnexplored", self:GetMapID())
		self.decal:SetColorModifier(red)
	elseif self.status == "unexplored" then
		self.decal = PlaceObjectIn("SectorUnexplored", self:GetMapID())
	elseif self.status == "scanned" and UICity and g_Consts.DeepScanAvailable ~= 0 then
		self.decal = PlaceObjectIn("SectorScanned", self:GetMapID())
	end	

	if IsValid(self.decal) then
		if GetInGameInterfaceMode() ~= "overview" then
			self.decal:ClearEnumFlags(const.efVisible)
		end
		
		self.decal:SetPos(self:GetPos())
		self.decal:SetScale(MulDivRound(self.area:sizex(), 100, 100*guim)+1) -- +1 to compensate rounding error
	end
end

function MapSector:GetDepositList(marker)
	local depth_class = marker:GetDepthClass()
	local list = self.markers[depth_class]
	assert(list, "unexpected deposit marker class")
	return list
end

function MapSector:RegisterDeposit(marker)
	local list = self:GetDepositList(marker)
	if list and not list[marker] then
		list[#list + 1] = marker
		list[marker] = true
	end
end

function MapSector:UnregisterDeposit(marker)
	local list = self:GetDepositList(marker)
	if list and list[marker] then
		table.remove_entry(list, marker)
		list[marker] = nil
	end
end

function GetMapSectorTile(map_id)
	local map_data = ActiveMaps[map_id]
	local border = map_data.PassBorder or 0
	local terrain = GetTerrainByID(map_id)
	local width = terrain:GetMapWidth()
	local height = terrain:GetMapHeight()
	assert(width == height) -- the selection art assumes square shape
	return (width - 2 * border) / 10
end

local function PosToSectorXY(map_id, x, y)
	local map_data = ActiveMaps[map_id]
	local border = map_data.PassBorder or 0
	x, y = x - border, y - border	
	local tile = GetMapSectorTile(map_id)
	return Clamp(1 + x / tile, 1, 10), Clamp(1 + y / tile, 1, 10)
end

function RevealDepositsInRange(realm, position, range)
	local markers = realm:MapGet(position, range, "DepositMarker")
	return RevealDeposits(markers)
end

function RevealDeposits(list, resource_amount, resource, revealed_list)
	local placed = 0
	for i = 1, #(list or "") do
		local marker = list[i]
		if IsValid(marker) and not marker.is_placed and (not resource or marker.resource == resource) then
			local deposit = marker:PlaceDeposit()
			if deposit then
				if resource_amount and deposit.resource then
					resource_amount[deposit.resource] = (resource_amount[deposit.resource] or 0) + deposit.max_amount
				end
				placed = placed + 1
				if revealed_list then
					revealed_list[placed] = marker
				end
				if IsKindOf(deposit, "ExplorableObject") then
					deposit:SetRevealed(true)
				end
			end
		end
	end
	return placed
end

local function InitDepositInfoTable()
	local deposits = {}
	for _, deposit_desc in ipairs(DepositDescription) do
		deposits[deposit_desc.name] = { amount = 0, count = 0 }
		local deposit = deposits[deposit_desc.name]
		deposit[1] = { amount = 0, count = 0 } -- surface
		deposit[2] = { amount = 0, count = 0 } -- subsurface
	end
	return deposits
end

local function ProcessDepositMarkers(markers, deposits, level)
	for i = 1, #markers do
		local marker = markers[i]
		local deposit = marker.placed_obj
		if marker.is_placed and IsValid(deposit) and IsKindOf(deposit, "Deposit") then
			local resource = deposit.resource
			if deposits[resource] then
				local amount = 0
				
				if IsKindOf(deposit, "SurfaceDeposit") then
					amount = deposit:GetAmount()
				elseif IsKindOf(deposit, "SubsurfaceDeposit") and not TerrainDeposits[resource] then
					amount = deposit.amount
				elseif IsKindOf(deposit, "TerrainDeposit") then
					amount = deposit:GetAmount()
				end
				
				if amount > 0 then
					local deposit = deposits[resource]
					deposit.amount = (deposit.amount or 0) + amount
					deposit.count = (deposit.count or 0) + 1

					local deposit_level = deposits[resource][level]
					deposit_level.amount = (deposit_level.amount or 0) + amount
					deposit_level.count = (deposit_level.count or 0) + 1
				end
			end
		end
	end
end

local function FormatResourceTexts(deposits, short, texts)
	local count = #texts
	for _, resource_desc in ipairs(DepositDescription) do
		if not resource_desc.hidden or Platform.developer then
			local res = resource_desc.name
			for i = 1, 2 do
				local deposit = deposits[res][i]
				local amount = deposit.amount
				local count = deposit.count

				local indicate_subsurface = i == 2 and resource_desc.multi_surface
				local resource_icon = indicate_subsurface and res.."Deep" or res
				local display_name = resource_desc.display_name

				if amount and amount > 0 then
					if short then
						texts[#texts + 1] = T{722, "<resource(amount,res)>",
							amount = amount,
							res = resource_icon}
					else
						if count then
							local resource_prefix = indicate_subsurface and T(13612, "Underground ") or ""
							texts[#texts + 1] = T{13613, "<nodes> <resource_prefix><display_name><right><resource(amount,res)>",
								amount = amount,
								res = resource_icon,
								display_name = display_name,
								nodes=count,
								resource_prefix=resource_prefix}
						elseif indicate_subsurface then
							texts[#texts + 1] = T{981, "Underground <display_name><right><resource(amount,res)>",
								amount = amount, 
								res = resource_icon,
								display_name = display_name}
						else
							texts[#texts + 1] = T{982, "<display_name><right><resource(amount,res)>",
								amount = amount,
								res = resource_icon,
								display_name = display_name}
						end
					end
				end
			end
		end
	end
end

function MapSector:GatherDiscoveredDeposits(new_only)
	local deposits = InitDepositInfoTable()
	
	if new_only then
		ProcessDepositMarkers(self.revealed_surf, deposits, 1)
		ProcessDepositMarkers(self.revealed_deep, deposits, 2)
	else	
		ProcessDepositMarkers(self.markers.surface, deposits, 1)
		ProcessDepositMarkers(self.markers.subsurface, deposits, 2)
		ProcessDepositMarkers(self.markers.deep, deposits, 2)
	end
	
	return deposits
end

function MapSector:GatherDiscoveredDepositsTexts(texts, short, new_only)
	if self.status == "unexplored" then
		return
	end

	local deposits = self:GatherDiscoveredDeposits(new_only)
	FormatResourceTexts(deposits, short, texts)
end

function Exploration:GatherDiscoveredDeposits()
	local deposits = InitDepositInfoTable()

	for j = 1, const.SectorCount do
		local row = self.MapSectors[j]
		for i = 1, const.SectorCount do
			local sector = row[i]
			
			ProcessDepositMarkers(sector.markers.surface, deposits, 1)
			ProcessDepositMarkers(sector.markers.subsurface, deposits, 2)
			ProcessDepositMarkers(sector.markers.deep, deposits, 2)
		end
	end

	return deposits
end

function Exploration:GatherDiscoveredDepositsTexts(texts, short)
	local deposits = self:GatherDiscoveredDeposits()
	FormatResourceTexts(deposits, short, texts)
end

function IsExplorationAvailable_Queue(city)
	local map_data = ActiveMaps[city.map_id]
	return map_data.Environment ~= "Asteroid" and map_data.Environment ~= "Underground"
end

function IsExplorationAvailable_Sectors(city)
	local map_data = ActiveMaps[city.map_id]
	return map_data.Environment ~= "Asteroid"
end

function MapSector:QueueForExploration(add_first)
	if g_Tutorial and not g_Tutorial.EnableExploration then
		return
	end
	if not IsExplorationAvailable_Queue(self.city) then return end
	PlayFX({
		actionFXClass = "SectorClick",
		actionFXMoment = "start",
		action_map_id = self:GetMapID(),
	})
	local max = const.ExplorationQueueMaxSize
	local queued = #self.city.ExplorationQueue 
	if self:CanBeScanned() and queued <= max then
		local idx = table.find(self.city.ExplorationQueue, self)
		if idx and idx>1 and add_first then
			self:RemoveFromExplorationQueue(idx)
			self:QueueForExploration(add_first)
		elseif not idx and queued < max then
			if add_first then
				table.insert(self.city.ExplorationQueue,1,self)
			else
				self.city.ExplorationQueue[#self.city.ExplorationQueue + 1] = self
			end	
			ShowExploration_Queue(self.city)
			if #self.city.ExplorationQueue == 1 or add_first then
				if add_first and self.city.ExplorationQueue[2] then
					self.city.ExplorationQueue[2]:SetScanFx(false)
				end
				self:SetScanFx(true)
			end
			HintDisable("HintScanningSectors")
			return true
		else
			return false
		end
	end
	PlayFX({
		actionFXClass = "SectorScanInvalid",
		actionFXMoment = "start",
		action_pos = self.area:Center():SetTerrainZ(),
		action_map_id = self:GetMapID(),
	})
	return false
end

function MapSector:RemoveFromExplorationQueue(idx)
	local idx = idx or table.find(self.city.ExplorationQueue, self)
	if idx then
		PlayFX("SectorCancel", "start")
		table.remove(self.city.ExplorationQueue, idx)
		if self.queue_text then
			DoneObject(self.queue_text)
			self.queue_text = nil
		end
		if idx == 1 then
			self:SetScanFx(false)
			if #self.city.ExplorationQueue > 0 then
				self.city.ExplorationQueue[1]:SetScanFx(true)			
			end
		end
		ShowExploration_Queue(self.city)
		return true
	end
end

function GetMapSector(city, x, y)
	if IsPoint(x) then
		x, y = x:xy()
	elseif IsValid(x) then
		x, y = x:GetVisualPosXYZ()
	elseif not x then
		return
	end
	return GetMapSectorXY(city, x, y)
end

function GetMapSectorXY(city, mx, my)
	local x, y = PosToSectorXY(city.map_id, mx, my)
	local row = x and city.MapSectors and city.MapSectors[x]
	return row and row[y]
end

function ShowExploration_Queue(city, initial)
	if not city then
		return
	end

	if GetInGameInterfaceMode() ~= "overview" then
		return
	end
	
	for i = 1, #city.ExplorationQueue do
		local sector = city.ExplorationQueue[i]
		if i == 1 then
			if sector.queue_text then
				DoneObject(sector.queue_text)
				sector.queue_text = nil
			end
			if initial then
				sector:SetScanFx(true, initial)
			end
		else
			if not sector.queue_text then
				sector.queue_text = PlaceObjectIn("Text", city:GetMapID(), {text_style = "ExplorationSector"})
			end
			sector.queue_text:SetText("" .. (i-1))
			sector.queue_text:SetPos(sector.area:Center())
		end
	end
end

function HideExploration_Queue(city)
	if city then
		for i = 1, #city.ExplorationQueue do
			local sector = city.ExplorationQueue[i]
			if sector.queue_text then
				DoneObject(sector.queue_text)
				sector.queue_text = nil
			end
		end
		if #city.ExplorationQueue > 0 then
			city.ExplorationQueue[1]:SetScanFx(false)
		end
	end
end

function ShowExploration_Sectors(city, time)
	if not city then
		return
	end
	local sectors = city.MapSectors
	if #sectors > 0 then
		for x = 1, const.SectorCount do
			local sectors = sectors[x]
			for y = 1, const.SectorCount do
				local decal = sectors[y].decal
				if IsValid(decal) then
					decal:SetEnumFlags(const.efVisible)
				end
			end
		end
	end
end

function HideExploration_Sectors(city, time)
	if city then
		local sectors = city.MapSectors
		if #sectors > 0 then
			for x = 1, const.SectorCount do
				local sectors = sectors[x]
				for y = 1, const.SectorCount do
					local decal = sectors[y].decal
					if IsValid(decal) then
						decal:ClearEnumFlags(const.efVisible)
					end
				end
			end
		end
	end
end

function OnMsg.PreSwitchMap(map_id, next_map_id)
	local city = Cities[map_id]

	if city then
		if city.DialogType == "overview" then
			if IsExplorationAvailable_Sectors(city) then
				HideExploration_Sectors(city)
			end
			if IsExplorationAvailable_Queue(city) then
				HideExploration_Queue(city)
			end
		end
	end
end

function OnMsg.PostSwitchMap(map_id)
	local next_city = Cities[map_id]
	if next_city then
		local igi_mode = GetInGameInterfaceMode()
		if next_city and igi_mode == "overview" then
			if IsExplorationAvailable_Sectors(next_city) then
				ShowExploration_Sectors(next_city)
			end
			if IsExplorationAvailable_Queue(next_city) then
				ShowExploration_Queue(next_city, true)
			end
		end
	end
end

function UpdateScannedSectorVisuals(status)
	local sectors = MainCity.MapSectors
	if #sectors > 0 then
		for x = 1, const.SectorCount do
			local sectors = sectors[x]
			for y = 1, const.SectorCount do
				local sector = sectors[y]
				if not status or sector.status == status then
					sector:UpdateDecal()
				end
			end
		end
	end
end

function Exploration:ExplorationTick()
	local deep = g_Consts.DeepScanAvailable ~= 0

	if #self.ExplorationQueue > 0 then
		RemoveOnScreenNotification("SectorScanAvailable", self.map_id)
		local sector = self.ExplorationQueue[1]
		
		-- tower boost
		local boost = sector:GetTowerBoost(self)
		
		-- calc scan progress
		local scan_rate = MulDivRound(g_Tutorial and g_Tutorial.SectorScanBase or const.SectorScanBase, 100 + boost, 100)
		local scan_time = sector.scan_time
		local scan_last = MulDivRound(scan_time, scan_rate, const.HourDuration)		
		scan_time = scan_time + const.ScanTick
		sector.scan_time = scan_time
		local scan_now = MulDivRound(scan_time, scan_rate, const.HourDuration)
		
		sector.scan_progress = sector.scan_progress + scan_now - scan_last
		
		local target = deep and const.SectorDeepScanPoints or const.SectorScanPoints
		if IsGameRuleActive("FastScan") then
			target = target / 10
		end
		
		if sector.scan_progress >= target then			
			sector:Scan(deep and "deep scanned" or "scanned")
			g_ExplorationNotificationShown = false
		end
	else
		local unexplored = UnexploredSectorsExist(self)
				
		if unexplored and not g_ExplorationNotificationShown and (not g_Tutorial or g_Tutorial.EnableExplorationWarning) then
			AddOnScreenNotification("SectorScanAvailable", GoToOverview, nil, nil, self.map_id)
			g_ExplorationNotificationShown = true
		end
	end
end

function InitSector(realm, sector, eligible)
	sector.exp_resources = {}
	sector.markers = {
		surface = {},
		subsurface = {},
		deep = {},
		block = {},
	}
	sector.deposits = {
		surface = {},
		subsurface = {},
		deep = {},
		block = {},
	}

	sector:SetPos(sector.area:Center())
	sector:UpdateDecal()

	-- enum & process markers
	local exec = function(marker)
		if IsKindOf(marker, "PrefabFeatureMarker") then -- data to display as expected findings prior to exploration
			local ft = marker.FeatureType
			local feature = rawget(PrefabFeatures, ft) or ""
			for j = 1, #feature do
				local char = feature[j]
				if char.class == "PrefabFeatureChar_Deposit" then
					local resource = char.DepositResource
					if resource and not sector.exp_resources[resource] then
						sector.exp_resources[#sector.exp_resources + 1] = resource
						sector.exp_resources[resource] = true
					end
				elseif char.class == "PrefabFeatureChar_Effect" then
					local deposit_class = char.EffectType
					local classdef = g_Classes[deposit_class]
					if not sector.exp_resources[deposit_class] and classdef.list_as_sector_expected then
						sector.exp_resources[#sector.exp_resources + 1] = deposit_class
						sector.exp_resources[deposit_class] = true
					end
				end
			end
		else -- deposit markers
			sector:RegisterDeposit(marker)
			local list
			if eligible and IsKindOfClasses(marker, "TerrainDepositMarker", "SurfaceDepositMarker") then
				if not eligible[sector] and sector.row > 1 and sector.row < const.SectorCount and sector.col > 1 and sector.col < const.SectorCount then
					eligible[#eligible + 1] = sector
					eligible[sector] = true
				end
			end
		end
	end
	realm:MapForEach(sector.area, "PrefabFeatureMarker", "DepositMarker", exec)
end

function OnMsg.LoadGame()
	MapsForEach(true, 
		"MapSector", 
		function(sector)
			if not sector.area then
				DoneObject(sector)
			else
				sector:SetPos(sector.area:Center())
			end
		end)
end

function InitialReveal(eligible, trand)
	local filtered, best = {}, {}
	local has_metals, has_concrete = {}, {}
	
	local qty_per_sector = {}
		
	for i = 1, #eligible do
		-- calculate the max amounts of surface resources from deposit markers
		local qtys = {}
		local sector = eligible[i]
		for j = 1, #sector.markers.surface do
			local marker = sector.markers.surface[j]
			if DepositResources[marker.resource] then
				local amount
				if IsKindOf(marker, "SurfaceDepositMarker") then
					amount = marker:GetEstimatedAmount()
				else
					amount = marker.max_amount
				end
				qtys[marker.resource] = (qtys[marker.resource] or 0) + amount
			end
		end
		--[[
		local text = "sector " .. sector.id .. ": "
		for k, v in pairs(qtys) do
			text = text .. v .. " " .. k .. " "
		end
		
		print(text)--]]
		if (qtys.Metals or 0) >= 50 then
			if qtys.Concrete then
				best[#best + 1] = sector
			else
				filtered[#filtered + 1] = sector
			end
		end
		if qtys.Metals then
			has_metals[#has_metals + 1] = sector
		end
		if qtys.Concrete then
			has_concrete[#has_concrete + 1] = sector
		end
		qty_per_sector[sector.id] = qtys
	end
	
	local function weight_func(sector)
		return MulDivRound(sector.play_ratio, sector.avg_heat, const.MaxHeat)
	end
	
	if #best > 0 then
		-- start in a single sector featuring both resources
		local sector = trand(best, weight_func)
		return { sector }
	end
		
	local sector
	-- no single sectors matching the selection criteria, fallback to sectors with enough metals
	if #filtered > 0 then
		sector = trand(filtered, weight_func)
	else
		print("no sectors found with enough average expected metals")
		if #has_metals > 0 then
			-- pick the one with most metals, add other sector for concrete later
			table.sort(has_metals, function(a, b) return qty_per_sector[a.id].Metals > qty_per_sector[b.id].Metals end)
			sector = has_metals[1]
		elseif #has_concrete > 0 then
			print("no sectors metals expected at all")
			sector = trand(has_concrete)
			return {sector}
		else
			print("no resources expected at all on the map")
			sector = trand(eligible)
			return {sector}
		end
	end
		
	-- sector selected, but only has metals, pick the nearest one having concrete
	local revealed = { sector }
	if #has_concrete > 0 then
		local pt = sector.area:Center()
		table.sort(has_concrete, function(a, b) return a.area:Dist2D(pt) < b.area:Dist2D(pt) end)			
		revealed[2] = has_concrete[1]
	end
	
	return revealed
end

function Exploration:InitialExplore(realm, eligible_sectors_with_surface_deposits_out)
	SuspendPassEdits("InitialExplore")
	
	local _, trand = self:CreateMapRand("Exploration")
	local revealed = InitialReveal(eligible_sectors_with_surface_deposits_out, trand) or ""
	
	local igi = GetInGameInterface()
	
	for i = 1, #revealed do
		if not self.InitialSector then
			self.InitialSector = revealed[i]
			if igi and igi.mode == "overview" then
				igi.mode_dialog.exit_to = self.InitialSector.area:Center()
			end
		end
		revealed[i]:Scan("scanned")
		print("starting sector selected: " .. revealed[i].id)
	end
	
	if self.InitialSector then
		local deposit, resource
		local profile = GetCommanderProfile().id
		
		if profile == "hydroengineer" then
			deposit, resource = "SubsurfaceDepositWater", "Water"
		elseif profile == "astrogeologist" then
			deposit, resource = "SubsurfaceDepositPreciousMetals", "PreciousMetals"
		end
		
		if deposit and realm:MapCount("map", deposit) == 0 then
			local marker = realm:MapFindNearest(self.InitialSector.area:Center(), "map", "SubsurfaceDepositMarker", function(o)
					return not o.is_placed and o.resource == resource and o.depth_layer <= 1
				end)
			if marker then
				marker.revealed = true
				marker:PlaceDeposit()
				if GetInGameInterfaceMode() == "overview" then
					GetInGameInterfaceModeDlg():ScaleSmallObjects(0, "up")
				end
			end
		end
	end
	
	if #revealed > 0 then			
		if GetInGameInterfaceMode() == "overview" then
			local overview_dialog = GetInGameInterfaceModeDlg()
			local last_revealed = revealed[#revealed]
			overview_dialog:SelectSector(last_revealed, nil, "forced")
		end
	end
	
	ResumePassEdits("InitialExplore")
end

function Exploration:UpdateBuildableRatio(bbox)
	local unbuildable_z = buildUnbuildableZ()
	local buildable_grid = GameMaps[self.map_id].buildable
	
	for j = 1, const.SectorCount do
		local row = self.MapSectors[j]
		for i = 1, const.SectorCount do
			local sector = row[i]
			if not bbox or bbox:Intersect2D(sector.area) ~= const.irOutside then
				sector.play_ratio = BuildableGridRatio(buildable_grid.z_grid, unbuildable_z, 100, sector.area)
			end
		end
	end
end

local function CreateSector(game_map, city, row, col, x, y, tile, orient, unbuildable_z, eligible_sectors)
	local name
	if orient == 0 then
		name = string.char(string.byte("A") + 10 - col) .. (row - 1)
	elseif orient == 90 then
		name = string.char(string.byte("A") + 10 - row) .. (10 - col)
	elseif orient == 180 then
		name = string.char(string.byte("A") + col - 1) .. (10 - row)
	elseif orient == 270 then
		name = string.char(string.byte("A") + row - 1) .. (col - 1)
	end

	local realm = game_map.realm
	local buildable_grid = game_map.buildable
	local heat_grid = game_map.heat_grid

	local bbox = box(x, y, x + tile, y + tile)
	local sector_data = {
		id = name, 
		display_name = name,
		area = bbox,
		play_ratio = BuildableGridRatio(buildable_grid.z_grid, unbuildable_z, 100, bbox),
		avg_heat = heat_grid:GetAverageHeatIn(bbox),
		row = row,
		col = col,
		city = city,
	}
	local sector = MapSector:new(sector_data, game_map.map_id)
	InitSector(realm, sector, eligible_sectors)
	return sector
end

function Exploration:InitSectors(game_map, realm, eligible_sectors_with_surface_deposits_out)
	local map_data = ActiveMaps[self.map_id]
	local border = map_data.PassBorder or 0
	local tile = GetMapSectorTile(self.map_id)

	local orient = map_data.OverviewOrientation
	local unbuildable_z = buildUnbuildableZ()
	
	local buildable_grid = game_map.buildable
	local heat_grid = game_map.heat_grid
	
	self.ExplorationQueue = {}
	self.MapSectors = {}
	for j = 1, const.SectorCount do
		local row = {}
		self.MapSectors[j] = row
		local x = border + (j - 1) * tile
		for i = 1, const.SectorCount do
			local y = border + (i - 1) * tile
			local sector = CreateSector(game_map, self, i, j, x, y, tile, orient, unbuildable_z, eligible_sectors_with_surface_deposits_out)
			row[i] = sector
			self.MapSectors[sector] = true
		end
	end
end

function Exploration:InitMapArea()
	assert(#self.MapSectors > 0)
	self.MapArea = box(
		self.MapSectors[1][1].area:min(),
		self.MapSectors[const.SectorCount][const.SectorCount].area:max())
end

function Exploration:Init()
	local game_map = GameMaps[self.map_id]
	local realm = game_map.realm

	realm:MapForEach("map", "Deposit", DoneObject)

	local eligible_sectors_with_surface_deposits = {}
	self:InitSectors(game_map, realm, eligible_sectors_with_surface_deposits)
	self:InitMapArea()

	if IsExplorationAvailable_Queue(self) then
		if realm:MapCount(true, "RevealedMapSector") == 0 then
			self:InitialExplore(realm, eligible_sectors_with_surface_deposits)
		end
		CreateGameTimeThread(function(self)
			while true do
				self:ExplorationTick()
				Sleep(const.ScanTick)
			end
		end, self)
	end
	
	Msg("MapSectorsReady", self)
end

function OnMsg.TechResearched(tech_id, research)
	local def = TechDef[tech_id]
	local resource, anomaly
	
	if tech_id == "CoreMetals" then
		resource = "Metals"
	elseif tech_id == "CoreWater" then
		resource = "Water"
	elseif tech_id == "CoreRareMetals" then
		resource = "PreciousMetals"
	elseif tech_id == "AlienImprints" then
		anomaly = true
	end
	
	if not resource and not anomaly then return end
	local cities_to_spawn = resource and Cities or { MainCity }
	
	for _, city in ipairs(cities_to_spawn) do
		local map_id = city.map_id
		local game_map = GameMaps[map_id]
		local buildable_grid = game_map.buildable
		local terrain = game_map.terrain
		local num = city:Random(def.param1, def.param2)
		for i = 1, num do
			local marker
			if resource then
				marker = PlaceObjectIn("SubsurfaceDepositMarker", map_id)
				marker.resource = resource
				marker.grade = "Very High"
				marker.max_amount = def.param3 * const.ResourceScale
				marker.depth_layer = 2
			else
				-- anomaly
				marker = PlaceObjectIn("SubsurfaceAnomalyMarker", map_id)
				marker.sequence = "Alien Artifacts"
				marker.sequence_list = "BreakthroughAlienArtifacts"
				marker.tech_action = "aliens"
			end

			-- pick position
			for i = 1, 50 do
				local sector_x = city:Random(1, 10)
				local sector_y = city:Random(1, 10)
				local sector = city.MapSectors[sector_x][sector_y]
				
				--local maxx, maxy = sector.area:
				local minx, miny = sector.area:minxyz()
				local maxx, maxy = sector.area:maxxyz()
				
				local x = city:Random(minx, maxx)
				local y = city:Random(miny, maxy)
				
				local q, r = WorldToHex(x, y)
				local pt = point(x, y)
				if buildable_grid:IsBuildable(q, r) and terrain:IsPassable(pt) then
					marker:SetPos(pt)
					break
				end
			end
			
			if marker:IsValidPos() then
				marker.revealed = true
				marker:PlaceDeposit()
			else
				printf("couldn't find position to place %s deposit", resource)
				DoneObject(marker)
			end
		end
	end
end

function SavegameFixups.UpdateSectorNumberTextStyle()
	for i = 2, #g_ExplorationQueue do
		if g_ExplorationQueue[i].queue_text then
			g_ExplorationQueue[i].queue_text:SetTextStyle("ExplorationSector")
		end
	end
end

function SavegameFixups.MoveExplorationDataToCity(metadata, lua_revision)
	if not AppliedSavegameFixups.UpdateSectorNumberTextStyle then
		AppliedSavegameFixups.UpdateSectorNumberTextStyle = true
		SavegameFixups.UpdateSectorNumberTextStyle(metadata, lua_revision)
	end
	
	local city = UICity
	city.MapSectors = g_MapSectors
	city.ExplorationQueue = g_ExplorationQueue
	city.InitialSector = g_InitialSector
	city.MapArea = g_MapArea
	city.DialogType = "overview"
	
	g_MapSectors = false
	g_ExplorationQueue = false
	g_InitialSector = false
	g_MapArea = false

	for x = 1, const.SectorCount do
		for y = 1, const.SectorCount do
			city.MapSectors[x][y].city = city
		end
	end
end

function SavegameFixups.RestoreInvalidSectors()
	local sectors = MainCity.MapSectors
	if #sectors > 0 then
		local map_id = MainCity.map_id
		local tile = GetMapSectorTile(map_id)
		local map_data = ActiveMaps[map_id]
		local border = map_data.PassBorder or 0
		local orient = map_data.OverviewOrientation
		local game_map = GameMaps[map_id]
		local unbuildable_z = buildUnbuildableZ()

		for i = 1, const.SectorCount do
			local sectors_row = sectors[i]
			for j = 1, const.SectorCount do
				local sector = sectors_row[j]
				if not IsValid(sector) then
					local x = border + (j - 1) * tile
					local y = border + (i - 1) * tile

					local sector = CreateSector(game_map, MainCity, i, j, x, y, tile, orient, unbuildable_z)
					sectors_row[j] = sector
					sectors[sector] = true
				end
			end
		end
		
		for sector, _ in pairs(sectors) do
			if is_table(sector) and not IsValid(sector) then
				sectors[sector] = nil
			end
		end
	end
end
