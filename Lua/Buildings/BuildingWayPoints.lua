if FirstLoad then
	WaypointChains = false
end

--config.DebugWaypoints = true

ChainTypes =
{	-- [spotname] = chain type
	["Door"] = "entrance",
	["Doorentrance1"] = "entrance",
	["Doorentrance2"] = "entrance",
	["Doorexit1"] = "entrance",
	["Doorexit2"] = "entrance",
	["Cardoor"] = "drone_factory_exit",
	["Dronein"] = "rocket_entrance",
	["Droneout"] = "rocket_exit",
	["Dronedoor"] = "tunnel_entrance",
	["Pathpassage"] = "passage_entrance",
}

function GetEntityWaypointChains(entity)
	local waypoint_chains = WaypointChains[entity]
	if waypoint_chains then return waypoint_chains end
	waypoint_chains = {}
	WaypointChains[entity] = waypoint_chains
	if entity and IsValidEntity(entity) then
		local first, last = GetAllSpots(entity, "idle")
		local spot_chains
		for spot = first, last do
			local note = GetSpotAnnotation(entity, spot)
			if note and #note > 0 then
				local def
				for k, v in string.gmatch(note, "(%w+)=([%w_]+)") do
					def = def or {}
					def[k] = tonumber(v) or v
				end
				local chain_idx = def and def.chain
				if chain_idx then
					-- create chain if this is the first spot in it
					local spot_name = GetSpotName(entity, spot)
					spot_chains = spot_chains or {}
					local list = spot_chains[spot_name]
					local chain
					if list then
						chain = table.find_value(list, "chain", chain_idx)
					else
						list = {}
						spot_chains[spot_name] = list
					end
					if not chain then
						chain = {
							type = ChainTypes[spot_name],
							name = spot_name,
							chain = chain_idx,
							openInside = 1,
							openOutside = 2,
						}
						list[#list + 1] = chain
					end
					-- some chains have a door entity
					if (def.entity or def.door) and not chain.door then
						chain.outside = def.outside and def.outside > 0 or false
						chain.door = def.door or def.entity
						chain.door_spot = def.door_spot
						chain.openInside = def.openInside or chain.openInside
						chain.openOutside = def.openOutside or chain.openOutside
					end
					-- save spot at waypoint index
					chain[def.waypoint] = spot
				end
			end
		end
		if spot_chains then
			for spot_name, chains in sorted_pairs(spot_chains) do
				table.iappend(waypoint_chains, chains)
			end
		end
	end
	return waypoint_chains
end

function OnMsg.EntitiesLoaded()
	WaypointChains = {}
end

local ShowWaypoints
if config.DebugWaypoints then
	ShowWaypoints = function(map_id, waypoints, open, color_line, color_door)
		color_line = color_line or RGB(255, 255, 0)
		color_door = color_door or RGB(255, 0, 0)
		local line = PlaceObject("Polyline")
		local terrain = GetTerrainByID(map_id)
		line:SetEnumFlags(const.efVisible)
		local points, colors, texts = {}, {}, {}
		for i=1,#waypoints do
			local w = waypoints[i]
			local c = i == open and color_door or color_line
			local z = terrain:GetSurfaceHeight(w)
			points[i] = w
			colors[i] = c
			local t = Text:new()
			t:SetPos(w:SetZ((w:z() or terrain:GetHeight(w)) + 10*guic))
			t:SetColor(c)
			t:SetText(tostring(i))
			texts[i] = t
		end
		line:SetPos(AveragePoint2D(points))
		line:SetMesh(points, colors)
		return {line = line, texts = texts}
	end
end
local function HideWaypoints(data)
	if data then
		if IsValid(data.line) then
			DoneObject(data.line)
		end
		data.line = false
		local texts = data.texts
		for i = 1, #texts do
			if IsValid(texts[i]) then
				DoneObject(texts[i])
			end
		end
		data.texts = ""
	end
end


----- WaypointsObj

DefineClass.WaypointsObj = {
	__parents = { "Object" },
	waypoint_chains = false,
	entrance_fallback = false,
	parent_dome = false, --save compat with rev 225026 saves
}

function WaypointsObj:GameInit()
	self:BuildWaypointChains()
end

function WaypointsObj:BuildWaypointChains()
	local waypoint_chains
	local map_id = self:GetMapID()
	local terrain = GetTerrainByID(map_id)
	for _, chain in ipairs(GetEntityWaypointChains(self:GetEntity())) do
		if not waypoint_chains then
			waypoint_chains = {}
			self.waypoint_chains = waypoint_chains
		end
		local instance_chain = {
			openInside = chain.openInside,
			openOutside = chain.openOutside,
			name = chain.name,
		}
		-- attach door
		if chain.door then
			local door = self:GetAttach(chain.door)
			if not door then
				door = PlaceObjectIn(chain.door, map_id)
				CopyColorizationMaterial(self, door)
				self:Attach(door)
			end
			instance_chain.door = door
		end

		local pos1 = self:GetSpotPos(chain[1])
		assert(chain[1] and pos1, string.format("Invalid entrance/waypoints for class %s", self.class) )-- invalid entrance
		local dz1 = pos1:z() - terrain:GetHeight(pos1)
		-- convert spots to points, add points if there are points under the terrain
		for i = 2, #chain do
			local pos2 = self:GetSpotPos(chain[i])
			local dz2 = pos2:z() - terrain:GetHeight(pos2)
			-- waypoint
			instance_chain[#instance_chain + 1] = dz1 > 0 and pos1 or pos1:SetZ(pos1:z() - dz1)
			if dz1 > 0 and dz2 < 0 or dz1 < 0 and dz2 > 0 then
				-- one of the points is underground - insert a new point where the terrain
				local pt1, pt2
				if dz1 > 0 then
					pt1, pt2 = pos1, pos2
				else
					pt2, pt1 = pos2, pos1
				end
				for i = 1, 15 do
					local pt = pt1:Lerp(pt2, i, 16)
					local h = terrain:GetHeight(pt)
					if pt:z() <= h then
						instance_chain[#instance_chain + 1] = pt:SetZ(h)
						break
					end
				end
			end
			pos1, dz1 = pos2, dz2
		end
		-- don't forget the last waypoint
		instance_chain[#instance_chain + 1] = dz1 > 0 and pos1 or pos1:SetZ(pos1:z() - dz1)
		local chains = waypoint_chains
		if chain.type then
			chains = waypoint_chains[chain.type]
			if not chains then
				chains = {}
				waypoint_chains[chain.type] = chains
			end
		end
		chains[#chains + 1] = instance_chain
	end
end

function WaypointsObj:GetEntranceFallbackUncached()
	local origin = self:GetPos():SetInvalidZ()
	local pt, dir = origin, RotateRadius(guim, self:GetAngle())
	local retries = 100
	local map_id = self:GetMapID()
	local terrain = GetTerrainByID(map_id)
	while retries > 0 and not terrain:IsPassable(pt) do
		pt = pt + dir
		retries = retries - 1
	end
	if retries == 0 then
		print("once", "Unit stuck in holder!", self:GetName())
		pt = origin
	end
	return { pt - dir, pt }
end

function WaypointsObj:GetEntranceFallback()
	local fallback = self.entrance_fallback
	if not fallback and self:IsValidPos() then
		fallback = self:GetEntranceFallbackUncached()
		self.entrance_fallback = fallback
	end
	return fallback, fallback[2]
end

function WaypointsObj:GetEntrance(target, entrance_type, spot_name, unit)
	if not IsValid(self) or not self:IsValidPos() then
		return
	end
	target = target or self
	if self:HasSpot("Yard") then
		return nil, nil, "Yard"
	end
	local entrance
	entrance_type = entrance_type or "entrance"
	if entrance_type == "entrance" then
		entrance = self:NearestPassableWaypoints2D(target, entrance_type, spot_name, nil, unit and unit.pfclass or 0)
	end
	if not entrance then
		entrance = self:NearestWaypoints2D(target, entrance_type, spot_name)
	end
	if entrance then
		return entrance, entrance[#entrance]
	end
	return self:GetEntranceFallback()
end

function WaypointsObj:GetEntrancePoints(entrance_type, spot_name)
	if not self:IsValidPos() then
		return
	end
	if self:HasSpot("Yard") then
		return
	end
	local waypoint_chains = self.waypoint_chains
	waypoint_chains = waypoint_chains and waypoint_chains[entrance_type or "entrance"]
	if waypoint_chains then
		local count = 0
		local points
		for i = 1, #waypoint_chains do
			local chain = waypoint_chains[i]
			if not spot_name or chain.name == spot_name then
				local pt = chain[#chain]
				count = count + 1
				if count == 1 then
					points = pt
				elseif count == 2 then
					points = { points, pt }
				else
					points[count] = pt
				end
			end
		end
		return points
	end
end

local function FindNearestWaypoints(waypoint_chains, chain_type, spot_name, eval, ...)
	local best, best_value
	chain_type = chain_type or spot_name and ChainTypes[spot_name]
	if chain_type then
		waypoint_chains = waypoint_chains and waypoint_chains[chain_type]
	end
	if waypoint_chains then
		for i = 1, #waypoint_chains do
			local chain = waypoint_chains[i]
			if not spot_name or chain.name == spot_name then
				local value = eval(chain, ...)
				if value and (not best or value < best_value) then
					best, best_value = chain, value
				end
			end
		end
	end
	return best
end

function WaypointsObj:NearestWaypoints(target, chain_type, spot_name, chain_idx)
	local function eval(chain, fDist, target, chain_idx)
		return fDist(target, chain_idx and chain[chain_idx] or chain[#chain])
	end
	local fDist = IsValid(target) and target.GetVisualDist or target.Dist
	return FindNearestWaypoints(self.waypoint_chains, chain_type, spot_name, eval, fDist, target, chain_idx)
end

function WaypointsObj:NearestWaypoints2D(target, chain_type, spot_name, chain_idx)
	local function eval(chain, fDist, target, chain_idx)
		return fDist(target, chain_idx and chain[chain_idx] or chain[#chain])
	end
	local fDist = IsValid(target) and target.GetVisualDist2D or target.Dist2D
	return FindNearestWaypoints(self.waypoint_chains, chain_type, spot_name, eval, fDist, target, chain_idx)
end

function WaypointsObj:NearestPassableWaypoints2D(target, chain_type, spot_name, chain_idx, pfClass)
	local terrain = GetTerrain(self)
	local function eval(chain, fDist, target, chain_idx, pfClass, terrain)
		local pt = chain_idx and chain[chain_idx] or chain[#chain]
		return terrain:IsPassable(pt, pfClass) and fDist(target, pt)
	end
	local fDist = IsValid(target) and target.GetVisualDist2D or target.Dist2D
	return FindNearestWaypoints(self.waypoint_chains, chain_type, spot_name, eval, fDist, target, chain_idx, pfClass, terrain)
end

function WaypointsObj:FindWaypointsInRange(spot_name, first_range, first_target, last_range, last_target)
	local fFirstDist = first_target and (IsValid(first_target) and first_target.GetVisualDist or first_target.Dist)
	local fLastDist = last_target and (IsValid(last_target) and last_target.GetVisualDist or last_target.Dist)
	if first_range == "Nearest" then
		local function eval(chain, fDist, target, fRange, range_target, range)
			if not fRange or fRange(range_target, chain[#chain]) <= range then
				return fDist(target, chain[1])
			end
		end
		return FindNearestWaypoints(self.waypoint_chains, nil, spot_name, eval, fFirstDist, first_target, fLastDist, last_target, last_range)
	elseif last_range == "Nearest" then
		local function eval(chain, fDist, target, fRange, range_target, range)
			if not fRange or fRange(range_target, chain[1]) <= range then
				return fDist(target, chain[#chain])
			end
		end
		return FindNearestWaypoints(self.waypoint_chains, nil, spot_name, eval, fLastDist, last_target, fFirstDist, first_target, first_range)
	end
	local chain_type = spot_name and ChainTypes[spot_name]
	local waypoint_chains = self.waypoint_chains
	if chain_type then
		waypoint_chains = waypoint_chains and waypoint_chains[chain_type]
	end
	if waypoint_chains then
		for i = 1, #waypoint_chains do
			local chain = waypoint_chains[i]
			if not spot_name or chain.name == spot_name then
				if (not fFirstDist or fFirstDist(first_target, chain[1]) <= first_range) and
					(not fLastDist or fLastDist(last_target, chain[#chain]) <= last_range)
				then
					return chain
				end
			end
		end
	end
end

function WaypointsObj:NearestPassableSpot(spot_type, unit)
	local first, last = self:GetSpotRange(spot_type)
	local best, best_dist
	local terrain = GetTerrain(self)
	for spot = first, last do
		local pt = self:GetSpotLocPos(spot)
		if terrain:IsPassable(pt, unit.pfclass) then
			local dist = unit:GetDist(pt)
			if not best_dist or dist < best_dist then
				best, best_dist = spot, dist
			end
		end
	end
	return best
end

function WaypointsObj:RandomPassableSpot(spot_type, unit)
	local first, last = self:GetSpotRange(spot_type)
	local count = 0
	local terrain = GetTerrain(self)
	for spot = first, last do
		local pt = self:GetSpotLocPos(spot)
		if terrain:IsPassable(pt, unit.pfclass) then
			count = count + 1
		end
	end
	if count == 0 then
		return
	elseif count == 1 then
		return first
	else
		return first + AsyncRand(count)
	end
end

function FollowWaypointPath(unit, path, first, last, wait_door_open)
	if not path then return end
	first = first or #path
	last = last or #path
	local add_next = first <= last and 1 or -1
	if unit:IsValidPos() then
		assert(unit:IsCloser2D(path[first], 100*guim))
		unit:Goto(path[first], "sl")
		if not unit:IsValidPos() then
			return -- action was interrupted
		end
	else
		unit:SetPos(path[first])
		if first ~= last then
			unit:Face(path[first + add_next], 0)
		end
	end
	local door = path.door
	local open = door and (first <= last and path.openInside or path.openOutside)
	unit.visit_door_opened = false
	local debug_line = ShowWaypoints and ShowWaypoints(unit:GetMapID(), path, open)
	if debug_line then
		unit:PushDestructor(function(unit) HideWaypoints(debug_line) end)
	end
	for i = first + add_next, last, add_next do
		if i - add_next == open and IsValid(door) then
			unit.visit_door_opened = door
			door:Open()
			if wait_door_open or wait_door_open == nil and open == 1 then
				unit:WaitDoorOpening(door)
				if not unit:IsValidPos() then
					break -- action was interrupted
				end
			end
		end
		unit:Goto(path[i], "sl")
		if not unit:IsValidPos() then
			break -- action was interrupted
		end
	end
	door = unit.visit_door_opened
	if IsValid(door) then
		door:Close()
		unit.visit_door_opened = false
	end
	if debug_line then unit:PopAndCallDestructor() end
end

function WaypointsObj:LeadIn(unit, entrance)
	assert(type(entrance) == "table")
	if not entrance then return end
	assert(not unit.lead_in_out)
	unit.lead_in_out = self
	self:OnEnterUnit(unit)
	unit:PushDestructor(function(unit)
		unit.lead_in_out = false
		if unit.lead_interrupted then
			unit.lead_interrupted = nil
			unit:InterruptCommand()
		end
	end)
	FollowWaypointPath(unit, entrance, #entrance, 1)
	unit:PopAndCallDestructor()
end

function WaypointsObj:LeadOut(unit, entrance)
	assert(type(entrance) == "table")
	if not entrance then return end
	unit.lead_in_out = self
	self:OnExitStart(unit)
	unit:PushDestructor(function(unit)
		if not unit:IsValidPos() then
			unit:SetPos(entrance[#entrance])
			unit:SetAngle(CalcOrientation(entrance[#entrance-1], entrance[#entrance]))
		end
		unit.lead_in_out = false
		if unit.lead_interrupted then
			unit.lead_interrupted = nil
			unit:InterruptCommand()
		end
		self:OnExitUnit(unit)
	end)
	FollowWaypointPath(unit, entrance, 1, #entrance)
	unit:PopAndCallDestructor()
end

function WaypointsObj:OnEnterUnit(unit)
	unit:SetHolder(self)
	unit:ShowAttachedSigns(false)
	unit:SetOutsideEffects(false)
end

function WaypointsObj:OnExitStart(unit)
	unit:SetOutsideVisuals(not self.parent_dome)
end

function WaypointsObj:OnExitUnit(unit)
	if unit.holder == self then
		unit:SetHolder(false)
	end
	unit:ShowAttachedSigns(true)
	unit:SetOutside(not self.parent_dome)
end

function AttachDoors(obj, entity)
	local map_id = obj:GetMapID()
	for _, chain in ipairs(GetEntityWaypointChains(entity)) do
		if chain.door and not obj:GetAttach(chain.door) then
			local door = PlaceObjectIn(chain.door, map_id)
			CopyColorizationMaterial(obj, door)
			obj:Attach(door)
		end
	end
end
