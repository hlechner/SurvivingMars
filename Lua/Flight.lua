GlobalVar("Flight_ObjsToMark", false)
GlobalVar("Flight_ObjToUnmark", false)
GlobalVar("Flight_MarkedObjs", false)
GlobalVar("Flight_MarkThread", false)

GlobalVar("FlyingObjs", {})
GlobalVar("FlightId", 0)

GlobalVar("Flight_CalcId", 0)
GlobalVar("Flight_CalcList", {})

-- don't save these, we can rebuild it
GlobalVar("Flight_Height", false)
PersistableGlobals.Flight_Height = nil
GlobalVar("Flight_OrigHeight", false)
PersistableGlobals.Flight_OrigHeight = nil
GlobalVar("Flight_Traject", false)
PersistableGlobals.Flight_Traject = nil
GlobalVar("Flight_MoveCost", false)
PersistableGlobals.Flight_MoveCost = nil
GlobalVar("Flight_CalcThread", false)
PersistableGlobals.Flight_CalcThread = nil
GlobalVar("Flight_CalcBuffers", {})
PersistableGlobals.Flight_CalcBuffers = nil

DefineClass.Flight = {
	objects_to_mark = false,
	objects_to_unmark = false,
	marked_objects = false,
	mark_thread = false,
	flying_objects = false,
	calc_list = false,
	flight_policy = false,
	max_avoid_height = false,
}

FlightPolicy = {
	Surface = 0,
	Underground = 1,
}

local function GetFlightPolicy(map_id)
	assert(map_id)
	local map_data = ActiveMaps[map_id]
	if map_data.Environment == "Underground" then
		return FlightPolicy.Underground
	else
		return FlightPolicy.Surface
	end
end

local function GetFlightLimits(flight_policy)
	local max_avoid_height = flight_policy == FlightPolicy.Surface and 20*guim or 10*guim
	return max_avoid_height
end

function Flight.new(class, map_id)
	local self = setmetatable({}, class)
	self.flying_objects = {}
	self.calc_list = {}
	self.flight_policy = GetFlightPolicy(map_id)
	self.max_avoid_height = GetFlightLimits(self.flight_policy)
	return self
end

GlobalVar("FlightSystems", false)
function GetFlightSystem(object)
	local map_id = object:GetMapID()
	return FlightSystems[map_id]
end

DefineClass.FlightCache = {
	height = false,
	orig_height = false,
	terrain = false,
	traject = false,
	move_cost = false,
	calc_thread = false,
	calc_buffers = false,
	debug_path = false,
}

function FlightCache.new(class, terrain)
	local self = setmetatable({}, class)
	self.terrain = terrain
	self.calc_buffers = {}
	return self
end

GlobalVar("FlightCaches", false)
PersistableGlobals.FlightCaches = nil

function GetFlightCache(object)
	local map_id = object:GetMapID()
	return FlightCaches[map_id]
end

function SavegameFixups.MultimapFlight()
	FlightSystems = {}
	local flight_system = Flight:new(ActiveMapID)
	flight_system.objects_to_mark = Flight_ObjsToMark
	flight_system.objects_to_unmark = Flight_ObjToUnmark
	flight_system.marked_objects = Flight_MarkedObjs
	DeleteThread(Flight_MarkThread)
	flight_system.mark_thread = false
	flight_system.flying_objects = FlyingObjs
	flight_system.calc_list = Flight_CalcList
	FlightSystems[ActiveMapID] = flight_system
	
	FlightCaches = {}
	FlightCaches[ActiveMapID] = FlightCache:new(GetActiveTerrain())
	Flight_Traject = FlightCaches[ActiveMapID].traject
end

function SavegameFixups.MultimapFlight_AddPolicy()
	for map_id, flight_system in pairs(FlightSystems) do
		flight_system.flight_policy = GetFlightPolicy(map_id)	
		flight_system.max_avoid_height = GetFlightLimits(flight_system.flight_policy)
	end
end

local type_tile = const.TerrainTypeTileSize
local work_step = 16 * type_tile
local mark_step = 16 * type_tile
local grid_scale = const.GridScale
local height_scale = const.TerrainHeightScale
local slope_penality_angle = 30*60 -- corresponds to 1 unit in the cost grid
local slope_penality_tan = MulDivRound(4096, sincos(slope_penality_angle))
local mark_falloff = 40
local max_async_calc_path = 3
local min_async_path_dist = 1000*guim
local unity = 1024
local gravity = 3711
local mark_flags = const.efWalkable + const.efApplyToGrids + const.efCollision
local min_mark_height = 10*guim
local max_mark_height = 100*guim
local InvalidZ = const.InvalidZ
local min_obj_size = 4*guim

local IsValid = IsValid
local IsValidPos = CObject.IsValidPos
local GetEnumFlags = CObject.GetEnumFlags
local IsValidEntity = IsValidEntity
local developer = Platform.developer

if developer then
	GlobalVar("FlightCObjs", {}, weak_keys_meta)
	GlobalVar("Flight_BufferLock", {})
	GlobalVar("Flight_Errors", {})
	PersistableGlobals.FlightCObjs = nil
	PersistableGlobals.Flight_BufferLock = nil
end

Flight_MaxSplineDist = 100*guim
function OnMsg.ClassesBuilt()
	local max_spline_dist = 0
	local min_hover_height = max_int
	ClassDescendants("FlyingObject", function(name, def)
		max_spline_dist = Max(max_spline_dist, def.avg_spline_dist)
		min_hover_height = Min(min_hover_height, def.min_hover_height)
	end)
	min_mark_height = Max(min_hover_height, min_obj_size)
	Flight_MaxSplineDist = max_spline_dist
end

function OnMsg.PersistGatherPermanents(permanents)
	-- avoid trying to save a C function
	permanents["CObject.GetEnumFlags"] = CObject.GetEnumFlags
	permanents["CObject.IsValidPos"] = CObject.IsValidPos
	permanents["IsValidEntity"] = IsValidEntity
	permanents["IsValid"] = IsValid
end

local function Flight_NewGrid(map_width, map_height, step, packing)
	assert(map_width == map_height)
	local work_size = map_width / (step or work_step)
	return grid(work_size, packing or 32)
end

function FlightCache:TrajectMark(...)
	return Flight_MarkPathSpline(self.traject, mark_step, ...)
end
function FlightCache:TrajectUnmark(...)
	return Flight_UnmarkPathSpline(self.traject, mark_step, ...)
end
function FlightCache:TrajectCheck(...)
	return Flight_CheckPathSpline(self.traject, mark_step, ...)
end
function FlightCache:IdleMark(pos, radius)
	return self.traject:AddCircle(1, pos, mark_step, radius)
