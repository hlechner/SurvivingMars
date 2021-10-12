GlobalVar("MapLowestZ", {})
GlobalVar("MapHighestZ", {})

local function FillMapExtremeValues(map_id)
	local map_data = ActiveMaps[map_id]
	if not MapLowestZ[map_id] and not map_data.IsPrefabMap then
		local tavg, tmin, tmax = GetTerrainByID(map_id):GetAreaHeight()
		MapLowestZ[map_id] = tmin
		MapHighestZ[map_id] = tmax
	end
end

function SavegameFixups.Elevation_Multimap()
	MapLowestZ = {}
	MapHighestZ = {}
	FillMapExtremeValues(MainMapID)
end

function OnMsg.NewMapLoaded(map_id)
	FillMapExtremeValues(map_id)
end

function OnMsg.PreSwitchMap(prev_map_id, map_id)
	FillMapExtremeValues(map_id)
end

----- MinimumElevationMarker is used to determine lowest point on map

GlobalVar("there_can_be_only_one_height_marker", false)

DefineClass.MinimumElevationMarker = {
	__parents = { "EditorMarker" },
}

function MinimumElevationMarker:Init()
	if there_can_be_only_one_height_marker then
		print("warning!, this map already has an elevation marker!")
	end
	if editor.Active == 1 then
		self:EditorTextUpdate(true)
	end
end

function MinimumElevationMarker:Done()
	if there_can_be_only_one_height_marker == self then
		there_can_be_only_one_height_marker = nil
	end
end

function MinimumElevationMarker:GameInit()
	if there_can_be_only_one_height_marker then
		print("Killing extra MinimumElevationMarkers!")
		DoneObject(self)
	end
	local map_id = self:GetMapID()
	if MapLowestZ[map_id] == max_int then
		MapLowestZ[map_id] = self:GetVisualPos():z()
	end
	there_can_be_only_one_height_marker = self
end

function GetElevation(pos, map_id)
	return pos:z() and (Max(pos:z() - MapLowestZ[map_id], 0) / guim) or 0
end
