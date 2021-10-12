if FirstLoad then
	g_TitleObj = false
	g_ColonyNameObj = false
	g_RenameRocketObj = false
	g_UIAvailableRockets = 0
	g_UITotalRockets = 0
end

DefineClass.PGColonyNameObject = {
	__parents = { "PropertyObject" },
	display_name = "Our Colony",
}

function PGColonyNameObject:InitColonyName()
	if not g_CurrentMapParams.colony_name then
		g_CurrentMapParams.colony_name = _InternalTranslate(T(13789, "Our Colony"))
	end
	self.display_name = g_CurrentMapParams.colony_name
end

function PGColonyNameObject:GetColonyHyperlink()
	local base = T{13790, "<h RenameColony Rename>< image <img> 2000 > ", img = Untranslated("UI/Common/pm_rename.tga")}
	return T{11250, "<base><name><end_link>", base = base, name = Untranslated(self.display_name), end_link = T(4162, "</h>")}
end

function PGColonyNameObject:SetColonyName(name)
	self.display_name = name
	ObjModified(self)
	
	g_CurrentMapParams.colony_name = name
	if MarsScreenLandingSpots then
		MarsScreenLandingSpots.OurColony.display_name = Untranslated(name)
		ObjModified(MarsScreenLandingSpots.OurColony)
		ObjModified(MarsScreenLandingSpots)
		ObjModified(SortedMarsScreenLandingSpots)
	end
	ObjModified(self)
end

function PGColonyNameObject:GetColonyName()
	local name = self:GetColonyHyperlink()
	return T{4065, "<style LandingPosName><name></style><newline>", name = name}
end

function PGColonyNameObject:RenameColony(host, callback)
	CreateMarsRenameControl(host, T(4069, "Rename"), self.display_name, 
		function(name)
			self:SetColonyName(name)
			if callback then
				callback(name)
			end
		end, 
		nil, self, {max_len = 23, console_show = Platform.steam and GetUIStyleGamepad()})
end

DefineClass.PGTitleObject = {
	__parents = { "PropertyObject" },
	replace_param = false,
	replace_value = false,
	map_challenge_rating = false,
}

function PGTitleObject:GetTitleText()
	local dlg = GetPreGameMainMenu()
	if dlg and dlg.Mode == "Challenge" then
		local mode = dlg.idContent.PGChallenge.Mode
		if mode == "landing" then
			return T(10880, "CHALLENGES") .. Untranslated("<newline>") .. T{10881, "<white>Completed <CompletedChallenges>/<TotalChallenges></white>", self}
		elseif mode == "payload" then
			return T(4159, "PAYLOAD")
		else
			return ""
		end
	end
	if dlg and dlg.Mode == "Mission" then
		local mode = dlg.idContent.PGMission and dlg.idContent.PGMission.Mode or false
		if mode == "sponsor" then
			return T(10892, "MISSION PARAMETERS") .. Untranslated("<newline>") .. T{10893, "<white>Difficulty Challenge <percent(DifficultyBonus)></white>", self}
		elseif mode == "payload" then
			return T(4159, "PAYLOAD") .. Untranslated("<newline>") .. T{10893, "<white>Difficulty Challenge <percent(DifficultyBonus)></white>", self}
		elseif mode == "landing" then
			return T(10894, "COLONY SITE") .. Untranslated("<newline>") .. T{10893, "<white>Difficulty Challenge <percent(DifficultyBonus)></white>", self}
		else
			return ""
		end
	end
	
	local dlg = GetDialog("Resupply")
	if dlg then
		return T(4159, "PAYLOAD") .. Untranslated("<newline>") .. T{10893, "<white>Difficulty Challenge <percent(DifficultyBonus)></white>", self}
	end
	return ""
end

function PGTitleObject:GetDifficultyBonus()
	return 100 + CalcChallengeRating(self.replace_param, self.replace_value, self.map_challenge_rating)
end

function PGTitleObject:GetCompletedChallenges()
	return GetCompletedChallenges()
end

function PGTitleObject:GetTotalChallenges()
	return GetTotalChallenges()
end

function PGTitleObject:RecalcMapChallengeRating()
	self.map_challenge_rating = GetMapChallengeRating()
end

function PGTitleObjectCreate()
	g_TitleObj = PGTitleObject:new()
	return g_TitleObj
end

function PGColonyNameObjectCreate()
	g_ColonyNameObj = PGColonyNameObject:new()
	g_ColonyNameObj:InitColonyName()
	return g_ColonyNameObj
end

function GetCompletedChallenges()
	local n = 0
	ForEachPreset("Challenge", function(preset) 
		if preset.id ~= "" and AccountStorage.CompletedChallenges and AccountStorage.CompletedChallenges[preset.id] then
			n = n + 1
		end
	end)
	return n
end

function GetTotalChallenges()
	local n = 0
	ForEachPreset("Challenge", function(preset) 
		if preset.id ~= "" then
			n = n + 1
		end
	end)
	return n
end

