function HasParadoxSponsor()
	if Platform.developer or AccountStorage.has_paradox_sponsor then
		return true
	else
		return false, "paradox sponsor"
	end
end

MissionParams = {
	idMissionSponsor = {
		display_name = T(3474, "Mission Sponsor"),
		display_name_caps = T(3475, "MISSION SPONSOR"),
		descr = T(3476, "The patron country or organization standing behind the Mars mission. Grants funding, research and other benefits to colony."),
		gamepad_hint = T(3477, "<ButtonA> Choose Sponsor"),
		SortKey = 10000,
		empty_on_start = true,
	},
	idCommanderProfile = {
		display_name = T(3478, "Commander Profile"),
		display_name_caps = T(3479, "COMMANDER PROFILE"),
		descr = T(3480, "The mission commander grants various benefits to the colony."),
		gamepad_hint = T(3481, "<ButtonA> Choose Commander"),
		SortKey = 20000,
		empty_on_start = true,
	},

	idMissionLogo = {
		display_name = T(3482, "Colony Logo"),
		display_name_caps = T(3483, "COLONY LOGO"),
		descr = T(3484, "This is an aesthetic choice that has no effect on gameplay."),
		gamepad_hint = T(3485, "<ButtonA> Choose Logo"),
		SortKey = 30000,
	},
	
	idMystery = {
		display_name = T(3486, "Mystery"),
		display_name_caps = T(3487, "MYSTERY"),
		descr = T(3488, "Select an active storyline for this playthrough."),
		gamepad_hint = T(3489, "<ButtonA> Choose Mystery"),
		items = {
			{id = "random", display_name = T(3490, "Random"), rollover_text = T(7904, "Chooses a random mystery, preferably one you have not played yet.")},
			{id = "none", display_name = T(6839, "None")},
		},
		SortKey = 40000,
	},
	
	idGameRules = {
		display_name = T(8800, "Game Rules"),
		display_name_caps = T(8801, "GAME RULES"),
		descr = T(8804, "Select game rules you want to activate for this playthrough."), 
		gamepad_hint = T(8903, "<ButtonA> Choose Game Rules"),
		SortKey = 50000,
		empty_on_start = true,
	},
}

function GetSortedMissionParamsKeys()
	local keys = table.keys(MissionParams)
	table.sort(keys, function(a,b)
		return (MissionParams[a].SortKey or 0) < (MissionParams[b].SortKey or 0)
	end)
	return keys
end

