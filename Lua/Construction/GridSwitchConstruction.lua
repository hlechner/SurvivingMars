DefineClass.GridSwitchConstructionDialog = {
	__parents = { "InterfaceModeDialog" },
	mode_name = "electricity_switch",
	MouseCursor =  "UI/Cursors/CablePlacement.tga",
	success_sound = "CableConstructionSuccess",
	template = false,
	
	TryCloseAfterPlace = TryCloseAfterPlace,
}

function GridSwitchConstructionDialog:Init()
	table.change(hr, "Construction", { RenderBuildGrid = 1, BuildGridRadius = 13000 })
	HideGamepadCursor("construction")
	ShowResourceIcons("construction")
	
	if GetUIStyleGamepad() then
		self:CreateThread("GamepadCursorUpdate", UpdateConstructionCursorObject, GetGridSwitchConstructionController())
	end
end

function GridSwitchConstructionDialog:Open(...)
	if self.mode_name == "passage_ramp" then
		if not Platform.durango then
			HideMouseCursor("InGameInterface")
		end
		HideGamepadCursor("construction")
		ShowResourceIcons("construction")
	end

	InterfaceModeDialog.Open(self, ...)
	self:SetModal(true)
	GetGridSwitchConstructionController():SetMode(self.mode_name)
	self:OnMousePos() --initial update
	DelayedCall(0, OpenGridSwitchConstructionInfopanel)
end

function GridSwitchConstructionDialog:Close(...)
	InterfaceModeDialog.Close(self, ...)
	while not GetGridSwitchConstructionController():Deactivate() do end
	table.restore(hr, "Construction")
	if self.mode_name == "passage_ramp" then
		ShowMouseCursor("InGameInterface")
	end
	ShowGamepadCursor("construction")
	HideResourceIcons("construction")
	
	if self:IsThreadRunning("GamepadCursorUpdate") then
		self:DeleteThread("GamepadCursorUpdate")
	end
	local dlg = GetHUD()
	if dlg then dlg.idtxtConstructionStatus:SetVisible(false) end	
end

function GridSwitchConstructionDialog:TryPlace(pos)
	if GetGridSwitchConstructionController():Activate(HexGetNearestCenter(pos)) then
		PlayFX(self.success_sound, "start")
		self:TryCloseAfterPlace()
	else
		PlayFX("ConstructionFail", "start")
	end
end

function GridSwitchConstructionDialog:OnMouseButtonDown(pt, button)
	if button == "L" then
		self:TryPlace(GetTerrainCursor())
	elseif button == "R" then
		if GetGridSwitchConstructionController():Deactivate(pt) then
			PlayFX("GridConstructionCancel", "start")
			CloseModeDialog()
			return "break"
		end
	elseif self.mode_name == "passage_ramp" and button == "M" then
		GetGridSwitchConstructionController():Rotate(-1)
		return "break"
	end
end

function GridSwitchConstructionDialog:OnMousePos(pt)
	local terrain_pos = GetConstructionTerrainPos("mouse")
	if GetActiveTerrain():IsPointInBounds(terrain_pos) then
		GetGridSwitchConstructionController():UpdateCursor(terrain_pos)
	end
	return "break"
end

function GridSwitchConstructionDialog:OnShortcut(shortcut, source)
	if shortcut == "ButtonA" or shortcut == "LeftTrigger-ButtonA" then
		self:TryPlace(GetTerrainGamepadCursor())
		return "break"
	elseif shortcut == "ButtonB" then
		self:OnMouseButtonDown(nil, "R") --cancel
		return "break"
	elseif shortcut == "Back" or shortcut == "TouchPadClick" then
		if DismissCurrentOnScreenHint() then
			return "break"
		end
	end
end

DefineClass.GridSwitchConstructionDialogPipes = {
	__parents = { "GridSwitchConstructionDialog" },
	mode_name = "lifesupport_switch",
	MouseCursor = "UI/Cursors/PipePlacement.tga",
	success_sound = "PipeConstructionSuccess",
}

DefineClass.GridSwitchConstructionDialogPassageRamp = {
	__parents = { "GridSwitchConstructionDialog" },
	mode_name = "passage_ramp",
	MouseCursor = const.DefaultMouseCursor,
	success_sound = "PipeConstructionSuccess",
}

