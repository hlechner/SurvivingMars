DefineClass.ResourceTracking = {
	--tracked resource usage
	gathered_resources_today = false,
	gathered_resources_yesterday = false, --from surf deps, also it's more like current sol.
	gathered_resources_total = false,
	consumption_resources_consumed_yesterday = false,
	consumption_resources_consumed_today = false,
	maintenance_resources_consumed_yesterday = false,
	maintenance_resources_consumed_today = false,
	last_export = false, --last precious metals export info
	total_export = 0,    --total exported precious metals, in resource units
	fuel_for_rocket_refuel_today = 0,
	fuel_for_rocket_refuel_yesterday = 0,

	-- time series logs for bar graphs in CCC
	ts_colonists = false,
	ts_colonists_unemployed = false,
	ts_colonists_homeless = false,
	ts_drones = false,
	ts_shuttles = false,
	ts_buildings = false,
	ts_constructions_completed = false,
	ts_resources_stockpile = false,
	ts_resources_grid = false,
	constructions_completed_today = false,	
}


-------------- gathered resources
function ResourceTracking:InitGatheredResourcesTables()
	--conditional init so it can be used on save game load.
	self.gathered_resources_total = self.gathered_resources_total or {}
	self.gathered_resources_yesterday = self.gathered_resources_yesterday or {}
	self.gathered_resources_today = self.gathered_resources_today or {}
	self.consumption_resources_consumed_today = self.consumption_resources_consumed_today or {}
	self.consumption_resources_consumed_yesterday = self.consumption_resources_consumed_yesterday or {}
	self.maintenance_resources_consumed_today = self.maintenance_resources_consumed_today or {}
	self.maintenance_resources_consumed_yesterday = self.maintenance_resources_consumed_yesterday or {}
	
	for i = 1, #AllResourcesList do
		local r_n = AllResourcesList[i]
		self.gathered_resources_total[r_n] = self.gathered_resources_total[r_n] or 0
		self.gathered_resources_today[r_n] = self.gathered_resources_today[r_n] or 0
		self.gathered_resources_yesterday[r_n] = self.gathered_resources_yesterday[r_n] or 0
		self.consumption_resources_consumed_today[r_n] = self.consumption_resources_consumed_today[r_n] or 0
		self.consumption_resources_consumed_yesterday[r_n] = self.consumption_resources_consumed_yesterday[r_n] or 0
		self.maintenance_resources_consumed_today[r_n] = self.maintenance_resources_consumed_today[r_n] or 0
		self.maintenance_resources_consumed_yesterday[r_n] = self.maintenance_resources_consumed_yesterday[r_n] or 0
	end
end

function ResourceTracking:GatheredResourcesOnDailyUpdate()
	for i = 1, #AllResourcesList do
		local r_n = AllResourcesList[i]
		self.gathered_resources_yesterday[r_n] = self.gathered_resources_today[r_n]
		self.gathered_resources_today[r_n] = 0
		
		self.consumption_resources_consumed_yesterday[r_n] = self.consumption_resources_consumed_today[r_n]
		self.consumption_resources_consumed_today[r_n] = 0
		
		self.maintenance_resources_consumed_yesterday[r_n] = self.maintenance_resources_consumed_today[r_n]
		self.maintenance_resources_consumed_today[r_n] = 0
	end
	
	self.fuel_for_rocket_refuel_yesterday = self.fuel_for_rocket_refuel_today
	self.fuel_for_rocket_refuel_today = 0
end

function ResourceTracking:OnResourceGathered(r_type, r_amount)
	self.gathered_resources_today[r_type] = self.gathered_resources_today[r_type] + r_amount
	self.gathered_resources_total[r_type] = self.gathered_resources_total[r_type] + r_amount
	Msg("ResourceGathered", r_type, r_amount)
end

function ResourceTracking:OnConsumptionResourceConsumed(r_type, r_amount)
	self.consumption_resources_consumed_today[r_type] = self.consumption_resources_consumed_today[r_type] + r_amount
end

function ResourceTracking:OnMaintenanceResourceConsumed(r_type, r_amount)
	self.maintenance_resources_consumed_today[r_type] = self.maintenance_resources_consumed_today[r_type] + r_amount
