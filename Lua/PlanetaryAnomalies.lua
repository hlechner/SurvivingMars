DefineClass.PlanetaryAnomalies = {
	__parents = {"InitDone"},
	next_anomaly_day = false,
	next_anomaly_interval = 20, -- sols
}

function PlanetaryAnomalies:Init()
	if g_Tutorial then return end
	self.next_anomaly_day = 10 + SessionRandom:Random(2)
end

function PlanetaryAnomalies:UpdatePlanetaryAnomalies(day)
	if g_Tutorial or not self.next_anomaly_day or day < self.next_anomaly_day then
		return
	end
	
	self.next_anomaly_day = day + self.next_anomaly_interval + SessionRandom:Random(5)
	self.next_anomaly_interval = Min(100, self.next_anomaly_interval + 20)
	
	self:BatchSpawnPlanetaryAnomalies()
end

function PlanetaryAnomalies:BatchSpawnPlanetaryAnomalies()
	local num = 2 + SessionRandom:Random(3) -- todo: stable somehow
	local lat, long
	local breakthrough_placed = false
	for i = 1, num do
		lat, long = GenerateMarsScreenPoI("anomaly")
		local obj = PlaceObjectIn("PlanetaryAnomaly", MainMapID, {
			display_name = T(11234, "Planetary Anomaly"),
			longitude = long,
			latitude = lat,
		})
		if obj.reward == "breakthrough" then
			breakthrough_placed = true
		end
	end
	if not breakthrough_placed and #BreakthroughOrder > 0 then --if no breakthrough is placed yet and there are still some breakthroughs available
		lat, long = GenerateMarsScreenPoI("anomaly")
		local obj = PlaceObjectIn("PlanetaryAnomaly", MainMapID, {
			display_name = T(11234, "Planetary Anomaly"),
			longitude = long,
			latitude = lat,
			reward = "breakthrough",
		})
		num = num + 1
	end
	local function CenterOnSpawnedAnomaly()
		MarsScreenMapParams.latitude = lat
		MarsScreenMapParams.longitude = long
		OpenPlanetaryView()
	end

	AddOnScreenNotification("NewPlanetaryAnomalies", CenterOnSpawnedAnomaly, {count = num})
end

function PlanetaryAnomalies:CopyMove(other)
	CopyMoveClassFields(other, self,
		{
			"next_anomaly_day",
			"next_anomaly_interval",
		})
end
