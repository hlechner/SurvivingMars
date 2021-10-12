AttachedRechargeStations = {}
function AttachedRechargeStations.Init(self)
	local station_template = ClassTemplates.Building.RechargeStation
	local platforms = self:GetAttaches("RechargeStationPlatform")

	local ccs = GetCurrentColonyColorScheme()
	local cm1, cm2, cm3, cm4 = GetBuildingColors(ccs, station_template)
	
	local i = 1
	for _, platform in ipairs(platforms or empty_table) do
		platform:SetEnumFlags(const.efSelectable) --so we can select the command center through the recharge station
	
		local spot_obj = PlaceObjectIn("NotBuildingRechargeStation", self:GetMapID())
		spot_obj:ChangeEntity("RechargeStation")
		
		self:Attach(spot_obj, platform:GetAttachSpot())

		spot_obj:SetAttachOffset(platform:GetAttachOffset())
		spot_obj:SetAttachAngle(platform:GetAttachAngle())
		spot_obj.platform = platform
		spot_obj.hub = self
		assert(not IsValid(self.charging_stations[i]))
		self.charging_stations[i] = spot_obj
		i = i + 1
		if cm1 then
			Building.SetPalette(platform, cm1, cm2, cm3, cm4)
		end
	end
end

function AttachedRechargeStations.SetWorking(stations, working)
	for _, station in ipairs(stations) do
		if IsValid(station) then
			station.working = working
			if IsKindOf(station, "NotBuildingRechargeStation") then
				PlayFX("Working", working and "start" or "end", station, station.platform)
			end
			if working then
				station:StartAoePulse()
				station:NotifyDronesOnRechargeStationFree()
			end
		end
	end
end
