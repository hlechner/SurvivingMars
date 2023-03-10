function OpenPreGameMainMenu(mode)
	LoadingScreenOpen("idLoadingScreen", "pregame menu")
	ResetGameSession()
	local savegame_count = WaitCountSaveGames()
	local dlg = OpenDialog("PGMainMenu", nil, {savegame_count = savegame_count})
	if dlg and mode then
		dlg:SetMode(mode)
	end
	LoadingScreenClose("idLoadingScreen", "pregame menu")
end

function GetPreGameMainMenu()
	return GetDialog("PGMainMenu")
end

function ResetGameSession()
	CloseAllDialogs()
	local empty_map = GetMap() ~= "" 
	-- send end session telemetry with valid Sessionid
	if empty_map then
		if ActiveMapData.GameLogic then
			TelemetryEndSession("main_menu")
		end
	end
	-- reset game mission params
	InitNewGameMissionParams()
	
	-- reset AccessibleDLC
	for dlc in pairs(g_AvailableDlc) do
		g_AccessibleDlc[dlc] = true
	end
	
	-- change the map
	if empty_map then
		ChangeMap("")
	end
	
	-- reset cheats
	if not Platform.developer then
		config.BuildingInfopanelCheats = false
	end
	
	StopRadioStation()
	SetMusicPlaylist("MainTheme")
end

if Platform.desktop and not Platform.steam and not Platform.galaxy and not Platform.windows_store then

function AsyncAchievementUnlock(xplayer, achievement)
	Msg("AchievementUnlocked", 0, achievement)
end

end -- Platform.desktop and not Platform.steam and not Platform.galaxy

function CanUnlockAchievement(xplayer, achievement)
	return ActiveMapID ~= "Mod"
		and not g_Tutorial
		and not IsGameRuleActive("FreeConstruction")
		and not IsGameRuleActive("EasyMaintenance")
		and not IsGameRuleActive("IronColonists")
		and not IsGameRuleActive("EasyResearch")
		and not IsGameRuleActive("RichCoffers")
		and not IsGameRuleActive("EndlessSupply")
end