end
function FlightCache:IdleUnmark(pos, radius)
	return self.traject:AddCircle(-1, pos, mark_step, radius)
end
function FlightCache:IdleCheck(pos, radius)
	return self.traject:CheckCircle(0, pos, mark_step, radius)
end

function FlightCache:OnHeightChanged()
	if not self.orig_height then
		return
	end
	self.height:sub_i(self.orig_height)
	self.terrain:GetHeightGrid(self.orig_height, work_step)
	self.height:add_i(self.orig_height)
	self.move_cost = false
end

local function _Flight_Init(game_map, flight_system, flight_cache)
	local realm = game_map.realm
	local terrain = game_map.terrain
	local map_width, map_height = terrain:GetMapSize()
	if not flight_cache.orig_height then
		flight_cache.orig_height = Flight_NewGrid(map_width, map_height)
		flight_cache.terrain:GetHeightGrid(flight_cache.orig_height, work_step)
	end
	if not flight_cache.height then
		flight_cache.height = flight_cache.orig_height:clone()
		if flight_system.marked_objects then
			for obj in pairs(flight_system.marked_objects) do
				if not flight_system.objects_to_unmark[obj] then
					flight_system.objects_to_mark[obj] = true
				end
			end
		else
			flight_system.objects_to_mark = {}
			realm:MapForEach("map", "attached", false, nil, mark_flags, function(obj) flight_system.objects_to_mark[obj] = true end)
		end
		flight_system.objects_to_unmark = {}
		flight_system.marked_objects = {}
		MarkThreadProc(flight_system, flight_cache)
	end
	if not flight_cache.traject then
		flight_cache.traject = Flight_NewGrid(map_width, map_height, mark_step, 16)
		realm:MapForEach("map", "FlyingObject", function(obj)
			if flight_system.flying_objects[obj] then
				flight_cache:TrajectMark(obj.current_spline, obj.next_spline)
			elseif obj.idle_mark_pos then
				flight_cache:IdleMark(obj.idle_mark_pos, obj.collision_radius)
			end
		end)
	end
end

local function Flight_Init(map_id)
	if ActiveMapID == "PreGame" then return end
	
	FlightSystems = FlightSystems or {}
	FlightCaches = FlightCaches or {}
	
	if not FlightSystems[map_id] then
		FlightSystems[map_id] = Flight:new(map_id)
	end

	if not FlightCaches[map_id] then
		FlightCaches[map_id] = FlightCache:new(GetTerrainByID(map_id))
	end

	_Flight_Init(GameMaps[map_id], FlightSystems[map_id], FlightCaches[map_id])
end

function FlightCache:StartComputeThread(flight_system)
	if IsValidThread(self.calc_thread) then
		return
	end
	self.calc_thread = CreateMapRealTimeThread(function()
		while true do
			local calc = flight_system.calc_list[1]
			if calc then
				local obj, start, finish, id = table.unpack(calc)
				--print("Flight_FindSmoothPath CALC START", id)
				local compute_err, spline_path = Flight_FindSmoothPath(obj, start, finish, true)
				--print("Flight_FindSmoothPath CALC END", id)
				Msg(calc, compute_err, spline_path)
				table.remove(flight_system.calc_list, 1)
			else
				WaitWakeup()
			end
		end
	end)
end

local function FlightPolicySurface_GetMoveCost(height_grid)
	local cost = height_grid:slope(4096 * height_scale, work_step)
	cost:max_i(0, 1)
	cost:div_i(slope_penality_tan, 1)
	cost:add_i(1, 1)
	return cost
end

local function CopyTerrainHeightGrid(map_id)
	local terrain = GetTerrainByID(map_id)
	local map_width, map_height = terrain:GetMapSize()
	local grid = Flight_NewGrid(map_width, map_height)
	terrain:GetHeightGrid(grid, work_step)
	return grid
end

local function GetMaxFlightHeight(min_ground_h, max_ground_h)
	local height_dt = max_ground_h - min_ground_h
	local max_flight_h = min_ground_h + (height_dt / 2)
	return max_flight_h
end

local function FlightPolicyUnderground_MarkObjects(cost_grid, height_grid, marked_objects, min_ground_h, max_ground_h, max_flight_h)
	local cost_divider_approx = 4
	local below_hover_h_approx = 2000
	local radius_increase_approx = 1.5
	local decrease_to_be_passable_approx = 2
	local max_obj_height_approx = max_flight_h / decrease_to_be_passable_approx

	for obj, info in pairs(marked_objects or {}) do
		local x, y, radius, height = table.unpack(info)
		local cost_value, height_value
		local ground_h = height_grid:GetBilinear(x, y, work_step, 0, 1)
		if obj:IsKindOf("BaseBuilding") then
			if height >= max_flight_h then
				height_value = max_obj_height_approx * grid_scale
			else
				height_value = Max(height, max_obj_height_approx) * grid_scale
			end
			cost_value = height_value
		elseif height - ground_h < below_hover_h_approx then
			height_value = Max(min_ground_h, 1) * grid_scale
			cost_value = height_value
		elseif height >= max_flight_h then
			height_value = height_grid:GetBilinear(x, y, work_step, 0, 1) * grid_scale
			cost_value = max_obj_height_approx * grid_scale
		else
			height_value = Min((height / decrease_to_be_passable_approx), max_obj_height_approx) * grid_scale
			cost_value = height_value
		end
		if cost_value and height_value then
			local falloff = MulDivRound(radius, mark_falloff, grid_scale)
			local imprint_radius = (radius * radius_increase_approx) - falloff
			local imprint_falloff = radius * radius_increase_approx
			cost_grid:MaxCircle(cost_value, x, y, work_step, imprint_radius, imprint_falloff)
			height_grid:MaxCircle(height_value, x, y, work_step, radius - falloff, radius)
		end
	end
end

local function FlightPolicyUnderground_MarkLandingSpots(map_id, cost, marked_objects, min_ground_h)
	local msize = GetTerrainByID(map_id):GetMapSize()
	local gsize = cost:size()
	for obj, _ in pairs(marked_objects or {}) do
		if obj:HasMember("landing_slots") then
			for k, slot in pairs(obj.landing_slots) do
				local x = MulDivTrunc(slot.pos:x(), gsize, msize)
				local y = MulDivTrunc(slot.pos:y(), gsize, msize)
				cost:set(x, y, min_ground_h)
			end
		end
	end
end

