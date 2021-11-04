DefineClass.City = {
	__parents = { "InitDone", "ResourceTracking", "LabelContainer", "Exploration", "DemolishCascading", "ConstructionControllers" },
	properties = {
	},	
	day = 1, -- deprecated use the day in colony, but in certain saves still accessed
	hour = 6, -- deprecated use the hour in colony, but in certain saves still accessed
	minute = 0, -- deprecated use the minute in colony, but in certain saves still accessed
	
	colony = false,

	electricity = false,
	water = false,
	air = false,
	dome_networks = false,

	available_prefabs = false,
	drone_prefabs = 0,

	selected_dome = false,
	selected_dome_unit_tracking_thread = false,

	queued_resupply = false,
	launch_mode = false, -- (false, "rocket", "elevator", ...)
	
	LastConstructedBuilding = false,
	
	cur_sol_died = 0,
	last_sol_died = 0,
	dead_notification_shown = false,
	
	map_id = "",
}

function City:Init()
	assert(UIColony)
	self.colony = UIColony
	self.selected_dome = {}
	self.available_prefabs = {}
	self.electricity = SupplyGrid:new{ city = self }
	self.water = SupplyGrid:new{ city = self }
	self.air = SupplyGrid:new{ city = self }

	self.queued_resupply = {}
	DemolishCascading.Init(self)

	self:AddToLabel("Consts", g_Consts)
	self:InitEmptyLabel("Dome")

	self:InitGatheredResourcesTables()
	self:InitTimeSeries()

	self:InitConstructionControllers(self)

	CityUnitController[self] = UnitController:new()
end

function City:Done()
	self:DoneConstructionControllers()
	CityUnitController[self] = nil
end

function City:AddToLabel(label, obj)
	self.colony.city_labels:AddToLabel(label, obj)
	if not LabelContainer.AddToLabel(self, label, obj) then
		return
	end
	return true
end

function City:RemoveFromLabel(label, obj)
	self.colony.city_labels:RemoveFromLabel(label, obj)
	if not LabelContainer.RemoveFromLabel(self, label, obj) then
		return
	end
	return true
end

GlobalVar("FirstUniversalStorage", false)

function City:CreateSessionRand(...)
	return UIColony:CreateSessionRand(...)
end

function City:CreateMapRand(...)
	return UIColony:CreateMapRand(...)
end

function City:CreateResearchRand(...)
	return UIColony:CreateResearchRand(...)
end
function City:Random(min, max) -- compatibility
	return SessionRandom:Random(min, max)
end

function City:TableRand(tbl) -- compatibility
	return SessionRandom:TableRand(tbl)
end

function City:LabelRand(label)
	return SessionRandom:TableRand(self.labels[label] or empty_table)
end

function City:DailyUpdate(day)
	self:GatheredResourcesOnDailyUpdate()
	self:CalcRenegades()
	self:UpdateTimeSeries()
	
	self.last_sol_died = self.cur_sol_died
	self.cur_sol_died = 0
	
	if IsGameRuleActive("EndlessSupply") and FirstUniversalStorage and IsValid(FirstUniversalStorage) then
		FirstUniversalStorage:Fill()
	end
	local colonists = #(self.labels.Colonist or empty_table)
	ColonistHeavyUpdateTime = Clamp(colonists / 300, 0, 12) * const.HourDuration
end

function City:HourlyUpdate(hour)
	self:GatheredResourcesOnHourlyUpdate(self.map_id)
	CreateGameTimeThread(self.UpdateColonistsProc, self)
	
	if HasDustStorm(self:GetMapID()) and hour % const.BreakIntervalHours == 0 then
		self:RandomBreakSupplyGrid()
	end
end

function City:UpdateColonistsProc()
	local colonists = table.copy(self.labels.Colonist or empty_table)
	local update_interval = const.ColonistUpdateInterval or 50
	local update_steps = const.HourDuration / update_interval
	for i = 1, update_steps do
		local t = GameTime()
		local hour = UIColony.hour
		for j = #colonists * (i - 1) / update_steps + 1, #colonists * i / update_steps do
			local colonist = colonists[j]
			if IsValid(colonist) and not colonist:IsDying() then
				colonist:HourlyUpdate(t, hour)
			end
		end
		Sleep(update_interval)
	end
