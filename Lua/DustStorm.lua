DefineClass.MapSettings_DustStorm =
{
	__parents = { "MapSettings" },
	properties =
	{
		{ id = "name",				name = "Name",                		editor = "text",    default = "dust" },
		{ id = "seasonal",			name = "Seasonal",           			editor = "bool",    default = false, },
		{ id = "seasonal_sols",		name = "Seasonal Sols",					editor = "number",	default = 10, no_edit = function(self) return not self.seasonal end },
		{ id = "target_dust",		name = "Dust on Targets(per sec)",	editor = "number",	default = 50 },
		{ id = "solar_penalty",		name = "Solar Penalty(percents)",		editor = "number",	default = 60, min = 0, max = 100 },
		{ id = "min_duration",		name = "Min Duration",					editor = "number",	default = 25 * const.HourDuration, scale = const.HourDuration, help = "In Hours" },
		{ id = "max_duration",		name = "Max Duration",					editor = "number",	default = 75 * const.HourDuration, scale = const.HourDuration, help = "In Hours" },
		{ id = "electrostatic",		name = "Electrostatic Storm Chance",	editor = "number",	default = 3, min = 0, max = 100 },
		{ id = "great",				name = "Great Storm Chance",			editor = "number",	default = 3, min = 0, max = 100 },
		{ id = "strike_interval",	name = "Strikes Interval"		,		editor = "number",	default = 3 * 1000, scale = 1000, category = "Electrostatic Storm", help = "In Seconds"},
		{ id = "strike_random",		name = "Strikes Randomize",			editor = "number",	default = 5 * 1000, scale = 1000, category = "Electrostatic Storm", help = "In Seconds" },
		{ id = "strike_radius",		name = "Strikes Radius",				editor = "number",	default = 20 * guim, scale = guim, category = "Electrostatic Storm", help = "In Meters" },
		{ id = "strike_discharge",	name = "Strikes Discharge",			editor = "number",	default = 100 * 1000, category = "Electrostatic Storm" },
		{ id = "strike_suspend",	name = "Strikes Suspend",				editor = "number",	default = 24 * const.HourDuration, scale = const.HourDuration, category = "Electrostatic Storm", help = "In Seconds" },
	},

	noon = "DustStormNoon",
	dusk = "DustStormDusk",
	evening = "DustStormEvening",
	night = "DustStorNight",
	dawn = "DustStormDawn",
	morning = "DustStormMorning",
}

GlobalVar("g_DustStorm", false)
GlobalVar("g_DustStormType", false)
GlobalVar("g_DustStormStopped", false)
GlobalVar("g_DustStormDuration", 0)
GlobalVar("g_DustStormStart", false)
GlobalVar("g_DustStormEnd", false)

function HasDustStorm(map_id)
	return (MainCity.map_id == map_id or map_id == nil) and g_DustStorm
end

local hour_duration = const.HourDuration
local day_duration = const.DayDuration

local function GetDustStormDescr()
	local map_data = ActiveMaps[MainMapID]
	local preset_name = map_data.MapSettings_DustStorm
	if preset_name == "disabled" then
		return
	end
	
	local data = DataInstances.MapSettings_DustStorm
	local dust_storm = data[preset_name] or data["DustStorm_VeryLow"]
	
	local orig_data = (dust_storm and not dust_storm.forbidden) and dust_storm
	return OverrideDisasterDescriptor(orig_data)
end

local function apply_dust(label, dust, batch, batches)
	local IsObjInDome = IsObjInDome
	local count = #(label or "")
	local start_i, end_i = 1, count
	if count > batches then
		start_i = 1 + count * (batch - 1) / batches
		end_i = count * batch / batches
	elseif batch > 1 then
		return
	end
	for i = start_i, end_i do
		local obj = label[i]
		if not IsObjInDome(obj) then
			obj:AddDust(dust)
		end
	end
end

local function apply_dust_elements(grid, dust, batch, batches)
	local IsKindOf = IsKindOf
	for i = 1, #(grid or "") do
		local elements = grid[i].elements
		local count = #elements
		local start_i, end_i = 1, count
		if count > batches then
			start_i = 1 + count * (batch - 1) / batches
			end_i = count * batch / batches
		elseif batch > 1 then
			end_i = 0 -- continue
		end
		for i = start_i, end_i do
			local obj = elements[i].building
			if IsKindOf(obj, "DustGridElement") then
				obj:AddDust(dust)
			end
		end
	end
