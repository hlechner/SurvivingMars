DefineClass.SpawnsAnomalyOnGameInit = {
	__parents = { "Object" },	
	properties = {
		{ template = true, category = "Anomaly", name = T(1000037, "Name"), id = "anomaly_name", editor = "text", default = "", translate = true},
		{ template = true, category = "Anomaly", name = T(1000017, "Description"), id = "anomaly_description", editor = "text", default = "", translate = true},
		
		{ template = true, category = "Anomaly", name = T(3774, "Generate Breakthrough Tech"), id = "is_breakthrough", editor = "bool", default = false},
		{ template = true, category = "Anomaly", name = T(13604, "Revealed"), id = "anomaly_revealed", editor = "bool", default = false},
		{ template = true, category = "Anomaly", name = T(3775, "Sequence List"), id = "sequence_list", default = "", editor = "dropdownlist", items = function() return table.map(DataInstances.Scenario, "name") end, },
		{ template = true, category = "Anomaly", name = T(5, "Sequence"), id = "sequence", editor = "dropdownlist", items = function(self) return self.sequence_list == "" and {} or table.map(DataInstances.Scenario[self.sequence_list], "name") end, default = "", help = "Sequence to start when the anomaly is scanned" },
		{ template = true, category = "Anomaly", name = T(8696, "Expiration Time"), id = "expiration_time", editor = "number", default = 0, scale = const.HourDuration, help = "If > 0 the anomaly will expire and disappear in this many hours." },
	},
}

function SpawnsAnomalyOnGameInit:GameInit()
	local map_id = self:GetMapID()
	local pos = self:GetPos()

	local marker = PlaceObjectIn("SubsurfaceSpecialAnomalyMarker", map_id)
	marker.display_name = self.anomaly_name ~= "" and self.anomaly_name or nil
	marker.description = self.anomaly_description ~= "" and self.anomaly_description or nil
	marker.sequence = self.sequence
	marker.sequence_list = self.sequence_list ~= "" and self.sequence_list or nil
	marker.expiration_time = self.expiration_time
	marker.tech_action = self.is_breakthrough and "breakthrough"
	marker.revealed = self.anomaly_revealed
	marker:SetPos(pos)

	local x, y, unobstructed, obstructed = FindUnobstructedDepositPos(marker)
	if obstructed and not unobstructed then
		marker:SetPos(x, y, const.InvalidZ)
	end

	local city = GetCity(marker)
	local sector = GetMapSectorXY(city, x, y)

	if sector then
		sector:RegisterDeposit(marker)
	end
end
