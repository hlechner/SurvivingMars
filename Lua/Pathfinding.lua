function GetRandomPassable(city)
	local pfClass = 0
	city = city or MainCity
	local seed = city:Random()
	local realm = GetRealm(city)
	return realm:GetRandomPassablePoint(seed)
end

function GetRandomPassableAwayFromBuilding(city)
	local pfClass = 0
	city = type(city) ~= "number" and city or MainCity --backward compat, first arg used to be a number
	local seed = city:Random()
	local map_id = city.map_id
	local object_hex_grid = GetObjectHexGrid(city)
	local buildable_grid = GetBuildableGrid(city)
	local realm = GetRealm(city)
	local filter = function(x, y)
		return buildable_grid:IsBuildableZone(x, y) and not IsPointNearBuilding(object_hex_grid, x, y)
	end
	return realm:GetRandomPassablePoint(seed, pfClass, filter)
end

GetRandomPassableAwayFromLargeBuilding = GetRandomPassableAwayFromBuilding -- compatibility

local UnbuildableZ = buildUnbuildableZ()

local function HexFindBuildableAround(object_hex_grid, buildable_grid, q, r, ...)
	return HexGridFindBuildable(q, r, object_hex_grid, buildable_grid, UnbuildableZ, ...)
end

function FindBuildableAround(object_hex_grid, buildable_grid, x, y, ...)
	local q, r = WorldToHex(x, y)
	local bq, br, depth = HexFindBuildableAround(object_hex_grid.grid, buildable_grid.z_grid, q, r, ...)
	if not bq then return end
	local x, y = HexToWorld(bq, br)
	return x, y, depth
end

function FindBuildableAreaAround(object_hex_grid, buildable_grid, position, angle, shape)
	local original_z = false

	local shape_pos_filter = function(x, y)
		local z = buildable_grid:GetZ(x, y)
		original_z = original_z or z
		if z == UnbuildableZ or z ~= original_z then
			return false
		end

		local blds = object_hex_grid and object_hex_grid:GetBuildObstructions(x, y) or empty_table
		if #blds > 0 then 
			return false
		end
		
		return true
	end

	local filter = function(q, r)
		local pos = point(HexToWorld(q, r))
		local validated = ValidateEachShapeHexPos(shape, pos, angle, shape_pos_filter)
		return validated ~= true
	end

	local q, r = WorldToHex(position)
	local bq, br, depth = HexGridFindBuildable(q, r, object_hex_grid.grid, buildable_grid.z_grid, UnbuildableZ, filter)
	if not bq then return end
	local x, y = HexToWorld(bq, br)
	return x, y, depth
end

function IsInMapPlayableArea(map_id, x, y)
	if not x then
		return
	elseif not y then
		x, y = x:xy()
	end

	local terrain = GetTerrainByID(map_id)
	local width, height = terrain:GetMapSize()
	local map_data = ActiveMaps[map_id]
	local border = map_data.PassBorder or 0
	local within_xy = x >= border and x < width - border and y >= border and y < height - border

	if within_xy then
		local range = map_data.playable_height_range
		if range and range.from < range.to then
			local z = terrain:GetHeight(x, y)
			return z >= range.from * guim and z <= range.to * guim
		else
			return true
		end
	else
		return false
	end
end

function IsTerrainFlatForPlacement(buildable_grid, shape, pos, angle)
	assert(buildable_grid)
	local original_z = false

	local shape_pos_filter = function(x, y)
		local z = buildable_grid:GetZ(x, y)
		original_z = original_z or z
		if z == UnbuildableZ or z ~= original_z then
			return false
		end
		return true
	end

	return ValidateEachShapeHexPos(shape, pos, angle, shape_pos_filter)
end

function GetPlayableAreaNearby(game_map, position, max_radius, min_radius, filter)
	local map_id = game_map.map_id
	local terrain = game_map.terrain
	local map_data = ActiveMaps[map_id]
	local range = map_data.playable_height_range
	filter = filter or function(x, y) return true end

	local _filter = function(x, y)
		local range = map_data.playable_height_range
		if range and range.from < range.to then
			local z = terrain:GetHeight(x, y)
			return z >= range.from * guim and z <= range.to * guim and filter(x, y)
		else
			return filter(x, y)
		end
	end

	return game_map.realm:GetPassablePointNearby(position, 0, max_radius or 0, min_radius or 0, _filter)
end

function GetRandomPassableAroundOnMap(map_id, center, max_radius, min_radius, random, filter, ...)
	local pfClass = 0
	min_radius = min_radius or 0
	random = random or SessionRandom
	local seed = random:Random()
	local realm = GetRealmByID(map_id)
	return realm:GetRandomPassablePoint(center, max_radius, min_radius, seed, pfClass, filter, ...)
end

function GetRandomPassableAround(center, max_radius, min_radius, random, filter, ...)
	local map_id = IsPoint(center) and MainMapID or center:GetMapID()
	return GetRandomPassableAroundOnMap(map_id, center, max_radius, min_radius, random, filter, ...)
end

--------------------------------------------

if FirstLoad then
	PathCaches = {}
end

function OnMsg.ChangeMap()
	PathCaches = {}
end

function OnMsg.MapUnload(map_id)
	table.remove_value(PathCaches, map_id)
end

function PathLenCacheValid(map_id)
	local path_cache = PathCaches[map_id]
	if path_cache then
		local game_map = GetGameMapByID(map_id)
		local pass_id = game_map.terrain:GetPassId()
		path_cache.pass_id = pass_id
	end
end

function PathLenCached(map_id, pt1, pfclass, pt2)
	if lessthan(pt1, pt2) then
		pt1, pt2 = pt2, pt1
	end

	local dist
	local key = xxhash64(pt1, pt2, pfclass)
	local game_map = GetGameMapByID(map_id)
	local pass_id = game_map.terrain:GetPassId()
	local path_cache = PathCaches[map_id]

	if not path_cache or path_cache.pass_id ~= pass_id then
		if path_cache then
			-- print("reset pass_id", pass_id, "hits", path_cache.hits, "misses", table.count(path_cache.lengths or empty_table))
		end
		path_cache = {
			pass_id = pass_id,
			lengths = {},
			hits = 0,
		}
		PathCaches[map_id] = path_cache
	else
		dist = path_cache.lengths[key]
	end

	if dist == nil then
		local has_path, len = game_map.realm:PosPathLen(pt1, pfclass, pt2)
		dist = has_path and len or false
		path_cache.lengths[key] = dist
	else
		path_cache.hits = path_cache.hits + 1
	end

	return not not dist, dist or 0
end
