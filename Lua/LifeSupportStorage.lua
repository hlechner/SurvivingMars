----- WaterStorage
--[[@@@
@class WaterStorage
Building derived [building template](ModItemBuildingTemplate.md.html) class. Handles water storage.
--]]
DefineClass.WaterStorage = {
	__parents = {"Building", "LifeSupportGridObject"},
	properties = {
		{ template = true, id = "max_water_charge", name = T(29, "Max water consumption while charging"), category = "Storage", editor = "number", default = 1000, help = "This is the amount of water the battery can charge per hour.", scale = const.ResourceScale  },
		{ template = true, id = "max_water_discharge", name = T(1068, "Max water output while discharging"), category = "Storage", editor = "number", default = 1000, help = "This is the amount of air the battery can discharge per hour.", scale = const.ResourceScale  },
		{ template = true, id = "water_conversion_efficiency", name = T(1069, "Conversion efficiency % of water (charging)"), category = "Storage", editor = "number", default = 100, help = "(100 - this number)% will go to waste when charging." },
		{ template = true, id = "water_capacity", name = T(30, "Water Capacity"), editor = "number", category = "Storage", default = 10000, scale = const.ResourceScale, modifiable = true  },
		{ id = "StoredWater", name = T(33, "Stored Water"), editor = "number", default = 0, scale = const.ResourceScale, no_edit = true },
	},
	
	is_tall = true,
}

function WaterStorage:CreateLifeSupportElements()
	self.water = NewSupplyGridStorage(self, self.water_capacity, self.max_water_charge, self.max_water_discharge, self.water_conversion_efficiency, 20)
	self.water:SetStoredAmount(self.StoredWater, "water")
end

function WaterStorage:OnModifiableValueChanged(prop)
	if self.water
		and (prop == "max_water_charge"
		or prop == "max_water_discharge"
		or prop == "water_conversion_efficiency"
		or prop == "water_capacity") then
		
		self.water.charge_efficiency = self.water_conversion_efficiency
		self.water.storage_capacity = self.water_capacity
		if self.water.grid and self.water.current_storage > self.water_capacity then
			local delta = self.water.current_storage - self.water_capacity
			self.water.current_storage = self.water_capacity
			self.water.grid.current_storage = self.water.grid.current_storage - delta
		end
		
		self.water:UpdateStorage()
	end
end

function WaterStorage:MoveInside(dome)
	return LifeSupportGridObject.MoveInside(self, dome)
end

function WaterStorage:OnSetWorking(working)
	Building.OnSetWorking(self, working)

	local water = self.water
	if working then
		water:UpdateStorage()
	else
		water:SetStorage(0, 0)
	end
end

function WaterStorage:ShouldShowNotConnectedToGridSign()
	return self:ShouldShowNotConnectedToLifeSupportGridSign()
end

function WaterStorage:ShouldShowNotConnectedToLifeSupportGridSign()
	local not_under_dome = not self.parent_dome
	if not_under_dome then
		if not self:HasPipes() then
			return true
		end
		if #self.water.grid.producers <= 0 then
			return true
		end
	end
	return false
end

function WaterStorage:UpdateAttachedSigns()
	self:AttachSign(self:ShouldShowNotConnectedToLifeSupportGridSign(), "SignNoPipeConnection")
end

function WaterStorage:CheatFill()
	self.water:SetStoredAmount(self.water_capacity, "water")
end

function WaterStorage:CheatEmpty()
	self.water:SetStoredAmount(0, "water")
end

function WaterStorage:GetStoredWater()
	return self.water.current_storage
end

function WaterStorage:NeedsWater()
	return true
end

function WaterStorage:NeedsAir()
	return false
end

----- AirStorage
--[[@@@
@class AirStorage
Building derived [building template](ModItemBuildingTemplate.md.html) class. Handles air storage.
--]]
DefineClass.AirStorage = {
	__parents = {"Building", "LifeSupportGridObject"},
	properties = {
		{ template = true, id = "max_air_charge", name = T(1070, "Max Oxygen consumption while charging"), category = "Storage", editor = "number", default = 1000, help = "This is the amount of Oxygen the battery can charge per hour.", scale = const.ResourceScale  },
		{ template = true, id = "max_air_discharge", name = T(1071, "Max Oxygen output while discharging"), category = "Storage", editor = "number", default = 1000, help = "This is the amount of Oxygen the battery can discharge per hour.", scale = const.ResourceScale  },
		{ template = true, id = "air_conversion_efficiency", name = T(1072, "Conversion Oxygen efficiency % (charging)"), category = "Storage", editor = "number", default = 100, help = "(100 - this number)% will go to waste when charging." },
		{ template = true, id = "air_capacity", name = T(1073, "Oxygen Capacity"), editor = "number", category = "Storage", default = 10000, scale = const.ResourceScale, modifiable = true  },
		{ id = "StoredAir", name = T(1074, "Stored Air"), editor = "number", default = 0, scale = const.ResourceScale, no_edit = true },
	},
	
	is_tall = true,
}

function AirStorage:CreateLifeSupportElements()
	self.air = NewSupplyGridStorage(self, self.air_capacity, self.max_air_charge, self.max_air_discharge, self.air_conversion_efficiency, 20)
	self.air:SetStoredAmount(self.StoredAir, "air")
end

function AirStorage:OnModifiableValueChanged(prop)
	if self.air
		and (prop == "max_air_charge"
		or prop == "max_air_discharge"
		or prop == "air_conversion_efficiency"
		or prop == "air_capacity") then
		
		self.air.charge_efficiency = self.air_conversion_efficiency
		self.air.storage_capacity = self.air_capacity
		if self.air.grid and self.air.current_storage > self.air_capacity then
			local delta = self.air.current_storage - self.air_capacity
			self.air.current_storage = self.air_capacity
			self.air.grid.current_storage = self.air.grid.current_storage - delta
		end
		
		self.air:UpdateStorage()
	end
