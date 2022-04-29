--used so pipes find their proper entities
TubeSkins = {
	Default = {
		dlc = false,
		Tube = "Tube",
		TubePillar = "TubePillar",
		TubeHubSlope = "TubePillarSlope",
		TubeHub = "TubeHub",
		TubeHubPlug = "TubeHubPlug",
		TubeJoint = "TubeJoint",
		TubeJointSeam = "TubeJointSeam",
		TubeSwitch = "TubeSwitch",
	},
	
	Chrome = {
		dlc = "dde",
		Tube = "TubeChrome",
		TubePillar = "TubeChromePillar",
		TubeHubSlope = "TubeChromePillarSlope",
		TubeHub = "TubeChromeHub",
		TubeHubPlug = "TubeChromeHubPlug",
		TubeJoint = "TubeChromeJoint",
		TubeJointSeam = "TubeChromeJointSeam",
		TubeSwitch = "TubeChromeSwitch",
	},
}
--[template_name] = {[tube_skin] = "template_param_name", ...}
--used for blds that flip their skin with the grid
BuildingGridSkins = {
	FuelFactory = { Default = "entity", Chrome = "entity2" },
	OxygenTank  = { Default = "entity", Chrome = "entity2" },
	WaterTank   = { Default = "entity", Chrome = "entity2" },
	WindTurbine = { Default = "entity", Chrome = "entity2" },
}

KnownPipeEntities = {} --for shader log
PlugsAndSeams = {} --for destroy attaches
for _, map in pairs(TubeSkins) do
	for part, e in pairs(map) do
		if part ~= "dlc" then
			table.insert(KnownPipeEntities, e)
			if part == "TubeHubPlug" or part == "TubeJointSeam" then
				table.insert(PlugsAndSeams, e)
			end
		end
	end
end

DefineClass.WaterGrid = {
	__parents = { "SupplyGridFragment" },
	supply_resource = "water",
	air_grid = false,
}

DefineClass.AirGridFragment = {
	__parents = { "SupplyGridFragment" },
	supply_resource = "air",
}

-- every water grid fragment has a corresponding air grid with the same elements (because water and air run in the same pipes)
-- adding or removing elements in the water grid does the same in the air grid
function WaterGrid:Init()
	self.air_grid = AirGridFragment:new({ city = self.city }, self.city.map_id)
end

function WaterGrid:Done()
	self.air_grid:delete()
end

function WaterGrid:AddElement(element, update)
	local air_element = element.building.air
	if air_element then
		self.air_grid:AddElement(air_element, update)
	end
	SupplyGridFragment.AddElement(self, element, update)
end

function WaterGrid:RemoveElement(element, update)
	local air_element = element.building.air
	if air_element then
		self.air_grid:RemoveElement(air_element, update)
	end
	SupplyGridFragment.RemoveElement(self, element, update)
end

function WaterGrid.CreateConnection(pt1, pt2, building1, building2)
	assert(building1 and building2)
	--local is_constr = IsKindOf(building1, "ConstructionSite") or IsKindOf(building2, "ConstructionSite")
	local supply_connection_grid = GetSupplyConnectionGrid(building1)
	SupplyGridAddConnection(supply_connection_grid["water"], pt1, pt2)
	local is_pipe1 = building1:IsKindOf("LifeSupportGridElement")
	local is_pipe2 = building2:IsKindOf("LifeSupportGridElement")
	local b1_cs = IsKindOf(building1, "ConstructionSite")
	local b2_cs = IsKindOf(building2, "ConstructionSite")
	
	if is_pipe1 then
		if not is_pipe2 or building1:GetNumberOfConnections() > 2 then --promote only when there is 1 non pipe, or we get pillars everywhere.
			assert(building1:CanMakePillar()) --pipe was erroneously marked as able to connect here!
			building1:MakePillar()
		end
		building1:UpdateVisuals()
	else
		building1:ConnectPipe(pt1, pt2, b2_cs)
	end
	if is_pipe2 then
		if not is_pipe1 or building2:GetNumberOfConnections() > 2 then --1 connection is meaningless.
			assert(building2:CanMakePillar())
			building2:MakePillar()
		end
		building2:UpdateVisuals()
	else
		building2:ConnectPipe(pt2, pt1, b1_cs)
	end
end

local function connection_destroyed(building, pt1, pt2, the_other_building, test)
	if IsBeingDestructed(building) then return end
	
	local DoneFunctor = test and function(bld) table.insert_unique(test, bld) end or DoneObject
	if building:IsKindOf("LifeSupportGridElement") then
		-- pipe
		local b1_cs = IsKindOf(building, "ConstructionSite")
		local b2_cs = IsKindOf(the_other_building, "ConstructionSite")
		local is_any_constr_site = b1_cs or b2_cs
		local are_both_pipes = IsKindOf(the_other_building, "LifeSupportGridElement")
		
		if not building.is_switch and not is_any_constr_site and
			(not building.pillar and are_both_pipes) then
			DoneFunctor(building)
			return
		else
			local c = building:GetNumberOfConnections()
			if c ~= 2 then
				if building:CanMakePillar() then
					if not test then building:MakePillar() end
				else
					DoneFunctor(building)
					return
				end
			end
		end
		
		if not building.is_switch and not is_any_constr_site and band(building.conn, 63) == 0 then
			DoneFunctor(building)
			return
		end
		
		if not test then building:UpdateVisuals() end
	elseif not test then
		building:DisconnectPipe(pt1, pt2)
	end
end

function WaterGrid.DestroyConnection(pt1, pt2, building1, building2, test)
	assert(building1 and building2)
	connection_destroyed(building1, pt1, pt2, building2, test)
	connection_destroyed(building2, pt2, pt1, building1, test)
end

function WaterGrid:GetUISectionWaterGridRollover()
	local ret = 
	{
		T(537, "Life support grid parameters. Water and Oxygen are consumed only when demanded.<newline>"),
		T{330, "Max production<right><water(production)>", self},
		T{331, "Water consumption<right><water(current_consumption)>", current_consumption = self.current_consumption},
	}

	if self.production > self.consumption then
		table.insert(ret, 
		T{543, "Unused production<right><water(number)>", number = function (obj) local el = ResolvePropObj(obj) return el.grid.production - el.grid.consumption end, self})
	elseif self.production < self.consumption then
		table.insert(ret, 
		T{544, "Insufficient production<right><water(number)>", number = function (obj) local el = ResolvePropObj(obj) return el.grid.consumption - el.grid.production end, self})
	end

	return table.concat(ret, "<newline><left>")
end

function AirGridFragment:GetUISectionAirGridRollover()
	local ret = 
	{
		T(537, "Life support grid parameters. Water and Oxygen are consumed only when demanded.<newline>"),
		T{325, "Max production<right><air(production)>", self},
		T{538, "Oxygen consumption<right><air(current_consumption)>", current_consumption = self.current_consumption},
	}

	if self.production > self.consumption then
		table.insert(ret, 
		T{539, "Unused production<right><air(number)>", number = 
			function (obj) 
				local el = ResolvePropObj(obj) 
				local grid = el.grid
				grid = grid:IsKindOf("WaterGrid") and grid.air_grid or grid
				return grid.production - grid.consumption 
			end, self})
	elseif self.production < self.consumption then
		table.insert(ret, 
		T{540, "Insufficient production<right><air(number)>", number = 
			function (obj) 
				local el = ResolvePropObj(obj) 
				local grid = el.grid
				grid = grid:IsKindOf("WaterGrid") and grid.air_grid or grid
				return el.grid.consumption - el.grid.production 
			end, self})
	end

	return table.concat(ret, "<newline><left>")
