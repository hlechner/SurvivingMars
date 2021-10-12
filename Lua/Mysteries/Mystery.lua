DefineClass.MysteryBase = { --data holder for mysteries
	__parents = {"InitDone"},
	mysteries = false,

	scenario_name = false,
	seq_player = false,
	
	display_name = "",
	rollover_text = "",
	challenge_mod = 0,
	
	--mystery resource properties
	resource_display_name = T(8064, "Mystery Resource"), 
	resource_display_icon = "UI/Icons/Buildings/res_mystery_resource.tga",
	resource_tag_icon = "UI/Icons/res_mystery_resource.tga",
	resource_unit_amount = const.ResourceScale, 
	resource_color = RGB(0, 255, 0), 
	resource_entity = "ResourceMystery", 
	resource_description = T(8065, "Mystery Resource Description"),
	
	--display names for mystery storage depots are stored here and they override the building template
	--this is done so multiple misteriese don't have to use hacks to set their own names, as the mystery resource is shared between games
	
	depot_display_name = T(8112, --[[BuildingTemplate StorageMysteryResource display_name]] "Mystery Depot"),
	depot_display_name_pl = T(8112, --[[BuildingTemplate StorageMysteryResource display_name_pl]] "Mystery Depot"),
	depot_description = T(8113, --[[BuildingTemplate StorageMysteryResource description]] "It's very mysterious."),
	mech_depot_display_name = T(8794, "Mystery Storage"),
	mech_depot_display_name_pl = T(8795, "Mystery Storages"),
	mech_depot_description = T(8113, "It's very mysterious."),
	
	order_pos = 0,
	dlc = false,
}

local resource_props_helper = {"resource_display_name", "display_name",
										"resource_display_icon", "display_icon",
										"resource_unit_amount",  "unit_amount",
										"resource_color",        "color",
										"resource_entity",       "entity", 
										"resource_description",  "description", }

function MysteryBase:ApplyMysteryResourceProperties()
	local r_desc = Resources.MysteryResource
	for i = 1, #resource_props_helper, 2 do
		r_desc[resource_props_helper[i + 1]] = self[resource_props_helper[i]]
	end
	
	const.TagLookupTable["icon_MysteryResource"] = string.format("<image %s 1300>", self.resource_tag_icon)
	const.TagLookupTable["icon_MysteryResource_small"] = string.format("<image %s 800>", self.resource_tag_icon)
	
	CalcSingleResGroupEntity(r_desc)
end

function MysteryBase:Init()
	self.mysteries = self.mysteries or UIColony
	self.mysteries:SetMystery(self)
	
	--init mystery resource
	self:ApplyMysteryResourceProperties()
	
	--init sequence player
	if self.scenario_name then
		local seq_list = DataInstances.Scenario[self.scenario_name]
		if not seq_list then
			printf("Mystery %s references missing scenario %s", self.class, self.scenario_name)
			return
		end
		assert(seq_list, "Sequence, " .. self.scenario_name .. " not found!")
		self.seq_player = CreateSequenceListPlayer(seq_list, MainMapID)
		self.seq_player:AutostartSequences()
	else
		print("Mystery, " .. self.class .. ", has no scenario set (sequence action)!")
	end
end
