GlobalVar("ResupplyItemDefinitions", {})

function GetResupplyItem(name)
	assert(#(ResupplyItemDefinitions or "") > 0)
	assert(type(name) == "string")
	return table.find_value(ResupplyItemDefinitions, "id", name)
end

function IsResupplyItemAvailable(name)
	local item = GetResupplyItem(name)
	if item then
		local override_prerequisites = BuildMenuPrerequisiteOverrides[item.id] == true
		local locked = not override_prerequisites and item.locked
		return not locked
	end
	return false
end

function GetResupplyItemPrice(item)
	local price = item.price
	
	local sponsor = GetMissionSponsor()
	if sponsor.WeightCostModifierGroup == item.group then
		price = MulDivRound(price, sponsor.CostModifierPercent, 100)
	end
	
	return price
end

function GetResupplyItemWeight(item)
	local weight = item.kg
	
	local sponsor = GetMissionSponsor()
	if sponsor.WeightCostModifierGroup == item.group then
		weight = MulDivRound(weight, sponsor.WeightModifierPercent, 100)
	end

	if item.group == "Rovers" then
		weight = MulDivRound(weight, g_Consts.RoversWeightModifierPercent, 100)
	elseif item.group == "Basic Resources" then
		weight = MulDivRound(weight, g_Consts.BasicResourcesWeightModifierPercent, 100)
	elseif item.group == "Advanced Resources" then
		weight = MulDivRound(weight, g_Consts.AdvancedResourcesWeightModifierPercent, 100)
	elseif item.group == "Other Resources" then
		weight = MulDivRound(weight, g_Consts.OtherResourcesWeightModifierPercent, 100)
	end
	
	return weight
end

local function ModifyResupplyDef(def, param, percent)
	local orig_def = def and CargoPreset[def.id]
	if not orig_def then
		-- asserts only if all dlcs are available and cannot find the cargo preset
		-- otherwise the preset may be in disabled dlc and return is enough
		if Platform.developer then
			assert(DbgAreDlcsMissing(), "No such cargo preset " .. tostring(def and def.id))
		else
			print("No such cargo preset " .. tostring(def and def.id))
		end
		return
	end
	if param == "price" then
		def.mod_price = (def.mod_price or 100) + percent
		def.price = MulDivRound(orig_def.price, def.mod_price, 100)
	elseif param == "weight" then
		def.mod_weight = (def.mod_weight or 100) + percent
		def.kg = MulDivRound(orig_def.kg, def.mod_weight, 100)
	else
		assert(false, "unexpected resupply parameter received for modification: " .. tostring(param))
	end
end

--[[@@@
Change price or weight of resupply item. If called multiple times, first sums percents.
@function void Gameplay@ModifyResupplyParam(string id, string param, int percent)	
@param string id - resupply item identifier.Can be
		"RCRover","ExplorerRover","RCTransport", "Drone", "Concrete", "Metals", "Food", "Polymers", "MachineParts", "Electronics" "DroneHub","MoistureVaporator","FuelFactory", "StirlingGenerator", "MachinePartsFactory","ElectronicsFactory",  "PolymerPlant","OrbitalProbe","ShuttleHub", "MetalsExtractor",  "RegolithExtractor", "WaterExtractor", "PreciousMetalsExtractor","Apartments", "LivingQuarters", "SmartHome", "Arcology",  "HangingGardens","WaterReclamationSystem", "CloningVats","NetworkNode", "MedicalCenter",  "Sanatorium",
@param string param  - type of change: "price", "weight" 
@param int percent - percent to change with.
--]]
function ModifyResupplyParam(id, param, percent)
	local def = GetResupplyItem(id)
	return def and ModifyResupplyDef(def, param, percent)
end

--[[@@@
Change price or weight of all resupply items.
@function void Gameplay@ModifyResupplyParams(string param, int percent)	
@param string param  - type of change: "price", "weight" 
@param int percent - percent to change with.
--]]
function ModifyResupplyParams(param, percent)
	for _, def in ipairs(ResupplyItemDefinitions) do
		ModifyResupplyDef(def, param, percent)
	end
end

function UpdateResupplyDef(sponsor, mods, locks, def)
	local mod = mods[def.id] or 0
	if mod ~= 0 then
		ModifyResupplyDef(def, "price", mod)
	end
	local lock = locks[def.id]
	if lock ~= nil then
		def.locked = lock
	end
	if type(def.verifier) == "function" then 
		def.locked = def.locked or not def.verifier(def, sponsor)
	end
end

function ResupplyItemsInit(ignore_existing_defs)
	local sponsor = g_CurrentMissionParams and g_CurrentMissionParams.idMissionSponsor or ""
	local mods = GetSponsorModifiers(sponsor)
	local locks = GetSponsorLocks(sponsor)
	local defs = {}
	ForEachPreset("Cargo", function(item, group, self, props)
		local def = setmetatable({}, {__index = item})
		if ignore_existing_defs then
			local resupply_item = GetResupplyItem(def.id)
			if not resupply_item then
				defs[#defs + 1] = def
				UpdateResupplyDef(sponsor, mods, locks, def)
			else
				table.insert(defs, resupply_item)
			end
		else
			defs[#defs + 1] = def
			UpdateResupplyDef(sponsor, mods, locks, def)
		end
	end)
	if _G["Cargo"].HasSortKey then
		table.sort(defs, PresetSortLessCb)
	end
	ResupplyItemDefinitions = defs
end

function RocketPayload_Init(ignore_existing_defs) -- deprecated
	ResupplyItemsInit(ignore_existing_defs)
end

function OnMsg.PostNewGame()
	--when a new game is loaded, ResupplyItemDefinitions gets initialized with default values
	--so we need to apply the sponsor modifiers once again
	ResupplyItemsInit()
end

function SavegameFixups.ResupplyItemDefinitions2()
	local sponsor = g_CurrentMissionParams and g_CurrentMissionParams.idMissionSponsor or ""
	local mods = GetSponsorModifiers(sponsor)
	local locks = GetSponsorLocks(sponsor)
	local idx = 0
	ForEachPreset("Cargo", function(item, group, self, props)
		local find = table.find(ResupplyItemDefinitions, "id", item.id)
		if not find then
			local def = setmetatable({}, {__index = item})
			local mod = mods[def.id] or 0
			if mod ~= 0 then
				ModifyResupplyDef(def, "price", mod)
			end
			local lock = locks[def.id]
			if lock ~= nil then
				def.locked = lock
			end
			if type(def.verifier) == "function" then 
				def.locked = def.locked or not def.verifier(def, sponsor)
			end
			idx =  idx +1
			table.insert(ResupplyItemDefinitions, idx, def)
		end
	end)

	table.sort(ResupplyItemDefinitions, PresetSortLessCb)
end

function SavegameFixups.CorrectOrderingOfResources()
	if _G["Cargo"].HasSortKey then
		table.sort(ResupplyItemDefinitions, PresetSortLessCb)
	end
end

function SavegameFixups.FixResupplyDefinitions()
	local entries_to_remove = {}
	for k, item in ipairs(ResupplyItemDefinitions) do
		if item.id == "MissingPreset" then
			entries_to_remove[#entries_to_remove + 1] = item
		end
	end
	
	for _, item in ipairs(entries_to_remove) do
		table.remove_entry(ResupplyItemDefinitions, item)
	end
end
