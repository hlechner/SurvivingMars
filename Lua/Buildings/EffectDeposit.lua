DefineClass.EffectDepositMarker = {
	__parents = { "DepositMarker" },
	properties = {
		{ category = "Deposit", name = T(11450, "Deposit Type"), id = "deposit_type", editor = "combo", items = ClassDescendantsCombo("EffectDeposit"), default = "" },
	},
	
	new_pos_if_obstruct = false,
}

function EffectDepositMarker:SpawnDeposit()
	if not g_Classes[self.deposit_type] then
		StoreErrorSource("silent", self, "Trying to place non-existing effect deposit:", self.deposit_type)
		return
	end
	
	local dep = PlaceObjectIn(self.deposit_type, self:GetMapID())
	dep:SetCollectionIndex(self:GetCollectionIndex())
	return dep
end

--This is not an explorable or minable deposit.
--Instead it gives a certain effect to surrounding buildings.
--`EffectDeposit:AffectBuilding()` will be automatically called once for each building that is in range.
DefineClass.EffectDeposit = {
	__parents = { "SubsurfaceDeposit" },
	
	building_class = "Building",
	fx_actor_class = "SubsurfaceAnomaly",
	city_label = "EffectDeposit",
	ip_template = "ipEffectDeposit",
	list_as_sector_expected = false,
	sector_expected_name = "",
	
	ConstructionStatusName = false,
	ResourceName = "",
	show_pin_toggle = false,
}

function GetBuildingAffectRange(building)
	if IsKindOfClasses(building, "Dome", "LowGLab") then
		return building:GetSelectionRadiusScale()
	end
	
	return 0
end

local function GameInit_ForEachFn(building, deposit)
	if deposit:CanAffectBuilding(building) then
		local hex_dist = HexAxialDistance(deposit, building)
		local range = GetBuildingAffectRange(building)
		if hex_dist <= range then
			deposit:AffectBuilding(building)
		end
	end
end

function EffectDeposit.GetConstructionStatusText(building, all_deposits)
end

function EffectDeposit:GameInit()
	local realm = GetRealm(self)
	realm:MapForEach("map", self.building_class, GameInit_ForEachFn, self)
end

function EffectDeposit:CanAffectBuilding(building)
	return IsKindOf(building, self.building_class)
end

function EffectDeposit:AffectBuilding(building)
end

local function ConstructionComplete_ForEachFn(deposit, building)
	if deposit:CanAffectBuilding(building) then
		deposit:AffectBuilding(building)
	end
end

function OnMsg.ConstructionComplete(building, dome)
	local range = GetBuildingAffectRange(building)
	local realm = GetRealm(building)
	realm:MapForEach(building, "hex", range, "EffectDeposit", ConstructionComplete_ForEachFn, building)
end

function EffectDeposit:GetInfopanelDetails()
	return ""
end

DefineClass.PrefabFeatureChar_Effect = {
	__parents = { "PrefabFeatureChar" },
	properties = {
		{ category = "Effect", id = "EffectType", name = "Effect Type", editor = "combo", items = ClassDescendantsCombo("EffectDeposit"), default = "" },
	}
}

function PrefabFeatureChar_Effect:GetDescription()
	return (self.EffectType ~= "") and self.EffectType or "Effect Deposit"
end

function PlaceEffectDeposit(effect_type, params, map_id)
	local classdef = g_Classes[effect_type]
	if IsKindOf(classdef, "EffectDeposit") then
		return classdef:new(params, map_id)
	end
end

----

DefineClass.BeautyEffectDeposit = {
	__parents = { "EffectDeposit", "SafariSight" },
	
	building_class = "Dome",
	modifier = false,
	comfort_increase = 10 * const.Scale.Stat,
	
	ConstructionStatusName = "BeautyDepositNearby",
	resource = "Beauty",
	display_name = T(11458, "Vista"),
	IPDescription = T(11459, "Improves the Comfort of all residences when in the radius of a Dome."),
	display_icon = "UI/Icons/bmb_demo.tga",
	entity = "SignBeautyDeposit",
	
	sight_category = "Environmental Sceneries",
	sight_satisfaction = 3,
}

function BeautyEffectDeposit:GetInfopanelDetails()
	return T{11460, "Comfort boost<right><resource(comfort_increase)>", self}
end