end

function City:RandomBreakSupplyGrid()
	self.electricity:RandomBreakElements()
	self.water:RandomBreakElements()
end

function City:CalcRenegades()
	local all_colonists = #(self.labels.Colonist or empty_table)
	local colonist_count_threshold = IsGameRuleActive("RebelYell") and 20 or 50
	if all_colonists<=colonist_count_threshold then return end
	
	for idx, dome in ipairs(self.labels.Dome) do
		all_colonists = all_colonists - #(dome.labels.Child or empty_table)
		if all_colonists <= colonist_count_threshold then return end
	end
	
	for idx, dome in ipairs(self.labels.Dome) do
		dome:CalcRenegades()
	end
end

function City:Gossip(gossip, ...)
	if not netAllowGossip then return end
	NetGossip(gossip, GameTime(), ...)
end

function OnMsg.LoadGame()
	local city = UICity
	if city then
		--fix resource tracking from old saves (init it if it aint inited).
		city:InitGatheredResourcesTables()
	end
end

---------------------Dome------------------------

function City:SelectDome(dome, trigger)
	if not dome then
		assert(dome)
		return
	end
	
	if self.selected_dome[dome] and self.selected_dome[dome][trigger] then return end
	self.selected_dome[dome] = self.selected_dome[dome] or {}
	self.selected_dome[dome][trigger] = true
	dome:Open()
	
	if IsValidThread(self.selected_dome_unit_tracking_thread) then
		DeleteThread(self.selected_dome_unit_tracking_thread)
	end
	
	if IsKindOf(trigger, "Unit") then
		--keep track when the unit will exit the dome.
		self.selected_dome_unit_tracking_thread = CreateGameTimeThread(function(self, dome, trigger)
			while true do
				if not IsValid(dome) then return end
				
				if not self.selected_dome[dome] then break end
				if not IsValid(SelectedObj) then break end
				if IsKindOf(SelectedObj, "MultiSelectionWrapper") then
					if not table.find(SelectedObj.objects, trigger) then break end
				else
					if SelectedObj ~= trigger then break end
				end
				
				local should_break = true
				if trigger:GetPos() ~= InvalidPos() then
					if trigger:HasMember("holder") and
						IsValid(trigger.holder) and
						self.selected_dome[IsObjInDome(trigger.holder)][trigger]
					then
						should_break = false
					end
				end
				if IsObjInDome(trigger) == dome then should_break = false end
				local object_hex_grid = GetObjectHexGrid(self)
				local hex_building = HexGetBuilding(object_hex_grid, WorldToHex(trigger))
				if hex_building == dome or hex_building == dome.my_interior then should_break = false end
				if should_break then break end
				
				Sleep(1000)
			end
			
			if self.selected_dome[dome] and self.selected_dome[dome][trigger] then
				CreateRealTimeThread(self.DeselectDome, self, dome, trigger)
			end
			
		end, self, dome, trigger)
	end
end

function City:DeselectDome(dome, trigger)
	if not self.selected_dome[dome] or not self.selected_dome[dome][trigger] then return end
	
	--handles special case when build menu is being opened, it will take care of the closing for us.
	local bm = GetDialog("XBuildMenu")
	if not bm or bm.context.selected_dome ~= self.selected_dome then
		dome:Close()
	end
	
	self.selected_dome[dome][trigger] = nil
	if not next(self.selected_dome[dome]) then
		self.selected_dome[dome] = nil
	end
end

function OnMsg.SelectionAdded(obj)
	if IsKindOf(obj, "MultiSelectionWrapper") and obj:IsClassSupported("Unit") then
		for i,subobj in ipairs(obj.objects) do
			local dome_to_select = IsObjInDome(subobj)
			if IsValid(dome_to_select) then
				UICity:SelectDome(dome_to_select, subobj)
			end
		end
	else
		local dome_to_select = IsKindOf(obj, "Dome") and obj or IsObjInDome(obj)
		if IsValid(dome_to_select) then
			UICity:SelectDome(dome_to_select, obj)
		end
	end
end

function OnMsg.SelectionRemoved(obj)
	for dome,triggers in pairs(UICity.selected_dome) do
		if triggers[obj] then
			UICity:DeselectDome(dome, obj)
		end
	end