local function MissionParamCombo(id)
	local items = {}
	for k,v in ipairs(MissionParams[id].items) do
		if v.filter == nil or v.filter == true or (type(v.filter) == "function" and v:filter()) then
			local rollover
			if id == "idMissionSponsor" then
				rollover = GetSponsorEntryRollover(v)
				if rollover and rollover.descr and rollover.descr.flavor~="" then
					rollover.descr = table.concat({rollover.descr, rollover.descr.flavor},"\n")
				end
			else
				rollover = GetEntryRollover(v)
			end
			local enabled = true
			if IsKindOf(v, "PropertyObject") and v:HasMember("IsEnabled") then
				enabled = v:IsEnabled()
			end
			items[#items + 1] = {
				value = v.id,
				text = T{11438, "<new_in(new_in)>", new_in = v.new_in} .. v.display_name,
				rollover = rollover,
				image = id == "idMissionLogo" and v.image,
				item_type = id,
				enabled = enabled,
			}
		end
	end
	return items
end

function GetMissionParamUICategories()
	local keys = GetSortedMissionParamsKeys()
	local items = {}
	for _, category in ipairs(keys) do
		local value = MissionParams[category]
		items[#items + 1] = {
			id = category,
			name = value.display_name,
			title = value.display_name_caps,
			descr = value.descr,
			gamepad_hint = value.gamepad_hint,
			editor = "dropdown",
			submenu = true,
			items = function()
				return MissionParamCombo(category)
			end,
		}
	end
	return items
end

function GetMissionParamRollover(item, value)
	local id = item.id
	if id == "idMissionSponsor" or id == "idCommanderProfile" then
		local entry = table.find_value(MissionParams[id].items, "id", value)
		local descr = item.descr
		local effect = entry and entry.effect or ""
		if effect ~= "" then
			if id == "idMissionSponsor" then
				descr = descr .. "<newline><newline>" .. GetSponsorDescr(entry, false, "include rockets")
			else
				descr = descr .. "<newline><newline>" .. T{ effect, entry }
			end
		end
		return {
			title = item.title,
			descr = descr,
			gamepad_hint = item.gamepad_hint,
		}
	end
	if id == "idGameRules" then
		local descr = item.descr
		local names = GetGameRulesNames()
		if names and names ~= "" then
			descr = table.concat({descr, names}, "\n\n")
		end
		return {
			title = item.title,
			descr = descr,
			gamepad_hint = item.gamepad_hint,
		}
	end
	return item
end

DefineClass.PGMissionObject = {
	__parents = { "PropertyObject" },
	params = false,
}

function PGMissionObject:GetEffects()
	return GetDescrEffects()
end

function PGMissionObject:GetProperty(prop_id)
	if self.params[prop_id] then
		return self.params[prop_id]
	end
	return PropertyObject.GetProperty(self, prop_id)
end

function PGMissionObject:SetProperty(prop_id, prop_val)
	self.params[prop_id] = prop_val
end

function PGMissionObject:GetDifficultyBonus()
	if g_TitleObj then
		return g_TitleObj:GetDifficultyBonus()
	end
	return ""
end

function PGMissionObjectCreateAndLoad(obj)
	local obj = PGMissionObject:new(obj)
	obj.params = {}
	for k, v in pairs(g_CurrentMissionParams) do
		obj.params[k] = v
	end
	return obj
end

function GetCargoSumTitle(name)
	return T{4065, "<style LandingPosName><name></style><newline>", name = name}
end

------ RocketRenameObject
DefineClass.RocketRenameObject = {
	__parents = {"PropertyObject"},
	pregame = false,
	rocket_name = false,
	rocket_name_base = false,
	rolover_image = "UI/Common/pm_rename_rollover.tga",
	normal_image = "UI/Common/pm_rename.tga",
	rename_image = "UI/Common/pm_rename.tga",
}

function RocketRenameObject:InitRocketName(pregame)
	self.pregame = pregame
	if self.pregame then
		if not g_CurrentMapParams.rocket_name then
			g_CurrentMapParams.rocket_name, g_CurrentMapParams.rocket_name_base = GenerateRocketName(true)
		end
		self.rocket_name = g_CurrentMapParams.rocket_name
		self.rocket_name_base = g_CurrentMapParams.rocket_name_base
	else
		local rockets = MainCity.labels.SupplyRocket or empty_table
		local has_rocket = false
		for _, rocket in ipairs(rockets) do
			if rocket:IsAvailable() and rocket.name~="" then
				self.rocket_name = rocket.name
				break
			end
		end
		if not self.rocket_name then
			self.rocket_name, self.rocket_name_base = GenerateRocketName(true)
		end
	end
end

function RocketRenameObject:GetRocketName()
	if MainCity and MainCity.launch_mode == "elevator" then
		return BuildingTemplates.SpaceElevator.display_name
	end
	return self.rocket_name
end

function RocketRenameObject:SetRocketName(rocket_name)
	self.rocket_name = rocket_name
	if self.pregame then
		g_CurrentMapParams.rocket_name = self.rocket_name
	end
end