end


----- LifeSupportGridObject

DefineClass.LifeSupportGridObject = {
	__parents = { "SupplyGridObject" },
	water = false,
	air = false,
	connections = false,
	connections_skin_name = false,
	
	is_tall = true,
}

function LifeSupportGridObject:GameInit()
	self:CreateLifeSupportElements()
	if self.air then
		-- if there is an air element we need to have a dummy water one because the water grid carries the air as well
		self.water = self.water or SupplyGridElement:new{ building = self }
	end
	self:SupplyGridConnectElement(self.water, WaterGrid)
end

function LifeSupportGridObject:DeleteLifeSupport()
	if not self.water then
		return
	end
	self:SupplyGridDisconnectElement(self.water, WaterGrid)
	self.water = false
	self.air = false
end

function LifeSupportGridObject:Done()
	self:DeleteLifeSupport()
end

function LifeSupportGridObject:OnDestroyed()
	self:DeleteLifeSupport()
end

function LifeSupportGridObject:GetUISectionAirGridRollover()
	local grid = self.air and self.air.grid or self.water and self.water.grid and self.water.grid.air_grid
	if grid then
		return grid:GetUISectionAirGridRollover()
	end
end

function LifeSupportGridObject:ShowUISectionLifeSupportGrid()
	local air_grid = self:IsKindOfClasses("AirProducer", "AirStorage") and self.air and self.air.grid
		or self:IsKindOf("LifeSupportGridElement") and self.pillar and self.water and self.water.grid and self.water.grid.air_grid
	local water_grid = self:IsKindOfClasses("WaterProducer", "WaterStorage") and self.water  
		or self:IsKindOf("LifeSupportGridElement") and not IsKindOf(self, "ConstructionSite") and self.pillar and self.water
	return water_grid or air_grid
end

function LifeSupportGridObject:ShowUISectionLifeSupportProduction()
	local air_production = self:IsKindOf("AirProducer")
	local water_production = self:IsKindOf("WaterProducer") 
	return water_production or air_production
end

-- override this function to create water/air elements - it is called before ancestors' GameInit
function LifeSupportGridObject:CreateLifeSupportElements()
end

function LifeSupportGridObject:MoveInside(dome)
	Building.MoveInside(self, dome)
	
	local grid = self.water.grid
	grid:RemoveElement(self.water)

	local game_map = GetGameMap(self)
	local supply_connection_grid = game_map.supply_connection_grid
	local supply_overlay_grid = game_map.supply_overlay_grid

	local ls_connection_grid = supply_connection_grid["water"]
	local shape = self:GetSupplyGridConnectionShapePoints("water")
	ApplyIDToOverlayGrid(supply_overlay_grid, self, shape, 15, "band")
	local connections = SupplyGridRemoveBuilding(ls_connection_grid, self, shape)
	local object_hex_grid = GetObjectHexGrid(self)
	-- destroy connections
	for i = 1, #(connections or ""), 2 do
		local pt, other_pt = connections[i], connections[i + 1]
		local adjacents = object_hex_grid:GetObjectsAtPos(other_pt, nil, nil, function(o)
			return GetGrid(o) == grid
		end)
		for i = 1, #adjacents do
			WaterGrid.DestroyConnection(pt, other_pt, dome, adjacents[i])
		end
	end
	
	if #grid.elements <= 0 then
		grid:delete()
	end
	assert(IsKindOf(dome, "Dome"))
	self.water.parent_dome = dome
	dome:AddToLabel("SupplyGridBuildings", self)
	local my_ls_grid = dome.water.grid
	my_ls_grid:AddElement(self.water)
end

function LifeSupportGridObject:GetPipeConnLookup()
	local ret = {}
	for _, t in pairs(self.connections or empty_table) do
		for __, o in ipairs(t) do
			ret[o] = true
		end
	end
	
	return ret
end

function LifeSupportGridObject:PlacePipeConnection(pipe, i)
	local cm1, cm2, cm3, cm4 = GetPipesPalette()
	self.connections = self.connections or {}

	local map_id = self:GetMapID()
	local obj = PlaceObjectIn(pipe[4], map_id)
	self:Attach(obj, pipe[3])
	SetObjectPaletteRecursive(obj, cm1, cm2, cm3, cm4)
	self.connections[i] = {obj}
	
	if pipe[5] then
		--decor spot defined
		local dec_data = pipe[5]
		local dec_obj = PlaceObjectIn(dec_data[1], map_id)
		
		local idx = 2
		local dec_s_e = dec_data[idx]
		local my_attach = self
		while dec_data[idx] do
			local d = dec_data[idx]
			idx = idx + 1
			if not dec_data[idx] then
				my_attach:Attach(dec_obj, d[1])
			else
				local att = my_attach:GetAttaches()
				for j = 1, #att do
					if att[j]:GetAttachSpot() == d[1] then
						my_attach = att[j]
						break
					end
				end
			end
		end
		
		dec_obj:SetAttachAngle(obj:GetAttachAngle())
		SetObjectPaletteRecursive(dec_obj, cm1, cm2, cm3, cm4)
		table.insert(self.connections[i], dec_obj)
	end
end

function LifeSupportGridObject:ConnectPipe(src_pt, pt)
	local self_dir = HexAngleToDirection(self)
	local q, r = WorldToHex(self)
	local src = point(HexRotate(src_pt:x() - q, src_pt:y() - r, - self_dir)) -- remove the object rotation
	local dir = (6 + HexGetDirection(src_pt, pt) - self_dir) % 6

	for i, pipe in ipairs(self:GetPipeConnections()) do
		if pipe[1] == src and pipe[2] == dir then
			self.connections = self.connections or {}
			if self.connections[i] and self.connections[i][1] then
				break
			end
			
			self:PlacePipeConnection(pipe, i)
			break
		end
	end
	
	self.connections_skin_name = self:GetGridSkinName()
end

function LifeSupportGridObject:DisconnectPipe(src_pt, pt)
	local self_dir = HexAngleToDirection(self)
	local q, r = WorldToHex(self)
	local src = point(HexRotate(src_pt:x() - q, src_pt:y() - r, 6 - self_dir)) -- remove the object rotation
	local dir = (6 + HexGetDirection(src_pt, pt) - self_dir) % 6
	
	for i, pipe in ipairs(self:GetPipeConnections()) do
		if pipe[1] == src and pipe[2] == dir then
			for j = #(self.connections[i] or ""), 1, -1 do
				DoneObject(self.connections[i][j])
				self.connections[i][j] = nil
			end
			self.connections[i] = nil
			break
		end
	end
end

function LifeSupportGridObject:HasPipes()
	local has_pipes = false
	if self.connections and next(self.connections) then
		has_pipes = true
	end
	return has_pipes
end

function LifeSupportGridObject:RecreatePipeConnections()
	local conns = self.connections or empty_table
	local pcs = self:GetPipeConnections()
	
	for i, t in pairs(conns) do
		for j = #t, 1, -1 do
			t[j]:Detach()
			DoneObject(t[j])
			t[j] = nil
		end
		assert(pcs[i], "Skin " .. self:GetGridSkinName() .. " does not have all pipe connections defined for building " .. self.template_name .. "!")
		if pcs[i] then
			self:PlacePipeConnection(pcs[i], i)
		end
	end
	
	if self:HasMember("DeduceAndReapplyDustVisualsFromState") then
		self:DeduceAndReapplyDustVisualsFromState()
	end
end

