-- max height delta within a hex for it to be even considered for building
g_NCF_FlatThreshold = 2*guim

-- max object surface height to be checked for collision with a hex
g_NCF_MaxSurfaceHeight = 30*guim
g_NCF_MaxSurfaceError = 3*guim
g_NCF_SurfaceTypes = EntitySurfaces.Collision
g_NCF_EnumFlags = const.efCollision
g_NCF_IgnoreGameFlags = const.gofTemporalConstructionBlock

-- areas 10x10 hexes and smaller tolerate height deltas up to 2 m
-- areas 100x100 hexes and larger tolerate height deltas up to 30 guim
-- areas between 10x10 and 100x100 hexes tolerate a height delta somewhere in between (linearly interpolated)

g_NCF_FlatThresholdAreaMin = 5
g_NCF_FlatThresholdAreaMinHeightDelta = 150*guic
g_NCF_FlatThresholdAreaMax = 100
g_NCF_FlatThresholdAreaMaxHeightDelta = 500*guic
g_NCF_MinArea = 50

function buildUnbuildableZ() -- workaround problem with storing 64-bit numbers in compiled chunks
	return 2^16 - 1
end

local UnbuildableZ = buildUnbuildableZ()

DefineClass.BuildableGrid = {
	__parents = { "InitDone" },
	z_grid = false,
}

function BuildableGrid:Build(realm, width, height, map_data)
	local invalidate = hr.TerrainDebugDraw == 1 and DbgLastBuildableColors

	local buildable_hex_z = NewGrid(width, height, 16, UnbuildableZ)
	local buildable_z = NewGrid(width, height, 16, UnbuildableZ)

	local border = map_data.PassBorder
	local range = map_data.visible_height_range

	local st = GetPreciseTicks()
	realm:InitBuildableGrid{
		buildable_grid = buildable_hex_z,
		unbuildable_z = UnbuildableZ,
		flat_threshold = g_NCF_FlatThreshold,
		max_surface_height = g_NCF_MaxSurfaceHeight,
		max_surface_error = g_NCF_MaxSurfaceError,
		surface_types = g_NCF_SurfaceTypes,
		enum_flags = g_NCF_EnumFlags,
		ignore_game_flags = g_NCF_IgnoreGameFlags,
		map_border = border,
		map_min_height = range and range.from*guim or 0,
		map_max_height = range and range.to*guim or UnbuildableZ,
	}

	ProcessBuildableGrid{
		buildable_grid = buildable_hex_z,
		buildable_z = buildable_z,
		unbuildable_z = UnbuildableZ,
		minsize = g_NCF_FlatThresholdAreaMin,
		maxsize = g_NCF_FlatThresholdAreaMax,
		mindelta = g_NCF_FlatThresholdAreaMinHeightDelta,
		maxdelta = g_NCF_FlatThresholdAreaMaxHeightDelta,
		minarea = g_NCF_MinArea,
	}

	local time_spent = GetPreciseTicks() - st
	if time_spent > 1000 then
		print("Buildable grid computing too slow! Took", time_spent)
	end

	self.z_grid = buildable_z

	DbgLastBuildableGrid = false
	if invalidate then
		DbgToggleBuildableGrid()
	end
end

function BuildableGrid:GetZ(q, r)
	return self.z_grid:get(q+r/2, r) -- aka HexToStorage in C++ terms
end

function BuildableGrid:IsBuildable(q, r)
	return self:GetZ(q, r) ~= UnbuildableZ
end

function BuildableGrid:IsBuildableZone(...)
	local q, r = WorldToHex(...)
	return self:IsBuildable(q, r)
end

function GetBuildableZ(q, r)
	return ActiveGameMap.buildable:GetZ(q, r)
end

function IsBuildableZone(...) -- pos or x,y 
	return ActiveGameMap.buildable:IsBuildableZone(...)
end

function IsBuildableZoneQR(q, r) --q, r
	return ActiveGameMap.buildable:IsBuildable(q, r)
end

--[=[ ProcessBuildableGrid orig Lua implementation
function ProcessBuildableGrid_Lua(buildable_hex_z)
	PauseInfiniteLoopDetection("RecalcBuildableGrid")
	local buildable_z = NewGrid(HexMapWidth, HexMapHeight, 16, UnbuildableZ)
	local visited_grid = NewGrid(HexMapWidth, HexMapHeight, 1, 0)
	local minsize = g_NCF_FlatThresholdAreaMin
	local maxsize = g_NCF_FlatThresholdAreaMax
	local A = g_NCF_FlatThresholdAreaMinHeightDelta
	local B = g_NCF_FlatThresholdAreaMaxHeightDelta - g_NCF_FlatThresholdAreaMinHeightDelta
	local C = maxsize - minsize
	local function CalcMaxDelta(hexes)
		local size = Clamp(sqrt(hexes) + 1, minsize, maxsize)
		return A + MulDivRound(size - minsize, B, C)
	end
	
	--DbgClear()
	local all_zones, valid_zones = 0, 0
	local i = 0
	for x = 0, HexMapWidth - 1 do
		for y = 0, HexMapHeight - 1 do
			local av_z = buildable_hex_z:get(x, y)
			if av_z ~= UnbuildableZ and visited_grid:get(x, y) == 0 then
				all_zones = all_zones + 1
				i = i + 1
				local q = x - y/2
				local r = y
				-- first pass
				local max, min = av_z, av_z
				local hexes = 1
				local max_delta
				HexGridFloodFill(visited_grid, q, r, const.hgfRestoreVisited, function(nq, nr)
					local z = buildable_hex_z:get(nq+nr/2, nr)
					if z == UnbuildableZ then
						return
					end
					if z < min then
						max_delta = max_delta or CalcMaxDelta(hexes)
						if z < max - max_delta then
							return
						end
						min = z
					elseif z > max then
						max_delta = max_delta or CalcMaxDelta(hexes)
						if z > min + max_delta then
							return
						end
						max = z
					end
					max_delta = false
					av_z = av_z + z
					hexes = hexes + 1
					return true
				end)
				assert(av_z >= 0, "Int overflow")
				av_z = av_z / hexes
				assert(av_z < UnbuildableZ)
				-- second pass
				max_delta = max_delta or CalcMaxDelta(hexes)
				local new_hexes = 1
				local visited = HexGridFloodFill(visited_grid, q, r, const.hgfQueryList, function(nq, nr)
					local z = buildable_hex_z:get(nq+nr/2, nr)
					if z == UnbuildableZ or 2 * abs(z - av_z) > max_delta then
						return
					end
					new_hexes = new_hexes + 1
					if new_hexes > hexes then
						max_delta = CalcMaxDelta(new_hexes)
					end
					return true
				end)
				--[[
				DbgAddVector(point(HexToWorld(q, r)), Clamp((visited and #visited) * guim, 10*guim, 300*guim))
				DbgAddText(print_format(i, "z", av_z, "/", visited and #visited, "d", max_delta, visited and #visited > g_NCF_MinArea), point(HexToWorld(q, r)))
				--]]
				assert(visited_grid:get(x, y) ~= 0)
				if visited and #visited > g_NCF_MinArea then
					for i = 1, #visited do
						local q, r = DecodePoint(visited[i])
						buildable_z:set(q+r/2, r, av_z)
					end
					valid_zones = valid_zones + 1
				end
			end
		end
	end
	ResumeInfiniteLoopDetection("RecalcBuildableGrid")
	printf("Buildable grid ready: %d/%d valid zones.", valid_zones, all_zones);
	return buildable_z
end
--]=]
