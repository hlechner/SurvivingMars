InitDoneMethods[#InitDoneMethods + 1] = "BuildingUpdate"
RecursiveCallOrder.BuildingUpdate = true
InitDoneMethods[#InitDoneMethods + 1] = "BuildingDailyUpdate"

AutoResolveMethods.GatherConstructionStatuses = true
AutoResolveMethods.GetWorkNotPossibleReason = "or"
AutoResolveMethods.GetWorkNotPermittedReason = "or"
AutoResolveMethods.UpdateAttachedSigns = true
AutoResolveMethods.OnSetWorking = true
AutoResolveMethods.MoveInside = true
AutoResolveMethods.OnDestroyed = true
AutoResolveMethods.SetSupply = true
AutoResolveMethods.SetPriority = true
AutoResolveMethods.ShouldShowNotConnectedToGridSign = "or"
AutoResolveMethods.IsSuitable = "and"
AutoResolveMethods.InitConstruction = true
AutoResolveMethods.RoverWork = true
AutoResolveMethods.GetDemolishObjs = true

BuildCategories = {
	{ id = "Infrastructure",      name = T(78, "Infrastructure"),              image = "UI/Icons/bmc_infrastructure.tga",     highlight = "UI/Icons/bmc_infrastructure_shine.tga" },
	{ id = "Power",               name = T(79, "Power"),                       image = "UI/Icons/bmc_power.tga",              highlight= "UI/Icons/bmc_power_shine.tga" },
	{ id = "Production",          name = T(80, "Production"),                  image = "UI/Icons/bmc_building_resources.tga", highlight= "UI/Icons/bmc_building_resources_shine.tga" },
	{ id = "Life-Support",        name = T(81, "Life Support"),                image = "UI/Icons/bmc_life_support.tga",       highlight= "UI/Icons/bmc_life_support_shine.tga" },
	{ id = "Storages",            name = T(82, "Storages"),                    image = "UI/Icons/bmc_building_storages.tga",  highlight= "UI/Icons/bmc_building_storages_shine.tga" },
	{ id = "Domes",               name = T(83, "Domes"),                       image = "UI/Icons/bmc_domes.tga",              highlight= "UI/Icons/bmc_domes_shine.tga" },
	{ id = "Habitats",            name = T(84, "Homes, Education & Research"), image = "UI/Icons/bmc_habitats.tga",           highlight= "UI/Icons/bmc_habitats_shine.tga" },	
	{ id = "Dome Services",       name = T(85, "Dome Services"),               image = "UI/Icons/bmc_dome_buildings.tga",     highlight= "UI/Icons/bmc_dome_buildings_shine.tga" },
	{ id = "Dome Spires",         name = T(86, "Dome Spires"),                 image = "UI/Icons/bmc_dome_spires.tga",        highlight= "UI/Icons/bmc_dome_spires_shine.tga" },
	{ id = "Decorations",         name = T(87, "Decorations"),                 image = "UI/Icons/bmc_decorations.tga",        highlight= "UI/Icons/bmc_decorations_shine.tga" },
	{ id = "Outside Decorations", name = T(11408, "Outside Decorations"),      image = "UI/Icons/bmc_outside_decorations.tga",highlight= "UI/Icons/bmc_outside_decorations_shine.tga" },
	{ id = "Wonders",             name = T(88, "Wonders"),                     image = "UI/Icons/bmc_wonders.tga",            highlight= "UI/Icons/bmc_wonders_shine.tga" },
	{ id = "Landscaping",         name = T(12424, "Landscaping"),              image = "UI/Icons/bmc_landscaping.tga",        highlight= "UI/Icons/bmc_landcaping_shine.tga"},
	{ id = "Terraforming",        name = T(12476, "Terraforming"),             image = "UI/Icons/bmc_terraforming.tga",       highlight= "UI/Icons/bmc_terraforming_shine.tga"},
	{ id = "Hidden",              name = T(1000155, "Hidden"),                 image = "UI/Icons/bmc_placeholder.tga",        highlight= "UI/Icons/bmc_placeholder_shine.tga" },
}


invalid_entity = "Hex1_Placeholder"

function GetBuildCategoryIds()
	local ids = {}
	for i = 1, #BuildCategories do
		ids[#ids + 1] = BuildCategories[i].id
	end
	for id in pairs(BuildMenuSubcategories) do
		ids[#ids + 1] = id
	end
	return ids
end

function BuildingClassesCombo()
	local list = ClassDescendantsList("Building")
	table.insert(list, 1, "")
	return list
end

function BuildingFromGotoTarget(target)
	return target
end

GlobalVar("DisabledInEnvironment", {})
local function GetDisabledEnvironments(building_id)
	return DisabledInEnvironment[building_id] or table.filter(GetPropertiesArray(BuildingTemplates[building_id], "disabled_in_environment"), function(environment) return environment ~= "" end)
end

function EnableInEnvironment(building_id, environment)
	DisabledInEnvironment[building_id] = GetDisabledEnvironments(building_id)
	table.remove_entry(DisabledInEnvironment[building_id], environment)
end

function DisableInEnvironment(building_id, environment)
	DisabledInEnvironment[building_id] = GetDisabledEnvironments(building_id)
	table.insert_unique(DisabledInEnvironment[building_id], environment)
end

function IsBuildingAllowedIn(building_id, environments)
	DisabledInEnvironment[building_id] = GetDisabledEnvironments(building_id)
	for _,environment in pairs(environments or empty_table) do
		if table.find(DisabledInEnvironment[building_id], environment) ~= nil then
			return false
		end
	end
	return true
end

function IsCargoLocked(def)
	local sponsor = g_CurrentMissionParams and g_CurrentMissionParams.idMissionSponsor or ""
	local locked = def.locked
	if locked and type(def.verifier) == "function" then 
		locked = not def.verifier(def, sponsor)
	else
		locked = false
	end
	return locked
end

local function CitiesHavePrefab(cities, prefab)
	for _, city in ipairs(cities) do
		if city:GetPrefabs(prefab) > 0 then
			return true
		end
	end
	return false
end

function GetAccessiblePrefabs(cities, environments)
	local cities = cities or { MainCity }
	local prefabs = {}
	for _,def in ipairs(ResupplyItemDefinitions) do
		local template = BuildingTemplates[def.id]
		if template and template.can_refab then
			local building_allowed = IsBuildingAllowedIn(template.id, environments)
			if building_allowed then
				local building_researched = IsBuildingTechResearched(template.id)
				local prerequisites_overridden = BuildMenuPrerequisiteOverrides[template.id] == true
				local building_unlocked = not def.locked or not IsCargoLocked(def) or prerequisites_overridden -- Remove function once Cargo is configured properly
				local building_available = (building_unlocked and building_researched) or CitiesHavePrefab(cities, template.id)
				if building_available then
					table.insert(prefabs, def)
				end
			end
		end
	end
	return prefabs
end

----------------------------------------

--[[@@@
@class Building
Building is the base template class associated with [building templates](ModItemBuildingTemplate.md.html). The template must define a template class type which is then the type of the object that would be instantiated when a template object is created. Specifically, for [building templates](ModItemBuildingTemplate.md.html) this class type may be Building or any Building derived class. The template class should implement all possible functionality of the template object, while the template itself defines its initialization properties.

The Building class is the base template functionality for all buildings in the game and holds a large part of the common functionality of all buildings. A large part of it comes from its parents, so consider examining them to glimpse further into what is readily available in it.

Notable children: [ElectricityProducer](LuaFunctionDoc_ElectricityProducer.md.html), [ElectricityConsumer](LuaFunctionDoc_ElectricityConsumer.md.html), [ElectricityStorage](LuaFunctionDoc_ElectricityStorage.md.html), [WaterProducer](LuaFunctionDoc_WaterProducer.md.html), [AirProducer](LuaFunctionDoc_AirProducer.md.html), [LifeSupportConsumer](LuaFunctionDoc_LifeSupportConsumer.md.html), [AirStorage](LuaFunctionDoc_AirStorage.md.html), [WaterStorage](LuaFunctionDoc_WaterStorage.md.html), [StorageWithIndicator](LuaFunctionDoc_StorageWithIndicator.md.html).

All buildings have a working state represented in the "working" bool member. Don't confuse with "ui_working" which is the state of the infopanel working button. There are two major groups of reasons to prevent a building from working. The IsWorkPossible checks if the game rules allow for the building to work. For example, for a building that is currently not supplied with electricity, but requires it, IsWorkPossible would return false. The IsWorkPermitted function returns the state of the second major group of reasons that prevent a building from working - user interaction. If the user forbids the building from working in any way this function should return false. For example, the infopanel button to stop a building from working is associated with IsWorkPermitted. There can be miriads of reasons for a building to not work, the reasons can be polled with GetNotWorkingReason which returns a humanly readable (not localized) string. The family of functions dealing with the working state of a building can be found in the [BaseBuilding](LuaFunctionDoc_BaseBuilding.md.html).

Buildings can have up to three upgrades aquired and applied throughout the game session. The relevant properties needed to define them on per [building template](ModItemBuildingTemplate.md.html) basis are located in the [UpgradableBuilding](LuaFunctionDoc_UpgradableBuilding.md.html) parent class, and can be used directly in a template definition to spec upgrades. Functions dealing with upgrades are located in the Building class.
--]]
DefineClass.Building = {
	__parents = { "ClassTemplateObject", "Shapeshifter", "BaseBuilding", "TaskRequester", "AutoAttachObject", "GridObject", "PinnableObject", "Constructable", "CityObject", "BuildingRevealDarkness", "UpgradableBuilding", "ComponentCustomData", "NightLightObject", "Demolishable", "Refabable", "WaypointsObj", "RequiresMaintenance", "HasConsumption", "SkinChangeable", "InfopanelObj", "ColorizableObject", "Renamable", "SafariSight", "Shroudable" },
	flags = { efBuilding = true, gofPermanent = true, gofTemporalConstructionBlock = true },
	__hierarchy_cache = true,
	
	UpdateConsumption = BaseBuilding.UpdateConsumption,
	
	properties = {
		{ template = true, name = T(1000067, "Display Name"),     id = "display_name",      category = "General",  editor = "text",         default = "", translate = true, },
		{ template = true, name = T(151, "Display Name (pl)"),    id = "display_name_pl",   category = "General",  editor = "text",         default = "", translate = true, },
		{ template = true, name = T(1000017, "Description"),      id = "description",       category = "General",  editor = "text",         default = "", translate = true, },
		
		{ template = true, name = T(152, "Build Menu Category"),  id = "build_category",    category = "General",  editor = "combo", default = "", items = GetBuildCategoryIds, },
		{ template = true, name = T(153, "Build Menu Icon"),      id = "display_icon",      category = "General",  editor = "browse",       default = "", folder = "UI" },
		{ template = true, name = T(154, "Build Menu Pos"),       id = "build_pos",         category = "General",  editor = "number",       default = 1, },
		{ template = true, name = T(155, "Entity"),               id = "entity",            category = "General",  editor = "dropdownlist", default = invalid_entity, items = function() return GetBuildingEntities(invalid_entity) end},
		--
		{ template = true, name = T(156, "Dome Comfort"),         id = "dome_comfort",      category = "General",  editor = "number",       default = 0 , scale = "Stat", modifiable = true },
		{ template = true, name = T(13586, "Dome Morale"),          id = "dome_morale",       category = "General",  editor = "number",       default = 0 , scale = "Stat", modifiable = true },

		{ template = true, name = T(10971, "Show Range for All"),   id = "show_range_all", 	 category = "General",  editor = "bool",         default = false, help = "Show range radii for all buildings of that class when selected" },
		{ template = true, name = T(158, "Show Range"),   		 id = "show_range", 	 	category = "General",  editor = "bool",         default = false, help = "Show range radius for this building" },
		{ template = true, name = T(7331, "Infopanel"),           id = "ip_template", 	    category = "General",  editor = "text",         default = "ipBuilding", help = "Template used for building infopanel" },
		{ template = true, name = T(8697, "Suspend on Dust Storm"),     id = "suspend_on_dust_storm", category = "General",  editor = "bool",         default = false },
		
		--
		{ template = true, name = T(4103, "Encyclopedia ID"),     id = "encyclopedia_id",      category = "Encyclopedia",  editor = "text", default = "" },
		{ template = true, name = T(160, "Encyclopedia Text"),    id = "encyclopedia_text",    category = "Encyclopedia",  editor = "multi_line_text",default = "", translate = true, },
		{ template = true, name = T(161, "Encyclopedia Image"),   id = "encyclopedia_image",   category = "Encyclopedia",  editor = "browse",       default = "", folder = "UI" },
		--
		{ template = true, name = T(11469, "Keybinding allowed"), id = "key_bindable", category = "Shortcuts", editor = "bool", default = true, },
		{ template = true, name = T(7615, "Build Shortcut"),    id = "build_shortcut1", category = "Shortcuts",  editor = "text",default = "", },
		{ template = true, name = T(7616, "Build Shortcut 2"),    id = "build_shortcut2", category = "Shortcuts",  editor = "text",default = "", },
		{ template = true, name = T(7617, "Gamepad Shortcut"),    id = "build_shortcut_gamepad", category = "Shortcuts",  editor = "text",default = "", },
		--
		{ template = true, name = T(167, "Label 1"),       id = "label1",    category = "Custom Labels",  editor = "text",         default = "" },
		{ template = true, name = T(168, "Label 2"),       id = "label2",    category = "Custom Labels",  editor = "text",         default = "" },
		{ template = true, name = T(169, "Label 3"),       id = "label3",    category = "Custom Labels",  editor = "text",         default = "" },
		--
		{ template = true, name = T(170, "Has On/Off button"),   id = "on_off_button",  category = "UI",  editor = "bool",         default = true },
		{ template = true, name = T(171, "Has Priority button"), id = "prio_button",    category = "UI",  editor = "bool",         default = true },		
		--
		{ name = T(172, "Priority"),            id = "priority",            category = "General", editor = "number", default = 2, ui = "scrollbar", min = 1, max = const.MaxBuildingPriority },
		{ name = T(173, "Salvage Modifier"),    id = "salvage_modifier",    category = "General", editor = "number", default = 100, ui = "number", min = 0, max = 100, modifiable = true, },
		--
		{ template = true, name = T(174, "Color Modifier"),       id = "color_modifier",    category = "General",  editor = "color",        default = const.clrNoModifier },
		
		{ template = true, name = T(11561, "Palette color 1"), id = "palette_color1", category = "General", editor = "combo", items = ColonyColorSchemeColorNames, default = "none" },
		{ template = true, name = T(11562, "Palette color 2"), id = "palette_color2", category = "General", editor = "combo", items = ColonyColorSchemeColorNames, default = "none" },
		{ template = true, name = T(11563, "Palette color 3"), id = "palette_color3", category = "General", editor = "combo", items = ColonyColorSchemeColorNames, default = "none" },
		{ template = true, name = T(11564, "Palette color 4"), id = "palette_color4", category = "General", editor = "combo", items = ColonyColorSchemeColorNames, default = "none" },
		
		{ template = true, category = "Demolish", name = T(157, "Indestructible"), 		        id = "indestructible", 	          editor = "bool",   default = false, help = "Specify if the building can be destroyed at all (by demolishing, by explosions, by meteors, etc)."},
		{ template = true, category = "Demolish", name = T(175, "Use demolished state?"),       id = "use_demolished_state",      editor = "bool",   default = true, help = "If true, the building will transofrm into ruins, instead of disappearing after destruction."},
		{ template = true, category = "Demolish", name = T(7332, "Demolish sinking (%)"),       id = "demolish_sinking",          editor = "range",  default = range(15, 30), min = 0, max = 50, help = "Building part sinking into the ground in demolished state. Valid only for buildings without terrain modification surfaces.", no_edit = function(obj) return not obj.use_demolished_state end, },
		{ template = true, category = "Demolish", name = T(7333, "Demolish tilt (deg)"),        id = "demolish_tilt_angle",       editor = "range",  default = range(5*60, 10*60), min = 0, max = 30*60, scale = 60, help = "Building tilt angle in demolished state", no_edit = function(obj) return not obj.use_demolished_state end, },
		{ template = true, category = "Demolish", name = T(7334, "Demolish color"),             id = "demolish_color",            editor = "color",  default = RGB(45, 50, 53), no_edit = function(obj) return not obj.use_demolished_state end, help = "Color modifier for the destroyed building." },
		{ template = true, category = "Demolish", name = T(7335, "Demolish place debris (%)"),  id = "demolish_debris",           editor = "number", default = 70, min = 0, max = 100, slider = true, no_edit = function(obj) return not obj.use_demolished_state end, help = "Percentage of debris left after destruction.",},
		{ template = true, category = "Demolish", name = T(8564, "Return resources"),           id = "demolish_return_resources", editor = "bool",   default = true, help = "If true, the building will return resources upon destruction.", },
		{ template = true, category = "Demolish", name = T(12558, "Auto clear"),                id = "auto_clear",                editor = "bool",   default = true, help = "If true, the building will be marked to be cleared after being demolished.", },
		
		{ template = true, category = "Construction", name = T(176, "Construction Mode"), id = "construction_mode", editor = "text", default = "construction", help = "The type of construction controller to launch", no_edit = true},
		{ template = true, category = "Construction", name = T(7891, --[[Post-Cert]] "Refund on Salvage"), id = "refund_on_salvage", editor = "bool", default = true},
		
		{ template = true, category = "General", name = T(9611, "Count as Building"), id = "count_as_building", editor = "bool", default = true, help = "Count as building for achievement / control center purposes"},
		{ template = true, category = "General", name = T(12466, "Clear Soil Underneath"),   id = "clear_soil_underneath", editor = "bool", default = false, help = "If the soil underneath the building should be set to 0.", no_edit = function() return not IsDlcAvailable("armstrong") end },
		
		{ template = true, category = "Construction", name = T(12705, "Disable in environment"),   id = "disabled_in_environment1", editor = "dropdownlist", default = "Underground", help = "Map type where building should be disabled", no_edit = function() return not IsDlcAvailable("picard") end, items = function (self) return table.union({""}, EnvironmentTypes) end },
		{ template = true, category = "Construction", name = T(12705, "Disable in environment"),   id = "disabled_in_environment2", editor = "dropdownlist", default = "Asteroid", help = "Map type where building should be disabled", no_edit = function() return not IsDlcAvailable("picard") end, items = function (self) return table.union({""}, EnvironmentTypes) end },
		{ template = true, category = "Construction", name = T(12705, "Disable in environment"),   id = "disabled_in_environment3", editor = "dropdownlist", default = "", help = "Map type where building should be disabled", no_edit = function() return not IsDlcAvailable("picard") end, items = function (self) return table.union({""}, EnvironmentTypes) end },
		{ template = true, category = "Construction", name = T(12705, "Disable in environment"),   id = "disabled_in_environment4", editor = "dropdownlist", default = "", help = "Map type where building should be disabled", no_edit = function() return not IsDlcAvailable("picard") end, items = function (self) return table.union({""}, EnvironmentTypes) end },	
		
		{ template = true, category = "Construction", name = T(13587, "Snap target"), id = "snap_target_type", editor = "combo", default = false, items = function(template) return ClassDescendantsList("Building") end, help = "Type to snap to when building" },	
		{ template = true, category = "Construction", name = T(13588, "Only build on snapped locations"), id = "only_build_on_snapped_locations", editor = "bool", default = false, help = "Only allow building on snap target" },
		{ template = true, category = "Construction", name = T(13589, "Snap error text"), id = "snap_error_text", editor = "text", default = "", translate = true, },
		{ template = true, category = "Construction", name = T(13590, "Snap error short"), id = "snap_error_short", editor = "text", default = "", translate = true, },
	},

	update_thread = false,
	building_update_time = const.HourDuration,
	
	gamepad_auto_deselect = true,
	
	creation_time = 0,
	configurable_attaches = {},
	is_tall = false, --diamond inherited.
	
	parent_dome = false,
	default_label = "Building",
	disable_selection = false,
	use_shape_selection = true,
	
	upgrade_modifiers = false,
	upgrade_id_to_modifiers = false, --this one can be safely iterated with pairs without going over the same mods twice.
	upgrades_built = false,
	
	upgrades_under_construction = false, --{ [id] = {id = id, tier = tier, construction_start_ts = , required_time = , reqs[] = } }
	upgrade_being_built = false,
	
	construction_cost_at_completion = false, --keeps the amount of resources spent to complete this bld, so we don't have to guess what they were.
	clear_work_request = false,
	
	upgrade_on_off_state = false,
	demolish_debris_objs = false,
		
	resource_spots = false,
	name = "",
	
	orig_terrain1 = false,
	orig_terrain2 = false,
	
	occupation_fx = false, --occupation FX prop
	occupation = 0, --occupation FX prop
	
	auto_attach_at_init = false,
	landscape_construction_visuals = false,
	ui_demolish = false,
}

function OnMsg.DataLoaded()
	DataInstances.BuildingTemplate = BuildingTemplates -- savegame compatibility
end

MaxAltEntityIdx = 7

do
	local status_items = {
		{value = false, text = ""},
		{value = "required", text = T(9828, "Required")},
		{value = "disabled", text = T(847439380056, "Disabled")},
	}
	local properties = Building.properties
	for i=1,3 do
		properties[#properties + 1] = { template = true, category = "Sponsor Condition", id = "sponsor_name" .. i,  name = T{9829, "Sponsor <number>", number = i}, editor = "combo",    default = "", items = SponsorCombo() }
		properties[#properties + 1] = { template = true, category = "Sponsor Condition", id = "sponsor_status" .. i, name = T{8692, "Status <number>", number = i}, editor = "dropdownlist", default = false, items = status_items}
	end
	for i=2,MaxAltEntityIdx do
		table.iappend(properties, {
			{ template = true, name = T{11217, "Alternative Entity <number>", number = i},          id = "entity" .. i,    category = "Alternative Entities", editor = "dropdownlist", default = "", items = function() return GetBuildingEntities("") end},
			{ template = true, name = T{11218, "Alternative Entity <number> DLC", number = i},      id = "entitydlc" .. i, category = "Alternative Entities", editor = "text", default = "", },
			{ template = true, name = T{11219, "Alternative Entity <number> Palette Color 1", number = i}, id = "palette" .. i .. "_color1", category = "Alternative Entities", editor = "combo", items = ColonyColorSchemeColorNames, default = "none" },
			{ template = true, name = T{11565, "Alternative Entity <number> Palette Color 2", number = i}, id = "palette" .. i .. "_color2", category = "Alternative Entities", editor = "combo", items = ColonyColorSchemeColorNames, default = "none" },
			{ template = true, name = T{11566, "Alternative Entity <number> Palette Color 3", number = i}, id = "palette" .. i .. "_color3", category = "Alternative Entities", editor = "combo", items = ColonyColorSchemeColorNames, default = "none" },
			{ template = true, name = T{11567, "Alternative Entity <number> Palette Color 4", number = i}, id = "palette" .. i .. "_color4", category = "Alternative Entities", editor = "combo", items = ColonyColorSchemeColorNames, default = "none" },
		
		})
	end
end

function Building:Random(...)
	return CityObject.Random(self, ...)
end

function Building:Init()
	local now = GameTime()
	self:StartUpdateThread(now == 0)
	
	self.creation_time = now
	
	self.upgrade_modifiers = {}
	self.upgrades_built = {}
	self.upgrade_id_to_modifiers = {}
	self.upgrade_on_off_state = {}
	
	self:InitResourceSpots()
end

function Building:InitResourceSpots()
	if self.resource_spots then
		return
	end
	self.resource_spots = {}
	for i=1, 10 do
		self.resource_spots[i] = {"Resourcepile" .. i, 90*60}
	end
	self.resource_spots[#self.resource_spots + 1] = {"Workdrone", 0}
	self.resource_spots[#self.resource_spots + 1] = {"Workrover", 0}	
end

function Building:ApplyToGrids()
	GridObject.ApplyToGrids(self)
	GetFlightSystem(self):Mark(self)
end

function Building:RemoveFromGrids()
	GridObject.RemoveFromGrids(self)
	GetFlightSystem(self):Unmark(self)
end

function Building:GetIPDescription()
	if self:IsKindOf("Building") and self.destroyed and not self.demolishing and not self.bulldozed then
		return T(597, "The <em>ruins</em> of an abandoned building. Can be <em>cleared</em> for resources, or <em>rebuilt</em>.")
	end
	return T{self.description,self}
end

function Building:GetBuildMenuCategory()
	if self.template_name ~= "" then
		return ClassTemplates.Building[self.template_name] and ClassTemplates.Building[self.template_name].build_category
	elseif self:HasMember("building_class_proto") and self.building_class_proto and self.building_class_proto:HasMember("build_category") then
		return self.building_class_proto.build_category
	end
end

function Building:SetCustomLabels(obj, add)
	local i = 1
	while true do
		if not self:HasMember("label"..i) then break end
		local label = self["label"..i]
		if label ~= "" then
			if add then
				obj:AddToLabel(label, self)
			else
				obj:RemoveFromLabel(label, self)
			end
		end
		i = i + 1
	end
end

function Building:AddToCityLabels()
	if self.default_label then
		self.city:AddToLabel(self.default_label, self)
		if self.default_label == "Building" and not IsKindOf(self, "Dome") and self.build_category ~= "Domes" then
			self.city:AddToLabel("BuildingNoDomes", self)
		end
	end
	self:SetCustomLabels(self.city, true)
	if self.template_name ~= "" then
		self.city:AddToLabel(self.template_name, self)
	end
	if self.class ~= self.template_name then
		self.city:AddToLabel(self.class, self)
	end
	local category = self:GetBuildMenuCategory()
	if category then
		self.city:AddToLabel(category, self)
	end

	Msg("AddToCityLabels", self)
end

function Building:RemoveFromCityLabels()
	if self.default_label then
		self.city:RemoveFromLabel(self.default_label, self)
		if self.default_label == "Building" and not IsKindOf(self, "Dome") then
			self.city:RemoveFromLabel("BuildingNoDomes", self)
		end
	end
	self:SetCustomLabels(self.city, false)
	if self.template_name ~= "" then
		self.city:RemoveFromLabel(self.template_name, self)
	end
	if self.class ~= self.template_name then
		self.city:RemoveFromLabel(self.class, self)
	end
	local category = self:GetBuildMenuCategory()
	if category then
		self.city:RemoveFromLabel(category, self)
	end
	if self.suspended then
		self.city:RemoveFromLabel("Suspended", self)
	end

	Msg("RemoveFromCityLabels", self)
end

function Building:DetachFromRealm(map_id)
	self:RemoveFromCityLabels()
end

function Building:AttachedToRealm(map_id)
	self:AddToCityLabels()
end

function Building:UpdateHexRanges(show)
	if not show then return end
	local controller = GetConstructionController()
	local template = (controller and controller.template) or (IsKindOf(SelectedObj, "Building") and SelectedObj.class)
	if GetBuildingObj(self).template_name ~= template then return end
	local cls = ClassTemplates.Building[template]
	if template and cls and cls.show_range_all then
		ShowHexRanges(self.city, nil, nil, nil, self)
	elseif Platform.developer and template and not cls then
		print("<color 255 216 0>Could not find template, ", template, "</color>")
	end	
end

function Building:GameInit()
	PlayFX("Spawn", "start", self, self:HasMember("building_class_proto") and self.building_class_proto or nil)
	
	local dome = GetDomeForBuilding(self)
	if dome and dome ~= self then
		self:InitInside(dome)
	else
		self:InitOutside()
	end

	if not self:IsKindOf("ConstructionSite") then
		self:SetIsNightLightPossible(false) --lights are turned off on init. needs 2 be after auto attaches, before nightlightenable
		self:NightLightDisable()	
		self:NightLightEnable()	
	end
	if not IsKindOfClasses(self, "ConstructionSite", "ConstructionSiteWithHeightSurfaces") then
		Msg("BuildingInit", self)
	end
	self:Notify("UpdateNoCCSign")
	self:Gossip("place", self:GetPos())
	if not dome and self.suspend_on_dust_storm then
		local dust_storm_start_time = HasDustStorm(self:GetMapID()) and g_DustStorm.start_time or GameTime()
		if GameTime() - dust_storm_start_time > const.HourDuration then
			self:SetSuspended(true, const.DustStormSuspendReason)
		end
	end
	self:UpdateHexRanges("show")
end

function Building:Done()
	self:Gossip("done")
	PlayFX("Spawn", "end", self, self:HasMember("building_class_proto") and self.building_class_proto or nil)
	self:KickUnitsFromHolder()
	self:RemoveFromCityLabels()
	self:StopUpgradeModifiers()
	if self.parent_dome and IsValid(self.parent_dome) then
		UpdateCoveredGrass(self, self.parent_dome, "clear")
	end
	self:SetDome(false)	
	local objs = self.demolish_debris_objs or ""
	for i=1,#objs do
		local debris = objs[i]
		if IsValid(debris) then
			DoneObject(debris)
		end
	end
	self.demolish_debris_objs = nil
	BumpDroneUnreachablesVersion()
	RefreshConstructionCursor()
	GetFlightSystem(self):Unmark(self)
end

function Building:InitInside(dome)
	self:SetDome(dome)
	UpdateCoveredGrass(self, dome, "build")
	self.show_dust_visuals = false --from maintenance, whether to show dust visuals.
	self.accumulate_dust = false
	self:SetDustVisualsPerc(0)
	self:ForEachAttach("ResourceStockpile", ResourceStockpileBase.InitInside, dome)
end

function Building:SetSuspended(suspended, reason, duration)
	BaseBuilding.SetSuspended(self, suspended, reason, duration)
	if self.suspended then
		self.city:AddToLabel("Suspended", self)
	else
		self.city:RemoveFromLabel("Suspended", self)
	end
end

function Building:InitOutside()
	self:SetDome(false)
	self.show_dust_visuals = nil
	self.accumulate_dust = nil
	self:ForEachAttach("ResourceStockpile", ResourceStockpileBase.InitOutside)
end

function Building:MoveInside(dome)
	self:InitInside(dome)
end

function Building:Gossip(gossip, ...)
	if not netAllowGossip then return end
	NetGossip("Building", self.template_name == "" and self.class or self.template_name, self.handle, gossip, GameTime(), ...)
end

function Building:GossipName()
	return (self.template_name == "" and self.class or self.template_name)
end

function Building:GetInfopanelTemplate()
	return not self:GetUIInteractionState() and "ipRogue" or self.ip_template
end

function Building:CanSnapTo()
	return true
end

function Building:GetSnapError()
	return {
		type = "error",
		priority = 90,
		text = self.snap_error_text,
		short = self.snap_error_short,
	}
end

function Building:CanWorkInTurnedOffDome()
end

function Building:GetWorkNotPermittedReason()
	if not self:CanWorkInTurnedOffDome() and self.parent_dome and not self.parent_dome.ui_working then
		return "DomeNotWorking"
	end	
	return BaseBuilding.GetWorkNotPermittedReason(self)
end

function Building:GetWorkNotPossibleReason()
	if self.destroyed then
		return "Destroyed"
	end
	if self:IsMalfunctioned() then
		return "Malfunction"
	end
	if not self:CanConsume() then
		return "Consumption"
	end
	if self:IsDemolishing() then
		return "Demolish"
	end	
	return BaseBuilding.GetWorkNotPossibleReason(self)
end

function Building:GetBuildShape()
	return self:GetShapePoints()
end
function Building:GetFlattenShape()
	return self:GetBuildShape()
end

function OnMsg.GatherLabels(labels)
	labels.Building = true
	labels.EntertainmentBuildings = true
	for id, template in pairs(BuildingTemplates) do
		labels[id] = true
		labels[id .. g_ConstructionSiteLabelSuffix] = true
		if template.build_category and not labels[template.build_category] then
			labels[template.build_category] = true
			labels[template.build_category .. g_ConstructionSiteLabelSuffix] = true
		end
		
		local j = 1
		while true do
			local label_id = "label"..j
			if not template:HasMember(label_id) then break end
			if template[label_id] ~= "" then
				labels[template[label_id]] = true
				labels[template[label_id] .. g_ConstructionSiteLabelSuffix] = true
			end
			j = j + 1
		end
	end
end

function Building:SetDome(dome)
	if self.parent_dome then
		self:StopUpgradeModifiers(self.parent_dome)
		self.parent_dome:RemoveFromLabel("Buildings", self)
		if self.template_name ~= "" then
			self.parent_dome:RemoveFromLabel(self.template_name, self)
		end	
		if self.dome_spot == "Spire" then
			self.parent_dome:RemoveFromLabel("Spire", self)
			self.parent_dome:UpdateSignOffset()
		end
		self:SetCustomLabels(self.parent_dome, false)
		self.parent_dome:UpdateColonists()
	end
	assert(not IsKindOf(self, "Dome") or not dome)
	assert(IsKindOf(dome, "Dome") or not dome)
	self.parent_dome = dome or nil
	if dome then
		self:ApplyUpgradeModifiers(dome) --TODO: does this work if modifiers' containers are set @ mod creation?
		self.parent_dome:AddToLabel("Buildings", self)
		if self.template_name ~= "" then
			self.parent_dome:AddToLabel(self.template_name, self)
		end
		if self.dome_spot == "Spire" then
			self.parent_dome:AddToLabel("Spire", self)
			self.parent_dome:UpdateSignOffset()
		end
		self:SetCustomLabels(self.parent_dome, true)
		
		if self.parent_dome.demolishing then
			self.parent_dome:ToggleDemolish()
		end
		self.parent_dome:UpdateColonists()
	end
end

function Building:ToggleDemolish(from_ui)
	Demolishable.ToggleDemolish(self)
	self.ui_demolish = from_ui and self.demolishing
end

function Building:SetPalette(cm1, cm2, cm3, cm4)
	if not IsValid(self) then return end
	SetObjectPaletteRecursive(self, cm1, cm2, cm3, cm4)
	if IsKindOf(self, "LifeSupportGridObject") then
		local pipes = self:GetPipeConnLookup()
		cm1, cm2, cm3, cm4 = GetPipesPalette()
		for p, _ in pairs(pipes) do
			p:SetColorizationMaterial4(cm1, cm2, cm3, cm4)
		end
	end
end

function Building:Settemplate_name(template_name, params)
	ClassTemplateObject.Settemplate_name(self, template_name)
	local entity = params and params.alternative_entity_t and params.alternative_entity_t.entity or self.entity
	self:ChangeEntity(entity)
	AutoAttachObjectsToShapeshifter(self)
	local cm1, cm2, cm3, cm4
	if params and params.alternative_entity_t and params.alternative_entity_t.palette then
		cm1, cm2, cm3, cm4 = DecodePalette(params.alternative_entity_t.palette)
	else
		cm1, cm2, cm3, cm4 = GetBuildingColors(GetCurrentColonyColorScheme(), self)
	end
	self:SetPalette(cm1, cm2, cm3, cm4)
	
	self:AttachConfigurableAttaches()
	self:InitMaintenanceRequests()
	self:InitConsumptionRequest()
end

function Building:GetSkins(ignore_destroyed_state)
	if ignore_destroyed_state or not self.destroyed then
		local skins, palettes = GetBuildingSkins(self.template_name)
		if next(skins) then
			return skins, palettes
		end
	end
	return false
end

function Building:GetCurrentSkin()
	local skins, palettes = self:GetSkins()
	if skins and next(skins) then
		local skin_idx = table.find(skins, self:GetEntity()) or 1
		return skins[skin_idx], palettes[skin_idx]
	else
		return self:GetEntity(), { self.palette_color1, self.palette_color2, self.palette_color3, self.palette_color4 }
	end
end

function AttachAttaches(obj, attaches)
	local map_id = obj:GetMapID()
	for _, entry in ipairs(attaches or empty_table) do
		local spot, class = entry[2], entry[1]
		local first, last = obj:GetSpotRange(spot)
		for i = first, last do
			local attach = PlaceObjectIn(class, map_id)
			obj:Attach(attach, i)
		end
	end
end

function Building:AttachConfigurableAttaches(attaches) --use for override
	AttachAttaches(self, attaches or self.configurable_attaches)
end

function Building:StartUpdateThread(randomize_tick)
	if not self.building_update_time then return end
	self.update_thread = CreateGameTimeThread(function(self, randomize_tick)
		if randomize_tick then
			Sleep( InteractionRand(max_int, "randomize_tick") % self.building_update_time + 1)
		end
		local last_day
		local city = self.city
		local delta = 0
		while IsValid(self) and city do
			local day = UIColony.day
			self:RecursiveCall(true, "BuildingUpdate", delta, day, UIColony.hour) --parents first
			if IsValid(self) and last_day ~= day then
				last_day = day
				self:RecursiveCall(true, "BuildingDailyUpdate", day)
			end
			delta = self.building_update_time
			Sleep(delta)
		end
	end, self, randomize_tick)
end

function Building:ThrowDust()
end

function Building:BuildingUpdate(delta, day, hour)
	self:ThrowDust()
	
	if self.upgrades_under_construction and self.working then
		self:UpdateUpgradeConstruction()
	end
end

function Building:IsOutsideCommandRange(ignore_cg)
	for _, cc in ipairs(self.command_centers or empty_table) do
		if cc.working then return false end
	end
	return true
end

function Building:ShouldShowNoCCSign()
	if not self:DoesHaveConsumption() and not self:DoesRequireMaintenance() and not self.exceptional_circumstances
		and (not IsKindOfClasses(self, "StorageDepot", "ConstructionSite") or IsKindOfClasses(self, "RocketBase")) then
		return false
	end
	
	return self:IsOutsideCommandRange()
end

function Building:UpdateNoCCSign()
	self:AttachSign(self:ShouldShowNoCCSign(), "SignNoCommandCenter")
end

function Building:OnAddedByControl(...)
	Building.UpdateNoCCSign(self, ...)
end

function Building:OnRemovedByControl(...)
	Building.UpdateNoCCSign(self, ...)
end

function Building:OnCommandCenterWorkingChanged(...)
	Building.UpdateNoCCSign(self, ...)
end

function Building:BuildingDailyUpdate(day)	
end

function Building:OnSetDemolishing(is_demolishing)
	self:UpdateWorking()
	self:AttachSign(is_demolishing, "SignSalvaged")
	if is_demolishing then
		self:StopAllUpgradeConstruction()
		self:InterruptUnitsInHolder()
	end
	self:UpdateConsumption()
end

function Building:InterruptUnitsInHolder()
	for _, unit in ipairs(self.units or empty_table) do
		unit:InterruptVisit()
	end
end

function Building:OnDemolish()
	self:RestoreTerrain()
	self:Destroy()
	if self.demolish_return_resources then
		self:ReturnResources()	
	end
	if self.ui_demolish and self.city.colony:IsTechResearched("DecommissionProtocol") and self.auto_clear then
		CreateGameTimeThread(self.DestroyedClear, self)
	end
end

function Building:CanDemolish()
	return self.can_demolish and not self.destroyed and not self.indestructible and not self.refab_work_request and self.ui_interaction_state
end

function Building:AddRefundResource(tbl, res, amnt)
	if amnt <= 0 then
		return
	end
	local idx = table.find(tbl, "resource", res)
	if not idx then
		tbl[#tbl + 1] = { resource = res, amount = amnt }
	else
		tbl[idx].amount = tbl[idx].amount + amnt
	end
end

function Building:GetRefundResources()
	local refund = {}
	
	if not self.refund_on_salvage then return refund end
	
	if self.construction_cost_at_completion then
		for r_n, amount in pairs(self.construction_cost_at_completion) do
			local refund_amount = self:CalcRefundAmount(amount)
			self:AddRefundResource(refund, r_n, refund_amount)
		end
	else
		for _, resource in ipairs(ConstructionResourceList) do
			local amount = UIColony.construction_cost:GetConstructionCost(self, resource)
			if amount > 0 then
				local refund_amount = self:CalcRefundAmount(amount)
				self:AddRefundResource(refund, resource, refund_amount)
			end
		end		
	end
		
	local upgrade_resources = self:GatherUpgradeSpentResources()
	for r_n, amount in pairs(upgrade_resources) do
		local refund_amount = self:CalcRefundAmount(amount)
		self:AddRefundResource(refund, r_n, refund_amount)
	end
		
	if self.consumption_stored_resources then
		local refund_amount = self.consumption_stored_resources
		self:AddRefundResource(refund, self.consumption_resource_type, refund_amount)
	end

	return refund
end

function Building:CalcRefundAmount(total_amount)
	local scale = const.ResourceScale
	return MulDivRound(total_amount / 2, self.salvage_modifier, 100)
end

function Building:GatherUpgradeSpentResources()
	--as long as upgrade costs cannot be modified this is accurate,
	local t = {}
	--built upgrades
	for i = 1, 3 do --for each tier, because self.upgrades_built has both [id]=true and [tier]=true
		if self.upgrades_built[i] then
			for j = 1, #AllResourcesList do
				local r_n = AllResourcesList[j]
				local c = self:GetUpgradeCost(i, r_n)
				if c and c > 0 then
					t[r_n] = (t[r_n] or 0) + c
				end
			end
		end
	end
	--upgrades under construction
	for id, data in pairs(self.upgrades_under_construction or empty_table) do
		local reqs = data.reqs
		for i = 1, #(reqs or empty_table) do
			local req = reqs[i]
			local r_n = req:GetResource()
			local amount_remaining = req:GetActualAmount()
			local total_cost = self:GetUpgradeCost(data.tier, r_n)
			local amount_spent = total_cost - amount_remaining
			if amount_spent > 0 then
				t[r_n] = (t[r_n] or 0) + amount_spent
			end
		end
	end
	
	return t
end

function Building:ReturnResources()
	local refund = self:GetRefundResources() or empty_table
	for i = 1, #refund do
		self:PlaceReturnStockpile(refund[i].resource, refund[i].amount)
	end
end

function Building:PlaceReturnStockpile(resource, amount)
	if amount <= 0 then
		return
	end
	
	local pos, angle
	local terrain = GetTerrain(self)
	for k = 1, #self.resource_spots do
		local spot_name = self.resource_spots[k][1]
		if self:HasSpot(spot_name) then
			local i1, i2 = self:GetSpotRange(spot_name)
			for i=i1, i2 do
				local pos_i = self:GetSpotPos(i)
				if terrain:IsPassable(pos_i) then
					pos = pos_i
					angle = self:GetSpotRotation(i) + self.resource_spots[k][2]
					break
				end
			end
			if pos then
				break
			end
		end
	end
	if not pos then
		pos = self:GetRandomSpotPosAsync("Workrover") or self:GetRandomSpotPosAsync("Workdrone") or self:GetVisualPos()
		angle = self:GetAngle()
	end
	PlaceResourceStockpile_Delayed(pos, self:GetMapID(), resource, amount, angle, true)
end

function Building:GetDisplayName()
	return not IsKindOf(self, "BuildingTemplate") and self.name and self.name~="" and Untranslated(self.name) or self.display_name 
end

function Building:View()  -- for hyperlinks
	ViewObjectMars(self:GetLogicalPos())
end

function Building:Select()  -- for hyperlinks
	SelectObj(self)
	ViewObjectMars(self:GetVisualPos())
end

function Building:GatherConstructionStatuses(statuses)
end

function Building:RepairNeeded()
	return self:IsMalfunctioned()
end

--Drones/rover do not clean dusty buildings before they malfunction, or do they
function Building:CleanNeeded()
	return self:RepairNeeded()
end

function Building:OnGameExitEditor()
	self:DisconnectFromCommandCenters()
	self:ConnectToCommandCenters()
end

function Building:IsLarge()
	return #self:GetShapePoints() >= g_Consts.LargeBuildingHexes
end

GlobalVar("UpgradeModifierModifiers", {}) --[UpgradeId] = { [prop] = {amount = , percent = }}, where mod_id is 1-3, both vals are accumulated on top of existing vals
function RegisterUpgradeModifierModifier(upgrade_id, prop, amount, percent)
	local bld_lbl_name
	local prop_names = { "upgrade1_id", "upgrade2_id", "upgrade3_id" }
	--figure out which bld this is for so we can apply the mod for blds that are already constructed
	for id, template in pairs(BuildingTemplates) do
		for i, u_prop_name in ipairs(prop_names) do
			if upgrade_id == template[u_prop_name] then
				bld_lbl_name = id
				break
			end
		end
		if bld_lbl_name then break end
	end
	
	if not bld_lbl_name then
		if Platform.developer and not DbgAreDlcsMissing() then
			print("RegisterUpgradeModifierModifier, did not find building with upgrade -> " .. upgrade_id)
		end
		return
	end
	
	--apply for future upgrades
	local t1 = UpgradeModifierModifiers[upgrade_id] or {}
	UpgradeModifierModifiers[upgrade_id] = t1
	local mod = t1[prop] or {amount = 0, percent = 0}
	t1[prop] = mod
	mod.amount = mod.amount + (amount or 0)
	mod.percent = mod.percent + (percent or 0)
	--apply to existing blds
	local lbl = UICity.labels[bld_lbl_name]
	
	for _, bld in ipairs(lbl or empty_table) do
		local mod_t = bld.upgrade_id_to_modifiers[upgrade_id]
		if mod_t then
			local is_applied = mod_t[1] and mod_t[1]:IsApplied() or false
			if is_applied then
				bld:StopUpgradeModifiersForUpgrade(upgrade_id)
			end
			
			for _, umod in ipairs(mod_t) do
				if umod.prop == prop then
					umod.amount = (umod.amount or 0) + mod.amount
					umod.percent = (umod.percent or 0) + mod.percent
				end
			end
			
			if is_applied then
				bld:ApplyUpgradeModifiersForUpgrade(upgrade_id)
			end
		end
	end
end

function Building:ApplyUpgrade(tier, force)
	local id = self:GetUpgradeID(tier)
	
	if not UIColony:IsUpgradeUnlocked(id) then
		print(id, " - Upgrade not researched!")
		if not force then return end
		
		UIColony:UnlockUpgrade(id)
	end
	
	if self:HasUpgrade(id) then 
		return 
	end
	
	local all_modifier_modifiers = UpgradeModifierModifiers[id] or empty_table
	
	for i = 1, 3 do
		local targetname = self[string.format("upgrade%d_mod_target_%d",  tier, i)]
		local label      = self[string.format("upgrade%d_mod_label_%d",   tier, i)]
		local propid     = string.format("upgrade%d_mod_prop_id_%d", tier, i)
		local prop       = self[propid]
		local percent    = self[string.format("upgrade%d_mul_value_%d",   tier, i)]
		local amount     = self[string.format("upgrade%d_add_value_%d",   tier, i)]
		local m_mods 	 = all_modifier_modifiers[prop] or empty_table
				
		if prop ~= "" then
			local modifier = nil
			local meta
			if targetname == "self" then
				meta = self:GetPropertyMetadata(prop)
			elseif targetname == "colony" then
				meta = g_Consts:GetPropertyMetadata(prop)
			elseif g_Classes[label] then
				meta = g_Classes[label]:GetPropertyMetadata(prop)
			elseif ClassTemplates[label] and g_Classes[ClassTemplates[label]] then
				meta = g_Classes[ClassTemplates[label]]:GetPropertyMetadata(prop)
			end
			
			local scale = meta and GetPropScale(meta.scale) or 1
			
			if targetname == "self" then
				-- make sure we're modifying an existing property
				assert(self:GetProperty(propid) ~= nil, string.format("Upgrade %s trying to modify nonexisting proprety %s for %s", id, propid, self.template_name))
				modifier = ObjectModifier:new{
					target = self, 
					prop = prop, 
					amount = (amount + (m_mods.amount or 0)) * scale, 
					percent = percent + (m_mods.percent or 0),
				}
			else
				local target = targetname == "colony" and UIColony.city_labels or self[targetname]
				if target then
					local mod_id = string.format("%s_upgrade%d_mod_%d", self.handle, tier, i)
					modifier = LabelModifier:new{
						container = target,
						label = label,
						id = mod_id,
						prop = prop,
						amount = (amount + (m_mods.amount or 0)) * scale,
						percent = percent + (m_mods.percent or 0),
					}
					target:SetLabelModifier(label, mod_id, modifier)		
				end
			end
			
			if modifier then
				self.upgrade_modifiers[id] = self.upgrade_modifiers[id] or {}
				self.upgrade_id_to_modifiers[id] = self.upgrade_id_to_modifiers[id] or {}
				table.insert(self.upgrade_modifiers[id], modifier)
				table.insert(self.upgrade_id_to_modifiers[id], modifier)
				rawset(modifier, "upgrade_id", id)
			end
		end
	end
	
	self:CreateUpgradeUpkeepObject(tier)
	
	self.upgrades_built[tier] = true
	self.upgrades_built[id] = true
	self.upgrade_on_off_state[id] = true --starts turned on
	if self.upgrades_under_construction then --not gona exist if from cheat
		self.upgrades_under_construction[id] = nil
		if not next(self.upgrades_under_construction) then
			self.upgrades_under_construction = nil --cleanup
		end
	end
	
	-- update/refresh working state
	if self.working and self:CanWork() then -- restart in case the upgrade alters production/consumption
		self.refreshing_working_state = true
		self:SetWorking(false)
		self:SetWorking(true)
		self.refreshing_working_state = false
	else
		self:UpdateWorking()
	end
	
	Msg("BuildingUpgraded", self, id)
end

for i = 1, 3 do
	Building["ToggleUpgradeTier" .. i] = function(self) self:ToggleUpgradeOnOff(self:GetUpgradeID(i)) end
end

function Building:ToggleUpgradeOnOff(upgrade_id)
	if not self:HasUpgrade(upgrade_id) or not self:CanDisableUpgrade(upgrade_id) then 
		return 
	end
	
	local new_state = not self.upgrade_on_off_state[upgrade_id]
	self.upgrade_on_off_state[upgrade_id] = new_state
	
	local c_obj = self.upgrade_consumption_objects and self.upgrade_consumption_objects[upgrade_id]
	if c_obj then
		c_obj:UpdateRequestConnectivity()
		new_state = new_state and c_obj:CanWork() --if upgrade cant work due to consumption don't turn it on
	end
		
	if new_state then
		self:ApplyUpgradeModifiersForUpgrade(upgrade_id)
	else
		self:StopUpgradeModifiersForUpgrade(upgrade_id)
	end
	
	self:OnUpgradeToggled(upgrade_id, new_state)
	CreateGameTimeThread(RebuildInfopanel, self) --so that supply grid updates have passed when we call this
end

function Building:OnUpgradeToggled(upgrade_id, new_state)
	--cb
end

function Building:ApplyUpgradeModifiersForUpgrade(upgrade_id)
	if not self:HasUpgrade(upgrade_id) then 
		return 
	end
	
	for _,  mod in ipairs(self.upgrade_modifiers[upgrade_id] or empty_table)do
		mod:TurnOn()
	end
end

function Building:StopUpgradeModifiersForUpgrade(upgrade_id)
	if not self:HasUpgrade(upgrade_id) then 
		return 
	end
	
	for _,  mod in ipairs(self.upgrade_modifiers[upgrade_id] or empty_table)do
		mod:TurnOff()
	end
end

function Building:ApplyUpgradeModifiers(only_for_object)
	for upgrade_id, modifiers in pairs(self.upgrade_id_to_modifiers) do
		if not self.upgrade_consumption_objects or not self.upgrade_consumption_objects[upgrade_id] or
			self.upgrade_consumption_objects[upgrade_id]:CanWork() then
			for i=1, #modifiers do
				local modifier = modifiers[i]
				if not only_for_object or (IsKindOf(modifier, "LabelModifier") and only_for_object == modifier.container) then
					modifier:TurnOn()
				end
			end
		end
	end
end

function Building:StopUpgradeModifiers(only_for_object)
	for _, modifier in ipairs(self.upgrade_modifiers) do
		if not only_for_object or (IsKindOf(modifier, "LabelModifier") and only_for_object == modifier.container) then
			modifier:TurnOff()
		end
	end
end

function Building:HasUpgrade(upgrade)
	return self.upgrades_built[upgrade]
end

function Building:GetUpgradeValue(upgrade_id, field)
	for i = 1, 3 do
		local id = self[string.format("upgrade%d_id", i)]
		if id == upgrade_id then
			return self[string.format("upgrade%d_%s", i, field)]
		end
	end
	assert(not "Trying to retrieve field from invalid upgrade: " .. upgrade_id)
end

function Building:CanDisableUpgrade(upgrade_id)
	return self:GetUpgradeValue(upgrade_id, "can_disable") or false
end

function Building:IsUpgradeOn(upgrade)
	return self.upgrade_on_off_state[upgrade]
end

function Building:AreNightLightsAllowed()
	local b = true
	if self.build_category == "Decorations" then
		local dome = self.parent_dome
		if dome then
			b = dome:AreNightLightsAllowed()
		end
	end
	return b and self.working and not self:IsSupplyGridDemandStoppedByGame()
end

local gofNightLightsEnabled = const.gofNightLightsEnabled
function Building:RefreshNightLightsState()
	if self:GetGameFlags(gofNightLightsEnabled) == 0 then
		if self:AreNightLightsAllowed() then
			self:SetIsNightLightPossible(true, true)
		end
	else
		if not self:AreNightLightsAllowed() then
			self:SetIsNightLightPossible(false, true)
		end
	end
end

function Building:OnSetWorking(working)
	BaseBuilding.OnSetWorking(self, working)
	self:RefreshNightLightsState()
	
	--Handle working/not-working emissive lights
	--Currently all entities that do not emit light during the night
	--  are turned on/off depending on the working state
	if not NightLightEmissiveEntites[self:GetEntity()] then
		if working then
			self:WorkLightsOn()
		else
			self:WorkLightsOff()
		end
	end
	
	--@@@msg OnSetWorking,building, working- fired when a buildings working state has been changed.
	Msg("OnSetWorking", self, working) --hook for modding
end

function Building:WorkLightsOn()
	self:SetSIModulation(200)
end

function Building:WorkLightsOff()
	self:SetSIModulation(0)
end

local DecDebrisClasses = empty_table
function OnMsg.ClassesBuilt()
	DecDebrisClasses = ClassDescendantsList("DecDebris")
end

function Building:GetDemolishObjs(list)
	ApplyToObjAndAttaches(self, function(obj)
		if IsKindOfClasses(obj, "Bush", "CropEntityClass") then
			DoneObject(obj)
		elseif IsKindOf(obj, "AnimatedTextureObject") then
			obj:SetFrameAnimationSpeed(0)
		elseif obj:GetClassFlags(const.cfConstructible + const.cfDecal) ~= 0 then
			list[#list + 1] = obj
		end
	end)
end

function Building:OnDestroyed()
end

GlobalVar("g_DestroyedBuildings", {})
GlobalGameTimeThread("DestroyedBuildingsNotif", function()
	HandleNewObjsNotif(g_DestroyedBuildings, "DestoyedBuildings", nil, nil, nil, "keep destroyed")
end)

function DestroyBuildingImmediate(bld, return_resources, dont_notify)
	if not IsValid(bld) or bld.destroyed or bld.indestructible then
		return
	end
	if not dont_notify then
		RequestNewObjsNotif(g_DestroyedBuildings, bld, bld:GetMapID())
	end
	bld.demolishing = true
	bld.demolishing_countdown = 0
	if return_resources ~= nil then
		bld.demolish_return_resources = return_resources
	end
	bld:DoDemolish()
	return true
end

local function IsSandTerrain(idx)
	local info = idx and TerrainTextures[idx]
	return info and info.type == "Sand"
end

function Building:RestoreTerrain(shape_obj, force_restore_type, force_restore_height)
	if self:GetEnumFlags(const.efApplyToGrids) == 0 and not (force_restore_height or force_restore_type) then
		return
	end
	shape_obj = shape_obj or self
	local terrain = GetTerrain(self)
	if (force_restore_type or HasAnySurfaces(self, EntitySurfaces.Terrain, true)) and not terrain:HasRestoreType() then
		local type_noise, type_thres
		local type_idx1, type_idx2 = self.orig_terrain1, self.orig_terrain2
		if not IsSandTerrain(type_idx1) or not IsSandTerrain(type_idx2) then
			local default_idx = GetTerrainTextureIndex("DomeDemolish")
			local peripheral_shape = GetEntityPeripheralHexShape(self:GetEntity())
			local all_tiles, terrain1, tiles1, terrain2, tiles2 = TerrainDeposit_CountTiles(peripheral_shape, self)
			type_idx1 = IsSandTerrain(type_idx1) and type_idx1 or IsSandTerrain(terrain1) and terrain1 or default_idx
			type_idx2 = IsSandTerrain(type_idx2) and type_idx2 or IsSandTerrain(terrain2) and terrain2 or default_idx
		end
		if type_idx1 and type_idx2 and type_idx1 ~= type_idx2 then
			local form_obj = DataInstances.NoisePreset.Terrain
			if form_obj then
				local map = g_CurrentMapParams or empty_table
				local seed = xxhash64(map.latitude, map.longitude, self:GetVisualPosXYZ())
				type_noise = form_obj:GetNoise(256, seed)
				type_thres = 512
			end
		end
		if type_idx1 then
			SetTerrainInShape(shape_obj:GetBuildShape(), self, type_idx1, type_idx2, type_thres, type_noise)
			GridOpFree(type_noise)
		end
	end
	if (force_restore_height or HasAnySurfaces(self, EntitySurfaces.Height, true)) and not terrain:HasRestoreHeight() then
		FlattenTerrainInBuildShape(shape_obj:GetFlattenShape(), self)
	end
end

function Building:Destroy()
	if self.destroyed or self.indestructible or not self:UseDemolishedState() then
		return
	end
	
	local realm = GetRealm(self)
	realm:SuspendPassEdits("Building.Destroy")
	local flags = self:GetEnumFlags(const.efCollision + const.efApplyToGrids)
	self:ClearEnumFlags(const.efWalkable + const.efCollision + const.efApplyToGrids)
	
	if self.parent_dome then
		self.parent_dome:UpdateColonists()
	end
	self.show_dust_visuals = true
	self.destroyed = true
	self:SetIsNightLightPossible(false) -- avoid night lights switching on
	self:DisableMaintenance() -- avoid drones to clear the dust
	self:DisconnectFromCommandCenters()
	self:UpdateWorking(false)
	self:DetachAllSigns() --attach destroyed sign @ sum point
	self:UpdateConsumption()
	self:ConsumptionOnDestroyed()
	self:UpdateNotWorkingBuildingsNotification() --rem from not working notif
	self:KickUnitsFromHolder()
	self:OnDestroyed()
	self:SetDustVisualsPerc(100)

	-- save current visual state in order to set it on rebuild
	local pos = self:GetVisualPos()
	local angle = self:GetVisualAngle()
	self.orig_state = {pos, angle}
	
	-- change color & anim
	local effects_time = 1000
	local demolish_color = self.demolish_color
	local demolish_objs = {}
	self:GetDemolishObjs(demolish_objs)
	for i=1,#demolish_objs do
		local obj = demolish_objs[i]
		if IsValid(obj) then
			obj:SetColorModifier(demolish_color, obj:GetClassFlags(const.cfDecal) and 0 or effects_time)
		end
	end
	
	-- sink & tilt into the ground
	local tilt, sink = 0, 0
	if not HasAnySurfaces(self, EntitySurfaces.TerrainHole + EntitySurfaces.Height, true) then
		local bbox = ObjectHierarchyBBox(self, const.efVisible, const.cfConstructible)
		--terrain:InvalidateType(bbox)
		local sx, sy, sz = 0, 0, 0
		if bbox then
			sx, sy, sz = bbox:sizexyz()
		end
		if sz and sz > 0 then
			local radius = Max(sx, sy) / 2
			local smin = MulDivRound(self.demolish_sinking.from, sz, 100)
			local smax = MulDivRound(self.demolish_sinking.to, sz, 100)
			sink = self:Random(smin, smax)
			
			local tmin = self.demolish_tilt_angle.from
			local tmax = self.demolish_tilt_angle.to
			tilt = self:Random(tmin, tmax)
			
			-- ensure the building is sinked after the tilt
			tilt = radius ~= 0 and Min(tilt, asin(MulDivRound(4096, smax, radius))) or radius
			sink = Max(sink, MulDivRound(radius, tilt, 4096))
		end
	end
	
	if sink > 0 or tilt > 0 then
		local spots = {Drone.work_spot_task, BaseRover.work_spot_task}
		for _, spot in pairs(spots) do
			if self:HasSpot(spot) then
				local arr = {}
				local b, e = self:GetSpotRange(spot)
				for j = b, e do
					table.insert(arr, self:GetSpotPos(j))
				end
				self.orig_state[spot] = #arr > 0 and arr or nil
			end
		end
		-- attach demolish objects
		for i=1,#demolish_objs do
			local obj = demolish_objs[i]
			if obj ~= self and IsValid(obj) and not obj:GetParent() then
				local pos_i = obj:GetVisualPos()
				local angle_i = obj:GetVisualAngle()
				obj:SetAttachOffset(pos_i - pos)
				obj:SetAttachAngle(angle_i - angle)
				self:Attach(obj, self:GetSpotBeginIndex("Origin"))
				obj:SetAnimSpeed(1, 0, effects_time)
			end
		end
	end
	if sink > 0 then
		local x, y, z = pos:xyz()
		self:SetPos(x, y, z - sink, effects_time)
		if tilt > 0 then
			SetRollPitchYaw(self, self:Random(-tilt, tilt), self:Random(-tilt, tilt), angle, effects_time)
		end
	end
		
	-- place debris decals
	local debris = self.demolish_debris or 0
	if debris > 0 then
		local objs = {}
		local shape_data = self:GetBuildShape()
		local dir = HexAngleToDirection(angle)
		local cq, cr = WorldToHex(pos)
		for _, shape_pt in ipairs(shape_data) do
			if self.city:Random(100) < debris then
				local sx, sy = shape_pt:xy()
				local q, r = HexRotate(sx, sy, dir)
				local hx, hy = HexToWorld(cq + q, cr + r)
				local debris_class = self.city:TableRand(DecDebrisClasses)
				if debris_class ~= "" then
					local debris = PlaceObjectIn(debris_class, self:GetMapID())
					debris:SetAngle(self:Random(360*60))
					debris:SetPos(hx, hy, const.InvalidZ)
					objs[#objs + 1] = debris
				end
			end
		end
		self.demolish_debris_objs = objs
	end
	
	PlayFX("Destroyed", "start", self)
	self:SetEnumFlags(flags)
	realm:ResumePassEdits("Building.Destroy")
	
	self:Notify("DisableCustomFX")
end

function Building:DisableCustomFX()
	local prev_sel = SelectedObj
	if SelectedObj == self then
		SelectObj(false)
	end
	self.fx_actor_class = "Building" -- disable FX linked to this specific building (e.g. hex radius)
	if prev_sel == self then
		SelectObj(self)
	end
end

function ApplyToObjAndAttaches(obj, func, ...)
	func(obj, ...)
	if IsValid(obj) then
		obj:ForEachAttach(ApplyToObjAndAttaches, func, ...)
	end
end

function Building:RebuildStart()
	self:ClearEnumFlags(const.efVisible)
end

function Building:RebuildCancel()
	self:SetEnumFlags(const.efVisible)
end

function Building:IsSuitable(colonist)
end

function Building:ColonistInteract(colonist)
end

function Building:ColonistCanInteract(colonist)
	return nil, nil, true
end

function Building:GetSelectionAngle()
	if self.destroyed and self.orig_state then
		return self.orig_state[2]
	end
	return self:GetAngle()
end

local unpack = table.unpack

function Building:Rebuild(params)
	params = params or {}
	assert(self.destroyed)
	local pos, angle
	if self.orig_state then
		pos, angle = unpack(self.orig_state)
	else
		local roll, pitch, yaw = GetRollPitchYaw(self)
		pos = self:GetPos():SetInvalidZ()
		angle = yaw
	end
	self:RebuildStart()
	if self:IsPinned() then
		self:TogglePin()
	end
	params.rebuild = self
	params.alternative_entity_t = {entity = self:GetEntity(), palette = {self:GetColorizationMaterial4()}}
	params.name = self.name
	return PlaceConstructionSite(self.city, self.template_name, pos, angle, params)
end

function Building:DestroyedRebuild(broadcast)
	if broadcast then
		BroadcastAction(self, "DestroyedRebuild")
		return
	end
	
	if not self.destroyed or self.bulldozed 
		or self:GetEnumFlags(const.efVisible) == 0 then --already rebuilding...
		return
	end
		
	local site = self:Rebuild()
	if SelectedObj == self then
		CreateGameTimeThread(SelectObj, site)
	end
end

function Building:DestroyedClear(broadcast)
	if broadcast then
		BroadcastAction(self, "DestroyedClear")
		return
	end

	if not self.destroyed or self.bulldozed or 
	not self.city.colony:IsTechResearched("DecommissionProtocol")
	or self.clear_work_request or not IsValid(self) then
		return
	end
	
	local template = BuildingTemplates[self.template_name]
	local pts = template and template.build_points or 1000
	self:DisconnectFromCommandCenters()
	self.bulldozed = true
	if self:HasSpot("Top") then
		self:Attach(PlaceObjectIn("RotatyThing", self:GetMapID()), self:GetSpotBeginIndex("Top"))
	end
	if self.parent_dome then
		self.parent_dome:UpdateColonists()
	end
	self.clear_work_request = self:AddWorkRequest("repair", 0, 0, Max(1, pts / 1000))
	self.clear_work_request:AddAmount(pts)	
	self:ConnectToCommandCenters()
	
	RebuildInfopanel(self)
end

function Building:CancelDestroyedClear(broadcast)
	if broadcast then
		BroadcastAction(self, "CancelDestroyedClear")
		return
	end
	
	if not self.bulldozed then return end
	local req = self.clear_work_request
	self:InterruptDrones(nil,function(drone) return drone.w_request==req and drone end)
	self:DisconnectFromCommandCenters()
	table.remove_entry(self.task_requests, req)
	self.clear_work_request = false
	self.bulldozed = false
	self:DestroyAttaches("RotatyThing")
	if self.parent_dome then
		self.parent_dome:UpdateColonists()
	end
	self:ConnectToCommandCenters()
	
	RebuildInfopanel(self)
end

function Building:ClearDone()
	PlayFXAroundBuilding(self, "Remove")
	self:RestoreTerrain()
	DoneObject(self)
end

function Building:OnRefabricate()
	Msg("Refabricated", self)
	self:OnDestroyed()
end

function Building:Refabricate()
	self:OnRefabricate()
	
	PlayFX("Refabbing", "end", self, nil, self:GetPos())
	self.city:AddPrefabs(self.template_name, 1)
	
	PlayFXAroundBuilding(self, "Remove")
	if IsKindOf(self, "Dome") then
		self:RestoreTerrain(nil, true)
	else
		self:RestoreTerrain()
	end

	DoneObject(self)
end

function Building:DroneWork(drone, request, resource, amount)
	if request then
		if request == self.clear_work_request then
			amount = DroneResourceUnits.repair

			drone:PushDestructor(function(drone)
				local self = drone.target
				if drone.w_request:GetActualAmount() <= 0 and IsValid(self) then
					self:ClearDone()
				end
			end)

			drone:ContinuousTask(request, amount, g_Consts.DroneBuildingRepairBatteryUse, "repairBuildingStart", "repairBuildingIdle", "repairBuildingEnd", "Repair")
			drone:PopAndCallDestructor()
		elseif request == self.refab_work_request then
			drone:PushDestructor(function(drone)
				local self = drone.target
				if drone.w_request:GetActualAmount() <= 0 and IsValid(self) then
					self:Refabricate()
				end
			end)
			
			PlayFX("Deconstruct", "start", self)
			drone:ContinuousTask(request, amount, g_Consts.DroneDeconstructBatteryUse, "constructStart", "constructIdle", "constructEnd", "Deconstruct")
			drone:PopAndCallDestructor()
		else
			RequiresMaintenance.DroneWork(self, drone, request, resource, amount)
		end
	end
end

function Building:CheatDestroy()
	self.indestructible = false
	if self.destroyed then
		self:ClearDone()
	else
		DestroyBuildingImmediate(self, nil, "dont_notify")
	end
end

function Building:CheatMalfunction()
	self:SetMalfunction()
end

function Building:CheatAddDust()
	self:AddDust(self.maintenance_threshold_current)
end

function Building:CheatAddMaintenancePnts()
	self:AccumulateMaintenancePoints(self.maintenance_threshold_current)
end

function Building:CheatCleanAndFix()
	self:Repair()
	self.accumulated_maintenance_points = 0
end

function Building:CheatUpgrade1()
	self:ApplyUpgrade(1, true)
end
function Building:CheatUpgrade2()
	self:ApplyUpgrade(2, true)
end
function Building:CheatUpgrade3()
	self:ApplyUpgrade(3, true)
end

function Building:CheatAddPrefab()
	self.city:AddPrefabs(self.template_name, 1)
end

local function CheatSpawnRunPrg(bld, id, prg, can_spawn_children, visit_duration)
	visit_duration = visit_duration or const.HourDuration
	local target = RotateRadius(100*guim, AsyncRand(360*60), bld:GetPos())
	local entrance, pos, entrance_spot = bld:GetEntrance(target, "entrance")
	if entrance_spot then
		pos = bld:GetSpotPos(bld:GetRandomSpot(entrance_spot))
	end
	if not pos then
		return
	end
	local angle = CalcOrientation(pos, #(entrance or "") > 1 and entrance[#entrance-1] or bld:GetPos())

	local unit = PlaceObjectIn("Unit", bld:GetMapID())
	NetTempObject(unit)
	unit.traits = {}
	unit.entity_gender = AsyncRand(2) == 1 and "Male" or "Female"
	unit.specialist = false
	unit.race = 1 + AsyncRand(5)
	unit.age_trait = "Adult"
	local usable_by_adults, usable_by_children
	if bld:HasMember("children_only") and bld.children_only then
		usable_by_children = true
	else
		usable_by_adults = true
		usable_by_children = can_spawn_children and (not bld:HasMember("usable_by_children") or bld.usable_by_children)
	end
	if usable_by_children and (not usable_by_adults or AsyncRand(100) < 30) then
		unit.traits.Child = true
	end
	local entity, ip_icon, pin_icon = GetSpecialistEntity(unit.specialist, unit.entity_gender, unit.race, unit.age_trait, unit.traits)
	unit:ChangeEntity(entity)
	unit.infopanel_icon = ip_icon
	unit.pin_icon = pin_icon
	unit.ip_specialization_icon, unit.pin_specialization_icon  = Colonist.GetSpecializationIcons(unit)

	unit.inner_entity = entity
	unit.SetOutsideEffects = empty_func
	unit.SetOutsideVisuals = Colonist.SetOutsideVisuals
	unit.SetOutside = unit.SetOutsideVisuals
	unit.fx_actor_class = unit.entity_gender == "Male" and "ColonistMale" or "ColonistFemale"
	unit:SetCollisionRadius(Colonist.radius)
	unit:SetDestlockRadius(Colonist.radius)
	unit:SetMoveAnim("moveWalk")
	unit:SetWaitAnim("idle")
	unit:SetMoveSpeed(Colonist.move_speed)
	unit.init_with_command = false
	unit:SetOpacity(0)
	unit:SetOpacity(100, 200)
	unit:SetAngle(angle)
	unit:SetPos(pos)
	bld:OnExitUnit(unit)
	local cmd_name = "Cheat" .. id
	unit[cmd_name] = function(self, prg, visit_duration, building)
		self:PushDestructor(function(self)
			if IsValid(self) then
				DoneObject(self)
			end
		end)
		self:EnterBuilding(building)
		self:PlayPrg(prg, visit_duration, building)
		self:ExitBuilding(building)
		self:SetOpacity(0, 200)
		Sleep(200)
		self:PopAndCallDestructor()
	end
	unit:SetCommand(cmd_name, prg, visit_duration, bld)
end

function Building:CheatSpawnWorker()
	CheatSpawnRunPrg(self, "Work", GetWorkPrg(self), false)
end

function Building:CheatSpawnVisitor()
	CheatSpawnRunPrg(self, "Visit", GetVisitPrg(self), true)
end

function Building:CheatMakeSphereTarget()
	MirrorSphereForcedTarget = self
end

function Building:ConstructUpgrade1(change)
	self:ConstructUpgrade(self:GetUpgradeID(1), change)
end

function Building:ConstructUpgrade2(change)
	self:ConstructUpgrade(self:GetUpgradeID(2), change)
end

function Building:ConstructUpgrade3(change)
	self:ConstructUpgrade(self:GetUpgradeID(3), change)
end

function Building:ConstructUpgrade(id)
	if UIColony:IsUpgradeUnlocked(id) and not self:HasUpgrade(id) then
		if self:IsUpgradeBeingConstructed(id) then
			self:StopUpgradeConstruction(id)
		else
			self:StartUpgradeConstruction(id)
		end
	end
end

function SavegameFixups.SupplyOneUpgradeAtATime()
	MapForEach("map", "Building", function(o)
		if o.upgrades_under_construction then			
			o:DisconnectFromCommandCenters()
			o.upgrade_being_built = false
			for id, data in pairs(o.upgrades_under_construction) do
				local reqs = data.reqs
				if not o.upgrade_being_built and reqs and not data.resources_delivered and not data.canceled then
					o.upgrade_being_built = id
				else
					for i = 1, #reqs do
						table.remove_entry(o.task_requests, reqs[i])
					end
				end
			end
			
			o:ConnectToCommandCenters()
		end
	end)
end

function Building:StartUpgradeConstruction(id)
	if not IsValid(self) then return end
	self.upgrades_under_construction = self.upgrades_under_construction or {}
	self.upgrade_being_built = self.upgrade_being_built or id
	
	if not self.upgrades_under_construction[id] then
		local tier = self:GetUpgradeTier(id)
		assert(tier)
		local reqs = {}
		self.upgrades_under_construction[id] = {
			id = id,
			tier = tier,
			construction_start_ts = false,
			required_time = self:GetUpgradeTime(tier),
			reqs = reqs,
			resources_delivered = false,
			canceled = false,
		}
		self:DisconnectFromCommandCenters()
		local is_free = true
		for i = 1, #AllResourcesList do
			local r_n = AllResourcesList[i]
			local c = self:GetUpgradeCost(tier, r_n)
			
			if c > 0 then
				is_free = false
				--0-5-> 2 drone, 6-8 - 3 drones, etc.
				local d_req = self:AddDemandRequest(r_n, c, const.rfUpgrade, Clamp(c/(const.ResourceScale * 3) + 1, 1, 8))
				reqs[#reqs + 1] = d_req
				--
				if self.upgrade_being_built ~= id then
					self.task_requests[#self.task_requests] = nil
				end
			end
		end
		
		self:ConnectToCommandCenters()
		
		if is_free then
			self.upgrades_under_construction[id].reqs = false
			self.upgrades_under_construction[id].resources_delivered = true
			self:OnUpgradeResourcesDelivered(id)
		end
	else
		--resuming
		self:ResumeUpgradeConstruction(id)
	end
	
	RebuildInfopanel(self)

	HintDisable("HintBuildingUpgrade")
end

function Building:StopAllUpgradeConstruction()
	if self.upgrades_under_construction then
		for id, _ in pairs(self.upgrades_under_construction) do
			--according to doc pairs can clear fields but not assign new fields, so this should be ok
			self:StopUpgradeConstruction(id)
		end
	end
end

function Building:StopUpgradeConstruction(id)
	local can_clean_up = true --if no resources are delivered, clean the thing
	local data = self.upgrades_under_construction[id]
	local reqs = data.reqs
	if reqs then
		for i = 1, #reqs do
			local r_n = reqs[i]:GetResource()
			if reqs[i]:GetActualAmount() ~= self:GetUpgradeCost(data.tier, r_n) then
				can_clean_up = false
				break
			end
		end
	end
	
	if not can_clean_up then
		data.canceled = true
		self:CleanUpgradeConstructionRequests(id, true)
	else
		self:CleanUpgradeConstructionRequests(id, false) 
		self.upgrades_under_construction[id] = nil
	end
	
	if self.upgrade_being_built == id then
		self:ConnectNextUpgradeRequests(id)
	end
	
	RebuildInfopanel(self)
end

function Building:ConnectNextUpgradeRequests(exclude_id, already_disconnected)
	for uid, data in pairs(self.upgrades_under_construction or empty_table) do
		if uid ~= exclude_id then
			local reqs = data and data.reqs
			if reqs and not data.resources_delivered and not data.canceled then
				self:DisconnectFromCommandCenters()
				self.upgrade_being_built = uid
				for i = 1, #reqs do
					table.insert(self.task_requests, reqs[i])
				end
				self:ConnectToCommandCenters()
				return
			end
		end
	end
	self.upgrade_being_built = false
end

function Building:IsUpgradeBeingConstructedAndCanceled(id)
	return self.upgrades_under_construction and self.upgrades_under_construction[id] and self.upgrades_under_construction[id].canceled or false
end

function Building:UpgradeCosts(index)
	local upgrade = self.upgrades_under_construction
	local id = self:GetUpgradeID(index)
	if upgrade and upgrade[id] then
		return self:GetCostsTArray(id, true)
	end
end

function Building:GetCostsTArray(id, include_total_cost)
	local costs = {}
	local available = {}
	if self.upgrades_under_construction and self.upgrades_under_construction[id] then
		local data = self.upgrades_under_construction[id]
		local reqs = data.reqs
		local sreqs = data.sreqs or empty_table
		for i = 1, #(reqs or empty_table) do
			local req = reqs[i]
			local sreq = sreqs[i]
			local r_n = req:GetResource()
			local amount_remaining = req:GetActualAmount()
			local total_cost = self:GetUpgradeCost(data.tier, r_n)
			local amount_supplying = sreq and sreq:GetActualAmount() or nil
			costs[#costs + 1] = FormatResource(empty_table, data.canceled and amount_supplying or (total_cost - amount_remaining), total_cost, r_n)
			available[#available + 1] = FormatResource(empty_table, GetCityResourceOverview(UICity):GetAvailable(r_n), r_n)
		end
	else
		local tier = self:GetUpgradeTier(id)
		for i = 1, #AllResourcesList do
			local r_n = AllResourcesList[i]
			local c = self:GetUpgradeCost(tier, r_n)
			if c > 0 then
				if include_total_cost then
					costs[#costs + 1] = FormatResource(empty_table, 0, c, r_n)
				else
					costs[#costs + 1] = FormatResource(empty_table, c, r_n)
				end
				available[#available + 1] = FormatResource(empty_table, GetCityResourceOverview(UICity):GetAvailable(r_n), r_n)
			end
		end
	end
	
	return table.concat(costs, " "), table.concat(available, " ")
end

function Building:IsUpgradeBeingConstructed(id)
	return self.upgrades_under_construction and self.upgrades_under_construction[id] and not self.upgrades_under_construction[id].canceled or false
end

function Building:ClearOwnRubble()
	Shroudable.ClearOwnRubble(self)
	self:UpdateWorking()
end

function Building:UpdateUpgradeConstructionSupplyRequests(data)
	assert(#self.command_centers == 0)
	local reqs = data.reqs
	if reqs then
		local sreqs = data.sreqs or {}
		data.sreqs = sreqs
		if Platform.developer and #sreqs > 0 then
			local sreq_cpy = table.copy(sreqs)
			CreateGameTimeThread(function(sreq_cpy)
				for i = 1, #sreq_cpy do
					local sreq = sreq_cpy[i]
					assert(sreq:GetActualAmount() == sreq:GetTargetAmount())
				end
			end, sreq_cpy)
		end
		for i = 1, #reqs do
			local resource = reqs[i]:GetResource()
			local amount = self:GetUpgradeCost(data.tier, resource) - reqs[i]:GetActualAmount()
			local sreq = sreqs[i]
			if amount > 0 and not sreq then
				local max_units = Clamp(amount / (const.ResourceScale * 3) + 1, 1, 8)
				sreq = self:AddSupplyRequest(resource, amount, const.rfUpgrade, max_units)
				sreqs[i] = sreq
			elseif sreq then
				sreq:SetAmount(amount)
				table.insert(self.task_requests, sreq)
			else
				sreqs[i] = false
			end
		end
	end
end

function Building:CleanUpgradeConstructionRequests(id, preserve_requestes)
	local data = self.upgrades_under_construction[id]
	local reqs = data and data.reqs
	local sreqs = data and data.sreqs or empty_table
	if reqs then
		self:InterruptDrones(nil, function(drone)
											return drone.d_request and table.find(reqs, drone.d_request) and drone or
													drone.s_request and table.find(sreqs, drone.s_request) and drone
										end, nil)

		self:DisconnectFromCommandCenters()

		for i = 1, #reqs do
			table.remove_entry(self.task_requests, reqs[i])
		end
		if not preserve_requestes then
			data.reqs = false
			if data.resources_delivered then
				if Platform.developer then
					local t = false
					local i = 1
					while not t and i <= #sreqs do
						t = sreqs[i]
						i = i + 1
					end
					if t then
						assert(not table.find(self.task_requests, t))
					end
				end
				
				data.sreqs = false
			end
		elseif not data.resources_delivered then
			self:UpdateUpgradeConstructionSupplyRequests(data)
		end
		self:ConnectToCommandCenters()
	end
end

function Building:ResumeUpgradeConstruction(id)
	local data = self.upgrades_under_construction[id]
	local reqs = data and data.reqs
	local sreqs = data and data.sreqs or empty_table
	data.canceled = false
	
	if reqs and not data.resources_delivered then
		self:InterruptDrones(nil, function(drone)
											return drone.s_request and table.find(sreqs, drone.s_request) and drone
										end, nil)
										
		self:DisconnectFromCommandCenters()
		
		for i = 1, #reqs do
			if sreqs[i] then
				assert(sreqs[i]:GetResource() == reqs[i]:GetResource())
				local r = sreqs[i]
				local a = self:GetUpgradeCost(data.tier, r:GetResource()) - r:GetActualAmount()
				assert(reqs[i]:GetActualAmount() == reqs[i]:GetTargetAmount())
				reqs[i]:SetAmount(a)
				table.remove_entry(self.task_requests, r)
			end
			
			if self.upgrade_being_built == id then
				table.insert(self.task_requests, reqs[i])
			end
		end
		
		self:ConnectToCommandCenters()
	end
	
	self:OnUpgradeResourcesDelivered(id)
end

function Building:OnStartWorkingStartUpgradeConstructionTimers()
	if not self.upgrades_under_construction then return end
	local tiers_to_apply = {}
	for upgrade_id, data in pairs(self.upgrades_under_construction) do
		if not data.canceled then
			if data.resources_delivered then
				if data.required_time > 0 then
					data.construction_start_ts = GameTime()
				else
					tiers_to_apply[#tiers_to_apply + 1] = data.tier
				end
			end
		end
	end
	if #tiers_to_apply > 0 then
		for i = 1, #tiers_to_apply do
			self:ApplyUpgrade(tiers_to_apply[i]) --this cleans up the data so it's not safe to call while iterating
		end
		RebuildInfopanel(self)
	end
end

function Building:OnUpgradeResourcesDelivered(id)
	if self.upgrades_under_construction[id].resources_delivered then --if not, onsetworking should call us
		if self.upgrades_under_construction[id].required_time > 0 then
			self.upgrades_under_construction[id].construction_start_ts = GameTime()
		else
			self:ApplyUpgrade(self.upgrades_under_construction[id].tier)
		end
		self:ConnectNextUpgradeRequests(id)
	end
end

function Building:UpdateUpgradeConstruction()
	if self.upgrades_under_construction then
		local tiers_to_apply = {}
		for upgrade_id, data in pairs(self.upgrades_under_construction) do
			if data.construction_start_ts and GameTime() - data.construction_start_ts >= data.required_time then
				tiers_to_apply[#tiers_to_apply + 1] = data.tier
			end
		end
		if #tiers_to_apply > 0 then
			for i = 1, #tiers_to_apply do
				self:ApplyUpgrade(tiers_to_apply[i]) --this cleans up the data so it's not safe to call while iterating
			end
			RebuildInfopanel(self)
		end
	end
end

function Building:GetUpgradeConstructionProgress1()
	return self:GetUpgradeConstructionProgress(1)
end

function Building:GetUpgradeConstructionProgress2()
	return self:GetUpgradeConstructionProgress(2)
end

function Building:GetUpgradeConstructionProgress3()
	return self:GetUpgradeConstructionProgress(3)
end

function Building:GetUpgradeConstructionProgress(tier)
	if not self.working or not self.upgrades_under_construction then 
		return 0
	end
	local id = self:GetUpgradeID(tier)
	local data = self.upgrades_under_construction[id]
	if data and data.construction_start_ts then		
		return MulDivRound(GameTime() - data.construction_start_ts, 100, data.required_time)
	end
	return 0
end

function Building:DroneUnloadResource(drone, request, resource, amount)
	if request:GetBuilding() ~= self then
		assert(not IsValid(self), "Invalid task request building")
		return
	end
	
	if self:DoesHaveConsumption() then
		self:ConsumptionDroneUnload(drone, request, resource, amount)
	end
	
	if self:DoesRequireMaintenance() then
		self:MaintenanceDroneUnload(drone, request, resource, amount)
	end
	
	if request:IsAnyFlagSet(const.rfUpgrade) then
		CreateGameTimeThread(function(self, request)
			if request:GetActualAmount() <= 0 then
				--succesfully fulfilled
				local map = self.upgrades_under_construction or empty_table
				for id, data in pairs(map) do
					local reqs = data.reqs
					if table.find(reqs, request) then
						local all_fulfilled = true
						for i = 1, #reqs do
							if reqs[i]:GetActualAmount() > 0 then
								all_fulfilled = false
								break
							end
						end
						if all_fulfilled then
							data.resources_delivered = true
							self:CleanUpgradeConstructionRequests(id, true)
							self:OnUpgradeResourcesDelivered(id)
						end
						break
					end
				end
			end
			RebuildInfopanel(self)
		end, self, request)
	end
end

function Building:ChangeSkin(skin, palette)
	if SelectedObj == self then
		PlayFX("Select", "end", self)
	end
	local realm = GetRealm(self)
	realm:SuspendPassEdits("Building.ChangeSkin")
	if self.working then
		self:ChangeWorkingStateAnim(false)
	end
	self:RestoreTerrain()
	self:ChangeEntity(skin)
	self:OnSkinChanged(skin, palette)
	self:DeduceAndReapplyDustVisualsFromState()
	if self.working then
		self:ChangeWorkingStateAnim(true)
	end
	realm:ResumePassEdits("Building.ChangeSkin")

	if SelectedObj == self then
		PlayFX("Select", "start", self)
	end
end

function Building:OnSkinChanged(skin, palette)
	local pipe_lookup = empty_table
	local cable_lookup = empty_table
	if IsKindOf(self, "LifeSupportGridObject") then
		pipe_lookup = self:GetPipeConnLookup()
	end
	if IsKindOf(self, "ElectricityGridObject") then
		cable_lookup = GetAllCableConnectionClassesTable()
	end
	
	self:DestroyAttaches(function(attach, pipe_lookup)
		return not pipe_lookup[attach] --pipe
			and not IsKindOfClasses(attach, "ResourceStockpileBase", "BuildingSign", "GridTileWater", table.unpack(cable_lookup))
													--own stockpile,          ui sign,         ui pipe helper
	end, pipe_lookup)
	AutoAttachObjectsToShapeshifter(self)
	self:AttachConfigurableAttaches()
	
	local cm1, cm2, cm3, cm4
	if palette then
		cm1, cm2, cm3, cm4 = DecodePalette(palette)
	else
		cm1, cm2, cm3, cm4 = GetBuildingColors(GetCurrentColonyColorScheme(), self)	
	end
	self:SetPalette(cm1, cm2, cm3, cm4)
	
	if self.parent_dome then
		DeleteUnattachedRoads(self, self.parent_dome)
	end
	local ft = self.force_fx_work_target
	if type(ft) == "table" and not IsValid(ft) and not IsKindOf(ft, "Object") then
		--auto particle target
		self.force_fx_work_target = false
	end
	self:ChangeWorkingStateAnim(self.working)
	self:BuildWaypointChains()
	self:SetIsNightLightPossible(self:IsNightLightPossible())
	CreateGameTimeThread(self.InterruptOpenAirState, self)
end

function Building:Getavailable_drone_prefabs()
	return self.city.drone_prefabs
end
----------------------------------------

DefineClassTemplate("Building", "Buildings", "Editors.Game", "Ctrl-Alt-B") -- all descendants of Building can be templated in a "Building Editor"

if FirstLoad then
	SortedBuildingTemplates = {} -- used in GameShortcuts
end
function OnMsg.BinAssetsLoaded()
	SortedBuildingTemplates = table.keys(ClassTemplates.Building)
	table.sort(SortedBuildingTemplates)
	ReloadShortcuts()
end

BuildingCSVColumns = {
	{ "name", "Name" },
	{ "display_name", "Display Name" },
	{ "description", "Description" },
	{ "build_category", "BM Category" },
	{ "build_pos", "BM Category Pos" },
	{ "max_dust", "Max Dust" },
	{ "cold_sensitive", "Cold Sensitive" },
	{ "dome_comfort", "Dome Comfort" },
	{ "dome_morale", "Dome Morale" },
	{ "service_comfort", "Comfort" },
	{ "construction_cost_Concrete", "Concrete Cost" },
	{ "construction_cost_Metals", "Metals Cost" },
	{ "construction_cost_Polymers", "Polymers Cost" },
	{ "construction_cost_Electronics", "Electronics" },
	{ "construction_cost_MachineParts", "Machine Parts" },
	{ "construction_cost_PreciousMetals", "Precious Metals"},
	{ "build_points", "Construction Pts" },
	{ "instant_build", "Instant Build" },
	{ "is_tall", "Tall Building" },
	{ "dome_required", "Requires Dome" },
	{ "dome_spot", "Required Dome Spot" },
	{ "dome_forbidden", "Outside Building" },
	{ "template_class", "Class" },
	{ "electricity_production", "Power Production" },
	{ "electricity_consumption", "Power Consumption" },
	{ "capacity", "Power/Colonist Capacity" },
	{ "air_production", "Air Production" },
	{ "air_consumption", "Air Consumption" },
	{ "air_capacity", "Air Capacity" },
	{ "water_production", "Water Production" },
	{ "water_consumption", "Water Consumption" },
	{ "water_capacity", "Water Capacity" },
	{ "max_workers", "Workers" },
	{ "specialist", "Preferred Specialist" },
	{ "enabled_shift_1", "Enabled Shift 1" },
	{ "enabled_shift_2", "Enabled Shift 2" },
	{ "enabled_shift_3", "Enabled Shift 3" },
	{ "max_visitors", "Visitors" },
	{ "ResearchPointsPerDay", "Research Pts Per Day" },
}

function ExportBuildingsCSV()
	local data = {}
	local template_names = table.keys(BuildingTemplates)
	for i = 1, #template_names do
		data[i] = {}
		local template = BuildingTemplates[template_names[i]]
		for j = 1, #BuildingCSVColumns do
			local prop = BuildingCSVColumns[j][1]
			data[i][prop] = PropObjHasMember(template, prop) and template[prop] or ""
		end
	end
	SaveCSV("Buildings.csv", data, table.map(BuildingCSVColumns, 1), table.map(BuildingCSVColumns, 2))
end

-- ui functions
function Building:Getui_dronehub_drones() return T{180, "Drones<right><DronesCount>/<CommandCenterMaxDrones>", self, CommandCenterMaxDrones = g_Consts.CommandCenterMaxDrones} end

NotWorkingWarning = {
	MechDepotWaitingForResourceUnload = T(9617, "Waiting for resources to unload."),
	PassageWaitingForColonistsToExit = T(9618, "Waiting for colonists to exit."),
	Demolish = T(181, "This building will be demolished in <em><FormatScale(demolishing_countdown,1000,true)></em> sec."),
	Malfunction = T(182, "This building has malfunctioned. Repair it with Drones."),
	MalfunctionRes = T(60192, "This building has malfunctioned. Drones can repair it with <resource(maintenance_resource_amount, maintenance_resource_type)>."),
	Frozen = T(183, "This building is frozen. It can be repaired by Drones after the Cold Wave has passed."),
	FrozenPerma = T(7892, "This building is frozen. Use a Subsurface Heater to heat the surrounding cold area."),
	IonStorm = T(8926, "This building has been disabled by an Ion Storm."),
	Defrosting = T(8520, "Defrosting. This building will need repair after it is defrosted."),
	TurnedOff = T(184, "This building has been turned off."),
	ExceptionalCircumstancesDisabled = T(10903, "This building is disabled due to exceptional circumstances"),
	ExceptionalCircumstancesMalafunction = T(10904, "This building was damaged due to exceptional circumstances. Drones can repair it with <resource(maintenance_resource_amount, maintenance_resource_type)>."), 
	NoResourceExceptionalCircumstancesMalafunction = T(11568, "This building was damaged due to exceptional circumstances."), 
	ExceptionalCircumstancesMaintenance = T(10905, "This building requires maintenance due to exceptional circumstances. Required resources <resource(maintenance_resource_amount, maintenance_resource_type)>."),
	NoResourceExceptionalCircumstancesMaintenance = T(11569, "This building requires maintenance due to exceptional circumstances."),
	SuspendedDustStorm = T(185, "Doesn't function during Dust Storms."),
	Suspended = T(7524, "Building disabled by lightning strike. Will resume work in several hours."),
	NoDeposits = T(187, "No deposits"),
	NoExploitableDeposits = T(188, "There are no exploitable deposits in range"),
	NoStorageSpace = T(189, "Storage space is full"),
	TooFarFromWorkforce = T(190, "This building requires Colonists and is too far from your Domes."),
	InactiveWorkshift = T(191, "Inactive work shift"),
	NotEnoughWorkers = T(192, "Not enough Workers"),
	NoPower = T(193, "Not enough Power"),
	NoOxygen = T(194, "Not enough Oxygen"),
	NoOxygenOpenCity = T(12388, "Unbreathable atmosphere"),
	NoWater = T(195, "Not enough Water"),
	NotConnectedToPowerGridConsumer = T(196, "Must be connected to a Power consumer"),
	NotConnectedToPowerGridProducer = T(197, "Must be connected to a Power producer"),
	NotConnectedToWaterConsumer = T(198, "Must be connected to a Water consumer"),
	NotConnectedToWaterProducer = T(199, "Must be connected to a Water producer"),
	NotConnectedToAirConsumer = T(200, "Must be connected to an Oxygen consumer"),
	NotConnectedToAirProducer = T(201, "Must be connected to an Oxygen producer"),
	NoResearch = T(202, "No research project assigned"),
	LowWind = T(203, "Not producing due to low wind and elevation"),
	Renegades = T(204, "You???ll need more operational Security Stations to deal with Renegade crime in the Dome"),
	WasteRock = T(205, "Waste Rock storage is full"),
	UnexploitableDeposit = T(206, "We can't exploit this deposit with our current technology"),
	WaitingFuel = T(207, "Waiting for Fuel"),
	Default = T(208, "This building is not working"),
	Destroyed = T(209, "This building has been destroyed"),
	Consumption = T(210, "Building is waiting for <resource(1000, consumption_resource_type)> to resume working"),
	WorkshopConsumption = T(8768, "Building is waiting for <resource(consumption_resource_type)> to resume working"),
	NoCrop = T(7525, "No crop set"),
	ToxicRain = T(12152, "Doesn't function during Toxic Rains."),
	NoCommandCenter = T(632, "Outside Drone commander range."),
	NoDroneHub = T(845, "Too far from working Drone commander."),
	DomeNotWorking = T(10548, "This building doesn't work because the Dome has been turned off"),
	Halted = T(11000, "The construction process has been halted due to exceptional circumstances."),
	MechDepotUnloading = T(12389, "Waiting for stored resources to be moved out before demolishing."),
	Refab = T(13591, "This building is being converted to a Prefab."),
}

local function UIWarningNoDeposits(self)
	return IsKindOf(self, "BuildingDepositExploiterComponent") and not self:HasNearbyDeposits() and not self.city.colony:IsTechResearched("NanoRefinement")
end

local function UIWarningNoExploitableDeposits(self)
	return IsKindOf(self, "BuildingDepositExploiterComponent") and not self:CanExploit() and not self.city.colony:IsTechResearched("NanoRefinement")
end

local function UIWarningAirConsumer(self)
	return IsKindOf(self, "AirConsumer") and self:ShouldShowNotConnectedToLifeSupportGridSign() and
		self:NeedsAir() and #self.air.grid.producers <= 0
end

local function UIWarningWaterConsumer(self)
	return IsKindOf(self, "WaterConsumer") and self:ShouldShowNotConnectedToLifeSupportGridSign() and
		self:NeedsWater() and #self.water.grid.producers <= 0
end

function Building:GetUIWarning()
	-- errors
	local reason = false
	if not self.ui_working then	
		reason = "TurnedOff" 
	elseif self.demolishing then
		reason = "Demolish"
	elseif self.refab_work_request then
		reason = "Refab"
	elseif self.exceptional_circumstances_maintenance then
		reason = self:IsMalfunctioned() and "ExceptionalCircumstancesMalafunction" or "ExceptionalCircumstancesMaintenance"
		if self.maintenance_resource_type == "no_resource" or self.maintenance_resource_type == "no_maintenance" then
			reason = "NoResource" .. reason
		end
	elseif self:IsMalfunctioned() then
		if self:DoesRequireMaintenance() then
			reason = "MalfunctionRes"
		else
			reason = "Malfunction"
		end	
	elseif self.exceptional_circumstances then	
		reason  = "ExceptionalCircumstancesDisabled"
	elseif self.destroyed then
		reason = "Destroyed"
	elseif #(self.ion_storms or empty_table) > 0 then
		reason = "IonStorm"
	elseif self.frozen then
		reason = HasColdWave(self:GetMapID()) and "Frozen" or self:IsFreezing() and "FrozenPerma" or "Defrosting"
	elseif self.suspended then
		reason = self.suspended
	elseif UIWarningNoDeposits(self) then
		reason = "NoDeposits" 
	elseif UIWarningNoExploitableDeposits(self) then
		reason = "NoExploitableDeposits"
	elseif IsKindOf(self, "ResourceProducer") and ResourceProducer.GetWorkNotPossibleReason(self) then 
		local waste_rock_producer = self.wasterock_producer
		if waste_rock_producer and waste_rock_producer:IsStorageFull() then
			reason = "WasteRock"
		elseif not IsKindOf(self, "WaterProducer") then
			reason = "NoStorageSpace"
		end
	elseif IsKindOf(self, "Workplace") and not self:HasNearByWorkers()  then
		reason = "TooFarFromWorkforce"
	elseif IsKindOf(self, "Workplace") and not self:HasWorkersForCurrentShift() then
		if self.active_shift == 0 and self:IsClosedShift(self.current_shift) and self:HasAnyWorkers() then
			reason = "InactiveWorkshift"
		else
			reason = "NotEnoughWorkers"
		end
	elseif IsKindOf(self, "OutsideBuildingWithShifts") and self:IsClosedShift(self.current_shift) then
		reason = "InactiveWorkshift"
	elseif IsKindOf(self, "ElectricityGridObject") and self:ShouldShowNotConnectedToPowerGridSign() then
		reason = IsKindOf(self, "ElectricityProducer") and "NotConnectedToPowerGridConsumer" or "NotConnectedToPowerGridProducer"
	elseif IsKindOf(self, "ElectricityConsumer") and self:ShouldShowNoElectricitySign() then
		reason = "NoPower"
	elseif UIWarningAirConsumer(self) then
		reason = "NotConnectedToAirProducer"
	elseif UIWarningWaterConsumer(self) then
		reason = "NotConnectedToWaterProducer"
	elseif IsKindOf(self, "LifeSupportConsumer") and self:ShouldShowNoAirSign() then
		reason = "NoOxygen"
	elseif IsKindOf(self, "LifeSupportConsumer") and self:ShouldShowNoWaterSign() then
		reason = "NoWater"
	elseif IsKindOf(self, "LifeSupportGridObject") and self:ShouldShowNotConnectedToLifeSupportGridSign() then
		reason = IsKindOf(self, "AirProducer") and "NotConnectedToAirConsumer"
			or IsKindOf(self, "WaterProducer") and "NotConnectedToWaterConsumer"
	elseif IsKindOf(self, "BaseResearchLab") and not self:TechId() then
		reason = "NoResearch"
	elseif IsKindOf(self, "WindTurbine") and not self:IsProducingEnoughToWork() then
		reason = "LowWind"
	elseif IsKindOf(self, "SecurityStation") and self:GetAdjustedRenegades()>0 then
		reason = "Renegades"
	elseif IsKindOf(self, "BuildingDepositExploiterComponent") and self:IsTechLocked() then
		reason = "UnexploitableDeposit"
	elseif IsKindOf(self, "RocketBase") and self.landed and not self:HasEnoughFuelToLaunch() then
		--reason = "WaitingFuel"
	elseif not self:CanConsume() then
		if IsKindOf(self, "Workshop") then
			reason = "WorkshopConsumption"
		else
			reason = "Consumption"
		end
	elseif self:ShouldShowNoCCSign() then
		reason = "NoDroneHub"
	elseif IsKindOf(self, "MechanizedDepot") and self:ShouldShowUnloadWarning() then
		reason = "MechDepotUnloading"
	end
	
	reason = reason or self:GetNotWorkingReason()
	return reason and NotWorkingWarning[reason]
end

function Building:ShowUISectionConsumption()
	return
		self:IsKindOf("ElectricityConsumer") and self.electricity_consumption
			and (self.electricity_consumption>0 or self:GetClassValue("electricity_consumption")>0)
		or self:IsKindOf("LifeSupportConsumer")
			and ((self.air_consumption and (self.air_consumption>0 or self:GetClassValue("air_consumption")>0))
				or (self.water_consumption and (self.water_consumption>0 or self:GetClassValue("water_consumption")>0)))
		or self:IsKindOf("HasConsumption") and self:DoesHaveConsumption()
		or #(self.upgrade_consumption_objects or empty_table)>0 
end

function Building:ShowUISectionElectricityProduction()
	return self:IsKindOf("ElectricityProducer")
end

function Building:ShowUISectionElectricityGrid()
	return self:IsKindOfClasses("ElectricityProducer", "ElectricityStorage") and self.electricity
end

ConsumptionStatuses = {
	Power = T(334, "Power<right><green><power(electricity_consumption)></green>"),
	PowerNotEnough = T(335, "Insufficient Power<right><red><power(electricity_consumption)></red>"),
	PowerRequired = T(336, "Required Power<right><power(electricity_consumption)>"),
	Oxygen = T(337, "Oxygen<right><green><air(air_consumption)></green>"),
	OxygenNotEnough = T(338, "Insufficient Oxygen<right><red><air(air_consumption)></red>"),
	OxygenRequired = T(339, "Required Oxygen<right><air(air_consumption)>"),
	Water = T(340, "Water<right><green><water(water_consumption)></green>"),
	WaterNotEnough = T(341, "Insufficient Water<right><red><water(water_consumption)></red>"),
	WaterRequired = T(342, "Required Water<right><water(water_consumption)>"),
	InsufficientResource = T(343, "Insufficient <resource(consumption_resource_type)><right><red><resource(consumption_stored_resources,consumption_max_storage,consumption_resource_type)></red>"),
	Resource = T(344, "Stored <resource(consumption_resource_type)><right><resource(consumption_stored_resources,consumption_max_storage,consumption_resource_type)>"),
	StoredWater = T(7336, "Stored Water<right><water(stored_water,water_capacity)>"),
}

ConsumptionStatusesShort = {
	Power = T(9689, "<green><power(electricity_consumption)></green>"),
	PowerNotEnough = T(9690, "<red><power(electricity_consumption)></red>"),
	PowerRequired = T(9691, "<power(electricity_consumption)>"),
	Oxygen = T(9692, "<green><air(air_consumption)></green>"),
	OxygenNotEnough = T(9693, "<red><air(air_consumption)></red>"),
	OxygenRequired = T(9694, "<air(air_consumption)>"),
	Water = T(9695, "<green><water(water_consumption)></green>"),
	WaterNotEnough = T(9696, "<red><water(water_consumption)></red>"),
	WaterRequired = T(9697, "<water(water_consumption)>"),
	InsufficientResource = T(9698, "<red><resource(consumption_stored_resources,consumption_max_storage,consumption_resource_type)></red>"),
	Resource = T(9699, "<resource(consumption_stored_resources,consumption_max_storage,consumption_resource_type)>"),
	StoredWater = T(9700, "<water(stored_water,water_capacity)>"),
}

function Building:UpdateUISectionConsumption(win)
	win.idPower:SetText("")
	win.idAir:SetText("")
	win.idWater:SetText("")
	win.idResource:SetText("")
	local res = self:GetUIConsumptionTexts()
	if res.power then win.idPower:SetText(res.power) end
	if res.air then win.idAir:SetText(res.air) end
	if res.water then win.idWater:SetText(res.water) end
	if res.stored_water then win.idStoredWater:SetText(res.stored_water) end
	if res.resource then win.idResource:SetText(res.resource) end
	if res.upgrade then win.idUpgrade:SetText(res.upgrade) end
end

function Building:GetUIConsumptionTexts(short)
	local statuses = short and ConsumptionStatusesShort or ConsumptionStatuses
	local res = {}
	local intentionally_not_consuming = self:IsSupplyGridDemandStoppedByGame()
	local permited = self:IsWorkPermitted()

	local not_permited = (not permited or intentionally_not_consuming)
	if self:IsKindOf("ElectricityConsumer") and self.electricity_consumption
		and (self.electricity_consumption>0 or self:GetClassValue("electricity_consumption")>0) 
	then
		local not_enough = self:ShouldShowNoElectricitySign() and not (intentionally_not_consuming or self.suspended)
		res.power = not_enough and statuses["PowerNotEnough"]
			or not_permited and statuses["PowerRequired"]
			or statuses["Power"]
	end
	if self:IsKindOf("AirConsumer") then
		if self.air_consumption and (self.air_consumption>0 or self:GetClassValue("air_consumption")>0) then
			local no_air = not (self:HasAir() or intentionally_not_consuming) and permited
			res.air = no_air and statuses["OxygenNotEnough"]
				or not_permited and statuses["OxygenRequired"]
				or statuses["Oxygen"]
		end
	end
	if self:IsKindOf("WaterConsumer") then
		if IsKindOf(self, "ArtificialSun") then
			if self.work_state ~= "produce" then
				res.water = not (self:HasWater() or intentionally_not_consuming) and permited and statuses["WaterNotEnough"]
					or not_permited and statuses["WaterRequired"]
					or (short and T{9701, "<green><water(number)></green>", number = self.water.current_consumption} 
						or T{345, "Water<right><green><water(number)></green>", number = self.water.current_consumption})
				res.stored_water = statuses["StoredWater"]
			end
		elseif self.water_consumption and (self.water_consumption>0 or self:GetClassValue("water_consumption")>0) then
			local no_water = not (self:HasWater() or intentionally_not_consuming) and permited 
			res.water = no_water and statuses["WaterNotEnough"]
				or not_permited  and statuses["WaterRequired"]
				or statuses["Water"]
		end
	end
	if self:IsKindOf("HasConsumption") and self:UIShowConsumption() and self.consumption_stored_resources then
		res.resource = self.consumption_stored_resources > 0 and statuses["Resource"] 
			or statuses["InsufficientResource"]
	end

	-- consumption from upgrades
	if #(self.upgrade_consumption_objects or empty_table)>0 then
		local texts = {}
		for _,cons_obj in ipairs(self.upgrade_consumption_objects) do
			if self.upgrade_on_off_state[cons_obj.upgrade_id] then
				local res_type = cons_obj.consumption_resource_type
				texts[#texts+1] = short and T{9702, "<resource(consumed_amount,res_type)>",resource_name = GetResourceInfo(res_type).display_name,  res_type = res_type, consumed_amount = cons_obj.consumption_amount }
					or T{7767, "<resource_name><right><resource(consumed_amount,res_type)>",resource_name = GetResourceInfo(res_type).display_name,  res_type = res_type, consumed_amount = cons_obj.consumption_amount }
			end
		end
		res.upgrade = table.concat(texts, short and " " or "<newline>")
	end
	return res
end

function Building:GetUISectionConsumptionRollover()
	local items = {}
	items[#items+1] = self:IsKindOf("Dome") and T(8652, "The total consumption of the Dome and all buildings inside is indicated in the infopanel. Individual consumption of the Dome is in parentheses. Red text indicates that the required resource is not provided.")
		or T(315, "Current consumption of this building is indicated in the infopanel. Red text indicates that the required resource is not provided.")
	items[#items+1] = T(8653, "<newline><center><em>Grid Parameters<left></em>")
	local grid = false
	if self:IsKindOf("ElectricityConsumer") and self.electricity and self.electricity_consumption and (self.electricity_consumption>0 or self:GetClassValue("electricity_consumption")>0) then
		grid = self.electricity.grid
		items[#items+1] = T{318, "Power production<right><power(current_production)>", grid}
		items[#items+1] = T{319, "Max production<right><power(production)>", grid}
		items[#items+1] = T{320, "Power consumption<right><power(current_consumption)>", grid}
		items[#items+1] = T{321, "Total demand<right><power(consumption)>", grid}
		items[#items+1] = T{322, "Stored Power<right><power(current_storage)>", grid}
		if self:GetColdPenalty()>0 then
			items[#items+1] = T{317, "<em>The Power consumption of this building is increased by <red><percent(ColdPenalty)></red> due to low temperature.</em>", self}
		end
		items[#items+1] = T(316, "<newline>")
	end
	if self:IsKindOf("AirConsumer") and self.air and self.air_consumption and (self.air_consumption>0 or self:GetClassValue("air_consumption")>0) then
		grid = self.air.grid
		items[#items+1] = T{324, "Oxygen production<right><air(current_production)>", grid}
		items[#items+1] = T{325, "Max production<right><air(production)>", grid}
		items[#items+1] = T{326, "Oxygen consumption<right><air(current_consumption)>", grid}
		items[#items+1] = T{327, "Total demand<right><air(consumption)>", grid}
		items[#items+1] = T{328, "Stored Oxygen<right><air(current_storage)>", grid}
		items[#items+1] = T(316, "<newline>")
	end
	if self:IsKindOf("WaterConsumer") and self.water and self.water_consumption and (self.water_consumption>0 or self:GetClassValue("water_consumption")>0) then
		grid = self.water.grid
		items[#items+1] = T{329, "Water production<right><water(current_production)>", grid}
		items[#items+1] = T{330, "Max production<right><water(production)>", grid}
		items[#items+1] = T{331, "Water consumption<right><water(current_consumption)>", grid}
		items[#items+1] = T{332, "Total demand<right><water(consumption)>", grid}
		items[#items+1] = T{333, "Stored Water<right><water(current_storage)>", grid}
		items[#items+1] = T(316, "<newline>")
	end
	-- consumption from upgrades
	if #(self.upgrade_consumption_objects or empty_table)>0 then
		for _, cons_obj in ipairs(self.upgrade_consumption_objects) do
			if self.upgrade_on_off_state[cons_obj.upgrade_id] then
				local res_type = cons_obj.consumption_resource_type
				items[#items+1] = T{7768, "Stored <resource_name><right><resource(stored,max_stored,res_type)>",resource_name = GetResourceInfo(res_type).display_name,  res_type = res_type, stored = cons_obj.consumption_stored_resources, max_stored =  cons_obj.consumption_max_storage }
			end
		end	
		items[#items+1] = T(316, "<newline>")
	end

	return table.concat(items, Untranslated("<newline><left>"))
end

function Building:GetBuildMenuProductionText(production_props)
	local production = {}
	for i = 1, #production_props do
		local prop = table.find_value(self.properties, "id", production_props[i][1])
		if prop and self[prop.id] ~= 0 then
			local resource_name = production_props[i][2]
			if not resource_name then
				local resource_id = self[production_props[i][3]]
				if resource_id and resource_id ~= "" and resource_id ~= "WasteRock" then
					resource_name = GetResourceInfo(resource_id).id
				end
			end
			if resource_name then
				production[#production + 1] = FormatResource(empty_table, self[prop.id], resource_name)
			end
		end
	end
	if next(production) then
		return T(3967, "Base production: ") .. table.concat(production, " ")
	end
end

function Building:GetBroadcastLabel()
	return self.template_name ~= "" and self.template_name or self.class
end

function Building:TogglePriority(change, broadcast)
	TaskRequester.TogglePriority(self, change)
	RebuildInfopanel(self)
	if broadcast then
		BroadcastAction(self, function(obj)
			assert(IsValid(obj))
			if not obj.destroyed then
				obj:SetPriority(self.priority)
			end
		end)
	end
end

function Building:UpdateOccupation(visitors, capacity)
	local increase = visitors > self.occupation
	local decrease = visitors < self.occupation
	local occupation_percent = MulDivRound(visitors, 100, capacity)
	if increase then
		if self.occupation_fx ~= "OccupationFull" and occupation_percent > 66 then
			if self.occupation_fx then
				PlayFX(self.occupation_fx, "end", self)
			end
			self.occupation_fx = "OccupationFull"
			PlayFX("OccupationFull ", "start", self)
		elseif self.occupation_fx ~= "OccupationPopulated" and occupation_percent > 33 and occupation_percent < 67 then
			if self.occupation_fx then
				PlayFX(self.occupation_fx, "end", self)
			end
			self.occupation_fx = "OccupationPopulated"
			PlayFX("OccupationPopulated", "start", self)
		elseif self.occupation_fx ~= "OccupationLow" and occupation_percent < 34 then
			self.occupation_fx = "OccupationLow"
			PlayFX("OccupationLow", "start", self)
		end
	end
	if decrease then
		if self.occupation_fx and occupation_percent == 0 then
			PlayFX(self.occupation_fx, "end", self)
			self.occupation_fx = false
		elseif self.occupation_fx ~= "OccupationLow" and occupation_percent > 0 and occupation_percent < 34 then
			if self.occupation_fx then
				PlayFX(self.occupation_fx, "end", self)
			end
			self.occupation_fx = "OccupationLow"
			PlayFX("OccupationLow", "start", self)
		elseif self.occupation_fx ~= "OccupationPopulated" and occupation_percent > 33 and occupation_percent < 67 then
			if self.occupation_fx then
				PlayFX(self.occupation_fx, "end", self)
			end
			self.occupation_fx = "OccupationPopulated"
			PlayFX("OccupationPopulated", "start", self)
		
		end
	end
	self.occupation = visitors
end

function GetBuildingObj(bld_or_site)
	if IsKindOf(bld_or_site, "ConstructionSite") and bld_or_site.building_class_proto:IsKindOf("Building") then
		return bld_or_site.building_class_proto
	elseif IsKindOf(bld_or_site, "Building") then
		return bld_or_site
	end
end

function PlayFXBuildingType(fx, moment, city, class, ignore)
	if city.labels[class] then
		for _, bld in ipairs(city.labels[class]) do
			if bld ~= ignore then
				PlayFX(fx, moment, bld)
			end
		end
	end
	local label = class == "Dome" and city.labels.Domes_Construction or city.labels.ConstructionSite
	if label then
		for _, site in ipairs(label) do
			if site ~= ignore and IsKindOf(site.building_class_proto, class) then
				PlayFX(fx, moment, site, class)
			end
		end
	end
end

function GetAllAnimMoments(obj, anim)
	anim = anim or GetStateName(obj:GetAnim(1))
	local ttt = {}
	local ret = {}
	local c = obj:GetAnimMomentsCount(anim)
	for i = 1, c do
		local s = obj:TypeOfMoment(1, i)
		if s ~= "" then
			ttt[s] = true
		end
	end
	for k, v in pairs(ttt) do 
		table.insert(ret, k)
	end
	
	return ret
end

function TrackAllMoments(obj, fx_action, fx_actor, fx_target) --expects to obj already be playing the anim we want to track
	fx_actor = fx_actor or obj
	fx_target = fx_target or nil
	fx_action = fx_action or "TrackedAnim"
	
	local moment_names = GetAllAnimMoments(obj)
	local tracked_anim_idx = obj:GetAnim(1)
	local t = CreateGameTimeThread(function(obj, moment_names, tracked_anim_idx, fx_action, fx_actor, fx_target)
		local next_m = obj:TypeOfMoment(1, 1) or ""
		if next_m ~= "" then
			local first_moment_t = obj:TimeToMoment(1, next_m, 1) or -1
			if first_moment_t > 0 then
				AnimMomentHook.WaitAnimMoment(obj, next_m) --sleep
			end
		end
		while IsValid(obj) and obj:GetAnim(1) == tracked_anim_idx and next_m ~= "" do
			local lowest_t = 9999999
			next_m = ""
			for i = #moment_names, 1, -1 do
				local t = obj:TimeToMoment(1, moment_names[i], 1) or -1
				if t == 0 then
					PlayFX(fx_action, moment_names[i], fx_actor, fx_target)
					--print(fx_action, moment_names[i], fx_actor.class, fx_target and fx_target.class, obj:GetAnimPhase(1))
					local next_t = obj:TimeToMoment(1, moment_names[i], 2)
					if not next_t then
						table.remove(moment_names, i) --no more moments of this type
					elseif next_t < lowest_t then
						lowest_t = next_t
						next_m = moment_names[i]
					end
				elseif t > 0 and t < lowest_t then
					lowest_t = t
					next_m = moment_names[i]
				elseif t == -1 then
					--no more moments of this type remain, and anim aint looped
					table.remove(moment_names, i)
				end
			end
			
			if next_m == "" then break end
			AnimMomentHook.WaitAnimMoment(obj, next_m) --sleep
		end
	end, obj, moment_names, tracked_anim_idx, fx_action, fx_actor, fx_target)
	
	return t
end

function GetDomeSkins(template, class)
	local skins = {{template.entity, class.configurable_attaches, construction_entity = template.construction_entity}}
	local palettes = { { template.palette_color1, template.palette_color2, template.palette_color3, template.palette_color4 } }
	ForEachPreset("DomeSkins", function(preset, grp, skins, class)
		if preset.dome_type == class.class then
			table.insert(skins, {
				preset.entity, 
				GetConfigAttachTableFromPreset(preset),
				construction_entity = preset.construction_entity, 
				skin_category = preset.preset, })
			table.insert(palettes, { preset.palette_color1, preset.palette_color2, preset.palette_color3, preset.palette_color4 } )
						
		end
	end, skins, class)
	
	return skins, palettes
end

function GetBuildingSkins(template_name, entity)
	local template = BuildingTemplates[template_name]
	if not template then return {}, {} end
	local class = ClassTemplates.Building[template.template_class]
	if IsKindOf(class, "Dome") then
		return GetDomeSkins(template, class)
	end
	local skins = { template.entity }
	local palettes = { { template.palette_color1, template.palette_color2, template.palette_color3, template.palette_color4 } }
	for i = 2, MaxAltEntityIdx do
		local entity = template["entity" .. i]
		if entity == "" then
			break
		end
		if IsDlcAccessible(template["entitydlc" .. i]) then
			table.insert(skins, entity)
			table.insert(palettes, { template["palette" .. i .. "_color1"], template["palette" .. i .. "_color2"], template["palette" .. i .. "_color3"], template["palette" .. i .. "_color4"] })
		end
	end
	if entity then
		if not table.find(skins, entity) then
			table.insert(skins, 1, entity)
			table.insert(palettes, 1, false)
		end
	end
	
	return skins, palettes
end

function Building:SetDustVisuals(dust)
	local in_dome = IsObjInDome(self)
	if in_dome and not self.destroyed then return end
	if self:GetGameFlags(const.gofUnderConstruction) ~= 0 then return end
	
	return BuildingVisualDustComponent.SetDustVisuals(self, dust)
end

function Building:CanGetDamagedBy(object)
	return true
end

----

local fx_actions = {}
do
	local suffix = "Building"
	local sizes = { "Small", "Big" }
	local actions = { "Demolish", "Remove", "Place" }
	local locs = { "Inside", "Outside" }
	for i=1,#sizes do
		local size = sizes[i]
		local str1 = suffix .. size
		fx_actions[size] = {}
		for j=1,#actions do
			local action = actions[j]
			local str2 = str1 .. action
			fx_actions[size][action] = {}
			for k=1,#locs do
				local loc = locs[k]
				local str3 = str2 .. loc
				fx_actions[size][action][loc] = str3
				fx_actions[#fx_actions + 1] = str3
			end
		end
	end
end

function PlayFXAroundBuilding(obj, action)
	if not IsValid(obj) or not obj:GetVisible() or GameTime() == 0 then
		return
	end
	local shape = GetEntityPeripheralHexShape(obj:GetEntity())
	local size = #shape > 30 and "Big" or "Small"
	local object_hex_grid = GetObjectHexGrid(obj)
	local res = object_hex_grid:GetObjectAtPos(obj, "DomeInterior")

	local inside = res and res.dome and obj ~= res.dome and "Inside" or "Outside"
	local action = fx_actions[size][action][inside]
	
	local pos, angle
	local orig_state = IsKindOf(obj, "Building") and obj.orig_state
	if orig_state then
		pos, angle = unpack(orig_state)
	else
		pos, angle = obj:GetPos(), obj:GetAngle()
	end
	--DbgClear()
	local dir = HexAngleToDirection(obj:GetAngle())
	local cq, cr = WorldToHex(obj)
	for _, shape_pt in ipairs(shape) do
		local sx, sy = shape_pt:xy()
		local q, r = HexRotate(sx, sy, dir)
		local hx, hy = HexToWorld(cq + q, cr + r)
		PlayFX(action, "start", obj, nil, point(hx, hy))
		--DbgAddVector(point(hx, hy))
	end
end

function OnMsg.GatherFXActions(list)
	for i=1,#fx_actions do
		list[#list + 1] = fx_actions[i]
	end
end

GlobalVar("ShowingGridTileWaterAttachesOn", false)
function OnMsg.SelectionChange()
	if ShowingGridTileWaterAttachesOn then
		SetObjWaterMarkers(ShowingGridTileWaterAttachesOn, false)
		ShowingGridTileWaterAttachesOn = false
	end
	local o = SelectedObj
	if o and IsKindOf(o, "LifeSupportGridObject") and SetObjWaterMarkers(o, true) then
		ShowingGridTileWaterAttachesOn = o
	end
end

function SelectNextBuildingOfSameType(dir)
	local igi = GetInGameInterface()
	local dlg = GetHUD()
	if igi and dlg and dlg:GetVisible() and igi:GetVisible() then
		local bld
		if IsKindOf(SelectedObj, "Building") and SelectedObj.build_category ~= "Hidden" then
			local name = IsKindOf(SelectedObj, "ConstructionSite") and "ConstructionSite" or SelectedObj.template_name
			local buildings = UICity.labels[name] or {}
			local idx = table.find(buildings, SelectedObj)
			local count = #buildings
			repeat
				idx = idx and buildings[idx + dir] and idx + dir or dir == 1 and 1 or count
				bld = buildings[idx]
			until bld.template_name == name or bld.template_name == "" and name == "ConstructionSite"
		else
			local realm = GetActiveRealm()
			bld = realm:MapFindNearest(GetTerrainGamepadCursor(), "map", "Building", const.efSelectable, function(obj) return obj.build_category ~= "Hidden" end)
		end
		ViewAndSelectObject(bld)
	end
end

local function DestroyedVehiclesParamFunc(displayed_in_notif)
	local rovers = 0
	for i,obj in ipairs(displayed_in_notif) do
		if IsKindOf(obj, "BaseRover") then
			rovers = rovers + 1
		end
	end
	local drones = #displayed_in_notif - rovers
	return { rovers = rovers, drones = drones }
end

GlobalVar("g_DestroyedVehicles", {})
GlobalGameTimeThread("DestroyedDronesNotif", function()
	HandleNewObjsNotif(g_DestroyedVehicles, "DestroyedVehicles", nil, DestroyedVehiclesParamFunc, nil, true)
end)

function SavegameFixups.DestroyedVehiclesNotifRestart()
	RestartGlobalGameTimeThread("DestroyedDronesNotif")
end

----

local range = 3500 --copied from large meteor
local position
local function filter(obj, building)
	return obj:IsCloser2D(position, range + obj:GetRadius())
	--and not IsObjInDome(obj)
	and (IsKindOf(obj, "ResourceStockpileBase") or not obj:GetParent())
end

local function GetExplosionQuery(building, range)
	local pos = building:GetPos()
	return pos, range + GetEntityMaxSurfacesRadius() , "Drone", "Colonist", "Building", "BaseRover", "ResourceStockpileBase", "ElectricityGridElement", "LifeSupportGridElement", "PassageGridElement" , filter
end

--immitates meteor explosion in the center of the building
function Building:BlowUp(kill_colonists, reason, single_building, explosion_range)
	explosion_range = explosion_range or range
	
	local units = self.units and table.copy(self.units) or empty_table
	
	position = self:GetPos()
	local colonists_to_kill = {}
	if kill_colonists then
		for _, unit in ipairs(units) do
			if unit:IsKindOf("Colonist") then
				table.insert(colonists_to_kill, unit)
			end
		end
	end
	
	local realm = GetRealm(self)
	realm:SuspendPassEdits("MeteorLargeExplode")
	local objects = single_building and {self} or realm:MapGet(GetExplosionQuery(self, explosion_range))
	local chain_id_counter = 1
	local passages_fractured = {}
	local destroyed_pipes = {}
	local destroyed_cables = {}
	local cablesnpipes_to_kill = {}
	local buildings_hit = {}
	local cablesnpipes = {}
	for _, obj in ipairs(objects) do
		if IsValid(obj) and self:IsCloser(obj, explosion_range) then
			if IsKindOfClasses(obj, "Drone", "BaseRover") then
				if not obj:IsDead() then
					PlayFX("MeteorDestruction", "start", obj)
					obj:SetCommand("Dead", false, true)
				end
			elseif IsKindOf(obj, "Colonist") and kill_colonists then
				PlayFX("MeteorDestruction", "start", obj)
				obj:SetCommand("Die", reason)
			elseif IsKindOf(obj, "UniversalStorageDepot") then
				if not IsKindOf(obj, "RocketBase") and obj:GetStoredAmount("Fuel") > 0 then
					PlayFX("FuelExplosion", "start", obj)
					obj:CheatEmpty()
					AddOnScreenNotification("FuelDestroyed", nil, {}, {obj}, self:GetMapID())
				end
			elseif IsKindOf(obj, "ResourceStockpileBase") then
				local amount = obj:GetStoredAmount()
				if obj.resource == "Fuel" and amount > 0 then
					PlayFX("FuelExplosion", "start", obj)
					obj:AddResourceAmount(-amount, true)
				end
			elseif IsKindOf(obj, "PassageGridElement") then
				if not passages_fractured[obj.passage_obj] then
					obj:AddFracture(position)
					passages_fractured[obj.passage_obj] = true
				end
			elseif IsKindOf(obj, "Building") then
				if not IsKindOfClasses(obj, "Dome", "ConstructionSite", "Passage") then
					local pos, radius = obj:GetPos(), obj:GetRadius() * 150 / 100
					if DestroyBuildingImmediate(obj) then
						PlayFX("MeteorDestruction", "start", obj, nil, pos)
						table.insert(buildings_hit, { pos = pos, radius = radius})
					end
				end
			elseif IsKindOfClasses(obj, "ElectricityGridElement", "LifeSupportGridElement") then
				cablesnpipes[#cablesnpipes + 1] = obj
			end
		end
	end
	
	for i = 1, #cablesnpipes do
		local obj = cablesnpipes[i]
		--destroy if origin in range, break if otherwise
		if self:IsCloser2D(obj, explosion_range) then
			local is_pipe = IsKindOf(obj, "LifeSupportGridElement")
			if is_pipe and g_Consts.InstantPipes == 0 or
				not is_pipe and g_Consts.InstantCables == 0 then --don't destroy if we are just gona place them instantly again
				if not IsKindOf(obj, "ConstructionSite") then
					if not is_pipe and not table.find(destroyed_cables, 4, obj) then
						local t = GatherSupplyGridObjectsToBeDestroyed(obj, destroyed_cables)
						table.iappend(destroyed_cables, t)
					elseif is_pipe and not table.find(destroyed_pipes, 4, obj) then
						local t
						t, chain_id_counter = GatherSupplyGridObjectsToBeDestroyed(obj, destroyed_pipes, chain_id_counter)
						table.iappend(destroyed_pipes, t)
					end
				end
				table.insert(cablesnpipes_to_kill, obj)
			else
				obj:Break()
			end
		else
			obj:Break()
		end
	end
	
	KillCablesAndPipesAndRebuildThem(self.city, cablesnpipes_to_kill, destroyed_cables, destroyed_pipes)
	
	for i = 1, #colonists_to_kill do
		colonists_to_kill[i]:SetCommand("Die", reason)
	end
	
	realm:ResumePassEdits("MeteorLargeExplode")
end

function BuildingTemplate:OnEditorSetProperty(prop_id, old_value)
	ClassTemplatePreset.OnEditorSetProperty(self, prop_id, old_value)
	if prop_id:match("palette%d?_color%d") then
		ReapplyPalettes()
	end
end

----
-- open air building support (avoid having special cases all over the code)

function Building:CalcOpenAirEntity()
end

function Building:CalcOpenAirSkin()
end

function Building:InterruptOpenAirState()
end

function Building:SetWorkshift()
end

----

function Building:SnappedTo(building)
end

function Building:SnappedObjectPlaced(building)
end