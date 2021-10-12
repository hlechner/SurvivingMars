----- ElectricityProducer
--[[@@@
@class ElectricityProducer
Building derived [building template](ModItemBuildingTemplate.md.html) class. Handles power production for a building. All buildings in the game that produce power inherit or are this class.
--]]
DefineClass.ElectricityProducer = {
	__parents = { "Building", "ElectricityGridObject"},
	properties = {
		{ template = true, id = "electricity_production", name = T(11017, "Power production"), category = "Power Production", editor = "number", default = 1000, help = Untranslated("This is the amount produced per hour."), modifiable = true },
	},
}

function ElectricityProducer:CreateElectricityElement()
	self.electricity = NewSupplyGridProducer(self)
	self.electricity:SetProduction(self.working and self:GetPerformanceModifiedElectricityProduction() or 0)
end

function ElectricityProducer:ShouldShowNotConnectedToGridSign()
	return self:ShouldShowNotConnectedToPowerGridSign()
end

function ElectricityProducer:ShouldShowNotConnectedToPowerGridSign()
	local grid = self.electricity.grid
	return grid and #grid.consumers <= 0 and #grid.storages <= 0
end

function ElectricityProducer:UpdateAttachedSigns()
	self:AttachSign(self:ShouldShowNotConnectedToPowerGridSign(), "SignNoPowerProducer")
end

function ElectricityProducer:OnSetWorking(working)
	Building.OnSetWorking(self, working)
	self.electricity:SetProduction(working and self:GetPerformanceModifiedElectricityProduction() or 0)
end

function ElectricityProducer:GetOptimalElectricityProduction()
	local prop = "electricity_production"
	local optimal = self:GetClassValue(prop)
	local prop_meta = self:GetPropertyMetadata(prop)
	local mod = {amount = 0, percent = 100, min = prop_meta and prop_meta.min, max = prop_meta and prop_meta.max}
	local my_mods = self.modifications and self.modifications[prop] or empty_table
	for i = 1, #my_mods do
		local m = my_mods[i]
		if m.amount >= 0 and m.percent >= 0 then
			mod.amount = mod.amount + m.amount
			mod.percent = mod.percent + m.percent
		end
	end
	
	return self:ModifyValue(optimal, nil, mod)
end

function ElectricityProducer:GetEletricityUnderproduction()
	return Max(0, self:GetOptimalElectricityProduction() - self:GetPerformanceModifiedElectricityProduction())
end

function ElectricityProducer:MoveInside(dome)
	return ElectricityGridObject.MoveInside(self, dome)
 end

function ElectricityProducer:GetPerformanceModifiedElectricityProduction()
	if self:HasMember("performance") then
		return MulDivRound(self.electricity_production, self.performance, 100)
	else
		return self.electricity_production
	end
end

function ElectricityProducer:OnModifiableValueChanged(prop)
	if (prop == "electricity_production" or prop == "performance") and self.electricity then
		self.electricity:SetProduction(self.working and self:GetPerformanceModifiedElectricityProduction() or 0)
	end
end

function ElectricityProducer:GetUIPowerProduction()
	return self.electricity and self.electricity.production or 0
end

function ElectricityProducer:GetUIPowerProductionToday()
	return Max(self.electricity.production_today, self.electricity.production_yesterday)
end

function ElectricityProducer:GetUIPowerProductionLifetime()
	return self.electricity.production_lifetime
end
