DefineClass.AutoRemoveObj = {
	__parents = { "CObject" },
}

GlobalGameTimeThread("AutoRemoveObjs", function()
	Sleep(const.HourDuration)
	while true do
		local sleep = const.HourDuration
		if NightLightsState then
			Sleep(10000) sleep = sleep - 10000
			local realm = GetActiveRealm()
			local sizex, sizey = GetActiveTerrain():GetMapSize()
			local border = ActiveMapData.PassBorder or 0
			local obj = realm:MapFindNearest(point(border + AsyncRand(sizex - 2 * border), border + AsyncRand(sizey - 2 * border)), "map", "AutoRemoveObj")
			Sleep(10000) sleep = sleep - 10000
			if IsValid(obj) then
				realm:SuspendPassEdits("AutoRemoveObjs")
				realm:MapDelete( obj, 200*guim, "AutoRemoveObj", "rand", 50, AsyncRand())
				if IsValid(obj) then obj:delete() end
				realm:ResumePassEdits("AutoRemoveObjs")
			end
		end
		Sleep(sleep)
	end
end)
