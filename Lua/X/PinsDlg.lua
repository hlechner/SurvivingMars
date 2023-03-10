
DefineClass.PinsDlg = {
	__parents = {"XDrawCacheDialog"},
	
	HAlign = "center",
	VAlign = "bottom",
	LayoutMethod = "HOverlappingList",
	FocusOnOpen = "",
	LayoutHSpacing = 10,
	Margins = box(100, 0, 500, 0),
	map_id = ActiveMapID,
}

function PinsDlg:Open(...)
	self.map_id = ActiveMapID
	self:RecalculateMargins()
	local gamepad_image = XTemplateSpawn("XImage", self)
	gamepad_image:SetId("idGamepadImage")
	gamepad_image:SetHAlign("left")
	gamepad_image:SetImage(GetPlatformSpecificImagePath("RB"))
	gamepad_image:SetImageScale(point(800,800))
	gamepad_image:SetMargins(box(0,0,10,0))
	local gamepad = GetUIStyleGamepad()
	gamepad_image:SetVisible(gamepad)
	gamepad_image:SetDock(gamepad and "left" or "ignore")
	
	local game_map = GameMaps[ActiveMapID]
	if game_map then
		local pinned_objects = game_map.pinnables.pins or empty_table
		self:PinObjects(pinned_objects, "open")
	end

	self:CreateThread("AutoUpdate", function(self)
		--this 1ms delay is here to quickly update the dialog after the first objects have been added
		Sleep(1)
		while true do
			local game_map = GameMaps[ActiveMapID]
			local pinned_objects = game_map and game_map.pinnables.pins or empty_table
			for _, obj in ipairs(pinned_objects) do
				ObjModified(obj)
			end
			Sleep(1000)
		end
	end, self)

	XDialog.Open(self, ...)
end

function PinsDlg:Pin(obj, on_open)
	local button = XTemplateSpawn("PinButton", self, obj)
	self:InitPinButton(button)
	if not on_open then
		button:Open()
		self:ResolveRelativeFocusOrder()
		self:UpdateGamepadHint()
	end
end

function PinsDlg:PinObjects(objs, on_open)
	for _, obj in ipairs(objs) do
		self:Pin(obj, on_open)
	end
end

function PinsDlg:Unpin(obj)
	for _, win in ipairs(self) do
		if not win.Dock and win.context == obj then
			win:Close()
			self:ResolveRelativeFocusOrder()
			self:UpdateGamepadHint()
			return
		end
	end
end

function PinsDlg:UnpinObjects(objs)
	for _, obj in ipairs(objs) do
		self:Unpin(obj)
	end
end

function PinsDlg:RecalculateMargins()
	--This is temporarily and should be removed when implementing InGameInterface with new UI
	local hud_margins = box()
	local hud = GetHUD()
	if hud then
		local gamepad = GetUIStyleGamepad() and not UseHybridControls()
		local ui_scale = GetUIScale()
		local hud_side_width = Max(hud.idLeft.measure_width, hud.idLeft.MinWidth)
		hud_side_width = MulDivRound(hud_side_width, 100, ui_scale)
		
		local pins_side_margin = Max(PinsDlg.Margins:minx(), PinsDlg.Margins:maxx())
		local side_margin = gamepad and (hud_side_width + 10 - pins_side_margin) or 0
		local bottom_margin = gamepad and 10 or 80
		hud_margins = box(side_margin, 0, side_margin,bottom_margin)
	end
	self:SetMargins(PinsDlg.Margins + hud_margins + GetSafeMargins())
end

function UpdatePinsDlgMargins()
	local pins_dlg = GetDialog("PinsDlg")
	if pins_dlg then
		pins_dlg:RecalculateMargins()
	end
end

OnMsg.SafeAreaMarginsChanged = UpdatePinsDlgMargins
OnMsg.ControlSchemeChanged = UpdatePinsDlgMargins

function PinsDlg:OnSetFocus()
	self:UpdateGamepadHint()
	XDialog.OnSetFocus(self)
end

function PinsDlg:OnKillFocus()
	self:UpdateGamepadHint()
	XDialog.OnKillFocus(self)
