DefineClass.GridConstructionDialog = {
	__parents = { "InterfaceModeDialog" },
	mode_name = "electricity_grid",
	MouseCursor =  "UI/Cursors/CablePlacement.tga",
	success_sound = "CableConstructionSuccess",
	grid_elements_require_construction = false,
}

function GridConstructionDialog:Init()
	for k,v in pairs(self.context) do
		self[k] = v
	end
	table.change(hr, "Construction", { RenderBuildGrid = 1, BuildGridRadius = 13000 })
	self:SetModal(true)
	HideGamepadCursor("construction")
	ShowResourceIcons("construction")
	
	if GetUIStyleGamepad() then
		self:CreateThread("GamepadCursorUpdate", UpdateConstructionCursorObject, GetGridConstructionController())
	end
end

function GridConstructionDialog:Open(...)
	InterfaceModeDialog.Open(self, ...)
	local city = UICity
	local controller = GetGridConstructionController(city)
	controller:SetMode(self.mode_name)
	if self.mode_name == "passage_grid" then
		OpenAllDomes()
	end
	if self.mode_name == "life_support_grid" then
		controller:InitHelpers()
	end
	
	controller.grid_elements_require_construction = self.grid_elements_require_construction
	controller.last_update_hex = false
	self:OnMousePos() --initial update
	DelayedCall(0, OpenGridConstructionInfopanel)
end

function GridConstructionDialog:Close(...)
	InterfaceModeDialog.Close(self, ...)
	while not GetGridConstructionController():Deactivate() do end
	table.restore(hr, "Construction")
	ShowGamepadCursor("construction")
	HideResourceIcons("construction")
	if self.mode_name == "passage_grid" then
		CloseAllDomes()
	end
	if self:IsThreadRunning("GamepadCursorUpdate") then
		self:DeleteThread("GamepadCursorUpdate")
	end
	local dlg = GetHUD()
	if dlg then dlg.idtxtConstructionStatus:SetVisible(false) end	
end

function GridConstructionDialog:TryPlace(pos)
	if GetGridConstructionController():Activate(HexGetNearestCenter(pos)) then
		PlayFX(self.success_sound, "start")
	else
		PlayFX("ConstructionFail", "start")
	end
end

function GridConstructionDialog:OnMouseButtonDown(pt, button)
	if button == "L" then
		self:TryPlace(GetTerrainCursor())
	elseif button == "R" then
		if GetGridConstructionController():Deactivate(pt) then
			PlayFX("GridConstructionCancel", "start")
			CloseModeDialog()
			return "break"
		end
	elseif button == "M" then
		self:ToggleBuildDirection()
		return "break"
	end
end

function GridConstructionDialog:OnMousePos(pt)
	local terrain_pos = GetConstructionTerrainPos("mouse")
	if GetActiveTerrain():IsPointInBounds(terrain_pos) then
		GetGridConstructionController():UpdateCursor(terrain_pos)
	end
	return "break"
end

function GridConstructionDialog:ToggleBuildDirection()
	GetGridConstructionController():Rotate()
end

function GridConstructionDialog:OnKbdKeyDown(virtual_key)
	if virtual_key == const.vkEsc then
		self:OnMouseButtonDown(nil, "R")
		return "break"
	end
end

function GridConstructionDialog:OnShortcut(shortcut, source)
	if shortcut == "ButtonA" or shortcut == "LeftTrigger-ButtonA" then
		self:TryPlace(GetTerrainGamepadCursor())
		return "break"
	elseif shortcut == "ButtonB" then
		self:OnMouseButtonDown(nil, "R") --cancel
		return "break"
	elseif shortcut == "LeftShoulder" then
		self:ToggleBuildDirection() --switch direction
		return "break"
	elseif shortcut == "RightShoulder" then
		self:ToggleBuildDirection() --switch direction
		return "break"
	elseif shortcut == "Back" or shortcut == "TouchPadClick" then
		if DismissCurrentOnScreenHint() then
			return "break"
		end
	end
end

function GridConstructionDialog:OnMouseWheelForward(...)
	GetGridConstructionController():UpdateShortConstructionStatus()
	return "continue"
end

function GridConstructionDialog:OnMouseWheelBack(...)
	GetGridConstructionController():UpdateShortConstructionStatus()
	return "continue"
end
DefineClass.GridConstructionDialogPipes = {
	__parents = { "GridConstructionDialog" },
	mode_name = "life_support_grid",
	MouseCursor = "UI/Cursors/PipePlacement.tga",
	success_sound = "PipeConstructionSuccess",
}

DefineClass.GridConstructionDialogPassage = {
	__parents = { "GridConstructionDialog" },
	mode_name = "passage_grid",
}
---

DefineClass.GridConstructionController = {
	__parents = { "ConstructionController" },
	
	properties = {
		{id = "construction_statuses_property", editor = "text", name = T{""}, translate = true, default = false},
		{id = "DisplayName",                    editor = "text", name = T{""}, translate = true, default = false},
	},
	
	ignore_domes = true,
	cursor_obj = false,
	starting_point = false,
	starting_cs_group = false,
	total_cost = false,
	visuals = false,
	water_markers = false,
	mode = "electricity_grid", --"electricity_grid" or "life_support_grid"
	max_hex_distance_to_allow_build = 20,
	max_plugs = 30, --(max_hex_distance_to_allow_build/3)*4 + 2
	grid_elements_require_construction = true,
	switch_dobule_line_directions = false,
	
	current_points = false,
	current_status = const.clrNoModifier,
	construction_statuses = false,
	
	construction_obstructors = false,
	
	last_update_hex = false,
	rocks_underneath = false,
	
	skin_name = "Default",
	
	placed_points = false,
	last_placed_points_count = false,
	current_len = 0,
	entrance_hexes = false,
	
	construction_ip = "ipGridConstruction",
}

function GridConstructionController:SetMode(mode)
	self.mode = mode
	self:UpdateCursorObject(true)
	self.construction_statuses = {}
	self.rocks_underneath = {}
	self.placed_points = {}
	self.last_placed_points_count = {}
	self.current_len = 0
end

function GridConstructionController:OnCursorObjNewPos()
	if self.mode == "life_support_grid" then
		self:UpdateCursorObject()
	end
end

function GridConstructionController:UpdateCursorObject(visible)
	if visible == nil then
		visible = not not self.cursor_obj
	end
	if visible then
		local entity
		local cm1, cm2, cm3, cm4
		local skin
		local terrain_pos = GetConstructionTerrainPos()
		local game_map = GetGameMap(self.city)
		if self.mode == "electricity_grid" then
			entity = "CableHub"
			cm1, cm2, cm3, cm4 = GetCablesPalette()
		elseif self.mode == "life_support_grid" then
			skin = TubeSkins[self.skin_name]
			entity = game_map.buildable:IsBuildableZone(terrain_pos) and skin.TubeHub or skin.TubeHubSlope
			cm1, cm2, cm3, cm4 = GetPipesPalette()
		elseif self.mode == "passage_grid" then
			entity = "PassageEntrance"
		end
		if IsValid(self.cursor_obj) then
			self.cursor_obj:DestroyAttaches()
			self.cursor_obj.entity = entity
			self.cursor_obj:ChangeEntity(entity)
		else
			self.cursor_obj = CursorAutoAttachGridElement:new{ entity = entity }
			self.cursor_obj:SetEnumFlags(const.efVisible)
			if game_map.terrain:IsPointInBounds(terrain_pos) then
				self.cursor_obj:SetPos(FixConstructPos(game_map.terrain, terrain_pos))
			end
		end
		
		AutoAttachObjectsToPlacementCursor(self.cursor_obj)
		
		if cm1 then
			SetObjectPaletteRecursive(self.cursor_obj, cm1, cm2, cm3, cm4)
		end
		self:SetTxtPosObj(self.cursor_obj)
	elseif IsValid(self.cursor_obj) then
		self.cursor_obj:delete()
		self.cursor_obj = false
	end
