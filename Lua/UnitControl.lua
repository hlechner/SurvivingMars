GlobalVar("CityUnitController", {})

if FirstLoad then
	g_RightClickControlsVehicles = false
	g_RightClickOpensBuildMenu = true
end

local function UpdateRightClickControl()
	if not AccountStorage then return end
	local old_vehicle_controls = g_RightClickControlsVehicles
	local old_build_menu = g_RightClickOpensBuildMenu
	
	g_RightClickControlsVehicles = AccountStorage.Options.RightClickAction ~= "Build"
	g_RightClickOpensBuildMenu = AccountStorage.Options.RightClickAction ~= "Move"
	UnitDirectionModeDialogExec(function(dlg)dlg:UpdateMouseCursor()end)
	
	local changed = (g_RightClickControlsVehicles ~= old_vehicle_controls) or (g_RightClickOpensBuildMenu ~= old_build_menu)
	if changed then
		g_BuildMenuRightClickPopupShown = true
	end
end

function OnMsg.OptionsApply()
	UpdateRightClickControl()
end

function OnMsg.AccountStorageChanged()
	UpdateRightClickControl()
end

function MoveUnitsOnRightClick()
	return g_RightClickControlsVehicles
end

function GetCursorWorldPos()
	return UseGamepadUI() and GetTerrainGamepadCursor() or GetTerrainCursor()
end
------------------------------------------------------------------------------
------------------------------------------------------------------------------

DefineClass.UnitDirectionModeDialog = {
	__parents = { "InterfaceModeDialog" },
	selection_dir_arrow = false,
	mode_name = "unit_direction_internal_use_only", -- should not be used directly, only through derived classes
	
	unit = false,
	last_mouse_pos = false,
	interaction_obj = false,
	interaction_pos = false,
	interaction_hint = false,
	block_goto = false,
	active_interaction = false,
	
	interaction_mode = false, --passed to CanInteract and InteractWith so they can do custom stuff when button is toggled.
	interaction_handler = false,
	
	fx_start_args = false,
	
	created_route = false,
	route_visuals = false,
	route_texts = false,
	cursor_obj = false,
}

function UnitDirectionModeDialog:Close(...)
	if self.route_visuals then
		DoneObjects(self.route_visuals)
		self.route_visuals = false
	end
	if self.route_texts then
		DoneObjects(self.route_texts)
		self.route_texts = false
	end
	self.created_route = false
	self:UpdateCursorObj()

	XDialog.Close(self, ...)
end

--helper lookup
local interaction_modes_with_no_obj_req = { --basically click on ground is just as good as selecting obj
	unload = true,
	load = true,
	move = true,
	gather_surface_deposits = true,
}

function UnitDirectionModeDialog:SetFocus()
	InterfaceModeDialog.SetFocus(self)
	self.last_mouse_pos = false
	self:OnMousePos()
end

function UnitDirectionModeDialog:ActivateUnitControl(obj, start_controllable)
	if GetUIStyleGamepad() then
		local focus = terminal.desktop:GetKeyboardFocus()
		if focus then
			local pins = GetDialog("PinsDlg")
			local infobar = GetDialog("Infobar")
			if not focus:IsWithin(pins) and not focus:IsWithin(infobar) then
				self:SetFocus()
			end
		else
			self:SetFocus()
		end
	else
		self:SetFocus()
	end
	
	assert(obj)
	if self.unit and IsKindOf(self.unit, "ExplorerRover") then
		HideResourceIcons("explorer")
	end
	self.unit = obj
	if IsKindOf(self.unit, "ExplorerRover") then
		ShowResourceIcons("explorer")
	end
	self.interaction_mode = obj.interaction_mode or false
	CityUnitController[UICity]:Activate(self.unit)
	self.Cursor = const.DefaultMouseCursor
	self.active_interaction = false
	self:UpdateMouseCursor()
	self:UpdateCursorText()
	if start_controllable then
		SetUnitControlInteractionMode(self.unit, "move")
	end
	
	if self.interaction_mode == "route" and not self.created_route and self.interaction_handler then
		self:SetCreateRouteMode(true, obj.ui_data_propagate)
		obj.ui_data_propagate = nil
		self.interaction_handler:UpdateRouteVisuals(self)
		self:UpdateCursorText()
	end
