----- WaterProducer
--[[@@@
@class WaterProducer
Building derived [building template](ModItemBuildingTemplate.md.html) class. Handles water production for a building. All buildings that produce water for the water grid are either of this class or a derived class.
--]]
DefineClass.WaterProducer = {
	__parents = { "Building", "LifeSupportGridObject" },
	properties = {
		{ template = true, id = "water_production", name = T(1065, "Water production"), category = "Water Production", editor = "number", default = 10000, help = Untranslated("This is the amount produced per hour."), scale = const.ResourceScale, modifiable = true },
	},
	
	is_tall = true,
}

function WaterProducer:GameInit()
	if HintsEnabled then
		HintTrigger("HintAirProduction")
	end
	
	if not (g_ActiveHints["HintDomePlacedTooEarly"] or empty_table).disabled then
		local has_one_air_producer
		local a_grids = (self.city or UICity).air
		for i = 1, #a_grids do
			if #a_grids[i].producers > 0 then
				has_one_air_producer = true
				break
			end
		end
		if has_one_air_producer then
			HintDisable("HintDomePlacedTooEarly")
			if HintsEnabled then
				HintTrigger("HintDomes")
			end
		end
	end
end

function WaterProducer:CreateLifeSupportElements()
	self.water = NewSupplyGridProducer(self)
	self.water:SetProduction(self.working and self.water_production or 0)
end

function WaterProducer:OnSetWorking(working)
	Building.OnSetWorking(self, working)
	if self.water then
		self.water:SetProduction(working and self.water_production or 0)
	end
end

function WaterProducer:MoveInside(dome)
	return LifeSupportGridObject.MoveInside(self, dome)
end

function WaterProducer:OnModifiableValueChanged(prop)
	if prop == "water_production" and self.water then
		self.water:SetProduction(self.working and self.water_production or 0)
	end
end

function WaterProducer:ShouldShowNotConnectedToGridSign()
	return self:ShouldShowNotConnectedToLifeSupportGridSign()
end

function WaterProducer:ShouldShowNotConnectedToLifeSupportGridSign()
	local not_under_dome = not self.parent_dome
	if not_under_dome then
		if not self:HasPipes() then
			return true
		end
		local transfer = self:WaterProducerConnectedToTransfer()
		if #self.water.grid.consumers <= 0 and #self.water.grid.storages <= 0 and (not transfer or not self:HasOtherSideWaterConsumers(transfer)) then
			return true
		end
	end
	return false
end

function WaterProducer:WaterProducerConnectedToTransfer()
	for _, producer in ipairs(self.water.grid.producers) do
		if IsKindOf(producer.building, "GridTransfer") then
			return producer.building
		end
	end
	return false
end

function WaterProducer:HasOtherSideWaterConsumers(transfer)
	if transfer and transfer.other then
		local other_side_grid = transfer.other.grids.water.grid
		return #other_side_grid.consumers + #other_side_grid.storages > 0
	end
end

function WaterProducer:UpdateAttachedSigns()
	self:AttachSign(self:ShouldShowNotConnectedToLifeSupportGridSign(), "SignNoPipeConnection")
end

function WaterProducer:GetWaterProductionText(short)
	local real_production = self.water.production > 0 and Max(self.water.production - self.water.current_throttled_production, 0) or 0
	local max_production = self.water.production
	return real_production < max_production
		and (short and T{9712, "<water(number1,number2)>", number1 = real_production, number2 = max_production} or T{482, "Water production<right><water(number1,number2)>", number1 = real_production, number2 = max_production})
		or (short and T{9713, "<water(number)>", number = real_production} or T{483, "Water production<right><water(number)>", number = real_production})
end

function WaterProducer:GetUISectionWaterProductionRollover()
	local lines = {
		T{479, "Production capacity<right><water(production)>", self.water},
		T{480, "Production per Sol<right><water(ProductionEstimate)>", self.water},
		T{481, "Lifetime production<right><water(production_lifetime)>", self.water},					
	}	
	AvailableDeposits(self, lines)
	if self:HasMember("wasterock_producer") and self.wasterock_producer then
		lines[#lines +1] = T(469, "<newline><center><em>Storage</em>")
		lines[#lines +1] = T{471, "Waste Rock<right><wasterock(GetWasterockAmountStored,wasterock_max_storage)>", self}
	end
	return table.concat(lines, "<newline><left>")
end



----- AirProducer
--[[@@@
@class AirProducer
Building derived [building template](ModItemBuildingTemplate.md.html) class. Handles air production for a building. All buildings that provide air to the air grid are either of this class or a derived class.
--]]
DefineClass.AirProducer = {
	__parents = { "Building", "LifeSupportGridObject" },
	properties = {
		{ template = true, id = "air_production", name = T(1066, "Oxygen production"), category = "Oxygen production", editor = "number", default = 10000, scale = const.ResourceScale, modifiable = true  },
	},
	
	is_tall = true,
}

function AirProducer:GameInit()
	if not (g_ActiveHints["HintDomePlacedTooEarly"] or empty_table).disabled then
		local has_one_water_producer
		local w_grids = (self.city or UICity).water
		for i = 1, #w_grids do
			if #w_grids[i].producers > 0 then
				has_one_water_producer = true
				break
			end
		end
		if has_one_water_producer then
			HintDisable("HintDomePlacedTooEarly")
			if HintsEnabled then
				HintTrigger("HintDomes")
			end
		end
	end
end

function AirProducer:CreateLifeSupportElements()
	self.air = NewSupplyGridProducer(self)
	self.air:SetProduction(self.working and self.air_production or 0)
end

function AirProducer:OnSetWorking(working)
	Building.OnSetWorking(self, working)
	if self.air then
		self.air:SetProduction(working and self.air_production or 0)
	end
end

function AirProducer:MoveInside(dome)
	return LifeSupportGridObject.MoveInside(self, dome)
end

function AirProducer:OnModifiableValueChanged(prop)
	if prop == "air_production" and self.air then
		self.air:SetProduction(self.working and self.air_production or 0)
	end
end

function AirProducer:ShouldShowNotConnectedToGridSign()
	return self:ShouldShowNotConnectedToLifeSupportGridSign()
end

function AirProducer:ShouldShowNotConnectedToLifeSupportGridSign()
	local not_under_dome = not self.parent_dome
	if not_under_dome then
		if not self:HasPipes() then
			return true
		end
		local transfer = self:AirProducerConnectedToTransfer()
		if #self.air.grid.consumers <= 0 and #self.air.grid.storages <= 0 and (not transfer or not self:HasOtherSideAirConsumers(transfer)) then
			return true
		end
	end
	return false
end

function AirProducer:AirProducerConnectedToTransfer()
	for _, producer in ipairs(self.air.grid.producers) do
		if IsKindOf(producer.building, "GridTransfer") then
			return producer.building
		end
	end
	return false
end

function AirProducer:HasOtherSideAirConsumers(transfer)
	if transfer and transfer.other then
		local other_side_grid = transfer.other.grids.air.grid
		return #other_side_grid.consumers + #other_side_grid.storages > 0
	end
end

function AirProducer:UpdateAttachedSigns()
	self:AttachSign(self:ShouldShowNotConnectedToLifeSupportGridSign(), "SignNoPipeConnection")
end

function AirProducer:GetAirProduction()
	return self.air.production
end

function AirProducer:GetUISectionAirProductionRollover()
	return T{484, "Production per Sol<right><air(ProductionEstimate)>", self.air} .. "<newline><left>" ..
	T{485, "Lifetime production<right><air(production_lifetime)>", self.air}
end