function LifeSupportGridObject:UpdateVisuals(supply_resource, change_building_ents)
	local t_n = self.template_name or self.class
	local data = BuildingGridSkins[t_n]
	local gsn = self:GetGridSkinName()
	if change_building_ents then
		if data then
			local member_name = data[gsn]
			if member_name then
				local e = self:GetEntity()
				local template = BuildingTemplates[t_n] or g_Classes[t_n]
				local new_skin = template[member_name] or ""
				
				if new_skin ~= "" then
					if e ~= new_skin then
						self:ChangeSkin(new_skin)
					end
				end
			end
		end
	end
	
	if self.connections_skin_name ~= gsn then
		self:RecreatePipeConnections()
		self.connections_skin_name = gsn
	end
end

function LifeSupportGridObject:GetGridSkinName()
	return self.water and self.water.grid and self.water.grid.element_skin or "Default"
end

function LifeSupportGridObject:GetEntityNameForPipeConnections(grid_skin_name)
	--default skin, all is well
	if not grid_skin_name then
		return self.entity
	end
	
	local t_n = self.template_name or self.class
	local data = BuildingGridSkins[t_n]
	local template = BuildingTemplates[t_n] or g_Classes[t_n]
	--we have special entity for this skin so we are already cached in a diff key
	if data and data[grid_skin_name] then 
		return template[data[grid_skin_name]]
	end
	
	--we use our regular entity for this grid skin but we needed it cached elsewhere (it has diff data)
	return grid_skin_name ~= "Default" and self.entity .. grid_skin_name or self.entity
end
----- LifeSupportGridElement
function SavegameFixups.ApplyTemporalConstructionBlockToAllPipes()
	MapForEach("map", "LifeSupportGridElement", LifeSupportGridElement.SetGameFlags, const.gofTemporalConstructionBlock)
end

DefineClass.LifeSupportGridElement = {
	__parents = { "LifeSupportGridObject", "TransportGridObject", "Shapeshifter", "Constructable", "DustGridElement", "SupplyGridSwitch", "BreakableSupplyGridElement", "SkinChangeable" },
	flags = { efApplyToGrids = false, gofPermanent = true, gofTemporalConstructionBlock = true },
	is_tall = true,
	properties = {
		{name = "Pillar", id = "pillar", editor = "number"},
		{name = "Connections", id = "conn", editor = "number"},
	},
	pillar = false,
	last_visual_pillar = false, --cached pillar val on last updatevisuals, so we can early exit the func and not cause flickering with large grids under construction
	chain = false,
	conn = -1,
	force_hub = false,
	--construction
	construction_cost_Metals = 1 * const.ResourceScale,
	build_points = 1000,
	--construction ui
	description = T(3972, "Transport Water and Oxygen."),
	display_name = T(1064, "Life Support Pipe"),
	display_name_pl = T(11674, "Life Support Pipes"),
	display_icon = "UI/Icons/Buildings/pipes.tga", --pin dialog icon during construction
	
	construction_connections = -1,
	
	supply_element = "water",
	
	--switch visuals
	on_state = "idle",
	off_state = "off",
	switch_anim = "switch",
	
	--
	connections_skin_name = false,
	--
	skin_before_switch = false, --switch specific, here for inheritence reasons
	construction_grid_skin = false,
	rename_allowed = false,
}

function LifeSupportGridElement:GetGridSkinName()
	return self.water and self.water.grid and self.water.grid.element_skin or self.skin_before_switch or "Default"
end

function LifeSupportGridElement:GetSkinFromGrid(str)
	return TubeSkins[str or self:GetGridSkinName()]
end

function LifeSupportGridElement:GetSkins()
	local skins, palettes = {}, {}
	local palette = {GetPipesPalette()}
	for k, v in pairs(TubeSkins) do
		if IsDlcAccessible(v.dlc) then
			table.insert(skins, k)
			table.insert(palettes, palette)
		end
	end
	
	return skins, palettes
end

function LifeSupportGridElement:GetNextSkinIdx(skins)
	local sn = self:GetGridSkinName()
	local skin_idx = (table.find(skins, sn) or 0) + 1
	if skin_idx > #skins then
		skin_idx = 1
	end
	return skin_idx
end

function LifeSupportGridElement:ChangeSkin(skin_name)
	local g = self.water and self.water.grid
	if g then
		g:ChangeElementSkin(skin_name, true)
	end
end

function LifeSupportGridElement:GameInit()
	if self.entity == false then
		self:UpdateVisuals()
	end
	self:SetPillar(self.pillar)
end

function LifeSupportGridElement:CreateLifeSupportElements()
	self.water = SupplyGridElement:new{ building = self, is_cable_or_pipe = true }
end

function LifeSupportGridElement:GetInfopanelTemplate()
	if self:IsKindOf("ConstructionSite") then return "ipBuilding" end
	if self.is_switch then return "ipSwitch" end
	if self.auto_connect then return "ipLeak" end
	if self.pillar then return "ipPillaredPipe" end
end

function LifeSupportGridElement:GetDisplayName()
	if self.repair_resource_request then
		return T(3891, "Pipe Leak")
	else
		return SupplyGridSwitch.GetDisplayName(self)
	end
end

local full_connections = { 63 * 256 + 128 }
local full_connections_switched = { 63 * 256 + 128 + 16384}
local pipe_connections = { (1 + 8) * 256 + 128 }
local pipe_connections_switched = { (1 + 8) * 256 + 128 + 16384}
local no_connector_versions = {
	[full_connections] = { 63 * 256 },
	[full_connections_switched] = { 63 * 256 + 16384 },
	[pipe_connections] = { (1 + 8) * 256 },
	[pipe_connections_switched] = { (1 + 8) * 256 + 16384 },
}

function LifeSupportGridElement:GetShapeConnections()
	local q, r = WorldToHex(self)
	local object_hex_grid = GetObjectHexGrid(self)
	local bld = HexGetBuilding(object_hex_grid, q, r)
	local result = (bld == nil or bld == self) and not self.chain and (self.switched_state and full_connections_switched or full_connections) 
						or (self.switched_state and pipe_connections_switched or pipe_connections)

	local buildable = GetBuildableGrid(self)
	local is_buildable = buildable:IsBuildable(q, r)
	if not is_buildable and not self.chain then
		result = no_connector_versions[result]
	end
	
	return result
end

function LifeSupportGridElement:MakePipe(dir, dont_demote, skin)
	if self.pillar then
		self:SetPillar(nil)
		self.conn = nil
	end
	self:DestroyAttaches(PlugsAndSeams)
	skin = skin or self:GetSkinFromGrid()
	self:ChangeEntity(skin.Tube)
	self:SetAngle(dir * 60 * 60)
	
	--deselect
	if SelectedObj == self then
		SelectObj()
	end
	if self:IsPinned() then
		self:TogglePin()
	end
	
	if not dont_demote and self.water and self.water.grid then -- we're already connected
		self:DemoteConnectionMask(dir)
	end
end
--makes connection mask represent 2 side possible connection
function LifeSupportGridElement:DemoteConnectionMask(dir)
	if self.pillar then return end --cant demote pillars
	dir = dir or self:GetAngle() / (60 * 60)
	local supply_connection_grid = GetSupplyConnectionGrid(self)
	local conn = HexGridGet(supply_connection_grid["water"], self)
	if conn == 0 then return end --we aint initialized yet, we'll figure out our potential later.
	local pipe_conn = bor(shift(1, dir), dir < 3 and shift(1, dir + 3) or shift(1, dir - 3))
	--63, skip 7th bit (is constr bit), skip 8th bit (ConnectorMask)
	assert(band(conn, bnot(pipe_conn), 63) == 0, "Potential connection terminated, while real connection exists!") -- make sure we're not removing actual connections
	conn = maskset(conn, 63 * 256, shift(pipe_conn, 8)) -- replace pipe potential connections
	HexGridSet(supply_connection_grid["water"], self, conn)
