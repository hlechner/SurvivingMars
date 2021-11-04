DefineClass.GridTransfer = {
	__parents = {
		"InitDone",
		"Building"
	},

	other = false,
	grids = false
}

function GridTransfer:GameInit()
	self.grids = {}
end

function GridTransfer:InitGridTransfer(other)
	self.other = other	
end

function GridTransfer:AddToCityLabels()
	self.city:AddToLabel("GridTransfer", self)
end

function GridTransfer:RemoveFromCityLabels()
	self.city:RemoveFromLabel("GridTransfer", self)
end

function GridTransfer:UpdateResourceTransfer(grid_type)
	--checked grid and other side
	local other_transfer = self:IsOtherTransferInGrid(grid_type)

	local resource_available_to_send = 0
	local resource_needed = 0

	resource_needed, resource_available_to_send = self:GetCurrentGridResource(grid_type)

	local resource_excess_sent = 0
	local resource_shortage = 0
	-- If there is other transfer then divide the resource in base to the priority and shortage of the other side
	if other_transfer then
		resource_excess_sent, resource_shortage = self:DivideResourceExcess(other_transfer, resource_available_to_send, resource_needed, grid_type)
	else
		resource_excess_sent = Max(resource_available_to_send, 0) 
		resource_shortage = resource_needed
	end

	return resource_excess_sent, resource_shortage
end

function GridTransfer:DivideResourceExcess(other_transfer, resource_available_to_send, resource_needed, grid_type)
	local resource_excess_sent = 0
	local resource_shortage = 0
	local other_transfer_resource_needs = 0 
	local current_transfer_resource_needs = 0 
	other_transfer_resource_needs = other_transfer.other:GetCurrentGridResource(grid_type)
	current_transfer_resource_needs = self.other:GetCurrentGridResource(grid_type)
	local both_sides_connected = false

	if self.other.grids[grid_type].grid == other_transfer.other.grids[grid_type].grid then
		both_sides_connected = true
		if self.priority > other_transfer.priority then
			other_transfer_resource_needs = 0
		elseif self.priority < other_transfer.priority then
			current_transfer_resource_needs = 0
		else
			current_transfer_resource_needs = current_transfer_resource_needs/2
			other_transfer_resource_needs = other_transfer_resource_needs/2
		end
	end
	
	--same quantity of resource for both elevators or adapt to the demand if can cover both sides
	if other_transfer.priority == self.priority then
		local divided_resource = Max(resource_available_to_send / 2, 0)
		if both_sides_connected then
			resource_excess_sent = divided_resource
		else
			local total_resource_needs = current_transfer_resource_needs + other_transfer_resource_needs
			if (total_resource_needs > resource_available_to_send and current_transfer_resource_needs > divided_resource and other_transfer_resource_needs > divided_resource) or total_resource_needs == 0 then
				resource_excess_sent = divided_resource
			else
				if current_transfer_resource_needs > other_transfer_resource_needs then
					resource_excess_sent = resource_available_to_send - other_transfer_resource_needs
				else
					resource_excess_sent = current_transfer_resource_needs
				end
			end
		end
	else
		--check if the other elevator's shortage is lower than the amount of resource and get what is left over (if something)
		if other_transfer.priority > self.priority then
			local not_used_resource = resource_available_to_send - other_transfer_resource_needs
			local current_transfer_resource = 0
			if not_used_resource > 0 then
				current_transfer_resource = not_used_resource <= current_transfer_resource_needs and not_used_resource or current_transfer_resource_needs
			end
			resource_excess_sent = Max(current_transfer_resource, 0)
		--this elevator has the priority and gets as much resource as needed
		else
			local not_used_resource = resource_available_to_send - current_transfer_resource_needs
			local current_transfer_resource = resource_available_to_send
			if not_used_resource > 0 and other_transfer_resource_needs > 0 then
				current_transfer_resource = current_transfer_resource - Min(not_used_resource, other_transfer_resource_needs)
			end
			resource_excess_sent = Max(current_transfer_resource, 0)
		end
	end
	resource_shortage = resource_needed

	return resource_excess_sent, resource_shortage
end