end

function AirStorage:OnSetWorking(working)
	Building.OnSetWorking(self, working)

	local air = self.air
	if working then
		air:UpdateStorage()
	else
		air:SetStorage(0, 0)
	end
end

function AirStorage:MoveInside(dome)
	return LifeSupportGridObject.MoveInside(self, dome)
end

function AirStorage:ShouldShowNotConnectedToGridSign()
	return self:ShouldShowNotConnectedToLifeSupportGridSign()
end

function AirStorage:ShouldShowNotConnectedToLifeSupportGridSign()
	local not_under_dome = not self.parent_dome
	if not_under_dome then
		if not self:HasPipes() then
			return true
		end
		if #self.air.grid.producers <= 0 then
			return true
		end
	end
	return false
end

function AirStorage:UpdateAttachedSigns()
	self:AttachSign(self:ShouldShowNotConnectedToLifeSupportGridSign(), "SignNoPipeConnection")
end

function AirStorage:CheatFill()
	if self.air then
		self.air:SetStoredAmount(self.air_capacity, "air")
	end
end

function AirStorage:CheatEmpty()
	if self.air then
		self.air:SetStoredAmount(0, "air")
	end
end

function AirStorage:GetStoredAir()
	return self.air.current_storage
end

function AirStorage:NeedsWater()
	return false
end

function AirStorage:NeedsAir()
	return true
end

----- StorageWithIndicator
--[[@@@
@class StorageWithIndicator
Building derived [building template](ModItemBuildingTemplate.md.html) class. Helper class that manages storage building animated attachement according to stored amount. For example the WaterTank class inherits both this class and the [WaterStorage](LuaFunctionDoc_WaterStorage.md.html) class.
--]]
local StorageIndicatorAnimDuration = 3333 --100 frames at 30fps

DefineClass.StorageWithIndicators = {
	__parents = { "Building" },
	indicated_resource = false,
	indicator_class = false,
}

function StorageWithIndicators:GameInit()
	self:ResetIndicatorAnimations()
end

function StorageWithIndicators:ResetIndicatorAnimations(indicator_class)
	indicator_class = indicator_class or self.indicator_class
	for _,attach in ipairs(self:GetAttaches(indicator_class) or empty_table) do
		attach:SetAnimSpeed(1, 0)
		attach:SetAnimPhase(1, 0)
	end
end

function StorageWithIndicators:BuildingUpdate(dt)
	--Happens once every 30 seconds (see Building.building_update_time)
	self:UpdateIndicators()
end

function StorageWithIndicators:OnSkinChanged()
	Building.OnSkinChanged(self)
	self:ResetIndicatorAnimations()
	self:UpdateIndicators()
end

function StorageWithIndicators:UpdateIndicators()
	local res = self.indicated_resource
	res = res and self[res]
	if not res then return end
	for _,attach in ipairs(self:GetAttaches(self.indicator_class) or empty_table) do
		local phase = MulDivRound(res.current_storage, StorageIndicatorAnimDuration, res.storage_capacity)
		attach:SetAnimPhase(1, phase)
	end
end

function OnMsg.DataLoaded()
	local descendants = ClassDescendantsList("StorageWithIndicators")
	local idle_state_idx = GetStateIdx("idle")
	
	--tracks problems with descendants that do not have an entity assigned
	local unassigned_problems = {}
	--tracks problems with indicator entities with incorrect anim. duration
	local duration_problems = {}
	
	for _,class in ipairs(descendants) do
		local classdef = g_Classes[class]
		--doesn't have an indicator class
		if classdef.indicator_class == false then
			unassigned_problems[class] = true
		else
			local indicator_class = g_Classes[classdef.indicator_class]
			local indicator_entity = indicator_class:GetEntity()
			local dur = GetAnimDuration(indicator_entity, idle_state_idx)
			--has incorrect animation duration
			if dur ~= StorageIndicatorAnimDuration then
				duration_problems[indicator_entity] = true
			end
		end
	end
	
	if next(unassigned_problems) then
		print(string.format("WARNING: The following resource storage buildings should have indicators, but do not have an assigned indicator class:\n%s",
			table.concat(table.keys(unassigned_problems), ", ")))
	end
	if next(duration_problems) then
		print(string.format("WARNING:The following entites are used for resource storage building indicators, but have incorrect animation durations:\n%s",
			table.concat(table.keys(duration_problems), ", ")))
		print(string.format("Their animation duration must be %s", StorageIndicatorAnimDuration))
	end
end

----- WaterTank

DefineClass.WaterTank = {
	__parents = { "WaterStorage", "StorageWithIndicators", "ColdSensitive" },
	indicated_resource = "water",
	indicator_class = "WaterTankFloat",
	building_update_time = 10000,
}

----- WaterTankLarge

DefineClass.WaterTankLarge = {
	__parents = { "WaterStorage", "StorageWithIndicators", "ColdSensitive" },
	indicated_resource = "water",
	indicator_class = "WaterTankLargeFloat",
	building_update_time = 10000,
}

----- OxygenTank

DefineClass.OxygenTank = {
	__parents = { "AirStorage", "StorageWithIndicators" },
	indicated_resource = "air",
	indicator_class = "AirTankArrow",
}

DefineClass.OxygenTankLarge = {
	__parents = { "OxygenTank" },
}

function OxygenTankLarge:GetEntityNameForPipeConnections(grid_skin_name)
	return grid_skin_name ~= "Default" and "Moxie" .. grid_skin_name or "Moxie"
end