end

function ResourceTracking:MarkPreciousMetalsExport(amount)
	if amount <= 0 then return end
	self.last_export = {amount = amount, day = UIColony.day, hour = UIColony.hour, minute = UIColony.minute}
	self.total_export = self.total_export + amount
	Msg("MarkPreciousMetalsExport", self, amount, self.total_export)
end

function ResourceTracking:FuelForRocketRefuelingDelivered(amount)
	self.fuel_for_rocket_refuel_today = self.fuel_for_rocket_refuel_today + amount
end

function ResourceTracking:InitTimeSeries()
	self.ts_colonists = TimeSeries:new()
	self.ts_colonists_unemployed = TimeSeries:new()
	self.ts_colonists_homeless = TimeSeries:new()
	self.ts_drones = TimeSeries:new()
	self.ts_shuttles = TimeSeries:new()
	self.ts_buildings = TimeSeries:new()
	self.ts_constructions_completed = TimeSeries:new()
	self.ts_resources = {}
	for _, resource in ipairs(GetStockpileResourceList()) do
		self.ts_resources[resource] = {
			stockpile = TimeSeries:new(),
			produced = TimeSeries:new(),
			consumed = TimeSeries:new()
		}
	end
	self.ts_resources_grid = {}
	for _, resource in ipairs{"water", "air", "electricity"} do
		self.ts_resources_grid[resource] = {
			stored = TimeSeries:new(),
			production = TimeSeries:new(),
			consumption = TimeSeries:new(),
		}
	end
end

