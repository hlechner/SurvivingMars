
-----------------------------------------------------------
--RCRovers will be spawned on the map for each such marker
-----------------------------------------------------------
DefineClass.RCRoverMarker = {
	__parents = { "EditorMarker" },
}

function OnMsg.ChangeMapDone(map_id)
	local realm = #map_id > 0 and GetRealmByID(map_id) or false
	if realm then
		realm:MapForEach("map",
			"RCRoverMarker",
			function(marker)
				local p = realm:GetPassablePointNearby(marker:GetPos(), RCRover.pfclass)
				if p then
					local r = PlaceObjectIn("RCRover", map_id)
					r:SetPos(p)
				end
		end)
	end
end
