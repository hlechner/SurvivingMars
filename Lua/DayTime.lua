function LocalToEarthTime(time)
	return MulDivRound(time, 24, const.HoursPerDay)
end

function EarthToLocalTime(time)
	return MulDivRound(time, const.HoursPerDay, 24)
end

GlobalVar("SunAboveHorizon", false)
GlobalVar("CurrentWorkshift", 2)
GlobalVar("DayStart", 0)

function OnMsg.NewHour(hour)
	local workshifts = const.DefaultWorkshifts
	if hour == workshifts[1][1] then
		-- at sunrise, first turn solar panels on, then change workshift !!!
		SunAboveHorizon = true
		Msg("SunChange")
		CurrentWorkshift = 1
		Msg("NewWorkshift", 1)
	elseif hour == workshifts[2][1] then
		CurrentWorkshift = 2
		Msg("NewWorkshift", 2)
	elseif hour == workshifts[3][1] then
		-- at set, first change workshift, then turn solar panels off !!!
		CurrentWorkshift = 3
		Msg("NewWorkshift", 3)
		SunAboveHorizon = false
		Msg("SunChange")
	end
end

GlobalGameTimeThread( "DateTimeThread", function()
	if not ActiveMapData.GameLogic then
		return
	end
	local hour_duration = const.HourDuration
	local minute_duration = const.MinuteDuration
	local minutes_per_hour = const.MinutesPerHour
	local day, hour, minute = Colony.day, Colony.hour, 0
	local workshifts = const.DefaultWorkshifts
	CurrentWorkshift = 3
	for i = 1, 2 do
		if hour >= workshifts[i][1] and hour < workshifts[i][2] then
			CurrentWorkshift = i
			SunAboveHorizon = true
			break
		end
	end
	
	SetTimeOfDay(LocalToEarthTime(hour*60*1000), const.HourDuration)
	local lm = FindNextLightmodel(GetCurrentLightmodelList(ActiveMapID), hour*60)
	SetLightmodel(1, lm.id, 0)
	InitNightLightState()
	
	Msg("NewDay", day)
	Msg("NewHour", hour)
	while true do
		Sleep(minute_duration)
		minute = minute + 1
		
		if minute == minutes_per_hour then
			minute = 0
			hour = hour + 1
			if hour == const.HoursPerDay then
				hour = 0
				day = day + 1
			end
		end
		Msg("NewMinute", hour, minute)
		if minute == 0 then
			--@@@msg NewHour,hour- fired every _GameTime_ hour.
			Msg("NewHour", hour)
			if hour == 0 then
				DayStart = GameTime()
				--@@@msg NewDay,day- fired every Sol.
				Msg("NewDay", day)
			end
		end
	end
end )

function IsDarkHour(hour)
	return hour<=3 or hour>=21
end
