ElectricGridCableDirectionRelationToEntity = {
	[1] = "CableHardLeft",
	[2] = "CableSoftLeft",
	[3] = "CableStraight",
	[4] = "CableSoftRight",
	[5] = "CableHardRight",
	[6] = "CableTerrain", --str8 cable with more vertexes for better terrain distortion
}

ElectricGridHubPlugEntities = { -- hubs connecting to other hubs or buildings
	[1] = "CableHubPlug",
	[2] = "CableHub",
}

ElectricGridElevatedPlugEntities = {
	[1] = "CableTowerPlugIn",
	[2] = "CableTowerPlugOut"
}

local AllPossiblePlugs = {
}

table.iappend(AllPossiblePlugs, ElectricGridHubPlugEntities)
table.iappend(AllPossiblePlugs, ElectricGridElevatedPlugEntities)

local custom_cable_connections = {
	StirlingGenerator = "CableStirlingGenerator",
	SensorTower = "CableSensorTower",
}

local all_cable_connection_classes = {
	"CableConnection",
}

for k, v in pairs(custom_cable_connections) do
	table.insert(all_cable_connection_classes, v)
end

function GetAllCableConnectionClassesTable()
	return all_cable_connection_classes
end

DefineClass.ElectricityGrid = {
	__parents = { "SupplyGridFragment" },
	supply_resource = "electricity",
}

local function find_cable(attaches, a, offset)
	for i = #(attaches or ""), 1, -1 do
		if (not offset or attaches[i]:GetAttachOffset() == offset) and
			attaches[i]:GetAttachAngle() == a then
			return true
		end
	end
end

function ElectricityGrid.CreateConnection(pt1, pt2, building1, building2)
	assert(building1 and building2)
	local supply_connection_grid = GetSupplyConnectionGrid(building1)
	SupplyGridAddConnection(supply_connection_grid["electricity"], pt1, pt2)
	local is_cable1 = building1:IsKindOf("ElectricityGridElement")
	local is_cable2 = building2:IsKindOf("ElectricityGridElement")
	local is_hub1, is_hub2
	if is_cable1 then
		building1:UpdateVisuals()
		is_hub1 = building1.is_hub
	end
	if is_cable2 then
		building2:UpdateVisuals()
		is_hub2 = building2.is_hub
	end
	pt1 = point(HexToWorld(pt1:xy()))
	pt2 = point(HexToWorld(pt2:xy()))
	
	local map_id = building1:GetMapID()
	if not is_cable1 then -- place a building-to-cable connection
		local ao = Rotate((pt1 - building1:GetPos()):SetZ(0), -building1:GetAngle())
		local aa = CalcOrientation(pt2, pt1) - building1:GetAngle()
		local clsn = custom_cable_connections[building1.class] or "CableConnection"
		local attaches = building1:GetAttaches(clsn)
		if not find_cable(attaches, aa, ao) then
			local cable = PlaceObjectIn(clsn, map_id)
			building1:Attach(cable)
			cable:SetAttachOffset(ao)
			cable:SetAttachAngle(aa)
		end
	end
	if not is_cable2 then -- place a building-to-cable connection
		local ao = Rotate((pt2 - building2:GetPos()):SetZ(0), -building2:GetAngle())
		local aa = CalcOrientation(pt1, pt2) - building2:GetAngle()
		local clsn = custom_cable_connections[building2.class] or "CableConnection"
		local attaches = building2:GetAttaches(clsn)
		if not find_cable(attaches, aa, ao) then
			local cable = PlaceObjectIn(clsn, map_id)
			building2:Attach(cable)
			cable:SetAttachOffset(ao)
			cable:SetAttachAngle(aa)
		end
	end
end

local function iterate_and_destroy(attaches, a, offset)
	for i = #(attaches or ""), 1, -1 do
		if (not offset or attaches[i]:GetAttachOffset() == offset) and
			attaches[i]:GetAttachAngle() == a then
			DoneObject(attaches[i])
		end
	end
end

IsCascadeDeleting = false
MaxCableToDelPiecesPerCascade = 5
ResetVarThread = false
GlobalVar("CablePiecesDelledThisCascade", 0)

