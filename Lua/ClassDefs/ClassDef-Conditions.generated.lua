-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

UndefineClass('AreDomesOpen')
DefineClass.AreDomesOpen = {
	__parents = { "Condition", },
	properties = {
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = T(112025262533, --[[ConditionDef Conditions AreDomesOpen value]] "Domes are open"),
	DescriptionNeg = T(715764222467, --[[ConditionDef Conditions AreDomesOpen value]] "Domes aren't open"),
	Documentation = "Checks if the domes are switched to open state (after reaching breathable atmosphere)",
}

function AreDomesOpen:__eval(map_id, obj, context)
	return GetOpenAirBuildings(map_id)
end

function AreDomesOpen:__eval(map_id, obj, context)
	return false
end

UndefineClass('CanCauseFault')
DefineClass.CanCauseFault = {
	__parents = { "Condition", },
	properties = {
		{ id = "Grid", help = "Select the grid.", 
			editor = "choice", default = false, items = function (self) return { {text = "Pipe", value = "water"}, {text = "Cable", value = "electricity"}} end, },
	},
	Description = Untranslated("Checks if there is a <Grid> grid fragment which can be broken"),
	Documentation = "Returns whether there exists a supply grid fragment of the selected type (electricity or water) where a fault can be caused (i.e. a grid with more then 10 elements).",
}

function CanCauseFault:__eval(map_id, obj, context)
	local city = Cities[map_id]
	for _, fragment in ipairs(city[self.Grid]) do
		if fragment:IsBreakable() then
			return true
		end
	end
	return false
end

UndefineClass('CheckAverageComfort')
DefineClass.CheckAverageComfort = {
	__parents = { "Condition", },
	properties = {
		{ id = "Amount", help = "Set the value to check against.", 
			editor = "number", default = false, 
			buttons = { { "Param", "StoryBit_PickParam" } }, },
		{ id = "Condition", help = "Select the relation to the specified value.", 
			editor = "choice", default = ">=", items = function (self) return { ">=", "<=", ">", "<", "==", "~=" } end, },
	},
	Description = Untranslated("Average comfort <Condition> <Amount>"),
	Documentation = "Checks the average comfort in the colony against a certain value.",
}

function CheckAverageComfort:__eval(map_id, obj, context)
	local city = Cities[map_id]
	local avg = GetAverageStat(city.labels.Colonist, "Comfort")
	return self:CompareOp(avg, context)
end

function CheckAverageComfort:__eval_relaxed(map_id, obj, context)
	return true
end

UndefineClass('CheckAverageMorale')
DefineClass.CheckAverageMorale = {
	__parents = { "Condition", },
	properties = {
		{ id = "Amount", help = "Set the value to check against.", 
			editor = "number", default = false, 
			buttons = { { "Param", "StoryBit_PickParam" } }, },
		{ id = "Condition", help = "Select the relation to the specified value.", 
			editor = "choice", default = ">=", items = function (self) return { ">=", "<=", ">", "<", "==", "~=" } end, },
	},
	Description = Untranslated("Average morale <Condition> <Amount>"),
	Documentation = "Checks the average morale in the colony against a certain value.",
}

function CheckAverageMorale:__eval(map_id, obj, context)
	local city = Cities[map_id]
	local avg = GetAverageStat(city.labels.Colonist, "Morale")
	return self:CompareOp(avg, context)
end

function CheckAverageMorale:__eval_relaxed(map_id, obj, context)
	return true
end

UndefineClass('CheckBuildingCount')
DefineClass.CheckBuildingCount = {
	__parents = { "Condition", },
	properties = {
		{ id = "Building", help = "Select building type to check for.", 
			editor = "combo", default = false, items = function (self) return BuildingsCombo() end, },
		{ id = "Amount", help = "Set the number of buildings of this type.", 
			editor = "number", default = 0, 
			buttons = { { "Param", "StoryBit_PickParam" } }, },
	},
	Documentation = "Checks the count of buildings of the selected type.",
	TextSingular = T(828647965498, --[[ConditionDef Conditions CheckBuildingCount value]] "1 <building_name>"),
	TextPlural = T(438871007969, --[[ConditionDef Conditions CheckBuildingCount value]] "<amount> <building_name_plural>"),
}

function CheckBuildingCount:__eval(map_id, obj, context)
	local count = 0
	local amount = self:ResolveValue("Amount", context)
	if ClassTemplates.Building[self.Building] then
		local city = Cities[map_id]
		for _, building in ipairs(city.labels[self.Building] or empty_table) do
			if not building:HasMember("destroyed") then
				count = count + 1
			elseif building.destroyed == false then
				count = count + 1
			end 
		end
	end
	return count >= amount
end

function CheckBuildingCount:GetDescription(obj, context)
	local bld = BuildingTemplates[self.Building]
	local amount = self:ResolveValue("Amount", context)
	if not bld then
		return amount == 1 and
			T{self.TextSingular, building_name = T(5426, --[[Label Building display_name]] "Building")} or
			T{self.TextPlural, amount = amount, building_name_plural = T(3980, "Buildings")}
	end
	return amount == 1 and
		T{self.TextSingular, building_name = bld.display_name} or
		T{self.TextPlural, amount = amount, building_name_plural = bld.display_name_pl}
end

UndefineClass('CheckColonistCount')
DefineClass.CheckColonistCount = {
	__parents = { "Condition", },
	properties = {
		{ id = "Amount", help = "Set the number of colonists.", 
			editor = "number", default = 1, 
			buttons = { { "Param", "StoryBit_PickParam" } }, },
		{ id = "Trait", help = "Limit only to colonists with this Trait.", 
			editor = "combo", default = false, items = function (self) return TraitsCombo() end, },
	},
	Documentation = "Counts the colonists with the selected trait.",
	TextSingular = T(189508201261, --[[ConditionDef Conditions CheckColonistCount value]] "1 Colonist"),
	TextPlural = T(672624091330, --[[ConditionDef Conditions CheckColonistCount value]] "<amount> Colonists"),
	TextTraitSingular = T(313070027412, --[[ConditionDef Conditions CheckColonistCount value]] "1 <trait> Colonist"),
	TextTraitPlural = T(330446983216, --[[ConditionDef Conditions CheckColonistCount value]] "<amount> <trait> Colonists"),
}

function CheckColonistCount:__eval(map_id, obj, context)
	local city = Cities[map_id]
	local objs = GetObjectsByLabel(city, "Colonist")
	local count = #(objs or "")
	if count > 0 and self.Trait and self.Trait ~= "" then
		for _, obj in ipairs(objs) do
			if not obj.traits[self.Trait] then
				count = count - 1
			end
		end
	end
	return count >= self:ResolveValue("Amount", context)
end

function CheckColonistCount:GetDescription(obj, context)
	local amount = self:ResolveValue("Amount", context)
	if self.Trait and self.Trait ~= "" then
		local trait = TraitPresets[self.Trait].display_name
		return amount == 1 and
			T{self.TextTraitSingular, trait = trait} or
			T{self.TextTraitPlural, trait = trait, amount = amount}
	else
		return amount == 1 and self.TextSingular or T{self.TextPlural, amount = amount}
	end
end

UndefineClass('CheckColonistStat')
DefineClass.CheckColonistStat = {
	__parents = { "Condition", },
	properties = {
		{ id = "Condition", help = "Select the relation to the specified value.", 
			editor = "choice", default = ">=", items = function (self) return { ">=", "<=", ">", "<", "==", "~=" } end, },
		{ id = "Stat", help = "Select the colonist Stat to check for.", 
			editor = "combo", default = false, items = function (self) return StatCombo() end, },
		{ id = "Amount", help = "Set the value to check against.", 
			editor = "number", default = 0, 
			buttons = { { "Param", "StoryBit_PickParam" } }, scale = "Stat", step = 1000, min = 0, max = 100000, },
		{ id = "Description", help = "The condition description.", 
			editor = "text", default = T(297267954147, --[[ConditionDef Conditions CheckColonistStat default]] "<Stat> <Condition> <Amount>"), translate = true, },
	},
	Documentation = "Checks the specified stat value of the associated colonist.",
}

function CheckColonistStat:__eval(colonist, context)
	if not IsValid(colonist) then return false end
	
	local stat = colonist["stat_"..self.Stat:lower()]
	return self:CompareOp(stat, context)
end

UndefineClass('CheckDeaths')
DefineClass.CheckDeaths = {
	__parents = { "Condition", },
	properties = {
		{ id = "ReasonsList", help = "Limit the checked deaths to the selected reasons.", 
			editor = "string_list", default = {}, item_default = "Old age", items = function (self) return table.keys(DeathReasons, true) end, },
		{ id = "Negate", name = "Negate Condition", help = "Tick to check if the number of deaths is less or equal to the specified Count.", 
			editor = "bool", default = false, },
		{ id = "OtherThan", help = "Tick to check for any other reason than the selected.", 
			editor = "bool", default = false, },
		{ id = "Sols", help = "Specify the time range of the check.", 
			editor = "number", default = 1, 
			buttons = { { "Param", "StoryBit_PickParam" } }, },
		{ id = "Count", help = "Specify the number of dead colonists to check against.", 
			editor = "number", default = 0, 
			buttons = { { "Param", "StoryBit_PickParam" } }, },
	},
	Documentation = "Checks the number of dead colonists for the set time period, limited to the listed reasons of death.",
	Description = Untranslated("Deaths <NegText> <ReasonsText> > <Count> for the last <Sols> sols"),
	DescriptionNeg = Untranslated("Deaths <NegText> <ReasonsText> <= <Count> for the last <Sols> sols"),
}

function CheckDeaths:__eval(map_id, obj, context)
	local count = self:ResolveValue("Count", context)
	local sols = self:ResolveValue("Sols", context)
	local reasons
	if self.OtherThan then
		reasons = table.copy(DeathReasons)
		for _, reason in ipairs(self.ReasonsList) do
			reasons[reason] = nil
		end
	else
		reasons = table.invert(self.ReasonsList)
	end
	return CountColonistDeaths(reasons, sols) > count
end

function CheckDeaths:GetReasonsText()
	return Untranslated(table.concat(self.ReasonsList, ", "))
end

function CheckDeaths:GetNegText()
	return self.OtherThan and "other than" or ""
end

function CheckDeaths:__eval_relaxed(map_id, obj, context)
	return true
end

UndefineClass('CheckObjectCount')
DefineClass.CheckObjectCount = {
	__parents = { "Condition", },
	properties = {
		{ id = "Label", help = "Select the type of object you want to check for.", 
			editor = "combo", default = false, items = function (self) return LabelsCombo() end, },
		{ id = "InDome", help = "Tick to limit the check only to objects currently inside a Dome.", 
			editor = "bool", default = false, },
		{ id = "Filters", help = "Specify Filters to limit the check only to objects with the selected properties. Note: Make sure the object has these properties, i.e. don't check the Sanity of a Drone (as tempting as it is).", 
			editor = "nested_list", default = false, base_class = "Condition", },
		{ id = "Condition", help = "Select the relation to the specified value.", 
			editor = "choice", default = false, items = function (self) return { ">=", "<=", ">", "<", "==", "~=" } end, },
		{ id = "Amount", help = "Set the value to check against.", 
			editor = "number", default = false, 
			buttons = { { "Param", "StoryBit_PickParam" } }, },
		{ id = "Description", help = "The condition description.", 
			editor = "text", default = T(569587504378, --[[ConditionDef Conditions CheckObjectCount default]] "<ObjName> count <Condition> <Amount>"), translate = true, },
	},
	Documentation = 'Checks the number of specified objects, limited by the selected Filters. For example, use Label "Colonist",  filter CheckColonistStat for Sanity < 10 and filter HasTrait "Scientist" to determine the count of mad scientists in the colony.',
}

function CheckObjectCount:__eval(map_id, obj, context)
	local objs
	local city = Cities[map_id]
	if not self.InDome then
		objs = GetObjectsByLabel(city, self.Label)
	elseif obj then
		-- might also be a Construction object
		objs = obj:IsKindOf("Dome") and obj.labels[self.Label] or empty_table
	else
		objs = {}
		for _, dome in ipairs(city.labels.Dome or empty_table) do
				table.iappend(objs, dome.labels[self.Label])
		end
	end
	local count = 0
	for i = 1, #(objs or "") do
		local ok = true
		for _, condition in ipairs(self.Filters or empty_table) do
			if not condition:Evaluate(map_id, objs[i], context) then
				ok = false
				break
			end
		end
		if ok then count = count + 1 end
	end
	return self:CompareOp(count, context)
end

function CheckObjectCount:GetObjName(obj, context)
	local prefix = self.InDome and "Dome." or ""
	return Untranslated(prefix .. (self.Label or "Object"))
end

UndefineClass('CheckResource')
DefineClass.CheckResource = {
	__parents = { "Condition", },
	properties = {
		{ id = "Condition", help = "Select the relation to the specified value.", 
			editor = "choice", default = ">=", items = function (self) return { ">=", "<=", ">", "<", "==", "~=" } end, },
		{ id = "Resource", help = "Select the type of resource to check for.", 
			editor = "combo", default = false, items = function (self) return AllResourcesCombo() end, },
		{ id = "Amount", help = "Set the value to check against.", 
			editor = "number", default = 0, 
			buttons = { { "Param", "StoryBit_PickParam" } }, },
		{ id = "Description", help = "The condition description.", 
			editor = "text", default = T(549355793884, --[[ConditionDef Conditions CheckResource default]] "<ResourceText> <Condition> <Amount>"), translate = true, },
	},
	Documentation = "Checks the quantity of the specified resource against the specified value.",
}

function CheckResource:__eval(map_id, obj, context)
	local count = 0
	local amount = self:ResolveValue("Amount", context)
	local resource = self.Resource
	local city = Cities[map_id]
	if resource == "ResearchPoints" then
		count = UIColony:GetEstimatedRP()
	elseif resource == "Funding" then
		count = UIColony.funds:GetFunding()
	elseif resource == "Power" or resource == "Water" or resource == "Air" then
		resource = resource:lower()
		count = GetCityResourceOverview(city).data["total_"..resource.."_production"] or 0
		amount = amount*const.ResourceScale
	elseif resource == "StoredPower" or resource == "StoredWater" or resource == "StoredAir" then
		resource = resource:match("Stored".."(%a+)"):lower()
		count = GetCityResourceOverview(city).data["total_"..resource.."_storage"] or 0
		amount = amount*const.ResourceScale
	else --Construction Resources, Food, Fuel
		count = GetCityResourceOverview(city).data[self.Resource] or 0
		amount = amount*const.ResourceScale
	end
	
	return self:CompareOp(count, context, amount)
end

function CheckResource:GetResourceText(obj, context)
	local desc = Resources[self.Resource]
	return desc and desc.display_name or T(15, "Resource")
end

UndefineClass('CheckTechStatus')
DefineClass.CheckTechStatus = {
	__parents = { "Condition", },
	properties = {
		{ id = "Field", help = "Select the research field from which the tech is to be selected.", 
			editor = "choice", default = "All Fields", items = function (self) return ResearchFieldsCombo() end, },
		{ id = "TechId", name = "Tech Id", help = "Select a tech in the specified field.", 
			editor = "choice", default = "", items = function (self) return ResearchTechsCombo(self) end, },
		{ id = "Status", help = "Choose whether to pick a Tech which is already researched (researched), revealed but not yet researched (available) or not discovered at all (unknown).", 
			editor = "choice", default = "researched", items = function (self) return { "unknown", "available", "researched" } end, },
		{ id = "Negate", name = "Negate Condition", help = "Tick to select the opposite status.", 
			editor = "bool", default = false, },
	},
	Documentation = "Checks if the specified tech is revealed and if it is researched or not.",
}

function CheckTechStatus:__eval(map_id, obj, context)
	if not TechDef[self.TechId] then
		context:ShowError(self, "No such tech:", self.TechId)
		return
	end
	if self.Status == "researched" then
		return UIColony:IsTechResearched(self.TechId)
	elseif self.Status == "available" then
		return UIColony:IsTechResearchable(self.TechId)
	elseif self.Status == "unknown" then
		return not UIColony:IsTechDiscovered(self.TechId)
	end
end

function CheckTechStatus:GetDescription()
	local desc = TechDef[self.TechId]
	local tech_name = desc and desc.display_name or ""
	if self.Status == "researched" then
		if self.Negate then
			return T{11879, "Tech <tech_name> not researched", tech_name = tech_name}
		else
			return T{11880, "Tech <tech_name> researched", tech_name = tech_name}
		end
	elseif self.Status == "available" then
		if self.Negate then
			return T{11881, "Tech <tech_name> not available", tech_name = tech_name}
		else
			return T{11882, "Tech <tech_name> available", tech_name = tech_name}
		end
	elseif self.Status == "unknown" then
		if self.Negate then
			return T{11884, "Tech <tech_name> discovered", tech_name = tech_name}
		else
			return T{11883, "Tech <tech_name> unknown", tech_name = tech_name}
		end
	end
end

UndefineClass('CountShuttles')
DefineClass.CountShuttles = {
	__parents = { "Condition", },
	properties = {
		{ id = "Status", help = "Limit the check to shuttles in flight, refueling or idle shuttles, or count all shuttles.", 
			editor = "choice", default = "all", items = function (self) return ShuttleStatusComboItems end, },
		{ id = "Amount", help = "Set the value to check against.", 
			editor = "number", default = 0, },
		{ id = "Condition", help = "Select the relation to the specified value.", 
			editor = "choice", default = ">=", items = function (self) return { ">=", "<=", ">", "<", "==", "~=" } end, },
	},
	Description = Untranslated("Shuttle count <Condition> <Amount>"),
	Documentation = "Checks the number of shuttles in the colony, according to the specified criteria (shuttles in flight, refueling shuttles, idle shuttles, all shuttles).",
}

function CountShuttles:__eval(map_id, obj, context)
	local count = 0
	local ShuttleHubCountShuttles
	if self.Status == "all" then
		ShuttleHubCountShuttles = function(hub) 
			return #hub.shuttle_infos
		end
	elseif self.Status == "in flight" then
		ShuttleHubCountShuttles = function(hub) 
			return hub:GetFlyingShuttles()
		end
	elseif self.Status == "refueling" then
		ShuttleHubCountShuttles = function(hub) 
			return hub:GetRefuelingShuttles()
		end
	elseif self.Status == "idle" then
		ShuttleHubCountShuttles = function(hub) 
			return hub:GetIdleShuttles()
		end
	end
	local city = Cities[map_id]
	for _, shuttle_hub in pairs(city.labels.ShuttleHub or empty_table) do
		if not shuttle_hub:IsKindOf("ConstructionSite") and not shuttle_hub.destroyed then
			count = count + ShuttleHubCountShuttles(shuttle_hub)
		end
	end
	return self:CompareOp(count, context)
end

UndefineClass('CountTechsResearched')
DefineClass.CountTechsResearched = {
	__parents = { "Condition", },
	properties = {
		{ id = "Filters", help = "Pick Filters to narrow the search to the specified techs.", 
			editor = "nested_list", default = false, no_edit = true, base_class = "Condition", },
		{ id = "Condition", help = "Select the relation to the specified value.", 
			editor = "choice", default = ">=", items = function (self) return { ">=", "<=", ">", "<", "==", "~=" } end, },
		{ id = "Amount", help = "Set the value to check against.", 
			editor = "number", default = false, 
			buttons = { { "Param", "StoryBit_PickParam" } }, },
		{ id = "Description", help = "The effect description", 
			editor = "text", default = T(847100615161, --[[ConditionDef Conditions CountTechsResearched default]] "Techs researched count <Condition> <Amount>"), translate = true, },
	},
	Documentation = "Checks the number of researched Techs.",
}

function CountTechsResearched:__eval(map_id, obj, context)
	local count = 0
	local fields = table.keys(TechFields)
	for i = 1, #fields do
		local t_c, all = UIColony:TechCount(fields[i], "researched")
		count = count + t_c
	end
	return self:CompareOp(count, context)
end

UndefineClass('FounderStageCompleted')
DefineClass.FounderStageCompleted = {
	__parents = { "Condition", },
	properties = {
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = Untranslated("Founder stage completed"),
	DescriptionNeg = Untranslated("Founder stage not completed"),
	Documentation = "Checks if Founder stage is completed (colony is approved).",
}

function FounderStageCompleted:__eval(map_id, obj, context)
	return g_ColonyNotViableUntil == -1
end

function FounderStageCompleted:__eval_relaxed(map_id, obj, context)
	return true
end

UndefineClass('HasTrait')
DefineClass.HasTrait = {
	__parents = { "Condition", },
	properties = {
		{ id = "Trait", help = "Select the trait to check for.", 
			editor = "choice", default = false, items = function (self) return PresetsCombo("TraitPreset") end, },
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = Untranslated("Colonist is <Trait>"),
	DescriptionNeg = Untranslated("Colonist is not <Trait>"),
	RequiredObjClasses = {
	"Colonist",
},
	Documentation = "Checks if colonist has the specified trait.",
}

function HasTrait:__eval(map_id, obj, context)
	return obj.traits[self.Trait]
end

UndefineClass('HasWorkplace')
DefineClass.HasWorkplace = {
	__parents = { "Condition", },
	properties = {
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = Untranslated("Colonist has a workplace"),
	DescriptionNeg = Untranslated("Colonist does not have a workplace"),
	RequiredObjClasses = {
	"Colonist",
},
	Documentation = "Checks if colonist has a workplace.",
}

function HasWorkplace:__eval(map_id, obj, context)
	return not not obj.workplace
end

UndefineClass('IsAssociatedObject')
DefineClass.IsAssociatedObject = {
	__parents = { "Condition", },
	Description = Untranslated("Is Associated Object"),
	Documentation = "Checks if object is the associated object.",
}

function IsAssociatedObject:__eval(map_id, obj, context)
	if not context.object then
		context:ShowError(self, "No associated object!")
		return
	end
	return context.object == obj
end

UndefineClass('IsAtmosphereBreathable')
DefineClass.IsAtmosphereBreathable = {
	__parents = { "Condition", },
	properties = {
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = T(928878462729, --[[ConditionDef Conditions IsAtmosphereBreathable value]] "Atmosphere is breathable"),
	DescriptionNeg = T(378316015016, --[[ConditionDef Conditions IsAtmosphereBreathable value]] "Atmosphere isn't breathable"),
	Documentation = "Checks if the atmosphere is breathable",
}

function IsAtmosphereBreathable:__eval(map_id, obj, context)
	return GetAtmosphereBreathable(map_id)
end

UndefineClass('IsBuildingClass')
DefineClass.IsBuildingClass = {
	__parents = { "Condition", },
	properties = {
		{ id = "BuildingClass", name = "Building Class", help = "List of building classes to check against", 
			editor = "string_list", default = {}, item_default = "Dome", items = function (self) return ClassDescendantsList("Building") end, },
		{ id = "Template", name = "Building Template", help = "List of building templates to check against", 
			editor = "string_list", default = {}, item_default = "", items = function (self) return PresetsCombo("BuildingTemplate") end, },
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = Untranslated("Building is <BuildingClasses> <Templates>"),
	DescriptionNeg = Untranslated("Building is not <BuildingClasses> <Templates>"),
	RequiredObjClasses = {
	"Building",
},
	Documentation = "Checks if building's class is one of the specified classes (if any) and its template is one of the specified templates (if any).",
}

function IsBuildingClass:__eval(map_id, obj, context)
	if #self.BuildingClass > 0 then
		if not obj:IsKindOfClasses(self.BuildingClass) then
			return false
		end
	end
	if #self.Template > 0 then
		if not table.find(self.Template, obj.template_name) then
			return false
		end
	end
	return true
end

function IsBuildingClass:GetBuildingClasses()
	return Untranslated(table.concat(self.BuildingClass, ", "))
end

function IsBuildingClass:GetTemplates()
	return Untranslated(table.concat(self.Template, ", "))
end

UndefineClass('IsBuildingWorking')
DefineClass.IsBuildingWorking = {
	__parents = { "Condition", },
	properties = {
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = Untranslated("Working"),
	DescriptionNeg = Untranslated("Not working"),
	RequiredObjClasses = {
	"Building",
},
	Documentation = "Checks if the building is working.",
}

function IsBuildingWorking:__eval(map_id, obj, context)
	return obj.working
end

UndefineClass('IsCommander')
DefineClass.IsCommander = {
	__parents = { "Condition", },
	properties = {
		{ id = "CommanderProfile", name = "Commander Profile", help = "Choose the commander profile to check against.", 
			editor = "choice", default = false, items = function (self) return PresetsCombo("CommanderProfilePreset") end, },
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = T(715647837632, --[[ConditionDef Conditions IsCommander value]] "<display_name('CommanderProfilePreset',CommanderProfile)>"),
	DescriptionNeg = T(370328927689, --[[ConditionDef Conditions IsCommander value]] "Commander Profile: not <display_name('CommanderProfilePreset',CommanderProfile)>"),
	Documentation = "Checks if player's Commander profile is the same as the specified.",
}

function IsCommander:__eval(map_id, obj, context)
	return GetCommanderProfile().name == self.CommanderProfile
end

function IsCommander:__eval_relaxed(map_id, obj, context)
	return true
end

UndefineClass('IsCommander2')
DefineClass.IsCommander2 = {
	__parents = { "Condition", },
	properties = {
		{ id = "CommanderProfile1", name = "Commander Profile 1", help = "Choose the first commander profile to check against.", 
			editor = "choice", default = false, items = function (self) return PresetsCombo("CommanderProfilePreset") end, },
		{ id = "CommanderProfile2", name = "Commander Profile 2", help = "Choose the second commander profile to check against.", 
			editor = "choice", default = false, items = function (self) return PresetsCombo("CommanderProfilePreset") end, },
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = T(954742980035, --[[ConditionDef Conditions IsCommander2 value]] "<display_name('CommanderProfilePreset',CommanderProfile1)> or <display_name('CommanderProfilePreset',CommanderProfile2)>"),
	DescriptionNeg = T(267085582298, --[[ConditionDef Conditions IsCommander2 value]] "Commander Profile: not <display_name('CommanderProfilePreset',CommanderProfile1)> or <display_name('CommanderProfilePreset',CommanderProfile2)>"),
	Documentation = "Checks if player's Commander profile is one of the two specified.",
}

function IsCommander2:__eval(map_id, obj, context)
	local commander = GetCommanderProfile().name 
	return commander == self.CommanderProfile1 or commander==self.CommanderProfile2
end

function IsCommander2:__eval_relaxed(map_id, obj, context)
	return true
end

UndefineClass('IsCommanders')
DefineClass.IsCommanders = {
	__parents = { "Condition", },
	properties = {
		{ id = "Commanders", help = "List of commanders to check against.", 
			editor = "string_list", default = {}, item_default = "", items = function (self) return PresetsCombo("CommanderProfilePreset") end, },
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = T(282335593996, --[[ConditionDef Conditions IsCommanders value]] "Commander is <NamesText>"),
	DescriptionNeg = T(403412127044, --[[ConditionDef Conditions IsCommanders value]] "Commander isn't <NamesText>"),
	Documentation = "Checks if player's Commander profile is one of the specified.",
}

function IsCommanders:__eval(map_id, obj, context)
	return table.find(self.Commanders, GetCommanderProfile().name)
end

function IsCommanders:GetNamesText()
	local items = {}
	local commanders = Presets.CommanderProfilePreset and Presets.CommanderProfilePreset.Default
	for i, name in ipairs(self.Commanders) do
		items[i] = commanders[name] and commanders[name].display_name or ""
	end
	return table.concat(items, ", ")
end

function IsCommanders:__eval_relaxed(map_id, obj, context)
	return true
end

UndefineClass('IsCustomAnomaly')
DefineClass.IsCustomAnomaly = {
	__parents = { "Condition", },
	properties = {
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
		{ id = "id", help = "Set the anomaly ID", 
			editor = "text", default = false, },
	},
	Description = Untranslated("Is associated anomaly"),
	DescriptionNeg = Untranslated("Not associated anomaly"),
	RequiredObjClasses = {
	"PlanetaryAnomaly",
	"RocketBase",
},
	Documentation = "Checks if asociated rocket is the Founder's rocket",
}

function IsCustomAnomaly:__eval(map_id, obj, context)
	if IsKindOf(obj, "RocketExpedition") then
		obj = obj.expedition and obj.expedition.anomaly
	end
	if IsKindOf(obj, "PlanetaryAnomaly") then
		if self.id then
			return obj.custom_id == self.id
		else
			return obj == context.object
		end
	end
end

UndefineClass('IsFoundersRocket')
DefineClass.IsFoundersRocket = {
	__parents = { "Condition", },
	properties = {
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = Untranslated("Rocket is Founder"),
	DescriptionNeg = Untranslated("Rocket is not Founder"),
	RequiredObjClasses = {
	"RocketBase",
},
	Documentation = "Checks if asociated rocket is the Founder's rocket",
}

function IsFoundersRocket:__eval(map_id, obj, context)
	return obj.category == "founder"
end

UndefineClass('IsMapEnvironment')
DefineClass.IsMapEnvironment = {
	__parents = { "Condition", },
	properties = {
		{ id = "Negate", name = "Negate Condition", help = "If true, checks for the opposite condition", 
			editor = "bool", default = false, },
		{ id = "SelectedMapEnvironment", help = "Map Environment to check", 
			editor = "combo", default = "Surface", items = function (self) return EnvironmentTypes end, },
	},
	Description = T(835138577012, --[[ConditionDef Conditions IsMapEnvironment value]] "Is map environment <SelectedMapEnvironment>"),
	DescriptionNeg = T(605538238925, --[[ConditionDef Conditions IsMapEnvironment value]] "Is map environment not <SelectedMapEnvironment>"),
	Documentation = "Checks if the map environment is of specified type.",
}

function IsMapEnvironment:__eval(map_id, obj, context)
	local map_data = ActiveMaps[map_id]
	return map_data and map_data.Environment == self.SelectedMapEnvironment
end

UndefineClass('IsMysteryActive')
DefineClass.IsMysteryActive = {
	__parents = { "Condition", },
	properties = {
		{ id = "Mystery", name = "Mystery", help = "Select the mystery to check for.", 
			editor = "choice", default = false, items = function (self) return ClassDescendantsList("MysteryBase") end, },
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = Untranslated("Is mystery <Mystery> active"),
	DescriptionNeg = Untranslated("Is mystery <Mystery> not active"),
	Documentation = "Checks whether the specified mystery is active in this playthrough.",
}

function IsMysteryActive:__eval(map_id, obj, context)
	return self.Mystery and IsKindOf(UIColony.mystery, self.Mystery)
end

function IsMysteryActive:__eval_relaxed(map_id, obj, context)
	return true
end

UndefineClass('IsRocketID')
DefineClass.IsRocketID = {
	__parents = { "Condition", },
	properties = {
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
		{ id = "rocket_id", name = "Rocket ID", help = "Specify the rocket ID to check for.", 
			editor = "text", default = false, },
	},
	Description = T(791896416077, --[[ConditionDef Conditions IsRocketID value]] "Is Rocket Id <rocket_id>"),
	DescriptionNeg = T(342912052918, --[[ConditionDef Conditions IsRocketID value]] "Is Rocket Id not <rocket_id>"),
	Documentation = "Checks if the rocket ID is the one specified.",
}

function IsRocketID:__eval(map_id, obj, context)
	return obj.custom_id == self.rocket_id
end

UndefineClass('IsRocketStatus')
DefineClass.IsRocketStatus = {
	__parents = { "Condition", },
	properties = {
		{ id = "Status", help = "Select a rocket status to check for.", 
			editor = "choice", default = "on earth", items = function (self) return RocketStatusComboItems() end, },
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = Untranslated("Is rocket <Status>"),
	DescriptionNeg = Untranslated("Is rocket not <Status>"),
	RequiredObjClasses = {
	"RocketBase",
},
	Documentation = "Checks if the associated rocket is in the specified status.",
}

function IsRocketStatus:__eval(map_id, obj, context)
	return obj:IsRocketStatus(self.Status)
end

UndefineClass('IsRocketType')
DefineClass.IsRocketType = {
	__parents = { "Condition", },
	properties = {
		{ id = "Type", help = "Select a rocket type to check for.", 
			editor = "choice", default = "Any", items = function (self) return RocketTypeComboItems() end, },
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	RequiredObjClasses = {
	"RocketBase",
},
	Documentation = "Checks whether the associated rocket is the specified type.",
}

function IsRocketType:GetEditorView()
	return self.Negate and T(11885, "Rocket is <Type>") or T(11886, "Rocket is not <Type>")
end

function IsRocketType:__eval(map_id, obj, context)
	if self.Type == "Any" then return true end
	if self.Type == "Trade" then return obj:IsKindOf("TradeRocket") end
	if self.Type == "Refugee" then return obj:IsKindOf("RefugeeRocket") end
	if self.Type == "Lander" then return obj:IsKindOf("LanderRocket") end
	return (self.Type == "Cargo") == (obj.category == "cargo")
end

UndefineClass('IsSolInRange')
DefineClass.IsSolInRange = {
	__parents = { "Condition", },
	properties = {
		{ id = "Min", name = "Min sol", help = "Set the lowest valid value for the current Sol.", 
			editor = "number", default = 0, 
			buttons = { { "Param", "StoryBit_PickParam" } }, },
		{ id = "Max", name = "Max sol", help = "Set the highest valid value for the current Sol.", 
			editor = "number", default = 10, 
			buttons = { { "Param", "StoryBit_PickParam" } }, },
	},
	Description = Untranslated("<Min> <= sol <= <Max>"),
	Documentation = "Checks whether the current Sol is in the specified time range.",
}

function IsSolInRange:__eval(map_id, obj, context)
	return UIColony.day>=self:ResolveValue("Min",context) and UIColony.day<=self:ResolveValue("Max",context)
end

UndefineClass('IsSpecialProjectCompleted')
DefineClass.IsSpecialProjectCompleted = {
	__parents = { "Condition", },
	properties = {
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
		{ id = "project_id", name = "project_id", help = "Project to chech for.", 
			editor = "preset_id", default = "", preset_class = "POI", },
	},
	EditorView = Untranslated("Is <project_id> completed"),
	EditorViewNeg = Untranslated("Is <project_id> not completed"),
	Documentation = "Check if the specified special project has been completed at least onece.",
}

function IsSpecialProjectCompleted:__eval(map_id, obj, context)
	if not self.project_id then return false end
	return  g_SpecialProjectCompleted and g_SpecialProjectCompleted[self.project_id] and  g_SpecialProjectCompleted[self.project_id]>0
end

function IsSpecialProjectCompleted:GetWarning()
	if not self.project_id  then return "Specify project id" end
end

UndefineClass('IsSponsor')
DefineClass.IsSponsor = {
	__parents = { "Condition", },
	properties = {
		{ id = "SponsorName", name = "Sponsor Name", help = "Select a mission sponsor to check for.", 
			editor = "choice", default = false, items = function (self) return PresetsCombo("MissionSponsorPreset") end, },
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = T(393331541770, --[[ConditionDef Conditions IsSponsor value]] "<display_name('MissionSponsorPreset',SponsorName)>"),
	DescriptionNeg = T(256907425108, --[[ConditionDef Conditions IsSponsor value]] "not <display_name('MissionSponsorPreset',SponsorName)>"),
	Documentation = "Check if the current mission sponsor is the specified one.",
}

function IsSponsor:__eval(map_id, obj, context)
	return GetMissionSponsor().name == self.SponsorName
end

function IsSponsor:__eval_relaxed(map_id, obj, context)
	return true
end

UndefineClass('IsSponsors')
DefineClass.IsSponsors = {
	__parents = { "Condition", },
	properties = {
		{ id = "Sponsors", help = "List of sponsors to check against.", 
			editor = "string_list", default = {}, item_default = "", items = function (self) return PresetsCombo("MissionSponsorPreset") end, },
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = T(299678364320, --[[ConditionDef Conditions IsSponsors value]] "Sponsor is <NamesText>"),
	DescriptionNeg = T(886907915754, --[[ConditionDef Conditions IsSponsors value]] "Sponsor isn't <NamesText>"),
	Documentation = "Check if the current mission sponsor is one of the specified ones.",
}

function IsSponsors:__eval(map_id, obj, context)
	return table.find(self.Sponsors, GetMissionSponsor().name)
end

function IsSponsors:GetNamesText()
	local items = {}
	local sponsors = Presets.MissionSponsorPreset and Presets.MissionSponsorPreset.Default
	for i, name in ipairs(self.Sponsors) do
		items[i] = sponsors[name] and sponsors[name].display_name or ""
	end
	return table.concat(items, ", ")
end

function IsSponsors:__eval_relaxed(map_id, obj, context)
	return true
end

UndefineClass('IsSupplyPod')
DefineClass.IsSupplyPod = {
	__parents = { "Condition", },
	properties = {
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = Untranslated("Rocket is a Supply Pod"),
	DescriptionNeg = Untranslated("Rocket is not a Supply Pod"),
	RequiredObjClasses = {
	"RocketBase",
},
	Documentation = "Check if the associated object is a Supply Pod.",
}

function IsSupplyPod:__eval(map_id, obj, context)
	return IsKindOf(obj, "SupplyPod")
end

UndefineClass('IsTechId')
DefineClass.IsTechId = {
	__parents = { "Condition", },
	properties = {
		{ id = "Field", help = "Select the research field from which the tech is to be selected.", 
			editor = "choice", default = false, items = function (self) return ResearchFieldsCombo() end, },
		{ id = "TechId", name = "Tech Id", help = "Select a tech in the specified field.", 
			editor = "choice", default = false, items = function (self) return ResearchTechsCombo(self) end, },
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = Untranslated("Is tech <TechId>"),
	DescriptionNeg = Untranslated("Is tech not <TechId>"),
	RequiredObjClasses = {
	"TechPreset",
},
	Documentation = "Check if the associated tech is the one specified.",
}

function IsTechId:__eval(map_id, obj, context)
	return obj.id == self.TechId
end

UndefineClass('IsWorkplace')
DefineClass.IsWorkplace = {
	__parents = { "Condition", },
	properties = {
		{ id = "Building", help = "Select a workplace for the colonist.", 
			editor = "combo", default = "", items = function (self) return BuildingsCombo() end, },
	},
	Description = Untranslated("Colonist workplace is <Building>"),
	RequiredObjClasses = {
	"Colonist",
},
	Documentation = "Check if the associated colonist works in the specified building.",
}

function IsWorkplace:__eval(colonist, context)
	return colonist.workplace and colonist.workplace.template_name == self.Building
end

UndefineClass('PickFromLabel')
DefineClass.PickFromLabel = {
	__parents = { "Condition", },
	properties = {
		{ id = "Label", help = "Select the label from which to choose the object.", 
			editor = "combo", default = false, items = function (self) return LabelsCombo end, },
		{ id = "Conditions", help = "List the conditions the object has to fulfill in order to be selected.", 
			editor = "nested_list", default = false, base_class = "Condition", },
	},
	Description = Untranslated("Pick from <Label>, where <ConditionsFormat>"),
	Documentation = "Picks a random object from a specific label, fulfilling the specified conditions.",
}

function PickFromLabel:ConditionsFormat()
	local t = {}
	for _, cond in ipairs(self.Conditions or empty_table) do
		t[#t + 1] = T{cond.EditorView, cond}
	end
	return table.concat(t, T(1000736, ", "))
end

function PickFromLabel:__eval(map_id, obj, context)
	if not self.Label then
		context:ShowError(self, "Label required!")
		return
	end
	local city = Cities[map_id]
	local objs = GetObjectsByLabel(city, self.Label)
	if not objs or #objs == 0 then return end
	
	local list = {}
	for i = 1, #objs do
		local obj, ok = objs[i], true
		for _, condition in ipairs(self.Conditions or empty_table) do
			if not condition:Evaluate(map_id, obj, context) then
				ok = false
				break
			end
		end
		if ok then list[#list + 1] = obj end
	end
	
	if #list > 0 then
		context.object = AsyncRandElement(list)
		return true
	end
end

function PickFromLabel:GetWarning()
	if (self.Label or "") == "" then
		return "Label required!"
	end
	return Condition.GetWarning(self)
end

UndefineClass('PickResident')
DefineClass.PickResident = {
	__parents = { "Condition", },
	properties = {
		{ id = "ParentBuildingLabel", help = "Select a parent building to pick a resident from.", 
			editor = "combo", default = false, items = function (self) return LabelsCombo end, },
		{ id = "ResidentConditions", help = "List the conditions the colonist has to satisfy to be selected.", 
			editor = "nested_list", default = false, base_class = "Condition", },
	},
	Description = Untranslated("Pick Resident"),
	Documentation = "Picks a random resident of the specified building who also satisfies certain conditions.",
}

function PickResident:__eval(map_id, obj, context)
	local city = Cities[map_id]
	local objs = GetObjectsByLabel(city, self.ParentBuildingLabel)
	if not objs or #objs == 0 then return end
	
	local building = AsyncRandElement(objs)
	if not building:IsKindOf("Residence") then return end
	local colonists = building.colonists
	
	local list = {}
	for i = 1, #colonists do
		local colonist, ok = colonists[i], true
		for _, condition in ipairs(self.ResidentConditions or empty_table) do
			if not condition:Evaluate(map_id, colonist, context) then
				ok = false
				break
			end
		end
		if ok then list[#list + 1] = colonist end
	end
	
	if #list > 0 then
		context.object = AsyncRandElement(list)
		return true
	end
end

UndefineClass('PickRocketWithStatus')
DefineClass.PickRocketWithStatus = {
	__parents = { "Condition", },
	properties = {
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
		{ id = "Status", help = "Select the desired status of the rocket.", 
			editor = "choice", default = "on earth", items = function (self) return RocketStatusComboItems() end, },
	},
	Description = Untranslated("Pick a rocket which is <Status>"),
	DescriptionNeg = Untranslated("Pick a rocket which is not <Status>"),
	Documentation = "Pick a random rocket with the specified status.",
}

function PickRocketWithStatus:__eval(map_id, obj, context)
	local matching = {}
	local city = Cities[map_id]
	for _, rocket in ipairs(city.labels.SupplyRocket or empty_table) do
		if rocket:IsRocketStatus(self.Status) then
			matching[#matching + 1] = rocket
		end
	end
	
	if #matching > 0 then
		context.object = AsyncRandElement(matching)
		return true
	end
end

UndefineClass('PickShuttle')
DefineClass.PickShuttle = {
	__parents = { "Condition", },
	Description = Untranslated("Pick random flying shuttle"),
	Documentation = "Pick a random flying shuttle.",
}

function PickShuttle:__eval(map_id, obj, context)
	local city = Cities[map_id]
	local shuttles = city.labels.CargoShuttle
	if #shuttles > 0 then
		context.object = AsyncRandElement(shuttles)
		return true
	end
end

UndefineClass('PickWorker')
DefineClass.PickWorker = {
	__parents = { "Condition", },
	properties = {
		{ id = "ParentBuildingLabel", help = "Select the building where the colonist works.", 
			editor = "combo", default = false, items = function (self) return LabelsCombo end, },
		{ id = "WorkerConditions", help = "List the conditions the colonist has to satisfy to be selected.", 
			editor = "nested_list", default = false, base_class = "Condition", },
	},
	Description = Untranslated("Pick Worker"),
	Documentation = "Pick a colonist with the specified workplace.",
}

function PickWorker:__eval(map_id, obj, context)
	local city = Cities[map_id]
	local objs = GetObjectsByLabel(city, self.ParentBuildingLabel)
	if not objs or #objs == 0 then return end
	
	local building = AsyncRandElement(objs)
	if not building:IsKindOf("Workplace") then return end
	
	local colonists = {}
	for i = 1, #building.workers do
		local shift = building.workers[i]
		for j = 1, #shift do
			table.insert(colonists, shift[j])
		end
	end
	
	local list = {}
	for i = 1, #colonists do
		local colonist, ok = colonists[i], true
		for _, condition in ipairs(self.WorkerConditions or empty_table) do
			if not condition:Evaluate(map_id, colonist, context) then
				ok = false
				break
			end
		end
		if ok then list[#list + 1] = colonist end
	end
	
	if #list > 0 then
		context.object = AsyncRandElement(list)
		return true
	end
end

UndefineClass('SupplyMissionsEnabled')
DefineClass.SupplyMissionsEnabled = {
	__parents = { "Condition", },
	properties = {
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = Untranslated("Supply missions enabled"),
	DescriptionNeg = Untranslated("Supply missions disabled"),
	Documentation = "Checks whether supply missions are enabled.",
}

function SupplyMissionsEnabled:__eval(map_id, obj, context)
	return g_Consts.SupplyMissionsEnabled == 1
end

UndefineClass('TerraformingActive')
DefineClass.TerraformingActive = {
	__parents = { "Condition", },
	properties = {
		{ id = "Negate", name = "Negate Condition", help = "if true, checks for the opposite condition", 
			editor = "bool", default = false, },
	},
	Description = T(292809665492, --[[ConditionDef Conditions TerraformingActive value]] "Terraforming is active"),
	DescriptionNeg = T(714483655704, --[[ConditionDef Conditions TerraformingActive value]] "Terraforming is not active"),
	Documentation = "Checks if terraforming is active in the current playthrough.",
}

function TerraformingActive:__eval(map_id, obj, context)
	return IsDlcAvailable("armstrong") and not g_NoTerraforming
end

AreDomesOpen.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 24, AreDomesOpen.__eval)
AreDomesOpen.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 36, AreDomesOpen.__eval)
CanCauseFault.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 51, CanCauseFault.__eval)
CheckAverageComfort.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 102, CheckAverageComfort.__eval)
CheckAverageComfort.__eval_relaxed = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 111, CheckAverageComfort.__eval_relaxed)
CheckAverageMorale.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 145, CheckAverageMorale.__eval)
CheckAverageMorale.__eval_relaxed = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 154, CheckAverageMorale.__eval_relaxed)
CheckBuildingCount.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 192, CheckBuildingCount.__eval)
CheckBuildingCount.GetDescription = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 211, CheckBuildingCount.GetDescription)
CheckColonistCount.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 268, CheckColonistCount.__eval)
CheckColonistCount.GetDescription = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 285, CheckColonistCount.GetDescription)
CheckColonistStat.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 336, CheckColonistStat.__eval)
CheckDeaths.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 396, CheckDeaths.__eval)
CheckDeaths.GetReasonsText = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 413, CheckDeaths.GetReasonsText)
CheckDeaths.GetNegText = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 419, CheckDeaths.GetNegText)
CheckDeaths.__eval_relaxed = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 426, CheckDeaths.__eval_relaxed)
CheckObjectCount.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 472, CheckObjectCount.__eval)
CheckObjectCount.GetObjName = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 503, CheckObjectCount.GetObjName)
CheckResource.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 543, CheckResource.__eval)
CheckResource.GetResourceText = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 571, CheckResource.GetResourceText)
CheckTechStatus.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 613, CheckTechStatus.__eval)
CheckTechStatus.GetDescription = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 629, CheckTechStatus.GetDescription)
CountShuttles.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 666, CountShuttles.__eval)
CountTechsResearched.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 752, CountTechsResearched.__eval)
FounderStageCompleted.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 787, FounderStageCompleted.__eval)
FounderStageCompleted.__eval_relaxed = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 794, FounderStageCompleted.__eval_relaxed)
HasTrait.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 841, HasTrait.__eval)
HasWorkplace.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 883, HasWorkplace.__eval)
IsAssociatedObject.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 907, IsAssociatedObject.__eval)
IsAtmosphereBreathable.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 943, IsAtmosphereBreathable.__eval)
IsBuildingClass.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 992, IsBuildingClass.__eval)
IsBuildingClass.GetBuildingClasses = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1015, IsBuildingClass.GetBuildingClasses)
IsBuildingClass.GetTemplates = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1021, IsBuildingClass.GetTemplates)
IsBuildingWorking.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1063, IsBuildingWorking.__eval)
IsCommander.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1101, IsCommander.__eval)
IsCommander.__eval_relaxed = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1108, IsCommander.__eval_relaxed)
IsCommander2.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1152, IsCommander2.__eval)
IsCommander2.__eval_relaxed = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1160, IsCommander2.__eval_relaxed)
IsCommanders.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1197, IsCommanders.__eval)
IsCommanders.GetNamesText = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1203, IsCommanders.GetNamesText)
IsCommanders.__eval_relaxed = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1215, IsCommanders.__eval_relaxed)
IsCustomAnomaly.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1263, IsCustomAnomaly.__eval)
IsFoundersRocket.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1314, IsFoundersRocket.__eval)
IsMapEnvironment.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1351, IsMapEnvironment.__eval)
IsMysteryActive.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1392, IsMysteryActive.__eval)
IsMysteryActive.__eval_relaxed = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1399, IsMysteryActive.__eval_relaxed)
IsRocketID.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1438, IsRocketID.__eval)
IsRocketStatus.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1486, IsRocketStatus.__eval)
IsRocketType.GetEditorView = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1514, IsRocketType.GetEditorView)
IsRocketType.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1528, IsRocketType.__eval)
IsSolInRange.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1569, IsSolInRange.__eval)
IsSpecialProjectCompleted.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1614, IsSpecialProjectCompleted.__eval)
IsSpecialProjectCompleted.GetWarning = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1621, IsSpecialProjectCompleted.GetWarning)
IsSponsor.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1654, IsSponsor.__eval)
IsSponsor.__eval_relaxed = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1661, IsSponsor.__eval_relaxed)
IsSponsors.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1698, IsSponsors.__eval)
IsSponsors.GetNamesText = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1704, IsSponsors.GetNamesText)
IsSponsors.__eval_relaxed = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1716, IsSponsors.__eval_relaxed)
IsSupplyPod.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1758, IsSupplyPod.__eval)
IsTechId.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1811, IsTechId.__eval)
IsWorkplace.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1848, IsWorkplace.__eval)
PickFromLabel.ConditionsFormat = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1880, PickFromLabel.ConditionsFormat)
PickFromLabel.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1891, PickFromLabel.__eval)
PickFromLabel.GetWarning = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1920, PickFromLabel.GetWarning)
PickResident.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 1946, PickResident.__eval)
PickRocketWithStatus.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 2018, PickRocketWithStatus.__eval)
PickShuttle.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 2052, PickShuttle.__eval)
PickWorker.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 2080, PickWorker.__eval)
SupplyMissionsEnabled.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 2153, SupplyMissionsEnabled.__eval)
TerraformingActive.__eval = SetFuncDebugInfo("@Data/ClassDef-Conditions.lua", 2185, TerraformingActive.__eval)