end
--makes connection mask represent 6 side possible connection
function LifeSupportGridElement:PromoteConnectionMask()
	local supply_connection_grid = GetSupplyConnectionGrid(self)
	local conn = HexGridGet(supply_connection_grid["water"], self)
	if conn == 0 then return end --we aint initialized yet, we'll figure out our potential later.
	conn = bor(conn, 63 * 256) -- mark all directions as potential connections
	HexGridSet(supply_connection_grid["water"], self, conn)
end

function LifeSupportGridElement:CanMakePillar(excluded_obj)
	if self.chain then return false end
	local q, r = WorldToHex(self)
	local object_hex_grid = GetObjectHexGrid(self)
	local bld = HexGetBuilding(object_hex_grid, q, r)
	local buildable = GetBuildableGrid(self)
	local is_buildable = buildable:IsBuildable(q, r)
	return self.pillar or self.force_hub or (is_buildable and (bld == nil or excluded_obj and bld == excluded_obj))
end

function LifeSupportGridElement:MakePillar(pipe_counter, excluded_obj)
	assert(self:CanMakePillar(excluded_obj), "Pipe pillar is about to corrupt the connection grids!")
	if not self.pillar then
		local grid = self.water and self.water.grid
		if grid then -- we're already connected
			self:PromoteConnectionMask()
			
			grid.update_visuals = true
			grid:UpdateGrid() --TODO: when is this pointless?
		end
	end
	local pillar = self.pillar == max_int and self.pillar or pipe_counter or self.pillar or true
	self:SetPillar(pillar)
end

function LifeSupportGridElement:SetPillar(pillar)
	self.pillar = pillar or nil
	local flight_system = GetFlightSystem(self)
	if pillar then
		flight_system:Mark(self)
	else
		flight_system:Unmark(self)
	end
end

function LifeSupportGridElement:MakeSwitch(constr_site)
	self:MakePillar(0, constr_site) --pipe counter is number so we cannot demote, ever, (although that cased is shielded)
	SupplyGridSwitch.MakeSwitch(self, constr_site)
end

function LifeSupportGridElement:GetNumberOfConnections()
	local supply_connection_grid = GetSupplyConnectionGrid(self)
	local conn = HexGridGet(supply_connection_grid["water"], self)
	
	local count, first, second = 0
	for dir = 0, 5 do
		if testbit(conn, dir) then
			second = second or first and dir
			first = first or dir
			count = count + 1
		end
	end
	
	return count, first, second
end

GlobalVar("QueuedEnableBlockPasObjects", {})

local function ProcessQueuedBlockPassObjects()
	SuspendPassEdits("QueuedBlockPassObjects")
	for i = 1, #QueuedEnableBlockPasObjects do
		if IsValid(QueuedEnableBlockPasObjects[i]) then --cascade deletion can cause this
			QueuedEnableBlockPasObjects[i]:SetEnumFlags(const.efApplyToGrids)
		end
	end
	QueuedEnableBlockPasObjects = {}
	ResumePassEdits("QueuedBlockPassObjects")
end

function QueueForEnableBlockPass(obj)
	table.insert(QueuedEnableBlockPasObjects, obj)
	DelayedCall(0, ProcessQueuedBlockPassObjects)
end

function LifeSupportGridElement:CanMakeSwitch(constr_site)
	local buildable = GetBuildableGrid(self)
	return SupplyGridSwitch.CanMakeSwitch(self) and self:CanMakePillar(constr_site) and buildable:IsBuildableZone(self)
end

function LifeSupportGridElement:UpdateVisuals(supply_resource)
	local supply_connection_grid = GetSupplyConnectionGrid(self)
	local conn = HexGridGet(supply_connection_grid["water"], self)
	local sn = self:GetGridSkinName()
	if self.conn == conn and self.pillar == self.last_visual_pillar and sn == self.connections_skin_name then return false end
	self.conn = conn
	self.last_visual_pillar = self.pillar
	self.connections_skin_name = sn
	local skin = self:GetSkinFromGrid(sn)
	
	if not self.is_switch and not self.pillar and not self.force_hub then
		if self:GetEntity() ~= skin.Tube then --happens when loading gofPermanent tubes.
			self:ChangeEntity(skin.Tube)
		end
		if self.chain then
			self:SetPos(self:GetPos():SetZ(self.chain.base))
			self:SetChainParams(self.chain.delta, self.chain.index, self.chain.length)
		end
		
		local cm1, cm2, cm3, cm4 = GetPipesPalette()
		SetObjectPaletteRecursive(self, cm1, cm2, cm3, cm4)
		return false
	end
	
	local count, first, second = self:GetNumberOfConnections()
	self:DestroyAttaches(PlugsAndSeams)
	local is_ubuildable_chunk_pillar = type(self.pillar) == "number" and self.pillar == max_int
	if not self.force_hub and not is_ubuildable_chunk_pillar and not self.is_switch and count == 2 and (second - first) == 3 then -- tube pillar
		if type(self.pillar) == "number" then --should be pillar no matter what
			self:ChangeEntity(skin.TubePillar)
			self:SetAngle(first * 60 * 60)
		else
			--revert to regular pipe, keep full conn mask so others may attach to us in the future.
			self:MakePipe(first, true)
			self.conn = conn
		end
	else
		local e = self.is_switch and skin.TubeSwitch or IsBuildableZone(self) and skin.TubeHub or skin.TubeHubSlope
		self:ChangeEntity(e)
		if self:GetAngle() ~= 0 then
			self:SetAngle(0)
		end
		
		local my_q, my_r = WorldToHex(self)
		local object_hex_grid = GetObjectHexGrid(self)
		for dir = 0, 5 do
			if testbit(conn, dir) then
				local dq, dr = HexNeighbours[dir + 1]:xy()
				local pipe = HexGetPipe(object_hex_grid, my_q + dq, my_r + dr)
				local plug = PlaceObjectIn(pipe and pipe.chain and pipe.chain.delta ~= 0 and skin.TubeJointSeam or skin.TubeHubPlug, self:GetMapID(), nil, const.cofComponentAttach)
				if self:GetGameFlags(const.gofUnderConstruction) ~= 0 then
					plug:SetGameFlags(const.gofUnderConstruction)
				end
				plug:SetEnumFlags(const.efSelectable)
				self:Attach(plug)
				plug:SetAttachAngle(180 * 60 + dir * 60 * 60)
				
				if pipe and pipe.chain and pipe.chain.delta ~= 0 then
					local tube_joint = PlaceObjectIn(skin.TubeJoint, self:GetMapID(), nil, const.cofComponentAttach)
					plug:Attach(tube_joint, plug:GetSpotBeginIndex("Joint"))
					tube_joint:SetAttachAxis(axis_y)
					local dist = const.GridSpacing * pipe.chain.length
					local angle = acos(MulDivRound(4096, dist, sqrt(pipe.chain.delta ^ 2 + dist ^ 2)))

					if (pipe.chain.delta < 0) == (dir >= 3) then
						tube_joint:SetAttachAngle(angle)
					else
						tube_joint:SetAttachAngle(-angle)
					end
					
					if plug:GetGameFlags(const.gofUnderConstruction) ~= 0 then
						tube_joint:SetGameFlags(const.gofUnderConstruction)
					end
					tube_joint:SetEnumFlags(const.efSelectable)
				end
			end
		end
	end
	
	--during init we are always a pillar due to being alone, so skip block pass first time around.
	if self.pillar and self:GetEnumFlags(const.efApplyToGrids) == 0 then
		QueueForEnableBlockPass(self)
	end
	
	local cm1, cm2, cm3, cm4 = GetPipesPalette()
	SetObjectPaletteRecursive(self, cm1, cm2, cm3, cm4)
	self:AddDust(0) --refresh dust visuals

	return true