end

function GridConstructionController:SetTxtPosObj(obj)
	--set text pos
	local dlg = GetHUD()
	if dlg then 
		local ctrl = dlg.idtxtConstructionStatus
		ctrl:AddDynamicPosModifier({id = "construction", target = obj})
	end
end

function GridConstructionController:GetCSGroupAtStartingPoint()
	local group
	if self.mode ~= "passage_grid" then
		local realm = GetRealm(self)
		realm:MapForEach(self.starting_point, const.HexSize * 2, "ConstructionSite", function (obj, self)
			if (self.mode == "electricity_grid" and obj.building_class ~= "ElectricityGridElement") or
				(self.mode == "life_support_grid" and obj.building_class ~= "LifeSupportGridElement") then
				return
			end
			
			local his_group = obj.construction_group
			
			if (not group and #his_group <= const.ConstructiongGridElementsGroupSize) or 
				(group and his_group ~= group and #his_group < #group) then
				group = his_group
			end
		end, self)
	end
	return group
end

function GridConstructionController:Activate(pt)
	self.construction_obstructors = self.construction_obstructors or {}
	if not self.starting_point then
		-- not currently building
		local res, reason, obj = self:CanExtendFrom(pt)
		if obj then
			--extend from nearby pillar
			pt = obj:GetPos()
		end
		if res then
			self.starting_point = pt
			self.starting_cs_group = self:GetCSGroupAtStartingPoint()
			self.placed_points = { pt:SetInvalidZ() }
			self.last_update_hex = false
			self:InitVisuals(pt)
			self:UpdateVisuals(pt)
			return true
		end
	else
		if self.current_status == const.clrNoModifier or self.current_status == g_PlacementStateToColor.Problematic then
			local group
			local realm = GetRealm(self)
			--check if we can extend an existing group
			if self.mode ~= "passage_grid" then
				self:DoneVisuals()
				group = self:GetCSGroupAtStartingPoint() --reget grp, might be gone by now
				self.starting_cs_group = false
				realm:SuspendPassEdits("construction_supply_grid_line")
				local last_placed_obj
				
				if self.current_points[2] then
					local data, _

					group, _, data = self:ConstructLine(self.starting_point, self.current_points[1], nil, group)
					group, last_placed_obj = self:ConstructLine(self.current_points[1], self.current_points[2], self.current_points[1] == self.current_points[2] and self.current_points[1] or nil, group, data)
				else
					group, last_placed_obj = self:ConstructLine(self.starting_point, self.current_points[1], nil, group)
				end
				realm:ResumePassEdits("construction_supply_grid_line")
				Msg("PlaceGridLineConstruction", self.mode, self.starting_point, self.current_points[1], self.current_points[2], self.skin_name, self.switch_dobule_line_directions)
				local new_start = IsValid(last_placed_obj) and last_placed_obj:GetPos() or self.current_points[#self.current_points]
				if self:CanExtendFrom(new_start) then
					self.starting_point = new_start
					self.starting_cs_group = self:GetCSGroupAtStartingPoint()
					self:InitVisuals(self.starting_point)
					self:UpdateVisuals(self.starting_point)
					self:UpdateCursorObject(false)
					return true
				else
					self.starting_point = false
					self.starting_cs_group = false
					self.total_cost = false
					self:ClearColorFromAllConstructionObstructors()
					self.construction_obstructors = false
					self:UpdateCursorObject(true)
					return false
				end
			else --passage grid
				if self:CanCompletePassage() then
					self:DoneVisuals()
					--build
					realm:SuspendPassEdits("construction_supply_grid_line")
					local indata, outdata, _
					local pts = table.iappend(self.placed_points, self.current_points)
					
					for i = 1, #pts - 1 do
						group, _, outdata = self:ConstructLine(pts[i], pts[i + 1], nil, group, indata)						
						indata = indata and table.iappend(indata, outdata) or outdata
						
						if #indata >= self.max_hex_distance_to_allow_build then
							break
						end
					end
					
					realm:ResumePassEdits("construction_supply_grid_line")
					self.starting_point = false
					self.starting_cs_group = false
					self.total_cost = false
					self.current_points = {}
					self:ClearColorFromAllConstructionObstructors()
					self.construction_obstructors = false
					self:UpdateCursorObject(true)
					local object_hex_grid = GetObjectHexGrid(self)
					Msg("PassageConstructionPlaced", GetDomeAtPoint(object_hex_grid, pts[1]), GetDomeAtPoint(object_hex_grid, pts[#pts]))
					return false
				end
			end
		elseif self.mode == "passage_grid" then
			if self:CanContinuePassage() then
				table.iappend(self.placed_points, self.current_points)
				table.insert(self.last_placed_points_count, #self.current_points)
				self.current_points = {}
			end
			return true
		end
	end
end

function GridConstructionController:CanContinuePassage()
	local all_eq = true
	local c = #self.current_points
	local j = 1
	for i = #self.placed_points - c + 1, #self.placed_points do
		local p = self.placed_points[i]
		if p ~= self.current_points[j] then
			all_eq = false
			break
		end
		j = j + 1
	end
	
	return not all_eq
		and (#self.construction_statuses == 1 or self.construction_statuses[2] == ConstructionStatus.NoDroneHub)
		and self.construction_statuses[1] == ConstructionStatus.PassageRequiresTwoDomes
		and self.current_len < self.max_hex_distance_to_allow_build
end

function GridConstructionController:CanCompletePassage()
	return #self.construction_statuses <= 0 or self:GetConstructionState() == "problem"
end

function GridConstructionController:BuildCableShapePts(dir, len)
	local dq, dr = HexNeighbours[dir + 1]:xy()
	local q, r = 0, 0
	
	local shape_arr = {} --cache?
	
	for i = 0, len do
		table.insert(shape_arr, point(q + dq * i, r + dr * i))
	end
	
	return shape_arr
end

function GetEntranceHex(hexes, q, r)
	return (hexes or empty_table)[q * (2^16) + r]
end

function SetEntranceHex(hexes, q, r, obj)
	(hexes or empty_table)[q * (2^16) + r] = obj
end

function GridConstructionController:CanExtendFrom(q, r) --pt should be clamped to hex center
	local pt
	if not r then
		pt = q
		q, r = WorldToHex(q)
	else
		pt = point(HexToWorld(q, r))
	end
	local game_map = GetGameMap(self)
	local object_hex_grid = game_map.object_hex_grid
	local buildable = game_map.buildable
	local realm = game_map.realm

	if self.mode == "electricity_grid" then	
		return CableBuildableTest(game_map, pt, q, r) and not HexGetUnits(realm, nil, nil, pt, 0, true, nil, "SurfaceDeposit") and HexGetBuilding(object_hex_grid, q, r) ~= g_DontBuildHere[game_map.map_id] and not GetDomeAtHex(object_hex_grid, q, r)
	elseif self.mode == "life_support_grid" then
		local p = HexGetPipe(object_hex_grid, q, r)
		if p and p.chain then
			return false, "chain_pipe"
		end
		
		if p and p.pillar then
			return true
		end
		
		local is_buildable = buildable:IsBuildable(q, r)
		local is_buildable2 = CableBuildableTest(game_map, pt, q, r)
		local nearby_pillar
		if not is_buildable and is_buildable2 then
			for i = 1, #HexNeighbours do
				local qq = q + HexNeighbours[i]:x()
				local rr = r + HexNeighbours[i]:y()
				local np = HexGetPipe(object_hex_grid, qq, rr)
				if np and np.pillar then
					nearby_pillar = np
					break
				end
			end
		end
		
		return is_buildable2
			and not HexGetUnits(realm, nil, nil, pt, 0, true, nil, "SurfaceDeposit") 
			and HexGetBuilding(object_hex_grid, q, r) ~= g_DontBuildHere[game_map.map_id] and not GetDomeAtHex(object_hex_grid, q, r), nil, nearby_pillar
	elseif self.mode == "passage_grid" then
		if HexGetBuildingNoDome(object_hex_grid, q, r) ~= nil then
			return false, "obstruced"
		end
		if GetEntranceHex(self.entrance_hexes, q, r) then
			return false, "block_entrance"
		end
		if GetDomeAtHex(object_hex_grid, q, r) == nil then
			return false, "requires_dome"
		end
		--TODO: blocking units
		return TestDomeBuildabilityForPassage(object_hex_grid, q, r, "check_edge", "check_road")
	end
end

function GridConstructionController:CanConstructLine(pt1, pt2, len, in_data)
	local q1, r1 = WorldToHex(pt1)
	local q2, r2 = WorldToHex(pt2)
	local dir = HexGetDirection(q1, r1, q2, r2)
	if q1 == q2 and r1 == r2 then
		dir = 0
		len = 0
	end
	if not dir then
		return
	end
	local func = self.mode == "electricity_grid" and PlaceCableLine or self.mode == "life_support_grid" and PlacePipeLine or PlacePassageLine
	local can_constr, constr_grp, obstructors, data, unbuildable_chunks, rocks, total_cost = func(self.city, q1, r1, dir, len, "test", nil, self.starting_cs_group, in_data, self.skin_name, self.entrance_hexes)
	self.total_cost = total_cost
	if self.mode == "passage_grid" then
		--move return values
		rocks = unbuildable_chunks
		unbuildable_chunks = nil
	end
	return can_constr, constr_grp, obstructors, data, unbuildable_chunks, len, rocks
end

DefineClass.CursorGridElement = {
	__parents = { "Shapeshifter" },
	flags = { cfNoHeightSurfs = true, efCollision = false, efApplyToGrids = false, efWalkable = false, efVisible = false, },
}

function CursorGridElement:Init()
	self:ChangeEntity(self.entity)
end

DefineClass.CursorAutoAttachGridElement = {
	__parents = {"CursorGridElement", "AutoAttachObject"},
	auto_attach_at_init = false,
}

function GridConstructionController:InitVisuals(pt)
	self:UpdateCursorObject(false)
	local start_visible = false
	local hub_entity, connection_entity, joint_entity, link_entity, chain_entity, pillar_entity, unbuildable_hub_entity
	local plug_angle_correction
	local skin = TubeSkins[self.skin_name]
	local pipe_non_hub_pillar = skin.TubePillar
	local tube_joint_seam = skin.TubeJointSeam
	local game_flags = 0
	local cm1, cm2, cm3, cm4
	local entrance_hexes
	if self.mode == "electricity_grid" then
		hub_entity = "CableHub"
		unbuildable_hub_entity = "CableHub"
		connection_entity = "CableHubPlug"
		joint_entity = ""
		link_entity = "CableStraight"
		chain_entity = "CableHanging"
		pillar_entity = "CableTower"
		plug_angle_correction = 0
		cm1, cm2, cm3, cm4 = GetCablesPalette()
	elseif self.mode == "life_support_grid" then
		hub_entity = skin.TubeHub
		unbuildable_hub_entity = skin.TubeHubSlope
		connection_entity = skin.TubeHubPlug
		joint_entity = skin.TubeJoint
		link_entity = skin.Tube
		chain_entity = skin.Tube
		pillar_entity = skin.TubeHub
		plug_angle_correction = 180*60
		cm1, cm2, cm3, cm4 = GetPipesPalette()
	elseif self.mode == "passage_grid" then
		hub_entity = "PassageEntrance"
		link_entity = "PassageCovered"
		entrance_hexes = {}
		local max_distance = self.max_hex_distance_to_allow_build * 10 * guim
		local realm = GetRealm(self)
		realm:MapForEach(pt, max_distance, "object_circles", GetEntityMaxSurfacesRadius(), "Dome", 
			function(dome)
					for _, obj in ipairs(dome.dome_entrances) do
						local chains = obj.waypoint_chains or empty_table
						for _, chain in ipairs(chains.entrance or empty_table) do
							if chain.name == "Doorentrance1" or chain.name == "Doorexit2" then
								local q, r = WorldToHex(chain[5])
								SetEntranceHex(entrance_hexes, q, r, dome)
							end
						end
					end
			end)
	end
	self.entrance_hexes = entrance_hexes
	self.visuals = self.visuals or {chain_entity = chain_entity, link_entity = link_entity, connection_entity = connection_entity, pillar_entity = pillar_entity, hub_entity = hub_entity, plug_angle_correction = plug_angle_correction, pipe_non_hub_pillar = pipe_non_hub_pillar, tube_joint_seam = tube_joint_seam, unbuildable_hub_entity = unbuildable_hub_entity}
	self.visuals.elements = {}
	for j = 1, self.max_hex_distance_to_allow_build do
		local e = self.mode == "passage_grid" and CursorAutoAttachGridElement:new{ entity = link_entity } or CursorGridElement:new { entity = link_entity }
		e:SetGameFlags(game_flags)
		if cm1 then
			SetObjectPaletteRecursive(e, cm1, cm2, cm3, cm4)
		end
		self.visuals.elements[j] = e
	end
	if self.mode ~= "passage_grid" then
		self.visuals.plugs = {}
		self.visuals.joints = {}
		for j = 1, self.max_plugs do
			local p = CursorGridElement:new { entity = connection_entity }
			p:SetGameFlags(game_flags)
			SetObjectPaletteRecursive(p, cm1, cm2, cm3, cm4)
			self.visuals.plugs[j] = p
			local joint = joint_entity ~= "" and CursorGridElement:new { entity = joint_entity } or nil
			if joint then
				SetObjectPaletteRecursive(joint, cm1, cm2, cm3, cm4)
			end
			self.visuals.joints[j] = joint
		end
	end
	if self.mode == "life_support_grid" then
		self:InitHelpers()
	end
end

function GridConstructionController:InitHelpers()
	if not self.water_markers then
		self.water_markers = {}
		local buildings  = self.city.labels.Building
		for i = 1, #(buildings or "") do
			local obj = buildings[i]
			if (IsKindOf(obj, "LifeSupportGridObject") or (IsKindOf(obj, "ConstructionSite") and IsKindOf(obj.building_class_proto, "LifeSupportGridObject"))) then
				SetObjWaterMarkers(obj, true, self.water_markers)
			end
		end
	end
end

function GridConstructionController:DoneHelpers()
	if not self.water_markers then
		return
	end
	local markers = self.water_markers
	for i = 1, #markers do
		if IsValid(markers[i]) then --building could be demolished while constructing and its attaches should already be dead.
			DoneObject(markers[i])
		end
	end
	self.water_markers = false
end

function GridConstructionController:GetDoubleLineData(pt, sp)
	local start_q, start_r = WorldToHex(sp or self.starting_point)
	local pt_q, pt_r = WorldToHex(pt)
	local diff_q, diff_r = pt_q - start_q, pt_r - start_r
	local abs_diff_q, abs_diff_r = abs(diff_q), abs(diff_r)
	local total_dist = HexAxialDistance(start_q, start_r, pt_q, pt_r)
	
	local is_double_dir = (abs_diff_q + abs_diff_r) > total_dist
	local d2_dist = abs_diff_q < abs_diff_r and (not is_double_dir and abs_diff_q or MulDivRound(abs_diff_q, total_dist, abs_diff_r)) or
																			(not is_double_dir and abs_diff_r or MulDivRound(abs_diff_r, total_dist, abs_diff_q))

	local d1_dist = total_dist - d2_dist
	local d1, d2
	
	if is_double_dir then
		if abs_diff_q == total_dist then
			d1 = point(diff_q/abs_diff_q, 0)
		else
			d1 = point(0, diff_r/abs_diff_r)
		end
		
		d2 = point(diff_q == 0 and 0 or diff_q/abs_diff_q, diff_r == 0 and 0 or diff_r/abs_diff_r)
	else
		if abs_diff_q == d1_dist then
			d1 = point(diff_q/abs_diff_q, 0)
			d2 = point(0, diff_r/abs_diff_r)
		else
			d2 = point(diff_q/abs_diff_q, 0)
			d1 = point(0, diff_r/abs_diff_r)
		end
	end
	
	if not self.switch_dobule_line_directions then
		return d1, d1_dist, d2, d2_dist
	else
		return d2, d2_dist, d1, d1_dist
	end
end

function GridConstructionController:GetDoubleLinePoints(pt, sp)
	local d1, d1_dist, d2, d2_dist = self:GetDoubleLineData(pt, sp)
	return { point(HexToWorld((point(WorldToHex(sp or self.starting_point)) + d1 * d1_dist):xy())), pt }
end

function table.iappend_unique(t1, t2)
	for i = 1, #t2 do
		table.insert_unique(t1, t2[i])
	end
end

function table.append_unique(t1, t2)
	assert(false, "Use table.iappend_unique instead.")
	table.iappend_unique(t1, t2)
end

local UnbuildableZ = buildUnbuildableZ()

function GridConstructionController:Rotate()
	if not self.starting_point then return end
	self.switch_dobule_line_directions = not self.switch_dobule_line_directions
	self.last_update_hex = false
	local terrain_pos = GetConstructionTerrainPos("mouse")
	if GetActiveTerrain():IsPointInBounds(terrain_pos) then
		self:UpdateCursor(terrain_pos)
	end
	self:SetColorToAllConstructionObstructors(g_PlacementStateToColor.Obstructing)
end

function GridConstructionController:UpdateVisuals(pt, input_points)
	local q, r = WorldToHex(pt)
	local hex_pos = point(q, r)
	if self.last_update_hex and hex_pos == self.last_update_hex then
		return
	end
	self.last_update_hex = hex_pos
	ObjModified(self)
	local old_t = self.construction_statuses 
	self.construction_statuses = {}
	local is_electricity_grid = self.mode == "electricity_grid"
	local is_ls_grid = self.mode == "life_support_grid"
	local is_passage_grid = self.mode == "passage_grid"

	local game_map = GetGameMap(self)

	if not self.starting_point then
		local result, reason, obj = self:CanExtendFrom(pt)
		if not result then
			if not is_passage_grid then
				local object_hex_grid = game_map.object_hex_grid
				local d = GetDomeAtHex(object_hex_grid, q, r)
				if d then
					table.insert(self.construction_statuses, ConstructionStatus.DomeProhibited)
				else
					if is_ls_grid then
						if reason == "chain_pipe" then
							table.insert(self.construction_statuses, ConstructionStatus.CantExtendFromTiltedPipes)
						else
							table.insert(self.construction_statuses, ConstructionStatus.UnevenTerrain)
						end
					else
						table.insert(self.construction_statuses, ConstructionStatus.UnevenTerrain)
					end
				end
			else
				--we have reason in this mode
				if reason == "requires_dome" then
					table.insert(self.construction_statuses, ConstructionStatus.DomeRequired)
				elseif reason == "block_entrance" then
					table.insert(self.construction_statuses, ConstructionStatus.PassageTooCloseToEntrance)
				elseif reason == "block_life_support" then
					table.insert(self.construction_statuses, ConstructionStatus.PassageTooCloseToLifeSupport)
				else
					table.insert(self.construction_statuses, ConstructionStatus.BlockingObjects)
				end
				
				if self.cursor_obj then
					if not self.template_obj then
						--init
						self.template_obj = ClassTemplates.Building.Passage
						self.is_template = true
						self.template_obj_points = FallbackOutline
					end
					self:UpdateConstructionObstructors(self)
					self:SetColorToAllConstructionObstructors(g_PlacementStateToColor.Obstructing)
				end
			end
			if self.cursor_obj then
				self.cursor_obj:SetColorModifier(g_PlacementStateToColor.Blocked)
			end
		elseif self.cursor_obj then
			if not DoesAnyDroneControlServiceAtPoint(game_map.map_id, pt) then
				table.insert_unique(self.construction_statuses, ConstructionStatus.NoDroneHub)
				self.cursor_obj:SetColorModifier(g_PlacementStateToColor.Problematic)
			else
				self.cursor_obj:SetColorModifier(const.clrNoModifier)
			end
			if is_passage_grid then
				self:ClearColorFromAllConstructionObstructors()
				self:ClearDomeWithObstructedRoads()
			end
		end
		if not table.iequals(old_t, self.construction_statuses) then
			ObjModified(self)
		end
		self:UpdateShortConstructionStatus()
		return
	end
	
	
	local pt_arr = is_passage_grid and self.placed_points or nil
	local sp = pt_arr and pt_arr[#pt_arr] or self.starting_point
	pt = pt:SetInvalidZ()
	local points
	if input_points then
		points = input_points
	else
		points = {HexClampToAxis(sp, pt)}
		local number_of_lines = points[1] == pt and 1 or 2
		if number_of_lines > 1 then
			points = self:GetDoubleLinePoints(pt, sp)
		end
	end
	local points_prestine = points
	if pt_arr then
		points = table.iappend(table.copy(pt_arr), points)
	end
	
	local total_len = 0
	local prev_point = is_passage_grid and points[1] or sp
	local start_idx = is_passage_grid and 2 or 1
	local last_angle = -1
	local start_dome = false
	local steps_arr = {}
	local clr = const.clrNoModifier
	local all_obstructors = {}
	local all_data = {}
	local all_chunks = {}
	local all_rocks = {}
	local can_constr_final = is_passage_grid or false
	local data_merge_idx = false
	local terrain = game_map.terrain
	for i = start_idx, #points do
		local next_point = points[i]
		next_point = next_point and next_point:SetZ(terrain:GetHeight(next_point)) or false
		if not next_point or next_point:Equal2D(prev_point) and i > start_idx then
			prev_point = next_point
		else
			local len = prev_point:Dist2D(next_point)
			local steps = (len + const.GridSpacing/2) / const.GridSpacing
			local max_steps = (self.max_hex_distance_to_allow_build - 1) - (steps_arr[i - 1] or 0)
			local end_pos = next_point
			local fbreak = false
			
			if is_passage_grid then
				if not end_pos:Equal2D(prev_point) then
					local a = CalcOrientation(prev_point, end_pos)
					
					local na = abs(AngleDiff(a, last_angle))
					if last_angle >= 0 and na > 60*60 then
						if #all_data < self.max_hex_distance_to_allow_build then
							table.insert(self.construction_statuses, ConstructionStatus.PassageAngleToSteep)
						end
						fbreak = true
					end
					last_angle = a
				end
			end
			
			if max_steps <= 0 or fbreak then
				--our step allowance was hit last 
				points[i] = nil
				steps_arr[i] = nil
				break
			elseif steps > max_steps then
				end_pos  = prev_point + MulDivRound(next_point - prev_point, max_steps, steps)
				steps = max_steps
			end
			points[i] = end_pos
			steps_arr[i] = steps
			
			local can_constr, constr_grp, obstructors, data, unbuildable_chunks, axial_dist, rocks = self:CanConstructLine(prev_point, end_pos, steps, all_data)
			all_rocks[i] = rocks
			if obstructors then
				table.iappend_unique(all_obstructors, obstructors)
			end
			
			if i > start_idx and #data > 0 then
				--the 2 lines we test share a hex at the the turn, so get rid of the duplicate data node
				data[0].is_turn = true
				data_merge_idx = #all_data
				local node_to_rem = all_data[data_merge_idx]
				data[0].chunk = (data[0].chunk or node_to_rem.chunk)
				data[0].chunk_start = (data[0].chunk_start or node_to_rem.chunk_start)
				data[0].chunk_end = (data[0].chunk_end or node_to_rem.chunk_end)
				table.remove(all_data)
			end
			
			for i=0,#data do
				all_data[#all_data + 1] = data[i]
			end
			for k, v in pairs(data) do
				if type(k) == "string" then
					all_data[k] = v
				end
			end
			
			table.iappend(all_chunks, unbuildable_chunks)
			total_len = total_len + (axial_dist or 0)
			if is_passage_grid then
				can_constr_final = can_constr_final and can_constr
			else
				can_constr_final = can_constr_final or can_constr
			end
			
			prev_point = next_point
			
			if is_passage_grid and not start_dome and #all_data > 0 then
				start_dome = all_data[1].dome
			end
			
			if i == 1 and
				(self.mode == "electricity_grid" and not const.SupplyGridElementsAllowUnbuildableChunksCables or
				self.mode ~= "electricity_grid" and not const.SupplyGridElementsAllowUnbuildableChunksPipes) and 
				data[#data].status == SupplyGridElementHexStatus.unbuildable_blocked then
				points[2] = nil
				break
			end
		end
	end
	
	--buildability tests
	local data_count = #all_data
	local last_idx = Min(data_count, self.max_hex_distance_to_allow_build)
	if last_idx <= 0 then
		return
	end
	if not can_constr_final then
		if not is_passage_grid then
			table.insert(self.construction_statuses, ConstructionStatus.UnevenTerrain)
		end
		clr = g_PlacementStateToColor.Blocked
	end
	
	if is_passage_grid and all_data[data_count].dome == start_dome then
		table.insert(self.construction_statuses, ConstructionStatus.PassageRequiresDifferentDomes)
		clr = g_PlacementStateToColor.Blocked
	end
	
	if clr == const.clrNoModifier then
		local obstructor_count = #all_obstructors
		
		--1 building on each side is allowed
		if obstructor_count > 2 
			or (obstructor_count == 2 and (all_data[1].status == SupplyGridElementHexStatus.clear or all_data[data_count].status == SupplyGridElementHexStatus.clear))
			or (obstructor_count == 1 
				and (all_data[1].status == SupplyGridElementHexStatus.clear and all_data[data_count].status == SupplyGridElementHexStatus.clear) or 
					all_obstructors[1] == g_DontBuildHere[game_map.map_id]) then
			clr = g_PlacementStateToColor.Blocked
		end
	end
	
	if clr == const.clrNoModifier and not is_passage_grid then
		--any blocked unbuildable buildable chunk also blocks
		local last_chunk = false
		for idx, chunk_data in ipairs(all_chunks) do
			if chunk_data.status == SupplyGridElementHexStatus.blocked then
				clr = g_PlacementStateToColor.Blocked
				table.insert_unique(self.construction_statuses, ConstructionStatus.UnevenTerrain)
				break
			elseif last_chunk and is_electricity_grid then
				local my_start = chunk_data.chunk_start
				local his_end = last_chunk.chunk_end
				if my_start == his_end and last_chunk.connect_dir ~= chunk_data.connect_dir then
					--cable pillars may connect 2 chunks only in the same direction
					clr = g_PlacementStateToColor.Blocked
					table.insert_unique(self.construction_statuses, ConstructionStatus.UnevenTerrain)
				end
			end
			last_chunk = chunk_data
		end
	end
	
	if clr == const.clrNoModifier and not is_passage_grid then
		if all_data[last_idx].chunk and not (all_data[last_idx].chunk_end or all_data[last_idx].chunk_start) then
			clr = g_PlacementStateToColor.Blocked
			table.insert_unique(self.construction_statuses, ConstructionStatus.UnevenTerrain)
		end
	end
	
	if is_passage_grid then
		--start and end must be in dome buildable hex, start should already be (can extend from) so check end
		local n = all_data[last_idx]
		
		if not self:CanExtendFrom(n.q, n.r) or n.dome == all_data[1].dome then --also can't start and end in the same dome
			clr = g_PlacementStateToColor.Blocked
			table.insert(self.construction_statuses, ConstructionStatus.PassageRequiresTwoDomes)
		end
	end
	
	
	if clr ~= const.clrNoModifier then
		if next(all_obstructors) then
			table.insert(self.construction_statuses, ConstructionStatus.BlockingObjects)
		end
	end
	
	if is_electricity_grid and clr ~= const.clrNoModifier and data_merge_idx and all_data[data_merge_idx].chunk_end and all_data[data_merge_idx].chunk_start then
		--if we are blocked, we have ran 2 passes, we are electricity, and the turn node is both a start and an end, show only up to the turn node
		last_idx = data_merge_idx
		all_rocks = all_rocks[1]
	else
		all_rocks[1] = all_rocks[1] or {}
		local rt = {}
		for i = 1, #all_rocks do
			rt = table.iappend(rt, all_rocks[i])
		end

		all_rocks = rt
	end
	
	self:ColorRocks(all_rocks)
	self:ClearColorFromMissingConstructionObstructors(self.construction_obstructors, all_obstructors)
	self.construction_obstructors = all_obstructors
	self:SetColorToAllConstructionObstructors(g_PlacementStateToColor.Obstructing)
	--all visuals visibility
	
	local ground_offset = is_electricity_grid and const.GroundOffsetForLosTest or 0
	local visuals = self.visuals

	local visuals_idx = 1
	local plugs_idx = 1
	local last_visual_element = false
	local last_visual_node = false
	local did_start = false
	local x, y, z
	z = const.InvalidZ
	local angle = CalcOrientation(self.starting_point, points[1])
	
	local HandleJoint = false
	if is_electricity_grid then
		HandleJoint = function(plug, plug_angle, joint, node, chunk)
			local length = chunk and chunk.chunk_end - chunk.chunk_start or 0
			if length > 0 then
				local chain = GetChainParams(node.chunk_start == chunk and 0 or length, length, HexAngleToDirection(plug_angle), chunk, true)
				plug:ChangeEntity(chain.index == 0 and "CableTowerPlugIn" or "CableTowerPlugOut")
				plug:SetPos(plug:GetPos():SetZ(chain.base))
				plug:SetAngle(chain.index ~= 0 and plug_angle + 180 * 60 or plug_angle)
				plug:SetChainParams(chain.delta, chain.index, chain.length)
			else
				plug:SetAngle(plug_angle)
				plug:ChangeEntity(visuals.connection_entity)
				plug:ClearGameFlags(const.gofPartOfChain)
			end
		end
	elseif is_ls_grid then
		HandleJoint = function(plug, plug_angle, joint, node, chunk)
			plug:SetAngle(plug_angle)
			local length = chunk and chunk.chunk_end - chunk.chunk_start - 1 or 0
			local delta = chunk and chunk.zd or 0
			if length > 0 and delta ~= 0 then
				plug:ChangeEntity(visuals.tube_joint_seam)
				
				plug:Attach(joint, plug:GetSpotBeginIndex("Joint"))
				joint:SetAttachAxis(axis_y)
				local dist = const.GridSpacing * length
				local angle = acos(MulDivRound(4096, dist, sqrt(chunk.zd ^ 2 + dist ^ 2)))
				
				if (chunk.zd < 0) == (node.chunk_start ~= chunk) then
					joint:SetAttachAngle(angle)
				else
					joint:SetAttachAngle(-angle)
				end
				
				joint:SetVisible(true)
			else
				joint:SetVisible(false)
				joint:Detach()
				if delta == 0 then
					plug:ChangeEntity(visuals.connection_entity)
				else
					plug:SetVisible(false)
					plugs_idx = plugs_idx - 1
				end
			end
		end
	end
	
	local passage_skin = nil
	if is_passage_grid then
		if all_data[1] and all_data[1].dome then
			passage_skin = all_data[1].dome:GetCurrentSkinStrIdForPassage()
		end
	end
	
	local passed_block_reasons = {}
	if all_data.has_group_with_no_hub then
		table.insert_unique(self.construction_statuses, ConstructionStatus.NoDroneHub)
	end
	
	for i = 1, last_idx do
		local node = all_data[i]
		--per node construction errors
		local reason = node.block_reason
		if reason and not passed_block_reasons[reason] then
			if reason == "roads" then
				table.insert_unique(self.construction_statuses, ConstructionStatus.NonBuildableInterior)
			elseif reason == "block_entrance" then
				table.insert_unique(self.construction_statuses, ConstructionStatus.PassageTooCloseToEntrance)
			elseif reason == "block_life_support" then
				table.insert_unique(self.construction_statuses, ConstructionStatus.PassageTooCloseToLifeSupport)
			elseif reason == "unbuildable" then
				table.insert_unique(self.construction_statuses, ConstructionStatus.UnevenTerrain)
			elseif reason == "no_hub" then
				table.insert_unique(self.construction_statuses, ConstructionStatus.NoDroneHub)
			end
			passed_block_reasons[reason] = true
		end
	end
	
	SortConstructionStatuses(self.construction_statuses)
	local s = self:GetConstructionState()
	if s == "error" and clr ~= g_PlacementStateToColor.Blocked then
		clr = g_PlacementStateToColor.Blocked
	elseif s == "problem" and clr ~= g_PlacementStateToColor.Problematic then
		clr = g_PlacementStateToColor.Problematic	
	end
	--cursor strings
	self:UpdateShortConstructionStatus(all_data[data_count])
	
	local buildable = game_map.buildable
	for i = 1, last_idx do
		local node = all_data[i]
		
		if node.is_turn then
			angle = CalcOrientation(points[1], points[2])
		end
		
		if clr == g_PlacementStateToColor.Blocked or node.status < SupplyGridElementHexStatus.blocked then
			x, y = HexToWorld(node.q, node.r)
			local el = visuals.elements[visuals_idx]
			local buildable_z = buildable:GetZ(node.q, node.r)
			el:SetPos(x, y, buildable_z ~= UnbuildableZ and buildable_z or z)
			if i == 1 and is_passage_grid then
				z = el:GetPos():z()
			end
			el:SetColorModifier(clr)
			el:SetAngle(angle % (180 * 60))
			rawset(el, "node", node)
			visuals_idx = visuals_idx + 1
			
			--pick entity
			local e = visuals.link_entity
			local cm1, cm2, cm3, cm4
			if is_electricity_grid then
				if node.is_turn and not node.chunk_start and not node.chunk_end then
					local a1 = CalcOrientation(points[1], self.starting_point)
					local a2 = angle
					local first = HexAngleToDirection(a1)
					local second = HexAngleToDirection(a2)
					local t_first = Min(first, second)
					second = Max(first, second)
					first = t_first
					e = ElectricGridCableDirectionRelationToEntity[second - first]
					el:SetAngle(60 * 60 * first)
				elseif node.is_turn and node.chunk_end then
					el:SetAngle(60 * 60 * node.chunk_end.connect_dir)
				end
			elseif is_ls_grid then --pipes
				if node.is_turn then
					e = visuals.hub_entity
				elseif node.pillar and not node.ignore_this_pillar_in_visuals then
					e = visuals.pipe_non_hub_pillar
				end
			elseif is_passage_grid then
				e, cm1, cm2, cm3, cm4 = GetPassageEntityAndPalette(node, passage_skin, game_map.map_id)
				local a = GetPassageAngle(node)
				if a ~= el:GetAngle() then
					el:SetAngle(a)
				end
			end
			
			if node.chunk_start or node.chunk_end then
				e = visuals.pillar_entity
			elseif node.chunk or (node.status == SupplyGridElementHexStatus.unbuildable and not is_passage_grid) then
				local chunk_idx = i - 1 
				local chain = false 
				if is_electricity_grid then
					chain = GetChainParams(chunk_idx - node.chunk.chunk_start, node.chunk.chunk_end - node.chunk.chunk_start, HexAngleToDirection(angle), node.chunk, true)
				else
					chain = GetChainParams(chunk_idx - node.chunk.chunk_start - 1, node.chunk.chunk_end - node.chunk.chunk_start - 1, HexAngleToDirection(angle), node.chunk)
				end
				el:SetChainParams(chain.delta, chain.index, chain.length)
				e = visuals.chain_entity
				el:SetPos(x, y, chain.base)
			end
			
			if not did_start then
				did_start = true
				if not (node.chunk_start or node.chunk_end) and not is_passage_grid then
					e = visuals.hub_entity
				end
			end

			if is_ls_grid and not node.is_buildable and e == visuals.hub_entity then
				e = visuals.unbuildable_hub_entity
			end
			
			if e ~= el:GetEntity() then
				if is_passage_grid then
					el:DestroyAttaches()
				end
				el:ChangeEntity(e)
				if is_passage_grid then
					AutoAttachObjectsToPlacementCursor(el)
					el:ForEachAttach(function(attach)
						attach:SetSIModulation(0) -- turn off entrance lights
					end)
				end
			end
			if cm1 then
				SetObjectPaletteRecursive(el, cm1, cm2, cm3, cm4)
			end
			if not is_passage_grid and e == visuals.hub_entity then
				el:SetAngle(0)
			end
			if e ~= visuals.chain_entity or not node.chunk then
				el:ClearGameFlags(const.gofPartOfChain)
			end
			el:SetVisible(true)
			
			if not is_passage_grid then
				--plug management
				if (e == visuals.pillar_entity or e == visuals.hub_entity or e == visuals.unbuildable_hub_entity) 
					and last_visual_element then
					local plug = visuals.plugs[plugs_idx]
					plugs_idx = plugs_idx + 1
					plug:SetPos(el:GetPos())	
					plug:SetColorModifier(clr)
					local plug_angle = CalcOrientation(el:GetPos(), last_visual_element:GetPos()) + visuals.plug_angle_correction
					HandleJoint(plug, plug_angle, visuals.joints[plugs_idx - 1], node, node.chunk_end)
					plug:SetVisible(true)
				end
				local lvee = last_visual_element and last_visual_element:GetEntity()
				if lvee 
					and (lvee == visuals.pillar_entity or lvee == visuals.hub_entity or lvee == visuals.unbuildable_hub_entity) then
					local plug = visuals.plugs[plugs_idx]
					plugs_idx = plugs_idx + 1
					local last_el_pos = last_visual_element:GetPos()
					plug:SetPos(last_el_pos)
					plug:SetColorModifier(clr)
					local plug_angle = CalcOrientation(last_el_pos, el:GetPos()) + visuals.plug_angle_correction
					HandleJoint(plug, plug_angle, visuals.joints[plugs_idx - 1], all_data[i-1], all_data[i-1].chunk_start)
					plug:SetVisible(true)
				end
			end
			
			
			last_visual_node = node
			last_visual_element = el
		end
	end
	--make last element into an end element
	local el = visuals.elements[visuals_idx - 1]
	if el and not is_passage_grid then
		local e = is_electricity_grid and visuals.hub_entity or is_ls_grid and visuals.pillar_entity
		if last_visual_node.chunk_start or last_visual_node.chunk_end then
			e = is_ls_grid and not last_visual_node.is_buildable and visuals.unbuildable_hub_entity or visuals.pillar_entity
		end
		if e ~= el:GetEntity() then
			el:ChangeEntity(e)
			el:ClearGameFlags(const.gofPartOfChain)
		end
		if not is_electricity_grid then
			el:SetAngle(0)
		end
		
		if not last_visual_node.chunk_end then
			angle = visuals.elements[visuals_idx - 2] and CalcOrientation( el:GetPos(), visuals.elements[visuals_idx - 2]:GetPos()) or (angle + 180 * 60)
			local plug = visuals.plugs[plugs_idx]
			plugs_idx = plugs_idx + 1
			plug:SetPos(el:GetPos())
			plug:SetColorModifier(clr)
			local plug_angle = angle + visuals.plug_angle_correction
			HandleJoint(plug, plug_angle, visuals.joints[plugs_idx - 1], last_visual_node, last_visual_node.chunk)
			plug:SetVisible(true)
		end
	end
	if el then
		self:SetTxtPosObj(el)
	end
	
	for i = visuals_idx, self.max_hex_distance_to_allow_build do
		visuals.elements[i]:SetVisible(false)
	end
	
	if not is_passage_grid then
		for i = visuals_idx == 2 and 1 or plugs_idx, self.max_plugs do
			visuals.plugs[i]:SetVisible(false)
			if not is_electricity_grid then
				visuals.joints[i]:SetVisible(false)
			end
		end
	end
	
	self.current_points = points_prestine
	self.current_status = clr
	self.current_len = data_count
	
	ObjModified(self)
end

function GridConstructionController:DoneVisuals()
	self:UpdateCursorObject(true)
	
	for j = 1, self.max_hex_distance_to_allow_build do
		self.visuals.elements[j]:delete()
	end
	if self.mode ~= "passage_grid" then
		for j = 1, #self.visuals.joints do
			self.visuals.joints[j]:delete()
		end
		
		for j = 1, self.max_plugs do
			self.visuals.plugs[j]:delete()
		end
	end
	
	self.visuals = false
	self.last_update_hex = false
end

function GridConstructionController:Deactivate(pt)
	self:ClearColorFromAllConstructionObstructors()
	self.construction_obstructors = false
	if self.starting_point then
		local terrain = GetTerrain(self)
		if self.mode == "passage_grid" and #self.last_placed_points_count > 0 then
			local idx = #self.placed_points - self.last_placed_points_count[#self.last_placed_points_count] + 1
			for i = #self.placed_points, idx, -1 do
				self.placed_points[i] = nil
			end
			table.remove(self.last_placed_points_count)
			if #self.last_placed_points_count > 0 then
				local terrain_pos = GetConstructionTerrainPos()
				if terrain:IsPointInBounds(terrain_pos) then
					self.last_update_hex = false
					self:UpdateVisuals(terrain_pos)
				end
				return false
			end
		end
		
		self.starting_point = false
		self.starting_cs_group = false
		self.total_cost = false
		self:DoneVisuals()
		self:UpdateCursorObject(true)
		self:ColorRocks()
		local terrain_pos = GetConstructionTerrainPos()
		if terrain:IsPointInBounds(terrain_pos) then --update at new pos
			self:UpdateCursor(terrain_pos)
		end
		return false --don't kill me
	else
		if self.mode == "passage_grid" then
			self:ClearDomeWithObstructedRoads()
		end
		self:ColorRocks()
		self:DoneHelpers()
		if IsValid(self.cursor_obj) then
			DoneObject(self.cursor_obj)
			self.cursor_obj = false
		end
		ShowNearbyHexGrid(false)
		return true --kill me
	end
end

function GridConstructionController:GetShortConstructionStatusPos()
	local obj = self.cursor_obj or self.visuals and self.visuals[#self.visuals].finish
	return ConstructionController.GetShortConstructionStatusPos(self, obj)
end

local RevMask = { 8, 16, 32, 1, 2, 4 } --corresponds to HexNeighbours

function GridConstructionController:UpdateShortConstructionStatus(last_data)
	local txt, ctrl = ConstructionController.UpdateShortConstructionStatus(self)
	if txt ~= "" or self.mode ~= "life_support_grid" then
		return
	end
	
	if not last_data then
		local arr = self.visuals and self.visuals.elements
		if arr and arr[1]:GetVisible() then --there is at least one visible
			for i = #arr, 1, -1 do
				if arr[i]:GetVisible() then
					last_data = arr[i].node
					break
				end
			end
		elseif self.cursor_obj then
			local p = self.cursor_obj:GetPos()
			local q, r = WorldToHex(p)
			last_data = {q = q, r = r}
		end
		
		if not last_data then
			return
		end
	end
	
	local q, r = last_data.q, last_data.r
	local all_cs
	local bld
	local pipe
	local object_hex_grid = GetObjectHexGrid(self)
	local supply_connection_grid = GetSupplyConnectionGrid(self)
	for d = 1, 6 do
		local p = HexNeighbours[d]
		local qq, rr = q + p:x(), r + p:y()
		local bld_in_hex = HexGetBuilding(object_hex_grid, qq, rr)
		if IsKindOf(bld_in_hex, "ConstructionSite") and IsKindOf(bld_in_hex.building_class_proto, "LifeSupportGridObject") then
			all_cs = all_cs or {}
			table.insert(all_cs, {bld = bld_in_hex, q = qq, r = rr}) 
		end
		local v = HexGridGet(supply_connection_grid.water, point(qq, rr))
		if band(v, shift(RevMask[d], 8)) ~= 0 then
			--any potential to us
			bld = bld or bld_in_hex
			pipe = HexGetPipe(object_hex_grid, qq, rr)
		end
		if bld then break end
	end
	
	if not bld and all_cs then
		--check construction sites
		for _, data in ipairs(all_cs) do
			local bld_dir = HexAngleToDirection(data.bld)
			local qq, rr = WorldToHex(data.bld)
			local src = point(HexRotate(data.q - qq, data.r - rr, -bld_dir)) -- remove the object rotation
			local dir = (6 + HexGetDirection(data.q, data.r, q, r) - bld_dir) % 6
			for _, conn in ipairs(data.bld.building_class_proto:GetPipeConnections()) do
				if conn[1] == src and conn[2] == dir then
					bld = data.bld
					break
				end
			end
		end
	end
	
	local new_skin = false
	if bld then
		txt = T(8019, "Connected to building")
		if not IsKindOf(bld, "ConstructionSite") and IsKindOf(bld, "LifeSupportGridObject") then
			new_skin = bld.water and bld.water.grid and bld.water.grid.element_skin
		end
	elseif pipe then
		txt = T(8020, "Connected to pipe")
		new_skin = pipe.water and pipe.water.grid and pipe.water.grid.element_skin
	else
		txt = T(8021, "<yellow>Not connected</color>")
	end
	
	if new_skin and not self.starting_point then
		self:SetSkin(new_skin)
	end
	
	ctrl:SetText(txt)
	ctrl:SetVisible(true)
	CreateGameTimeThread(function(ctrl)
		ctrl:SetMargins(box(-ctrl.text_width/2,30,0,0)) --delay until text_width is updated
	end, ctrl)
	--ctrl:SetMargins(box(-ctrl.text_width/2,30,0,0))
end

function GridConstructionController:SetSkin(skin_name)
	if self.skin_name == skin_name then return end
	self.skin_name = skin_name
	local vis = IsValid(self.cursor_obj)
	if self.visuals then
		self:DoneVisuals()
		self:InitVisuals()
	end
	self:UpdateCursorObject(vis)
	
	local terrain_pos = GetConstructionTerrainPos()
	local terrain = GetTerrain(self.city)
	if terrain:IsPointInBounds(terrain_pos) then
		self:UpdateVisuals(terrain_pos)
	end
end

function GridConstructionController:UpdateCursor(pt)
	local game_map = GetGameMap(self.city)
	if IsValid(self.cursor_obj) then
		self.cursor_obj:SetPos(FixConstructPos(game_map.terrain, pt))
		self:OnCursorObjNewPos()
	end
	ShowNearbyHexGrid(IsTerrainFlatForPlacement(game_map.buildable, {point20}, pt, 0) and pt)
	self:UpdateVisuals(pt)
end

function GridConstructionController:ConstructLine(pt1, pt2, override_from, group, last_data)
	local q1, r1 = WorldToHex(pt1)
	local q2, r2 = WorldToHex(pt2)
	local dir, len
	if override_from then
		local q3, r3 = WorldToHex(override_from)
		len = 0
		dir = (HexGetDirection(q3, r3, q2, r2) + 3) % 6
	else
		dir, len = HexGetDirection(q1, r1, q2, r2)
		if q1 == q2 and r1 == r2 then
			dir = 0
			len = 0
		end
	end
	
	assert(dir)
	local _, construction_grp, last_placed_obj, data
	if self.mode == "electricity_grid" then
		_, construction_grp, last_placed_obj, data = PlaceCableLine(self.city, q1, r1, dir, len, nil, self.grid_elements_require_construction, group, last_data, self.supplied)
	elseif self.mode == "life_support_grid" then
		_, construction_grp, last_placed_obj, data = PlacePipeLine(self.city, q1, r1, dir, len, nil, self.grid_elements_require_construction, group, last_data, self.skin_name, self.supplied)
	elseif self.mode == "passage_grid" then
		_, construction_grp, last_placed_obj, data = PlacePassageLine(self.city, q1, r1, dir, len, nil, self.grid_elements_require_construction, group, last_data, self.skin_name, self.entrance_hexes)
	else
		return
	end

	return construction_grp, last_placed_obj, data
end

function GridConstructionController:Getconstruction_statuses_property()
	local items = {}
	if #self.construction_statuses > 0 then --we have statuses, display first 3
		for i = 1, Min(#self.construction_statuses, 3) do
			local st = self.construction_statuses[i]
			items[#items+1] = T{879, "<col><text></color>", col = ConstructionStatusColors[st.type].color_tag, text = st.text}
		end
	else
		items[#items+1] = T(880, "<green>All Clear!</green>")
	end
	return table.concat(items, "\n")
end

function GridConstructionController:Getconstruction_costs_property()
	local text = ""
	local t = {}
	
	for k, v in pairs(self.total_cost or empty_table) do
		t[#t + 1] = FormatResource(empty_table, v, k)
	end
	
	if next(t) then
		text = T(263, "Cost: ") .. table.concat(t , " ")
	end
	
	return text
end

function GridConstructionController:GetDisplayName()
	if self.mode == "electricity_grid" then
		return T(881, "Power Cables")
	elseif self.mode == "life_support_grid" then
		return T(882, "Pipes")
	elseif self.mode == "passage_grid" then
		return T(8776, "Passages")
	end
end

function GridConstructionController:GetDescription()
	if self.mode == "electricity_grid" then
		return T(883, "Cables connect adjacent buildings to the power grid when constructed.")
	elseif self.mode == "life_support_grid" then
		return T(884, "Pipes transport Oxygen and Water and have to be connected to buildings on the spots indicated with a pipe connection icon.")
	elseif self.mode == "passage_grid" then
		return T(8777, "Connect two domes by placing both ends of the Passage on empty hexes inside two nearby domes.")
	end
end
