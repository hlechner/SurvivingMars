DefineClass.MapSettings_ColdWave =
{
	__parents = { "MapSettings" },
	properties =
	{
		{ id = "name",            name = "Name",                 editor = "text",    default = "cold wave" },
		{ id = "temp_drop",                                      editor = "number",  default = -55, no_edit = true, dont_save = true, help = "Unused"},
		{ id = "min_temp_drop",   name = "Min Temperature Drop", editor = "number",  default = -100, min = -100, max = -30, help = "Unused"},
		{ id = "max_temp_drop",   name = "Max Temperature Drop", editor = "number",  default = -30, min = -100, max = -30, help = "Unused"},
		{ id = "seasonal",        name = "Seasonal",             editor = "bool",    default = false,},
		{ id = "seasonal_sols",   name = "Seasonal Sols",        editor = "number",  default = 13, no_edit = function(self) return not self.seasonal end },
		{ id = "min_duration",    name = "Min Duration",         editor = "number",  default = 25 * const.HourDuration, scale = const.HourDuration, help = "In Hours" },
		{ id = "max_duration",    name = "Max Duration",         editor = "number",  default = 75 * const.HourDuration, scale = const.HourDuration, help = "In Hours" },
	},
	
	noon = "ColdWaveNoon",
	dusk = "ColdWaveDusk",
	evening = "ColdWaveEvening",
	night = "ColdWaveNight",
	dawn = "ColdWaveDawn",
	morning = "ColdWaveMorning",
}

GlobalVar("g_ColdWave", false)
GlobalVar("g_ColdWaves", 0)
GlobalVar("g_ColdWaveStartTime", false)
GlobalVar("g_ColdWaveEndTime", false)
GlobalVar("g_ColdWaveExtend", false)

function HasColdWave(map_id)
	return (MainCity.map_id == map_id or map_id == nil) and g_ColdWave
end

local hour_duration = const.HourDuration
local day_duration = const.DayDuration
local day_hours = const.HoursPerDay

local function GetColdWaveDescr()
	if ActiveMaps[MainMapID].MapSettings_ColdWave == "disabled" then
		return
	end
	
	local data = DataInstances.MapSettings_ColdWave
	local cold_wave = data[ActiveMaps[MainMapID].MapSettings_ColdWave] or data["ColdWave_VeryLow"]
	
	local orig_data = cold_wave and not cold_wave.forbidden and cold_wave
	return OverrideDisasterDescriptor(orig_data)
end

function ExtendColdWave(time)
	if HasColdWave() and g_ColdWaveStartTime and g_ColdWaveEndTime then
		local map_id = MainCity.map_id
		g_ColdWaveEndTime = g_ColdWaveEndTime + time
		AddDisasterNotification("ColdWaveDuration", {start_time = g_ColdWaveStartTime, expiration = g_ColdWaveEndTime - g_ColdWaveStartTime}, "extended", map_id)
		g_ColdWaveExtend = true
		Msg("ColdWaveCancel", map_id)
	end
end