local function FlightPolicyUnderground_AssignCost(cost, levels_cnt, max_ground_h, max_flight_h)
	cost:normalize_i(1, levels_cnt, 1)
	cost:round_i()
	local increase_all_but_ground_cost_mul = 16
	cost:mul_i(increase_all_but_ground_cost_mul, 1)
	cost:normalize_i(1, levels_cnt, 1)

	local max_flight_h_normalized = DivAsFloats(max_flight_h, max_ground_h)
	local max_flight_h_level = floatfloor((levels_cnt * max_flight_h_normalized) + 0.5)
	local cost_obstacle_value = 0
	
	cost:min_i(max_flight_h_level, 1)
	cost:replace_i(max_flight_h_level, cost_obstacle_value, 1)
end

function FlightCache:GetMoveCost(map_id, force_recalc)
	local cost = self.move_cost
	if not cost or force_recalc then
		Flight_Init(map_id)
		local flight_system = FlightSystems[map_id]
		if flight_system.flight_policy == FlightPolicy.Underground then
			cost = CopyTerrainHeightGrid(map_id)
			local min_ground_h, max_ground_h = cost:minmax(false, 1)
			local max_flight_h = GetMaxFlightHeight(min_ground_h, max_ground_h)
			self.height = self.orig_height:clone()
			FlightPolicyUnderground_MarkObjects(cost, self.height, flight_system.marked_objects, min_ground_h, max_ground_h, max_flight_h)
			FlightPolicyUnderground_MarkLandingSpots(map_id, cost, flight_system.marked_objects, min_ground_h)
			local cost_levels_cnt = 128
			FlightPolicyUnderground_AssignCost(cost, cost_levels_cnt, max_ground_h, max_flight_h)
		else
			cost = FlightPolicySurface_GetMoveCost(self.height)
		end
		self.move_cost = cost
	end
	return self.move_cost
end

