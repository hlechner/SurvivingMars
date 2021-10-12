DefineClass.OnScreenNotificationsDlg =
{
	__parents = {"XDialog"},
	Margins = box(60,60,0,220),
	FocusOnOpen = "",
	HAlign = "left",
	VAlign = "top",
	
	gamepad_selection = false,
}

function OnScreenNotificationsDlg:Init()
	XWindow:new({
		Id = "idNotifications",
		LayoutMethod = "VOverlappingList",
		LayoutVSpacing = 10,
		IdNode = true,
	}, self)
	local gamepad_controls = XWindow:new({
		Id = "idGamepadControls",
		Dock = "bottom",
		MinWidth = 450,
		MaxWidth = 450,
		FoldWhenHidden = true,
	}, self)
	local rollover = XFrame:new({
		Id = "idRolloverWindow",
		Margins = box(0,20,0,0),
		Padding = box(24, 0, 24, 20),
		BorderWidth = 0,
		VAlign = "top",
		HAlign = "left",
		Image = "UI/CommonNew/rollover.tga",
		FrameBox = box(35, 45, 35, 33),
		LayoutMethod = "VList",
		IdNode = false,
	}, gamepad_controls)
	rollover:SetVisible(false)
	XImage:new({
		Id = "idGamepadHint",
		Image = GetPlatformSpecificImagePath("LB"),
		ImageScale = point(800, 800),
		VAlign = "top",
		HAlign = "left",
	}, gamepad_controls)
	XText:new({
		Id = "idTitle",
		Translate = true,
		TextStyle = "RolloverTitleStyle",
		TextHAlign = "center",
		TextVAlign = "center",
		Dock = "top",
		MinHeight = 45,
		MaxHeight = 45,
	}, rollover)
	XText:new({
		Id = "idText",
		Margins = box(0,5,0,0),
		MinHeight = 100,
		Translate = true,
		TextStyle = "RolloverTextStyle",
		ShadowColor = RGBA(0,0,0,0),
	}, rollover)
end

function OnScreenNotificationsDlg:UpdateRollover()
	local selection = self.gamepad_selection
	local notif = selection and self.idNotifications[selection]
	if not notif then
		return
	end
	
	local descr = T(7548, "<LB> / <DPadUp> Navigate <DPadDown> / <RB>")
	
	local can_activate = notif.can_be_activated
	if can_activate then
		descr = descr .. T(7888, "<newline><ButtonA> Activate")
	end
	
	if notif:IsDismissable() then
		descr = descr .. T(7889, "<newline><ButtonX> Dismiss")
	end
	
	self.idTitle:SetText(T(7582, "Notifications"))
	self.idText:SetText(descr)
end

function OnScreenNotificationsDlg:Open(...)
	self:RecalculateMargins()
	XDialog.Open(self, ...)
end

local ForbidNotificationVoicesBeforeTime = 15*1000 --15 seconds

function OnScreenNotificationsDlg:AddNotification(id, preset, callback, params, cycle_objs, map_id)
	assert(preset)
	local notif = self:GetNotificationById(id, map_id)
	if notif then
		notif:FillData(id, preset, callback, params, cycle_objs)
	else
		local class = NotificationClasses[preset.priority]
		local new_item = g_Classes[class]:new({}, self.idNotifications)
		
		local total_colonists = #(UICity.labels.Colonist or empty_table)
		local voiced_text = preset.voiced_text or ""
		if voiced_text ~= "" and GameTime() > ForbidNotificationVoicesBeforeTime and (total_colonists <= 100 or (id ~= "BrokenCables" and id ~= "BrokenPipes")) then
			if g_Voice:IsPlaying() or IsValidThread(g_Voice.thread) then
				table.insert(OnScreenNotificationVoicesQueue, preset) --enqueue voice
			else
				OnScreenNotificationVoicesQueue = { } --begin new voice queue
				g_Voice:Play(voiced_text, not "actor", "Voiceover", not "subtitles", nil, nil, OnScreenNotificationsDlgPlayNextVoice)
			end
		end
		
		new_item:FillData(id, preset, callback, params, cycle_objs)
		new_item:Open()
		self:ResolveRelativeFocusOrder()
		self:UpdateGamepadHint()
	end
end

function OnScreenNotificationsDlg:AddCustomNotification(data, callback, params, cycle_objs)
	local notif = self:GetNotificationById(data.id)
	if notif then
		notif:FillData(data.id, data, callback, params, cycle_objs)
	else
		local class = NotificationClasses[data.priority]
		local new_item = g_Classes[class]:new({}, self.idNotifications)
		
		new_item:FillData(data.id, data, callback, params, cycle_objs)
		new_item:Open()
		self:ResolveRelativeFocusOrder()
		self:UpdateGamepadHint()
	end
end

function OnScreenNotificationsDlg:CancelAllNotifications()
	local notif_container = self.idNotifications
	for i = #notif_container, 1, -1 do
		notif_container[i].idButton:Press(true)
	end
	self:UpdateGamepadHint()