end

function PinsDlg:SetVisible(visible, instant, ...)
	if self.window_state == "destroying" then return end
	
	if self:IsThreadRunning("SetVisibleThread") then
		self:DeleteThread("SetVisibleThread")
		XDrawCacheDialog.SetVisible(self, false, "instant", ...)
	end
	
	if self:GetVisible() == visible then
		return
	end

	if instant then
		XDrawCacheDialog.SetVisible(self, visible, "instant", ...)
	end

	local function ButtonAnimation(button, start_time, show)
		local box = button.box
		button:AddInterpolation{
			id = "drop",
			type = const.intRect,
			originalRect = Offset(box, point(0, -box:sizey())),
			targetRect = box,
			start = start_time,
			duration = 250,
			flags = show and const.intfInverse or nil,
			easing = const.Easing.CubicIn,
			autoremove = true,
		}
		button:AddInterpolation{
			id = "fade",
			type = const.intAlpha,
			startValue = 0,
			endValue = 255,
			start = start_time + 50,
			duration = 150,
			autoremove = not not show,
			flags = not show and const.intfInverse or nil,
		}
	end
	
	if visible then
		XDrawCacheDialog.SetVisible(self, true, "instant", ...)
	end
	
	local half = (#self - 1) / 2
	local delay = 30
	local start_time = GetPreciseTicks() + half * delay
	for i=2,#self do
		ButtonAnimation(self[i], start_time, visible)
		start_time = start_time + (i <= half and -delay or delay)
	end
	
	if not visible then
		self:CreateThread("SetVisibleThread", function(self, visible, instant, ...)
			Sleep(30 * (#self / 2) + 250)
			XDrawCacheDialog.SetVisible(self, false, "instant", ...)
		end, self, visible, instant, ...)
	end
end

function PinsDlg:UpdateGamepadHint()
	if #self <= 1 or not GetUIStyleGamepad() then
		self.idGamepadImage:SetVisible(false)
		return
	end
	
	local focus = self.desktop:GetKeyboardFocus()
	if IsKindOfClasses(focus, "SelectionModeDialog", "OverviewModeDialog", "InGameInterface") then
		self.idGamepadImage:SetVisible(true)
	else
		self.idGamepadImage:SetVisible(false)
	end
end

function PinsDlg:OnXButtonDown(button)
	if button == "ButtonB" then
		self:SetFocus(false, true)
		return "break"
	elseif XShortcutToRelation[button] then
		self:OnShortcut(button)
		return "break"
	elseif button == "LeftShoulder" then
		self:OnShortcut("DPadLeft")
		return "break"
	elseif button == "RightShoulder" then
		self:OnShortcut("DPadRight")
		return "break"
	elseif button == "RightTrigger" then
		if SelectedObj then
			self:SetFocus(false, true)
			return "continue"
		end
	end
end

local blocked_xbox_shortcuts = {
	["LeftThumbLeft"] = true,
	["LeftThumbDownLeft"] = true,
	["LeftThumbUpLeft"] = true,
	["LeftThumbRight"] = true,
	["LeftThumbDownRight"] = true,
	["LeftThumbUpRight"] = true,
	["LeftThumbUp"] = true,
	["LeftThumbDown"] = true,
}

function PinsDlg:OnMouseEnter(pos)
	if UseGamepadUI() then return end
	local igi = GetInGameInterface()
	local dlg = igi and igi.mode_dialog
	if dlg and dlg:IsKindOf("UnitDirectionModeDialog") and dlg.unit then
		dlg:HideMouseCursorText(pos)
	end	
	return XDialog.OnMouseEnter(self, pos)
end

function PinsDlg:OnShortcut(shortcut, source)
	if shortcut == "Escape" then
		self:SetFocus(false, true)
		return "break"
	elseif shortcut == "DPadLeft" then
		--implements looping around the ends of the pins dlg
		
		local focus = self.desktop:GetKeyboardFocus()
		if focus:IsWithin(self) and focus:GetFocusOrder():x() == 1 then
			self[#self]:SetFocus(true)
			return "break"
		end
	elseif shortcut == "DPadRight" then
		--implements looping around the ends of the pins dlg
		
		local focus = self.desktop:GetKeyboardFocus()
		--minus 1 because the first item is the gamepad hint icon
		--thus focus orders of pins start from 1 and end at #self-1
		if focus:IsWithin(self) and focus:GetFocusOrder():x() == (#self - 1) then
			self[2]:SetFocus(true) --2, for the same reason as above
			return "break"
		end
	elseif blocked_xbox_shortcuts[shortcut] then
		--block thumbstick from navigating the pins
		return "break"
	end
	return XDialog.OnShortcut(self, shortcut, source)
end

function PinsDlg:GetPinConditionImage(obj)
	if not obj then return end
	local img
	if obj:IsKindOf("RocketBase") then
		img = obj.pin_status_img
	elseif obj:HasMember("ui_working") and not obj.ui_working then
		img = "UI/Icons/pin_turn_off.tga"
	elseif obj:IsKindOf("Demolishable") and obj.demolishing then
		img = "UI/Icons/pin_salvage.tga"
	elseif obj:HasMember("IsMalfunctioned") and obj:IsMalfunctioned() then
		img = "UI/Icons/pin_malfunction.tga"
	elseif obj:IsKindOf("ElectricityConsumer") and obj:ShouldShowNoElectricitySign() then
		img = "UI/Icons/pin_power.tga"
	elseif obj:IsKindOf("AirConsumer") and obj:ShouldShowNoAirSign() then
		img = "UI/Icons/pin_oxygen.tga"
	elseif obj:IsKindOf("WaterConsumer") and obj:ShouldShowNoWaterSign() then
		img = "UI/Icons/pin_water.tga"
	elseif obj:IsKindOf("BaseRover") then
		if obj:IsDead() then
			img = "UI/Icons/pin_not_working.tga"
		end
		if obj:IsStorageFull() then
			img = "UI/Icons/pin_full.tga"
		elseif	obj.command == "Idle" or obj.command == "LoadingComplete" then
			img = "UI/Icons/pin_idle.tga"
		end
		if obj.goto_target then
			img = "UI/Icons/pin_moving.tga"
		elseif obj.command == "Analyze" then
			img = "UI/Icons/pin_scan.tga"
		elseif obj.command == "DumpCargo" or obj.command == "Unload" then
			img = "UI/Icons/pin_unload.tga"
		elseif obj.command == "PickupResource" or obj.command == "Load" then
			img = "UI/Icons/pin_load.tga"
		elseif obj:IsKindOf("RCTerraformer") and obj.command == "Construct" then
			img = "UI/Icons/pin_landscaping.tga"
		end
	elseif obj:IsKindOf("Drone") and obj.command == "Idle" then
		img = "UI/Icons/pin_idle.tga"
	elseif IsKindOf(obj, "Building") and obj:ShouldShowNoCCSign() then
		img = "UI/Icons/pin_drone.tga"
	elseif obj:HasMember("working") and not obj.working then
		img = "UI/Icons/pin_not_working.tga"
	elseif obj:IsKindOf("Dome") and obj.overpopulated then
		img = "UI/Icons/pin_overpopulated.tga"
	end
	return img
end

local function resolve_pin_rollover_hint(obj, gamepad)
	local hint_property = gamepad and "pin_rollover_hint_xbox" or "pin_rollover_hint"
	local hint = obj:GetProperty(hint_property)
	if not hint then
		hint = PinnableObject[hint_property]
	elseif hint ~= "" then
		hint = T{hint, obj}
	end
	 
	if obj:CanBeUnpinned() then
		if gamepad then
			return T{10988, "<hint> <ButtonY> Unpin", hint = hint}
		else
			return T{10988, "<hint> <ButtonY> Unpin", hint = hint, ButtonY=TLookupTag("<right_click>")}
		end
	end
	return hint
end

function PinsDlg:InitPinButton(button)
	local obj = button.context
	button.keep_highlighted = false
		
	if obj.pin_summary2 ~= "" then
		button.idTextBackground:SetImage("UI/Common/pin_shadow_2.tga")
	end
	
	local icon = obj:GetPinIcon()
	button:SetIcon(icon)
	if obj:IsKindOf("Colonist") then
		button.idSpecialization:SetImage(obj.pin_specialization_icon)
	end
	button.idIcon.Columns = 2
	button.idIcon:SetColumn(1)
	
	local old_SetRollover = button.SetRollover
	function button:SetRollover(rollover)
		old_SetRollover(self, rollover or self.keep_highlighted)
		self.idIcon:SetColumn(button:GetColumn())
	end
	
	function button:OnPress(gamepad)
		if self.context:OnPinClicked(gamepad) then
			return
		end
		if SelectedObj == obj then
			ViewObjectMars(self.context)
		else
			SelectObj(self.context)
		end
	end
	
	local old_OnShortcut = button.OnShortcut
	function button:OnShortcut(shortcut, soruce, repeated)
		if shortcut == "ButtonY" then
			if self.context:CanBeUnpinned() then
				local next_pin = self.parent:GetRelativeFocus(self.FocusOrder, "next") or self.parent:GetRelativeFocus(self.FocusOrder, "prev")
				if next_pin then
					next_pin:SetFocus()
				end
				self.context:TogglePin()
			end
			return "break"
		else
			return old_OnShortcut(self, shortcut, soruce, repeated)
		end
	end
	
	function button:OnAltPress(gamepad)
		if SelectedObj and self.context and IsKindOf(SelectedObj, "Drone")
			and IsKindOf(self.context, "DroneControl") and SelectedObj.interaction_mode == "reassign"
			and self.context:CanHaveMoreDrones() and SelectedObj.command_center ~= self.context then
			
			SelectedObj:SetCommandCenterUser(self.context)
		else
			self.context:TogglePin()		
		end
	end
	
	--achieve proper highlighting of pin btn - highlight when interacting with it, zoom-in in other cases
	local old_OnMouseLeft = button.OnMouseLeft
	function button:OnMouseLeft()
		old_OnMouseLeft(self)
		local mouse_pos = self.desktop.last_mouse_pos
		if mouse_pos and not self:MouseInWindow(mouse_pos) and not self.blinking then
			self.idRollover:SetVisible(false)
		end
	end
	
	--achieve proper highlighting of pin btn - highlight when interacting with it, zoom-in in other cases
	local old_OnMouseEnter = button.OnMouseEnter
	function button:OnMouseEnter()
		old_OnMouseEnter(self)
		local mouse_pos = self.desktop.last_mouse_pos
		if mouse_pos and self:MouseInWindow(mouse_pos) then
			self.idRollover:SetVisible(true)
		end
	end
	
	function button:OnContextUpdate(context)
		local icon = context:GetPinIcon()
		if icon ~= self:GetIcon() then
			self:SetIcon(icon)
			if context:IsKindOf("Colonist") then
				self.idSpecialization:SetImage(obj.pin_specialization_icon)
			end		
		end
		local condition_icon = self.parent:GetPinConditionImage(context)
		self.idCondition:SetVisible(not not condition_icon)
		if condition_icon then
			self.idCondition:SetImage(condition_icon)
		end
		if context.pin_blink ~= self.blinking then
			self:SetBlinking(context.pin_blink, context.pin_obvious_blink)
		end
		assert(obj.pin_rollover~="" or (type(obj.description)== "string" and obj.description~="")or obj:GetProperty("description"), "Add pin description for object: ".. tostring(obj.class))
		local text = "" 
		local rollover = obj.pin_rollover
		if type(rollover) == "function" then 
			rollover =  rollover(obj)
		end
		if rollover == "" then
			text = (obj.description ~= "" and T{obj.description, obj}) or obj:GetProperty("description") or ""
		elseif IsT(rollover) or type(rollover) == "string" then
			text = T{rollover, obj}
		end
		
		self:SetRolloverTitle(T{8108, "<Title>", obj})
		self:SetRolloverText(text)
		self:SetRolloverHint(resolve_pin_rollover_hint(obj))
		self:SetRolloverHintGamepad(resolve_pin_rollover_hint(obj, "gamepad"))
	
		return XTextButton.OnContextUpdate(self, context)
	end
		
	local old_OnSetFocus = button.OnSetFocus
	if obj and IsValid(obj) and obj:IsKindOf("InfopanelObj") and obj:HasMember("GetPos") then
		function button:OnSetFocus(...)
			if self.context:GetPos() ~= InvalidPos() then
				SelectObj(self.context)
			else
				SelectObj()
			end
			return old_OnSetFocus(self, ...)
		end
	else
		function button:OnSetFocus(...)
			SelectObj()
			return old_OnSetFocus(self, ...)
		end
	end	
	
	--achieve proper highlighting of pin btn - highlight when interacting with it, zoom-in in other cases
	local old_OnKillFocus = button.OnKillFocus
	function button:OnKillFocus()
		old_OnKillFocus(self)
		if not self.blinking then
			self.idRollover:SetVisible(false)
		end
	end
end

local function UpdatePinDlgOrdering(map_id)
	local pinned_objects = GameMaps[map_id].pinnables.pins

	--update order of ctrls in the pins dialog
	local pins_dlg = GetDialog("PinsDlg")
	if pins_dlg then
		local obj_to_ctrl = {}
		--the first ctrl in PinsDlg is the gamepad hint icon
		for i=2,#pins_dlg do
			local ctrl = pins_dlg[i]
			obj_to_ctrl[ctrl.context] = ctrl
			rawset(pins_dlg, i, nil)
		end
		for i,obj in ipairs(pinned_objects) do
			rawset(pins_dlg, i + 1, obj_to_ctrl[obj])
		end
		pins_dlg:InvalidateLayout()
		pins_dlg:ResolveRelativeFocusOrder()
	end
end

function SortPinnedObjs()
	SortPins(ActiveMapID)
	UpdatePinDlgOrdering(ActiveMapID)
end

function OnMsg.PostLoadGame()
	SortPinnedObjs()
end

function OnMsg.SwitchMap(map_id)
	local pins_dlg = GetDialog("PinsDlg")
	if pins_dlg then
		local old_objs = {}
		for i=2,#pins_dlg do
			local ctrl = pins_dlg[i].context
			table.insert(old_objs, ctrl)
		end		
		pins_dlg:UnpinObjects(old_objs)

		local pins = GameMaps[map_id].pinnables.pins
		pins_dlg:PinObjects(pins)
		pins_dlg.map_id = map_id
	end
end

function OnMsg.GamepadUIStyleChanged()
	local pins_dlg = GetDialog("PinsDlg")
	if pins_dlg then
		local gamepad = GetUIStyleGamepad()
		pins_dlg.idGamepadImage:SetVisible(gamepad)
		pins_dlg.idGamepadImage:SetDock(gamepad and "left" or "ignore")
		pins_dlg:RecalculateMargins()
	end
end

function OnMsg.OnControllerTypeChanged(controller_type)
	local pins_dlg = GetDialog("PinsDlg")
	if pins_dlg then
		pins_dlg.idGamepadImage:SetImage(GetPlatformSpecificImagePath("RB"))
	end
end

function OnMsg.SelectionAdded(obj)
	local pins_dlg = GetDialog("PinsDlg")
	if not pins_dlg then return end
	
	for i,pin in ipairs(pins_dlg) do
		if not pin.Dock and pin.context == obj then
			pin.keep_highlighted = true
			local focus = pin.desktop:GetKeyboardFocus()
			if focus and focus:IsWithin(pins_dlg) then
				pin:SetFocus(true)
			else
				pin:OnMouseEnter()
			end
		end
	end
end

function OnMsg.SelectionRemoved(obj)
	local pins_dlg = GetDialog("PinsDlg")
	if not pins_dlg then return end
	
	for i,pin in ipairs(pins_dlg) do
		if not pin.Dock and pin.context == obj then
			pin.keep_highlighted = false
			pin:OnMouseLeft()
			pin:SetFocus(false, true)
		end
	end
end