function BeautyEffectDeposit:Init()
	self.encyclopedia_id = "Colonist"
	self.modifier = Modifier:new{
		prop = "dome_comfort",
		amount = self.comfort_increase,
		percent = 0,
		id = "Beauty Effect Deposit",
	}
end

function BeautyEffectDeposit:AffectBuilding(building)
	building:UpdateModifier("add", self.modifier, self.modifier.amount, self.modifier.percent)
end

function BeautyEffectDeposit.GetConstructionStatusText(building, all_deposits)
	local sum = 0
	for i,deposit in ipairs(all_deposits) do
		sum = sum + deposit.comfort_increase / const.Scale.Stat
	end
	return T{12263, "Vista - Comfort of residences will be boosted by <sum>", sum = sum}
end

----

DefineClass.ResearchEffectDeposit = {
	__parents = { "EffectDeposit" },
	
	modifier = false,
	research_increase = 10,
	research_increase_options = { 10, 15, 20 },
	
	ConstructionStatusName = "ResearchDepositNearby",
	list_as_sector_expected = true,
	sector_expected_name = T(311, "Research"),
	resource = "Research",
	display_name = T(11461, "Research Site"),
	IPDescription = T(11462, "Boosts research production when in radius of a Dome or outside research facility."),
	display_icon = "UI/Icons/bmb_demo.tga",
	entity = "SignResearchDeposit",
}

function ResearchEffectDeposit:GetInfopanelDetails()
	return T{11463, "Research boost<right><percent(research_increase)>", self}
end

function ResearchEffectDeposit:Init()
	self.research_increase = table.rand(self.research_increase_options)
	self.modifier = Modifier:new{
		prop = "ResearchPointsPerDay",
		amount = 0,
		percent = self.research_increase,
		id = "Research Effect Deposit",
	}
end

function ResearchEffectDeposit:CanAffectBuilding(building)
	return (IsKindOf(building, "ResearchBuilding") and not building.dome_required) or IsKindOf(building, "Dome")
end

function ResearchEffectDeposit:AffectBuilding(building)
	if IsKindOf(building, "ResearchBuilding") and not building.dome_required then
		building:UpdateModifier("add", self.modifier, self.modifier.amount, self.modifier.percent)
	elseif IsKindOf(building, "Dome") then
		building:SetLabelModifier("ResearchBuildings", self, self.modifier, false)
	end
end

function ResearchEffectDeposit.GetConstructionStatusText(building, all_deposits)
	local sum = 0
	for i,deposit in ipairs(all_deposits) do
		sum = sum + deposit.research_increase
	end
	return T{12264, "Research Site - all Research will be boosted by <percent(sum)>.", sum = sum}
end

----

DefineClass.MoraleEffectDeposit = {
	__parents = { "EffectDeposit" },
	
	modifier = false,
	morale_increase = 10 * const.Scale.Stat,
	
	ConstructionStatusName = "MoraleDepositNearby",
	resource = "Morale",
	display_name = T(11458, "Vista"),
	IPDescription = T(13600, "Improves the Morale of all residences when in the radius of a Dome."),
	display_icon = "UI/Icons/bmb_demo.tga",
	entity = "SignBeautyDeposit",
}

function MoraleEffectDeposit:GetInfopanelDetails()
	return T{13601, "Morale boost<right><resource(morale_increase)>", self}
end

function MoraleEffectDeposit:Init()
	self.encyclopedia_id = "Colonist"
	self.modifier = Modifier:new{
		prop = "dome_morale",
		amount = self.morale_increase,
		percent = 0,
		id = "Morale Effect Deposit",
		display_text = self.display_name,
	}
end

function MoraleEffectDeposit:SetMoraleIncrease(increase)
	self.morale_increase = increase
	self.modifier.amount = self.morale_increase
end

function MoraleEffectDeposit:AddMoraleIncrease(increase)
	self.morale_increase = self.morale_increase + increase
	self.modifier.amount = self.morale_increase
end

function MoraleEffectDeposit:CanAffectBuilding(building)
	return IsKindOf(building, "Dome")
end

function MoraleEffectDeposit:AffectBuilding(building)
	building:UpdateModifier("add", self.modifier, self.modifier.amount, self.modifier.percent)
end

function MoraleEffectDeposit.GetConstructionStatusText(building, all_deposits)
	local sum = 0
	for i,deposit in ipairs(all_deposits) do
		sum = sum + deposit.morale_increase / const.Scale.Stat
	end
	return T{13603, "Vista - Morale of residences will be boosted by <sum>", sum = sum}
end
