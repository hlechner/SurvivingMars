DefineClass.CargoTransporter = {
	__parents = { "Object" },
	
	properties = {
		{ category = "CargoTransporter", id = "name", name = T(1000037, "Name"), editor = "text", default = ""},
		{ template = true, category = "CargoTransporter", name = T(757, "Cargo Capacity (kg)"), id = "cargo_capacity", editor = "number", default = 10000, min = 0, max = 1000000, modifiable = true, help = "The amount of available cargo capacity." },
	},
	
	cargo = false,
	demand = false,
	supply = false,
}

function CargoTransporter:GameInit()
	self.cargo = self.cargo or {}
	self.drones_entering = {}
	self.drones_exiting = {}
end

function CargoTransporter:CreateEmptyManifest()
	local manifest = {}
	
	manifest.rovers = {}
	manifest.drones = 0
	manifest.passengers = {}
	manifest.prefabs = {}
	
	return manifest
end

function CreateManifest(cargo)
	local manifest = CargoTransporter.CreateEmptyManifest()
	
	local transportable_rovers = table.filter(cargo, function(k, v) return IsKindOf(g_Classes[k], "BaseRover") end)
	for _,entry in pairs(transportable_rovers) do
		manifest.rovers[entry.class] = entry.requested or 0
	end
	
	manifest.drones = cargo["Drone"] and cargo["Drone"].requested or 0
	
	for _,specialization in ipairs(GetSortedColonistSpecializationTable()) do
		manifest.passengers[specialization] = cargo[specialization] and cargo[specialization].requested or 0
	end
	
	local prefabs = table.filter(cargo, function(k, v) return BuildingTemplates[k] end)
	for _,entry in pairs(prefabs) do
		manifest.prefabs[entry.class] = entry.requested
	end
	return manifest
end