end

function UnitDirectionModeDialog:DeactivateUnitControl()
	if not self.unit then return end
	
	if self.unit:HasMember("ui_data_propagate") and self.unit.ui_data_propagate then
		self.unit.ui_data_propagate = nil
	end
	if IsKindOf(self.unit, "ExplorerRover") then
		HideResourceIcons("explorer")
	end
	
	SelectionRemove(self.unit)
	CityUnitController[UICity]:Deactivate()
	
	if self.interaction_mode then
		SetUnitControlInteractionMode(self.unit, false)
	end
	
	if IsValid(self.route_visuals) then
		DoneObjects(self.route_visuals)
		self.route_visuals = false
	end
	
	if IsValid(self.route_texts) then
		DoneObjects(self.route_texts)
		self.route_texts = false
	end
	
	if IsValid(self.cursor_obj) then
		DoneObject(self.cursor_obj)
		self.cursor_obj = false
	end
	
	self.unit = false
	self:UpdateMouseCursor()
	self:UpdateCursorText()
	self:SetCreateRouteMode(false)
	ShowMouseCursor("InGameInterface")
	ShowGamepadCursor("construction")
end

function UnitDirectionModeDialog:UpdateMouseCursor()
	local xcursor = GetGamepadCursor()
	if UseGamepadUI() or
		(not IsValid(self.unit) or (not self.interaction_mode and not MoveUnitsOnRightClick()) or (not self.unit:CanBeControlled() and not self.interaction_mode)) then
		self:SetMouseCursor(const.DefaultMouseCursor)
	elseif self.interaction_obj then
		self:SetMouseCursor(const.DefaultInteractionCursor)
	else
		self:SetMouseCursor(self.unit:GetCursor())
	end
end

function UnitDirectionModeDialog:AllowExitToOverview()
	return not self.interaction_handler
end

local interaction_mode_cursor_text = {
	--["move"] = T{7972, "Select Target"},
	["route"] = T(7972, "Select Target"),
	["reassign"] = T(4427, "Reassign"),
	["reassign_all"] = T(4427, "Reassign"),
	["maintenance"] = T(4433, "Perform Maintenance"),
	["recharge"] = T(7973, "Select target"),
	["assign_to_bld"] = T(7972, "Select Target"),
	["build"] = T(9800, "Build"),
}

function UnitDirectionModeDialog:HideMouseCursorText(pos)
	if self.unit then
		local hud = GetHUD()
		local ctrl = hud and hud.idtxtConstructionStatus
		if ctrl then
			ctrl:SetVisible(false)
		end
	end
end

function UnitDirectionModeDialog:UpdateCursorText()
	local hud = GetHUD()
	if not hud then
		return
	end
	local gamepad = UseGamepadUI()
	local txt
	if self.unit and self.unit:CanBeControlled() then
		if self.interaction_mode == "route" and self.interaction_handler then
			txt = self.interaction_handler:UpdateCursorText(self)
			hud.idSightsStatus:AddDynamicPosModifier({ id = "unit_direction", target = gamepad and "gamepad" or "mouse"})
			self.interaction_handler:UpdateTooltip(self)
		else
			txt = interaction_mode_cursor_text[self.interaction_mode]
			ShowTooltip(false)
		end
	end

	if not txt then
		local hint = self.unit and self.interaction_hint or ""
		txt = gamepad and Untranslated("\n")..hint or hint		
	end
	
	local ctrl = hud.idtxtConstructionStatus
	local xcursor = GetGamepadCursor()
	ctrl:SetVisible(txt and txt~= "")
	if txt and txt~= "" and txt ~= ctrl:GetText() then
		ctrl:SetText(txt)
		ctrl:SetMargins(box(40,40,0,0))
		ctrl:AddDynamicPosModifier({ id = "unit_direction", target = gamepad and "gamepad" or "mouse"})
	end
end

function UnitDirectionModeDialog:HideCursorText()
	local hud = GetHUD()
	if not hud then
		return
	end
	hud.idtxtConstructionStatus:SetVisible(false)
end