function GridTransfer:GetCurrentGridResource(grid_type)
	local other_transfer = self:IsOtherTransferInGrid(grid_type)
	local other_transfer_other_side = self.other:IsOtherTransferInGrid(grid_type)

	local other_transfer_resource = 0
	local resource_available_to_send = 0
	local resource_needed = 0
	
	local grid = self.grids[grid_type].grid
	local other_side_resource = self.grids[grid_type].production
	
	-- When we have other transfer on both sides, remove from the resource available from the other transfer resource as well
	if other_transfer and other_transfer_other_side then
		other_transfer_resource = other_transfer.grids[grid_type].production
	end 
	local storage_excess = #grid.storages > 0 and grid.discharge > 0 and grid.current_storage_change or 0
	storage_excess = storage_excess < 0 and -storage_excess or 0 
	local current_grid_excess = grid.current_production - grid.current_consumption
	local received_from_other_side = other_side_resource + other_transfer_resource
	resource_available_to_send = current_grid_excess + storage_excess - received_from_other_side
	resource_needed = abs((grid.current_production - grid.consumption) - received_from_other_side)
	resource_needed = resource_available_to_send > 0 and 0 or resource_needed

	return resource_needed, resource_available_to_send
end

function GridTransfer:IsOtherTransferInGrid(grid_type)
	for _,producer in ipairs(self.grids[grid_type].grid.producers) do
		if IsKindOf(producer.building, "GridTransfer") and producer.building ~= self then
			return producer.building
		end
	end		
	return nil
end

function GridTransfer:ShowPowerTransportUI()
	if self.other then
		local have_resources = self.electricity and self.other.electricity and self.water and self.other.water and self.air and self.other.air
		if have_resources then
			local electricity_transfer = self.electricity.excess_sent ~= 0 or self.other.electricity.excess_sent ~= 0
			local water_transfer = self.water.excess_sent ~= 0 or self.other.water.excess_sent ~= 0
			local air_transfer = self.air.excess_sent ~= 0 or self.other.air.excess_sent ~= 0
			return electricity_transfer or water_transfer or air_transfer
		end
	end
	return false
end

function GridTransfer:GetUIGridResourceTransferRollover()
	local power_items = self:GetUIPowerTransferRollover()
	local life_support_items = self:GetUILifeSupportTransferRollover()

	return (power_items .. life_support_items)
end

function GridTransfer:GetOtherSideConsumption(grid_type)
	local resource = self.grids[grid_type]
	local other_resource = self.other.grids[grid_type]
	local excess_sent = resource.excess_sent
	local grid_other_transfer = self:IsOtherTransferInGrid(grid_type)
	if grid_other_transfer and self.other:IsOtherTransferInGrid(grid_type) then
		excess_sent = excess_sent + grid_other_transfer.grids[grid_type].excess_sent
	end
	local other_side_consumption = resource and other_resource and Min(other_resource.shortage, excess_sent) or 0

	return other_side_consumption
end

function GridTransfer:GetTooltipGridAvailable(grid_type)
	local resource = self.grids[grid_type]
	local grid_available = (resource.grid.current_production - resource.grid.current_consumption)
	local other_side_consumption = self:GetOtherSideConsumption(grid_type)
	local other_transfer = self:IsOtherTransferInGrid(grid_type)
	local other_transfer_consumption = other_transfer and Min(other_transfer.grids[grid_type].excess_sent, other_transfer.other.grids[grid_type].shortage) or 0
	local other_side_connected = self.other:IsOtherTransferInGrid(grid_type)
	other_transfer_consumption = other_side_connected and other_transfer and 0 or other_transfer_consumption
	grid_available = grid_available - other_side_consumption - other_transfer_consumption
	
	if other_side_connected and not other_transfer then
		-- EDGE CASE SPECIFIC: remove the other side elevator transfer back when this elevator is the only producer 
		if #other_side_connected.grids[grid_type].grid.producers == 2 then
			local other_side_excess_sent = other_side_connected:GetOtherSideConsumption(grid_type)
			grid_available = grid_available - other_side_excess_sent
		end
	end

	return grid_available
end

function GridTransfer:GetTooltipShortage(grid_type)
	local other_map_shortage = self.other.grids[grid_type].shortage
	local other_transfer = self:IsOtherTransferInGrid(grid_type)
	local other_side_connected = self.other:IsOtherTransferInGrid(grid_type)
	if other_transfer and not other_side_connected then
		other_map_shortage = other_map_shortage + other_transfer.other.grids[grid_type].shortage
	end

	return other_map_shortage
end

DefineClass.ElectricityTransfer = {
	__parents = {
		"GridTransfer",
		"ElectricityConsumer",
		"ElectricityProducer"
	}
}

