GlobalVar("LandscapeGrid", false)
GlobalVar("LandscapeLastMark", 0)
GlobalVar("LandscapeMark", 0)
GlobalVar("Landscapes", {})

local UnbuildableZ = buildUnbuildableZ()

function ResetLandscapeGrid(map_id)
	map_id = map_id or ActiveMapID
	local game_map = GameMaps[map_id]
	local landscape_grid = game_map.landscape_grid

	game_map.buildable.GetZ = function(self, q, r)
		if Landscape_Check(landscape_grid, q, r, true) then
			return UnbuildableZ
		end
		return BuildableGrid.GetZ(self, q, r)
	end

	hr.RenderLandscape = 0
	if game_map.hex_width == 0 or game_map.hex_height == 0 then
		return
	end
	if not Landscape_IsLandscapeGrid(landscape_grid) then
		local grid = NewGrid(game_map.hex_width, game_map.hex_height, 32, 0)
		if landscape_grid then
			grid:copy(landscape_grid)
		end
		landscape_grid = grid
	end
	Landscape_SetGrid(landscape_grid)
	hr.RenderLandscape = next(Landscapes) and 1 or 0
end

function OnMsg.DoneMap()
	hr.RenderLandscape = 0
	Landscape_SetGrid(false)
end

function OnMsg.NewMap()
	ResetLandscapeGrid()
end

SavegameFixups.ResetLandscapeGrid = ResetLandscapeGrid
SavegameFixups.MultimapLandscaping = function()
	for _,landscape in pairs(Landscapes) do
		landscape.grid = ActiveGameMap.landscape_grid
		landscape.map_id = MainMapID
	end
end

local function LandscapeFixProblems()
	for mark, landscape in pairs(Landscapes) do
		if not landscape.site then
			LandscapeDelete(landscape)
		end
	end
end

function OnMsg.PostLoadGame()
	LandscapeFixProblems()
	ResetLandscapeGrid()
end

function OnMsg.OnPassabilityChanged(rbox, map_id)
	local map_id = map_id or ActiveMapID
	local game_map = GameMaps and GameMaps[map_id]
	if Landscapes and game_map and game_map.landscape_grid then
		Landscape_BlockPass(Landscapes, game_map.landscape_grid, rbox)
	end
end

function LandscapeMarkBuildable(map_id, pt)
	local buildable = GameMaps[map_id].buildable
	return BuildableGrid.GetZ(buildable, WorldToHex(pt)) ~= UnbuildableZ
end

function GetLandscapedTextureType(map_id)
	return "DomeDemolish"
end

function LandscapeMarkStart(map_id, pt)
	local landscape = Landscapes[LandscapeMark]
	if not landscape then
		local mark0 = LandscapeLastMark
		local mark = mark0 + 1
		while Landscapes[mark] do
			mark = mark + 1
			if mark == const.LandscapeMaxId then
				mark = 1
			end
			assert(mark ~= mark0)
			if mark == mark0 then
				return
			end
		end
		LandscapeMark = mark
		LandscapeLastMark = mark
		landscape =  {
			hexes = 0,
			primes = 0,
			mark = mark,
			accum = 0,
			bbox = box(),
			pass_bbox = false,
			apply_block_pass = false,
			volume = 0,
			material = 0,
			hex_radius = 0,
			volume_delta = 0,
			changed = false,
			collision_objs = setmetatable({}, weak_keys_meta),
			offset_objs = setmetatable({}, weak_keys_meta),
			site = false,
			texture_type = GetLandscapedTextureType(map_id),
			texture_cover = 75,
			grid = GameMaps[map_id].landscape_grid,
			map_id = map_id,
		}
		Landscapes[mark] = landscape
		hr.LandscapeCurrentMark = mark
		hr.RenderLandscape = 1
	end
	landscape.height = GetTerrainByID(map_id):GetHeight(pt)
	landscape.start = pt
	return landscape