DefineClass.GridSwitchConstructionController = {
	__parents = { "ConstructionController" },
	
	properties = {
		{id = "construction_statuses_property", editor = "text", name = T{""}, translate = true, default = false},
		{id = "DisplayName",                    editor = "text", name = T{""}, translate = true, default = false},
	},
	
	ignore_domes = true,
	cursor_obj = false,
	mode = "electricity_switch", --"electricity_switch" or "lifesupport_switch" or "passage_ramp"
	
	current_status = const.clrNoModifier,
	construction_statuses = false,
	is_template = true,
	stockpiles_obstruct = false,
	
	construction_ip = "ipGridConstruction",
}

function GridSwitchConstructionController:Getconstruction_costs_property()
	return ""
end

local passage_ramp_shape_hollow = false

function GridSwitchConstructionController:SetMode(mode)
	self.selected_domes = {}
	self.mode = mode
	if mode == "passage_ramp" then
		if not passage_ramp_shape_hollow then
			--initialize the shape
			passage_ramp_shape_hollow = table.copy(PassageRamp:GetShapePoints())
			table.remove_entry(passage_ramp_shape_hollow, point20)
			table.remove_entry(passage_ramp_shape_hollow, point(1, 0))
			table.remove_entry(passage_ramp_shape_hollow, point(-1, 0))
		end
		self.template_obj_points = passage_ramp_shape_hollow
		local template = "PassageRamp"
		self.template_name = template
		self.template_obj = ClassTemplates.Building[template] or g_Classes[template]
	else
		self.template_obj_points = false
		self.template_name = false
		self.template_obj = false
	end
	self:UpdateCursorObject(true)
	self.construction_statuses = {}
end

function GridSwitchConstructionController:UpdateCursorObject(visible)
	if visible then
		local entity
		local cm1, cm2, cm3, cm4
		if self.mode == "electricity_switch" then
			cm1, cm2, cm3, cm4 = GetCablesPalette()
			entity = "CableSwitch"
		elseif self.mode == "lifesupport_switch" then
			cm1, cm2, cm3, cm4 = GetPipesPalette()
			entity = "TubeSwitch"
		elseif self.mode == "passage_ramp" then
			entity = "PassageRamp"
		end
		if IsValid(self.cursor_obj) then
			self.cursor_obj.entity = entity
			self.cursor_obj:ChangeEntity(entity)
		else
			self.cursor_obj = CursorGridElement:new{ entity = entity }
			self.cursor_obj:SetEnumFlags(const.efVisible)
		end
		
		if cm1 then
			SetObjectPaletteRecursive(self.cursor_obj, cm1, cm2, cm3, cm4)
		end
		
		self:SetTxtPosObj(self.cursor_obj)
	elseif IsValid(self.cursor_obj) then
		self.cursor_obj:delete()
		self.cursor_obj = false
	end
end

GridSwitchConstructionController.SetTxtPosObj = GridConstructionController.SetTxtPosObj

function GridSwitchConstructionController:Activate(pt)
	--place
	local s = self:GetConstructionState()
	if s == "error" then
		return false
	end
	
	local pos = self.cursor_obj:GetPos()
	local q, r = WorldToHex(pos)
	local angle = self.cursor_obj:GetAngle()
	local game_map = GetGameMap(self)
	local object_hex_grid = game_map.object_hex_grid
	local realm = game_map.realm
	local obj_underneath = self.mode == "electricity_switch" and HexGetCable(object_hex_grid, q, r) or self.mode == "lifesupport_switch" and HexGetPipe(object_hex_grid, q, r)
													or self.mode == "passage_ramp" and HexGetPassageGridElement(object_hex_grid, q, r)
	assert(obj_underneath)
	
	local params = {obj_to_turn_into_switch = obj_underneath, place_stockpile = false}
	local no_blk_pass = false
	local rocks, stocks
	if self.mode == "passage_ramp" then
		local cursor_obj = self.cursor_obj
		local template_obj = self.template_obj
		rocks = HexGetUnits(realm, cursor_obj, template_obj:GetEntity(), nil, nil, nil, nil, "WasteRockObstructor")
		stocks = HexGetUnits(realm, cursor_obj, template_obj:GetEntity(), nil, nil, nil, function(obj) return obj:GetParent() == nil and IsKindOf(obj, "DoesNotObstructConstruction") and not IsKindOf(obj, "Unit") end, "ResourceStockpileBase")
		no_blk_pass = #rocks >= 0 or #stocks >= 0
		params.place_stockpile = true
		params.resource_stockpile_spot = "Workdrone"
	end
	local cs = PlaceConstructionSite(self.city, self.mode == "electricity_switch" and "ElectricitySwitch" or self.mode == "lifesupport_switch" and "LifesupportSwitch" 
										or self.mode == "passage_ramp" and "PassageRamp", pos, angle, params, no_blk_pass, self.mode ~= "passage_ramp")
	cs:AppendWasteRockObstructors(rocks)
	cs:AppendStockpilesUnderneath(stocks)
	return true