function RocketRenameObject:RenameRocket(host, func)
	CreateMarsRenameControl(host, T(4069, "Rename"), self:GetRocketName(), 
		function(name) 
			local prev = self:GetRocketName()			
			self:SetRocketName(name) 
			if func then func() end 
			if prev~=name then
				self.rocket_name_base = false
			end
		end, 
		nil, self, {max_len = 23, console_show = Platform.steam and GetUIStyleGamepad()})
end

function RocketRenameObject:GetRocketHyperlink()
	if MainCity and MainCity.launch_mode == "elevator" then
		return BuildingTemplates.SpaceElevator.display_name
	end
	local base = T{6898, "<h RenameRocket Rename>< image <img> 2000 > ", img = Untranslated(self.rename_image)}
	return T{11250, "<base><name><end_link>", base = base, name = Untranslated(self.rocket_name), end_link = T(4162, "</h>")}
end

function InitRocketRenameObject(pregame, new_instance)
	if not g_RenameRocketObj or new_instance then
		g_RenameRocketObj = RocketRenameObject:new()
		g_RenameRocketObj:InitRocketName(pregame)
	end
	return g_RenameRocketObj
end



function ResupplyDialogOpen(host, ...)
	RefreshRocketAvailability()
		
	if g_ActiveHints["HintResupply"] then
		HintDisable("HintResupply")
	end
	if HintsEnabled or g_Tutorial then
		if HintsEnabled then
			ContextAwareHintShow("HintResupplyUI", true)
		end
		local hintdlg = GetOnScreenHintDlg()
		if hintdlg then
			hintdlg:SetParent(terminal.desktop)
			hintdlg:SetHiddenMinimized(true)
		end
	end
end

function ResupplyDialogClose(host, ...)
	g_RenameRocketObj = false
	ResetCargo()
	g_UIAvailableRockets = 0
	g_UITotalRockets = 0
	
	if g_ActiveHints["HintResupplyUI"] then
		ContextAwareHintShow("HintResupplyUI", false)
	end
	if HintsEnabled or g_Tutorial then
		local hintdlg = GetOnScreenHintDlg()
		if hintdlg then
			hintdlg:SetParent(GetInGameInterface())
			hintdlg:SetHiddenMinimized(false)
		end
	end
end

function RefreshRocketAvailability()
	local owned, available = 0, 0
	for _,rocket in ipairs(MainCity.labels.AllRockets or empty_table) do
		if rocket.owned and IsKindOf(rocket, "SupplyRocket") and not IsKindOf(rocket, "SupplyPod") then
			owned = owned + 1
			if rocket:IsAvailable() then
				available = available + 1
			end
		end
	end
	g_UIAvailableRockets = available
	g_UITotalRockets = owned
end

function BuyRocket(host)
	CreateRealTimeThread(function()
		local price = g_Consts.RocketPrice
		if UIColony and UIColony and (UIColony.funds:GetFunding() - g_CargoCost) >= price then
			if WaitMarsQuestion(host, T(6880, "Warning"), T{6881, "Are you sure you want to buy a new Rocket for <funding(price)>?", price = price}, T(1138, "Yes"), T(1139, "No"), "UI/Messages/rocket.tga") == "ok" then
				local city = MainCity
				g_UIAvailableRockets = g_UIAvailableRockets + 1
				g_UITotalRockets = g_UITotalRockets + 1
				UIColony.funds:ChangeFunding(-price, "Rocket")
				local rocket = PlaceBuildingIn(GetRocketClass(), city.map_id, {city = city})
				city:AddToLabel("SupplyRocket", rocket) -- add manually to avoid reliance on running game time
				rocket:SetCommand("OnEarth")
				local obj = host.context
				ObjModified(obj)
			end
		else
			CreateMarsMessageBox(T(6902, "Warning"), T{7546, "Insufficient funding! You need <funding(price)> to purchase a Rocket!", price = price}, T(1000136, "OK"), host)
		end
	end)
end

function SetupLaunchLabel(mode)
	local label = "SupplyRocket"
	if mode == "pod" then
		label = "SupplyPod"
	end
	return label
end

function LaunchCargoRocket(obj, func_on_launch)
	local city = MainCity
	local mode = city and city.launch_mode or "rocket"
	local label = SetupLaunchLabel(mode)
	
	Msg("ResupplyRocketLaunched", label, g_CargoCost)
	
	CreateRealTimeThread(function(cargo, cost, obj, mode, label)
		if mode == "elevator" then
			assert(city.labels.SpaceElevator and #city.labels.SpaceElevator > 0)
			city.labels.SpaceElevator[1]:OrderResupply(cargo, cost)
		else
			cargo.rocket_name = g_RenameRocketObj.rocket_name
			MarkNameAsUsed("Rocket", g_RenameRocketObj.rocket_name_base)
			city:OrderLanding(cargo, cost, false, label)
		end
		if func_on_launch then
			func_on_launch()
		end
	end, g_RocketCargo, g_CargoCost, obj, mode, label)
	
	if HintsEnabled then
		HintDisable("HintResupplyUI")
	end
end

function SavegameFixups.InitColonyName()
	g_ColonyNameObj = PGColonyNameObject:new()
	g_ColonyNameObj:InitColonyName()
end
