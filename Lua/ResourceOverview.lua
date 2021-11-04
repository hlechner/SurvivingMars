GlobalVar("ShowResourceOverview", false)
GlobalVar("g_ResourceOverviewCity", {})
GlobalVar("g_ResourceOverviewTotal", false)

GlobalRealTimeThread("ResourceOverviewThread", function()
	while true do
		ResourceOverviewThreadBody()
		Sleep(1000)
	end
end)

function SavegameFixups.ResourceOverviewThread_MovedBodyOutOfLoop()
	RestartGlobalRealTimeThread("ResourceOverviewThread")
end

function OnMsg.MapUnload(map_id)
	if g_ResourceOverviewCity then
		g_ResourceOverviewCity[map_id] = nil
	end
end

function ResourceOverviewThreadBody()
	for _,city in ipairs(Cities) do
		local resource_overview = GetCityResourceOverview(city)
		resource_overview.estimated_maintenance_time = RealTime() -- avoid performing estimation on a regular basis
		pcall(GatherResourceOverviewData, resource_overview.data, city)
		resource_overview:GatherPerDomeInfo()
		resource_overview:ProcessDomelessColonists()
		resource_overview:CalcColonistsTraits()
		resource_overview:CalcConsumptionProduction()
		resource_overview:GatherDronesInfo()
		ObjModified(resource_overview)
	end
	local resource_overview_total = GetResourceOverviewTotal()
	resource_overview_total:Update()
end

function GetResourceOverviewTotal()
	g_ResourceOverviewTotal = g_ResourceOverviewTotal or ResourceOverviewTotal:new()
	return g_ResourceOverviewTotal 
end

function GetCityResourceOverview(city)
	assert(city ~= nil)
	local map_id = city.map_id
	if g_ResourceOverviewCity[map_id] == nil then
		g_ResourceOverviewCity[map_id] = ResourceOverview:new()
		g_ResourceOverviewCity[map_id].city = city
		pcall(GatherResourceOverviewData, g_ResourceOverviewCity[map_id].data, city)
	end
	return g_ResourceOverviewCity[map_id]
end

DefineClass.ResourceOverviewTotal =
{
	__parents = { "Object", "InfopanelObj" },

	resources_total = {
		Metals = 0,
		Concrete = 0,
		Food = 0,
		PreciousMetals = 0,
		Polymers = 0,
		MachineParts = 0,
		Fuel = 0,
		Electronics = 0,
		PreciousMinerals = 0,
		WasteRock = 0,
		tourists = 0,
		colonists = 0,
		drones = 0
	},
	non_roundable = {
		tourists = true,
		colonists = true,
		drones = true
	},
}

function ResourceOverviewTotal:Update()
	for restype,_ in pairs(self.resources_total) do
		self.resources_total[restype] = 0
	end
	local cities = Cities
	for restype, value in pairs(self.resources_total) do
		for i = 1, #Cities do
			local city = Cities[i]
			local res_city = GetCityResourceOverview(city)
			local amount = res_city.data[restype] or 0
			self.resources_total[restype] = self.resources_total[restype] + amount
		end
	end
end

DefineClass.ResourceOverview =
{
	__parents = { "Object", "InfopanelObj" },
	DisplayName = T(235513581267, "Resource Overview"),
	description = T(3610, "Aggregated information for all resources in the Colony."),
	
	data = false,
	city = false,
	encyclopedia_id = false,
	overview = "ResourceOverview",
	
	estimated_maintenance_res = empty_table,
	estimated_maintenance_time = 0,
}

local function RoundDownResourceAmount(r)
	r = r or 0
	r = r / const.ResourceScale
	r = r * const.ResourceScale
	return r
end

function ResourceOverview:Init()
	self.data = {}
	self.city = false
end

function ResourceOverview:GetDisplayName()
	if self.overview == "ResourceOverview" then
		return T(235513581267, --[[Post-Cert]] "Resource Overview")
	elseif self.overview == "ColonistOverview" then 
		return T(7853, --[[Post-Cert]] "Colonists Overview")
	elseif self.overview == "TraitsOverview" then	
		return T(235, --[[Post-Cert]] "Traits")
	end
end

function ResourceOverview:GetIPMode()
	return self.overview
end

function ResourceOverview:Getdescription()
	if self.overview == "ResourceOverview" then
		return T(7852, --[[Post-Cert]] "View information about the resources in your Colony.")
	elseif self.overview == "ColonistOverview" then
		return T(7854, --[[Post-Cert]] "View information about your Colonists.")
	elseif self.overview == "TraitsOverview" then	
		return T(7855, --[[Post-Cert]] "View information about the traits of your Colonists.")
	end
end

function ResourceOverview:GetTotalProducedPower()
	return self.data.total_power_production or 0
end

function ResourceOverview:GetTotalStoredPower()
	return self.data.total_power_storage or 0
end

function ResourceOverview:GetTotalRequiredPower()
	return self.data.total_power_demand or 0
end

function ResourceOverview:GetTotalProducedAir()
	return self.data.total_air_production or 0
end

function ResourceOverview:GetTotalStoredAir()
	return self.data.total_air_storage or 0
end

function ResourceOverview:GetTotalRequiredAir()
	return self.data.total_air_demand or 0
end

function ResourceOverview:GetTotalProducedWater()
	return self.data.total_water_production or 0
end

function ResourceOverview:GetTotalStoredWater()
	return self.data.total_water_storage or 0
end

function ResourceOverview:GetTotalRequiredWater()
	return self.data.total_water_demand or 0
end

function ResourceOverview:GetFoodStoredInServiceBuildings()
	return self.data.food_in_service_buildings or 0
end

function ResourceOverview:GetAvailable(resource_type) --stuff stored in stockpiles + carried by drones + carried by rovers + carried by shuttles
	return RoundDownResourceAmount(self.data[resource_type])
end

