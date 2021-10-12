-- ElectricityConsumer
--[[@@@
@class ElectricityConsumer
Building derived [building template](ModItemBuildingTemplate.md.html) class. Handles power consumption for a building. All buildings in the game that consume power inherit or are this class.
--]]
DefineClass.ElectricityConsumer = {
	__parents = { "Building", "ElectricityGridObject", "ColdSensitive" },

	properties = {
		{ template = true, id = "electricity_consumption", name = T(683, "Power Consumption"),  category = "Consumption", editor = "number", default = 1000, modifiable = true, min = 0 },
		{ template = true, id = "disable_electricity_consumption", name = T(937, "Disable Consumption"), no_edit = true, modifiable = true, editor = "number", default = 0, help = "So consumption can be turned off with modifiers"},
	},
	
	is_electricity_consumer = true,
	cold_mod = false,
}

function ElectricityConsumer:CreateElectricityElement()
	if self.disable_electricity_consumption >= 1 then
		self:SetBase("electricity_consumption", 0)
	end
	self.electricity = NewSupplyGridConsumer(self)
	self.electricity:SetConsumption(self.electricity_consumption)
end

function ElectricityConsumer:SetPriority(priority)
	Building.SetPriority(self, priority)
	local electricity = self.electricity
	if electricity then
		self.electricity:SetPriority(priority)
	end
end

function ElectricityConsumer:HasPower()
	local electricity = self.electricity
	return electricity and electricity.consumption >= self.electricity_consumption and electricity.consumption <= electricity.current_consumption
end

function ElectricityConsumer:GetWorkNotPossibleReason()
	if not self:HasPower() then
		return "NoPower"
	end
	return Building.GetWorkNotPossibleReason(self)
end

function ElectricityConsumer:AreNightLightsAllowed()
	return self.working and self:HasPower() and not self:IsSupplyGridDemandStoppedByGame()
end

function ElectricityConsumer:IsFreezing()
	if self.electricity_consumption == 0 or self:HasPower() then
		return false
	end
	return ColdSensitive.IsFreezing(self)
end

function ElectricityConsumer:OnFrozenStateChanged()
	self:UpdateConsumption()
end

function ElectricityConsumer:BuildingUpdate(delta)
	local penalty = self:GetColdPenalty()
	if self.cold_mod then
		if penalty > 0 then
			self.cold_mod:Change(0, penalty)
		else
			DoneObject(self.cold_mod)
			self.cold_mod = false
		end
	elseif penalty > 0 then
		self.cold_mod = ObjectModifier:new{target = self, prop = "electricity_consumption", percent = penalty, amount = 0 }
	end
end

function ElectricityConsumer:SetSupply(resource, amount)
	if resource == "electricity" then
		self:Gossip("SetSupply", resource, amount)
		self:UpdateConsumption()
		self:UpdateWorking()
	end
end

function ElectricityConsumer:GatherConstructionStatuses(statuses)
	Building.GatherConstructionStatuses(self, statuses)
	local consumption = self.electricity_consumption

	if self:HasMember("template_name") and self.template_name ~= "" then
		local modifier_obj = GetModifierObject(self.template_name)
		local disable = 0
		disable = modifier_obj:ModifyValue(disable, "disable_electricity_consumption") --check this only with mod obj, since, presumably, no consumer should start with this enabled by default
		if disable >= 1 then
			consumption = 0
		else
			consumption = modifier_obj:ModifyValue(consumption, "electricity_consumption")
		end
	end

	if consumption == 0 then
		return
	end

	local penalty = self:GetColdPenalty()
	consumption = consumption * (100 + penalty) / 100
	local reserve_power = 0
	local grids = {}
	local object_hex_grid = GetObjectHexGrid(self)
	local dome = GetDomeAtPoint(object_hex_grid, self:GetPos())
	if dome then
		if dome.electricity then
			local grid = dome.electricity.grid
			grids[grid] = true
			reserve_power = grid.current_reserve
		end
	else
		local supply_connection_grid = GetSupplyConnectionGrid(self)
		local neighbours = SupplyGridApplyBuilding(supply_connection_grid["electricity"], 
				self, self:GetSupplyGridConnectionShapePoints("electricity"), self:GetShapeConnections("electricity"), 
				"don't apply")
				
		for i = 1, #(neighbours or ""), 2 do
			object_hex_grid:GetObjectsAtPos(neighbours[i + 1], nil, nil, function(o)
				local grid = GetGrid(o, "electricity")
				if grid and not grids[grid] then
					grids[grid] = true
					reserve_power = reserve_power + grid.current_reserve
				end
			end)
		end
	end
	
	if not next(grids) then --no grids
		statuses[#statuses + 1] = ConstructionStatus.ElectricityRequired
	elseif reserve_power < consumption then --not nuff power produced.
		statuses[#statuses + 1] = ConstructionStatus.ElectricityGridNotEnoughPower
	end
	if penalty > 0 then
		local status = table.copy(ConstructionStatus.ColdSensitive)
		status.text = T{status.text, {pct = penalty, col = ConstructionStatusColors.error.color_tag}}
		statuses[#statuses + 1] = status
	end
end

function ElectricityConsumer:ShouldShowNoElectricitySign()
	return not self.suspended and self:IsWorkPermitted() and self.electricity and self.electricity.consumption ~= 0 and not self:HasPower()
end

function ElectricityConsumer:ShouldShowNotConnectedToGridSign()
	return self:ShouldShowNotConnectedToPowerGridSign()
end

function ElectricityConsumer:ShouldShowNotConnectedToPowerGridSign()
	local electricity = self.electricity 
	return electricity and not self.parent_dome and self.electricity_consumption > 0 and #electricity.grid.producers <= 0
end

function ElectricityConsumer:MoveInside(dome)
	return ElectricityGridObject.MoveInside(self, dome)
end

function ElectricityConsumer:OnModifiableValueChanged(prop)
	if self.electricity then
		if prop == "electricity_consumption" then
			self:UpdateConsumption("immediate")
			self:Notify("UpdateWorking")
		elseif prop == "disable_electricity_consumption" then
			assert(not IsKindOf(self, "RangeElConsumer"), "RangeElConsumer and disabling electricity consumption both change the base electricity_consumption value. These two logics should not intersect.")
			if self.disable_electricity_consumption >= 1 then
				self:SetBase("electricity_consumption", 0)
			else
				self:RestoreBase("electricity_consumption")
			end
		end
	end
end

function ElectricityConsumer:UpdateAttachedSigns()
	self:AttachSign(self:ShouldShowNotConnectedToPowerGridSign(), "SignNoPowerProducer")
	self:AttachSign(self:ShouldShowNoElectricitySign(), "SignNoPower")
end

function ElectricityConsumer:CheatNoConsumption()
	self.disable_electricity_consumption = 1
	self:SetBase("electricity_consumption", 0)
end

----

DefineClass.RangeElConsumer =
{
	__parents = { "ElectricityConsumer", "UIRangeBuilding" },
}

function RangeElConsumer:UpdateElectricityConsumption()
	assert(self.disable_electricity_consumption == 0, "RangeElConsumer and disabling electricity consumption both change the base electricity_consumption value. These two logics should not intersect.")
	local range = self.UIRange
	local prop_meta = self:GetPropertyMetadata("UIRange")
	local min_range = prop_meta.min
	local template = ClassTemplates.Building[self.template_name]
	self:SetBase("electricity_consumption", MulDivRound(range * range, template.electricity_consumption, min_range * min_range))
end