end

function LandscapeMarkCancel()
	local landscape = Landscapes[LandscapeMark]
	if not landscape then
		return
	end
	local count, primes, bbox = Landscape_MarkErase(LandscapeMark, landscape.bbox, landscape.grid, true)
	landscape.bbox = bbox
	landscape.primes = primes
	return count
end

function LandscapeMarkSmooth(test, obstruct_handles, obstruct_marks, handle_filter, ...)
	local landscape = Landscapes[LandscapeMark]
	if not landscape or landscape.primes == 0 then
		return 0
	end
	local game_map = GameMaps[landscape.map_id]
	test = test or false
	local success, hexes, bbox = Landscape_MarkSmooth(landscape, landscape.grid, game_map.object_hex_grid.grid, test, obstruct_handles, obstruct_marks, handle_filter, ...)
	landscape.bbox = Extend(landscape.bbox, bbox)
	landscape.hexes = hexes
	
	local volume, material = Landscape_GetVolume(landscape, landscape.grid, const.Terraforming.WasteRockPerHexCube)
	landscape.volume = volume
	landscape.material = material
	
	return success
end

function LandscapeMarkEnd()
	LandscapeMark = 0
	hr.LandscapeCurrentMark = 0
end

local ClearCachedZ = CObject.ClearCachedZ
local GetVisualPosXYZ = CObject.GetVisualPosXYZ
local IsValidZ = CObject.IsValidZ
local SetPos = CObject.SetPos
local SetPosAndNormalOrientation = CObject.SetPosAndNormalOrientation
local efVisible = const.efVisible
local efCollision = const.efCollision
local ClearEnumFlags = CObject.ClearEnumFlags
local SetEnumFlags = CObject.SetEnumFlags
local GetEnumFlags = CObject.GetEnumFlags
local IsKindOf = IsKindOf
local IsValid = IsValid

local function AdjustObjZ(obj, offsets)
	local collision = GetEnumFlags(obj, efCollision) ~= 0
	assert(not collision or GetEnumFlags(obj, efVisible) == 0)
	if IsValidZ(obj) then
		local dz = offsets[obj] or 0
		local x, y = GetVisualPosXYZ(obj)
		SetPos(obj, x, y, GetTerrain(obj):GetHeight(x, y) + dz)
	else
		ClearCachedZ(obj)
	end
	if collision then
		SetPosAndNormalOrientation(obj)
	end
end

local function CollectOffsets(obj, offsets)
	if not IsValidZ(obj) then
		return
	end
	if IsKindOf(obj, "Deposit") then
		offsets[obj] = 10
		return
	end
	local x, y, z = GetVisualPosXYZ(obj)
	local dz = z - GetTerrain(obj):GetHeight(x, y)
	if dz ~= 0 then
		offsets[obj] = dz
	end
end

local foreach_params_collision = {
	collections = true,
	enum_flags = const.efCollision + const.efVisible,
	reject = "Unit",
}

local function CollectObjs(obj, objs)
	objs[obj] = true
end

function LandscapeProgressInit(landscape)
	 -- first call of Landscape_Progress will init skip hexes
	local bbox = Landscape_Progress(landscape, landscape.grid)
	landscape.pass_bbox = bbox:grow(const.GridSpacing)
	return landscape.pass_bbox
end