local refreshing_interaction = false
function UnitDirectionModeDialog:RefreshActiveInteraction()
	if UseGamepadUI() then return end
	local o = self.active_interaction or SelectionMouseObj()
	if not self.unit or IsEditorActive() or o ~= refreshing_interaction then return end
	CityUnitController[UICity].position = false
	local p = GetTerrainCursor()
	self:UpdateInteractionObj(o, p)
	self:UpdateCursorObj(p)
	self:UpdateMouseCursor()
	self:UpdateCursorText()
	self.active_interaction = false
end

function UnitDirectionModeDialog:OnMouseButtonDown(pt, button)
	if button == "R" then
		if not self.unit or IsEditorActive() then return end
		if MoveUnitsOnRightClick() and self.interaction_mode == false then
			self:UpdateInteractionObj(SelectionMouseObj(), GetTerrainCursor())
			local r = self:Interact(GetTerrainCursor())
			if not UseGamepadUI() and r == "break" then
				self:HideCursorText()
				refreshing_interaction = self.active_interaction or SelectionMouseObj()
				DelayedCall(10, UnitDirectionModeDialog.RefreshActiveInteraction, self)
			end
			return r
		end
		if self.interaction_mode == "move" then
			SetUnitControlInteractionMode(self.unit, false)
		elseif self.interaction_mode == "route" and self.created_route.from and not self.created_route.to then
			self.created_route.from = false
			self.created_route.obj_at_source = false
			SetUnitControlInteractionMode(self.unit, "route")
			self.interaction_handler:UpdateRouteVisuals(self)
			self:UpdateCursorObj()
			return "break"
		elseif not MoveUnitsOnRightClick() and not self.interaction_mode then
			if HintsEnabled and IsKindOfClasses(SelectedObj, "RCRover","RCTransport") then
				HintTrigger("HintVehicleOrders")
			end
			SelectObj()
			if g_RightClickOpensBuildMenu and not self:IsKindOf("OverviewModeDialog") then
				g_BuildMenuRightClicksCount = g_BuildMenuRightClicksCount + 1
				OpenXBuildMenu()
			end
		elseif self.interaction_mode == "route" then
			self:SetCreateRouteMode(false)
		end
		SetUnitControlInteractionMode(self.unit, false)
		return "break"
	elseif button == "L" then
		if not self.unit or IsEditorActive() then return end
		self:UpdateInteractionObj(SelectionMouseObj(), GetTerrainCursor())
		local r = self:InteractWithPos(GetTerrainCursor())
		if not UseGamepadUI() and r == "break" then
			self:HideCursorText()
			refreshing_interaction = self.active_interaction or SelectionMouseObj()
			DelayedCall(10, UnitDirectionModeDialog.RefreshActiveInteraction, self)
		end
		return r
	end
end

function UnitDirectionModeDialog:OnMouseButtonDoubleClick(pt, button)
	if not self.unit or IsEditorActive() then return end
	self:UpdateInteractionObj(SelectionMouseObj(), GetTerrainCursor())
	local r = self:InteractWithPos(GetTerrainCursor())
	if not UseGamepadUI() and r == "break" then
		self:HideCursorText()
		refreshing_interaction = self.active_interaction or SelectionMouseObj()
		DelayedCall(10, UnitDirectionModeDialog.RefreshActiveInteraction, self)
	end
	return r
end

function UnitDirectionModeDialog:InteractWithPos(pos, keep_control)
	if self.interaction_mode == "route" then
		self.interaction_handler:CreateRoute(self, pos)
		return "break"
	elseif not self.interaction_mode or
		(not self.interaction_obj and not interaction_modes_with_no_obj_req[self.interaction_mode]) then
		if self.interaction_mode then
			SetUnitControlInteractionMode(self.unit, false)
			return "break"
		else
			if HintsEnabled and IsKindOfClasses(SelectedObj, "RCRover","RCTransport") then
				HintTrigger("HintVehicleOrders")
			end
			--not activated, close us and select whatever is at pt.
			SelectObj()
			return
		end
	else
		return self:Interact(pos, keep_control)
	end
	return
end