function ResourceOverview:GetProducedYesterday(resource_type) --includes both gathered and produced resources
	return RoundDownResourceAmount(self.city.gathered_resources_yesterday[resource_type] + self.data.produced_resources_yesterday[resource_type])
end

function ResourceOverview:GetGatheredYesterday(resource_type) --only gathered resources (includes only surf deps atm)
	return RoundDownResourceAmount(self.city.gathered_resources_yesterday[resource_type])
end

function ResourceOverview:GetConsumedByConsumptionYesterday(resource_type)
	return RoundDownResourceAmount(self.city.consumption_resources_consumed_yesterday[resource_type])
end

function ResourceOverview:GetConsumedByMaintenanceYesterday(resource_type)
	return RoundDownResourceAmount(self.city.maintenance_resources_consumed_yesterday[resource_type])
end

function ResourceOverview:GetEstimatedDailyMaintenance(resource_type)
	if RealTime() - self.estimated_maintenance_time > 500 then
		self.estimated_maintenance_time = RealTime()
		self.estimated_maintenance_res = {}
		MapForEach("map", "RequiresMaintenance",function(bld, resources) bld:GetDailyMaintenance(resources) end, self.estimated_maintenance_res)
	end
	return self.estimated_maintenance_res[resource_type] or 0
end

function ResourceOverview:GetLastExportFunding()
	return (UIColony.funds.funding_gain_last or empty_table)["Export"] or 0
end

function ResourceOverview:GetTotalExportFunding()
	return (UIColony.funds.funding_gain_total or empty_table)["Export"] or 0
end