end

function OnScreenNotificationsDlg:RemoveNotification(id)
	local ctrl = self:GetNotificationById(id)
	if ctrl then
		local notif_container = self.idNotifications
		if ctrl:IsThreadRunning("show_thread") then return end
		ctrl:CreateThread("show_thread", function()
			local time = const.InterfaceAnimDuration
			if ctrl.window_state ~= "destroying" then
				ctrl:Show(false, time)
			end
			Sleep(time)
			if ctrl.window_state ~= "destroying" then
				local new_selection
				if self.gamepad_selection then
					local notif_count = #notif_container
					local pos = notif_count == self.gamepad_selection and (notif_count - 1) or Min(self.gamepad_selection + 1, notif_count)
					new_selection = notif_container[pos]
					if new_selection then
						new_selection:SetFocus(true)
					end
				end
				ctrl:Close()
				if #notif_container > 0 then
					self:ResolveRelativeFocusOrder()
					if new_selection then
						self.gamepad_selection = new_selection:GetFocusOrder():y()
					end
				else
					self:SetFocus(false, true)
					self.gamepad_selection = false
				end
				self:UpdateGamepadHint()
			end
		end)
	end
end

function OnScreenNotificationsDlg:PressNotification(id)
	local ctrl = self:GetNotificationById(id)
	if ctrl then
		ctrl.idButton:Press()
	end
end

function OnScreenNotificationsDlg:OnShortcut(shortcut, source)
	if shortcut == "ButtonB" or shortcut == "Escape" then
		self:SetFocus(false, true)
		return "break"
	elseif shortcut == "LeftShoulder" or shortcut == "+LeftShoulder" or shortcut == "RightShoulder" then
		shortcut = (shortcut == "LeftShoulder" or shortcut == "+LeftShoulder") and "DPadUp" or "DPadDown"
		XDialog.OnShortcut(self, shortcut, source)
		return "break"
	end
	XDialog.OnShortcut(self, shortcut, source)
	return source == "gamepad" and not shortcut:starts_with("+") and "break"
end

function OnScreenNotificationsDlg:GetRelativeFocus(order, relation)
	local focus = XDialog.GetRelativeFocus(self, order, relation)
	if not focus then
		local notif_container = self.idNotifications
		if relation == "down" then
			focus = notif_container[1]
		elseif relation == "up" then
			focus = notif_container[#notif_container]
		end
	end
	return focus
end

function OnScreenNotificationsDlg:OnSetFocus()
	LockHRXboxLeftThumb(self.class)

	local notif_container = self.idNotifications
	if #notif_container == 0 then
		return
	end
	
	self.gamepad_selection = #notif_container
	self.idNotifications[self.gamepad_selection]:SetFocus(true)
	self.idRolloverWindow:SetVisible(true)
	self:UpdateGamepadHint()
	XDialog.OnSetFocus(self)
end

function OnScreenNotificationsDlg:OnKillFocus()
	UnlockHRXboxLeftThumb(self.class)
	if self.window_state ~= "destroying" then
		local notif_container = self.idNotifications
		local selection = self.gamepad_selection
		if selection and #notif_container >= selection then
			notif_container[selection]:SetFocus(false)
		end
		self.gamepad_selection = false
		self.idRolloverWindow:SetVisible(false)
		self:UpdateGamepadHint()
		XDialog.OnKillFocus(self)
	end
end

function OnScreenNotificationsDlg:UpdateGamepadHint()
	if #self.idNotifications == 0 or not GetUIStyleGamepad() then
		self.idGamepadControls:SetVisible(false)
		return
	end
	
	self.idGamepadControls:SetVisible(true)
	local focus = self.desktop:GetKeyboardFocus()
	if IsKindOfClasses(focus, "SelectionModeDialog", "OverviewModeDialog", "InGameInterface") then
		self.idGamepadHint:SetVisible(true)
	else
		self.idGamepadHint:SetVisible(false)
	end
end

function OnScreenNotificationsDlg:GetNotificationById(id, map_id)
	map_id = map_id or ""
	local map_notif_id = id .. map_id
	local notif = table.find_value(self.idNotifications, "notification_id", map_notif_id)
	if not notif then
		notif = table.find_value(self.idNotifications, "notification_id", id)
	end

	if not notif then return end
	return notif.window_state ~= "destroying" and notif
end

function OnScreenNotificationsDlg:IsActive(id)
	return not not self:GetNotificationById(id)
end

function OnScreenNotificationsDlg:RecalculateMargins()
	--This is temporary and should be removed when implementing InGameInterface with new UI
	self:SetMargins(OnScreenNotificationsDlg.Margins + GetSafeMargins())
end

function GetOnScreenNotification(id, map_id)
	local dlg = GetDialog("OnScreenNotificationsDlg")
	if dlg then
		local notification = dlg:GetNotificationById(id, map_id)
		return notification
	end
	return false
end
