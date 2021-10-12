GlobalVar("NextHour", 0)
GlobalVar("TimeOfDayLightmodelChange")
function OnMsg.NewHour(hour)
	local earth_time = MulDivRound(hour, 24 * 60 * 1000, const.HoursPerDay)
	local hour_duration = (const.HourDuration * const.HoursPerDay) / 24
	
	-- sync time only once per day and on changemap
	if NextHour == 0 then
		SetTimeOfDay(earth_time, hour_duration)
	end
	NextHour = (hour + 1) % const.HoursPerDay
	
	local time = hour*60
	DeleteThread(TimeOfDayLightmodelChange)
	TimeOfDayLightmodelChange = CreateGameTimeThread(function()
		while true do
			local lml = GetCurrentLightmodelList(ActiveMapID)
			local lm = FindNextLightmodel(lml, time)
			if not lm or lm.time/60 ~= hour or hr.TODForceTime > -1 then return end
			local lm_time = lm.time
			local lm_blend_time = lm.blend_time
			local sleep_time = MulDivRound(lm_time - time, const.HourDuration, 60)
			Sleep(sleep_time)
			local blend_time = MulDivRound(lm_blend_time, const.HourDuration, 60)
			SetLightmodel(1, lm.id, blend_time)
			--print(lm.id)
			time = lm_time + lm_blend_time
			Sleep(lm_blend_time)
		end
	end)
end

function OnMsg.PostLoadGame()
	local hour, minute = GetTimeOfDay()
	local time_in_minutes = hour*60+minute
	local earth_time = MulDivRound(time_in_minutes, 1000 * 24 , const.HoursPerDay) -- (in 1/1000 min) * 24 / 25
	local hour_duration = (const.HourDuration * const.HoursPerDay) / 24
	
	SetTimeOfDay(earth_time, hour_duration)
	
	local light_model_list = GetCurrentLightmodelList(ActiveMapID)
	local last_lm = FindPrevLightmodel(light_model_list, time_in_minutes)
	if not last_lm then return end
	local time_since_last_lm = time_in_minutes - last_lm.time
	if time_since_last_lm < 0 then -- handle midnight time reset
		time_since_last_lm  = const.HoursPerDay *60 - time_since_last_lm
	end
	
	local remaining_blend = last_lm.blend_time - time_since_last_lm
	if remaining_blend <= 0 then
		-- set and leave 
		SetLightmodel(1, last_lm.id, 0)
	else
		-- setup minute precise blend with previous lm, offseting interpolation start
		local prev_lm = FindPrevLightmodel(light_model_list, last_lm.time - 1)
		SetLightmodel(1, prev_lm.id, 0)
		CreateRealTimeThread(function()
			WaitNextFrame(2)
			local blend_gametime = MulDivRound(remaining_blend, const.HourDuration, 60)
			local offset_gametime = MulDivRound(-time_since_last_lm, const.HourDuration, 60)
			SetLightmodel(1, last_lm.id, blend_gametime, offset_gametime)
		end)
	end
end

function OnMsg.PostNewMapLoaded()
	SetNormalLightmodelList(ActiveMapData.LightmodelList, ActiveMapID)
end

function OnMsg.SwitchMap(map_id)
	local hour, minute = GetTimeOfDay()
	local time_in_minutes = hour*60+minute
	local light_model_list = GetCurrentLightmodelList(map_id)
	local last_lm = FindPrevLightmodel(light_model_list, time_in_minutes)
	SetLightmodel(1, last_lm.id, 0)
end

GlobalVar("s_TurnOffIceThread", false)
GlobalVar("s_IceReasons", {})
GlobalVar("s_TerrainIceActive", false)
GlobalVar("s_IceStrength", 100)

local function SetTerrainIce()
	if s_TerrainIceActive then
		hr.RenderIce = 1
		SetTerrainRenderMode(const.trmIce)
	else
		hr.RenderIce = 0
		SetTerrainRenderMode(const.trmNormal)
	end
end

