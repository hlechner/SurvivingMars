DefineClass.LandscapeClearWasteRockBuilding = {
	__parents = { "LandscapeBuilding" },
	construction_mode = "landscape_clearwasterock",
	max_boundary = 80,
}

DefineClass.LandscapeClearWasteRockDialog = {
	__parents = { "LandscapeConstructionDialog" },
	mode_name = "landscape_clearwasterock",
}

DefineClass.LandscapeClearWasteRockController = {
	__parents = { "LandscapeConstructionController" },
	
	brush_radius = 15*guim,
	brush_radius_step = 5*guim,
	brush_radius_min = 5*guim, --m
	brush_radius_max = 45*guim, --m
}

function LandscapeClearWasteRockController:Mark(test)
	LandscapeMarkCancel()
	LandscapeMarkClearWasteRock(self:GetMapID(), self.last_pos, self.last_undo_pos, self.brush_radius, test)
	local success = self:ValidateMark(true)
	local ready = success and self.last_undo_pos and not IsPlacingMultipleConstructions()
	return success, ready
end

function LandscapeClearWasteRockController:ValidateMark(test)
	local landscape = Landscapes[LandscapeMark]
	if not landscape then
		return
	end
	local success = LandscapeMarkSmooth(test, self.obstruct_handles, self.obstruct_marks)
	landscape.volume = 0
	landscape.material = 0
	return success
end

function LandscapeMarkClearWasteRock(map_id, pt1, pt0, radius, test)
	local landscape = Landscapes[LandscapeMark]
	if not landscape then
		return
	end
	if not pt0 then
		test = true
		pt0 = pt1
	end
	local game_map = GameMaps[map_id]
	local h0 = landscape.height
	local primes, bbox = Landscape_MarkLine{
		map_id = map_id,
		mark = LandscapeMark, 
		pos0 = pt0, 
		pos1 = pt1, 
		radius = radius, 
		landscape_grid = game_map.landscape_grid,
		object_hex_grid = game_map.object_hex_grid.grid,
		test = test,
	}
	if not primes then
		return
	end
	landscape.bbox = Extend(landscape.bbox, bbox)
	landscape.primes = landscape.primes + primes
	landscape.texture_type = nil
	return true
end
