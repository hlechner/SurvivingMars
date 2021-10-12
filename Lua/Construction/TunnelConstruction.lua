DefineClass.TunnelConstructionDialog = {
	__parents = { "InterfaceModeDialog" },
	MouseCursor = const.DefaultMouseCursor,
	mode_name = "tunnel_construction",
	success_sound = "CableConstructionSuccess",
	
	template = false,
	params = false,
	
	TryCloseAfterPlace = TryCloseAfterPlace,
}

function TunnelConstructionDialog:Init()
	for k,v in pairs(self.context) do
		self[k] = v
	end
	table.change(hr, "Construction", { RenderBuildGrid = 1, BuildGridRadius = 13000 })
	HideGamepadCursor("construction")
	ShowResourceIcons("construction")
	
	if GetUIStyleGamepad() then
		self:CreateThread("GamepadCursorUpdate", UpdateConstructionCursorObject, GetTunnelConstructionController())
	end
end

function TunnelConstructionDialog:Open(...)
	InterfaceModeDialog.Open(self, ...)
	self:SetModal(true)
	DelayedCall(0, OpenTunnelConstructionInfopanel, self.template)
end

function TunnelConstructionDialog:Close(...)
	InterfaceModeDialog.Close(self, ...)
	while not GetTunnelConstructionController():Deactivate() do end
	table.restore(hr, "Construction")
	ShowGamepadCursor("construction")
	HideResourceIcons("construction")
	
	if self:IsThreadRunning("GamepadCursorUpdate") then
		self:DeleteThread("GamepadCursorUpdate")
	end
	local dlg = GetHUD()
	if dlg then dlg.idtxtConstructionStatus:SetVisible(false) end	
end

function TunnelConstructionDialog:TryPlace(pos)
	local close = not not GetTunnelConstructionController().placed_obj
	if GetTunnelConstructionController():Activate(HexGetNearestCenter(pos)) then
		PlayFX(self.success_sound, "start")
		if close then
			self:TryCloseAfterPlace()
		end
	else
		PlayFX("ConstructionFail", "start")
	end
end

function TunnelConstructionDialog:OnKbdKeyDown(virtual_key, repeated)
	if virtual_key == const.vkEsc then
		self:OnMouseButtonDown(nil, "R")
		return "break"
	end
end

function TunnelConstructionDialog:OnMouseButtonDown(pt, button)
	if button == "L" then
		self:TryPlace(GetTerrainCursor())
	elseif button == "R" then
		if GetTunnelConstructionController():Deactivate(pt) then
			PlayFX("GridConstructionCancel", "start")
			CloseModeDialog()
			return "break"
		end
	elseif button == "M" then
		GetTunnelConstructionController():Rotate(-1)
		return "break"
	end
end

function TunnelConstructionDialog:OnMouseButtonDoubleClick(pt, button)
	if button == "M" then
		return self:OnMouseButtonDown(pt, button)
	end
end

function TunnelConstructionDialog:OnMousePos(pt)
	local terrain_pos = HexGetNearestCenter(GetTerrainCursor())
	if GetActiveTerrain():IsPointInBounds(terrain_pos) then
		GetTunnelConstructionController():UpdateCursor(terrain_pos)
	end
	return "break"
end

function TunnelConstructionDialog:OnShortcut(shortcut, source)
	if shortcut == "ButtonA" then
		self:OnMouseButtonDown(GetTerrainGamepadCursor(), "L")
		return "break"
	elseif shortcut == "ButtonB" then
		self:OnMouseButtonDown(nil, "R") --cancel
		return "break"
	end
end

DefineClass.ObstacleCursorBuilding = {
	__parents = {"CursorBuilding", "UngridedObstacle"},
}

function ObstacleCursorBuilding:Done()
	SetShapeMarkers(self, false)
end

--controller->
DefineClass.TunnelConstructionController = {
	__parents = { "ConstructionController" },
	
	properties = {
		{id = "construction_statuses_property", editor = "text", name = T{""}, translate = true, default = false},
		{id = "DisplayName",                    editor = "text", name = T{""}, translate = true, default = false},
	},
	
	cursor_obj = false,
	placed_obj = false, --when placing the first part of the tunnel, this will be a cursor obj with the picked pos
	
	template_name = false,
	template_obj = false,
	template_obj_points = false,
	is_template = true,
	
	max_range = 100, --hexes
		
	current_status = const.clrNoModifier,
	PickCursorObjColor = GridSwitchConstructionController.PickCursorObjColor,
	stockpiles_obstruct = true,
}

function TunnelConstructionController:Initialize(template)
	self.rocks_underneath = {}
	self.template_name = template
	self.template_obj = ClassTemplates.Building[template] or g_Classes[template]
	self.template_obj_points = self.template_obj:GetBuildShape()
	self:UpdateCursorObject(true)
	self.construction_statuses = {}
	self.selected_domes = {}
	
	local terrain_pos = HexGetNearestCenter(GetUIStyleGamepad() and GetTerrainGamepadCursor() or GetTerrainCursor())
	self:UpdateCursor(terrain_pos)
end