function ElectricityGrid.DestroyConnection(pt1, pt2, building1, building2, test)
	assert(building1 and building2)
	local is_hub1 = building1:IsKindOfClasses("ElectricityGridElement", "Passage")
	local is_hub2 = building2:IsKindOfClasses("ElectricityGridElement", "Passage")
	local is_b1_constr = building1:IsKindOf("ConstructionSite")
	local is_b2_constr = building2:IsKindOf("ConstructionSite")
	local map_id = building1:GetMapID() or building2:GetMapID()
	local city = Cities[map_id]
	local cascade_cable_deletion_enabled = city.cascade_cable_deletion_enabled
	local supply_connection_grid = GetSupplyConnectionGrid(building1)
	local conn_grid = supply_connection_grid["electricity"]
	local hanging_cable = (is_hub1 and is_hub2) and ((building1.chain and building2.pillar) or (building1.pillar and building2.chain) or (building1.chain and building2.chain))
	local should_delete =  cascade_cable_deletion_enabled and (CablePiecesDelledThisCascade or 0) < (MaxCableToDelPiecesPerCascade - 1) and (is_hub1 and is_hub2) and not (is_b1_constr or is_b2_constr) and not (building1.is_switch or building2.is_switch)
								and (building1:GetEntity() == ElectricGridCableDirectionRelationToEntity[3] or building1:GetEntity() == ElectricGridCableDirectionRelationToEntity[6] or band(HexGridGet(conn_grid, building1), 63) == 0)
								and (building2:GetEntity() == ElectricGridCableDirectionRelationToEntity[3] or building2:GetEntity() == ElectricGridCableDirectionRelationToEntity[6] or band(HexGridGet(conn_grid, building2), 63) == 0)
	IsCascadeDeleting = true
	
	if not ResetVarThread then
		ResetVarThread = CreateRealTimeThread(function()
			CablePiecesDelledThisCascade = 0
			ResetVarThread = false
		end)
	end
	
	pt1 = point(HexToWorld(pt1:xy()))
	pt2 = point(HexToWorld(pt2:xy()))
	
	local done_func = test and function(o) table.insert_unique(test, o) end or DoneObject
	local update_vis = test and empty_func or function(o) o:UpdateVisuals() end
	
	if is_hub1 then
		if not IsBeingDestructed(building1) then
			if hanging_cable or should_delete then
				done_func(building1)
			else
				update_vis(building1)
			end
		end
	elseif not test then -- destroy building-to-hub connection
		local attaches = building1:GetAttaches(all_cable_connection_classes)
		local a = CalcOrientation(pt2, pt1) - building1:GetAngle()
		local offset = Rotate((pt1 - building1:GetPos()):SetZ(0), -building1:GetAngle())
		iterate_and_destroy(attaches, a, offset)
	end
	if is_hub2 then
		if not IsBeingDestructed(building2) then
			if hanging_cable or should_delete then
				done_func(building2)
			else
				update_vis(building2)
			end
		end
	elseif not test then -- destroy building-to-hub connection
		local attaches = building2:GetAttaches(all_cable_connection_classes)
		local a = CalcOrientation(pt1, pt2) - building2:GetAngle()
		local offset = Rotate((pt2 - building2:GetPos()):SetZ(0), -building2:GetAngle())
		iterate_and_destroy(attaches, a, offset)
	end
	IsCascadeDeleting = false
end