function ResourceOverview:GatherPerDomeInfo()
	if not self.city then return end
	local domes = self.city.labels.Dome or {}
	local celebrity_count, renegades, martianborn, earthborn, tourists = 0, 0, 0, 0, 0
	local children, adults, youths, middleageds, seniors = 0,0,0,0,0
	for _, dome in ipairs(domes) do
		local labels = dome.labels
		celebrity_count = celebrity_count + (dome.labels.Celebrity and #dome.labels.Celebrity or 0)
		renegades = renegades + (labels.Renegade and #labels.Renegade or 0)
		children    = children    + (labels.Child and #labels.Child or 0)
		youths      = youths      + (labels.Youth and #labels.Youth or 0)
		adults      = adults      + (labels.Adult and #labels.Adult or 0)
		middleageds = middleageds + (labels["Middle Aged"] and #labels["Middle Aged"] or 0)
		seniors     = seniors     + (labels.Senior and #labels.Senior or 0)
		martianborn = martianborn + (labels.Martianborn and #labels.Martianborn or 0)
		tourists    = tourists    + (labels.Tourist and #labels.Tourist or 0)
	end	
	self.data.celebrity_count = celebrity_count
	self.data.renegades       = renegades
	self.data.children        = children
	self.data.adults          = adults
	self.data.youths          = youths
	self.data.middleageds     = middleageds
	self.data.seniors         = seniors
	self.data.martianborn     = martianborn
	self.data.tourists        = tourists
	self.data.colonists       = self:GetColonistCount()
	self.data.earthborn       = self.data.colonists - martianborn
end

local AgeTraitToFieldMapping = {
	Child = "children",
	Youth = "youths",
	Adult = "adults",
	["Middle Aged"] = "middleageds",
	Senior = "seniors",
}

function ResourceOverview:ProcessDomelessColonists()
	if not self.city then return end
	local homeless = self.city.labels.Homeless or empty_table
	local domeless = table.filter(homeless, function(_,colonist) return not colonist.dome end)
	for _,domeless_colonist in ipairs(domeless) do
		if domeless_colonist.traits.Celebrity then self.data.celebrity_count = self.data.celebrity_count + 1 end
		if domeless_colonist.traits.Renegade then self.data.renegades = self.data.renegades + 1 end
		
		local age_field = AgeTraitToFieldMapping[domeless_colonist.age_trait]
		self.data[age_field] = self.data[age_field] + 1
		
		if domeless_colonist.traits.Martianborn then self.data.martianborn = self.data.martianborn + 1 end
		if domeless_colonist.traits.Tourist then self.data.tourists = self.data.tourists + 1 end
	end
end

function ResourceOverview:GatherDronesInfo()
	self.data.drones = self:GetDronesCount()
end

function ResourceOverview:GetLastRareMetalsExportStr()
	if self.city.last_export then
		local t = self.city.last_export
		return T{3611, "Last export<right>Sol <day>, Hour <hour><newline><left>Rare Metals exported<right><preciousmetals(amount)>", day = t.day, hour = t.hour, amount = t.amount}
	else
		return T(3612, "Last export<right>N/A")
	end
end

function ResourceOverview:GetLastExportStr()
	return self:GetLastRareMetalsExportStr()
end

function ResourceOverview:GetRocketRefuelFuelYesterday()
	return self.city.fuel_for_rocket_refuel_yesterday
end

FundingSourceTexts = {
	Celebrity = T(10402, "Celebrities"),
	Sponsor = T(10403, "Sponsor"),
	Export = T(419, "Export"),
	Tourist = T(10404, "Tourists"),
	Building = T(3980, "Buildings"),
	Research = T(311, "Research"),
}

function FundingSourceCombo()
	local items = {{value = "", text = T(10405, "Other")}}
	for source, text in sorted_pairs(FundingSourceTexts) do
		items[#items + 1] = {value = source, text = text}
	end
	return items
end

function ResourceOverview:GetFundingRollover()
	local ret = {
		T{10552, "Funding<right><white><funding(total)></white>", total = UIColony.funds.funding},
		T{3614, "Rare Metals price<right><white><funding(price)></white>", price = g_Consts.ExportPricePreciousMetals*1000000},
		T{3615, "Last Export<right><white><funding(LastExportFunding)></white>", self},
		T{10406, "Total Export<right><funding(TotalExportFunding)>", self },
	}
	local other_sources = 0
	local unknown_amount = 0
	local total_amount = 0
	local sources = 0
	for reason, amount in sorted_pairs(UIColony.funds.funding_gain_sol or empty_table) do
		if amount ~= 0 then
			if sources == 0 then
				ret[#ret + 1] = T(10524, "Last Sol Income:")
			end
			local source = FundingSourceTexts[reason]
			if source then
				other_sources = other_sources + 1
				ret[#ret + 1] = T{10408, "<tab 30><source><right><funding(amount)>", amount = amount, source = source }
			else
				unknown_amount = unknown_amount + amount
			end
			sources = sources + 1
			total_amount = total_amount + amount
		end
	end
	if unknown_amount > 0 then
		ret[#ret + 1] = T{10525, "<tab 30>Other sources<right><funding(amount)>", amount = unknown_amount }
	end
	if sources > 1 then
		ret[#ret + 1] = T{10410, "Total<right><funding(amount)>", amount = total_amount }
	end
	return table.concat(ret, "<newline><left>")
end

function ResourceOverview.GetFunding()
	return UIColony and UIColony.funds:GetFunding() or 0
end

function ResourceOverview:GetAvailableRockets(label)
	local rockets = self.city.labels[label or "SupplyRocket"] or empty_table
	local available = 0
	for i = 1, #rockets do
		if rockets[i]:IsAvailable() then
			available = available + 1
		end
	end
	return available
end

function ResourceOverview:GetAvailablePods()
	return self:GetAvailableRockets("SupplyPod")
end

function ResourceOverview:GetBuildingsCount(label)
	return #(self.city.labels[label or "Building"] or empty_table)
end

function ResourceOverview:GetDomesCount()
	return self:GetBuildingsCount("Dome")
end

function ResourceOverview:GetPowerProducersCount()
	local buildings = self.city.labels["Building"] or empty_table
	local count = 0
	for i=1,#buildings do
		if IsKindOf(buildings[i], "ElectricityProducer") then
			count = count + 1
		end
	end
	return count
end

function ResourceOverview:GetProductionBuildingsCount()
	return self:GetBuildingsCount("Production")
end

function ResourceOverview:GetResearchProgress()
	local research = UIColony
	local queue = research and research:GetResearchQueue() or empty_table
	if not next(queue) then
		return T(9765, "n/a")
	else
		return T{9766, "<percent(number)>", number = research:GetResearchProgress()}
	end
end

function ResourceOverview:GetEstimatedRP()
	return UIColony and UIColony:GetEstimatedRP() or 0
end

function ResourceOverview:GetResearchRolloverItems()
	local ret = {
			T{13807, "Estimated per sol<right><ResearchPoints(EstimatedRP)>", UIColony},
			T{4533, "Sponsor<right><ResearchPoints(EstimatedRP_Sponsor)>", UIColony},
			T{4534, "Outsourcing<right><ResearchPoints(EstimatedRP_Outsource)>", UIColony},
			T{11829, "Research Buildings<right><ResearchPoints(EstimatedRP_ResearchBuildings)>", UIColony},
			T{4537, "Genius Colonists<right><ResearchPoints(EstimatedRP_Genius)>", UIColony},
		}
	if UIColony:IsTechResearched("ExplorerAI") then
		ret[#ret+1] = T{4538, "Explorers<right><ResearchPoints(EstimatedRP_Explorer)>", UIColony}
	end
	if g_Consts.ElectricityForResearchPoint ~= 0 then
		ret[#ret+1] = T{4539, "Excess Power<right><ResearchPoints(EstimatedRP_SuperconductingComputing)>", UIColony}
	end
	Msg("AddResearchRolloverTexts", ret, UIColony)
	return ret
end

function ResourceOverview:GetResearchRollover()
	local ret = self:GetResearchRolloverItems()
	return table.concat(ret, "<newline><left>")
end

function ResourceOverview:GetElectricityStorageCapacity()
	local buildings = MapGet("map","ElectricityStorage", nil, const.efVisible ) 
	local capacity = 0
	for _, building in ipairs(buildings)do
		capacity = capacity + building.capacity
	end
	return capacity
end

function ResourceOverview:GetElectricityGridRollover()
	local stored_power_sols = 0
	if self:GetTotalRequiredPower() > 0 then
		stored_power_sols = self:GetTotalStoredPower() / self:GetTotalRequiredPower()
		stored_power_sols = stored_power_sols * const.HourDuration
	end
	local ret = {
		T(3619, "Power, Water and Oxygen are distributed via Power and Life Support grids.<newline>") ,
		T{13808, "Number of grids<right><number><newline>", number = #(UICity.electricity or empty_table)},
		T{3620, "Power production<right><power(TotalProducedPower)>", self}, 
		T{3621, "Power demand<right><power(TotalRequiredPower)>", self}, 
		T{3622, "Stored Power<right><power(TotalStoredPower)>", self}, 
		T{12597, "Capacity<right><power(ElectricityStorageCapacity)>", self}, 
		T{13809, "Stored Power lasts<right><time(number)>", number = stored_power_sols}, 
	}
	return table.concat(ret, "<newline><left>")
end

function ResourceOverview:GetWaterStorageCapacity()
	local buildings = MapGet("map","WaterStorage", nil, const.efVisible ) 
	local capacity = 0
	for _, building in ipairs(buildings)do
		capacity = capacity + building.water_capacity
	end
	return capacity
end

function ResourceOverview:GetAirStorageCapacity()
	local buildings = MapGet("map","AirStorage", nil, const.efVisible ) 
	local capacity = 0
	for _, building in ipairs(buildings)do
		capacity = capacity + building.air_capacity
	end
	return capacity
end

function ResourceOverview:GetLifesupportGridRollover()
	local stored_water_sols = 0
	local stored_oxygen_sols = 0
	if self:GetTotalRequiredWater() > 0 then
		stored_water_sols = self:GetTotalStoredWater() / self:GetTotalRequiredWater()
		stored_water_sols = stored_water_sols * const.HourDuration
	end
	if self:GetTotalRequiredAir() > 0 then
		stored_oxygen_sols = self:GetTotalStoredAir() / self:GetTotalRequiredAir()
		stored_oxygen_sols = stored_oxygen_sols * const.HourDuration
	end
	local ret = {
		T(3619, "Power, Water and Oxygen are distributed via Power and Life Support grids.<newline>") ,
		T{13808, "Number of grids<right><number><newline>", number = #(UICity.water or empty_table)}, 
		T{3623, "Oxygen production<right><air(TotalProducedAir)>", self}, 
		T{3624, "Oxygen demand<right><air(TotalRequiredAir)>", self}, 
		T{3625, "Stored Oxygen<right><air(TotalStoredAir)>", self},
		T{12598, "Capacity<right><air(AirStorageCapacity)>", self}, 
		T{13810, "Stored Oxygen lasts<right><time(number)>", number = stored_oxygen_sols},
		T(316, "<newline>"),
		T{3626, "Water production<right><water(TotalProducedWater)>", self}, 
		T{3627, "Water demand<right><water(TotalRequiredWater)>", self}, 
		T{3628, "Stored Water<right><water(TotalStoredWater)>", self}, 
		T{12599, "Capacity<right><water(WaterStorageCapacity)>", self}, 
		T{13811, "Stored Water lasts<right><time(number)>", number = stored_water_sols}, 
	}
	return table.concat(ret, "<newline><left>")
end

function ResourceOverview:GetGridRollover()
	local ret = {
		T(3619, "Power, Water and Oxygen are distributed via Power and Life Support grids.<newline>") ,
		T{3620, "Power production<right><power(TotalProducedPower)>", self}, 
		T{3621, "Power demand<right><power(TotalRequiredPower)>", self}, 
		T{3622, "Stored Power<right><power(TotalStoredPower)>", self}, 
		T(316, "<newline>"),
		T{3623, "Oxygen production<right><air(TotalProducedAir)>", self}, 
		T{3624, "Oxygen demand<right><air(TotalRequiredAir)>", self}, 
		T{3625, "Stored Oxygen<right><air(TotalStoredAir)>", self}, 
		T(316, "<newline>"),
		T{3626, "Water production<right><water(TotalProducedWater)>", self}, 
		T{3627, "Water demand<right><water(TotalRequiredWater)>", self}, 
		T{3628, "Stored Water<right><water(TotalStoredWater)>", self}, 
	}
	return table.concat(ret, "<newline><left>")
end

function ResourceOverview:GetPowerNumber()
	return self:GetTotalProducedPower() - self:GetTotalRequiredPower()
end

function ResourceOverview:GetAirNumber()
	return self:GetTotalProducedAir() - self:GetTotalRequiredAir()
end

function ResourceOverview:GetWaterNumber()
	return self:GetTotalProducedWater() - self:GetTotalRequiredWater()
end

function ResourceOverview:GetPowerLine()
	local difference = self:GetPowerNumber()
	if difference >= 0 then
		return T{3629, "Power surplus<right><green><power(number)></green>", number = difference}
	else
		return T{3630, "Power shortage<right><red><power(number)></red>", number = difference}
	end
end

function ResourceOverview:GetAirLine()
	local difference = self:GetAirNumber()
	if difference >= 0 then
		return T{3631, "Oxygen surplus<right><green><air(number)></green>", number = difference}
	else
		return T{3632, "Oxygen shortage<right><red><air(number)></red>", number = difference}
	end
end

function ResourceOverview:GetWaterLine()
	local difference = self:GetWaterNumber()
	if difference >= 0 then
		return T{3633, "Water surplus<right><green><water(number)></green>", number = difference}
	else
		return T{3634, "Water shortage<right><red><water(number)></red>", number = difference}
	end
end

function ResourceOverview:GetBasicResourcesHeading()
	return T(3635, "Basic resource production, consumption and other stats from the <em>last Sol</em>. Resources in consumption buildings are not counted towards the total available amount. Resource maintenance is estimated per Sol.")
end

function ResourceOverview:GetScannedResourcesRollover()
	local ret = {}
	self.city:GatherDiscoveredDepositsTexts(ret)
	return table.concat(ret, "<newline><left>")
end

function ResourceOverview:GetAdvancedResourcesHeading()
	return T(3654, "Advanced resource production, consumption and other stats from the <em>last Sol</em>. Resources in consumption buildings are not counted towards the total available amount. Resource maintenance is estimated per Sol.")
end

function ResourceOverview:GetOtherResourcesHeading()
	return T(12292, "Other resource production, consumption and stats from the <em>last Sol</em>. Resources in consumption buildings are not counted towards the total available amount.")
end

function ResourceOverview:GetSeedsRollover()
	local ret = {
			self:GetOtherResourcesHeading(),
			T(316, "<newline>"),
			T{12085, "Seeds production<right><seeds(SeedsProducedYesterday)>", self},
			T{12293, "Seeds consumption<right><seeds(SeedsConsumedByConsumptionYesterday)>", self},
		}
	return table.concat(ret, "<newline><left>")
end

function ResourceOverview:GetPrefabRollover()
	local ret = {}

	local prefabs = self.city.available_prefabs or empty_table
	for prefab, count in pairs(prefabs) do
		if count > 0 then
			local display_name = BuildingTemplates[prefab].display_name
			ret[#ret + 1] = T{13656, "<u(prefab)><right><prefab(count)>", prefab = display_name, count = count}
		end
	end

	if #ret == 0 then
		ret[1] = T(13657, "No Prefabs available")
	end

	return table.concat(ret, "<newline><left>")
end

function ResourceOverview:GetCheatsRollover()
	local ret = {}
	for source, mod in pairs(self.city.label_modifiers.Consts or empty_table) do
		ret[#ret + 1] = string.format("<left>%s<right>%d, %d%%, %s", mod.prop, mod.amount, mod.percent, mod.id or "")
	end
	return Untranslated(table.concat(ret, '\n'))
end

function ResourceOverview:CreateCheatActions(win)
	return InfopanelObj.CreateCheatActions(self, win) or true
end

for i = 1, #AllResourcesList do
	local r_n = AllResourcesList[i]
	
	ResourceOverview["Get" .. r_n .. "ProducedYesterday"] = function(self)
		return self:GetProducedYesterday(r_n)
	end
	
	ResourceOverview["Get" .. r_n .. "GatheredYesterday"] = function(self)
		return self:GetGatheredYesterday(r_n)
	end
	
	ResourceOverview["Get" .. r_n .. "ConsumedByConsumptionYesterday"] = function(self)
		return self:GetConsumedByConsumptionYesterday(r_n)
	end
	
	-- TODO: change the strings "ConsumedByMaintenanceYesterday" with "EstimatedDailyMaintenance"
	ResourceOverview["Get" .. r_n .. "ConsumedByMaintenanceYesterday"] = function(self)
		return self:GetEstimatedDailyMaintenance(r_n)
	end
	
	ResourceOverview["GetAvailable" .. r_n] = function(self)
		return self:GetAvailable(r_n)
	end
	
	ResourceOverview["Get" .. r_n .. "InConstructionSitesActual"] = function(self)
		return self:GetInConstructionSites(r_n, "actual")
	end
	
	ResourceOverview["Get" .. r_n .. "InConstructionSitesTotal"] = function(self)
		return self:GetInConstructionSites(r_n, "total")
	end
	
	ResourceOverview["Get" .. r_n .. "UpgradeConstructionActual"] = function(self)
		return self:GetUpgradeConstruction(r_n, "actual")
	end
	
	ResourceOverview["Get" .. r_n .. "UpgradeConstructionTotal"] = function(self)
		return self:GetUpgradeConstruction(r_n, "total")
	end
end

--------- colonists--------------
function ResourceOverview:GetColonistCount()
	return #(self.city.labels.Colonist or empty_table)
end

function ResourceOverview:GetTouristCount()
    local tourists = self:GetAllTourists()
    return #tourists
end
	
function ResourceOverview:GetDronesCount()
	return #(self.city.labels.Drone or empty_table)
end

function ResourceOverview:GetFreeLivingSpace()
	return GetFreeLivingSpace(self.city)
end

function ResourceOverview:GetFreeLivingSpaces()
	return GatherFreeLivingSpaces(self.city.labels.Residence or empty_table)
end

function ResourceOverview:GetClosedLivingSpace()
	local closed = 0
	for _, home in ipairs(self.city.labels.Residence or empty_table) do
		if not home.destroyed then
			closed = closed + home.closed
		end
	end
	return closed
end

function ResourceOverview:GetHomelessColonists()
	local city_labels = self.city.labels
	return city_labels.Homeless and #city_labels.Homeless or 0
end

function ResourceOverview:GetFreeWorkplaces()
	return GetFreeWorkplaces(self.city)
end

function ResourceOverview:GetUnemployedColonists()
	local city_labels = self.city.labels
	return city_labels.Unemployed and #city_labels.Unemployed or 0
end

function ResourceOverview:GetDetrimentalColonistsCount()
	return #GetDetrimentalStatusColonists(self.city)
end

function ResourceOverview:GetEmploymentMessage()
	local city_labels = self.city.labels
	local unemployed = city_labels.Unemployed and #city_labels.Unemployed or 0
	local vacant_on, vacant_off = GetFreeWorkplaces(self.city)
	if unemployed > 0 then
		return T{566, "Unemployed<right><unemployed(number)>", number = unemployed}
	elseif vacant_on > 0 then
		return T{567, "Vacant work slots<right><work(number)>", number = vacant_on}
	elseif vacant_off > 0 then
		return T{568, "Disabled work slots<right><work(number)>", number = vacant_off}
	elseif city_labels.Colonist and #city_labels.Colonist > 0 then
		return T(569, "No unemployment, no vacant workplaces")
	end
	return ""
end

function ResourceOverview:GetUnemployedBtnEnabled()
	local city_labels = self.city.labels
	return city_labels.Unemployed and #city_labels.Unemployed>0 or false
end

function ResourceOverview:GetHomelessBtnEnabled()
	local city_labels = self.city.labels
	return city_labels.Homeless and #city_labels.Homeless>0 or false
end

function ResourceOverview:GetAverageHealth() return GetAverageStat(self.city.labels.Colonist, "Health") end
function ResourceOverview:GetAverageSanity() return GetAverageStat(self.city.labels.Colonist, "Sanity") end
function ResourceOverview:GetAverageComfort() return GetAverageStat(self.city.labels.Colonist, "Comfort") end
function ResourceOverview:GetAverageMorale() return GetAverageStat(self.city.labels.Colonist, "Morale") end
function ResourceOverview:GetAverageSatisfaction() return GetAverageStat(self.city.labels.Colonist, "Satisfaction") end

function ResourceOverview:GetJobsText()
	local city_labels = self.city.labels
	local ui_on_vacant, ui_off_vacant = GetFreeWorkplaces(self.city)
	local renegades = rawget(self.data,"renegades")
	if not renegades then
		renegades = 0
		for _, dome in ipairs(self.city.labels.Dome) do
			renegades = renegades + (dome.labels.Renegade and #dome.labels.Renegade or 0)
		end
	end
	local texts = {
		T{548, "Unemployed, seeking work<right><unemployed(number)>", number = city_labels.Unemployed and #city_labels.Unemployed or 0, empty_table},
		T{549, "Vacant work slots<right><work(number)>",  number = ui_on_vacant},
		T{550, "Disabled work slots<right><work(number)>",  number = ui_off_vacant},
		T{7346, "Renegades<right><colonist(number)>", number = renegades},
		T(3879, "Earthsick") .. T{9719, "<right><colonist(number)>", number = #g_EarthSickColonists[self.city.map_id]},
	}	
	if city_labels.Workshop and next(city_labels.Workshop) then
		texts[#texts +1] = T{8802, "Workers in Workshops<right><percent(WorkshopWorkersPercent)>", self.city}		
	end
	return table.concat(texts, "<newline><left>")
end

function ResourceOverview:GetLivingSpaceText()
	local city_labels = self.city.labels
	local free_residences = self:GetFreeLivingSpaces()
	local free_exclusive = free_residences.exclusive
	local free_nursery = free_residences.traits.Child or 0
	local free_retirement = free_residences.traits.Senior or 0
	local free_hotels = free_residences.traits.Tourist or 0

	local texts = {
		T{552, "Vacant residential slots<right><home(number)>", number = free_exclusive},
		T{7624, "Vacant nursery slots<right><home(number)>", number = free_nursery},
		T{12904, "Vacant hotel slots<right><home(number)>", number = free_hotels},
		T{12903, "<if_all(has_dlc('kerwin'))>Vacant retirement home slots<right><home(number)></if>", number = free_retirement},
		T{551, "Homeless<right><homeless(number)>",   number = city_labels.Homeless and #city_labels.Homeless or 0},
	}
	return table.concat(texts, "<newline><left>")
end

function ResourceOverview:GetAllTourists()
	local tourists = {}
	for _, colonist in ipairs(self.city.labels.Colonist or empty_table) do
		if colonist.traits.Tourist then
			table.insert(tourists, colonist)
		end
	end
	return tourists
end

function ResourceOverview:GetHomesRollover()
	local free_residences = self:GetFreeLivingSpaces()
	local free_exclusive = free_residences.exclusive
	local free_nursery = free_residences.traits.Child or 0
	local free_retirement = free_residences.traits.Senior or 0
	local free_hotels = free_residences.traits.Tourist or 0
	local closed_slots = self:GetClosedLivingSpace()
	local city_labels = self.city.labels
	
	local texts = {	
		T{7623, "<newline><center><em>Living space</em>", newline = ""},
		T{552, "Vacant residential slots<right><home(number)>", number = free_exclusive },
		T{7624, "Vacant nursery slots<right><home(number)>",    number = free_nursery },
		T{12904, "Vacant hotel slots<right><home(number)>", number = free_hotels},
		T{12903, "<if_all(has_dlc('kerwin'))>Vacant retirement home slots<right><home(number)></if>", number = free_retirement},
		T{551, "Homeless<right><homeless(number)>",                 number = city_labels.Homeless and #city_labels.Homeless or 0 },
		T{10532, "Disabled residential slots<right><homeless(number)>", number = closed_slots },
	}
	return table.concat(texts, "<newline><left>")
end

function ResourceOverview:GetJobsRollover()
	local data = self.data
	local ui_on_vacant, ui_off_vacant = GetFreeWorkplaces(self.city)
	local city_labels = self.city.labels
	local earthsick = #(g_EarthSickColonists[self.city.map_id] or empty_table)
	local tourists = rawget(self.data, "tourists")
	local renegades = rawget(self.data, "renegades")
	if not renegades or not tourists then
		renegades = 0
		tourists = 0
		for _, dome in ipairs(city_labels.Dome) do
			renegades = renegades + (dome.labels.Renegade and #dome.labels.Renegade or 0)
			tourists = tourists + (dome.labels.Tourist and #dome.labels.Tourist or 0)
		end
	end
	local temporaryill = 0
	for _, col in ipairs(city_labels.Colonist or empty_table) do
		if col:IsTemporaryIll() then
			temporaryill = temporaryill + 1
		end
	end
	
	local texts = {	
		T(11711, "<center><em>Jobs</em>"),
		T{548, "Unemployed, seeking work<right><unemployed(number)>", number = city_labels.Unemployed and #city_labels.Unemployed or 0 },
		T{549, "Vacant work slots<right><work(number)>",        number = ui_on_vacant },
		T{550, "Disabled work slots<right><work(number)>",      number = ui_off_vacant },
		T{7346, "Renegades<right><colonist(number)>",               number = renegades },
		T{11700, "Earthsick<right><colonist(number)>", number = earthsick},
		T{12707, "Tourists<right><tourist(number)>", number = tourists },
		T{12481, "Temporarily ill<right><colonist(number)>", number = temporaryill},
		T(316, "<newline>"),
		T(7622, "<center><em>Specialization / Vacancies</em>"),
	}
	texts[#texts+1] = T{7858, "<specialization><right><colonist(number)>", specialization = const.ColonistSpecialization["none"].display_name_plural, number = #(self.city.labels["none"] or empty_table)}
	for id, spec in sorted_pairs(const.ColonistSpecialization) do
		if id~="none" then
			local vacant_specialized_work, occupied_specialized_work = GetFreeWorkplaces(self.city, id)
			local num_colonists = #(self.city.labels[id] or empty_table)
			texts[#texts+1] = T{13812, "<specialization><right><colonist(number)> / <work(vacant)>", specialization = spec.display_name_plural, number = num_colonists, vacant = vacant_specialized_work}
		end
	end
	return table.concat(texts, "<newline><left>")
end

-----------------------traits--------------
function ResourceOverview:GetSpecializationsText()
	local texts = {}
	texts[#texts+1] = T{7858, "<specialization><right><colonist(number)>", specialization = const.ColonistSpecialization["none"].display_name_plural, number = #(self.city.labels["none"] or empty_table)}
	for id, spec in sorted_pairs(const.ColonistSpecialization) do
		if id~="none" then
			local num_colonists = #(self.city.labels[id] or empty_table)
			texts[#texts+1] = T{7858, "<specialization><right><colonist(number)>", specialization = spec.display_name_plural, number = num_colonists}
		end
	end
	return #texts>0 and table.concat(texts, "<newline><left>") or T(6761, "None")
end

function ResourceOverview:CalcColonistsTraits()
	if not self.city then return end
	local traits_count = {["Positive"] = {}, ["Negative"] = {}, ["rare"] = {}}
	--local max = {["Positive"] = {}, ["Negative"] = {}, ["rare"] = {}}
	ForEachPreset(TraitPreset, function(trait, group_list)
		local in_category = trait.group=="Positive" or trait.group=="Negative" 
		if in_category or trait.rare then
			for _, dome in ipairs(self.city.labels.Dome) do
				local count = #(dome.labels[trait.id] or empty_table)
				if count>0 then
					if in_category then
						traits_count[trait.group][trait.id] = (traits_count[trait.group][trait.id] or 0) + count
					--	local max_incategory = max[trait.group]
					--	if #max_incategory<4 then
					--		max_incategory[#max_incategory + 1] = {trait.id, count}
					--	elseif count>max_incategory[#max_incategory] then
							
					--	end
					end	
					if trait.rare then
						traits_count.rare[trait.id] = (traits_count.rare[trait.id] or 0) + count
					end	
				end	
			end
		end
	end)
	self.data.traits_count = traits_count
	return traits_count
end

function ResourceOverview:CalcConsumptionProduction()
	local gtime = GameTime()
	local data = self.data
	if GameTime() - (data.last_averages_gtime or 0) > 0 then
		--update resource demand with the other side consumption
		data.total_power_demand = data.total_power_demand + self:GetExcessOtherSideConsumption("electricity")
		data.total_water_demand = data.total_water_demand + self:GetExcessOtherSideConsumption("water")
		data.total_air_demand = data.total_air_demand + self:GetExcessOtherSideConsumption("air")
		-- "consumption" below actually means "demand" - not changing to preserve savegames
		data.total_power_production_sum = (data.total_power_production_sum or 0) + data.total_power_production
		data.total_power_consumption_sum = (data.total_power_consumption_sum or 0) + data.total_power_demand
		data.total_water_production_sum = (data.total_water_production_sum or 0) + data.total_water_production
		data.total_water_consumption_sum = (data.total_water_consumption_sum or 0) + data.total_water_demand
		data.total_air_production_sum = (data.total_air_production_sum or 0) + data.total_air_production
		data.total_air_consumption_sum = (data.total_air_consumption_sum or 0) + data.total_air_demand
		data.total_grid_samples = (data.total_grid_samples or 0) + 1
		data.last_averages_gtime = gtime
	end
end

function ResourceOverview:GetPerksText()
	local traits_count = rawget(self.data, "traits_count") or self:CalcColonistsTraits()
	local t = GetComboItems(traits_count.Positive)
	table.sort(t, function(a,b) return a.text>b.text end )
	local texts = {}
	for i=1, Min(4,#t) do
		texts[#texts + 1] = T{7859, "<trait><right><colonist(number)>", trait =  TraitPresets[t[i].value].display_name, number = t[i].text}
	end
	return #t>0 and table.concat(texts, "<newline><left>") or T(6761, "None")
end

function ResourceOverview:GetPerksRolloverText()
	local traits_count = rawget(self.data, "traits_count") or self:CalcColonistsTraits()
	local t = GetComboItems(traits_count.Positive)
	table.sort(t, function(a,b) return a.text>b.text end )
	local texts = { T(7861, --[[XTemplate ipTraitsOverview RolloverText]] "Perks are beneficial traits, representing various talents and abilities of your Colonists."),}
	for i=1, #t do
		texts[#texts + 1] = T{7859, "<trait><right><colonist(number)>", trait =  TraitPresets[t[i].value].display_name, number = t[i].text}
	end
	return table.concat(texts, "<newline><left>")
end

function ResourceOverview:GetFlawsText()
	local traits_count = rawget(self.data, "traits_count") or self:CalcColonistsTraits()
	local t = GetComboItems(traits_count.Negative)
	table.sort(t, function(a,b) return a.text>b.text end )
	local texts = {}
	for i=1, Min(4,#t) do
		texts[#texts + 1] = T{7859, "<trait><right><colonist(number)>", trait = TraitPresets[t[i].value].display_name, number = t[i].text}
	end
	return #t>0 and table.concat(texts, "<newline><left>") or T(6761, "None")
end

function ResourceOverview:GetFlawsRolloverText()
	local traits_count = rawget(self.data, "traits_count") or self:CalcColonistsTraits()
	local t = GetComboItems(traits_count.Negative)
	table.sort(t, function(a,b) return a.text>b.text end )
	local texts = {T(7862, --[[XTemplate ipTraitsOverview RolloverText]] "Flaws are Detrimental traits, representing various flaws and disabilities of your Colonists.")}
	for i=1, #t do
		texts[#texts + 1] = T{7859, "<trait><right><colonist(number)>", trait = TraitPresets[t[i].value].display_name, number = t[i].text}
	end
	return table.concat(texts, "<newline><left>")
end

function ResourceOverview:GetRareTraits()
	local traits_count = rawget(self.data, "traits_count") or self:CalcColonistsTraits()
	local t = GetComboItems(traits_count.rare)
	table.sort(t, function(a,b) return a.text>b.text end )
	local texts = {}
	for i=1, Min(4,#t) do
		texts[#texts + 1] = T{7859, "<trait><right><colonist(number)>", trait = TraitPresets[t[i].value].display_name, number = t[i].text}
	end
	return #t>0 and table.concat(texts, "<newline><left>") or T(6761, "None")
end

function ResourceOverview:GetRareTraitsRollover()
	local traits_count = rawget(self.data, "traits_count") or self:CalcColonistsTraits()
	local t = GetComboItems(traits_count.rare)
	table.sort(t, function(a,b) return a.text>b.text end )
	local texts = {T(7863, --[[XTemplate ipTraitsOverview RolloverText]] "Rare traits denote exceptional citizens that have significant impact on your Colony.")}
	for i=1, #t do
		texts[#texts + 1] = T{7859, "<trait><right><colonist(number)>", trait = TraitPresets[t[i].value].display_name, number = t[i].text}
	end
	return table.concat(texts, "<newline><left>")
end

------------------------------------------------------------------
function ResourceOverview:GetFirstWithDetrimentalStatusEffect()
	return GetDetrimentalStatusColonists(self.city, true)
end

function ResourceOverview:GetHomelessRolloverTitle()
	return T{7864, --[[Post-Cert]] "Homeless colonists: <homeless(number)>", number = #(self.city.labels.Homeless or empty_table)}
end

function ResourceOverview:GetHomelessRolloverText()
	if #(self.city.labels.Homeless or empty_table)>0 then
		return T(9624, --[[Post-Cert]] "Inspect all homeless colonists in the Command Center.")
	else	
		return T(7866, --[[Post-Cert]] "There are no homeless colonists.")
	end	
end

function ResourceOverview:GetUnemployedRolloverTitle()
	return T{7867, --[[Post-Cert]] "Unemployed colonists: <unemployed(number)>", number = #(self.city.labels.Unemployed or empty_table)}
end

function ResourceOverview:GetUnemployedRolloverText()
	if #(self.city.labels.Unemployed or empty_table)>0 then
		return T(9625, --[[Post-Cert]] "Inspect all unemployed colonists in the Command Center.")
	else	
		return T(7869, --[[Post-Cert]] "There are no unemployed colonists.")
	end	
end

function ResourceOverview:GetProblematicRolloverTitle()
	return T{7870, --[[Post-Cert]] "Problematic colonists: <colonist(number)>", number = #(GetDetrimentalStatusColonists(self.city))}
end

function ResourceOverview:GetProblematicRolloverText()
	if self:GetFirstWithDetrimentalStatusEffect() then
		return T(9626, --[[Post-Cert]] "Inspect all colonists suffering from status effects in the Command Center.")
	else	
		return T(7971, --[[Post-Cert]] "There are no colonists suffering from status effects.")
	end	
end

function ResourceOverview:OnShortcut(shortcut, source)
	if shortcut == "RightTrigger-ButtonA" then
		SetResourceOverviewDlgMode("ResourceOverview")
		return "break"
	elseif shortcut == "RightTrigger-ButtonX" then
		SetResourceOverviewDlgMode("ColonistOverview")
		return "break"
	elseif shortcut == "RightTrigger-ButtonY" then
		SetResourceOverviewDlgMode("TraitsOverview")
		return "break"		
	end		
end	
--------------------------------
function IsColonyOverviewOpened()
	local infopanel = GetDialog("Infopanel")
	return infopanel and IsKindOf(infopanel.context, "ResourceOverview")
end

function GetColonyOverviewDlg()
	local infopanel = GetDialog("Infopanel")
	return infopanel and IsKindOf(infopanel.context, "ResourceOverview") and infopanel
end

function SetResourceOverviewDlgMode(mode)
	InfopanelSlideIn = false
	GetCityResourceOverview(self.city).overview = mode
	local dlg = GetColonyOverviewDlg()
	if dlg and dlg.Mode ~= mode then
		dlg:SetMode(mode)
	end
	ObjModified(GetCityResourceOverview(self.city))
end

function OpenResourceOverviewInfopanel(parent)
	if not IsColonyOverviewOpened() then
		local dlg = OpenXInfopanel(parent, GetCityResourceOverview(self.city), "ipResourceOverview")
		local mode = GetCityResourceOverview(self.city):GetIPMode()
		if mode and dlg.Mode ~= mode then
			dlg:SetMode(mode)
		end
	end
end

function CloseResourceOverviewInfopanel()
	if IsColonyOverviewOpened() then
		CloseXInfopanel()
		if SelectedObj and GetInGameInterfaceMode() ~= "overview" then
			ReopenSelectionXInfopanel()
		end
	end
end
---
function ResourceOverview:GetInConstructionSites(resource_type, function_type)
	local construction_labels = {
		self.city.labels.ConstructionSite,
		self.city.labels.ConstructionSiteWithHeightSurfaces,
		self.city.labels.ConstructionGroupLeader,
	}
	local result = 0
	for _,label in pairs(construction_labels) do
		for _,site in ipairs(label or empty_table) do
			local resources = site.construction_resources
			if resources and resources[resource_type] then
				local target = site.construction_costs_at_start[resource_type]
				if function_type == "actual" then
					local actual = site.construction_resources[resource_type]:GetActualAmount()
					result = result + (target - actual)
				else
					result = result + target
				end
			end
		end
	end
	return result
end

function ResourceOverview:GetUpgradeConstruction(resource_type, function_type)
	local result = 0
	for _,bld in ipairs(self.city.labels.Building or empty_table) do
		for name,upgrade in pairs(bld.upgrades_under_construction or empty_table) do
			local target = bld:GetUpgradeCost(bld:GetUpgradeTier(name), resource_type)
			if target > 0 then
				for _,request in ipairs(upgrade.reqs) do
					if request:GetResource() == resource_type then
						if function_type == "actual" then
							local actual = request:GetActualAmount()
							result = result + (target - actual)
						else
							result = result + target
						end
					end
				end
			end
		end
	end
	return result
end

function ResourceOverview:GetExcessOtherSideConsumption(grid_type)
	local buildings = self.city.labels.GridTransfer or empty_table
	local other_side_consumption = 0
	local stored_other_side_grid = false
	for _, building in ipairs(buildings) do
		local building_other_side_grid = building.other.grids[grid_type].grid
		if building_other_side_grid and stored_other_side_grid ~= building_other_side_grid then
			other_side_consumption = other_side_consumption + building:GetOtherSideConsumption(grid_type)
		end
		stored_other_side_grid = building_other_side_grid
	end
	return other_side_consumption
end