local function PlayInteractFX(moment, actor, target)
	PlayFX("ClickInteract", moment, actor, target)
	local children = target and target:GetAttaches()
	if children then
		for i,child in ipairs(children) do
			PlayInteractFX(moment, actor, child)
		end
	end
end

function UnitDirectionModeDialog:Interact(pos, keep_control)
	HintDisable("HintVehicleOrders")

	if self.interaction_mode == "route" then
		self.interaction_handler:CreateRoute(self, pos)
		return "break"
	end
	--we are active and not sieged, do stuff.
	if self.interaction_obj then
		--we have an interactable building underneath
		if self.interaction_obj ~= self.active_interaction then
			CityUnitController[UICity]:InteractWithObject(self.interaction_obj, self.interaction_mode, self.interaction_pos)
			self.active_interaction = self.interaction_obj
		end
		if self.fx_start_args then
			local unit, target = table.unpack(self.fx_start_args)
			if IsValid(target) then
				PlayInteractFX("end", unit, target) --for spam
			end
			self.fx_start_args = false
		end
		self.fx_start_args = table.pack(self.unit, self.interaction_obj)
		PlayInteractFX("start", self.unit, self.interaction_obj)
		return "break"
	else
		self.active_interaction = false
		if not self.block_goto then
			CityUnitController[UICity]:GoToPos(pos)
			return "break"
		end
	end
	
	if self.interaction_mode and not keep_control then
		SetUnitControlInteractionMode(self.unit, false)
		return "break"
	end
end

function UnitDirectionModeDialog:UpdateInteractionObj(obj, pos)
	local gamepad = UseGamepadUI()
	obj = gamepad and IsKindOf(obj, "SurfaceDepositGroup") and obj.group[1] or obj
	local ctrl = CityUnitController[UICity]
	local mode = self.interaction_mode
	obj = obj or ctrl:ResolveObjAt(pos, mode)
	
	local interaction_obj = false
	local block_goto = nil
	
	local h1, h2, _
	if IsValid(obj) then
		interaction_obj, h1, block_goto = ctrl:CanInteractWithObject(obj, mode)
		interaction_obj = interaction_obj and obj
	else
		interaction_obj = interaction_obj or false
		h1 = gamepad and self.unit and self.unit:CanBeControlled("move") and T{4339, "<UnitMoveControl('ButtonA',interaction_mode)>: Move", self.unit} or false
	end
	
	if not interaction_obj and IsValid(obj) and not IsKindOfClasses(obj, "SharedStorageBaseVisualOnly", "StorageDepot") then
		local stockpiles = obj:GetAttaches("ResourceStockpileBase")
		interaction_obj = stockpiles and FindNearestObject(stockpiles, pos, function(stockpile)
			return stockpile ~= obj and ctrl:CanInteractWithObject(stockpile, mode)
		end)
		if interaction_obj then --get the hint
			_, h2, block_goto = ctrl:CanInteractWithObject(interaction_obj, mode)
		end
	end
	
	self.interaction_pos = pos
	self.interaction_obj = interaction_obj or false
	self.interaction_hint = (h2 or h1)
	
	self.block_goto = (block_goto or (GetDomeAtPoint(GetActiveObjectHexGrid(), pos) and IsKindOf(self.unit, "BaseRover")))
	if mode == "route" and self.interaction_handler then
		self.interaction_handler:UpdateRouteVisuals(self.interaction_handler, self)
	end
	self:UpdateCursorText()
end

function UnitDirectionModeDialog:OnMousePos(pt)
	if not self.unit then return end
	if UseGamepadUI() then return end
	local pos = GetTerrainCursor()
	if self.last_mouse_pos ~= pos then
		self:UpdateInteractionObj(SelectionMouseObj(), pos)
		self:UpdateCursorObj(pos)
		self:UpdateMouseCursor()
		self.last_mouse_pos = pos
	end
	return "break"
end

