
function SavegameFixups.MultimapDisasters_OnScreenNotificationChanges()
	if g_ColdWave then
		CreateGameTimeThread(function()
			WaitCurrentDisaster()
			RestartGlobalGameTimeThread("ColdWave")
		end)
	else
		RestartGlobalGameTimeThread("ColdWave")
	end

	if g_DustStorm then
		CreateGameTimeThread(function()
			WaitCurrentDisaster()
			RestartGlobalGameTimeThread("DustStorm")
		end)
	else
		RestartGlobalGameTimeThread("DustStorm")
	end
	
	if not (g_ColdWave or g_DustStorm) then
		for i = #g_ActiveOnScreenNotifications, 1, -1 do
			local notif = g_ActiveOnScreenNotifications[i]
			local preset = notif[1]
			if g_DisastersPredicted[preset] then
				table.remove(g_ActiveOnScreenNotifications, i)
			end
		end
		RemoveDisasterNotifications()
	end
	
	RestartGlobalGameTimeThread("Meteors")
	if g_MeteorStorm then
		CreateGameTimeThread(function()
			WaitCurrentDisaster()
			RestartGlobalGameTimeThread("MeteorStorm")
		end)
	else
		RestartGlobalGameTimeThread("MeteorStorm")
	end
end

function SavegameFixups.MultimapDisasters_ForceRestartColdWave()
	if g_ColdWave and not IsValid(g_ColdWave) then
		g_ColdWave:ApplyHeat(false, MainMapID)
		g_ColdWave = false
		g_ColdWaveExtend = false
		g_ColdWaveStartTime = false
		g_ColdWaveEndTime = false
		RemoveDisasterNotifications()
		Msg("ColdWaveEnded", MainMapID)
		RestartGlobalGameTimeThread("ColdWave")
	end
end

function SavegameFixups.RestartDeadDisasterThreads()
	if not IsValidThread(_G["ColdWave"]) then
		RestartGlobalGameTimeThread("ColdWave")
	end
	
	if not IsValidThread(_G["DustStorm"]) then
		RestartGlobalGameTimeThread("DustStorm")
	end
	
	if not IsValidThread(_G["MeteorStorm"]) then
		RestartGlobalGameTimeThread("MeteorStorm")
	end
	
	if not IsValidThread(_G["Meteors"]) then
		RestartGlobalGameTimeThread("Meteors")
	end
end

function SavegameFixups.StopDisasters()
	if IsGameRuleActive("NoDisasters") then
		StopGlobalGameTimeThread("ColdWave")
		StopGlobalGameTimeThread("DustStorm")
		StopGlobalGameTimeThread("MeteorStorm")
		StopGlobalGameTimeThread("Meteors")
	end
end

local function RestartDisasterThread(disaster, rule_name, thread_name)
	local map_data = ActiveMaps[MainMapID]
	local rule_value = disaster .. "_GameRule"
	local setting_name = "MapSettings_" .. disaster
	if map_data[setting_name] ~= "disabled" and map_data[setting_name] ~= rule_value and IsGameRuleActive(rule_name) then
		map_data[setting_name] = rule_value
		RestartGlobalGameTimeThread(thread_name)
	end
end

function SavegameFixups.UpdateMaxDisasters(metadata)
	if metadata.active_mods and #metadata.active_mods > 0 then
		RestartDisasterThread("Meteor", "Armageddon", "Meteors")
		RestartDisasterThread("Meteor", "Armageddon", "MeteorStorm")
		RestartDisasterThread("ColdWave", "WinterIsComing", "ColdWave")
		RestartDisasterThread("DustStorm", "DustInTheWind", "DustStorm")
		RestartDisasterThread("DustDevils", "Twister", "DustDevils")
	end
end