function ElectricityGrid:GetUISectionPowerGridRollover()
	local items =  
	{
		T(572, "Power grid parameters. Power reserve indicates the duration that the stored energy will last with the current consumption.<newline>"),
		T{319, "Max production<right><power(production)>", self},
		T{573, "Power consumption<right><power(current_consumption)>", current_consumption = self.current_consumption},
	}
	if self.production > self.consumption then
		items[#items+1]= T{574, "Unused Power<right><power(number)>", number = self.production - self.consumption, self}
	elseif self.production < self.consumption then
		items[#items+1]= T{575, "Insufficient production<right><power(number)>", number = self.consumption - self.production, self}
	end
	return table.concat(items, "<newline><left>")
end

DefineClass.ElectricityGridObject = {
	__parents = { "SupplyGridObject" },
	electricity = false,
}

function ElectricityGridObject:GameInit()
	self:CreateElectricityElement()
	self:SupplyGridConnectElement(self.electricity, ElectricityGrid)
end

function ElectricityGridObject:DeleteElectricity()
	if not self.electricity then
		return
	end
	self:SupplyGridDisconnectElement(self.electricity, ElectricityGrid)
	self.electricity = false
end

function ElectricityGridObject:Done()
	self:DeleteElectricity()
end

function ElectricityGridObject:OnDestroyed()
	self:DeleteElectricity()
end

-- override this function to create electricity element - it is called before ancestors' GameInit
function ElectricityGridObject:CreateElectricityElement()
end

function ElectricityGridObject:MoveInside(dome)
	Building.MoveInside(self, dome)
	
	local grid = self.electricity.grid
	grid:RemoveElement(self.electricity)

	local game_map = GetGameMap(self)
	local supply_connection_grid = game_map.supply_connection_grid
	local supply_overlay_grid = game_map.supply_overlay_grid
	local el_connection_grid = supply_connection_grid["electricity"]
	local shape = self:GetSupplyGridConnectionShapePoints("electricity")
	ApplyIDToOverlayGrid(supply_overlay_grid, self, shape, 240, "band")
	local connections = SupplyGridRemoveBuilding(el_connection_grid, self, shape)
	local object_hex_grid = GetObjectHexGrid(self)

	-- destroy connections
	for i = 1, #(connections or ""), 2 do
		local pt, other_pt = connections[i], connections[i + 1]
		local others = object_hex_grid:GetObjectsAtPos(other_pt, nil, nil, function(o)
			return GetGrid(o, "electricity")
		end)
		for i = 1, #others do
			ElectricityGrid.DestroyConnection(pt, other_pt, self, others[i])
		end
	end
	
	if #grid.elements <= 0 then
		grid:delete()
	end
	
	self.electricity.parent_dome = dome
	dome:AddToLabel("SupplyGridBuildings", self)
	local dome_grid = dome.electricity.grid
	dome_grid:AddElement(self.electricity)
end
----- ElectricityGridElement
const.GroundOffsetForLosTest = 15*guim --about the height of a pipe

DefineClass.ElectricityGridElement = { -- cables
	__parents = {"ElectricityGridObject", "TransportGridObject", "Shapeshifter", "Constructable", "DustGridElement", "SupplyGridSwitch", "BreakableSupplyGridElement"},
	flags = { gofPermanent = true },
	properties = {
		{name = "Connections", id = "conn", editor = "number"},
	},
	
	conn = -1,
	is_tall = false,
	is_hub = false,
	pillar = false,
	chain = false,
	unbuildable_chunk_dir = false, --el pillars can only conn in one dir, this keeps that dir
	force_hub = false,
	
	--construction
	construction_cost_Metals = 1 * const.ResourceScale,
	build_points = 1000,
	construction_entity = "Hex1_Placeholder",
	--construction ui
	description = T(935, "Power Cable"),
	display_name = T(935, "Power Cable"),
	display_name_pl = T(881, "Power Cables"),
	display_icon = "UI/Icons/Buildings/power_cables.tga", --pin dialog icon during construction
	
	construction_connections = -1,
	
	--switch visuals
	on_state = "idle",
	off_state = "off",
	switch_anim = "switch",
	rename_allowed = false,
}

function ElectricityGridElement:GameInit()
	if not self.entity then
		self:UpdateVisuals()
	end
end

function ElectricityGridElement:CreateElectricityElement()
	self.electricity = SupplyGridElement:new{ building = self, is_cable_or_pipe = true }
end

function ElectricityGridElement:GetInfopanelTemplate()
	if self:IsKindOf("ConstructionSite") then return "ipBuilding" end
	if self.is_switch then return "ipSwitch" end
	if self.auto_connect then return "ipLeak" end
end

function ElectricityGridElement:GetDisplayName()
	if self.repair_resource_request then
		return T(3890, "Cable Fault")
	else
		return SupplyGridSwitch.GetDisplayName(self)
	end
end

local full_connections = { 63 * 256 + 128 }
local full_connections_switched = { 63 * 256 + 128 + 16384}
local pipe_connections = { (1 + 8) * 256 + 128 }
local pipe_connections_switched = { (1 + 8) * 256 + 128 + 16384}

function ElectricityGridElement:GetShapeConnections(supply_resource)
	return self.chain and (not self.switched_state and pipe_connections or pipe_connections_switched) or not self.switched_state and full_connections or full_connections_switched
end

function ElectricityGridElement:Done()
	--self.is_switch = false
	CablePiecesDelledThisCascade = (CablePiecesDelledThisCascade or 0) + (IsCascadeDeleting and 1 or 0)
end

function ElectricityGridElement:Switch(broadcast)
	if not self.is_switch then return end
	local city = Cities[self:GetMapID()]
	city:SetCableCascadeDeletion(false, "switch") --so that grid disconnects do not provoke cascade cable deletion
	SupplyGridSwitch.Switch(self, broadcast)
	city:SetCableCascadeDeletion(true, "switch")
end

function ElectricityGridElement:UpdateVisuals()
	local supply_connection_grid = GetSupplyConnectionGrid(self)
	local conn = HexGridGet(supply_connection_grid["electricity"], self)
	if self.conn == conn then return false end
	self.conn = conn
	local total_count, cable_count, first, second = 0, 0
	local q, r = WorldToHex(self)
	local cables = 0
	local chained_cables = {}
	local object_hex_grid = GetObjectHexGrid(self)
	for dir = 0, 5 do
		if testbit(conn, dir) then
			local dq, dr = HexNeighbours[dir + 1]:xy()
			local c = HexGetCable(object_hex_grid, q + dq, r + dr)
			if c then
				chained_cables[dir] = c.chain
				cables = bor(cables, shift(1, dir))
				second = second or first and dir
				first = first or dir
				cable_count = cable_count + 1
			end
			
			total_count = total_count + 1
		end
	end
	self:DestroyAttaches(AllPossiblePlugs)
	
	local cm1, cm2, cm3, cm4 = GetCablesPalette()
	
	local is_turn = not second or not first or second - first ~= 3 --any other entity is a turn
	local map_id = self:GetMapID()
	if self.pillar then
		--pillars are more or less like hubs, but plugs should consider whether adjacent is elevated or not
		self:ChangeEntity("CableTower")
		local is_constr_colored = self:GetGameFlags(const.gofWhiteColored) ~= 0
		for dir = 0, 5 do
			if testbit(cables, dir) then -- add plug, we have removed the existing plugs
				local chain = chained_cables[dir]
				local plug = false
				if chain then
					if dir < 3 then
						plug = PlaceObjectIn(ElectricGridElevatedPlugEntities[1], map_id)
						self:Attach(plug)	
						plug:SetAttachAngle(dir * 60 * 60 - self:GetAngle())
						plug:SetChainParams(chain.delta, 0, chain.length)
					else
						plug = PlaceObjectIn(ElectricGridElevatedPlugEntities[2], map_id)
						self:Attach(plug)
						plug:SetAttachAngle((dir % 3) * 60 * 60 - self:GetAngle())
						plug:SetChainParams(chain.delta, chain.length, chain.length)
					end
				else
					plug = PlaceObjectIn(ElectricGridHubPlugEntities[1], map_id)
					self:Attach(plug)
					plug:SetAttachAngle(dir * 60 * 60 - self:GetAngle())
				end
				plug:SetEnumFlags(const.efSelectable)
								
				if is_constr_colored then
					plug:SetGameFlags(const.gofWhiteColored)
				end
			end
		end
	elseif not self.force_hub and not self.is_switch and cable_count == 2 and (not is_turn or total_count == 2) then -- exactly two connections with cabels
		if self.chain then
			--chained segs should always be with 2 conns
			self:ChangeEntity("CableHanging")
			self:SetPos(self:GetPos():SetZ(self.chain.base)) --temp presnetation
			self:SetChainParams(self.chain.delta, self.chain.index, self.chain.length)
		else
			local idx = second - first
			if idx == 3 then --str8
				idx = idx + 3
			end
			self:ChangeEntity(ElectricGridCableDirectionRelationToEntity[idx])
		end
		self:SetAngle(first * 60 * 60)
		self.is_hub = nil
	else -- other than two connections
		self:ChangeEntity(self.is_switch and "CableSwitch" or "CableHub")
		self:SetAngle(0)
		self.is_hub = true
		local is_constr_colored = self:GetGameFlags(const.gofWhiteColored) ~= 0
		for dir = 0, 5 do
			if testbit(cables, dir) then -- add plug, we have removed the existing plugs
				local plug = PlaceObjectIn(ElectricGridHubPlugEntities[1], map_id)
				plug:SetEnumFlags(const.efSelectable)
				self:Attach(plug)
				plug:SetAttachAngle(dir * 60 * 60)
				if is_constr_colored then
					plug:SetGameFlags(const.gofWhiteColored)
				end
			end
		end
	end
	SetObjectPaletteRecursive(self, cm1, cm2, cm3, cm4)
	
	self:AddDust(0) --refresh dust visuals
	
	return true
end

function ElectricityGridElement:CanMakePillar(direction)
	if self.pillar then return direction == self.unbuildable_chunk_dir end --cable pillars can only connect from 1 angle with floaty cables.
	local q, r = WorldToHex(self)
	local object_hex_grid = GetObjectHexGrid(self)
	local pipe = HexGetPipe(object_hex_grid, q, r)
	return pipe == nil or excluded_obj and pipe == excluded_obj
end

function ElectricityGridElement:MakePillar(direction)
	assert(self:CanMakePillar(direction))
	self.pillar = true
	self.unbuildable_chunk_dir = direction
	self:UpdateVisuals()
end

function ElectricityGridElement:TryConnectInDir(dir)
	if self.switched_state then return end
	
	local conn = self.conn
	if not testbit(conn, dir) and testbit(shift(conn, -8), dir) then --not connected yet and has potential
		local dq, dr = HexNeighbours[dir + 1]:xy()
		local my_q, my_r = WorldToHex(self)
		local game_map = GetGameMap(self)
		local object_hex_grid = game_map.object_hex_grid

		local obj = HexGetCable(object_hex_grid, my_q + dq, my_r + dr)
		if obj and obj.electricity then --its a cable or cable constr
			local supply_connection_grid = game_map.supply_connection_grid
			local his_conn = HexGridGet(supply_connection_grid["electricity"], obj)
			if testbit(shift(his_conn, -8), dir) then --he also has potential
				ElectricityGrid.CreateConnection(point(my_q, my_r), point(my_q + dq, my_r + dr), self, obj)

				if self.class == obj.class and self.electricity.grid ~= obj.electricity.grid then --both constr or both finished but diff grids, merge
					local my_grid_count = #self.electricity.grid.elements
					local his_grid_count = #obj.electricity.grid.elements
					local my_grid_has_more_elements = my_grid_count > his_grid_count
					local supply_overlay_grid = game_map.supply_overlay_grid
					MergeGrids(supply_overlay_grid, supply_connection_grid, my_grid_has_more_elements and self.electricity.grid or obj.electricity.grid,
									my_grid_has_more_elements and obj.electricity.grid or self.electricity.grid)
				elseif self.class ~= obj.class then --constr grid vs real grid, acknowledge conn
					ConnectGrids(self.electricity, obj.electricity)
				end
			end
		end
	end
end

function ElectricityGridElement:GetFlattenShape()
	return FallbackOutline
end

function ElectricityGridElement:CanBreak()
	if UIColony:IsTechResearched("SuperiorCables") then
		return false
	end
	return BreakableSupplyGridElement.CanBreak(self)
end

const.SupplyGridElementsAllowUnbuildableChunksCables = false
const.CableLOSTestGranularity = 5

SupplyGridElementHexStatus = {
	clear = 1, --np
	unbuildable = 2, --can only place chain line
	blocked = 3, --cant place here
	unbuildable_blocked = 4, --special case when building in unbuildable is toggled off
}

local hex_verts
max_z_delta_for_cable_placement = 3 * guim
function CableBuildableTest(game_map, pos, q, r, hv, max_z_delta) --tests flatness and passability
	max_z_delta = max_z_delta or max_z_delta_for_cable_placement
	hv = hv or hex_verts
	if game_map.buildable:IsBuildable(q, r) then
		return true
	end
	
	local terrain = game_map.terrain
	local realm = game_map.realm

	--test passability and zd for buildable
	if not terrain:IsPassable(pos) then
		return false
	end
	
	local original_z = realm:GetWalkableZ(pos)
	local biggest_z_d = 0
	
	if not hv then --build verts
		local v = point(HexGetSize() * 8 / 10, 0)
		hv = { v }
		for i = 1, 5 do
			hv[i + 1] = Rotate(v, i * 60 * 60)
		end
	end
	
	for _, offset in ipairs(hv) do
		local pt = pos + offset
		if not terrain:IsPassable(pt) then
			return false
		end
		biggest_z_d = Max(biggest_z_d, abs(realm:GetWalkableZ(pt) - original_z))
	end
	
	return biggest_z_d <= max_z_delta, original_z
end

function PlaceCableLine(city, start_q, start_r, dir, steps, test, elements_require_construction, input_constr_grp, input_data, supplied)
	local dq, dr = HexNeighbours[dir + 1]:xy()
	local z = const.InvalidZ
	local connect_dir = dir < 3 and dir or dir - 3
	local angle = dir * 60 * 60
	
	local construction_group = false
	local cs_grp_counter_for_cost = 1
	local cs_grp_elements_in_this_group = 0
	if not test and elements_require_construction or input_constr_grp then
		if input_constr_grp then
			construction_group = input_constr_grp
			cs_grp_counter_for_cost = cs_grp_counter_for_cost - 1
			cs_grp_elements_in_this_group = #input_constr_grp - 1
		else
			construction_group = CreateConstructionGroup("ElectricityGridElement", point(HexToWorld(start_q, start_r)), city:GetMapID(), 3, not elements_require_construction)
			construction_group[1].supplied = supplied
		end
	end
	
	local function clean_group(construction_group)
		if construction_group and construction_group[1]:CanDelete() then --it only has a leader.
			DoneObject(construction_group[1])
			construction_group = false
		end
		return construction_group
	end
	
	local last_status = false
	local last_placed_data_cell = nil
	local last_pass_idx = 0
	
	local has_group_with_no_hub = false
	local current_group_has_hub = false
	
	if input_data and #input_data > 0 then
		last_placed_data_cell = input_data[#input_data]
		last_pass_idx = last_placed_data_cell.idx
		last_status = last_placed_data_cell.status
		cs_grp_counter_for_cost = input_data.cs_grp_counter_for_cost or cs_grp_counter_for_cost
		cs_grp_elements_in_this_group = Max((input_data.cs_grp_elements_in_this_group or cs_grp_elements_in_this_group) - 1, 0)
		has_group_with_no_hub = input_data.has_group_with_no_hub
		current_group_has_hub = input_data.current_group_has_hub
		if input_data.last_group_had_no_hub then
			has_group_with_no_hub = false
		end
	end
	
	--preprocess
	local data = {} --step = { q, r, status }, 
	local unbuildable_chunks = {} --unbuildable_chunks = {chunk_start, chunk_end, status}
	local obstructors = {}
	local all_rocks = {}
	local chunk_idx = 0
	local can_build_anything = false
	local chunk_has_blocked_members = false
	local surf_deps_filter = function(obj) return not table.find(obstructors, obj) end
	local stockpile_filter = function(obj) return obj:GetParent() == nil and IsKindOf(obj, "DoesNotObstructConstruction") and not IsKindOf(obj, "Unit") end
	local game_map = GetGameMap(city)
	local object_hex_grid = game_map.object_hex_grid
	local realm = game_map.realm
	local terrain = game_map.terrain

	for i = 0, steps do
		local q = start_q + i * dq
		local r = start_r + i * dr
		local bld = object_hex_grid:GetObject(q, r, nil, "TransportGridObject",
						function (obj)
							return not IsKindOfClasses(obj, "GridSwitchConstructionSite")
						end)
		local cable = HexGetCable(object_hex_grid, q, r)
		local pipe = HexGetPipe(object_hex_grid, q, r)
		local world_pos = point(HexToWorld(q, r))
		local is_buildable, override_z = CableBuildableTest(game_map, world_pos, q, r, hex_verts, max_z_delta_for_cable_placement)
		local surf_deps = is_buildable and HexGetUnits(realm, nil, nil, world_pos, 0, nil, surf_deps_filter, "SurfaceDeposit") or empty_table
		local rocks = is_buildable and HexGetUnits(realm, nil, nil, world_pos, 0, false, nil, "WasteRockObstructor") or empty_table
		table.iappend(all_rocks, rocks)
		local stockpiles = is_buildable and HexGetUnits(realm, nil, nil, world_pos, 0, false, stockpile_filter, "ResourceStockpileBase") or empty_table
		
		override_z = override_z or is_buildable and realm:GetWalkableZ(world_pos) -- don't flatten the terrain
		
		data[i] = i == 0 and last_placed_data_cell ~= nil and last_placed_data_cell or {q = q, r = r, status = SupplyGridElementHexStatus.clear, cable = cable, rocks = rocks, stockpiles = stockpiles, pipe = pipe, idx = last_pass_idx + i, bld = bld, can_make_pillar = not pipe, override_z = override_z}
		data[i].place_construction_site = elements_require_construction or construction_group or #rocks > 0 or #stockpiles > 0
		data[i].chunk = data[i].chunk or unbuildable_chunks[chunk_idx] and (not unbuildable_chunks[chunk_idx].chunk_end or unbuildable_chunks[chunk_idx].chunk_end < 0) and unbuildable_chunks[chunk_idx] or nil
		--test current hex
		if bld then
			table.insert(obstructors, bld)
			data[i].status = SupplyGridElementHexStatus.blocked
			data[i].can_make_pillar = false
		end
		
		if surf_deps and #surf_deps > 0 then
			table.iappend(obstructors, surf_deps)
			data[i].status = SupplyGridElementHexStatus.blocked
			data[i].can_make_pillar = false
		end
		
		if not is_buildable then
			data[i].status = const.SupplyGridElementsAllowUnbuildableChunksCables and SupplyGridElementHexStatus.unbuildable or SupplyGridElementHexStatus.unbuildable_blocked
			data[i].can_make_pillar = false
		end
		
		if not const.SupplyGridElementsAllowUnbuildableChunksCables and last_status == SupplyGridElementHexStatus.unbuildable_blocked then
			data[i].status = SupplyGridElementHexStatus.unbuildable_blocked
		end
		
		--analyze status
		if last_status then
			if (last_status == SupplyGridElementHexStatus.clear and data[i].status == SupplyGridElementHexStatus.unbuildable)
				or (last_placed_data_cell and i == 1 --sepcifically for placement tool visuals, catch turn
					and data[i].status == SupplyGridElementHexStatus.unbuildable 
					and (last_status == SupplyGridElementHexStatus.blocked or last_status == SupplyGridElementHexStatus.unbuildable)) 
				or (data[i].chunk == nil 
					and ((last_status == SupplyGridElementHexStatus.unbuildable and data[i].status == SupplyGridElementHexStatus.clear)
						or (last_status == SupplyGridElementHexStatus.blocked and data[i].status == SupplyGridElementHexStatus.unbuildable)))then --sepcifically for placement tool visuals, catch ful
				--it's a new unbuildable chunk
				chunk_idx = chunk_idx + 1
				
				local chunk = { chunk_start = i + last_pass_idx - 1, chunk_end = -(i + last_pass_idx), status = SupplyGridElementHexStatus.blocked, connect_dir = connect_dir }
				chunk.place_construction_site = data[i].place_construction_site
				
				local start_node = data[i - 1]
				if start_node.chunk then
					start_node.chunk_end = start_node.chunk
					start_node.chunk_end.chunk_end = i + last_pass_idx - 1
				end
				start_node.chunk_start = chunk
				start_node.chunk = chunk
				data[i].chunk = chunk
				chunk.z1 = buildable:IsBuildable(start_node.q, start_node.r) and buildable:GetZ(start_node.q, start_node.r) or terrain:GetHeight(HexToWorld(start_node.q, start_node.r))
				chunk_has_blocked_members = false
				
				unbuildable_chunks[chunk_idx] = chunk
				
				if not start_node.can_make_pillar 
					or (start_node.cable and not start_node.cable:CanMakePillar(connect_dir)) then
					--this chunk is blocked
					local o = start_node.pipe or (start_node.cable and not start_node.cable:CanMakePillar(connect_dir)) and start_node.cable
					if o then
						table.insert(obstructors, o)
					end
					chunk_has_blocked_members = true
				end
			elseif last_status == SupplyGridElementHexStatus.unbuildable and data[i].status == SupplyGridElementHexStatus.blocked 
				and unbuildable_chunks[chunk_idx] then
				--blocked chunk
				unbuildable_chunks[chunk_idx].status = SupplyGridElementHexStatus.blocked
				chunk_has_blocked_members = true
			elseif last_status == SupplyGridElementHexStatus.unbuildable and data[i].status == SupplyGridElementHexStatus.clear 
				and unbuildable_chunks[chunk_idx] and unbuildable_chunks[chunk_idx].chunk_end < 0 then
				--possible buildable unbuildable chunk
				unbuildable_chunks[chunk_idx].chunk_end = i + last_pass_idx
				data[i].chunk_end = unbuildable_chunks[chunk_idx]
				unbuildable_chunks[chunk_idx].place_construction_site = unbuildable_chunks[chunk_idx].place_construction_site or data[i].place_construction_site
				unbuildable_chunks[chunk_idx].status = not chunk_has_blocked_members and SupplyGridElementHexStatus.clear or unbuildable_chunks[chunk_idx].status
				--build z data
				local cell_data = data[unbuildable_chunks[chunk_idx].chunk_start - last_pass_idx]
				local x1, y1 = HexToWorld(cell_data.q, cell_data.r)
				local z1 = unbuildable_chunks[chunk_idx].z1
				local x2, y2 = world_pos:x(), world_pos:y()
				local z2 = buildable:GetZ(q, r)
				unbuildable_chunks[chunk_idx].z2 = z2
				unbuildable_chunks[chunk_idx].zd = z2 - z1
				--test for pipe
				if not data[i].can_make_pillar or data[i].cable and not data[i].cable:CanMakePillar(connect_dir) then
					unbuildable_chunks[chunk_idx].status = SupplyGridElementHexStatus.blocked
				else
					--test los
					local chain = GetChainParams(0, unbuildable_chunks[chunk_idx].chunk_end - unbuildable_chunks[chunk_idx].chunk_start, dir, unbuildable_chunks[chunk_idx], true)
					
					local pt_start, pt_end
					if chain.index == 0 then
						pt_start = point(x1, y1, z1)
						pt_end = point(x2, y2, z2)
					else
						pt_start = point(x2, y2, z2)
						pt_end = point(x1, y1, z1)
					end
					
					local offset_cable_1 = RotateAxis(GetEntitySpotPos(CableTower:GetEntity(), GetSpotBeginIndex(CableTower:GetEntity(), "idle", "Lowercable1")), axis_z, angle)
					local offset_cable_2 = RotateAxis(GetEntitySpotPos(CableTower:GetEntity(), GetSpotBeginIndex(CableTower:GetEntity(), "idle", "Lowercable2")), axis_z, angle)
					local LOSTestLines = CalculateCableLOSTestLines(pt_start, pt_end, chain.delta, chain.length, const.CableLOSTestGranularity)
					
					for _, line in pairs(LOSTestLines) do
						-- ShowMe({line[1] + offset_cable_1, line[2] + offset_cable_1}, nil, 4000)
						-- ShowMe({line[1] + offset_cable_2, line[2] + offset_cable_2}, nil, 4000)
						if not realm:CheckLineOfSight(line[1] + offset_cable_1, line[2] + offset_cable_1) or not realm:CheckLineOfSight(line[1] + offset_cable_2, line[2] + offset_cable_2) then
							unbuildable_chunks[chunk_idx].status = SupplyGridElementHexStatus.blocked
							break
						end
					end
										
				end
			end
			if data[i].chunk and data[i].chunk.chunk_end < 0 then
				data[i].chunk.chunk_end = -(i + last_pass_idx)
				local x, y = world_pos:x(), world_pos:y()
				data[i].chunk.z2 = buildable:IsBuildable(q, r) and buildable:GetZ(q, r) or terrain:GetHeight(x, y)
				data[i].chunk.zd = data[i].chunk.z2 - data[i].chunk.z1
			end
		end
		
		if data[i].status == SupplyGridElementHexStatus.unbuildable and not data[i].chunk then
			data[i].status = SupplyGridElementHexStatus.blocked
		end
		
		if not can_build_anything and data[i].status == SupplyGridElementHexStatus.clear then
			can_build_anything = true
		end
		
		if cs_grp_elements_in_this_group >= const.ConstructiongGridElementsGroupSize then
			cs_grp_counter_for_cost = cs_grp_counter_for_cost + 1
			cs_grp_elements_in_this_group = 1
			
			if not current_group_has_hub then
				has_group_with_no_hub = true
			else
				current_group_has_hub = false
			end
		elseif not (data[i] ~= last_placed_data_cell and cable and construction_group and table.find(construction_group, cable)) then
			cs_grp_elements_in_this_group = cs_grp_elements_in_this_group + 1
		end
		
		if not current_group_has_hub and not has_group_with_no_hub then
			if DoesAnyDroneControlServiceAtPoint(game_map.map_id, world_pos) then
				current_group_has_hub = true
			end
		end
		
		last_status = data[i].status
	end
	
	data.cs_grp_counter_for_cost = cs_grp_counter_for_cost
	data.cs_grp_elements_in_this_group = cs_grp_elements_in_this_group
	local total_cost = GetGridElementConstructionCost("ElectricityGridElement", false, cs_grp_counter_for_cost * 100)
	
	if not current_group_has_hub and not has_group_with_no_hub then
		has_group_with_no_hub = true
		data.last_group_had_no_hub = true
	end
	data.has_group_with_no_hub = has_group_with_no_hub
	data.current_group_has_hub = current_group_has_hub
	
	--fix up chunk end
	if chunk_idx > 0 then
		local last_chunk = unbuildable_chunks[#unbuildable_chunks]
		if last_chunk.chunk_end < 0 then
			last_chunk.chunk_end = abs(last_chunk.chunk_end)
			data[last_chunk.chunk_end - last_pass_idx].chunk_end = last_chunk
		end
	end

	if test or not can_build_anything then
		--ret
		construction_group = clean_group(construction_group)
		return can_build_anything, construction_group, obstructors, data, unbuildable_chunks, all_rocks, total_cost
	end
	
	--postprocess and place
	local proc_placed_cable = function(data_idx, cell_data, pillar, chain, connect_dir, cg)
		if cell_data.cable then
			if pillar then
				cell_data.cable:SetAngle(angle)
				cell_data.cable:MakePillar(connect_dir)
				if cg and cell_data.cable:GetGameFlags(const.gofUnderConstruction) ~= 0 and pillar == max_int then
					cell_data.cable:ChangeConstructionGroup(cg)
				end
			elseif not chain and data_idx ~= steps then
				cell_data.cable:TryConnectInDir(dir)
			end
			
			return cell_data.cable
		end
		
		return false
	end
	
	local place_cable_cs = function(data_idx, cg, pillar, chain, connect_dir)
		local params = {}
		local cell_data = data[data_idx]
		local c = proc_placed_cable(data_idx, cell_data, pillar, chain, connect_dir, cg)
		if c then return c end
		local q = cell_data.q
		local r = cell_data.r
		
		params.construction_group = cg
		cg[#cg + 1] = params
		params.connect_dir = connect_dir
		params.pillar = pillar
		params.chain = chain
		params.unbuildable_chunk_dir = connect_dir
		
		local pos = point(HexToWorld(q, r))
		if cell_data.override_z then
			pos = pos:SetZ(cell_data.override_z)
		end
		local cs = PlaceConstructionSite(city, "ElectricityGridElement", pos, angle, params, nil, chain or cell_data.override_z)
		if not chain then --chain cables are in unbuildable places so drones might not be able to cleanup
			cs:AppendWasteRockObstructors(cell_data.rocks)
			cs:AppendStockpilesUnderneath(cell_data.stockpiles)
		end
		cell_data.cable = cs
		return cs
	end
	
	local cm1, cm2, cm3, cm4 = GetCablesPalette()
	local InvalidZ = const.InvalidZ
	local place_cable = function(data_idx, pillar, chain, connect_dir)
		local cell_data = data[data_idx]
		local c = proc_placed_cable(data_idx, cell_data, pillar, chain, connect_dir)
		if c then return c end
		local q = cell_data.q
		local r = cell_data.r
		local el = ElectricityGridElement:new({ connect_dir = connect_dir, pillar = pillar, chain = chain, unbuildable_chunk_dir = connect_dir }, city:GetMapID())
		local x, y = HexToWorld(q, r)
		el:SetPos(x, y, cell_data.override_z or InvalidZ)
		el:SetAngle(angle)
		el:SetGameFlags(const.gofPermanent)
		if not chain and not cell_data.override_z then
			FlattenTerrainInBuildShape(nil, el)
		end
		SetObjectPaletteRecursive(el, cm1, cm2, cm3, cm4)
		cell_data.cable = el
		return el
	end
	
	chunk_idx = 1
	local i = 0
	local last_placed_obj
	
	while i <= steps do
		local cell_data = data[i]
		local q = cell_data.q
		local r = cell_data.r
		local is_chunk_start = unbuildable_chunks[chunk_idx] and unbuildable_chunks[chunk_idx].chunk_start == (i + last_pass_idx)
		
		if is_chunk_start and unbuildable_chunks[chunk_idx].status == SupplyGridElementHexStatus.clear then
			--place buildable unbuildable chunk
			local chunk_data = unbuildable_chunks[chunk_idx]
			local length = chunk_data.chunk_end - chunk_data.chunk_start
			if chunk_data.place_construction_site then
				--place construction group, chunks are their own groups
				local chunk_construction_group = CreateConstructionGroup("ElectricityGridElement", point(HexToWorld(q, r)), city:GetMapID(), 3, not elements_require_construction)
				local chunk_group_leader = chunk_construction_group[1]
				chunk_group_leader.supplied = supplied
				chunk_group_leader.construction_cost_multiplier = 500
				--add pillar 1
				local p1 = place_cable_cs(i, chunk_construction_group, max_int, nil, connect_dir)
				--place the lines
				for j = i + 1, chunk_data.chunk_end - 1 - last_pass_idx do
					local chain = GetChainParams(j + last_pass_idx - chunk_data.chunk_start, length, dir, chunk_data, true)
					local cable = place_cable_cs(j, chunk_construction_group, nil, chain, connect_dir)
					cable:SetChainParams(chain.delta, chain.index, chain.length)
				end
				local p2 = place_cable_cs(chunk_data.chunk_end - last_pass_idx, chunk_construction_group, max_int, nil, connect_dir)
				if chunk_group_leader:CanDelete() then
					--line was already placed
					DoneObject(chunk_group_leader)
				else
					chunk_group_leader.drop_offs = {p1, p2}
					last_placed_obj = p2
				end
			else
				--place instant
				local p1 = place_cable(i, max_int, nil, connect_dir)
				for j = i + 1, chunk_data.chunk_end - 1 - last_pass_idx do
					local chain = GetChainParams(j + last_pass_idx - chunk_data.chunk_start, length, dir, chunk_data, true)
					local cable = place_cable(j, nil, chain, connect_dir)
					cable:SetChainParams(chain.delta, chain.index, chain.length)
				end
				local p2 = place_cable(chunk_data.chunk_end - last_pass_idx, max_int, nil, connect_dir)
				last_placed_obj = p2
			end
			
			i = chunk_data.chunk_end - last_pass_idx
		else
			--place regular cable
			if data[i].status == SupplyGridElementHexStatus.clear then
				local placed = false
				if cell_data.place_construction_site then
					--make new group if needed
					if not construction_group or #construction_group > const.ConstructiongGridElementsGroupSize then
						if construction_group and construction_group[1]:CanDelete() then
							DoneObject(construction_group[1])
						end
						
						construction_group = false
						
						--new group
						if elements_require_construction or #data[i].rocks > 0 or #data[i].stockpiles > 0 then
							construction_group = CreateConstructionGroup("ElectricityGridElement", point(HexToWorld(q, r)), city:GetMapID(), 3, not elements_require_construction)
							construction_group[1].supplied = supplied
						end
					end
					
					if construction_group then
						last_placed_obj = place_cable_cs(i, construction_group, nil, nil, connect_dir)
						placed = last_placed_obj
					end
				end
				
				if not placed then
					last_placed_obj = place_cable(i, nil, nil, connect_dir)
				end
			end
		end
		
		--increment counters
		if is_chunk_start then
			if unbuildable_chunks[chunk_idx].status ~= SupplyGridElementHexStatus.clear then
				if unbuildable_chunks[chunk_idx].chunk_end then
					i = unbuildable_chunks[chunk_idx].chunk_end - 1 - last_pass_idx
				else
					i = steps + 1
				end
			end
			
			chunk_idx = chunk_idx + 1
			
			if unbuildable_chunks[chunk_idx] and unbuildable_chunks[chunk_idx].status == SupplyGridElementHexStatus.clear 
				and unbuildable_chunks[chunk_idx].chunk_start == (i + last_pass_idx) then
				--next chunk starts @ this chunk's end
				i = i - 1 
			end
		end
		
		i = i + 1
	end
	
	construction_group = clean_group(construction_group)
	
	return true, construction_group, obstructors, data, unbuildable_chunks, last_placed_obj, total_cost
end