function Flight_FindSmoothPath(obj, start, finish, sync)
	local flight_cache = GetFlightCache(obj)
	local flight_system = GetFlightSystem(obj)
	if not sync and IsGameTimeThread() and not IsCloser2D(start, finish, min_async_path_dist) then
		local queue = flight_system.calc_list or {}
		if #queue < max_async_calc_path then
			flight_cache:StartComputeThread(flight_system)
			Flight_CalcId = Flight_CalcId + 1
			local id = Flight_CalcId
			local requested = {obj, start, finish, id}
			if #queue == 0 then
				-- wakeup the async op thread only if no computation is in process (otherwise it would break the async op logic)
				Wakeup(flight_cache.calc_thread)
				flight_system.calc_list = queue
			end
			queue[#queue + 1] = requested
			--print("Flight_FindSmoothPath REQUEST", id)
			local wait_success, compute_err, spline_path = WaitMsg(requested)
			--print("Flight_FindSmoothPath FINISH", id)
			if not wait_success then
				return "failed"
			end
			return compute_err, spline_path
		end
	end

	local map_id = obj:GetMapID()
	local map_data = ActiveMaps[map_id]
	local cost = flight_cache:GetMoveCost(map_id)
	local border = Max(0, map_data.PassBorder - work_step)
	local buffer_idx = sync and 1 or 2
	local buffer = flight_cache.calc_buffers[buffer_idx]
	local terrain = GetTerrain(obj)
	if not buffer then
		local map_width, map_height = terrain:GetMapSize()
		buffer = Flight_NewGrid(map_width, map_height)
		flight_cache.calc_buffers[buffer_idx] = buffer
	end
	
	local buffer_lock
	if developer then
		local map_id = obj:GetMapID()
		Flight_BufferLock[map_id] = Flight_BufferLock[map_id] or {0, 0}
		buffer_lock = Flight_BufferLock[map_id]
		buffer_lock[buffer_idx] = buffer_lock[buffer_idx] + 1
	end

	local excess = 1 + 90*60 / slope_penality_angle
	local compute_err, spline_path = AsyncFindSmoothPath(terrain, obj, start, finish, cost, border, buffer, excess, flight_system.flight_policy)
	
	if developer then
		buffer_lock[buffer_idx] = buffer_lock[buffer_idx] - 1
		assert(buffer_lock[buffer_idx] == 0)
	end
	
	return compute_err, spline_path
end

function MarkThreadProc(flight_system, flight_cache)
	local start_time = GetPreciseTicks()
	local unmarked, marked = 0, 0
	local ObjectHierarchyBSphere = ObjectHierarchyBSphere
	local ObjectHierarchyBBox = ObjectHierarchyBBox
	local MulDivRound = MulDivRound
	local Min, Max = Min, Max
	local unpack = table.unpack
	local mask
	local terrain = flight_cache.terrain
	local map_width, map_height = terrain:GetMapSize()
	local flight_policy = flight_system.flight_policy
	for obj in pairs(flight_system.objects_to_unmark) do
		local info = flight_system.marked_objects[obj]
		assert(info)
		if info then
			local x, y, r = unpack(info)
			for obji, infoi in pairs(flight_system.marked_objects) do
				if obji ~= obj and IsValid(obji) and not flight_system.objects_to_mark[obji] then
					local xi, yi, ri = unpack(infoi)
					if IsCloser2D(x, y, xi, yi, r + ri) then
						flight_system.objects_to_mark[obji] = true
					end
				end
			end
			if flight_policy == FlightPolicy.Surface then
				mask = mask or Flight_NewGrid(map_width, map_height)
				mask:SetCircle(grid_scale, x, y, work_step, r)
			end
			unmarked = unmarked + 1
		end
		flight_system.objects_to_unmark[obj] = nil
		flight_system.marked_objects[obj] = nil
	end
	if flight_policy == FlightPolicy.Surface and mask and not mask:empty() then
		flight_cache.height:mulinv_i(mask)
		mask:mul_i(flight_cache.orig_height)
		flight_cache.height:add_i(mask)
		mask:free()
	end

	for obj in pairs(flight_system.objects_to_mark) do
		if IsValid(obj) and IsValidPos(obj) then
			local info = flight_system.marked_objects[obj]
			local x, y, z, r, h
			if info == nil then
				r, x, y, z = ObjectHierarchyBSphere(obj, mark_flags, true)
				if r > min_obj_size then
					local minx, miny, minz, maxx, maxy, maxz = ObjectHierarchyBBox(obj, mark_flags, true)
					maxx = Min(maxx, x + r)
					minx = Max(minx, x - r)
					maxy = Min(maxy, y + r)
					miny = Max(miny, y - r)
					maxz = Min(maxz, z + r)
					minz = Max(minz, z - r)
					x = (minx + maxx) / 2
					y = (miny + maxy) / 2
					local ground = terrain:GetHeight(x, y)
					if maxz > ground + min_mark_height and minz < ground + max_mark_height then
						h = maxz
						r = Max(maxx - minx, maxy - miny) / 2 + (work_step - 1) / 2
						info = {x, y, r, h}
					end
				end
			elseif info then
				x, y, r, h = unpack(info)
			end
			if info then
				if flight_policy == FlightPolicy.Surface then
					local f = MulDivRound(r, mark_falloff, 100)
					flight_cache.height:MaxCircle(h * grid_scale, x, y, work_step, r - f, r)
				end
				flight_system.marked_objects[obj] = info
				marked = marked + 1
			end
		end
		flight_system.objects_to_mark[obj] = nil
	end
	
	if marked > 0 or unmarked > 0 then
		flight_cache.move_cost = false
	end

	--print("work_time", GetPreciseTicks() - start_time, "marked", marked, "unmarked", unmarked)
end

function OnMsg.DoneGame()
	Flight_Free(true)
end

function OnMsg.NewMapLoaded(map_id)
	Flight_Init(map_id)
end

function OnMsg.NewGame()
	Flight_Free()
end

function OnMsg.PostLoadGame()
	for map_id, flight_system in pairs(FlightSystems) do
		Flight_Init(map_id)
		local flight_cache = FlightCaches[map_id]
		flight_cache:StartComputeThread(flight_system)
		
		for _, obj in ipairs(flight_system.flying_objects) do
			obj:RegisterFlight(true)
		end
	end

	-- Backwards compatibility for running threads
	local flight_cache = FlightCaches[ActiveMapID]
	Flight_Height = flight_cache.height
	Flight_Traject = flight_cache.traject
end

function OnMsg.MapUnload(map_id)
	local flight_system = FlightSystems and FlightSystems[map_id]
	local flying_objects = flight_system and flight_system.flying_objects
	for _, obj in ipairs(flying_objects or {}) do
		obj:UnregisterFlight(true)
	end

	local flight_cache = FlightCaches and FlightCaches[map_id]	
	if flight_cache then
		local calc_thread = flight_cache.calc_thread
		if IsValidThread(calc_thread) then
			DeleteThread(calc_thread)
		end
		FlightCaches[map_id] = nil
	end
	
	if flight_system then
		local mark_thread = flight_system.mark_thread
		if IsValidThread(mark_thread) then
			DeleteThread(mark_thread)
		end
		FlightSystems[map_id] = nil
	end
end

local function MarkThreadStart(map_id)	
	local flight_system = FlightSystems[map_id]
	if IsValidThread(flight_system.mark_thread) then
		Wakeup(flight_system.mark_thread)
		return
	end
	flight_system.mark_thread = CreateGameTimeThread(function()
		Flight_Init(map_id)
		local flight_cache = FlightCaches[map_id]
		while true do
			MarkThreadProc(flight_system, flight_cache)
			WaitWakeup()
		end
	end)
end

local function Flight_IsMarkable(obj)
	return IsValid(obj) and IsValidPos(obj) and GetEnumFlags(obj, mark_flags) ~= 0 and IsValidEntity(obj:GetEntity())
end

function Flight:Mark(obj)
	if not Flight_IsMarkable(obj) or self.objects_to_mark[obj] then
		return
	end
	if self.objects_to_unmark[obj] then
		self.objects_to_unmark[obj] = nil
	end
	if self.marked_objects[obj] then
		return
	end
	self.objects_to_mark[obj] = true
	MarkThreadStart(obj:GetMapID())
end

function Flight:Unmark(obj)
	if self.objects_to_unmark[obj] then
		return
	end
	self.objects_to_mark[obj] = nil
	if not self.marked_objects[obj] then
		return
	end
	self.objects_to_unmark[obj] = true
	MarkThreadStart(obj:GetMapID())
end

function Flight:Remark(obj)
	if not Flight_IsMarkable(obj) then
		return
	end
	if self.marked_objects[obj] then
		self.objects_to_unmark[obj] = true
	end
	self.objects_to_mark[obj] = true
	MarkThreadStart(obj:GetMapID())
end

function FlightCache:GetHeight(mx, my)
	return self.height:GetBilinear(mx, my, work_step, 0, 1)
end

DefineClass.FlyingObject = {
	__parents = { "FXObject", "Object", "CommandObject", "ComponentAttach", "ComponentInterpolation", "UnitRevealDarkness" },
	flags = { cofComponentSound = true, efWalkable = false, efApplyToGrids = false, efCollision = false },
	
	flight_id = 0,
	idle_mark_pos = false,
	
	-- collision params:
	collision = false,
	avoid_max = 8,
	avoid_height = 20*guim,
	collision_radius = 20*guim,
	avoid_class = 0,
	avoid_mask = 0,
	maneuver_time = 4000,
	-- backward compat
	avoid_level = 0,
	avoid_count = 0,
	
	-- move params:
	current_path = false,
	current_spline = false,
	next_spline = false,
	accel_dist = 40*guim,
	decel_dist = 80*guim,
	move_speed = 50*guim,
	min_speed = 4*guim,
	max_yaw_speed = 50*60,
	max_roll_speed = 30*60,
	roll_modifier = 100,
	turn_slow_down = 30,
	pitch_height_adjust = 20*guim,
	pitch_speed_adjust = 50,
	pitch_modifier = 100,
	thrust_max = 40*guim,
	thrust_modifier = 100,
	thrust_frict = 100,
	hover_height = 30*guim,
	min_hover_height = 10*guim,
	step = 8*guim,
	max_sleep = 333,
	auto_landing = false,
	starting_angle_error = 10 * 60,
	
	-- path params:
	start_pos = false,
	start_dir = false,
	start_dir_obj = false,
	end_pos = false,
	end_dir = false,
	dist_to_target = false,
	move_cost = false,
	mass = 4 * unity,
	friction = unity / 3,
	unity = unity,
	target_ref_dist = 256*guim,
	target_min_dist = 32*guim,
	avg_spline_dist = 80*guim,
	tangent = 6,
	max_points = 512,
	complete = true,
	fix_loops = true,
	reach_target = true,
	dont_splinify = false,
}

local DbgSetText = empty_func
local DbgInit = empty_func

function FlyingObject:Init()
	FlightId = FlightId + 1
	self.flight_id = FlightId
	local flight_system = GetFlightSystem(self)
	self.avoid_height = Min(self.avoid_height, flight_system.max_avoid_height)
	DbgInit(self)
	--DbgSetText(self, self.flight_id)
end

function FlyingObject:Done()
	--[[
	assert(not self.current_spline)
	assert(not self.next_spline)
	assert(not self.idle_mark_pos)
	--]]
	self:OnCommandStart()
end

function Flight_DrawAvoidance()
	DbgClearVectors()
	local flight_system = FlightSystems[ActiveMapID]
	for i=1,#flight_system.flying_objects do
		local obj = flight_system.flying_objects[i]
		local pos = obj:GetVisualPos()
		local color = RandColor(100, xxhash64(obj.flight_id))
		local to_avoid = Flight_ToAvoid(obj)
		for obj_i in pairs(to_avoid or empty_table) do
			if IsValid(obj_i) then
				DbgAddVector(pos, obj_i:GetVisualPos() - pos, color)
			end
		end
	end
end

function FlyingObject:IdleMark(mark)
	if self.avoid_class == 0 then
		return
	end
	local prev_pos = self.idle_mark_pos
	local new_pos = mark and self:GetPos() or nil
	local radius = self.collision_radius
	local flight_cache = GetFlightCache(self)
	if prev_pos then
		if new_pos and new_pos:Equal2D(prev_pos) then
			return
		end
		if developer then
			local min, max = flight_cache:IdleCheck(prev_pos, self.collision_radius)
			assert(min >= 1, "Flight traject grid corruption")
		end
		flight_cache:IdleUnmark(prev_pos, radius)
	end
	if mark then
		flight_cache:IdleMark(new_pos, radius)
	end
	self.idle_mark_pos = new_pos
end

function FlyingObject:CalcPath(pt1, pt2, sync)
	assert(self:IsValidPos())
	if pt1:Equal2D(pt2) then
		return
	end
	local err, spline_path
	if not IsCloser2D(pt1, pt2, work_step) then
		err, spline_path = Flight_FindSmoothPath(self, pt1, pt2, sync)
		if err then
			if developer then
				local dir = self.start_dir_obj and self:GetVelocityVector(true)
				Flight_Errors[#Flight_Errors + 1] = {self, pt1, pt2, dir, err}
			end
			assert(false, "Failed to compute flying trajectory: " .. err)
		end
	end
	if not spline_path or #spline_path == 0 then
		local dir = (pt2 - pt1) / 2
		spline_path = {{BS3_CreateSmoothSpline2D(pt1, dir, pt2, -dir)}}
	elseif not pt2:Equal2D(spline_path[#spline_path][4]) then
		local pos = spline_path[#spline_path][4]
		local dir = -spline_path[#spline_path][3]
		spline_path[#spline_path + 1] = {BS3_CreateSmoothSpline2D(pos, dir, pt2, pos - pt2)}
	end
	local flight_cache = GetFlightCache(self)
	if flight_cache.debug_path then
		flight_cache:DrawTraject(spline_path, white)
	end
	return spline_path
end

function FlyingObject:ReversePath(path)
	for i=1,#path do
		table.reverse(path[i])
	end
	table.reverse(path)
end

function FlyingObject:GetLogicalPos()
	local pos = self:GetVisualPos()
	if self:IsValidPos() then
		pos = pos:SetTerrainZ()
	end
	return pos
end

function FlyingObject:IsLanded()
	return false
end

function FlyingObject:WaitFollowPath(path)
	if not path or not path[1][1] then
		return
	end
	self:SetCommand("FollowPathCmd", path)
	WaitMsg(self)
end

function FlyingObject:FollowPathDstr()
	local flight_system = GetFlightSystem(self)
	if not flight_system.flying_objects[self] then
		assert(not self.current_spline)
		assert(not self.next_spline)
		return
	end
	flight_system.flying_objects[self] = nil
	table.remove_entry(flight_system.flying_objects, self)
	local flight_cache = GetFlightCache(self)
	flight_cache:TrajectUnmark(self.current_spline, self.next_spline)
	self.collision = false
	self.current_path = false
	self.current_spline = false
	self.next_spline = false
	if IsValid(self) then
		assert(not self:IsValidPos() or flight_cache.terrain:IsPointInBounds(self:GetPos()))
		Flight_EnableCollision(self, false)
		self:UnregisterFlight()
		self:SetAcceleration(0) -- clear acceleration
		--self:SetPos(self:GetVisualPosXYZ()) -- clear interpolation info
	end
	self:OnMoveEnd()
	Msg(self)
end

function FlyingObject:OnCommandStart()
	self:FollowPathDstr()
end

local function Land_GetHeight(flight_cache, x, y, gf)
	local th = flight_cache.terrain:GetHeight(x, y)
	local fh = flight_cache:GetHeight(x, y)
	return th + MulDivRound(fh - th, gf, 1000)
end

function FlyingObject:FollowPathCmd(path)
	if not IsValid(self) then
		assert(false, "Invalid flying object!")
		return
	end
	local flight_system = GetFlightSystem(self)
	if flight_system.flying_objects[self] then
		assert(false, "Flying object controlled from multiple threads!")
		return
	end
	local first_pos = path[1][1]
	local last_pos = path[#path][4]
	if not IsCloser2D(first_pos, last_pos, 30000 * guim) then
		assert(false, "Flying path too long!")
		self:SetPos(last_pos:SetTerrainZ(hover_height), 1000)
		Sleep(1000)
		return
	end
	flight_system.flying_objects[#flight_system.flying_objects + 1] = self
	flight_system.flying_objects[self] = CurrentThread()
	self:RegisterFlight(true)
	self.current_path = path

	local flight_cache = GetFlightCache(self)

	local Flight_GetHeight = function(x, y) return flight_cache:GetHeight(x, y) end
	local hover_height = self.hover_height
	local spline = path[1]
	local spline_idx = 1
	local spline_coef = 0
	local dir = BS3_GetSplineDir2D(spline)
	local angle = atan(dir)
	if not IsValidPos(self) then
		assert(false, "Invalid flying object pos!")
		local x, y = first_pos:xy()
		local z = flight_cache:GetHeight(x, y) + hover_height
		self:SetPos(x, y, z)
		self:SetAngle(angle)
	else
		local my_angle = self:GetAngle()
		local da = abs(AngleDiff(angle, my_angle))
		local rotation_time = MulDivRound(1000, da, self.max_yaw_speed)
		self:SetAngle(angle, rotation_time)
		if da > self.starting_angle_error then
			self:OnRotationStart()
			rotation_time = MulDivRound(rotation_time, da - self.starting_angle_error, da)
			self:MoveSleep(rotation_time)
			self:OnRotationEnd()
		end
	end
	local thrust_max = self.thrust_max
	local thrust_modifier = self.thrust_modifier
	local thrust_frict = self.thrust_frict
	local accel_dist = self.accel_dist
	local decel_dist = self.decel_dist
	local min_speed = self.min_speed
	local max_speed = self.move_speed
	local pitch_modifier = self.pitch_modifier
	local pitch_speed_adjust = self.pitch_speed_adjust
	local pitch_height_adjust = self.pitch_height_adjust
	local roll_modifier = self.roll_modifier
	local max_roll_speed = self.max_roll_speed
	local step = self.step * (100 + #flight_system.flying_objects / 2) / 100
	local max_sleep = self.max_sleep
	local turn_slow_down = self.turn_slow_down
	local check_collisions = self.avoid_mask ~= 0
	local auto_landing = self.auto_landing
	local len = BS3_GetSplineLengthEst(spline)
	assert(len > 0)
	local advance_max = len > 0 and Max(1, 4096 * step / len) or 1
	local min_hover_height = self.min_hover_height
	assert(hover_height >= min_hover_height)
	min_hover_height = Min(min_hover_height, hover_height)
	
	local spline_change = true
	self:OnMoveStart()
	local ground_ref = auto_landing and 0
	local dist_to_target 
	local travel_dist = 0
	local time
	assert(not self.current_spline and not self.next_spline)
	while IsValid(self) and (spline_idx ~= #path or spline_coef < 4096) do
		do
			local Min, Max = Min, Max
			local atan = atan
			local MulDivRound = MulDivRound
			local avoid_level = Flight_CheckCollisions(self)
			local advance = advance_max
			local step_reduced
			local x1, y1, x0, y0, z0, vx, vy, vz, speed_xy
			local angle_diff, roll0, pitch0, yaw0, yaw, ground_pitch
			local new_speed, accel, ground_height, step_dist
			local get_height = ground_ref and Land_GetHeight or FlightCache.GetHeight
			while true do
				local new_spline_idx = spline_idx
				local new_spline_coef = spline_coef + advance
				while new_spline_coef > 4096 do
					new_spline_coef = new_spline_coef - 4096
					new_spline_idx = new_spline_idx + 1
				end
				if new_spline_idx > #path or new_spline_idx == #path and new_spline_coef > (4096 - advance /2) then
					new_spline_idx = #path
					new_spline_coef = 4096
				end
				local new_spline = new_spline_idx ~= spline_idx and path[new_spline_idx] or spline
				local dirx, diry
				x1, y1, dirx, diry = BS3_GetSplinePosDir2D(new_spline, new_spline_coef)
				ground_height = get_height(flight_cache, x1, y1, ground_ref)
				x0, y0, z0 = self:GetVisualPosXYZ()
				local ground_denivelation = ground_height - get_height(flight_cache, x0, y0, ground_ref)
				step_dist = self:GetVisualDist2D(x1, y1)
				ground_pitch = -atan(ground_denivelation, step_dist)
				yaw = atan(diry, dirx)
				roll0, pitch0, yaw0 = GetRollPitchYaw(self)
				angle_diff = AngleDiff(yaw, yaw0)
				local turn_slow_down_factor = MulDivRound(turn_slow_down, abs(angle_diff), 90 * 60)
				local allowed_speed = MulDivRound(max_speed, 100 - turn_slow_down_factor, 100)
				local pitch_speed_factor = MulDivRound(pitch_speed_adjust, ground_pitch, 90*60)
				allowed_speed = allowed_speed + MulDivRound(allowed_speed, pitch_speed_factor, 100)
				if new_spline_idx >= #path - 1 and self:IsCloser2D(last_pos, decel_dist) then
					dist_to_target = self:GetVisualDist2D(last_pos)
					local decel_speed = MulDivRound(max_speed, dist_to_target, decel_dist)
					allowed_speed = Min(allowed_speed, decel_speed)
				end
				local stop
				if new_spline_idx == #path then
					local stop_speed = MulDivRound(max_speed, 4096 - new_spline_coef, 4096)
					allowed_speed = Min(allowed_speed, stop_speed)
					stop = new_spline_coef == 4096
				end
				vx, vy, vz = self:GetVelocityVector(true, true)
				speed_xy = sqrt(vx * vx + vy * vy)
				local delta_speed = MulDivRound(max_speed - speed_xy, step_dist, accel_dist)
				new_speed = stop and 0 or Max(min_speed, Min(speed_xy + delta_speed, allowed_speed))
				accel, time = self:GetAccelerationAndTime(x1, y1, z0, new_speed, speed_xy)
				if time < max_sleep or step_reduced then
					assert(time < 30000, "Movement too slow!")
					spline_coef = new_spline_coef
					if new_spline_idx ~= spline_idx then
						spline_idx = new_spline_idx
						spline = new_spline
						len = BS3_GetSplineLengthEst(spline)
						assert(len > 0)
						advance_max = len > 0 and Max(1, 4096 * step / len) or 1
						spline_change = true
					end
					break
				end
				step_reduced = true
				local new_time = (time < 2*max_sleep) and (time/2) or max_sleep
				advance = MulDivRound(advance, new_time, time)
			end
			travel_dist = travel_dist + step_dist
			if auto_landing then
				if dist_to_target then
					ground_ref = MulDivRound(1000, dist_to_target, decel_dist)
				elseif travel_dist < accel_dist then
					ground_ref = MulDivRound(1000, travel_dist, accel_dist)
				else
					ground_ref = false
				end
			end
			if spline_change then
				spline_change = false
				local next_spline = path[spline_idx + 1]
				flight_cache:TrajectUnmark(self.current_spline, self.next_spline)
				if check_collisions then
					local collision = flight_cache:TrajectCheck(spline, next_spline) or false
					if self.collision ~= collision then
						self.collision = collision
						Flight_EnableCollision(self, collision)
					end
				end
				self.current_spline = spline
				self.next_spline = next_spline
				flight_cache:TrajectMark(spline, next_spline)
			end
			local ground_offset = avoid_level + hover_height + MulDivRound(pitch_height_adjust, abs(ground_pitch), 90*60)
			local z1 = ground_height + ground_offset
			self:SetAcceleration(accel)
			local time_adjust = 100
			local thrust = z1 - z0
			if thrust > 0 then
				thrust = Min(MulDivRound(thrust, thrust_modifier, 100), thrust_max)
				if vz < 0 then
					local dist_to_ground = z0 - ground_height
					if dist_to_ground > min_hover_height then
						thrust = thrust + MulDivRound(thrust_max - thrust, ground_offset - dist_to_ground, ground_offset - min_hover_height)
					else
						thrust = thrust_max
					end
				end
				thrust = MulDivRound(thrust, speed_xy, max_speed)
				time_adjust = 100 - MulDivRound(50, thrust, thrust_max)
			else
				thrust = Max(thrust, -gravity)
			end
			thrust = thrust - MulDivRound(vz, thrust_frict, 100)
			z1 = z0 + MulDivRound(vz, time, 1000) + MulDivRound(thrust, time * time, 2000000)
			if z1 < ground_height + min_hover_height then
				z1 = Max(z1, flight_cache.terrain:GetHeight(x1, y1) + min_hover_height)
			end
			local roll = MulDivRound(-angle_diff, roll_modifier * new_speed, 100 * max_speed)
			roll = Clamp(roll, -90*60, 90*60)
			roll = (roll + roll0) / 2
			local droll = abs(AngleDiff(roll, roll0))
			local required_time = MulDivRound(1000, droll, max_roll_speed)
			if required_time > time then
				roll = MulDivRound(roll, time, required_time)
			end
			local pitch = atan(z0 - z1, step_dist)
			pitch = MulDivRound(pitch, new_speed * pitch_modifier, max_speed * 100)
			pitch = Clamp(pitch, -90*60, 90*60)
			pitch = (pitch + pitch0) / 2
			SetRollPitchYaw(self, roll, pitch, yaw, time)
			self:SetPos(x1, y1, z1, time)
			if new_speed ~= 0 then
				time = MulDivRound(time - 30, time_adjust, 100)
			end
		end
		self:MoveSleep(Max(1, time))
	end
	self:FollowPathDstr()
	return true
end

function FlyingObject:RegisterFlight(forced)
	if developer then
		assert(not FlightCObjs[self] or FlightCObjs[self] == self[true])
		FlightCObjs[self] = self[true]
	end
	Flight_Register(self, forced)
end

function FlyingObject:UnregisterFlight()
	if developer then
		assert(not FlightCObjs[self] or FlightCObjs[self] == self[true])
		FlightCObjs[self] = nil
	end
	Flight_Unregister(self)
end

function FlyingObject:OnMoveStart()
	self:PlayFX("Move", "start")
end

function FlyingObject:OnMoveEnd()
	self:PlayFX("Move", "end")
end

function FlyingObject:MoveSleep(t) --override me
	Sleep(t)
end

function FlyingObject:OnRotationStart()
	self:PlayFX("Rotate", "start")
end

function FlyingObject:OnRotationEnd()
	self:PlayFX("Rotate", "end")
end

function FlyingObject:PlayFX(action, moment, target)
	--DbgSetText(self, action, moment)
	PlayFX(action, moment, self, target)
end

function FlyingObject:GetHeightAround(height, ...)
	height = height or 0
	local x, y = ...
	if not x then
		x, y = self:GetVisualPosXYZ()
	elseif not y then
		x, y = x:xy()
	end
	local flight_cache = GetFlightCache(self)
	return GetRealm(self):GetHeightAround(flight_cache.height, height, x, y, self)
end

function OnMsg.GatherFXActions(list)
	list[#list + 1] = "Move"
	list[#list + 1] = "Rotate"
end

----
-- backward compat

function FlyingObject:CheckCollisions()
	local flight_system = GetFlightSystem(self)
	Flight_CheckCollisions(self, flight_system.flying_objects, Flight_MaxSplineDist)
	return max_int 
end
function FlyingObject:SetSpline(current_spline, next_spline)
	current_spline = current_spline or false
	next_spline = next_spline or false
	if current_spline == self.current_spline and next_spline == self.next_spline then
		return
	end
	local flight_cache = GetFlightCache(self)
	flight_cache:TrajectUnmark(self.current_spline, self.next_spline)
	
	if self.avoid_class ~= 0 then
		local collision = flight_cache:TrajectCheck(current_spline, next_spline) or false
		if self.avoid_mask ~= 0 and self.collision ~= collision then
			self.collision = collision
			Flight_EnableCollision(self, collision)
		end
	end
	self.current_spline = current_spline
	self.next_spline = next_spline
	flight_cache:TrajectMark(current_spline, next_spline)
end

function SavegameFixups.SetFlyingObjectFlag()
	for _, flight_system in pairs(FlightSystems) do
		for _, obj in ipairs(flight_system.flying_objects or empty_table) do
			obj:SetGameFlags(const.gofFlyingObject)
		end
	end
end

----

if developer then

GlobalVar("Flight_LastPt1", point(340070, 225104, 8457) )
GlobalVar("Flight_LastPt2", point(443178, 489249, 21120) )
GlobalVar("Flight_RandState", false)

function Flight_ClearPts()
	Flight_LastPt1, Flight_LastPt2 = false, false
end

function Flight_SavePt1()
	Flight_LastPt1 = GetTerrainCursor()
end

function Flight_SavePt2()
	Flight_LastPt2 = GetTerrainCursor()
end

function Flight_RandPos()
	Flight_RandState = Flight_RandState or RandState(xxhash64(GetMapName()))
	local mw, mh = GetActiveTerrain():GetMapSize()
	local x, y = Flight_RandState:Get(mw), Flight_RandState:Get(mh)
	return point(x, y)
end

FlyingObject.dbg_color = const.clrNoModifier
FlyingObject.dbg_text = false

DbgInit = function(self)
	self:SetColorModifier(self.dbg_color)
end

DbgSetText = function(self, ...)
	local text = self.dbg_text
	if not IsValid(text) then
		text = Text:new()
		text:SetAttachOffset(point(0, 0, 10*guim))
		text:SetDepthTest(true)
		self:Attach(text, self:GetSpotBeginIndex("Origin"))
		self.dbg_text = text
	end
	text:SetText(print_format(...))
end

function Flight_Test(class)
	CreateGameTimeThread(function()
		Flight_DbgClear()
		local pt1, pt2 = Flight_LastPt1, Flight_LastPt2
		if not pt1 then
			pt1 = GetTerrainCursor()
		end
		if not pt2 then
			pt2 = Flight_RandPos()
		end
		local shuttle = PlaceObject(class or "Shuttle")
		local flight_cache = GetFlightCache(shuttle)
		local path = shuttle and shuttle:CalcPath(pt1, pt2) or ""
		if #path < 2 then
			return
		end
		shuttle:SetVisible(true)
		shuttle:SetState("idle")
		local start_time = GameTime()
		print("Flight", shuttle.flight_id, "started")
		if flight_cache.debug_path then
			flight_cache:DrawTraject(path, yellow)
		end
		shuttle:WaitFollowPath(path)
		print("Flight", shuttle.flight_id, "arrived in", GameTime() - start_time)
		if not IsValid(shuttle) then
			return
		end
		local path2 = shuttle:CalcPath(pt2, pt1) or ""
		if not path2 or #path2 < 2 then
			shuttle:ReversePath(path)
			path2 = path
		elseif flight_cache.debug_path then
			flight_cache:DrawTraject(path2, red)
		end
		shuttle:WaitFollowPath(path2)
		Sleep(1000)
		if IsValid(shuttle) then
			DoneObject(shuttle)
		end
	end)
end

GlobalVar("Flight_DbgMesh", false)
GlobalVar("Flight_DbgCircles", false)

local dbg_step = work_step / 4
local dbg_size = 256 * guim

function FlightCache:InspectGetHeight(pos)
	return flight_cache.height and flight_cache.height:GetBilinear(pos, work_step, 0, 1) or 0
end

function Flight_DbgClear()
	if not FlightCaches then return false end
	if IsValid(Flight_DbgMesh) then
		DoneObject(Flight_DbgMesh)
	end
	if Flight_DbgCircles then
		for i=1,#Flight_DbgCircles do
			DoneObject(Flight_DbgCircles[i])
		end
		Flight_DbgCircles = false
	end
	DbgClear()
end

function Flight_DbgShowMarks()
	if not FlightCaches then return false end
	Flight_DbgClear()
	Flight_DbgCircles = {}
	
	local terrain = GetActiveTerrain()
	local map_width, map_height = terrain:GetMapSize()
	local grid = Flight_NewGrid(map_width, map_height)
	local flight_system = FlightSystems[ActiveMapID]
	for obj, info in pairs(flight_system.marked_objects) do
		local x, y, r, h = table.unpack(info)
		local p = point(x, y)
		local ground = terrain:GetHeight(p)
		local f = MulDivRound(r, mark_falloff, 100)
		grid:MaxCircle((h - ground) * grid_scale, p, work_step, r - f, r)
		Flight_DbgCircles[#Flight_DbgCircles + 1] = PlaceTerrainCircle(p, r)
		Flight_DbgCircles[#Flight_DbgCircles + 1] = PlaceTerrainCircle(p, r - f, blue)
	end
	Flight_DbgMesh = PlaceTerrainGrid(grid)
end

function Flight_DbgRasterLine(pos1, pos0, zoffset)
	if not FlightCaches then return false end
	return DbgInspectRasterLine(FlightCache.InspectGetHeight, FlightCaches[ActiveMapID], pos1, pos0, dbg_step, zoffset)
end

function Flight_DbgRasterArea(pos, size)	
	if not FlightCaches then return false end
	return DbgInspectRasterArea(FlightCache.InspectGetHeight, FlightCaches[ActiveMapID], pos, size, dbg_step)
end

function Flight_DbgToggleInspect()
	if not FlightCaches then return false end
	return DbgInspectToggle(FlightCache.InspectGetHeight, FlightCaches[ActiveMapID], dbg_size, dbg_step)
end

function Flight_DbgToggleCostGrid(palette, force_recalc)
	if not FlightCaches then return false end
	local flight_cache = FlightCaches[ActiveMapID]
	local grid_initial = flight_cache:GetMoveCost(ActiveMapID, force_recalc)
	local grid_to_show = grid_initial:clone()
	grid_to_show:normalize_i(0, 255, 1)
	DbgToggleAnyGrid("flight_cost", grid_to_show, palette)
end

function Flight_DbgToggleHeightGrid(palette)
	if not FlightCaches then return false end
	local flight_cache = FlightCaches[ActiveMapID]
	local grid = flight_cache.height:clone()
	grid:normalize_i(0, 255, 1)
	DbgToggleAnyGrid("flight_height", grid, palette)
end

function Flight_DbgToggleFlightPath(color)
	if not FlightCaches then return false end
	local flight_cache = FlightCaches[ActiveMapID]
	flight_cache.debug_path = not flight_cache.debug_path and true or false
	DbgClearVectors()
end

function FlightCache:DrawTraject(pts, color)
	color = color or white
	local hover_height = 20*guim
	local function Flight_FixHeight(pt)
		return pt:SetZ(self:GetHeight(pt:xy()) + hover_height)
	end	
	local pt = pts[1]
	if type(pt) == "table" then
		for i=1,#pts do
			local pti = {}
			for j, pt in ipairs(pts[i]) do
				pti[j] = Flight_FixHeight(pt)
			end
			DbgAddSpline(pti, color)
			DbgAddVector(pti[1])
		end
		DbgAddVector(pts[#pts][4])
	else
		local pt = Flight_FixHeight(pts[1])
		DbgAddVector(pt)
		for i=2,#pts do
			local pti = Flight_FixHeight(pts[i])
			DbgAddVector(pti)
			DbgAddVector(pt, pti - pt, color)
			pt = pti
		end
	end
end

FlyingObject.dbg_flight = false

function Flight_CheckError(idx)
	local obj, pt1, pt2, dir, err = table.unpack(Flight_Errors[idx] or empty_table)
	if not IsValid(obj) then return end
	obj.start_dir = dir
	obj.dbg_flight = true
	DbgClearVectors()
	DbgAddVector(pt1, pt2 - pt1, red)
	local err, path = Flight_FindSmoothPath(obj, pt1, pt2, true)
	local flight_cache = GetFlightCache(obj)
	if flight_cache.debug_path then
		DrawTraject(path, white)
	end
	ViewObjectMars(obj)
	obj.start_dir = nil
	obj.dbg_flight = nil
	return err, path
end

function Flight_DbgTrajectMark(seed, class, count)
	class = class or "CargoShuttle"
	count = count or 1000
	seed = seed or count
	local map_id = ActiveMapID
	local realm = GetRealmByID(map_id)
	local terrain = GetTerrainByID(map_id)
	local map_width, map_height = terrain:GetMapSize()
	local buffer = Flight_NewGrid(map_width, map_height)
	local map_data = ActiveMaps[map_id]
	local border = Max(0, map_data.PassBorder - work_step)
	local obj = PlaceObjectIn(class, map_id)
	local flight_cache = GetFlightCache(map_id)
	local cost = flight_cache:GetMoveCost(map_id)
	local traject = flight_cache.traject:clone()
	for i=1,count do
		local start = realm:GetRandomPassablePoint()
		local finish = realm:GetRandomPassablePoint()
		local compute_err, spline_path = AsyncFindSmoothPath(terrain, obj, start, finish, cost, border, buffer, 0, 0)
		if spline_path then
			local s0, s1
			for j=1,#spline_path do
				local s2, s3 = spline_path[j], spline_path[j + 1]
				flight_cache:TrajectUnmark(s0, s1)
				flight_cache:TrajectMark(s2, s3)
				DbgAddSpline(s2)
				s0, s1 = s2, s3
			end
			flight_cache:TrajectUnmark(s0, s1)
			DbgClearVectors()
		end
	end
	assert(flight_cache.traject:equals(traject))
	DoneObject(obj)
	return seed
end

end -- Platform.developer

