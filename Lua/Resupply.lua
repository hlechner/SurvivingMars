ResupplyPresets = {
	["Start_low"] = { --low funding starting params
		text = T(3675, "Default starting resources"),
		items = {
			{class = "RCRover",           amount = 1},
			{class = "RCTransport",       amount = 1},
			{class = "Concrete",          amount = 10},
			{class = "Metals",            amount = 10},
			{class = "Polymers",          amount = 5},
			{class = "Electronics",       amount = 5},
			{class = "MachineParts",      amount = 10},
			{class = "OrbitalProbe",      amount = 2,},
			{class = "DroneHub",          amount = 1,},
			{class = "MoistureVaporator", amount = 1,},
		},
	},
	["Start_medium"] = { --medium funding starting params
		text = T(3675, "Default starting resources"),
		items = {
			{class = "RCRover",           amount = 1},
			{class = "RCTransport",       amount = 1},
			{class = "Concrete",          amount = 10},
			{class = "Metals",            amount = 10},
			{class = "Polymers",          amount = 10},
			{class = "Electronics",       amount = 15},
			{class = "MachineParts",      amount = 10},
			{class = "OrbitalProbe",      amount = 2,},
			{class = "DroneHub",          amount = 2,},
			{class = "MoistureVaporator", amount = 1,},
			{class = "FuelFactory",       amount = 1,},
		},
	},
	["Start_high"] = { --high funding starting params
		text = T(3675, "Default starting resources"),
		items = {
			{class = "RCRover",           amount = 1},
			{class = "RCTransport",       amount = 1},
			{class = "Concrete",          amount = 10},
			{class = "Metals",            amount = 10},
			{class = "Polymers",          amount = 20},
			{class = "Electronics",       amount = 20},
			{class = "MachineParts",      amount = 15},
			{class = "OrbitalProbe",      amount = 2,},
			{class = "DroneHub",          amount = 2,},
			{class = "StirlingGenerator", amount = 1,},
			{class = "MoistureVaporator", amount = 1,},
			{class = "FuelFactory",       amount = 1,},
		},
	},
	["Rover"] = {
		text = T(3676, "Rover Start"),
		items = {
			{class = "RCRover",           amount = 1},
		},
	},
	["Materials"] = {
		text = T(3677, "Materials"),
		items = {
			{class = "Concrete",          amount = 30},
			{class = "Metals",            amount = 20},
			{class = "Polymers",          amount = 10},
		},
	},
	["Probe"] = {
		text = T(3678, "Probe"),
		items = {
			{ class = "OrbitalProbe",     amount = 1, },
		},
	},
}

function GetResupplyPresetsCombo()
	local items = {}
	for id, data in pairs(ResupplyPresets) do
		items[#items+1] = {value = id, text = data.text}
	end
	return items
end

function ApplyResupplyPreset(city, preset)
	if not city then return end
	if not ResupplyPresets[preset] then return end
	local preset_items = ResupplyPresets[preset].items	
	city.queued_resupply = table.copy(preset_items, "deep")
end

function GetResupplyClassesCombo()
	local items = {}
	items[#items+1] = {value = "OrbitalProbe", text = g_Classes.OrbitalProbe.display_name}
	items[#items+1] = {value = "AdvancedOrbitalProbe", text = g_Classes.AdvancedOrbitalProbe.display_name}
	for _,res in ipairs(AllResourcesList) do
		items[#items+1] = {value = res, text = GetResourceInfo(res).display_name}
	end

	local buildings = BuildingsCombo()
	table.iappend(items, buildings)
	
	return items
end

DefineClass.SA_ResuppyInventory = {
	__parents = { "SequenceAction" },
	
	properties = {
	},

	Menu = "Gameplay",
	MenuName = "Resupply stuff",
	RestrictToList = "Scenario",
	PropertyTranslation = false,
	MenuSection = "Resupply",
	max_classes = 10,
}

for i=1, SA_ResuppyInventory.max_classes do
	table.insert(SA_ResuppyInventory.properties,{ category = "General", id = "item"..i,   name = "class",  default = "", editor = "dropdownlist",items = GetResupplyClassesCombo,})
	table.insert(SA_ResuppyInventory.properties,{ category = "General", id = "amount"..i, name = "amount", default = 1,  editor = "number" })
end

function SA_ResuppyInventory:Exec(sequence_player, ip, seq, registers)
	local items = {}
	local refreshBM = false
	local city = MainCity
	for i = 1, self.max_classes do
		if self["item"..i] and self["item"..i]~="" then
			local class = self["item"..i]
			local amount = self["amount"..i]
			
			-- place probes directly, add buildings as prefabs
			if IsKindOf(g_Classes[class], "OrbitalProbe") then 
				for j = 1, amount do
					PlaceObjectIn(class, city.map_id)
				end
			else
				refreshBM = true
				city:AddPrefabs(class, amount, false)
			end
		end
	end	
	if refreshBM then
		RefreshXBuildMenu()
	end
end

function SA_ResuppyInventory:ShortDescription()
	local texts = {"Resupply inventory:"}
	for i=1, self.max_classes do
		if self["item"..i] and self["item"..i]~="" then
			texts[#texts + 1] =  string.format("   %s - %d", self["item"..i],self["amount"..i])
		end
	end	
	return table.concat(texts, "\n")
end


DefineClass.SA_ChangeFunding = {
	__parents = { "SequenceAction" },
	
	properties = {
		{category = "General", id = "funding",   name = "Funding",  default = "0", editor = "text"},
		{category = "General", id = "reason",   name = "Reason",  default = "", editor = "combo", items = function() return FundingSourceCombo() end},
	},

	Menu = "Gameplay",
	MenuName = "Change Funding",
	RestrictToList = "Scenario",
	PropertyTranslation = false,
	MenuSection = "Resupply",
	max_classes = 10,
}


function SA_ChangeFunding:Exec(sequence_player, ip, seq, registers)
	local funding = sequence_player:Eval("return " .. self.funding, registers)
	UIColony.funds:ChangeFunding(funding, self.reason)
end

function SA_ChangeFunding:ShortDescription()
	return  string.format("Change Funding: %s", tostring(self.funding))
end