function LandscapeProgressStep(landscape, forced)
	local remaining = landscape.volume - landscape.accum
	local volume_delta = Min(landscape.volume_delta, remaining)
	if volume_delta == 0 then
		return
	end
	local min_delta = Min(remaining, landscape.volume / 100)
	--print(volume_delta, "/", min_delta, "|",  landscape.accum, "/", landscape.volume)
	if not forced and volume_delta < min_delta then
		-- skip progress for small volume deltas and wait to accum
		return
	end
	if not landscape.changed then
		Landscape_ForEachObject(landscape, landscape.grid, foreach_params_default, CollectOffsets, landscape.offset_objs)
	end
	local changed = Landscape_Progress(landscape, landscape.grid, volume_delta)
	if not changed or changed:IsEmpty() then
		return
	end
	local collected = Landscape_ForEachObject(landscape, landscape.grid, foreach_params_collision, CollectObjs, landscape.collision_objs)
	if collected > 0 or not landscape.changed then
		landscape.changed = landscape.changed or changed
		local realm = GetRealmByID(landscape.map_id)
		realm:SuspendPassEdits(landscape)
		for obj in pairs(landscape.collision_objs) do
			if IsValid(obj) then
				ClearEnumFlags(obj, efVisible)
			end
		end
		if not landscape.pass_bbox then
			landscape.pass_bbox = changed:grow(const.GridSpacing)
			if landscape.apply_block_pass then
				GetTerrainByID(landscape.map_id):RebuildPassability(landscape.pass_bbox)
			end
		end
		realm:ResumePassEdits(landscape)
	end
	landscape.volume_delta = 0
	landscape.accum = Min(landscape.accum + volume_delta, landscape.volume)
	Landscape_ForEachObject(landscape, landscape.grid, foreach_params_default, AdjustObjZ, landscape.offset_objs)
	FlightCaches[landscape.map_id]:OnHeightChanged()
	return true
end

function LandscapeDamageSoil(map_id, mark)
end

function LandscapeFixBuildable(landscape)
	local game_map = GameMaps[landscape.map_id]
	local city = Cities[landscape.map_id]
	Landscape_FixBuildable(landscape, landscape.grid, game_map.buildable.z_grid, UnbuildableZ, guim/3)
	city:UpdateBuildableRatio(HexStoreToWorld(landscape.bbox, const.GridSpacing))
	BumpDroneUnreachablesVersion()
end

local function LandscapeDelete(landscape)
	local mark = landscape.mark
	
	local realm = GetRealmByID(landscape.map_id)
	if landscape.changed or landscape.pass_bbox then
		realm:SuspendPassEdits(landscape)
	end
	
	if landscape.changed then
		for obj in pairs(landscape.collision_objs) do
			if IsValid(obj) then
				SetEnumFlags(obj, efVisible)
			end
		end
		LandscapeDamageSoil(landscape.map_id, mark)
		LandscapeFixBuildable(landscape)
		
		local invalidate = hr.TerrainDebugDraw == 1 and DbgLastBuildableColors
		DbgLastBuildableGrid = false
		if invalidate then
			DbgToggleBuildableGrid()
		end
	end
	
	Landscapes[mark] = nil
	hr.RenderLandscape = next(Landscapes) and 1 or 0
	Landscape_MarkErase(mark, landscape.bbox, landscape.grid)
	
	if landscape.pass_bbox then
		GetTerrainByID(landscape.map_id):RebuildPassability(landscape.pass_bbox)
	end

	if landscape.changed or landscape.pass_bbox then
		realm:ResumePassEdits(landscape)
	end
end

function LandscapeProgress(mark, volume_delta, volume_max)
	local landscape = Landscapes[mark]
	if not landscape then
		return
	end
	if volume_delta then
		if volume_max then
			volume_delta = MulDivRound(landscape.volume, volume_delta, volume_max)
		end
		landscape.volume_delta = landscape.volume_delta + volume_delta
	end
	LandscapeProgressStep(landscape)
end

function LandscapeCheck(landscape_grid, ...)
	return Landscape_Check(landscape_grid, ...)
end

function LandscapeFinish(mark)
	local landscape = Landscapes[mark]
	if not landscape then
		return
	end
	LandscapeProgressStep(landscape, true)
	LandscapeChangeTerrain(mark)
	LandscapeDelete(landscape)
end

----

foreach_params_default = {
	reject = "FlyingObject"
}

