----- AirConsumer
--[[@@@
@class AirConsumer
Building derived [building template](ModItemBuildingTemplate.md.html) class. Handles air consumption.
--]]
DefineClass.AirConsumer = {
	__parents = { "Building", "LifeSupportGridObject"},

	properties = {
		{ template = true, id = "air_consumption",   name = T(1067, "Oxygen consumption"), category = "Consumption", editor = "number", default = 10000, scale = const.ResourceScale, modifiable = true, min = 0, },
		{ template = true, id = "disable_air_consumption", name = T(12290, "Disable Oxygen Consumption"), no_edit = true, modifiable = true, editor = "number", default = 0, help = "So consumption can be turned off with modifiers"},
	},

	is_tall = true,
}

function AirConsumer:CreateLifeSupportElements()
	if self.air_consumption > 0 then
		self.air = NewSupplyGridConsumer(self) or nil
		self.air:SetConsumption(self.air_consumption)
	end
end

function AirConsumer:SetSupply(resource, amount)
	if resource == "air" and self.air then
		self:Gossip("SetSupply", resource, amount)
		self:UpdateWorking()
	end
end

function AirConsumer:SetPriority(priority)
	Building.SetPriority(self, priority)
	if self.air then self.air:SetPriority(priority) end
end

function AirConsumer:HasAir()
	local air = self.air
	return self.air_consumption == 0 or (air and air.current_consumption >= air.consumption and self.air_consumption <= air.consumption)
end

function AirConsumer:GetWorkNotPossibleReason()
	if not self:HasAir() then
		return "NoOxygen"
	end
	return Building.GetWorkNotPossibleReason(self)
end

function AirConsumer:MoveInside(dome)
	return LifeSupportGridObject.MoveInside(self, dome)
end

function AirConsumer:OnModifiableValueChanged(prop)
	if prop == "air_consumption" then
		self:UpdateConsumption()
	elseif prop == "disable_air_consumption" then
		if self.disable_air_consumption >= 1 then
			self:SetBase("air_consumption", 0)
		else
			self:RestoreBase("air_consumption")
		end
	end
end

function AirConsumer:NeedsAir()
	local needs_air = false
	if self.air and self.air.consumption > 0 then
		needs_air = true
	end
	return needs_air
end

function AirConsumer:ShouldShowNoAirSign()
	return self:NeedsAir() and self:IsWorkPermitted() and not self:HasAir()
end

function AirConsumer:ShouldShowNotConnectedToGridSign()
	return self:ShouldShowNotConnectedToLifeSupportGridSign()
end