function ElectricityTransfer:InitElectricityTransfer()
	local electricity = self.electricity 
	self.grids.electricity = electricity 
	electricity.excess_sent = 0
	electricity.shortage = 0
end

function ElectricityTransfer:AddToCityLabels()
	Building.AddToCityLabels(self)
	GridTransfer.AddToCityLabels(self)
end

function ElectricityTransfer:RemoveFromCityLabels()
	Building.RemoveFromCityLabels(self)
	GridTransfer.RemoveFromCityLabels(self)
end

function ElectricityTransfer:OnDestroyed()
	ElectricityProducer.OnDestroyed(self)
	ElectricityConsumer.OnDestroyed(self)
end

function ElectricityTransfer:UpdateElectricityTransfer()
    if self.grids.electricity and self.other then
		self.electricity.excess_sent, self.electricity.shortage = self:UpdateResourceTransfer("electricity")
	end
end

function ElectricityTransfer:UpdateElectricityTransferProduction()
	if self.other then
		self.other.electricity:SetProduction(Max(self.electricity.excess_sent,0))
	end
end

function ElectricityTransfer:CreateElectricityElement()
	self.electricity = SupplyGridElement:new{
		building = self,
		consumption = self.electricity_consumption,
		variable_consumption = true,
		production = 0,
		throttled_production = 0,
	}
	
	self.electricity:SetProduction(0)
	self.electricity_base_consumption = self.electricity_consumption
end

--hide power producer infopanel data
function ElectricityTransfer:ShowUISectionElectricityProduction()
	return false
end

--hide power producer infopanel data
function ElectricityTransfer:ShowUISectionElectricityGrid()
	return false
end

function ElectricityTransfer:ShouldShowNotConnectedToPowerGridSign()
	local my_electricity = self.electricity
	local their_electricity = self.other and self.other.electricity
	local has_electricity_producer = my_electricity and #my_electricity.grid.producers > 0 or their_electricity and #their_electricity.grid.producers > 0
	return not has_electricity_producer and self.electricity_consumption > 0
end

function ElectricityTransfer:ShouldShowNotConnectedToGridSign()
	return false
end

function ElectricityTransfer:GetUIPowerTransferRollover()
	local current_map = GetEnvironmentDisplayName(self:GetMapID())
	local other_map = GetEnvironmentDisplayName(self.other:GetMapID())
	local grid_available = self:GetTooltipGridAvailable("electricity")
	local other_map_shortage = self:GetTooltipShortage("electricity")

	local items =
	{
		T(13888, "Excess power, water and oxygen can be sent through the elevator between the surface and underground."),
		T(13889, "<newline><center><em>Power</em><newline>"),
		T{13890, "Power production <current_map> <right><power(power_production)>", current_map = current_map, power_production = self.electricity.grid.current_production},
		T{13891, "Power consumption <current_map> <right><power(power_consumption)>", current_map = current_map, power_consumption = self.electricity.grid.consumption},
		T{13892, "Excess power transferred <right><power(power_transfered)>", power_transfered = self.electricity.excess_sent},
		T{13893, "Power shortage <other_map> <right><power(power_shortage)>", other_map = other_map, power_shortage = other_map_shortage},
		T{13894, "Power available in grid <right><power(power_available)>", power_available = grid_available}
	}

	return table.concat(items, "<newline><left>")
end

function ElectricityTransfer:GetUISentPowerExcess()
	local ui_power_excess = self.electricity and self.electricity.excess_sent
	return T{13895, "Power transferred <right><power(power_excess)>", power_excess = ui_power_excess}
end

function ElectricityTransfer:GetUIReceivedPowerExcess()
	local ui_power_excess = self.other.electricity and self.other.electricity.excess_sent
	return T{13896, "Power received <right><power(power_excess)>", power_excess = ui_power_excess}
end

DefineClass.LifeSupportTransfer = {
	__parents = {
		"GridTransfer",
		"AirProducer",
		"WaterProducer"
	}
}

function LifeSupportTransfer:InitLifeSupportTransfer()
	if self.water and self.air then
		local water = self.water
		self.grids.water = water
		water.excess_sent = 0
		water.shortage = 0

		local air = self.air
		self.grids.air = air
		air.excess_sent = 0
		air.shortage = 0
	end
end

function LifeSupportTransfer:UpdateLifeSupportTransfer()
    if self.grids.water and self.grids.air and self.other then
		self.water.excess_sent, self.water.shortage = self:UpdateResourceTransfer("water")
		self.air.excess_sent, self.air.shortage = self:UpdateResourceTransfer("air")
	end