function UnitDirectionModeDialog:GamepadUpdateThread()
	while true do
		WaitNextFrame()
		local function UpdateForGamepadState(state_idx)
			local state = XInput.CurrentState[state_idx]
			if type(state) == "table" and state.LeftThumb then
				local x, y = state.LeftThumb:xy()
				if x ~= 0 or y ~= 0 then
					local pos = GetTerrainGamepadCursor()
					self:UpdateCursorObj(pos)
				end
			end
		end
		
		if Platform.pc then
			for i = 0, XInput.MaxControllers() - 1 do
				UpdateForGamepadState(i)
			end
		else
			UpdateForGamepadState(XPlayerActive)
		end
	end
end

function UnitDirectionModeDialog:UpdateCursorObj(pos)
	pos = pos or GetUIStyleGamepad() and GetTerrainGamepadCursor() or GetTerrainCursor()
	if self.created_route then
		self.interaction_handler:UpdateCursorObj(self, pos)
	else
		ShowGamepadCursor("construction")
		if IsValid(self.cursor_obj) then
			DoneObject(self.cursor_obj)
			self.cursor_obj = false
		end
	end
end

function UnitDirectionModeDialog:OnKbdKeyDown(virtual_key)
	if self.unit then
		if virtual_key == const.vkEsc then
			if self.interaction_mode then
				SetUnitControlInteractionMode(self.unit, false)
			else
				SelectObj()
			end
			if(GetInGameInterface().mode ~= "overview") then
				return "break"
			end
		end
	end
	return "continue"
end

function UnitDirectionModeDialog:OnShortcut(shortcut, source)
	if UseGamepadUI() and self.unit then
		if g_GamepadObjects then
			g_GamepadObjects:FindInteractableObj()
		else
			self:UpdateInteractionObj(SelectionGamepadObj(), GetTerrainGamepadCursor())
		end
	end
	self:UpdateCursorText()
	--when doing an action
	if self.unit then
		if self.interaction_mode then
			if shortcut == "+ButtonA" then
				self:InteractWithPos(GetTerrainGamepadCursor(), "keep_control")
				return "break"
			elseif shortcut == "+ButtonB" or shortcut == "+ButtonY" or shortcut == "+ButtonX" then
				SetUnitControlInteractionMode(self.unit, false)
				return "break"
			end
		end	
	end
	
	return InterfaceModeDialog.OnShortcut(self, shortcut, source)
end

function UnitDirectionModeDialog:SetCreateRouteMode(val, data)
	self.created_route = val 
	if val then
		self.created_route = self.interaction_handler:NewRoute()
	end
	if val then
		if GetUIStyleGamepad() then
			self:CreateThread("GamepadCursorUpdate", self.GamepadUpdateThread, self)
		end
	elseif not val then
		if self.interaction_handler then
			self.interaction_handler:UpdateRouteVisuals(self)
		end
		
		if self:IsThreadRunning("GamepadCursorUpdate") then
			self:DeleteThread("GamepadCursorUpdate")
		end
	end
	self:UpdateCursorObj()
	self:UpdateMouseCursor()
	self.desktop:UpdateCursor()
end

DefineClass.UnitController = {
	__parents = { "InitDone" },
	unit = false,
	position = false,
}

function UnitController:Activate(u)
	self.unit = u
	self.position = false
end

function UnitController:Deactivate()
	self.unit = false
end

function UnitController:OnUnitControlActiveChanged(new_val)
	if self.unit:HasMember("OnUnitControlActiveChanged") then
		self.unit:OnUnitControlActiveChanged(new_val)
	end
end

function UnitController:ResolveObjAt(pos, interaction_mode)
	if self.unit then 
		return self.unit:ResolveObjAt(pos, interaction_mode)
	else
		return nil
	end
end

function UnitController:CanInteractWithObject(o, m)
	if not self.unit then return end
	
	local gamepad = UseGamepadUI()
	if not gamepad then
		local mousetarget = terminal.desktop:GetMouseTarget(terminal.GetMousePos())
		if not mousetarget and not IsKindOfClasses(mousetarget, "SelectionModeDialog", "OverviewModeDialog") then		
			return false
		end	
	end
	if not self.unit:CanBeControlled(m) then return false end
	return self.unit:CanInteractWithObject(o, m)
end

function UnitController:InteractWithObject(o, m, p)
	if not self.unit then return false end
	if not self.unit:CanBeControlled(m) then return false end
	RebuildInfopanel(self.unit)
	return self.unit:InteractWithObject(o, m, p)