end

function GridSwitchConstructionController:Deactivate(pt)
	if IsValid(self.cursor_obj) then
		DoneObject(self.cursor_obj)
		self.cursor_obj = false
	end
	
	ConstructionController.ClearColorFromAllConstructionObstructors(self)
	self.construction_obstructors = false
	
	self:ClearDomeWithObstructedRoads()
	self:ColorRocks()
	
	return true --kill me
end

function GridSwitchConstructionController:UpdateConstructionStatuses(pt)
	local old_t = self.construction_statuses 
	self.construction_statuses = {}
	
	local q, r = WorldToHex(pt or self.cursor_obj)
	local object_hex_grid = GetObjectHexGrid(self)
	
	if self.mode == "electricity_switch" then
		local c = HexGetCable(object_hex_grid, q, r)
		if not c then
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.RequiresCable
		elseif IsKindOf(c, "ConstructionSite") then
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.RequiresCompletedCable
		elseif not c:CanMakeSwitch() then
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.UnevenTerrain
		end
	elseif self.mode == "lifesupport_switch" then
		local p = HexGetPipe(object_hex_grid, q, r)
		if not p then
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.RequiresPipe
		elseif IsKindOf(p, "ConstructionSite") then
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.RequiresCompletedPipe
		elseif not p:CanMakeSwitch() then
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.UnevenTerrain
		end
	elseif self.mode == "passage_ramp" then
		local p = HexGetPassageGridElement(object_hex_grid, q, r)
		if not p then
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.RequiresPassage
		elseif IsKindOf(p, "ConstructionSite") then
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.RequiresCompletedPassage
		end
		
		local to = self.template_obj
		local co = self.cursor_obj
		if not self:IsTerrainFlatForPlacement(to:GetBuildShape(), co:GetPos(), co:GetAngle()) then
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.UnevenTerrain
		end
		
		if self.template_obj.dome_forbidden and GetDomeAtHex(object_hex_grid, q, r) then
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.DomeProhibited
		end
	end
	
	if not DoesAnyDroneControlServiceAtPoint(self:GetMapID(), self.cursor_obj) then
		self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.NoDroneHub
	end
	
	if self.mode == "passage_ramp" then
		ConstructionController.UpdateConstructionObstructors(self)
		ConstructionController.SetColorToAllConstructionObstructors(self, g_PlacementStateToColor.Obstructing)
		if #(self.construction_obstructors or "") > 0 then
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.BlockingObjects
		end
	else
		local b = HexGetBuildingNoDome(object_hex_grid, q, r)
		if b then --any building blocks
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.BlockingObjects
		end
	end
	
	SortConstructionStatuses(self.construction_statuses)
	if not table.iequals(old_t, self.construction_statuses) then
		ObjModified(self)
	end
	
	self:PickCursorObjColor()
end

function GridSwitchConstructionController:UpdateCursor(pt)
	local game_map = GetGameMap(self.city)
	if IsValid(self.cursor_obj) then
		self.cursor_obj:SetPos(FixConstructPos(game_map.terrain, pt))
	end

	ShowNearbyHexGrid(IsTerrainFlatForPlacement(game_map.buildable, {point20}, pt, 0) and pt)
	self:UpdateConstructionStatuses(pt)
	self:UpdateShortConstructionStatus()
end

function GridSwitchConstructionController:PickCursorObjColor()
	local clr
	local s = self:GetConstructionState()
	if s == "error" then
		clr = g_PlacementStateToColor.Blocked
	else
		self:ClearColorFromAllConstructionObstructors()
		clr = s == "problem" and g_PlacementStateToColor.Problematic or g_PlacementStateToColor.Placeable
		self.construction_obstructors = false
	end
	self.cursor_obj:SetColorModifier(IsEditorActive() and const.clrNoModifier or clr) 
end

function GridSwitchConstructionController:GetDisplayName()
	if self.mode == "electricity_switch" then
		return T(885, "Power Switch")
	elseif self.mode == "lifesupport_switch" then
		return T(886, "Pipe Valve")
	elseif self.mode == "passage_ramp" then
		return T(8813, "Passage Ramp")
	end
end

function GridSwitchConstructionController:GetDescription()
	if self.mode == "electricity_switch" then
		return T(887, "Place a power switch")
	elseif self.mode == "lifesupport_switch" then
		return T(888, "Place a pipe valve")
	elseif self.mode == "passage_ramp" then
		return T(8778, "Place a passage ramp")
	end
end