function TunnelConstructionController:UpdateCursorObject(visible)
	if visible then
		local entity = self.template_obj.entity
		
		if IsValid(self.cursor_obj) then
			self.cursor_obj.entity = entity
			self.cursor_obj:ChangeEntity(entity)
		else
			self.cursor_obj = CursorBuilding:new{ template = self.template_obj, entity = entity }
			self.cursor_obj:SetEnumFlags(const.efVisible)
		end
		
		self:SetTxtPosObj(self.cursor_obj)
	elseif IsValid(self.cursor_obj) then
		self.cursor_obj:delete()
		self.cursor_obj = false
	end
end

TunnelConstructionController.SetTxtPosObj = GridConstructionController.SetTxtPosObj

function TunnelConstructionController:Activate(pt)
	--place
	local s = self:GetConstructionState()
	if s == "error" then
		return false
	end
	
	if self.placed_obj then
		--place tunnels
		local template_obj = self.template_obj
		local placed_obj = self.placed_obj
		local cursor_obj = self.cursor_obj
		
		local group = CreateConstructionGroup("Tunnel", placed_obj:GetPos(), placed_obj:GetMapID(), 2, false, true, false)
		local params1, params2 = {construction_group = group, place_stockpile = false}, {construction_group = group, place_stockpile = false}
		params1.linked_obj = params2
		params2.linked_obj = params1
		table.insert(group, params1)
		table.insert(group, params2)
		
		local realm = GetRealm(self)
		local entity = template_obj:GetEntity()
		local force_extend_bb = template_obj:HasMember("force_extend_bb_during_placement_checks") and template_obj.force_extend_bb_during_placement_checks ~= 0 and template_obj.force_extend_bb_during_placement_checks or false
		local rocks1 = HexGetUnits(realm, placed_obj, entity, nil, nil, nil, nil, "WasteRockObstructor", force_extend_bb)
		local rocks2 = HexGetUnits(realm, cursor_obj, entity, nil, nil, nil, nil, "WasteRockObstructor", force_extend_bb)
		--tunnels destroy rocks
		for i = 1, #(rocks1 or empty_table) do
			DoneObject(rocks1[i])
		end
		
		for i = 1, #(rocks2 or empty_table) do
			DoneObject(rocks2[i])
		end
		
		params1 = PlaceConstructionSite(self.city, self.template_name, placed_obj:GetPos(), placed_obj:GetAngle(), params1)
		
		params2 = PlaceConstructionSite(self.city, self.template_name, cursor_obj:GetPos(), cursor_obj:GetAngle(), params2)
		
		DoneObject(self.placed_obj)
		self.placed_obj = false
	else
		--place a cursor obj to mark tunnel entrance
		self.placed_obj = ObstacleCursorBuilding:new{ template = self.template_obj, entity = self.template_obj:GetEntity() }
		self.placed_obj:SetPos(self.cursor_obj:GetPos())
		self.placed_obj:SetAngle(self.cursor_obj:GetAngle())
		self.placed_obj:SetEnumFlags(const.efVisible)
	end
	
	local terrain_pos = HexGetNearestCenter(GetUIStyleGamepad() and GetTerrainGamepadCursor() or GetTerrainCursor())
	self:UpdateCursor(terrain_pos)
	return true
end

function TunnelConstructionController:Deactivate(pt)
	if self.placed_obj then
		DoneObject(self.placed_obj)
		self.placed_obj = false
		return false --don't kill me
	else
		if IsValid(self.cursor_obj) then
			DoneObject(self.cursor_obj)
			self.cursor_obj = false
		end
		
		self:ColorRocks()
		self:ClearColorFromAllConstructionObstructors()
		return true --kill me
	end
end

function TunnelConstructionController:UpdateConstructionStatuses(pt)
	local old_t = ConstructionController.UpdateConstructionStatuses(self, "dont_finalize")
	
	if self.placed_obj then
		if not IsCloser2D(self.placed_obj, self.cursor_obj, self.max_range * const.GridSpacing) then
			table.insert(self.construction_statuses, ConstructionStatus.TooFarFromTunnelEntrance)
		end
		table.remove_entry(self.construction_statuses, ConstructionStatus.NoDroneHub)
	end

	self:FinalizeStatusGathering(old_t)
end

function TunnelConstructionController:UpdateConstructionObstructors()
	ConstructionController.UpdateConstructionObstructors(self)
	
	local realm = GetRealm(self)
	local template_obj = self.template_obj
	local force_extend_bb = template_obj:HasMember("force_extend_bb_during_placement_checks") and template_obj.force_extend_bb_during_placement_checks ~= 0 and template_obj.force_extend_bb_during_placement_checks or false
	if self.placed_obj and HexGetUnits(realm, self.cursor_obj, template_obj:GetEntity(), nil, nil, "test", nil, "ObstacleCursorBuilding", force_extend_bb) then
		table.insert(self.construction_obstructors, self.placed_obj)
	end
end

function TunnelConstructionController:UpdateCursor(pt)
	ShowNearbyHexGrid(pt)
	
	if IsValid(self.cursor_obj) then
		local terrain = GetTerrain(self.city)
		self.cursor_obj:SetPos(FixConstructPos(terrain, pt))
	end
	ObjModified(self)
	if not self.template_obj or not self.cursor_obj then return end
	self:UpdateConstructionObstructors()
	self:UpdateConstructionStatuses(pt)
	self:UpdateShortConstructionStatus()
end