function ReloadMissionSponsors()
	local sponsors = Presets.MissionSponsorPreset and Presets.MissionSponsorPreset.Default
	if sponsors then
		MissionParams.idMissionSponsor.items = {}
		ForEachPreset("MissionSponsorPreset", function(preset, group, items) items[#items + 1] = preset end, MissionParams.idMissionSponsor.items)
	end
end

function ReloadCommanderProfiles()
	local commanders = Presets.CommanderProfilePreset and Presets.CommanderProfilePreset.Default
	if commanders then
		MissionParams.idCommanderProfile.items = {}
		ForEachPreset("CommanderProfilePreset", function(preset, group, items) items[#items + 1] = preset end, MissionParams.idCommanderProfile.items)
	end
end

const.TagLookupTable["sponsor_name"] = function() return GetMissionSponsor().display_name end
const.TagLookupTable["commander_name"] = function() return GetCommanderProfile().display_name end

function ReloadMissionParams(override)
	if not override and not DataLoaded then
		return -- wait for data loaded event.
	end
	ReloadMissionSponsors()
	ReloadCommanderProfiles()
	ReloadGameRules()
	ReloadMissionLogos()
end

OnMsg.DataLoaded = function() ReloadMissionParams(true) end
OnMsg.ModsReloaded = function() ReloadMissionParams(true) end
OnMsg.Autorun = function() ReloadMissionParams() end --intentionally a function, can be overriden in DLC

local modifier_list_for_sponsor
local modifier_list = {}
function GetSponsorModifiers(sponsor)
	if modifier_list_for_sponsor ~= sponsor then
		modifier_list_for_sponsor = sponsor
		sponsor = GetMissionSponsor(sponsor)
		modifier_list = {}
		for i=1,const.MissionSponsorPriceModifiers do
			local name = sponsor:GetProperty("modifier_name" .. i) or ""
			if name and name ~= "" then
				modifier_list[name] = sponsor:GetProperty("modifier_value" .. i)
			end
		end
	end
	return modifier_list
end

local lock_list_for_sponsor
local lock_list = {}
function GetSponsorLocks(sponsor)
	if lock_list_for_sponsor ~= sponsor then
		lock_list_for_sponsor = sponsor
		sponsor = GetMissionSponsor(sponsor)
		lock_list = {}
		for i=1,const.MissionSponsorLockModifiers do
			local name = sponsor:GetProperty("lock_name" .. i) or ""
			if name and name ~= "" then
				local lock = sponsor:GetProperty("lock_value" .. i)
				if lock == "locked" then
					lock_list[name] = true
				elseif lock == "unlocked" then
					lock_list[name] = false
				end
			end
		end
	end
	return lock_list
end

local nations_list_for_sponsor
local nations_list = {}
function GetSponsorNations(sponsor)
	if nations_list_for_sponsor ~= sponsor then
		nations_list_for_sponsor = sponsor
		sponsor = GetMissionSponsor(sponsor)
		nations_list = {}
		for i=1,const.MissionSponsorNations do
			local nation_name = sponsor:GetProperty("sponsor_nation_name" .. i) or ""
			if nation_name ~= "" then
				nations_list[#nations_list + 1] = {nation_name, sponsor:GetProperty("sponsor_nation_percent" .. i)}
			end
		end
	end
	return nations_list
end

function OnMsg.ClassesBuilt()
	CreateRealTimeThread(function()
		WaitInitialDlcLoad()
		-- add mysteries
		local items = MissionParams.idMystery.items
		local all_mysteries = ClassDescendantsList("MysteryBase")
		local function mystery_order(name)
			local class = g_Classes[name]
			return class.order_pos
		end
		all_mysteries = table.sortby(all_mysteries, mystery_order)
		for i = 1, #all_mysteries do
			local mystery_id = all_mysteries[i]
			local class = g_Classes[mystery_id]
			if (Platform.developer or IsDlcAccessible(class.dlc)) and not table.find(items, "id", mystery_id) then
				items[#items + 1] = {
					id = mystery_id,
					display_name = class.display_name,
					challenge_mod = class.challenge_mod,
					rollover_text = class.rollover_text
				}
			end
		end
	end)
end

function OnMsg.ChangeMap(map)
	g_CurrentMissionParams.idMissionSponsor = g_Tutorial and "None" or g_CurrentMissionParams.idMissionSponsor or "IMM"
	g_CurrentMissionParams.idCommanderProfile = g_Tutorial and "None" or g_CurrentMissionParams.idCommanderProfile or "rocketscientist"
	g_CurrentMissionParams.idGameRules = g_Tutorial and {} or g_CurrentMissionParams.idGameRules or {}
	g_CurrentMissionParams.GameMode = g_Tutorial and "tutorial" or g_CurrentMissionParams.GameMode or "unknown"
end

function InitNewGameMissionParams()
	g_CurrentMissionParams = {}
	-- reset ramdom settings for sponsor and 
	random_mission_params = {
		idMissionSponsor = false,
		idCommanderProfile = false,
	}
	for k, v in pairs(MissionParams) do
		if not MissionParams[k].empty_on_start then
			local items = v.items or empty_table
			for i=1,#items do
				local item = items[i]
				if item.filter == nil or item.filter == true or (type(item.filter) == "function" and item:filter()) then
					g_CurrentMissionParams[k] = item.id
					break
				end
			end
		end
	end
	g_CurrentMapParams = {}
	g_SessionSeed = AsyncRand()
	ResetCargo()
end

function OnMsg.DataLoaded()
	InitNewGameMissionParams()
end

if FirstLoad then
	g_CurrentMissionParams = false
	g_CurrentMapParams = false	
	g_SessionSeed = false
end

function OnMsg.PersistSave(data)
	-- note: not GlobalVars, as they have to persist between PreGame and in-game, and GlobalVars would be reset
	data.g_CurrentMissionParams = g_CurrentMissionParams
	data.g_CurrentMapParams = g_CurrentMapParams
end

function OnMsg.PersistLoad(data)
	g_CurrentMissionParams = data.g_CurrentMissionParams
	g_CurrentMapParams = data.g_CurrentMapParams
end

local function accumulate_ranges(total, addend)
	if not addend then
		return
	end
	
	for key,rng in pairs(addend) do
		if not total[key] then
			--copy, just in case
			total[key] = range(rng.from, rng.to)
		else
			--increment
			local entry = total[key]
			entry.from = entry.from + rng.from
			entry.to = entry.to + rng.to
		end
	end
end

function GetDefaultMissionSponsor()
	return setmetatable({}, {__index = MissionSponsorPreset}) -- savegame compatibility
end

function GetMissionSponsor(name)
	name = name or g_CurrentMissionParams.idMissionSponsor
	local presets = Presets.MissionSponsorPreset
	local sponsor = name and presets and presets.Default[name] or GetDefaultMissionSponsor()
	if not rawget(sponsor, "name") then
		rawset(sponsor, "name", sponsor.id) --backward compatibility for mods
	end
	return sponsor
end

function GetDefaultCommanderProfile()
	return setmetatable({}, {__index = CommanderProfilePreset}) -- savegame compatibility
end

function GetCommanderProfile(name)
	name = name or g_CurrentMissionParams.idCommanderProfile
	local presets = Presets.CommanderProfilePreset
	local commander = name and presets and presets.Default[name] or GetDefaultCommanderProfile()
	if not rawget(commander, "name") then
		rawset(commander, "name", commander.id) --backward compatibility for mods
	end
	return commander
end

--When generating a new map anomalies are placed depending on some chance
--This function tells us what probability increase we get from our mission settings
function GetMissionAnomalyBonus()
	local sponsor = GetMissionSponsor()
	local profile = GetCommanderProfile()
	
	local sponsor_bonus = 
	{
		Breakthrough = sponsor.anomaly_bonus_breakthrough,
		Event = sponsor.anomaly_bonus_event,
		FreeTech = sponsor.anomaly_bonus_free_tech
	}
	local profile_bonus = 
	{
		Breakthrough = profile.anomaly_bonus_breakthrough,
		Event = profile.anomaly_bonus_event,
		FreeTech = profile.anomaly_bonus_free_tech
	}
	
	local total_bonuses = {}
	accumulate_ranges(total_bonuses, sponsor_bonus)
	accumulate_ranges(total_bonuses, profile_bonus)
	
	return total_bonuses
end

--In the pregame menu the mission sponsor dictates what items
--will be initially loaded on the rocket - this function gives that preset
function GetMissionInitialLoadout(pregame)
	local preset = GetMissionSponsor()
	if not preset then
		return false
	end
	local items = {}
	for _, def in ipairs(ResupplyItemDefinitions) do
		local amount = not def.locked and pregame and rawget(preset, def.id) or 0
		items[#items + 1] = { class = def.id, amount = amount }
	end
	return items
end

-------------------------------------------

function ResolveDisplayName(id)
	local res = GetResourceInfo(id)
	if res then
		return res.display_name, res.description
	end
	local template = BuildingTemplates[id]
	if template then
		return template.display_name, template.description
	end
	local def = g_Classes[id]
	if def and def:HasMember("display_name") and def.display_name and def.display_name ~= "" then
		return def.display_name, def.description
	end
	local article
	ForEachPreset(EncyclopediaArticle, function(preset, group_list)
		if preset.title_id == id then
			article = preset
		end
	end)
	if article then
		return article.title_text, article.text
	end
	return Untranslated(id), ""
end

function ResupplyItemsCombo()
	local items = {}
	for group_i, group_items in ipairs(Presets.Cargo or empty_table) do
		for _, item in ipairs(group_items) do
			items[#items + 1] = { value = item.id, text = item.name }
		end
	end
	TSort(items, "text")
	table.insert(items, 1, "")
	return items
end

function LockStatusCombo()
	return {
		{ value = false, text = "" },
		{ value = "locked",   text = T(8056, "Locked") },
		{ value = "unlocked", text = T(8690, "Unlocked") },
	}
end

modifiableConsts = {
	{local_id = "additional_research_points", global_id = "SponsorResearch"},
	{local_id = "additional_colonists_per_rocket", global_id = "MaxColonistsPerRocket"},
	{local_id = "additional_initial_applicants", global_id = "ApplicantsPoolStartingSize"}
}

directlyModifiableConsts = {
	{local_id = "precious_metals_export_price", global_id = "ExportPricePreciousMetals"},
	{local_id = "research_points", global_id = "SponsorResearch"},
	{local_id = "initial_applicants", global_id = "ApplicantsPoolStartingSize"},
	{local_id = "funding_per_interval", global_id = "SponsorFundingPerInterval"},
	{local_id = "rocket_price", global_id = "RocketPrice"},
}

function SavegameFixups.ModifiableRocketPrice()
	g_Consts:SetBase("RocketPrice", GetMissionSponsor().rocket_price)
end

function DirectlyModifiedConstValue(label, base_value)
	local sponsor = GetMissionSponsor()
	if sponsor then
		for _, const_pair in pairs(directlyModifiableConsts) do
			if const_pair.global_id == label and sponsor[const_pair.local_id] ~= base_value then
				return sponsor[const_pair.local_id]
			end
		end
	end
	return false
end

if FirstLoad then
	SponsorModifiedGlobalConsts = {}
end

function ReloadSponsorModifiedGlobalConsts()
	SponsorModifiedGlobalConsts = {}
	for _, sponsor in ipairs(Presets.MissionSponsorPreset.Default) do
		for i = 1,#sponsor do
			local modifier = sponsor[i]
			if ObjectClass(modifier) == "Effect_ModifyLabel" and
				modifier.Label == "Consts" then
				SponsorModifiedGlobalConsts[modifier.Prop] = true
			end
		end
	end
end

OnMsg.DataLoaded = ReloadSponsorModifiedGlobalConsts

function GetModifiedConsts(sponsor, commander)
	local t = {}
		
	for k,v in pairs(SponsorModifiedGlobalConsts) do
		t[k] = g_Consts[k]
	end
	
	for i = 1,#sponsor do
		local mod = sponsor[i]
		if ObjectClass(mod) == "Effect_ModifyLabel" and
			mod.Label == "Consts" then
			t[mod.Prop] = MulDivRound(g_Consts[mod.Prop], 100 + mod.Percent, 100) + mod.Amount
		end
	end
	
	for _, const in ipairs(directlyModifiableConsts) do
		local value_id = const.local_id
		local global_name = const.global_id
		if sponsor[value_id] and sponsor[value_id] >= 0 then 
			t[global_name] = sponsor[value_id]			
		end
		t[global_name] = t[global_name] or g_Consts[global_name]
	end 
	
	if commander then
		for _, const in ipairs(modifiableConsts) do
			local value_id = const.local_id
			local global_name = const.global_id
			if commander[value_id] and commander[value_id] ~= 0 then 
				t[global_name] = MulDivRound(t[global_name] or g_Consts[global_name], 100, 100) + commander[value_id]			
			end
			t[global_name] = t[global_name] or g_Consts[global_name]
		end 
	end
	
	return t
end

function GetSponsorModifiedFunding(funding, commander)
	funding = funding or GetMissionSponsor().funding
	commander = commander or GetCommanderProfile()
	for _, effect in ipairs(commander or empty_table) do
		if IsKindOf(effect, "Effect_Funding") then
			funding = funding + effect.Funding
		end
	end
	if IsGameRuleActive("RichCoffers") then
		-- Start with $100,000 M funding
		funding = funding + 100*1000
	end
	return funding
end

function GetSponsorDescr(sponsor, include_flavor, include_rockets, include_commander, include_sponsor)
	--combining descr and sponsor to create context to resolve tags from sponsor.effect
	local commander_profile = GetCommanderProfile()
	local context = GetModifiedConsts(sponsor, include_commander and commander_profile)
	for _, prop in ipairs(sponsor:GetProperties()) do
		context[prop.id] = sponsor:GetProperty(prop.id)
	end
	context.challenge_rating = sponsor.challenge_mod and Untranslated(string.format("%3.2f", (sponsor.challenge_mod + 100)/100.0))
	
	if include_commander then
		context.funding = GetSponsorModifiedFunding(context.funding, commander_profile)
	end
	if IsGameRuleActive("MoreApplicants") then
		context.ApplicantsPoolStartingSize = context.ApplicantsPoolStartingSize + 500
	end
	if IsGameRuleActive("MoreTourists") then
		context.ApplicantsPoolStartingSize = context.ApplicantsPoolStartingSize + 20
	end
	if IsGameRuleActive("EasyResearch") then
		context.SponsorResearch = context.SponsorResearch + 3000
	end
	local additional_rockets = commander_profile.bonus_rockets and commander_profile.bonus_rockets or 0
	context.initial_rockets = context.initial_rockets + additional_rockets
	local txtsponsor = include_sponsor and T(10521, "<em>Mission Sponsor:</em>")..Untranslated("\n") or ""
	local start = T{10061, "Difficulty: <em><difficulty></em><newline>Funding: $<funding> M<newline>", context}
	local rockets = include_rockets and T{10062, "Starting Rockets: <initial_rockets><newline>", context} or ""
	local applicants = T{10063, "Starting Applicants: <applicants><newline><newline>", applicants = context.ApplicantsPoolStartingSize, context}
	local effect = sponsor.effect and T{sponsor.effect, context} or ""
	local flavor = include_flavor and sponsor.flavor and T{10064, "<em><flavor></em>", context} or ""
	return txtsponsor..start..rockets..applicants..effect..flavor
end

-------------------------------------------
function GetSponsorEntryRollover(param_t)
	if not param_t.effect or param_t.effect == "" then return end
	return {
		id = param_t.display_name,
		title = param_t.display_name,
		descr = GetSponsorDescr(param_t, "include flavor", false),
		gamepad_hint = T(3545, "<ButtonA> Select"),
	}
end

function GetEntryRollover(param_t)
	if (not param_t.effect or param_t.effect == "") and not rawget(param_t, "rollover_text") and not rawget(param_t, "description") then return end
	local rollover = {title = param_t.display_name}
	local descr = rawget(param_t, "rollover_text") or rawget(param_t, "description") or param_t.effect or ""
	local flavor = rawget(param_t, "flavor")
	if flavor and flavor ~= "" then
		descr = table.concat({descr, flavor},"\n\n")
	end
	if IsKindOf(param_t, "GameRules") then
		descr = descr .. GetGameRuleIncompatibleText(param_t.id)
	end
	rollover.descr = descr
	rollover.id = rollover.title
	rollover.gamepad_hint = T(3545, "<ButtonA> Select")
	return rollover
end

if FirstLoad then
	random_mission_params = {
		idMissionSponsor = false,
		idCommanderProfile = false,
	}
end

function GetDescrEffects()
	local lines = {}
	local rules = g_CurrentMissionParams.idGameRules or empty_table
	if next(rules) then
		lines[#lines + 1] = T(10523, "<em>Game Rules:</em>")
		ForEachPreset("GameRules", function(preset, group, lines, rules)
			if rules[preset.id] then
				lines[#lines + 1] = T{10106, "- <em><display_name></em> - <description>", preset}
			end
		end, lines, rules)
		lines[#lines + 1] = ""
	end
	local keys = GetSortedMissionParamsKeys()
	for i, id in ipairs(keys) do
		if not random_mission_params[id] then
			local entry = table.find_value(MissionParams[id].items, "id", g_CurrentMissionParams[id])
			local effect = entry and entry.effect or ""
			if IsKindOf(entry, "MissionSponsorPreset") then
				lines[#lines + 1] = GetSponsorDescr(entry, false, "include rockets", true, true)
			elseif effect ~= "" then
				if id == "idCommanderProfile" then 				
					lines[#lines + 1] = T(10522, "<em>Commander Profile:</em>")
				end	
				lines[#lines + 1] = T{ effect, entry }
			end
		end
	end
	if #lines<=0 then 
		return TLookupTag("<white>") .. T(3490, "Random") .. TLookupTag("</white>")
	end
	return table.concat(lines, "<newline>")
end

function GetMapChallengeRating()
	if not g_CurrentMapParams.seed then
		return 0
	end
	local gen = GetRandomMapGenerator()
	local blank_map = FillRandomMapProps(gen)
	local map_data = MapDataPresets[blank_map]
	return map_data and map_data.challenge_rating or 0
end

function CalcChallengeRating(replace_param, replacement_id, map_challenge_rating)
	local sponsor_mod = 0
	local rating = 0
	local function UpdateRatingForParam(param_id, item_id)
		if not MissionParams[param_id] then
			return
		end
		local search_table = MissionParams[param_id].items
		local idx = table.find(search_table, "id", item_id)
		local mod
		if param_id == "idGameRules" then
			mod = CalcGameRulesChallengeMod(item_id)
		else
			mod = idx and search_table[idx].challenge_mod or 0
		end
		if param_id == "idMissionSponsor" then
			sponsor_mod = mod
		else
			rating = rating + mod
		end
	end
	local params = g_CurrentMissionParams
	for param_id, item_id in pairs(params) do
		if replacement_id and param_id == replace_param then
			item_id = replacement_id
		end
		UpdateRatingForParam(param_id, item_id)
	end
	if replacement_id and not params[replace_param] then
		UpdateRatingForParam(replace_param, replacement_id)
	end
	if params.SelectedSpotChallengeMods then
		for k, v in pairs(params.SelectedSpotChallengeMods) do
			rating = rating + v
		end
	end
	rating = rating + (map_challenge_rating or GetMapChallengeRating())
	rating = rating + sponsor_mod
	return Max(0, rating)
end

function GenerateRandomMissionParams()
	InitNewGameMissionParams()
	for k, v in pairs(MissionParams) do
		if k ~= "idMissionSponsor" and k ~= "idCommanderProfile" and k ~= "idMystery" and k ~= "idGameRules" then
			g_CurrentMissionParams[k] = GetRandomMissionParam(k)
		end
	end
	g_CurrentMissionParams.idMissionSponsor = g_Tutorial and "None" or "IMM"
	g_CurrentMissionParams.idCommanderProfile = g_Tutorial and "None" or "rocketscientist"
	g_CurrentMissionParams.idMystery = "random"
	g_CurrentMissionParams.idGameRules = {}
	g_CurrentMissionParams.GameMode = "unknown"
	g_CurrentMissionParams.GameSessionID = srp.random_encode64(96)
	GenerateRocketCargo()
end

function GenerateRocketCargo()
	ResupplyItemsInit()
	g_RocketCargo = GetMissionInitialLoadout("on_start")
	RocketPayload_CalcCargoWeightCost()
end

function GetRandomMissionParam(param)
	local filtered = {}
	local items = MissionParams[param].items
	for i=1,#items do
		local item = items[i]
		local id = item.id
		if id ~= "random" and id ~= "none" and (item.filter == nil or item.filter == true or (type(item.filter) == "function" and item:filter())) then
			filtered[#filtered + 1] = item
		end
	end
	local chosen = filtered[1 + AsyncRand(#filtered)]
	return chosen.id
end

function GenerateRandomMapParams()
	local lat, long
	if Presets.LandingSpot.Default then
		local items = {}
		for _, item in ipairs(Presets.LandingSpot.Default) do
			if item.quickstart then
				items[#items + 1] = item
			end
		end
		local spot = items[1 + AsyncRand(#items)]
		lat, long = spot.latitude * 60, spot.longitude * 60
	else
		lat, long = GenerateRandomLandingLocation()
	end
	GetOverlayValues(lat, long)
	g_CurrentMapParams.rocket_name, g_CurrentMapParams.rocket_name_base = GenerateRocketName(true)
end

function ShowStartGamePopup()	
	if g_CurrentMissionParams.challenge_id then
		local challenge = Presets.Challenge.Default[g_CurrentMissionParams.challenge_id]
		WaitPopupNotification("Challenge_Welcome", { 
			challenge_name = challenge.title,
			params = {
				challenge_objective = challenge.description,
				challenge_deadline = challenge.time_completed / const.DayDuration,
				perfect_deadline = challenge.time_perfected  / const.DayDuration,
			},
		})
	else
		local sponsor   = GetMissionSponsor()
		local commander = GetCommanderProfile()
		WaitPopupNotification("WelcomeGameInfo",
		{ params = { sponsor_name = sponsor.display_name or "", 
						commander_name = commander.display_name , 
						}
		})
	end
end

function SponsorCombo()
	return function()
		local result = {}
		for i = 1, #MissionParams.idMissionSponsor.items do
			result[i] = MissionParams.idMissionSponsor.items[i].id
		end
		return result
	end
end

function WaitWarnTutorialWithMods(host)
	if AccountStorage and AccountStorage.LoadMods and next(AccountStorage.LoadMods) ~= nil then
		local choice = WaitPopupNotification("Tutorial_ActiveMods", nil, nil, host)
		if choice == 1 then
			LoadingScreenOpen("idLoadingScreen", "AllModsOff")
			AllModsOff()
			SaveAccountStorage(5000)
			WaitDisableAllPDXMods()
			g_ParadoxModsContextObj = false
			if ModsLoaded then
				ModsReloadItems()
			end
			LoadingScreenClose("idLoadingScreen", "AllModsOff")
		end
	end
end

function ChooseToPlayTutorial(host)
	if config.DisableTutorialPopup then
		return false
	end
	if (AccountStorage.CompletedTutorials and next(AccountStorage.CompletedTutorials)) or AccountStorage.DisablePlayTutorialPopup then
		return false
	end	
	local choice = WaitPopupNotification("Tutorial_FirstTimePlayers", nil, nil, host)		
	AccountStorage.CompletedTutorials = {}
	SaveAccountStorage(5000)
	if choice == 1 then
		WaitWarnTutorialWithMods(host)
		host:SetMode("Tutorial")
		return true
	end
	return false
end 

function StartNewGame(host, mode, session_mode, rules)
	CreateRealTimeThread(function()
		if ChooseToPlayTutorial(host) then
			return
		end	
		
		InitNewGameMissionParams()
		g_CurrentMissionParams.idGameRules = rules or {}
		g_CurrentMissionParams.GameMode = session_mode or "unknown"
		
		LoadingScreenOpen("idLoadingScreen", "pre_game")
		if host.window_state ~= "destroying" then
			host:SetMode("Empty")
		end
		ChangeMap("PreGame")
		if host.window_state ~= "destroying" then
			host:SetMode(mode or "Mission")
		end
		LoadingScreenClose("idLoadingScreen", "pre_game")
	end)
end