end

function UnitController:SetTransportRoute(r)
	self.unit:SetTransportRoute(r)
end

function UnitController:SetSafariRoute(r)
	self.unit:SetSafariRoute(r)
end

function UnitController:CallCustomFunctor(functor)
	return functor(self.unit)
end

function UnitController:GoToPos(pos)
	local u = self.unit
	if IsValid(u) and u:CanBeControlled("move") then --unit can be salvaged.
		local realm = GetRealm(u)
		local new_pos = realm:GetPassablePointNearby(pos, u.pfclass)
		if new_pos and new_pos ~= self.position then
			self.position = new_pos
			if self.position:x() ~= -1 and self.position:y() ~= -1 then
				PlayFX("ClickMove", "end", u)
				PlayFX("ClickMove", "start", u, nil, self.position)
				if u:HasMember("GoToPos") then
					u:GoToPos(self.position)
				else
					u:SetCommandUserInteraction("GotoFromUser", self.position)
				end
				if not u:IsKindOf("Building") then
					CreateGameTimeThread(RebuildInfopanel, u)
				end
			end
		end
	end
end

function UnitControlCreateRoute(unit)
	local dlg = GetInGameInterfaceModeDlg()
	if dlg and dlg:IsKindOf("UnitDirectionModeDialog") and dlg.unit == unit then
		dlg.interaction_handler:OnRouteCreated(dlg)
	end
end

function SetUnitControlInteractionMode(unit, m, handler, route)
	local dlg = GetInGameInterfaceModeDlg()	
	if dlg and dlg:IsKindOf("UnitDirectionModeDialog") and dlg.unit == unit then
		local old = dlg.interaction_mode
		if old ~= m then
			dlg.interaction_mode = m
			dlg.interaction_handler = handler
			dlg.active_interaction = false			
			unit:OnInteractionModeChanged(old, m)
			dlg:UpdateCursorText()
			if not m then
				dlg:UpdateMouseCursor()
			end
			
			if m ~= "route" and dlg.created_route ~= false then
				dlg:SetCreateRouteMode(false)
			elseif route then
				dlg.created_route = route
			end
		end
	end
end

function GetUnitControlInteractionMode()
	local dlg = GetInGameInterfaceModeDlg()
	return dlg and dlg.interaction_mode
end

function UnitDirectionModeDialogExec(fn)
	local dlg = GetInGameInterfaceModeDlg()
	if dlg and dlg:IsKindOf("UnitDirectionModeDialog") then
		return fn(dlg)
	end
end

function GetUnitControlDlg(unit)
	local dlg = GetInGameInterfaceModeDlg()
	if dlg and dlg:IsKindOf("UnitDirectionModeDialog") and dlg.unit == unit then 
		return dlg
	end	
end

function ResetUnitControlInteractionMode(mode, obj)
	if GetUnitControlDlg(obj) then
		SetUnitControlInteractionMode(obj, mode) 
	end
end

function SetUnitControlFocus(focus,obj)
	local dlg = GetUnitControlDlg(obj)
	if dlg then
		dlg:SetFocus(focus) 
	end	
end

function SetUnitControlInteraction(interact, obj)
	local dlg = GetUnitControlDlg(obj)
	if dlg then
		 dlg.active_interaction = interact
	end	
end
--[[
function GetUnitControlInteractionHint(unit, CanBeControlled_text, InalidControl_text)
	local dlg = GetUnitControlDlg(unit)
	if not dlg then return false end
	return dlg:HasMember("interaction_hint") and dlg.interaction_hint and dlg.interaction_hint~="" and dlg.interaction_hint or unit:CanBeControlled() and CanBeControlled_text or InalidControl_text
end
--]]

function ShouldQueueCommand(self)
	if 	IsKindOf(self, "MultiSelectionWrapper")
		or self.command == "Idle"
		or self:IsDisabled()
	then 
		return false
	end
	
	local queue = terminal.IsKeyPressed(const.vkShift) --TODO: gamepad
	return queue
end

function GetCommandFunc(self)
	local r = ShouldQueueCommand(self)
	return r and self.QueueCommand or self.SetCommand, r
end