end

function SavegameFixups.OpenManyDomesWithMultiselection()
	if UICity.selected_dome and SelectedObj == UICity.selected_dome then
		UICity.selected_dome = {
			[UICity.selected_dome] = {
				[UICity.selected_dome] = true,
			},
		}
	else
		UICity.selected_dome = { }
	end
end

function City:CountDomeLabel(label)
	local count = 0
	local domes = self.labels.Dome or ""
	for i = 1,#domes do
		count = count + #(domes[i].labels[label] or "")
	end
	return count
end

-------------Resupply------------------

function City:CreateSupplyShips()
	local rockets = self.labels.SupplyRocket or empty_table
	
	for i = #rockets, 1, -1 do
		if not rockets[i]:IsValidPos() then
			DoneObject(rockets[i])
		end
	end
	
	for i = #rockets+1, GetStartingRockets() do
		PlaceBuildingIn(GetRocketClass(), self.map_id, {city = self})
	end
end

function GetStartingRockets(sponsor, commander, ignore_bonus_rockets)
	sponsor = sponsor or GetMissionSponsor()
	commander = commander or GetCommanderProfile()
	return (sponsor.initial_rockets or 0) + (not ignore_bonus_rockets and commander.bonus_rockets or 0)
end

function City:OrderLanding(cargo, cost, initial, label)
	label = label or "SupplyRocket"
	local rockets = self.labels[label] or empty_table
	for i = 1, #rockets do
		local rocket = rockets[i]
		if initial and rocket:IsValidPos() then
			return
		end
		if rocket:IsAvailable() then
			rocket:SetCommand("FlyToMars", cargo, cost, nil, initial)
			return 
		end
	end
end

function City:UseInventoryItem(obj,class, amount)
end
--------------------- resupply ---------------------

function City:GetWorkshopWorkersPercent()
	local colonists = (self.labels.Colonist or empty_table)
	local workshops = self.labels.Workshop or empty_table
	if #colonists==0 or #workshops==0 then 
		return 0 
	end
	local workers= 0
	for _, workshop in ipairs(workshops) do
		if workshop.working then
			for i=1, workshop.max_shifts do
				workers = workers + #workshop.workers[i]				
			end
		end
	end
	if workers==0 then 
		return 0 
	end
	local col_count = 0
	for _, colonist in ipairs(colonists) do
		if colonist:CanWork() then
			col_count = col_count + 1
		end
	end
	if col_count==0 then 
		return 0 
	end
	return MulDivRound(workers, 100, col_count)
end

CargoCapacityLabels = {}

function City:GetCargoCapacity()
	local label = CargoCapacityLabels[self.launch_mode]
	if label then
		local obj = (self.labels[label] or empty_table)[1]
		return obj and obj.cargo_capacity or 0
	end
	return g_Consts.CargoCapacity
end

function GetLaunchModeMaxPassengers(launch_mode)
	return launch_mode == "passenger_pod" and g_Consts.MaxColonistsPerPod or g_Consts.MaxColonistsPerRocket
end