end

function LifeSupportTransfer:AddToCityLabels()
	Building.AddToCityLabels(self)
	GridTransfer.AddToCityLabels(self)
end

function LifeSupportTransfer:RemoveFromCityLabels()
	Building.RemoveFromCityLabels(self)
	GridTransfer.RemoveFromCityLabels(self)
end

function LifeSupportTransfer:OnDestroyed()
	WaterProducer.OnDestroyed(self)
	AirProducer.OnDestroyed(self)
end

function LifeSupportTransfer:UpdateLifeSupportTransferProduction()
	if self.other then
		self.other.water:SetProduction(Max(self.water.excess_sent,0))
		self.other.air:SetProduction(Max(self.air.excess_sent,0))
	end
end

function LifeSupportTransfer:ShouldShowNotConnectedToLifeSupportGridSign()
	return WaterProducer.ShouldShowNotConnectedToLifeSupportGridSign(self) or AirProducer.ShouldShowNotConnectedToLifeSupportGridSign(self) 
end

function LifeSupportTransfer:CreateLifeSupportElements()
	WaterProducer.CreateLifeSupportElements(self)
	AirProducer.CreateLifeSupportElements(self)
end

function LifeSupportTransfer:GetUILifeSupportTransferRollover()
	local current_map = GetEnvironmentDisplayName(self:GetMapID())
	local other_map = GetEnvironmentDisplayName(self.other:GetMapID())
	local water_grid_available = self:GetTooltipGridAvailable("water")
	local other_map_water_shortage = self:GetTooltipShortage("water")


	local water_items =
	{
		T(13897, "<newline><center><em>Water</em><newline>"),
		T{13898, "Water production <current_map> <right><water(water_production)>", current_map = current_map, water_production = self.water.grid.current_production},
		T{13899, "Water consumption <current_map> <right><water(water_consumption)>", current_map = current_map, water_consumption = self.water.grid.consumption},
		T{13900, "Excess water transferred <right><water(water_transfered)>", water_transfered = self.water.excess_sent},
		T{13901, "Water shortage <other_map> <right><water(water_shortage)>", other_map = other_map, water_shortage = other_map_water_shortage},
		T{13902, "Water available in grid <right><water(water_available)>", water_available = water_grid_available}
	}

	local air_grid_available = self:GetTooltipGridAvailable("air")
	local other_map_air_shortage = self:GetTooltipShortage("air")

	local air_items =
	{
		T(13903, "<newline><center><em>Oxygen</em><newline>"),
		T{13904, "Oxygen production <current_map> <right><air(air_production)>", current_map = current_map, air_production = self.air.grid.current_production},
		T{13905, "Oxygen consumption <current_map> <right><air(air_consumption)>", current_map = current_map, air_consumption = self.air.grid.consumption},
		T{13906, "Excess oxygen transferred <right><air(air_transfered)>", air_transfered = self.air.excess_sent},
		T{13907, "Oxygen shortage <other_map> <right><air(air_shortage)>", other_map = other_map, air_shortage = other_map_air_shortage},
		T{13908, "Oxygen available in grid <right><air(air_available)>", air_available = air_grid_available}
	}

	return "<newline><left>" .. table.concat(water_items, "<newline><left>") .. "<newline><left>" .. table.concat(air_items, "<newline><left>")
end

function LifeSupportTransfer:GetUISentWaterExcess()
	local ui_water_excess = self.water and self.water.excess_sent
	return T{13909, "Water transferred <right><water(water_excess)>", water_excess = ui_water_excess}
end

function LifeSupportTransfer:GetUIReceivedWaterExcess()
	local ui_water_excess = self.other.water and self.other.water.excess_sent
	return T{13910, "Water received <right><water(water_excess)>", water_excess = ui_water_excess}
end

function LifeSupportTransfer:GetUISentOxygenExcess()
	local ui_air_excess = self.air and self.air.excess_sent
	return T{13911, "Oxygen transferred <right><air(air_excess)>", air_excess = ui_air_excess}
end

function LifeSupportTransfer:GetUIReceivedOxygenExcess()
	local ui_air_excess = self.other.air and self.other.air.excess_sent
	return T{13912, "Oxygen received <right><air(air_excess)>", air_excess = ui_air_excess}
end

function LifeSupportTransfer:ShowUISectionLifeSupportGrid()
	return false
end

function LifeSupportTransfer:ShowUISectionLifeSupportProduction()
	return false
end