function StartColdWave(settings, endless)
	local map_id = MainCity.map_id
	local cold_wave = ColdWaveInstance:new({
		settings = settings,
		temp_drop = SessionRandom:Random(settings.min_temp_drop, settings.max_temp_drop),
	}, map_id)
	local duration = not endless and SessionRandom:Random(settings.min_duration, settings.max_duration)
	if not endless then
		g_ColdWaveStartTime = GameTime()
		g_ColdWaveEndTime = g_ColdWaveStartTime + duration
	end
	if g_ColdWave then
		g_ColdWave:ApplyHeat(false)
	else
		PlayFX({
			actionFXClass = "ColdWave",
			actionFXMoment = "start",
			action_map_id = map_id,
		})
	end
	g_ColdWave = cold_wave
	Msg("ColdWave", map_id)
	RemoveDisasterNotifications()
	local preset = duration and "ColdWaveDuration" or "ColdWaveEndless"
	
	local id = AddDisasterNotification(preset, {
		start_time = g_ColdWaveStartTime or 0,
		expiration = duration
	}, nil, map_id)
	ShowDisasterDescription("ColdWave", map_id)
	for i = #g_DustDevils, 1, -1 do
		g_DustDevils[i]:delete()
	end
	cold_wave:ApplyHeat(true)
	while true do
		if WaitMsg("ColdWaveCancel", duration) then
			if g_ColdWaveExtend then
				duration = g_ColdWaveEndTime - GameTime()
				g_ColdWaveExtend = false
			else
				break
			end
		else
			break
		end
	end
	cold_wave:ApplyHeat(false)
	RemoveOnScreenNotification(preset, map_id)
	if g_ColdWave == cold_wave then
		PlayFX({
			actionFXClass = "ColdWave",
			actionFXMoment = "end",
			action_map_id = map_id,
		})
		g_ColdWave = false
		g_ColdWaveStartTime = false
		g_ColdWaveEndTime = false
		Msg("ColdWaveEnded", map_id)
	end
end

GlobalGameTimeThread("ColdWave", function()
	if IsGameRuleActive("NoDisasters") then return end

	local cold_wave = GetColdWaveDescr()
	if not cold_wave then
		return
	end

	-- wait a few sols
	local wait_time = 0
	if not cold_wave.seasonal then
		wait_time = cold_wave.birth_hour + SessionRandom:Random(cold_wave.spawntime_random)
	end
	
	local first = true
	while true do
		-- find wait time
		if cold_wave.seasonal then
			wait_time = wait_time + cold_wave.seasonal_sols * day_duration
		else
			if not first then
				wait_time = wait_time + SessionRandom:Random(cold_wave.spawntime, cold_wave.spawntime_random)
			end
		end
		
		-- wait and show the notification
		local start_time = GameTime()
		local last_check_time = GameTime()
		local map_id = MainCity.map_id
		while ColdWavesDisabled or IsDisasterPredicted() or IsDisasterActive() or (GameTime() - start_time < wait_time) do
			local dt = GameTime() - last_check_time
			last_check_time = GameTime()
			if ColdWavesDisabled or IsDisasterPredicted() or IsDisasterActive() then
				wait_time = wait_time + dt
			else
				local warn_time = GetDisasterWarningTime(cold_wave)
				if GameTime() - start_time > wait_time - warn_time then
					AddDisasterNotification("ColdWave2", {
						start_time = GameTime(), 
						expiration = warn_time,
						early_warning = GetEarlyWarningText(warn_time),
						num_of_sensors = GetTowerCountText()},
					nil, map_id)
					ShowDisasterDescription("ColdWave", map_id)
					WaitMsg("TriggerColdWave", wait_time - (GameTime() - start_time))
					while IsDisasterActive() do
						WaitMsg("TriggerColdWave", 5000)
					end
					break
				end
			end
			local forced = WaitMsg("TriggerColdWave", 5000)
			if forced then
				break
			end
		end
		first = false
		wait_time = 0	
		if not ColdWavesDisabled then
			StartColdWave(cold_wave)
		end
		
		local new_cold_wave = GetColdWaveDescr()
		while not new_cold_wave do
			Sleep(const.DayDuration)
			new_cold_wave = GetColdWaveDescr()
		end
		cold_wave = new_cold_wave
	end
end)

----

DefineClass.ColdWaveInstance =
{
	__parents = { "BaseHeater", "Object" },
	settings = false,
	temp_drop = 0,
	heat = -2*const.MaxHeat,
	GetHeatRange = empty_func,
	GetHeatBorder = empty_func,
	GetHeatCenter = empty_func,
}

function ColdWaveInstance:ApplyForm(grid, heat)
	Heat_AddAmbient(grid, heat)
end

----