function City:AddResupplyItems(items)
	local inventory = self.queued_resupply
	for i = 1, #items do
		local item = items[i]
		local idx = table.find(inventory, "class", item.class)
		if idx then
			inventory[idx].amount = inventory[idx].amount + item.amount
		elseif item.amount > 0 then
			inventory[#inventory + 1] = item
		end
	end	
end

function City:GetPrefabs(bld)
	return self.available_prefabs[bld] or 0
end

function City:AddPrefabs(bld, count, refresh)
	assert((self.available_prefabs[bld] or 0) + count >= 0)
	local available = (self.available_prefabs[bld] or 0) + count
	self.available_prefabs[bld] = available > 0 and available or nil
	if refresh==nil or refresh==true then
		RefreshXBuildMenu()
	end
end

function City:GetTotalPrefabs()
	local prefabs_count = 0
	local prefabs = self.available_prefabs or empty_table
	for prefab, count in pairs(prefabs) do
		prefabs_count = prefabs_count + count
	end
	return prefabs_count
end

function City:GetTotalPrefabsAllowedIn(environments)
	local prefabs_count = 0
	local prefabs = self.available_prefabs or empty_table
	for prefab, count in pairs(prefabs) do
		if IsBuildingAllowedIn(prefab, environments) then
			prefabs_count = prefabs_count + count
		end
	end
	return prefabs_count
end

function City:RegisterBuildingCompleted(bld)
	self.LastConstructedBuilding = bld
end

function OnMsg.ConstructionComplete(bld)
	if not ActiveMapData.GameLogic then return end
	assert(bld.city)
	bld.city:RegisterBuildingCompleted(bld)
end

GlobalVar("Cities", {})
GlobalVar("UICity", false)
GlobalVar("MainCity", false)

function GetCityByID(map_id)
	return Cities[map_id] or MainCity
end

function GetCity(object)
	local map_id = object:GetMapID()
	return Cities[map_id] or MainCity
end

local function CreateCity(map_id)
	local city = City:new({map_id = map_id})
	Cities[map_id] = city
	table.insert(Cities, city)
end

function OnMsg.PostPreSwitchMap(previous_map_id, map_id)
	if not ActiveMapData.GameLogic then return end

	Cities = Cities or {}
	local is_first_city = #Cities == 0
	
	if not Cities[map_id] then
		CreateCity(map_id)
	end
	
	UICity = Cities[map_id]

	if is_first_city then
		MainCity = Cities[map_id]
		Msg("CityStart", MainCity)
	end
end

function OnMsg.NewMapLoaded(map_id)
	if not ActiveMapData.GameLogic then return end

	local city = Cities[map_id]
	city:InitBreakThroughAnomalies()
	Exploration.Init(city)
end

function SavegameFixups.A001_CityMulti()
	MainCity = Cities[1]
	Cities[ActiveMapID] = MainCity
	MainCity.map_id = ActiveMapID

	Discoveries.Init(MainCity)	
end

function SavegameFixups.A002_CityMulti()
	for _, city in ipairs(Cities) do
		city:InitConstructionControllers(city)
		city:ApplyFixup()
	end	
end

function OnMsg.MapUnload(map_id)
	if Cities then
		local city = Cities[map_id]
		assert(city)
		if city == UICity then
			UICity = false
		end
		Cities[map_id] = nil
		local index = table.find(Cities, city)
		assert(index)
		DoneObject(city)
		table.remove(Cities, index)
	end
end

function OnMsg.SwitchMap(map_id)
	if Cities[map_id] then
		UICity = Cities[map_id]
	end
end

function OnMsg.ChangeMap()
	if not ActiveMapData.GameLogic then return end
	SetTimeFactor(const.DefaultTimeFactor)
end

function OnMsg.PostNewGame()
	if ActiveMapData.GameLogic then
		StartScenarios()
	end
end

function OnMsg.NewHour(hour)
	for _, city in ipairs(Cities) do
		city:HourlyUpdate(hour)
	end
end

function OnMsg.NewDay(day)
	for _, city in ipairs(Cities) do
		city:DailyUpdate(day)
	end
end

-------------------------------

function SavegameFixups.CityTimeSeries()
	UICity:InitTimeSeries()
end

function City:CountBuildings(label)
	label = label or "Building"
	local all_buildings = 0
	for _, building in ipairs(self.labels[label] or empty_table) do
		if building.count_as_building and not building.destroyed and not IsKindOfClasses(building, "ConstructionSite", "ConstructionSiteWithHeightSurfaces") then
			all_buildings = all_buildings + 1
		end
	end
	return all_buildings
end

function City:CountShuttles()
	local shuttles = 0
	for _, hub in ipairs(self.labels.ShuttleHub or empty_table) do
		shuttles = shuttles + #hub.shuttle_infos
	end
	return shuttles
end

function City:HasLandedRocket(use_inorbit)
	for _, rocket in ipairs(self.labels.AllRockets or empty_table) do
		if rocket.command == "Refuel" or rocket.command == "WaitLaunchOrder" or (use_inorbit and rocket.command == "WaitInOrbit") then
			return true
		end
	end
	return false
end

function GetDroneClass()
	return "Drone"
end

function City:CreateDrone()
	local drone_class = GetDroneClass()
	local classdef = drone_class and g_Classes[drone_class] or Drone
	local drone = classdef:new({ city = self }, self.map_id)	
	return drone
end

function GetCityConstructionControllers(city)
	return city or UICity
end