function OnMsg.PostLoadGame()
	local game_map = GameMaps[ActiveMapID]
	game_map.heat_grid:SetVisible()
	SetTerrainIce()
	SetSceneParam(1, "IceStrength", s_IceStrength, 0, 0)
end

function OnMsg.SwitchMap(map_id)
	SetTerrainIce()
end

function SetIceStrength(strength, reason, view, time, offset)
	reason = reason or false
	view = view or 1
	time = time or GameTime() > 0 and 30000 or 0
	offset = offset or 0
	if strength > 0 then
		if next(s_IceReasons) == nil then
			DeleteThread(s_TurnOffIceThread)
			SetTerrainRenderMode(const.trmIce)
			hr.RenderIce = 1
		end
		s_IceReasons[reason] = strength
		for _, s in pairs(s_IceReasons) do
			if strength < s then
				return
			end
		end
	else
		if s_IceReasons[reason] == nil then
			return
		end
		s_IceReasons[reason] = nil
		for _, s in pairs(s_IceReasons) do
			if strength < s then
				strength = s
			end
		end
		if strength == 0 then
			if not IsValidThread(s_TurnOffIceThread) then
				s_TurnOffIceThread = CreateMapRealTimeThread(function()
					Sleep(time)
					SetTerrainRenderMode(const.trmNormal)
					hr.RenderIce = 0
				end)
				MakeThreadPersistable(s_TurnOffIceThread)
			end
		end
	end
	s_TerrainIceActive = strength > 0
	s_IceStrength = strength
	SetSceneParam(view, "IceStrength", strength, time, offset)
end

table.iappend(g_ClassesToHideInCubemaps, { "SubsurfaceDeposit", "BuildingSign", "UnitSign", "ArrowTutorialBase", "TerrainDeposit" })

GlobalVar("LightmodelListNames", {})
function SetNormalLightmodelList(list_name, map_id)
	local list_name = list_name or LightmodelListNames[map_id].normal
	
	if not LightmodelListNames[map_id] then LightmodelListNames[map_id] = {} end
	
	if list_name == LightmodelListNames[map_id].normal then return end
	
	LightmodelListNames[map_id].normal = list_name
	local lm = FindPrevLightmodel(list_name, NextHour*60)
	if map_id == ActiveMapID then
		SetLightmodel(1, lm.id, const.HourDuration)
	end
end

function SetDisasterLightmodelList(list_name, fade_time, map_id)
	local list_name = list_name 
	if LightmodelListNames[map_id]["disaster"] and list_name == LightmodelListNames[map_id].disaster then return end
	LightmodelListNames[map_id].disaster = list_name
	
	list_name = list_name or LightmodelListNames[map_id].normal
	
	local lm = FindPrevLightmodel(list_name, NextHour*60)
	if map_id == ActiveMapID then
		SetLightmodel(1, lm.id, fade_time or const.HourDuration)
	end
end

function GetCurrentLightmodelList(map_id)
	if not LightmodelListNames[map_id] then
		return "TheMartian"
	end
	
	return LightmodelListNames[map_id].disaster or LightmodelListNames[map_id].normal
end

GlobalVar("NormalLightmodelList", "TheMartian")
GlobalVar("DisasterLightmodelList", false)
function SavegameFixups.MultipleLightModelInstances()
	FixupNightlightState() -- Update to multimap support variant before trying to change light mode
	SetNormalLightmodelList(NormalLightmodelList, ActiveMapID)
	SetDisasterLightmodelList(DisasterLightmodelList, nil, ActiveMapID)
end

function SavegameFixups.MultipleLightModelInstances2()
	SetNormalLightmodelList(NormalLightmodelList, MainMapID)
	SetDisasterLightmodelList(GetDisasterLightmodelList(), nil, MainMapID)
end

function DisasterEventLightmodelHandler(map_id)
	SetDisasterLightmodelList(GetDisasterLightmodelList(), nil, map_id)
end

OnMsg.DustStorm = DisasterEventLightmodelHandler
OnMsg.ColdWave = DisasterEventLightmodelHandler
OnMsg.DustStormEnded = DisasterEventLightmodelHandler
OnMsg.ColdWaveEnded = DisasterEventLightmodelHandler