function CargoTransporter:Load(manifest, quick_load)
	assert(manifest)
	self.boarding = {}
	self.departures = {}
	self.cargo = self.cargo or {}
	
	local function SetCargoAmount(cargo, class_id, amount)
		if not cargo[class_id] then
			cargo[class_id] = { 
				class = class_id,
				requested = 0,
				amount = 0,
			}
		end
		cargo[class_id].amount = cargo[class_id].amount + amount
	end
	
	-- Find all available cargo
	local succeed, rovers, drones, crew, prefabs = self:Find(manifest, quick_load)
	while not succeed do
		Sleep(1000)
		succeed, rovers, drones, crew, prefabs = self:Find(manifest, quick_load)
	end
	
	-- Finaly, load found cargo
	for _,rover in pairs(rovers) do
		self:ExpeditionLoadRover(rover)
		SetCargoAmount(self.cargo, rover.class, 1)
	end
	
	self:ExpeditionLoadDrones(drones, quick_load)
	SetCargoAmount(self.cargo, "Drone", #drones)
	
	self:ExpeditionLoadCrew(crew)
	for _,member in pairs(crew) do
		if member.traits.Tourist then
			SetCargoAmount(self.cargo, "Tourist", 1)
		else
			SetCargoAmount(self.cargo, member.specialist, 1)
		end
	end
	
	for _,prefab in pairs(prefabs) do
		SetCargoAmount(self.cargo, prefab.class, prefab.amount)
		self.city:AddPrefabs(prefab.class, -prefab.amount, false)
	end
	
	return rovers, drones, crew, prefabs
end

function CargoTransporter:Find(manifest, quick_load)
	-- find vehicles
	local rovers = {}
	for rover_type, count in pairs(manifest.rovers) do
		local new_rovers = self:ExpeditionFindRovers(rover_type, quick_load, count) or empty_table
		if not quick_load and #new_rovers < count then 
			return false
		end
		
		table.iappend(rovers, new_rovers)
	end
	
	-- pick the required number of drones uniformly from hubs in range
	local drones = {}
	if manifest.drones > 0 then
		drones = self:ExpeditionFindDrones(manifest.drones, quick_load)
		if not quick_load and #drones < manifest.drones then
			return false
		end
	end
	
	-- wait to have enough potential crew, set command, wait them to board
	local crew = {}
	for specialization, count in pairs(manifest.passengers) do
		local new_crew = self:ExpeditionGatherCrew(count, specialization, quick_load) or empty_table
		if not quick_load and #new_crew < count then
			return false
		end
		
		table.iappend(crew, new_crew)
	end
	
	-- wait till all prefabs are available to be loaded
	local prefabs = {}
	local manifest_prefabs = table.filter(manifest.prefabs, function(k, v) return v > 0 end)
	for prefab,count in pairs(manifest_prefabs) do
		local available_count = self:ExpeditionGatherPrefabs(count, prefab)
		if not quick_load and available_count  < count then
			return false
		end
		
		table.insert(prefabs, {class = prefab, amount = count})
	end
	
	return true, rovers, drones, crew, prefabs
end

local function FilterColonists(colonists, label, num_crew)
	local all_filter = function(i, col) return (label == "Colonist" or col.traits[label]) end
	local adult_filter = function(i, col) return not col.traits.Child and all_filter(i, col) end
	
	local list = table.ifilter(colonists or empty_table, adult_filter) 
	if #list < num_crew then
		list = table.ifilter(colonists or empty_table, all_filter) 
	end
	return list
end

function CargoTransporter:ExpeditionGatherCrew(num_crew, label, quick_load)
	label = label or "Colonist"
	while true do
		local list = FilterColonists(self.city.labels.Colonist or empty_table, label, num_crew)
		
		self.colonist_summon_fail = #list < num_crew
		ObjModified(self)
		
		if #list >= num_crew or quick_load then
			local crew = {}
			while #list > 0 and #crew < num_crew do
				local unit = table.rand(list, InteractionRand("PickCrew"))
				table.remove_value(list, unit)
				table.insert(crew, unit)
			end
			return crew
		else
			return {}
		end
	end
end

function CargoTransporter:ExpeditionLoadCrew(crew)
	for _,unit in pairs(crew) do
		if unit == SelectedObj then
			SelectObj()
		end
		unit:SetDome(false)
		if not unit:IsValidPos() then
			-- About to be transfered anyway, force a valid position here
			unit:SetPos(self:GetPos())
		end
		unit:SetHolder(self)
		unit:SetCommand("Disappear", "keep in holder")
	end
end

function CargoTransporter:ExpeditionGatherPrefabs(num_prefabs, prefab)
	local city = self.city or MainCity
	local available_prefabs = city:GetPrefabs(prefab)
	if available_prefabs >= num_prefabs then
		return num_prefabs
	else
		return available_prefabs
	end
end

function CargoTransporter:WaitToFinishDisembarking(crew)
	while #crew > 0 do
		for _,unit in ipairs(crew) do
			if unit.command~="ReturnFromExpedition" then
				table.remove_value(crew, unit)
			end
		end
		Sleep(1000)
	end
end

function ExpeditionPickDroneFrom(controller, picked, filter)
	local drone = nil
	for _, d in ipairs(controller.drones or empty_table) do
		if d:CanBeControlled() and not table.find(picked, d) then
			if (not filter or filter(d)) then
				if not drone or drone.command ~= "Idle" and d.command == "Idle" then -- prefer idling drones
					drone = d
				end
			end
		end
	end
	return drone
end

function ExpeditionPickDrones(drones, num_drones, city, filter)
	local list = table.copy(city.labels.DroneControl or empty_table)
	local idx = 1
	while #drones < num_drones and #list > 0 do
		local drone = ExpeditionPickDroneFrom(list[idx], drones, filter)
		if drone then
			table.insert(drones, drone)
			idx = idx + 1
		else
			table.remove(list, idx)
		end
		if idx > #list then
			idx = 1
		end
	end
end

local function ExpeditionFindDronesWithFilter(drones, num_drones, obj, filter)
	-- prefer own drones first
	while #drones < num_drones and #(obj:HasMember("drones") and obj.drones or empty_table) > 0 do
		local drone = ExpeditionPickDroneFrom(obj, drones, filter)
		if not drone then
			break
		end
		table.insert(drones, drone)
	end
	
	-- pick from other drone controllers
	ExpeditionPickDrones(drones, num_drones, obj.city, filter)
end

local function DroneApproachingRocket(drone)
	if drone.s_request then
		local target_building = drone.s_request:GetBuilding()
		if IsKindOf(target_building, "RocketBase") and table.find(target_building.drones_entering, drone) then
			return true
		end
	end
	return false
end

local function GetAvailableDronesFilter(drone)
	local available = not drone.resource and drone.command ~= "Deliver" and not drone.holder
	available = available and not DroneApproachingRocket(drone)
	return available
end

function CargoTransporter:ExpeditionFindDrones(num_drones, quick_load)
	local found_drones = {}
	-- wait to have enough drones
	ExpeditionFindDronesWithFilter(found_drones, num_drones, self, GetAvailableDronesFilter)
	
	-- Check if it's an availability issue
	if #found_drones < num_drones then
		-- Try finding all drones available drones
		local available_drones = table.copy(found_drones)
		ExpeditionFindDronesWithFilter(available_drones, num_drones, self, nil)
		self.drone_summon_fail = #available_drones < num_drones
		if quick_load then
			found_drones = table.copy(available_drones)
		end
	else
		self.drone_summon_fail = false
	end
	
	ObjModified(self)
	return found_drones
end

function CargoTransporter:ExpeditionLoadDrones(found_drones)
	for idx, d in ipairs(found_drones or empty_table) do
		if not GetAvailableDronesFilter(d) then
			-- Filter failed, but we have to load the drones
			-- Check if drone needs to be removed from approaching rocket
			if DroneApproachingRocket(d) then
				local rocket = drone.s_request:GetBuilding()
				table.remove_entry(rocket.drones_entering, d)
			end
			
			-- Kill current drone and respawn it so it can be loaded safely
			local controller = d.command_center
			d:DespawnNow()
			d = controller.city:CreateDrone()
			d.init_with_command = false
			d:SetCommandCenter(controller)
			found_drones[idx] = d
		end
	end
	
	for _, drone in ipairs(found_drones) do
		if drone == SelectedObj then
			SelectObj()
		end
		drone:SetCommandCenter(false, "do not orphan!")
		drone:SetHolder(self)
		drone:SetCommand("Disappear", "keep in holder")
	end
end

function CargoTransporter:ExpeditionFindRovers(class, quick_load, amount)
	local filter = function(unit) return unit.class == class and unit:CanBeControlled() and (quick_load or unit.command == "Idle") end
	local realm = GetRealm(self)
	local list = realm:MapGet("map", class, filter) or empty_table
	
	if #list < amount then
		self.rover_summon_fail = true
		ObjModified(self)
		return nil
	end
	self.rover_summon_fail = nil
	ObjModified(self)
	
	local candidates = {}
	for _, unit in ipairs(list) do
		local d = self:GetDist2D(unit)
		table.insert(candidates, {
			rover = unit,
			distance = d,
		})
	end
	table.sortby_field(candidates, "distance")
	
	local rovers = {}
	for i = 1, amount do
		rovers[i] = candidates[i].rover
	end
	return rovers
end

function CargoTransporter:ExpeditionLoadRover(rover)
	if rover then
		if rover == SelectedObj then
			SelectObj()
		end
		
		if rover.class == "RCRover" then
			rover.sieged_state = false
		end
		rover:SetHolder(self)
		rover:SetCommand("Disappear", "keep in holder")
	end
end

function CargoTransporter:AttachRovers(rovers)
	for n,rover in ipairs(rovers) do
		if n > 2 then break end
		
		self:Attach(rover, self:GetSpotBeginIndex("Roverdock"..n))
		if n == 1 then
			rover:ClearGameFlags(const.gofSpecialOrientMode)
		end
		
		if rover:HasState("idleRocket") then
			rover:SetState("idleRocket")
		end
	end
end

function CargoTransporter:SpawnRovers()
	local rovers = { transports = {} }
	local map_id = self:GetMapID()
	for _,item in pairs(self.cargo or emptry_table) do
		if IsKindOf(g_Classes[item.class], "BaseRover") and item.amount > 0 then
			while item.amount > 0 do
				local rover = PlaceObjectIn(item.class, map_id, {city = self.city, override_ui_status = "Disembarking"})
				rovers[#rovers + 1] = rover
				item.amount = item.amount - 1
			end
		end
	end

	return rovers
end

function CargoTransporter:PlaceAdjacent(obj, def_pt, set_pos, move)
	local placement = self.placement
	local radius = obj:HasMember("GetDestlockRadius") and obj:GetDestlockRadius() or obj:GetRadius()
	local target_pt
	local adjacent
	local my_rad = self:GetRadius()
	my_rad = my_rad * my_rad
	
	-- artificially increase the radius for a sparser placement
	radius = MulDivRound(radius, 150, 100)
	
	if #placement == 0 then
		-- no objects placed, pick the default pt
		target_pt = def_pt
		adjacent = {}
	elseif #placement == 1 then
		-- only one object placed, pick a point in the direction of default
		local dir = (def_pt - placement[1].center):SetZ(0)
		target_pt = placement[1].center + SetLen(dir, placement[1].radius + radius)
		adjacent = { 1 }
	else
		-- two or more objects: pick an object at random and one adjacent to it, then
		-- try the centers of the two circles touching the two picked ones (one on each side)
		
		local objs = table.copy(placement, "deep") -- code below modifies adjacency structures, using a copy
		local valid = {}
		
		-- build a list of indices of valid starting objecets
		for i = 1, #objs do 
			valid[i] = i
		end
		
		local terrain = GetTerrain(self)

		while not target_pt and #valid > 0 do
			local obj_idx, idx = table.rand(valid, InteractionRand("RocketUnload"))
			local obj = objs[obj_idx]
			if #obj.adjacent == 0 then
				-- obj is no longer a valid pick, remove from valid (not from objs, as it would invalidate adjacencies)
				table.remove(valid, idx)
			else
				local obj_idx2, idx2 = table.rand(obj.adjacent, InteractionRand("RocketUnload"))
				local obj2 = objs[obj_idx2]
				
				local d1 = obj.radius + obj2.radius
				local d2 = obj.radius + radius
				local d3 = obj2.radius + radius
				
				assert(d1 > 0 and d2 > 0 and d3 > 0)
				
				-- the centers of the 3 circles form a triangle with sides of length d1, d2 and d3
				-- calculate the angle at 'obj' using cosine theorem
				local cos_alpha = MulDivRound(4096, (-d3 * d3 + d1 * d1 + d2 * d2), (2 * d1 * d2)) -- scale 4096
				local angle = acos(cos_alpha)
				
				-- align a vector to the known side of the triangle, resize it to match the desired length
				local v = SetLen((obj2.center - obj.center):SetZ(0), d2)
				
				for i = 1, 2 do
					if not target_pt then
						-- rotate the vector using the calculated angle to get the 3rd point of the triangle
						target_pt = obj.center + Rotate(v, angle)
						-- check if valid
						if not terrain:IsPassable(target_pt) or target_pt:Dist2(self:GetPos()) < my_rad then --2 close 2 rocket or not passable.
							target_pt = false
						else							
							for j = 1, #placement do
								if j ~= obj_idx2 and j ~= obj_idx and placement[j].center:Dist2D(target_pt) < placement[j].radius + radius then
									--DbgAddCircle(target_pt, radius, const.clrRed)
									target_pt = false
									break
								end
							end
						end
					end
					
					if target_pt then
						assert(target_pt:Dist2D(obj.center) < d2 + 10*guic and target_pt:Dist2D(obj2.center) < d3 + 10*guic)
						break
					end
					
					-- invert angle and try placing on the opposite side
					angle = -angle
				end
						
				-- if both points aren't valid remove adjacency between obj and obj2 for this placement
				if not target_pt then
					table.remove_entry(obj.adjacent, obj_idx2)
					table.remove_entry(obj2.adjacent, obj_idx)
				else
					adjacent = { obj_idx, obj_idx2 }
				end
			end
		end
		
	end
	
	local realm = GetRealm(self)
	target_pt = realm:SnapToTerrain(target_pt or def_pt)
	adjacent = adjacent or ""
	
	placement[#placement + 1] = {
		--obj = obj,
		center = target_pt,
		x = target_pt:x(),
		y = target_pt:y(),
		radius = radius,
		adjacent = adjacent,
	}
	
	if move then
		Movable.Goto(obj, target_pt) -- Unit.Goto is a command, use this instead for direct control
	end
	if set_pos then
		obj:SetPos(target_pt)
	end
	
	--DbgAddCircle(target_pt, radius, const.clrGreen)
	
	for i = 1, #adjacent do
		local idx = adjacent[i]
		local tbl = placement[idx].adjacent
		tbl[#tbl + 1] = #placement
		
		--DbgAddVector(placement[idx].center, target_pt - placement[idx].center, const.clrBlue)
	end
	
	return target_pt
end

function CargoTransporter:UnloadRovers(rovers, out)
	local rc_rovers = {}
	local angle = self:GetAngle()
	if #rovers > 0 then
		local first_rover = rovers[1]
		if IsKindOf(first_rover, "RCRover") then
			rc_rovers[1] = first_rover
		end

		local realm = GetRealm(self)
		local def_out_1 = out + SetLen((out - self:GetPos()):SetZ(0), 25*guim)
		local out_1 = realm:GetPassablePointNearby(def_out_1, first_rover.pfclass)
		out_1 = self:PlaceAdjacent(first_rover, out_1 or def_out_1)
		out = realm:GetPassablePointNearby(out, first_rover.pfclass) or out
		self:PlaceAdjacent(first_rover, out) --block out so they don't park right @ the ramp exit.

		first_rover:Detach()
		first_rover:SetGameFlags(const.gofSpecialOrientMode)
		first_rover:SetAngle(angle)
		first_rover:SetPos(out)
		first_rover:SetAnim(1, "disembarkUnload", const.eDontCrossfade)
		Sleep(first_rover:TimeToAnimEnd())
		first_rover:SetHolder(false)
		first_rover.override_ui_status = nil
		first_rover:SetCommand("Goto", out_1)

		Sleep(1000) --disembark 2 anim is kinda quick so give it a sec
		if #rovers > 1 then
			--generate positions
			local positions = {}
			for i = #rovers, 2, -1 do
				if IsKindOf(rovers[i], "RCRover") then
					rc_rovers[#rc_rovers + 1] = rovers[i]
				end
				positions[i] = self:PlaceAdjacent(rovers[i], out_1)
			end
		
			for i = 2, #rovers do
				local rover = rovers[i]
				rover:Detach()
				rover:SetAngle(angle)
				rover:SetPos(out)
				rover:SetAnim(1, "disembarkUnload2", const.eDontCrossfade)
				Sleep(rover:TimeToAnimEnd())
				rover:SetHolder(false)
				rover.override_ui_status = nil
				rover:SetCommand("Goto", positions[i])
				Sleep(1000) --disembark 2 anim is kinda quick so give it a sec
			end
		end
	end
	
	--re enable auto siege mode on RC Commanders
	for i = 1, #rc_rovers do
		local rc_rover = rc_rovers[i]
		rc_rover.sieged_state = true
		if rc_rover.command == "Idle" then --otherwise player is touching it.
			rc_rover:SetCommand("Idle")
		end
	end
end

function CargoTransporter:PickArrivalPos(center, dir, max_radius, min_radius, max_angle, min_angle)
	min_radius = min_radius or 0
	
	if not dir or not center then
		local spot = self:GetSpotBeginIndex("Colonistout")
		local pos, angle = self:GetSpotLoc(spot)
		
		center = center or pos
		dir = dir or (pos - self:GetPos()):SetZ(0)
	end
	
	local terrain = GetTerrain(self)
	local mw, mh = terrain:GetMapSize()
	if center == InvalidPos() then
		center = point(mw / 2, mh / 2)
	end
	
	--DbgClearVectors()
	--DbgAddVector(center, dir, const.clrWhite)
	
	for j = 1, 25 do
		local r = SetLen(dir, Random(min_radius, max_radius))
		local v = Rotate(r, Random(min_angle, max_angle))
		local pt = v + center
		local x, y = pt:x(), pt:y()
		x = Clamp(x, guim, mw - guim)
		y = Clamp(y, guim, mh - guim)
		if terrain:IsPassable(x, y) then
			--DbgAddVector(center, v, const.clrGreen)
			local pos = point(x, y)
			return pos
		end
		--DbgAddVector(center, v, const.clrYellow)
	end
	return center
end

function CargoTransporter:OnWaypointStartGoto(drone, pos, next_pos)
	local z = pos:z()
	local a = z and (z - (next_pos:z() or z)) or 0
	if a ~= 0 then
		local b = pos:Dist2D(next_pos)
		local axis, angle = ComposeRotation(axis_y, atan(a, b), drone:GetAxis(), drone:GetAngle())
		drone:SetAxisAngle(axis, angle)
	else
		drone:SetAxis(axis_z)
	end
end

function CargoTransporter:GetEntrancePoint()
	local entrance = nil
	if not self.waypoint_chains then return entrance end
	
	if self.waypoint_chains.entrance then
		entrance = self.waypoint_chains.entrance[1]
	end
	if self.waypoint_chains.rocket_exit then
		entrance = self.waypoint_chains.rocket_exit[1]
	end
	return entrance
end

function CargoTransporter:LeadOut(unit)
	if IsKindOf(unit, "Drone") then
		if self:HasMember("drone_charged") and self.drone_charged == unit then
			self.drone_charged = false
			unit.force_go_home = true
		end
		if unit.command == "Embark" then --cant move in embark
			unit:SetCommand(false)
			while unit.command_destructors and unit.command_destructors[1] > 0 do --wait while unit's destructor cleans up
				Sleep(1)
			end
			
			unit.command_thread = CurrentThread() --hack, so that PopAndCallDestructor in Goto doesn't halt this thread.
		end
		table.insert_unique(self.drones_exiting, unit)
		unit:ClearGameFlags(const.gofSpecialOrientMode)
	end
	unit:PushDestructor(function(unit)
		-- uninterruptible code:
		if not IsValid(unit) then return end
		unit:SetOutside(true)
		unit:SetState(unit:GetMoveAnim()) --fix for drones sometimes exiting in weird animation
		local entrance = self:GetEntrancePoint()
		if entrance then
			local open = entrance.openInside
			unit:SetPos(entrance[1])
			local speed = unit:GetSpeed()
			for i = 2, #entrance do
				if not IsValid(self) or not IsValid(unit) then
					return
				end
				local p1 = entrance[i - 1]
				local p2 = entrance[i]
				unit:Face(p2)
				self:OnWaypointStartGoto(unit, p1, p2)
				local t = p1:Dist(p2) * 1000 / speed
				unit:SetPos(p2, t)
				Sleep(t)
			end
		else
			unit:SetPos(self:GetPos())
		end
		if IsValid(unit) then
			unit:SetHolder(false)
			self:OnExitUnit(unit)
		end
		if IsKindOf(unit, "Drone") then
			table.remove_entry(self.drones_exiting, unit)
			if IsValid(unit) then
				unit:SetGameFlags(const.gofSpecialOrientMode)
				unit:SetAxis(axis_z)
			end
			if self == SelectedObj and self:HasMember("drones") and table.find(self.drones, unit) then
				SelectionArrowAdd(unit)
			end
		end
	end)
	unit:PopAndCallDestructor()
end

function CargoTransporter:UnloadDrones(drones)
	for i = 1, #drones do
		CreateGameTimeThread(function()
			local drone = drones[i]
			Sleep( (i - 1) * 1000 )
			if IsValid(drone) then
				self:LeadOut(drone)
				if not IsValid(drone) then return end
				local pt
				if IsValid(self) then
					pt = self:PickArrivalPos(false, false, 30*guim, 10*guim, 90*60, -90*60)
				else
					pt = self:PickArrivalPos(drone:GetPos(), point(guim, 0, 0), 30*guim, 10*guim, 180*60, -180*60)
				end
				Movable.Goto(drone, pt) -- Unit.Goto is a command, use this instead for direct control
				drone:SetCommand(IsValid(self) and "GoHome" or "Idle")
			end
		end, self, i)
	end
end

function CargoTransporter:UnloadCargoObjects(cargo, out)
	local refreshBM = false
	local map_id = self:GetMapID()
	for _,item in pairs(cargo) do
		local classdef = g_Classes[item.class]
		if Resources[item.class] then
			if item.amount > 0 then
				self:AddResource(item.amount*const.ResourceScale, item.class)
			end
		elseif item.class == "Passengers" then
			self:GenerateArrivals(item.amount, item.applicants_data)
		elseif IsKindOf(classdef, "Vehicle") then
			for j = 1, item.amount do
				local obj = PlaceObjectIn(item.class, map_id, {city = self.city})
				self:PlaceAdjacent(obj, out, true)
			end
		elseif BuildingTemplates[item.class] then
			refreshBM  = true
			self.city:AddPrefabs(item.class, item.amount, false)
		else
			print("unexpected cargo type", item.class, "ignored")
		end
	end
	if refreshBM then
		RefreshXBuildMenu()
	end
end

local function ExtractCargo(cargo)
	local new_cargo = {}
	
	for _,entry in ipairs(cargo) do
		entry.requested = 0
		new_cargo[entry.class] = entry
	end
	
	return new_cargo
end

function NormalizeCargo(cargo)
	if #cargo > 0 then
		return ExtractCargo(cargo)
	else
		return cargo
	end
end

function CargoTransporter:FixPayloadToCargoObject(payload_request)
	local flying_idx = table.find(payload_request, "class", "FlyingDrone")
	if flying_idx then
		local drone_idx = table.find(payload_request, "class", "Drone")
		payload_request[drone_idx].amount = payload_request[drone_idx].amount + payload_request[flying_idx].amount
		payload_request[flying_idx].amount = 0
	end
end

function CargoTransporter:FixCargoToPayloadObject(payload_request)
	if GetMissionSponsor().id == "Japan" then
		local flying_amount = RocketPayload_GetAmount("FlyingDrone")
		local drone_amount = RocketPayload_GetAmount("Drone")
		payload_request:SetItem("FlyingDrone", flying_amount + drone_amount)
		payload_request:SetItem("Drone", 0)
	end
end

local function AddPayloadToCargo(payload_request, cargo)
	cargo = NormalizeCargo(cargo)
	payload_request = NormalizeCargo(payload_request)
	
	local classes = table.keys(payload_request)
	for class,_ in pairs(cargo) do
		table.insert_unique(classes, class)
	end
	
	local new_cargo = {}
	
	for _,class in ipairs(classes) do
		local entry = cargo[class]
		new_cargo[class] = { 
			class = class,
			amount = entry and entry.amount or 0,
			requested = payload_request[class] and payload_request[class].amount or 0
		}
	end
	
	return new_cargo
end

local function AddPassengerManifestToCargo(passenger_manifest, cargo)
	cargo = NormalizeCargo(cargo)
	
	for class,amount in pairs(passenger_manifest) do
		cargo[class] = { 
			class = class,
			amount = 0,
			requested = amount
		}
	end
	
	return cargo
end

function CargoTransporter:GetRequestUnitCount(max_storage)
	return 3 + (max_storage / (const.ResourceScale * 5)) -- 1 per 5 + 3
end

function CargoTransporter:GetCargoLoadingStatus()
	local resources = table.filter(self.cargo, function(k, v) return Resources[k] end)
	for _,entry in pairs(resources) do
		if entry.amount > entry.requested then
			return "unloading"
		end
		if entry.amount < entry.requested then
			return "loading"
		end
	end
	return false
end

function CargoTransporter:GetRollover(id)
	local item = RocketPayload_GetMeta(id)
	if not item then
		return
	end
	local display_name, description = item.name, item.description
	if not display_name or display_name == "" then
		display_name, description = ResolveDisplayName(id)
	end
	description = (description and description ~= "" and description .. "<newline><newline>") or ""
	local icon = item.icon and Untranslated("<image "..item.icon.." 2000><newline><newline>") or ""
	local item_weight = RocketPayload_GetItemWeight(item)
	local building_cost = ""
	if ClassTemplates.Building[id] then
		building_cost = FormatBuildingCostInfo(id, false)
	end
	description = icon..description .. T{13730, "Weight: <value> kg<newline><newline><cost>", value = item_weight, cost = building_cost}
	
	return {
		title = display_name,
		descr = description,
		gamepad_hint = T(7580, "<DPadLeft> Change value <DPadRight>"),
	}
end

function CargoTransporter:UpdateResourceRequests(resources)
	self:DisconnectFromCommandCenters()
	for _,entry in pairs(resources) do
		if not self.demand[entry.class] then
			local unit_count = self:GetRequestUnitCount(entry.requested)
			self.demand[entry.class] = self:AddDemandRequest(entry.class, 0, self.demand_r_flags, unit_count)
			self.supply[entry.class] = self:AddSupplyRequest(entry.class, 0, self.supply_r_flags, unit_count)
		end

		if entry.amount <= entry.requested then
			local amount_to_request = (entry.requested - entry.amount) * const.ResourceScale
			self.supply[entry.class]:SetAmount(0)
			self.demand[entry.class]:SetAmount(amount_to_request)
		end
		
		if entry.amount > entry.requested then
			local amount_to_supply = (entry.amount - entry.requested) * const.ResourceScale
			self.supply[entry.class]:SetAmount(amount_to_supply)
			self.demand[entry.class]:SetAmount(0)
		end
	end
	self:ConnectToCommandCenters()
end

local function ContainsActiveRequests(requests)
	for _,request in pairs(requests) do
		if request:GetActualAmount() > 0 then
			return true
		end
	end
	return false
end

function CargoTransporter:HasActiveDemandRequests()
	return ContainsActiveRequests(self.demand)
end

function CargoTransporter:SetCargoRequest(payload_object, passenger_manifest)
	self:FixPayloadToCargoObject(payload_object)
	self.cargo = AddPayloadToCargo(payload_object, self.cargo)
	self.cargo = AddPassengerManifestToCargo(passenger_manifest, self.cargo)
	
	local resources = table.filter(self.cargo, function(k, v) return Resources[k] end)
	self:UpdateResourceRequests(resources)
end

function CargoTransporter:DroneLoadResource(drone, request, resource, amount)
	if table.has_value(self.supply, request) then
		local unscaled_amount = amount / const.ResourceScale
		self.cargo[resource].amount = self.cargo[resource].amount - unscaled_amount
	end
end

function CargoTransporter:DroneUnloadResource(drone, request, resource, amount)
	if table.has_value(self.demand, request) then
		local unscaled_amount = amount / const.ResourceScale
		self.cargo[resource].amount = self.cargo[resource].amount + unscaled_amount
	end
end

local function GetTotalPending(city, class)
	local total = 0
	for _,transporter in ipairs(city.labels.LanderRocketBase or empty_table) do
		local requested = transporter.cargo[class] and transporter.cargo[class].requested or 0
		local loaded = transporter.cargo[class] and transporter.cargo[class].amount or 0
		local pending = requested - loaded
		total = total + pending
	end
	return total
end

function GetTotalAvailable(city, class)
	local available = 0
	local cities_to_check = city ~= "Colony" and {city} or Cities
	for _,city in ipairs(cities_to_check) do
		local resources = GetCityResourceOverview(city)
		available = available + resources:GetAvailable(class) + city:GetPrefabs(class) + (not BuildingTemplates[class] and #(city.labels[class] or empty_table) or 0)
	end
	return available
end

function CargoTransporter:BuildCargoInfo(supply_table)
	local array = {}

	local table_copy = table.copy(supply_table)
	table_copy["rocket_name"] = nil
	
	for _,entry in pairs(table_copy) do
		table.insert(array, {
			class = entry.class,
			amount = entry.amount,
			requested = entry.requested,
			total_pending = GetTotalPending(self.city, entry.class),
			available = GetTotalAvailable(self.city, entry.class),
		})
	end
	return array
end

local AvailabilityStatus = {
	NotEnough = T(13775, "<red>Not enough</red>"),
	Limited = T(13776, "<yellow>Limited</yellow>"),
	Ready = T(13777, "<green>Ready</green>"),
	Loaded = T(13805, "<green>Loaded</green>"),
}

local function GetHighestAvailabilityStatus(status, other_status)
	if status == AvailabilityStatus.NotEnough or other_status == AvailabilityStatus.NotEnough then
		return AvailabilityStatus.NotEnough
	end
	
	if status == AvailabilityStatus.Limited or other_status == AvailabilityStatus.Limited then
		return AvailabilityStatus.Limited
	end
	
	if status == AvailabilityStatus.Ready or other_status == AvailabilityStatus.Ready then
		return AvailabilityStatus.Ready
	end
	
	return AvailabilityStatus.Loaded
end

local function GetAvailabilityStatus(amount, requested, total_pending, available)
	local result = nil
	if amount == requested then
		result = AvailabilityStatus.Loaded
	elseif (requested - amount) > available then
		result = AvailabilityStatus.NotEnough
	elseif total_pending > available then
		result = AvailabilityStatus.Limited
	else
		result = AvailabilityStatus.Ready
	end
	return result
end

local function FormatCargotManifestLine(name, amount, requested, status, icon, show_status)
	status = show_status and status or T{""}
	local amount_str = show_status and T{13778, "<requested>", requested = requested} or T{13779, "<number>/<requested>", number = amount, requested = requested}
	return T{13780, "<left><name><right><status> <amount_str><icon>", name = name, status = status, amount_str = amount_str, icon = icon}
end

function FormatRequestedCargoManifest(cargo, show_status, collapse_groups, only_collapsed)
	if not cargo or #cargo == 0 then
		return T(720, "Nothing")
	end
	
	local prefabs = {loaded = 0, requested = 0, status = AvailabilityStatus.Ready, texts = {}, }
	local passengers = {loaded = 0, requested = 0, status = AvailabilityStatus.Ready, texts = {}, }
	local other_texts = {}
	local resource_texts = {}
	
	for i = 1, #cargo do
		local item = cargo[i]
		if item.requested and item.requested > 0 then
			if item.class == "Passengers" then
				other_texts[#other_texts + 1] = T{13592, "<left>Passengers<right><amount>/<requested>", number = item.amount}
			elseif Resources[item.class] then
				resource_texts[#resource_texts + 1] = T{13593, "<left><name><right><resource(amount, requested, res)>", amount = item.amount*const.ResourceScale, requested = item.requested*const.ResourceScale, res = item.class, name = GetResourceTranslation(item.class)}
			elseif BuildingTemplates[item.class] then
				prefabs.loaded = prefabs.loaded + item.amount
				prefabs.requested = prefabs.requested + item.requested
				
				local status = GetAvailabilityStatus(item.amount, item.requested, item.total_pending, item.available)
				prefabs.status = GetHighestAvailabilityStatus(prefabs.status, status)
				
				if not collapse_groups then
					local def = BuildingTemplates[item.class]
					local name = item.amount > 1 and def.display_name_pl or def.display_name
					table.insert(prefabs.texts, FormatCargotManifestLine(name, item.amount, item.requested, status, T(13781, "<icon_Prefab_orig>"), show_status))
				end
			elseif table.find(GetSortedColonistSpecializationTable(), item.class) then
				passengers.loaded = passengers.loaded + item.amount
				passengers.requested = passengers.requested + item.requested
				
				local status = GetAvailabilityStatus(item.amount, item.requested, item.total_pending, item.available)
				passengers.status = GetHighestAvailabilityStatus(passengers.status, status)
					
				if not collapse_groups then
					local name = const.ColonistSpecialization[item.class].display_name
					table.insert(passengers.texts, FormatCargotManifestLine(name, item.amount, item.requested, status, T(13782, "<icon_Colonist_orig>"), show_status))
				end
			else
				local def = g_Classes[item.class]
				if def then
					local status = GetAvailabilityStatus(item.amount, item.requested, item.total_pending, item.available)
					table.insert(other_texts, FormatCargotManifestLine(def.display_name, item.amount, item.requested, status, T(13783, "<icon_Drone_orig>"), show_status))
				else
					assert(false, "invalid class (" .. tostring(item.class) .. ") in rocket cargo")
				end
			end
		end
	end
	
	local texts = {}
	if prefabs.requested > 0 then
		if collapse_groups then
			table.insert(texts, FormatCargotManifestLine(T(13784, "Prefabs"), prefabs.loaded, prefabs.requested, prefabs.status, T(13781, "<icon_Prefab_orig>"), show_status))
		else
			table.insert(texts, T(13785, "<left><em>Prefabs</em>"))
			table.iappend(texts, prefabs.texts)
			table.insert(texts, "<newline>")
		end
	end
	if passengers.requested > 0 then
		if collapse_groups then
			table.insert(texts, FormatCargotManifestLine(T(547, "Colonists"), passengers.loaded, passengers.requested, passengers.status, T(13782, "<icon_Colonist_orig>"), show_status))
		else
			table.insert(texts, T(13786, "<left><em>Colonists</em>"))
			table.iappend(texts, passengers.texts)
			table.insert(texts, "<newline>")
		end
	end
	
	if not only_collapsed then
		other_texts = table.map(other_texts, _InternalTranslate)
		table.sort(other_texts)
		table.iappend(texts, other_texts)
		
		resource_texts = table.map(resource_texts, _InternalTranslate)
		table.sort(resource_texts)
		table.iappend(texts, resource_texts)
	end
	
	texts = table.map(texts, Untranslated)
	
	if #texts == 0 then
		return nil
	end
	
	return table.concat(texts, "<newline>")
end

local function GetAdditionalResources(supply_table)
	local array = {}
	
	local table_copy = table.copy(supply_table)
	table_copy["rocket_name"] = nil
	
	for _,entry in pairs(table_copy) do
		local requested = (entry.requested or 0)
		local extra = entry.amount - requested
		if extra > 0 then
			table.insert(array, {
				class = entry.class,
				amount = extra,
			})
		end
	end
	return array
end

function CargoTransporter:GetRequestedCrew()
	local passengers = CreateManifest(self.cargo).passengers
	local total = 0
	for k,v in pairs(passengers) do
		total = total + v
	end
	return total
end

function CargoTransporter:GetAdditionalResources()
	return GetAdditionalResources(self.cargo)
end

function CargoTransporter:GetUnloadingCargoManifest()
	return FormatCargoManifest(GetAdditionalResources(self.cargo))
end

function CargoTransporter:GetCargoManifest()
	return FormatRequestedCargoManifest(self:BuildCargoInfo(self.cargo), false, true, false) or T(10887, "No Cargo")
end

function CargoTransporter:GetPayloadRolloverText()
	return FormatRequestedCargoManifest(self:BuildCargoInfo(self.cargo), false, false, true) or T("")
end

function CargoTransporter:CanRequestPayload()
	return true
end

function CargoTransporter:OpenPayloadDialog(name, object, context)
	if IsKindOf(SelectedObj, "MultiSelectionWrapper") and table.find(SelectedObj.objects, object) then
		context.object = SelectedObj
	else
		context.object = object
	end

	local dlg = GetDialog(name)
	if dlg then
		if not dlg.context or dlg.context.object ~= context.object then
			CloseDialog(name)
		else
			return
		end
	end
	return OpenDialog(name, nil, context)
end

function CargoTransporter:UIEditPayloadRequest()
	if self:CanRequestPayload() then
		self:OpenPayloadDialog("PayloadRequest", self, {meta_key = const.vkControl, close_on_rmb = true })
	end
end

function CargoTransporter:UIEditPayloadRequest_Update(button)
	button:SetEnabled(self:CanRequestPayload())
end

function CargoTransporter:GetLaunchIssue(skip_flight_ban)
	return self:GetCargoLoadingStatus()
end

function CargoTransporter:UICanTransport(payload, item)
	return (not item.filter or item.filter()) and 
		not payload:IsBlacklisted(item) and 
		not payload:IsLocked(item.id) and
		not BuildingTemplates[item.id] and 
		not IsKindOf(g_Classes[item.id], "BaseRover") and
		not IsKindOf(g_Classes[item.id], "OrbitalProbe")
end

function CargoTransporter:SetPayload(payload)
	local specializations = GetSortedColonistSpecializationTable()
	for _,entry in pairs(self.cargo) do
		if table.find(specializations, entry.class) then
			payload.traits_object.approved_per_trait = payload.traits_object.approved_per_trait or {}
			payload.traits_object.approved_per_trait[entry.class] = entry.requested
		else
			local amount = entry.requested - entry.amount
			if amount > 0 then
				payload:SetItem(entry.class, amount)
			end
		end
	end
	self:FixCargoToPayloadObject(payload)
end

function CargoTransporter:SetDefaultPayload(payload)

end

function CargoTransporter:GetCapacity()
	return self.cargo_capacity
end

function CargoTransporter:UIGetTransportableVehicles(excluded)
	local vehicles = {}
	for _,def in ipairs(ResupplyItemDefinitions) do
		local class = g_Classes[def.id]
		local item = RocketPayload_GetMeta(def.id)
		if IsKindOf(class, "BaseRover") and not IsKindOfClasses(class, excluded) and not item.locked then
			table.insert(vehicles, def)
		end
	end
	table.sort(vehicles, PresetSortLessCb)
	return vehicles
end

function CargoTransporter:UIGetTransportablePrefabs(environments)
	local prefabs = GetAccessiblePrefabs(self:GetMapID(), environments)
	table.sort(prefabs, PresetSortLessCb)
	return prefabs
end

function SavegameFixups.AddMissingResupplyItemDefs()
	if IsDlcAccessible("picard") then
		RocketPayload_Init(true)
	end
end