DefineClass.ColdArea =
{
	__parents = { "EditorMarker", "BaseHeater", "EditorRangeObject" },
	properties =
	{
		{ category = "Cold", name = T(643, "Range"),        id = "Range",       editor = "number", default = 512*guim, scale = guim, min = 0, max = 2048 * guim, slider = true, buttons = {{"Apply", "Reapply"}}},
		{ category = "Cold", name = T(841, "Ice Strength"), id = "IceStrength", editor = "number", default = 100, min = 0, max = 100, slider = true},
	},
	Scale = 1000,
	heat = -const.MaxHeat,
	is_static = true,
	noise = "ColdArea",
	dbg_range_color = cyan,
}

function ColdArea:Init()
	self:SetScale(self.Scale)
end

function ColdArea:Done()
	SetIceStrength(0, self)
end

function ColdArea:GameInit()
	self:ApplyHeat(true)
end

function ColdArea:Reapply(self)
	self:ApplyHeat(true)
end

function ColdArea:GetHeatRange()
	return self.Range
end

function ColdArea:EditorGetRange()
	return self.Range
end

function ColdArea:ApplyForm(grid, heat, center_x, center_y, radius, border, map_width, map_height, map_border, grid_tile)
	if radius == 0 then
		return
	end
	local max_size = self.Range / (2 * guim)
	local noise_size = 64
	while noise_size < max_size do
		noise_size = 2 * noise_size
	end
	noise_size = Max(32, Min(256, noise_size / 2))
	local noise_center = point(noise_size / 2, noise_size / 2)
	local form_obj = DataInstances.NoisePreset[self.noise]
	if not form_obj then
		StoreErrorSource(self, "Missing cloud form preset")
		return
	end
	local seed = xxhash64(GetMap(), center_x, center_y)
	local pattern = form_obj:GetNoise(noise_size, seed)
	if pattern:get(0, 0) ~= 0 then
		pattern:lnot_i()
	end
	local minx, miny, maxx, maxy = pattern:minmaxdist(noise_center)
	local radius_max = noise_center:Dist2D(maxx, maxy)
	if radius_max == 0 then
		StoreErrorSource(self, "Cloud form error")
		return
	end
	SetIceStrength(self.IceStrength, self)
	Heat_AddColdArea(grid, pattern, radius_max, center_x, center_y, radius, heat, map_width, map_height, map_border, grid_tile)
	pattern:free()
end

function ColdArea:EditorEnter()
	EditorRangeObject.EditorEnter(self)
	EditorMarker.EditorEnter(self)
end

function ColdArea:EditorExit()
	EditorRangeObject.EditorExit(self)
	EditorMarker.EditorExit(self)
end

function CheatColdWave(setting)
	CheatStopDisaster()
	if not setting and GetColdWaveDescr() then
		Msg("TriggerColdWave")
	else
		CreateGameTimeThread(function()
			setting = setting or ActiveMaps[MainMapID].MapSettings_ColdWave
			local data = DataInstances.MapSettings_ColdWave
			StartColdWave(data[setting] or data["ColdWave_VeryLow"])
		end)
	end
end

function CheatDisasterWarning()
	if IsDisasterPredicted() then 
		return 
	end
	local disaster = "ColdWave2"
	local cold_wave = GetColdWaveDescr()
	if not cold_wave then
		return
	end	
	local warn_time = GetDisasterWarningTime(cold_wave)
	local map_id = MainCity.map_id
	AddDisasterNotification(disaster, {
		start_time = GameTime(),
		expiration = warn_time,
		early_warning = GetEarlyWarningText(warn_time),
		num_of_sensors = GetTowerCountText() },
	nil, map_id)
	ShowDisasterDescription(disaster, map_id)
end

function StopColdWave()
	Msg("ColdWaveCancel", MainCity.map_id)
end

function OnMsg.CheatStopDisaster()
	if not HasColdWave() then return end
	StopColdWave()
end