end
--mostly copy paste from ElectricityGridElement
function LifeSupportGridElement:TryConnectInDir(dir)
	local conn = self.conn
	if not testbit(conn, dir) and testbit(shift(conn, -8), dir) then --not connected yet and has potential
		local dq, dr = HexNeighbours[dir + 1]:xy()
		local my_q, my_r = WorldToHex(self)

		local game_map = GetGameMap(self)
		local object_hex_grid = game_map.object_hex_grid

		local obj = HexGetPipe(object_hex_grid, my_q + dq, my_r + dr)
		if obj and obj.water then
			local supply_connection_grid = game_map.supply_connection_grid
			local his_conn = HexGridGet(supply_connection_grid["water"], obj)
			if testbit(shift(his_conn, -8), dir) then --he has ptoential
				WaterGrid.CreateConnection(point(my_q, my_r), point(my_q + dq, my_r + dr), self, obj)
					
				if self.class == obj.class and self.water.grid ~= obj.water.grid then --both constr or both finished but diff grids, merge
					local my_grid_count = #self.water.grid.elements
					local his_grid_count = #obj.water.grid.elements
					local my_grid_has_more_elements = my_grid_count > his_grid_count
					local supply_overlay_grid = game_map.supply_overlay_grid
					MergeGrids(supply_overlay_grid, supply_connection_grid, my_grid_has_more_elements and self.water.grid or obj.water.grid,
									my_grid_has_more_elements and obj.water.grid or self.water.grid)
				elseif self.class ~= obj.class then --constr grid vs real grid, acknowledge conn
					ConnectGrids(self.water, obj.water)
				end
			end
		end
	end
end

function LifeSupportGridElement:GetFlattenShape()
	return FallbackOutline
end

function LifeSupportGridElement:CanBreak()
	if UIColony:IsTechResearched("SuperiorPipes") then
		return false
	end
	return BreakableSupplyGridElement.CanBreak(self)
end

const.SupplyGridElementsAllowUnbuildableChunksPipes = true