function AirConsumer:ShouldShowNotConnectedToLifeSupportGridSign()
	local not_under_dome = not self.parent_dome
	if not_under_dome then
		local needs_air = self:NeedsAir()
		if needs_air and not self:HasPipes() then
			return true
		end
		if needs_air and (#self.air.grid.producers <= 0 and #self.air.grid.storages <= 0) then
			return true
		end
	end
	return false
end

function AirConsumer:UpdateAttachedSigns()
	self:AttachSign(self:ShouldShowNotConnectedToLifeSupportGridSign(), "SignNoPipeConnection")
	if self.air then
		self:AttachSign(self:ShouldShowNoAirSign(), "SignNoOxygen")
	end
end

----- WaterConsumer
--[[@@@
@class WaterConsumer
Building derived [building template](ModItemBuildingTemplate.md.html) class. Handles water consumption.
--]]
DefineClass.WaterConsumer = {
	__parents = { "Building", "LifeSupportGridObject"},

	properties = {
		{ template = true, id = "water_consumption", name = T(656, "Water consumption"),  category = "Consumption", editor = "number", default = 10000, scale = const.ResourceScale, modifiable = true, min = 0, },
		{ template = true, id = "disable_water_consumption", name = T(12289, "Disable Water Consumption"), no_edit = true, modifiable = true, editor = "number", default = 0, help = "So consumption can be turned off with modifiers"},
	},
	
	is_tall = true,
}

function WaterConsumer:CreateLifeSupportElements()
	if self.water_consumption > 0 then
		self.water = NewSupplyGridConsumer(self)
		self.water:SetConsumption(self.water_consumption)
	end
end

function WaterConsumer:SetSupply(resource, amount)
	if resource == "water" and self.water then
		self:Gossip("SetSupply", resource, amount)
		self:UpdateWorking()
	end
end

function WaterConsumer:SetPriority(priority)
	Building.SetPriority(self, priority)
	if self.water then self.water:SetPriority(priority) end
end

function WaterConsumer:HasWater()
	local water = self.water
	return self.water_consumption == 0 or (water and water.current_consumption >= water.consumption and self.water_consumption <= water.consumption)
end

function WaterConsumer:GetWorkNotPossibleReason()
	if not self:HasWater() then
		return "NoWater"
	end
	return Building.GetWorkNotPossibleReason(self)
end

function WaterConsumer:MoveInside(dome)
	return LifeSupportGridObject.MoveInside(self, dome)
end

function WaterConsumer:OnModifiableValueChanged(prop)
	if prop == "water_consumption" then
		self:UpdateConsumption()
	elseif prop == "disable_water_consumption" then
		if self.disable_water_consumption >= 1 then
			self:SetBase("water_consumption", 0)
		else
			self:RestoreBase("water_consumption")
		end
	end
end

function WaterConsumer:NeedsWater()
	local needs_water = false
	if self.water and self.water.consumption and self.water.consumption > 0 then
		needs_water = true
	end
	return needs_water
end

function WaterConsumer:ShouldShowNoWaterSign()
	return self:NeedsWater() and self:IsWorkPermitted() and not self:HasWater()
end

function WaterConsumer:ShouldShowNotConnectedToGridSign()
	return self:ShouldShowNotConnectedToLifeSupportGridSign()
end

function WaterConsumer:ShouldShowNotConnectedToLifeSupportGridSign()
	local not_under_dome = not self.parent_dome
	if not_under_dome then
		local needs_water = self:NeedsWater()
		if needs_water and not self:HasPipes() then
			return true
		end
		if needs_water and (#self.water.grid.producers <= 0 and #self.water.grid.storages <= 0) then
			return true
		end
	end
	return false
end

function WaterConsumer:UpdateAttachedSigns()
	self:AttachSign(self:ShouldShowNotConnectedToLifeSupportGridSign(), "SignNoPipeConnection")
	if self.water then
		self:AttachSign(self:ShouldShowNoWaterSign(), "SignNoWater")
	end
end

----- LifeSupportConsumer
--[[@@@
@class LifeSupportConsumer
Building derived [building template](ModItemBuildingTemplate.md.html) class. Handles air and water consumption. An object of this class may consume only water, only air or both. All buildings that consume air or water in whatever fashion are of this class or a derived class.
--]]
DefineClass.LifeSupportConsumer = {
	__parents = { "AirConsumer", "WaterConsumer"},

	is_tall = true,
	is_lifesupport_consumer = true,
}

function LifeSupportConsumer:CreateLifeSupportElements()
	AirConsumer.CreateLifeSupportElements(self)
	WaterConsumer.CreateLifeSupportElements(self)
end

function LifeSupportConsumer:SetSupply(resource, amount)
	AirConsumer.SetSupply(self, resource, amount)
	WaterConsumer.SetSupply(self, resource, amount)
end

function LifeSupportConsumer:SetPriority(priority)
	Building.SetPriority(self, priority)
	if self.water then self.water:SetPriority(priority) end
	if self.air then self.air:SetPriority(priority) end
end

function LifeSupportConsumer:GetWorkNotPossibleReason()
	if not self:HasAir() then
		return "NoOxygen"
	end
	if not self:HasWater() then
		return "NoWater"
	end
	return Building.GetWorkNotPossibleReason(self)
end

function LifeSupportConsumer:MoveInside(dome)
	return LifeSupportGridObject.MoveInside(self, dome)
end

function LifeSupportConsumer:OnModifiableValueChanged(prop)
	AirConsumer.OnModifiableValueChanged(self, prop)
	WaterConsumer.OnModifiableValueChanged(self, prop)
end

function LifeSupportConsumer:ShouldShowNotConnectedToGridSign()
	return self:ShouldShowNotConnectedToLifeSupportGridSign()
end

function LifeSupportConsumer:ShouldShowNotConnectedToLifeSupportGridSign()
	local not_under_dome = not self.parent_dome
	if not_under_dome then
		local needs_water, needs_air = self:NeedsWater(), self:NeedsAir()
		if (needs_water or needs_air) and not self:HasPipes() then
			return true
		end
		if needs_water and (#self.water.grid.producers <= 0 and #self.water.grid.storages <= 0) then
			return true
		end
		if needs_air and (#self.air.grid.producers <= 0 and #self.air.grid.storages <= 0) then
			return true
		end
	end
	return false
end

function LifeSupportConsumer:UpdateAttachedSigns()
	self:AttachSign(self:ShouldShowNotConnectedToLifeSupportGridSign(), "SignNoPipeConnection")
	if self.water then
		self:AttachSign(self:ShouldShowNoWaterSign(), "SignNoWater")
	end
	if self.air then
		self:AttachSign(self:ShouldShowNoAirSign(), "SignNoOxygen")
	end
end