end

local suspend_reason = const.DustStormSuspendReason
local suspend_labels = const.DustStormSuspendBuildings
if FirstLoad then
	g_SuspendLabels = false
end
function OnMsg.DataLoaded()
	g_SuspendLabels = {}
	for id, bld in pairs(BuildingTemplates) do
		if bld.suspend_on_dust_storm then
			g_SuspendLabels[#g_SuspendLabels + 1] = id
		end
	end
end

function FuelExplosion(obj)
	PlayFX("FuelExplosion", "start", obj)
	AddOnScreenNotification("FuelDestroyed", nil, {}, {obj}, obj:GetMapID())
	local IsObjInDome = IsObjInDome
	local in_dome = IsObjInDome(obj)
	MapForEach(obj, 30*guim,
		"Colonist",
		function(colonist)
			if not colonist:IsDying() and in_dome == IsObjInDome(colonist) then
				colonist:SetCommand("Die", "fuel explosion")
			end
		end)
end

function ExtendDustStorm(time)
	if HasDustStorm() then
		g_DustStormDuration = g_DustStormDuration + time
		g_DustStormEnd = g_DustStormEnd + time
		AddDisasterNotification(g_DustStorm.type .. "DustStormDuration", {
			start_time = g_DustStormStart,
			expiration = g_DustStormEnd - g_DustStormStart
		}, "extend", MainCity.map_id)
	end
end

function StartDustStorm(storm_type, dust_storm)
	assert(not HasDustStorm(), "Dust storm is already present!")
	local city = MainCity
	local map_id = city.map_id
	g_DustStormDuration = SessionRandom:Random(dust_storm.min_duration, dust_storm.max_duration)
	g_DustStorm = { type = storm_type, descr = dust_storm, start_time = GameTime(), duration = g_DustStormDuration }
	Msg("DustStorm", map_id)
	RemoveDisasterNotifications()
	local preset = storm_type .. "DustStormDuration"
	g_DustStormStart = GameTime()
	g_DustStormEnd = g_DustStormStart + g_DustStormDuration
	local id = AddDisasterNotification(preset, {
		start_time = g_DustStormStart,
		expiration = g_DustStormDuration
	}, nil, map_id)
	ShowDisasterDescription("DustStorm", map_id)
	local target_dust = g_DustStorm.type == "great" and 2 * dust_storm.target_dust or dust_storm.target_dust
	local time = 0
	local next_strike = GameTime() + dust_storm.strike_interval + SessionRandom:Random(dust_storm.strike_random)
	if g_DustStorm.type == "electrostatic" then
		PlayFX({
			actionFXClass = "ElectrostaticStorm", 
			actionFXMoment = "start",
			action_map_id = map_id,
		})
	elseif g_DustStorm.type == "great" then
		PlayFX({
			actionFXClass = "GreatStorm", 
			actionFXMoment = "start",
			action_map_id = map_id,
		})
	else
		PlayFX({
			actionFXClass = "DustStorm", 
			actionFXMoment = "start",
			action_map_id = map_id,
		})
	end
	g_DustStormStopped = false
	-- dust is applied to objects in batches
	local interval = 100
	local dust_labels = { "Building", "Drone", "Rover", "Dome" }
	local dust_grids = { "water", "electricity" }
	local max_count = 0
	for _, label_name in ipairs(dust_labels) do
		max_count = Max(#(city.labels[label_name] or ""), max_count)
	end
	for _, grid_name in ipairs(dust_grids) do
		for _, grid in ipairs(city[grid_name] or empty_table) do
			max_count = Max(#grid.elements, max_count)
		end
	end
	local period = Max(max_count / 2, 1000)
	local period_dust = target_dust * period / 1000
	local batches = period / interval
	local batch = 1
	local realm = GetRealm(city)
	while not g_DustStormStopped and g_DustStormDuration > 0 do
		for _, label_name in ipairs(dust_labels) do
			apply_dust(city.labels[label_name], period_dust, batch, batches)
		end
		for _, grid_name in ipairs(dust_grids) do
			apply_dust_elements(city[grid_name], period_dust, batch, batches)
		end
		if g_DustStorm.type == "electrostatic" and GameTime() > next_strike then
			next_strike = GameTime() + dust_storm.strike_interval + SessionRandom:Random(dust_storm.strike_random)
			local strike_pos = GetRandomPassable(city)
			local strike_radius = dust_storm.strike_radius
			PlayFX({
				actionFXClass = "ElectrostaticStormArea", 
				actionFXMoment = "start", 
				action_pos = strike_pos,
				action_map_id = map_id,
			})
			PlayFX({
				actionFXClass = "ElectrostaticStorm", 
				actionFXMoment = "hit-moment" .. tostring(1 + SessionRandom:Random(4)), 
				action_pos = strike_pos,
				action_map_id = map_id,
			})
			local fuel_explosions
			local IsObjInDome = IsObjInDome
			local IsKindOf = IsKindOf
			local IsCloser2D = IsCloser2D
			local FuelExplosion = FuelExplosion
			realm:MapForEach(strike_pos, strike_radius + GetEntityMaxSurfacesRadius(), 
				"Colonist", "Building", "Drone", "RCRover", "ResourceStockpileBase",
				function(obj)
					if not IsCloser2D(obj, strike_pos, strike_radius) or IsObjInDome(obj) then
						return
					end
					PlayFX({
						actionFXClass = "ElectrostaticStormObject",
						actionFXMoment = "start",
						target = obj,
						action_pos = strike_pos,
					})
					if IsKindOf(obj, "Drone") then
						obj:UseBattery(obj.battery)
					elseif IsKindOf(obj, "RCRover") then
						obj:SetCommand("Malfunction")
					elseif IsKindOf(obj, "UniversalStorageDepot") then
						if not IsKindOf(obj, "RocketBase") and obj:GetStoredAmount("Fuel") > 0 then
							obj:CheatEmpty()
							fuel_explosions = fuel_explosions or {}
							fuel_explosions[#fuel_explosions + 1] = obj
						end
					elseif IsKindOf(obj, "ResourceStockpileBase") then
						local amount = obj:GetStoredAmount()
						if obj.resource == "Fuel" and amount > 0 then
							obj:AddResourceAmount(-amount, true)
							fuel_explosions = fuel_explosions or {}
							fuel_explosions[#fuel_explosions + 1] = obj
						end
					elseif IsKindOf(obj, "Building") then
						obj:SetSuspended(true, "Suspended", dust_storm.strike_suspend)
						if IsKindOf(obj, "ElectricityStorage") then
							obj.electricity.current_storage = Max(0, obj.electricity.current_storage - dust_storm.strike_discharge)
						end
					elseif IsKindOf(obj, "Colonist") then
						if not obj:IsDying() then
							obj:SetCommand("Die", "lighting strike")
						end
					end
				end)
			for _, obj in ipairs(fuel_explosions or empty_table) do
				if IsValid(obj) then
					FuelExplosion(obj)
				end
			end
		end
		if batch == 1 and time > hour_duration then
			for _, label in ipairs(g_SuspendLabels or suspend_labels) do
				for _, bld in ipairs(city.labels[label] or empty_table) do
					if not bld.suspended and not IsObjInDome(bld) then
						bld:SetSuspended(true, suspend_reason)
					end
				end
			end
		end
		local delta = Min(g_DustStormDuration, interval)
		Sleep(delta)
		time = time + delta
		g_DustStormDuration = g_DustStormDuration - delta
		batch = batch < batches and (batch + 1) or 1
	end
	
	local actionFXClass = "DustStorm"
	if g_DustStorm.type == "electrostatic" then
		actionFXClass = "ElectrostaticStorm"
	elseif g_DustStorm.type == "great" then
		actionFXClass = "GreatStorm"
	end
	
	PlayFX({
		actionFXClass = actionFXClass, 
		actionFXMoment = "end",
		action_map_id = map_id,
	})
	
	g_DustStorm = false
	g_DustStormStart = false
	g_DustStormEnd = false
	RemoveOnScreenNotification(id, map_id)
	Msg("DustStormEnded", map_id)
end

function OnMsg.DustStormEnded(map_id)
	local buildings = Cities[map_id].labels.Suspended or ""
	for i = #buildings, 1, -1 do
		buildings[i]:SetSuspended(false, suspend_reason)
	end
end

function SavegameFixups.BrokenDustStormAfterLongWinter()
	if IsValidThread(DustStorm) then return end
	
	local realm = GetRealm(MainCity)
	realm:MapForEach("map", "RequiresMaintenance", function(o)
		o:DisconnectFromCommandCenters()
		local tr = o.task_requests
		for i = #(tr or ""), 1, -1 do
			if tr[i] == false then
				table.remove(tr, i)
			end
		end
		o:CreateResourceRequest()
		o:AccumulateMaintenancePoints()
		o:ConnectToCommandCenters()
	end)
	
	if g_DustStorm then			
		local storm_type = g_DustStorm.type
		local preset = storm_type .. "DustStormDuration"
		
		if storm_type == "electrostatic" then
			PlayFX("ElectrostaticStorm", "end")
		elseif storm_type == "great" then
			PlayFX("GreatStorm", "end")
		else
			PlayFX("DustStorm", "end")
		end
		
		g_DustStorm = false
		g_DustStormStart = false
		g_DustStormEnd = false
		
		local map_id = MainCity.map_id

		RemoveOnScreenNotification(preset, map_id)
		Msg("DustStormEnded", map_id)
	end
	
	RestartGlobalGameTimeThread("DustStorm")
end

GlobalGameTimeThread("DustStorm", function()
	if IsGameRuleActive("NoDisasters") then return end
	
	local dust_storm = GetDustStormDescr()
	if not dust_storm then
		return
	end
	
	-- wait a few sols
	local wait_time = 0
	if not dust_storm.seasonal then
		wait_time = dust_storm.birth_hour + SessionRandom:Random(dust_storm.spawntime_random)
	end
	
	local first = true
	while true do
		-- find wait time and next storm type
		if dust_storm.seasonal then
			wait_time = wait_time + dust_storm.seasonal_sols * day_duration
		else
			if not first then
				wait_time = wait_time + SessionRandom:Random(dust_storm.spawntime, dust_storm.spawntime_random)
			end
		end
		if not g_DustStormType then
			local rand = SessionRandom:Random(101)
			if rand < dust_storm.electrostatic then
				g_DustStormType = "electrostatic"
			elseif rand < dust_storm.electrostatic + dust_storm.great then
				g_DustStormType = "great"
			else	
				g_DustStormType = "normal"
			end
		end
		
		-- wait and show the notification
		local start_time = GameTime()
		local last_check_time = GameTime()
		while DustStormsDisabled or IsDisasterPredicted() or IsDisasterActive() or (GameTime() - start_time < wait_time) do
			local dt = GameTime() - last_check_time
			last_check_time = GameTime()
			if DustStormsDisabled or IsDisasterPredicted() or IsDisasterActive() then
				wait_time = wait_time + dt
			else
				local warn_time = GetDisasterWarningTime(dust_storm)
				if GameTime() - start_time > wait_time - warn_time then
					local map_id = MainCity.map_id
					AddDisasterNotification(g_DustStormType .. "DustStorm2",
						{ 	start_time = GameTime(),
							expiration = warn_time,
							early_warning = GetEarlyWarningText(warn_time),
							num_of_sensors = GetTowerCountText()
						}, nil, map_id)
					ShowDisasterDescription("DustStorm", map_id)
					WaitMsg("TriggerDustStorm", wait_time - (GameTime() - start_time))
					while IsDisasterActive() do
						WaitMsg("TriggerDustStorm", 5000)
					end
					break
				end
			end
			local forced = WaitMsg("TriggerDustStorm", 5000)
			if forced then
				break
			end
		end
		first = false
		wait_time = 0
		local next_storm = g_DustStormType
		g_DustStormType = false
		if not DustStormsDisabled then
			StartDustStorm(next_storm, dust_storm)
		end
		
		local new_dust_storm = GetDustStormDescr()
		while not new_dust_storm do
			Sleep(const.DayDuration)
			new_dust_storm = GetDustStormDescr()
		end
		dust_storm = new_dust_storm
	end
end)

function CheatDustStorm(storm_type, setting)
	CheatStopDisaster()
	if not setting and GetDustStormDescr() then
		g_DustStormType = storm_type
		Msg("TriggerDustStorm")
	else
		CreateGameTimeThread(function()
			setting = setting or ActiveMaps[MainMapID].MapSettings_DustStorm
			local data = DataInstances.MapSettings_DustStorm
			StartDustStorm(storm_type, data[setting] or data["DustStorm_VeryLow"])
		end)
	end
end

function StopDustStorm()
	g_DustStormStopped = true
end

function OnMsg.CheatStopDisaster()
	if not HasDustStorm() then return end
	StopDustStorm()
end