function PlacePipeLine(city, start_q, start_r, dir, steps, test, elements_require_construction, input_constr_grp, input_data, skin_name, supplied)
	local pillar_spacing = g_Consts.PipesPillarSpacing
	local last_pillar = 0
	local dq, dr = HexNeighbours[dir + 1]:xy()
	local z = const.InvalidZ
	local connect_dir = dir < 3 and dir or dir - 3
	local angle = connect_dir * 60 * 60
	local game_map = GetGameMap(city)
	local object_hex_grid = game_map.object_hex_grid
	-- try to connect with previous pipe strip
	local pipe = HexGetPipe(object_hex_grid, start_q, start_r)
	local next_pipe = HexGetPipe(object_hex_grid, start_q + dq, start_r + dr) --if there is a next pipe we shouldnt demote to tube since connections are already set.
	if pipe and type(pipe.pillar) == "number" and pipe.pillar ~= 0 and not next_pipe then -- there is a last pilar in a pipe line
		local supply_connection_grid = GetSupplyConnectionGrid(city)
		local conn = HexGridGet(supply_connection_grid["water"], start_q, start_r)
		if band(conn, 63) == shift(1, dir > 2 and dir - 3 or dir + 3) then -- in our direction
			if pipe.pillar ~= max_int then
				last_pillar = pipe.pillar
				if not test then
					pipe:MakePipe(dir) -- convert that pillar to a pipe - we will continue the pipe line
				end
			end
		end
	end
	
	local construction_group = false
	local cs_grp_counter_for_cost = 1
	local cs_grp_elements_in_this_group = 0
	local cs_chunk_grp_counter_for_cost = 0
	if not test and elements_require_construction or input_constr_grp then
		if input_constr_grp then
			construction_group = input_constr_grp
			cs_grp_counter_for_cost = cs_grp_counter_for_cost - 1
			cs_grp_elements_in_this_group = #input_constr_grp - 1
		else
			construction_group = CreateConstructionGroup("LifeSupportGridElement", point(HexToWorld(start_q, start_r)), city:GetMapID(), 3, not elements_require_construction)
			construction_group[1].supplied = supplied
		end
	end
	
	local function clean_group(construction_group)
		if construction_group and construction_group[1]:CanDelete() then --it only has a leader.
			DoneObject(construction_group[1])
			construction_group = false
		end
		return construction_group
	end
	
	local last_status = false
	local last_placed_data_cell = nil
	local last_pass_idx = 0
	local has_group_with_no_hub = false
	local current_group_has_hub = false
	local last_element_found_hub = false
	local current_chunk_group_has_hub = false
	local last_non_chunk_element = false
	local total_chunk_cost = 0
	local last_connect_dir = connect_dir
	
	if input_data and #input_data > 0 then
		last_placed_data_cell = input_data[#input_data]
		last_pass_idx = last_placed_data_cell.idx
		last_status = last_placed_data_cell.status
		cs_grp_counter_for_cost = input_data.cs_grp_counter_for_cost or cs_grp_counter_for_cost
		cs_chunk_grp_counter_for_cost = input_data.cs_chunk_grp_counter_for_cost or cs_chunk_grp_counter_for_cost
		cs_grp_elements_in_this_group = Max((input_data.cs_grp_elements_in_this_group or cs_grp_elements_in_this_group) - 1, 0)
		has_group_with_no_hub = input_data.has_group_with_no_hub
		current_group_has_hub = input_data.current_group_has_hub
		local input_lnce = input_data.last_non_chunk_element
		last_non_chunk_element = input_lnce and input_lnce == #input_data and 0 or not not input_lnce
		if input_data.last_group_had_no_hub then
			has_group_with_no_hub = false
		end
		last_connect_dir = input_data.connect_dir
	end
	
	--preprocess
	local data = {} --step = { q, r, status }, 
	local unbuildable_chunks = {} --unbuildable_chunks = {chunk_start, chunk_end, status}
	local obstructors = {}
	local all_rocks = {}
	local chunk_idx = 0
	local can_build_anything = false
	local chunk_has_blocked_members = false
	local realm = game_map.realm
	local buildable = game_map.buildable
	local terrain = game_map.terrain

	for i = 0, steps do
		local q = start_q + i * dq
		local r = start_r + i * dr
		local bld = HexGetBuilding(object_hex_grid, q, r)
		local cable = HexGetCable(object_hex_grid, q, r)
		local pipe = HexGetPipe(object_hex_grid, q, r)
		local world_pos = point(HexToWorld(q, r))
		local is_buildable = buildable:IsBuildable(q, r)
		local is_buildable2 = pipe and pipe.pillar or CableBuildableTest(game_map, world_pos, q, r)
		local surf_deps = is_buildable and HexGetUnits(realm, nil, nil, world_pos, 0, nil, function(o) return not obstructors or not table.find(obstructors, o) end, "SurfaceDeposit") or empty_table
		local rocks = is_buildable and HexGetUnits(realm, nil, nil, world_pos, 0, false, nil, "WasteRockObstructor") or empty_table
		local stockpiles = is_buildable and HexGetUnits(realm, nil, nil, world_pos, 0, false, function(obj) return obj:GetParent() == nil and IsKindOf(obj, "DoesNotObstructConstruction") and not IsKindOf(obj, "Unit") end, "ResourceStockpileBase") or empty_table
		local pillar = is_buildable and (i + last_pillar) % pillar_spacing or nil
		pillar = pillar == 0 and pillar or is_buildable and i == steps and pillar or nil
		
		data[i] = i == 0 and last_placed_data_cell ~= nil and last_placed_data_cell or {q = q, r = r, can_make_pillar = true, status = SupplyGridElementHexStatus.clear, cable = cable, rocks = rocks, stockpiles = stockpiles, pipe = pipe, pillar = pillar, idx = last_pass_idx + i, bld = bld}
		data[i].place_construction_site = elements_require_construction or construction_group or #rocks > 0 or #stockpiles > 0
		data[i].chunk = data[i].chunk or unbuildable_chunks[chunk_idx] and (not unbuildable_chunks[chunk_idx].chunk_end or unbuildable_chunks[chunk_idx].chunk_end < 0) and unbuildable_chunks[chunk_idx] or nil
		data[i].pillar = not data[i].chunk and pillar or nil
		data[i].is_buildable = is_buildable
		data[i].is_buildable2 = is_buildable2
		
		local no_pillar_count = 0
		
		if pillar then
			table.iappend(all_rocks, rocks)
		end
		
		--test hex
		if bld then
			if data[i].pillar or bld.is_tall then
				table.insert(obstructors, bld)
				data[i].status = SupplyGridElementHexStatus.blocked
			end
			data[i].can_make_pillar = false
			no_pillar_count = no_pillar_count + 1
		end
		
		if pipe and (not pipe:CanMakePillar() 
			or (i > 0 and i < steps and not is_buildable)) then --no crossing in unbuildable
			if bld then
				table.insert_unique(obstructors, bld)
			end
			table.insert(obstructors, pipe)
			data[i].status = SupplyGridElementHexStatus.blocked
			data[i].can_make_pillar = false
			no_pillar_count = no_pillar_count + 1
		end
		
		if data[i] ~= last_placed_data_cell and pipe and construction_group and table.find(construction_group, pipe) then
			cs_grp_elements_in_this_group = cs_grp_elements_in_this_group - 1
		end
		
		if surf_deps and #surf_deps > 0 then
			if data[i].pillar then
				table.iappend(obstructors, surf_deps)
				data[i].status = SupplyGridElementHexStatus.blocked
			else
				data[i].can_make_pillar = false
				no_pillar_count = no_pillar_count + 1
			end
		end
		
		if cable and cable.pillar then
			table.insert(obstructors, cable)
			data[i].status = SupplyGridElementHexStatus.blocked
		end
		
		if not is_buildable then
			if i ~= steps 
				or not data[i].chunk 
				or not is_buildable2 
				or (i + last_pass_idx - 1 - data[i].chunk.chunk_start < 1) then
				data[i].status = const.SupplyGridElementsAllowUnbuildableChunksPipes and SupplyGridElementHexStatus.unbuildable or SupplyGridElementHexStatus.unbuildable_blocked
				data[i].can_make_pillar = false
				no_pillar_count = no_pillar_count + 1
			end
		end
		
		if not const.SupplyGridElementsAllowUnbuildableChunksPipes and last_status == SupplyGridElementHexStatus.unbuildable_blocked then
			data[i].status = SupplyGridElementHexStatus.unbuildable_blocked
		end
		
		data[i].no_pillar_count = no_pillar_count
		
		if i == 1 and input_data and #input_data > 0 and data[0].chunk and not data[0].is_buildable and
				data[i].is_buildable and not data[i].chunk and connect_dir ~= last_connect_dir then
			--very special case - going from unbuildable to buildable with a turn and having 2 pillars
			--next to each other on diff heights
			data[i].can_make_pillar = false
			no_pillar_count = no_pillar_count + 1
		end
		
		--analyze status and build unbuildable chunks
		if last_status then
			if (last_status == SupplyGridElementHexStatus.clear
				and data[i].status == SupplyGridElementHexStatus.unbuildable
				and (i > 0 or last_connect_dir == connect_dir)) --normal behavior
				or (last_placed_data_cell and i == 1 and 
					(data[i].status == SupplyGridElementHexStatus.unbuildable) and
					(last_status == SupplyGridElementHexStatus.blocked or last_status == SupplyGridElementHexStatus.unbuildable))--sepcifically for placement tool visuals, catch turn
				or (data[i].chunk == nil 
					and ((last_status == SupplyGridElementHexStatus.unbuildable and data[i].status == SupplyGridElementHexStatus.clear)
						or (last_status == SupplyGridElementHexStatus.blocked and data[i].status == SupplyGridElementHexStatus.unbuildable)))then --sepcifically for placement tool visuals, catch full unbuildable chunks so we can visualise them
				--it's a new unbuildable chunk
				chunk_idx = chunk_idx + 1
				
				local chunk = { chunk_start = i + last_pass_idx - 1, chunk_end = -(i + last_pass_idx), status = SupplyGridElementHexStatus.blocked, connect_dir = connect_dir }
				chunk.place_construction_site = data[i].place_construction_site
				
				local start_node = i > 0 and data[i - 1] or input_data and input_data[#input_data - 1]
				assert(start_node and start_node.idx == chunk.chunk_start)
				if start_node.chunk then
					start_node.chunk_end = start_node.chunk
					start_node.chunk_end.chunk_end = i + last_pass_idx - 1
				end
				start_node.chunk_start = chunk
				start_node.chunk = chunk
				data[i].chunk = chunk
				chunk.z1 = buildable:IsBuildable(start_node.q, start_node.r) and buildable:GetZ(start_node.q, start_node.r) or terrain:GetHeight(HexToWorld(start_node.q, start_node.r))
				chunk_has_blocked_members = false
				
				unbuildable_chunks[chunk_idx] = chunk
				
				if not start_node.can_make_pillar then
					if start_node.is_buildable2 and start_node.no_pillar_count == 1 and not start_node.is_buildable then
						start_node.can_make_pillar = true
						start_node.status = SupplyGridElementHexStatus.clear
					end
				end
				
				if start_node.cable and start_node.cable.pillar or
					start_node.pipe and not start_node.pipe:CanMakePillar() or
					not start_node.can_make_pillar then
					--this chunk is blocked
					chunk_has_blocked_members = true
					if start_node.bld then --since we didn't know we are gona be a pillar, we got to append this obstructor
						table.insert(obstructors, start_node.bld)
					end
				elseif not start_node.pillar then
					table.iappend(all_rocks, start_node.rocks)
				end
				
				cs_grp_elements_in_this_group = cs_grp_elements_in_this_group - 1
				if cs_grp_elements_in_this_group <= 0 then
					cs_grp_elements_in_this_group = 0
					cs_grp_counter_for_cost = Max(cs_grp_counter_for_cost - 1, 0)
					if last_element_found_hub then
						current_group_has_hub = false
						current_chunk_group_has_hub = true
					end
				end
				if last_non_chunk_element == i - 1 then
					last_non_chunk_element = false
				end
				if not start_node.pipe then
					total_chunk_cost = total_chunk_cost + 200 --mark prev
				end
			elseif last_status == SupplyGridElementHexStatus.unbuildable and data[i].status == SupplyGridElementHexStatus.blocked 
				and unbuildable_chunks[chunk_idx] then
				--blocked chunk
				unbuildable_chunks[chunk_idx].status = SupplyGridElementHexStatus.blocked
				chunk_has_blocked_members = true
			end
			if last_status == SupplyGridElementHexStatus.unbuildable and data[i].status == SupplyGridElementHexStatus.clear 
				and unbuildable_chunks[chunk_idx] and unbuildable_chunks[chunk_idx].chunk_end < 0 then
				--possible buildable unbuildable chunk
				unbuildable_chunks[chunk_idx].chunk_end = i + last_pass_idx
				local chunk_size = unbuildable_chunks[chunk_idx].chunk_end - unbuildable_chunks[chunk_idx].chunk_start
				data[i].chunk_end = unbuildable_chunks[chunk_idx]
				unbuildable_chunks[chunk_idx].place_construction_site = unbuildable_chunks[chunk_idx].place_construction_site or data[i].place_construction_site
				unbuildable_chunks[chunk_idx].status = chunk_size >= 1 and not chunk_has_blocked_members and SupplyGridElementHexStatus.clear or unbuildable_chunks[chunk_idx].status
				
				--ui counters
				cs_chunk_grp_counter_for_cost = cs_chunk_grp_counter_for_cost + 1
				if not current_chunk_group_has_hub then
					has_group_with_no_hub = true
				else
					current_chunk_group_has_hub = false
				end
				
				--build z data
				local arr_idx = unbuildable_chunks[chunk_idx].chunk_start - last_pass_idx
				local cell_data = arr_idx >= 0 and data[arr_idx] 
										or input_data and input_data[#input_data + arr_idx]
				assert(cell_data and cell_data.idx == unbuildable_chunks[chunk_idx].chunk_start)
				local x1, y1 = HexToWorld(cell_data.q, cell_data.r)
				local z1 = unbuildable_chunks[chunk_idx].z1
				local x2, y2 = HexToWorld(q, r)
				local z2 = is_buildable and buildable:GetZ(q, r) or terrain:GetHeight(x2, y2)
				unbuildable_chunks[chunk_idx].z2 = z2
				unbuildable_chunks[chunk_idx].zd = z2 - z1
				--test for pipe/cable block
				if data[i].cable and data[i].cable.pillar or
					data[i].pipe and not data[i].pipe:CanMakePillar() or 
					not data[i].can_make_pillar then
					unbuildable_chunks[chunk_idx].status = SupplyGridElementHexStatus.blocked
					if bld then
						table.insert(obstructors, bld)
					end
				else
					--test los
					local has_los = realm:CheckLineOfSight(point(x1, y1, z1 + const.GroundOffsetForLosTest), point(x2, y2, z2 + const.GroundOffsetForLosTest))
					if not has_los then
						unbuildable_chunks[chunk_idx].status = SupplyGridElementHexStatus.blocked
					else
						last_pillar = pillar_spacing - (i % pillar_spacing)
					end
				end
				
				if not pillar then
					table.iappend(all_rocks, rocks)
				end
			end
			if data[i].chunk and data[i].chunk.chunk_end < 0 then
				data[i].chunk.chunk_end = -(i + last_pass_idx)
				local x, y = HexToWorld(q, r)
				data[i].chunk.z2 = is_buildable and buildable:GetZ(q, r) or terrain:GetHeight(x, y)
				data[i].chunk.zd = data[i].chunk.z2 - data[i].chunk.z1
			end
		end
		
		if data[i].status == SupplyGridElementHexStatus.unbuildable and not data[i].chunk then
			data[i].status = SupplyGridElementHexStatus.blocked
		end
		
		if not can_build_anything and data[i].status == SupplyGridElementHexStatus.clear then
			if (not last_placed_data_cell or not can_build_anything) and not data[i].pillar and not data[i].can_make_pillar then
				--first buildable should be pillar, hacky tets wether we are the first line override_first_pillar ~= nil
				 data[i].status = SupplyGridElementHexStatus.blocked
			else
				if not last_placed_data_cell and not data[i].pillar and last_pillar == 0 then
					last_pillar = i
					data[i].pillar = 0
				end
				can_build_anything = true
			end
		end
		
		last_element_found_hub = false
		if not data[i].chunk then
			if cs_grp_elements_in_this_group >= const.ConstructiongGridElementsGroupSize then
				cs_grp_counter_for_cost = cs_grp_counter_for_cost + 1
				cs_grp_elements_in_this_group = 1
				
				if not current_group_has_hub then
					has_group_with_no_hub = true
				else
					current_group_has_hub = false
				end
			else
				if cs_grp_elements_in_this_group <= 0 and cs_grp_counter_for_cost <= 0 then
					cs_grp_counter_for_cost = 1
				end
				cs_grp_elements_in_this_group = cs_grp_elements_in_this_group + 1
			end
			
			if not current_group_has_hub and not has_group_with_no_hub then
				if DoesAnyDroneControlServiceAtPoint(game_map.map_id, world_pos) then
					current_group_has_hub = true
					last_element_found_hub = true
				end
			end
		else
			if not data[i].pipe then
				total_chunk_cost = total_chunk_cost + 200
			end
			if not current_chunk_group_has_hub and not has_group_with_no_hub then
				if DoesAnyDroneControlServiceAtPoint(game_map.map_id, world_pos) then
					current_chunk_group_has_hub = true
				end
			end
		end
		
		if not last_non_chunk_element and not data[i].chunk then
			last_non_chunk_element = i
		end
		
		last_status = data[i].status
	end
	
	data.connect_dir = connect_dir
	data.cs_grp_counter_for_cost = cs_grp_counter_for_cost
	data.cs_grp_elements_in_this_group = cs_grp_elements_in_this_group
	data.cs_chunk_grp_counter_for_cost = cs_chunk_grp_counter_for_cost
	local total_cost = GetGridElementConstructionCost("LifeSupportGridElement")
	for k, v in pairs(total_cost or empty_table) do
		total_cost[k] = v * cs_grp_counter_for_cost + total_chunk_cost
	end
	
	if not has_group_with_no_hub and 
			((data[steps].chunk and (not data[steps].chunk_end and not current_chunk_group_has_hub or 
				(last_non_chunk_element and not current_group_has_hub))) or
			 not data[steps].chunk and not current_group_has_hub) then
		has_group_with_no_hub = true
		data.last_group_had_no_hub = true
	end
	data.has_group_with_no_hub = has_group_with_no_hub
	data.current_group_has_hub = current_group_has_hub
	
	--find last pillar
	local data_count = #data
	local data_counter = data_count
	while data_counter > 0 
		and ((data[data_counter].status == SupplyGridElementHexStatus.blocked 
			or data[data_counter].status == SupplyGridElementHexStatus.unbuildable_blocked)
		or (not data[data_counter].pillar and not data[data_counter].can_make_pillar)) do
		if data[data_counter].status ~= SupplyGridElementHexStatus.blocked or 
			data[data_counter].status ~= SupplyGridElementHexStatus.unbuildable_blocked then
			data[data_counter].status = const.SupplyGridElementsAllowUnbuildableChunksPipes and SupplyGridElementHexStatus.blocked or SupplyGridElementHexStatus.unbuildable_blocked
		end
		data_counter = data_counter - 1
	end
	if data_counter ~= data_count and data[data_counter] then
		data[data_counter].pillar = (data_counter + last_pillar) % pillar_spacing
		data[data_counter].ignore_this_pillar_in_visuals = true
	end
	
	--fix up chunk end
	if chunk_idx > 0 then
		local last_chunk = unbuildable_chunks[#unbuildable_chunks]
		if last_chunk.chunk_end < 0 then
			last_chunk.chunk_end = abs(last_chunk.chunk_end)
			local node = data[last_chunk.chunk_end - last_pass_idx]
			node.chunk_end = last_chunk
			if not node.pillar then
				table.iappend(all_rocks, node.rocks)
			end
		end
	end
	
	if test or not can_build_anything then
		--ret
		construction_group = clean_group(construction_group)
		return can_build_anything, construction_group, obstructors, data, unbuildable_chunks, all_rocks, total_cost
	end
	
	--postprocess and place
	local proc_placed_pipe = function(data_idx, cell_data, pillar, chain, cg)
		if cell_data.pipe then
			if pillar then
				local is_chunk_pillar = cell_data.pipe.pillar == max_int
				cell_data.pipe:MakePillar(pillar == max_int and pillar or cell_data.pipe.pillar or true)
				if not is_chunk_pillar and cg and cell_data.pipe:GetGameFlags(const.gofUnderConstruction) ~= 0 and pillar == max_int then
					cell_data.pipe:ChangeConstructionGroup(cg)
				end
			end
			if not chain and data_idx ~= steps then
				cell_data.pipe:TryConnectInDir(dir)
			end
			
			return cell_data.pipe
		end
		
		return false
	end
	
	local place_pipe_cs = function(data_idx, cg, pillar, chain)
		local params = {}
		local cell_data = data[data_idx]
		local c = proc_placed_pipe(data_idx, cell_data, pillar, chain, cg)
		if c then return c end
		local q = cell_data.q
		local r = cell_data.r
		
		params.construction_group = cg
		cg[#cg + 1] = params
		params.connect_dir = connect_dir
		params.pillar = pillar
		params.chain = chain
		params.construction_grid_skin = skin_name
		
		local cs = PlaceConstructionSite(city, "LifeSupportGridElement", point(HexToWorld(q, r)), angle, params, nil, chain or not buildable:IsBuildable(q, r))
		if not chain and cell_data.status == SupplyGridElementHexStatus.clear then
			cs:AppendWasteRockObstructors(cell_data.rocks)
			cs:AppendStockpilesUnderneath(cell_data.stockpiles)
		end
		
		cell_data.pipe = cs
		return cs
	end

	local cm1, cm2, cm3, cm4 = GetPipesPalette()
	local place_pipe = function(data_idx, pillar, chain)
		local cell_data = data[data_idx]
		local c = proc_placed_pipe(data_idx, cell_data, pillar, chain)
		if c then return c end
		local q = cell_data.q
		local r = cell_data.r
		local el = LifeSupportGridElement:new({ city = city, connect_dir = connect_dir, pillar = pillar, chain = chain, construction_grid_skin = skin_name }, city:GetMapID())
		local x, y = HexToWorld(q, r)
		el:SetPos(x, y, z)
		el:SetAngle(angle)
		el:SetGameFlags(const.gofPermanent)
		if not chain and buildable:IsBuildable(q, r) then
			FlattenTerrainInBuildShape(nil, el)
		end
		SetObjectPaletteRecursive(el, cm1, cm2, cm3, cm4)
		
		cell_data.pipe = el
		return el
	end
	
	chunk_idx = 1
	local i = 0
	local last_placed_obj
	
	while i <= steps do
		local cell_data = data[i]
		local q = cell_data.q
		local r = cell_data.r
		local is_chunk_start = unbuildable_chunks[chunk_idx] and unbuildable_chunks[chunk_idx].chunk_start == (i + last_pass_idx)
		
		if is_chunk_start and unbuildable_chunks[chunk_idx].status == SupplyGridElementHexStatus.clear then
			--place buildable unbuildable chunk
			local chunk_data = unbuildable_chunks[chunk_idx]
			local length = chunk_data.chunk_end - chunk_data.chunk_start - 1
			if chunk_data.place_construction_site then
				--place constr grp, chunks are their own groups
				local chunk_construction_group = CreateConstructionGroup("LifeSupportGridElement", point(HexToWorld(q, r)), city:GetMapID(), 3, not elements_require_construction)
				local chunk_group_leader = chunk_construction_group[1]
				chunk_group_leader.supplied = supplied
				--add pillar 1
				local p1 = place_pipe_cs(i, chunk_construction_group, max_int) --pillar == number means it cant auto demote
				--place the lines
				for j = i + 1, chunk_data.chunk_end - 1 - last_pass_idx do
					local chain = GetChainParams(j + last_pass_idx - chunk_data.chunk_start - 1, length, dir, chunk_data) 
					local pipe = place_pipe_cs(j, chunk_construction_group, nil, chain)
					pipe:SetChainParams(chain.delta, chain.index, chain.length)
				end
				local p2 = place_pipe_cs(chunk_data.chunk_end - last_pass_idx, chunk_construction_group, max_int)
				if chunk_group_leader:CanDelete() then
					--line was already placed
					DoneObject(chunk_group_leader)
				else
					chunk_group_leader.drop_offs = {p1, p2}
					chunk_group_leader.construction_cost_multiplier = (20 * (#chunk_construction_group - 1)) --0.2 per pipe
					last_placed_obj = p2
				end
			else
				--place instant
				local p1 = place_pipe(i, max_int)
				for j = i + 1, chunk_data.chunk_end - 1 - last_pass_idx do
					local chain = GetChainParams(j + last_pass_idx - chunk_data.chunk_start - 1, length, dir, chunk_data) 
					local pipe = place_pipe(j, nil, chain)
					pipe:SetChainParams(chain.delta, chain.index, chain.length)
				end
				local p2 = place_pipe(chunk_data.chunk_end - last_pass_idx, max_int)
				last_placed_obj = p2
			end
			
			i = chunk_data.chunk_end - last_pass_idx
		else
			--place regular cable
			if cell_data.status == SupplyGridElementHexStatus.clear then
				local placed = false
				if cell_data.place_construction_site then
					--make new grp if needed
					if not construction_group or #construction_group > const.ConstructiongGridElementsGroupSize then
						if construction_group and construction_group[1]:CanDelete() then
							DoneObject(construction_group[1])
						end
						
						construction_group = false
						
						--new group
						if elements_require_construction or #data[i].rocks > 0 or #data[i].stockpiles > 0 then
							construction_group = CreateConstructionGroup("LifeSupportGridElement", point(HexToWorld(q, r)), city:GetMapID(), 3, not elements_require_construction)
							construction_group[1].supplied = supplied
						end
					end
					
					if construction_group then
						last_placed_obj = place_pipe_cs(i, construction_group, cell_data.pillar)
						placed = last_placed_obj
					end
				end
				if not placed then
					last_placed_obj = place_pipe(i, cell_data.pillar)
				end
			end
		end
		
		--increment counters
		if is_chunk_start then
			if unbuildable_chunks[chunk_idx].status ~= SupplyGridElementHexStatus.clear then
				if unbuildable_chunks[chunk_idx].chunk_end then
					i = unbuildable_chunks[chunk_idx].chunk_end - 1 - last_pass_idx
				else
					i = steps + 1
				end
			end
			
			chunk_idx = chunk_idx + 1
			
			if unbuildable_chunks[chunk_idx] and unbuildable_chunks[chunk_idx].status == SupplyGridElementHexStatus.clear 
				and unbuildable_chunks[chunk_idx].chunk_start == (i + last_pass_idx) then
				--next chunk starts @ this chunk's end
				i = i - 1 
			end
		end
		
		i = i + 1
	end

	construction_group = clean_group(construction_group)
	
	return true, construction_group, obstructors, data, unbuildable_chunks, last_placed_obj, total_cost
end