local foreach_params_decals = {
	enum_flags = const.efBakedTerrainDecal,
	reject = "ToxicPoolDecal, GeyserObject",
}
local remove_classes = "WasteRockObstructor, Deposition"
local except_classes = "BaseBuilding, Unit, GridObject, Destlock, FlyingObject"
local foreach_params_no_surf = {
	accept = remove_classes,
	reject = except_classes,
}
local foreach_params_surf = {
	collections = true,
	enum_flags = const.efCollision,
	surfaces = EntitySurfaces.Collision,
	reject = except_classes,
}

function LandscapeForEachObstructor(mark, callback, ...)
	local landscape = Landscapes[mark]
	if not landscape then
		return
	end

	local realm = GetRealmByID(landscape.map_id)
	realm:SuspendPassEdits("LandscapeForEachObstructor")
	Landscape_ForEachObject(landscape, landscape.grid, foreach_params_decals, callback, ...)
	Landscape_ForEachObject(landscape, landscape.grid, foreach_params_no_surf, callback, ...)
	Landscape_ForEachObject(landscape, landscape.grid, foreach_params_surf, callback, ...)
	realm:ResumePassEdits("LandscapeForEachObstructor")
end

local foreach_params_stock = {
	accept = "ResourceStockpileBase",
	reject = "Unit",
}

function LandscapeForEachStockpile(mark, callback, ...)
	local landscape = Landscapes[mark]
	if not landscape then
		return
	end
	
	local passed = {}
	local function filter_parent(o, ...)
		if IsValid(o) and not passed[o] and o:GetParent() == nil and IsKindOf(o, "DoesNotObstructConstruction") then
			passed[o] = true
			callback(o, ...)
		end
	end
	Landscape_ForEachObject(landscape, landscape.grid, foreach_params_stock, filter_parent, ...)
end

local foreach_params_unit = {
	accept = "Unit",
}
function LandscapeForEachUnit(mark, callback, ...)
	local landscape = Landscapes[mark]
	if not landscape then
		return
	end
	
	local passed = {}
	local function filter_embark(o, ...)
		if IsValid(o) and not passed[o] and o.command ~= "Embark" then
			passed[o] = true
			callback(o, ...)
		end
	end
	Landscape_ForEachObject(landscape, landscape.grid, foreach_params_unit, callback, ...)
end

local exclude_terrains = { "Regolith", "Regolith_02", "Spider" }

function LandscapeChangeTerrain(mark, perc)
	local landscape = Landscapes[mark]
	if not landscape or (not perc and landscape.accum == 0 and not landscape.completed) or not landscape.texture_type then
		return
	end
	perc = perc or nil
	local noise_max, noise_grid
	local noise_obj = landscape.texture_pattern and DataInstances.NoisePreset[landscape.texture_pattern]
	if noise_obj then
		noise_max = noise_obj.Max
		noise_grid = noise_obj:GetNoise(256, xxhash(landscape.bbox))
	end
	local inv = Landscape_SetTerrainType(landscape, landscape.grid, exclude_terrains, noise_max, noise_grid, perc)
	if noise_grid then
		noise_grid:free()
	end
	GetTerrainByID(landscape.map_id):InvalidateType(inv)
	return inv
end

----

function LandscapeForEachHex(map_id, param, callback, ...)
	local mark, bbox, landscape_grid
	if IsBox(param) then
		-- enum any landscape in a specific region
		bbox = HexWorldToStore(param)
		mark = -1
		landscape_grid = GameMaps[map_id].landscape_grid
	else
		local landscape = Landscapes[param] or param
		if not landscape then
			return
		end
		assert(landscape.map_id == map_id) -- If these are different we're trying to do something weird
		
		-- enum a specific landscape in its region
		mark = landscape.mark
		bbox = landscape.bbox
		landscape_grid = landscape.grid
	end
	return Landscape_ForEachHex(mark, bbox, landscape_grid, callback, ...)
end