function ResourceTracking:UpdateTimeSeries()
	if UIColony.day == 1 then return end

	self.ts_colonists:AddValue(#(self.labels.Colonist or empty_table))
	self.ts_colonists_unemployed:AddValue(#(self.labels.Unemployed or empty_table))
	self.ts_colonists_homeless:AddValue(#(self.labels.Homeless or empty_table))
	self.ts_drones:AddValue(#(self.labels.Drone or empty_table))

	self.ts_shuttles:AddValue(self:CountShuttles())
	self.ts_buildings:AddValue(self:CountBuildings())
	self.ts_constructions_completed:AddValue(self.constructions_completed_today)
	self.constructions_completed_today = 0

	local resource_overview_obj = GetCityResourceOverview(self)
	for _, resource in ipairs(GetStockpileResourceList()) do
		local ts_resource = self.ts_resources[resource]
		ts_resource.stockpile:AddValue(resource_overview_obj:GetAvailable(resource))
		ts_resource.produced:AddValue(resource_overview_obj:GetProducedYesterday(resource))
		ts_resource.consumed:AddValue(resource_overview_obj:GetConsumedByConsumptionYesterday(resource) + resource_overview_obj:GetConsumedByMaintenanceYesterday(resource))
	end
	local water, air, electricity = self.ts_resources_grid.water, self.ts_resources_grid.air, self.ts_resources_grid.electricity
	water.stored:AddValue(resource_overview_obj:GetTotalStoredWater())
	air.stored:AddValue(resource_overview_obj:GetTotalStoredAir())
	electricity.stored:AddValue(resource_overview_obj:GetTotalStoredPower())
	
	local data = resource_overview_obj.data
	if data.total_grid_samples > 0 then
		air.consumption:AddValue(data.total_air_consumption_sum / data.total_grid_samples)
		air.production:AddValue(data.total_air_production_sum / data.total_grid_samples)
		electricity.consumption:AddValue(data.total_power_consumption_sum / data.total_grid_samples)
		electricity.production:AddValue(data.total_power_production_sum / data.total_grid_samples)
		water.consumption:AddValue(data.total_water_consumption_sum / data.total_grid_samples)
		water.production:AddValue(data.total_water_production_sum / data.total_grid_samples)
		data.total_air_consumption_sum = 0
		data.total_air_production_sum = 0
		data.total_power_consumption_sum = 0
		data.total_power_production_sum = 0
		data.total_water_consumption_sum = 0
		data.total_water_production_sum = 0
		data.total_grid_samples = 0
	end
end

function ResourceTracking:GatheredResourcesOnHourlyUpdate(map_id)
	local maintenance_resources = self.maintenance_resources_consumed_yesterday
	local transportable_resources = {}
	local resource_overview = GetCityResourceOverview(self)	
	GatherTransportableResources(transportable_resources, self)
	for k,v in pairs(maintenance_resources) do
		if v > 0 and (transportable_resources[k] / v) < const.MinDaysMaintenanceSupplyBeforeNotification then
			RequestNewObjsNotif(g_InsufficientMaintenanceResources, k, map_id)
		else
			DiscardNewObjsNotif(g_InsufficientMaintenanceResources, k, map_id)
		end
	end

	-- food
	local food_consumed = resource_overview:GetFoodConsumedByConsumptionYesterday()
	local food_total = resource_overview:GetAvailableFood()
	if food_total>0 and food_consumed>0 and (food_total/food_consumed) < const.MinDaysFoodSupplyBeforeNotification then
		RequestNewObjsNotif(g_InsufficientMaintenanceResources, "Food", map_id)
	else
		DiscardNewObjsNotif(g_InsufficientMaintenanceResources, "Food", map_id)
	end
	
	-- water, power, oxygen
	local water_stored = resource_overview:GetTotalStoredWater()
	local air_stored = resource_overview:GetTotalStoredAir()
	local el_stored = resource_overview:GetTotalStoredPower()
    
	local ts_grid = self.ts_resources_grid
	local ts_grid_air,ts_grid_el,ts_grid_water = ts_grid.air,ts_grid.electricity,ts_grid.water
	local air_consumption   = ts_grid_air.consumption:GetLastValue()
	local air_production    = ts_grid_air.production:GetLastValue()
	local el_consumption    = ts_grid_el.consumption:GetLastValue()
	local el_production     = ts_grid_el.production:GetLastValue()
	local water_consumption = ts_grid_water.consumption:GetLastValue()
	local water_production  = ts_grid_water.production:GetLastValue()
	
	--water
	if const.MinHoursWaterResourceSupplyBeforeNotification*(water_consumption - water_production) > water_stored then
		RequestNewObjsNotif(g_InsufficientMaintenanceResources, "Water", map_id)
	else
		DiscardNewObjsNotif(g_InsufficientMaintenanceResources, "Water", map_id)
	end
   -- air
	if const.MinHoursAirResourceSupplyBeforeNotification*(air_consumption - air_production) > air_stored then
		RequestNewObjsNotif(g_InsufficientMaintenanceResources, "Air", map_id)
	else
		DiscardNewObjsNotif(g_InsufficientMaintenanceResources, "Air", map_id)
	end
   -- power
	if const.MinHoursPowerResourceSupplyBeforeNotification*(el_consumption - el_production) > el_stored then
		RequestNewObjsNotif(g_InsufficientMaintenanceResources, "Power", map_id)
	else
		DiscardNewObjsNotif(g_InsufficientMaintenanceResources, "Power", map_id)
	end
end

function OnMsg.ConstructionComplete(bld)
	bld.city.constructions_completed_today = (bld.city.constructions_completed_today or 0) + 1
end

function CalcInsufficientResourcesNotifParams(displayed_in_notif)
	local params = {}
	local resource_names = {}
	for _, name in ipairs(displayed_in_notif) do
		resource_names[#resource_names + 1] = TLookupTag("<icon_" .. name .. ">")
	end
	params.low_on_resource_text = #resource_names == 1 and T(839, "Resource:") or T(840, "Resources:")
	params.resources = table.concat(resource_names, " ")
	params.rollover_title = T(5640, "Low Storage")
	params.rollover_text = T(10371, "Stored resources expected to last less than 3 Sols.")
	return params
end

GlobalVar("g_InsufficientMaintenanceResources", {})
GlobalGameTimeThread("InsufficientMaintenanceResourcesNotif", function()
	HandleNewObjsNotif(g_InsufficientMaintenanceResources, "InsufficientMaintenanceResources", nil, CalcInsufficientResourcesNotifParams, false, nil, true)
end)
