DefineClass.OnScreenNotification =
{
	__parents = {"XDrawCacheDialog"},
	FocusOnOpen = "",
	RolloverOnFocus = true,
	RolloverTemplate = "Rollover",
	RolloverAnchorId = "idButton",
	RelativeFocusOrder = "new-line",
	ScaleModifier = point(900,900),
	Margins = box(0,-8,0,-8),
	
	default_icon = "UI/Icons/Notifications/New/placeholder.tga",
	background_image = "UI/CommonNew/notication_blue.tga",
	title_style = "OnScreenTitle",
	text_style = "OnScreenText",
	button_shine = "UI/Icons/Notifications/New/select.tga",
	
	notification_id = false,
	dismissable = false,
	expiration = false,
	last_seen = false,
	game_time_expiration_thread = false,
	game_time_validation_thread = false,
	game_time_press_thread = false,
	preset = false,
	show_vignette = false,
	vignette_image = "UI/Onscreen/onscreen_gradient_red.tga",
	vignette_pulse_duration = 2000,
	vignette_thread = false,
	can_be_activated = false,
}

local notification_pack_id_index = 1
local notification_pack_map_id_index = 5

function OnScreenNotification:Open(...)
	XDialog.Open(self, ...)
	self:InitControls()
	self:CreateThread("show_thread", function()
		self:Show(true)
	end)
end

function OnScreenNotification:Init()
	local button = XBlinkingButton:new({
		Id = "idButton",
		ZOrder = 2,
		Shape = "InEllipse",
		HAlign = "left",
		VAlign = "center",
		LayoutMethod = "Box",
		Background = RGBA(0,0,0,0),
		FocusedBackground = RGBA(0,0,0,0),
		RolloverBackground = RGBA(0,0,0,0),
		PressedBackground = RGBA(0,0,0,0),
		MouseCursor = "UI/Cursors/Rollover.tga",
		FXMouseIn = "UIButtonMouseIn",
		FXPress = "UIButtonPressed",
		Icon = self.default_icon,
		AltPress = true,
		OnAltPress = function(ctrl, gamepad)
			if self:IsDismissable() then
				PlayFX("NotificationDismissed", "start")
				RemoveOnScreenNotification(self.notification_id)
			end
		end,
	}, self)
	XImage:new({
		Id = "idRollover",
		Visible = false,
		FadeInTime = 100,
		FadeOutTime = 100,
		Image = self.button_shine,
		HAlign = "left",
	}, self.idButton)
	self.idButton.idRollover:SetVisible(false, true)
	local background = XFrame:new({
		IdNode = false,
		Margins = box(42,8,0,8),
		Padding = box(42,0,0,0),
		MinWidth = 400,
		MaxWidth = 400,
		HAlign = "left",
		VAlign = "stretch",
		ChildrenHandleMouse = false,
		Image = self.background_image,
	}, self)
	local text_win = XWindow:new({
		HAlign = "stretch",
		VAlign = "center",
		LayoutMethod = "VList",
		LayoutVSpacing = -3,
	}, background)
	XText:new({
		Id = "idTitle",
		Translate = true,
		Shorten = true,
		Margins = box(0,-3,0,0),
		Padding = box(0,0,0,0),
		HandleMouse = false,
		TextStyle = self.title_style,
		MaxHeight = 35,
	}, text_win)
	XText:new({
		Id = "idText",
		Translate = true,
		Padding = box(0,0,0,0),
		MaxHeight = 45,
		HandleMouse = false,
		TextStyle = self.text_style,
	}, text_win)
end

function OnScreenNotification:InitControls()
end

function OnScreenNotification:Done()
	if IsValidThread(self.game_time_press_thread) then
		DeleteThread(self.game_time_press_thread)
	end
end

function OnScreenNotification:OnSetRollover(rollover)
	if self.window_state ~= "destroying" then
		XDialog.OnSetRollover(self, rollover)
		if self.idButton.rollover ~= rollover then
			self.idButton:SetRollover(rollover)
		end
	end
end

function OnScreenNotification:OnMouseEnter(pos)
	if UseGamepadUI() then return end
	local igi = GetInGameInterface()
	local dlg = igi and igi.mode_dialog
	if dlg and dlg:IsKindOf("UnitDirectionModeDialog") and dlg.unit then
		dlg:HideMouseCursorText(pos)
	end	
	return XDialog.OnMouseEnter(self, pos)
end

function OnScreenNotification:OnSetFocus()
	XDialog.OnSetFocus(self)
	local parent = GetDialog(self.parent)
	parent.gamepad_selection = self:GetFocusOrder():y()
	parent:UpdateRollover()
end

function OnScreenNotification:OnShortcut(shortcut, source)
	if shortcut == "ButtonA" then
		self.idButton:Press()
		GetDialog(self.parent):SetFocus(false, true)
		return "break"
	elseif shortcut == "ButtonX" then
		self.idButton:Press(true)
		return "break"
	end
	XDialog.OnShortcut(self, shortcut, source)
end

function OnScreenNotification:CycleObjs(cycle_objs)
	if cycle_objs then
		local idx = (self.last_seen or 0) + 1
		if idx > #cycle_objs then
			idx = 1
		end
		local obj = cycle_objs[idx]
		if IsPoint(obj) then
			ViewObjectMars(obj)
		elseif IsValid(obj) and obj:GetMapID() == ActiveMapID then
			if obj:GetEnumFlags(const.efVisible) ~= 0 then
				ViewAndSelectObject(obj)
			elseif obj:IsValidPos() then
				ViewObjectMars(obj:GetPos())
			end
		end
		self.last_seen = idx
		return obj
	end
end

function OnScreenNotification:SetTexts(preset, params)
	self.idTitle:SetText(T{preset.title, params})
	local text = params and params.override_text or preset.text
	text = T{text, params}
	if params.additional_text then
		text = text .. T{params.additional_text, params}
	end
	self.idText:SetText(T{text, params})
	
	if params.rollover_title then
		if params.context then
			self:SetContext(params.context)
		end
		self:SetRolloverTitle(params.rollover_title or "")
		self:SetRolloverText(T{params.rollover_text, params} or "")
		self:SetRolloverHint(params.rollover_hint or "")
		self:SetRolloverHintGamepad(params.rollover_hint_gamepad or "")
	end
end

function OnScreenNotification:AcceptNotification(id, preset, callback, params, cycle_objs)
	if self:IsThreadRunning("press_btn") then return end
	
	self:CreateThread("press_btn", function()
		local encyclopedia_id = preset.encyclopedia_id
		if encyclopedia_id and encyclopedia_id ~= "" then
			OpenEncyclopedia(encyclopedia_id)
		else
			local popup_preset = preset.popup_preset
			local popup_notification = params.popup_notification

			local res
			if (popup_preset or "") ~= "" or popup_notification then
				if type(params.GetPopupPreset)== "function" then 
					popup_preset = params.GetPopupPreset(params)
				end
				if not popup_notification and not params.params then
					params = {params = params}
				end
				if (popup_preset and PopupNotificationPresets[popup_preset]) or popup_notification then
					params.start_minimized = false
					res = WaitPopupNotification(popup_preset, params)
				end
			end
			local cur_obj = self:CycleObjs(cycle_objs)
			if callback then
				callback(cur_obj, params, res)
			end
			if preset.close_on_read then
				PlayFX("NotificationDismissed", "start")
				RemoveOnScreenNotification(id)
			end
		end
	end)
end

function OnScreenNotification:FillData(id, preset, callback, params, cycle_objs)
	assert(preset)
	self.preset = preset
	self.notification_id = params.override_id or id
	self.show_vignette = preset.ShowVignette
	self.vignette_image = preset.VignetteImage
	self.vignette_pulse_duration = preset.VignettePulseDuration
	if preset.image ~= "" then
		self.idButton.idIcon:SetImage(preset.image)
	end
	self:SetTexts(preset, params)
	
	local popup_preset = preset.popup_preset
	local popup_notification = params.popup_notification
	local encyclopedia_id = preset.encyclopedia_id
	local has_id = encyclopedia_id and encyclopedia_id ~= ""
	local can_cycle = cycle_objs and not not next(cycle_objs)
	local has_callback = not not callback
	self.can_be_activated = has_id or popup_preset ~= "" or can_cycle or has_callback or preset.close_on_read

	self.idButton.OnPress = function() self:AcceptNotification(id, preset, callback, params, cycle_objs) end
	if popup_notification then
		assert(not params.parent,
			"Notification " .. id .. " with parent should either have explicit 'start_minimized = false' in preset or have no parent")
		params.press_time = params.press_time or (GameTime() + 8 * const.HourDuration)

		local function delayed_press_button()
			Sleep(Max(params.press_time - GameTime(), 0)) --sleep for one Sol
			local idx = table.find(g_ActiveOnScreenNotifications, 1, id)
			if idx then
				local notification = GetOnScreenNotification(id)
				if notification then
					notification:AcceptNotification(id, preset, callback, params, cycle_objs)
				end
				RemoveOnScreenNotification(id)
			end
		end
		DeleteThread(self.game_time_press_thread)
		self.game_time_press_thread = CreateGameTimeThread(delayed_press_button)
	end

	local validate = preset.validate_context or params.validate_context
	if type(validate) == "function" then
		local function validate_params()
			assert(not params.parent)
			while(true) do
				Sleep(1000)
				if not validate(params) then
					RemoveOnScreenNotification(id)
					return
				end
			end
		end
		if preset.game_time then
			DeleteThread(self.game_time_validation_thread)
			self.game_time_validation_thread = CreateGameTimeThread(validate_params)
		else
			self:DeleteThread("validate")
			self:CreateThread("validate", validate_params)
		end
	end
		
	--Assign initial expiration time
	if not self.expiration then
		self.expiration = preset.expiration
	end
	-- Overwrite dismissable from params
	if params and params.dismissable then
		self.dismissable = params.dismissable
	end
	-- Overwrite expiration from params
	local current_expiration = self.expiration
	if params and params.expiration then
		current_expiration = params.expiration
	end
	--Close after the expiration time is over (self.expiration is subject to change)
	local expiration = preset.expiration ~= -1 and Min(current_expiration, preset.expiration) or current_expiration
	if expiration and expiration ~= -1 then
		local start_time = params.start_time or GameTime()
		local end_time = params.end_time or (start_time + expiration)
		params.end_time = end_time
		if preset.display_countdown then
			assert(preset.game_time, "'Display Countdown' must be used only on 'Game Time' notifications!")
			self:DeleteThread("countdown")
			self:CreateThread("countdown", function(self, preset, params, start_time, end_time)
				while true do
					for i = 1, 3 do
						local st, et = start_time, end_time
						local cd_param = "countdown"
						
						if i > 1 then 
							if params["start_time"..i] then
								st = params["start_time"..i]
							end
							if params["end_time"..i] then
								et = params["end_time"..i]
							elseif params["expiration"..i] then
								et = st + params["expiration"..i]
							end
							cd_param = "countdown"..i
						end
						
						params[cd_param] = GetFormattedExpirationString(GameTime(), et)
					end
					self:SetTexts(preset, params)
					Sleep(1000)
				end
			end, self, preset, params, start_time, end_time)
		end
		
		local function remove_notif()
			assert(not params.parent)
			Sleep(Max(end_time - GameTime(), 0))
			RemoveOnScreenNotification(id)
		end
		
		if preset.game_time then
			DeleteThread(self.game_time_expiration_thread)
			self.game_time_expiration_thread = CreateGameTimeThread(remove_notif)
		else
			self:DeleteThread("expire")
			self:CreateThread("expire", remove_notif)
		end
	end
end

function OnScreenNotification:Show(bShow, time)
	time = time or const.InterfaceAnimDuration
	EdgeAnimation(bShow, self, -(self.box:minx() + self.box:sizex()), 0, time)
	if bShow then
		if self.show_vignette then
			self:PulseVignette()
		end
		local sound_effect = self.preset and self.preset.SoundEffectOnShow
		if sound_effect and sound_effect ~= "" then
			PlayFX(sound_effect, "start")
		end
		PlayFX("NotificationIn", "start")
	else
		PlayFX("NotificationOut", "start")
	end
end

function OnScreenNotification:PulseVignette()
	DeleteThread(self.vignette_thread)
	self.vignette_thread = CreateRealTimeThread(function()
		local vignette = GetInGameInterface():GetVignette()
		if vignette then
			vignette:SetVisible(true)
			vignette:SetImage(self.vignette_image)
			vignette:Pulse(self.vignette_pulse_duration)
			Sleep(self.vignette_pulse_duration)
			vignette:SetVisible(false)
		end
	end)
end

function OnScreenNotification:IsDismissable()
	return self.dismissable or self.preset and self.preset.dismissable
end

DefineClass.OnScreenNotificationImportant =
{
	__parents = { "OnScreenNotification" },
	default_icon = "UI/Icons/Notifications/New/placeholder_2.tga",
	background_image = "UI/CommonNew/notication_red.tga",
	title_style = "OnScreenTitleImportant",

	button_shine = "UI/Icons/Notifications/New/select_red.tga",
}

DefineClass.OnScreenNotificationCritical =
{
	__parents = { "OnScreenNotificationImportant" },
	show_vignette = true,
	
	background_image = "UI/CommonNew/notication_red.tga",
	title_style = "OnScreenTitleCritical",
	text_style = "OnScreenTextCritical",
}

function OnScreenNotificationCritical:InitControls()
	self.idButton:SetBlinking(true)
end

DefineClass.OnScreenNotificationCriticalBlue = {
	__parents = { "OnScreenNotificationCritical" },
	default_icon = "UI/Icons/Notifications/New/placeholder.tga",
	background_image = "UI/CommonNew/notication_blue.tga",
	title_style = "OnScreenTitleCriticalBlue",
	text_style = "OnScreenTextCriticalBlue",
	
	button_shine = "UI/Icons/Notifications/New/select.tga",
}

DefineClass.OnScreenNotificationNormalDiscovery = {
	__parents = { "OnScreenNotification" },
	default_icon = "UI/Icons/Notifications/asteroid.tga",
	background_image = "UI/CommonNew/notication_blue.tga",
	title_style = "OnScreenTitleNormalTerraforming",
	text_style = "OnScreenTextNormalTerraforming",
	
	button_shine = "UI/Icons/Notifications/New/select_green.tga",
}

DefineClass.OnScreenNotificationCriticalDiscovery = {
	__parents = { "OnScreenNotification" },
	default_icon = "UI/Icons/Notifications/asteroid_2.tga",
	background_image = "UI/CommonNew/notication_red.tga",
	title_style = "OnScreenTitleNormalTerraforming",
	text_style = "OnScreenTextNormalTerraforming",
	
	button_shine = "UI/Icons/Notifications/New/select_green.tga",
}

DefineClass.OnScreenNotificationNormalTerraforming = {
	__parents = { "OnScreenNotification" },
	default_icon = "UI/Icons/Notifications/New/placeholder_3.tga",
	background_image = "UI/CommonNew/notication_green.tga",
	title_style = "OnScreenTitleNormalTerraforming",
	text_style = "OnScreenTextNormalTerraforming",
	
	button_shine = "UI/Icons/Notifications/New/select_green.tga",
}

DefineClass.OnScreenNotificationCriticalTerraforming = {
	__parents = { "OnScreenNotificationCritical" },
	default_icon = "UI/Icons/Notifications/New/placeholder_3.tga",
	background_image = "UI/CommonNew/notication_green.tga",
	title_style = "OnScreenTitleCriticalTerraforming",
	text_style = "OnScreenTextCriticalTerraforming",
	
	button_shine = "UI/Icons/Notifications/New/select_green.tga",
}

NotificationClasses = {
	Normal = "OnScreenNotification",
	Important = "OnScreenNotificationImportant",
	Critical = "OnScreenNotificationCritical",
	CriticalBlue = "OnScreenNotificationCriticalBlue",
	NormalTerraforming = "OnScreenNotificationNormalTerraforming",
	CriticalTerraforming = "OnScreenNotificationCriticalTerraforming",
	NormalDiscovery = "OnScreenNotificationNormalDiscovery",
	CriticalDiscovery = "OnScreenNotificationCriticalDiscovery",
}

OnScreenNotificationVoicesQueue = { }
function OnScreenNotificationsDlgPlayNextVoice()
	-- This fn. is called from within Voice:Play() (this is the callback).
	-- This creates a sort of loop that goes on until the voices queue is empty
	--     or the notif. voice is interrupted by someone else calling Voice:Play().
	-- Note: the queue is cleared before starting the loop.
	local notif_dlg = GetDialog("OnScreenNotificationsDlg")
	while next(OnScreenNotificationVoicesQueue) do
		local preset = OnScreenNotificationVoicesQueue[1]
		table.remove(OnScreenNotificationVoicesQueue, 1)
		--skip over voices for notifs. that have been dismissed
		if notif_dlg:IsActive(preset.id) then
			g_Voice:Play(preset.voiced_text, not "actor", "Voiceover", not "subtitles", nil, nil, OnScreenNotificationsDlgPlayNextVoice)
			break
		end
	end
end

function OnMsg.GamepadUIStyleChanged()
	local notifs = GetDialog("OnScreenNotificationsDlg")
	if notifs then notifs:UpdateGamepadHint() end
end

function RequestNewObjsNotif(container, data, map_id, allow_duplicates)
	assert(map_id ~= nil)
	assert(not container or type(container) == "table")
	container[map_id] = container[map_id] or {}
	if allow_duplicates then
		table.insert(container[map_id], data)
	else
		table.insert_unique(container[map_id], data)
	end
end
				
function DiscardNewObjsNotif(container, data, map_id)
	assert(map_id ~= nil)
	assert(not container or type(container) == "table")
	container[map_id] = container[map_id] or {}
	table.remove_entry(container[map_id], data)
end

function HandleNewObjsNotif(container, notif_id, bExpire, params_func, contains_objects, keep_destroyed, cycle_prevent)
	contains_objects = (contains_objects ~= false) and true or false
	local duration = 60000
	local displayed_in_notif = {}
	local expiration = {}
	while true do
		local change = {}
		if contains_objects then
			for map_id, objs in pairs(container) do
				for i = #objs, 1, -1 do
					local obj = objs[i]
					if not IsValid(obj) or IsKindOf(obj, "BaseBuilding") and obj.destroyed and not keep_destroyed then
						table.remove(objs, i)
					end
				end
			end
		end
		for map_id, objs in pairs(container) do
			displayed_in_notif[map_id] = displayed_in_notif[map_id] or {}
			if not table.is_isubset(objs, displayed_in_notif[map_id]) then
				expiration[map_id] = GameTime() + duration
				change[map_id] = true
			elseif #objs ~= #displayed_in_notif[map_id] then
				change[map_id] = true
			end
		end
		for map_id, changed in pairs(change) do
			if changed then
				displayed_in_notif[map_id] = table.copy(container[map_id])
				local params = params_func and type(params_func) == "function" and params_func(displayed_in_notif[map_id]) or {count = #displayed_in_notif[map_id]}
				if cycle_prevent then
					AddOnScreenNotification(notif_id, nil, params, nil, map_id)
				else
					AddOnScreenNotification(notif_id, nil, params, displayed_in_notif[map_id], map_id)
				end
			end
		end
		Sleep(1000)
		for map_id, changed in pairs(change) do
			if bExpire and (expiration[map_id] > 0 and expiration[map_id] < GameTime()) or not bExpire and #container[map_id] == 0 then
				RemoveOnScreenNotification(notif_id, map_id)
				for i = #container[map_id], 1, -1 do
					table.remove(container[map_id], i)
				end
				displayed_in_notif[map_id] = {}
				expiration[map_id] = 0
			end
		end
	end
end

function GetOnScreenNotificationPreset(id, params, map_id)
	map_id = map_id or ""
	local preset = false
	if params.popup_notification then
		local title = params.title or ""
		local text = params.text or ""
		local preset_name = params.preset or ""
		local title_id = IsT(title) and TGetID(title)
		local text_id = IsT(text) and TGetID(text)
		local notification_id = params.id or (preset_name ~= "" and preset_name) or 
			((title_id or text_id) and (tostring(title_id) .. tostring(text_id))) or 
			(text ~= "" and Encode16(SHA256(text))) or 
			(title ~= "" and Encode16(SHA256(title))) or ""
		id = "popup" .. notification_id .. map_id
		preset = OnScreenNotificationPreset:new{
			title = title,
			text = T(10918, "View Message"),
			dismissable = false,
			popup_preset = params.id,
			id = id,
			close_on_read = true,
			priority = params.minimized_notification_priority or "Critical",
			ShowVignette = true,
			VignetteImage = "UI/Onscreen/onscreen_gradient_red.tga",
			VignettePulseDuration = 2000,
		}
	else
		params.preset_id = params.preset_id or id
		preset = OnScreenNotificationPresets[params.preset_id]		
		id = (params.override_id or id) .. map_id
	end
	return id, preset
end

local function UpdateDisplayedNotifications(map_id)
	local function visible_notification_filter(k, v)
		local notification_map_id = v[notification_pack_map_id_index]
		return not notification_map_id or notification_map_id == map_id
	end

	local function hidden_notification_filter(k, v)
		return not visible_notification_filter(k,v)
	end

	local dlg = GetDialog("OnScreenNotificationsDlg")
	if not dlg then
		return
	end
	local notifications_hidden = table.ifilter(g_ActiveOnScreenNotifications, hidden_notification_filter)
	for _,notification in ipairs(notifications_hidden) do
		local id = notification[notification_pack_id_index]
		dlg:RemoveNotification(id)
	end
	
	local notifications_visible = table.ifilter(g_ActiveOnScreenNotifications, visible_notification_filter)
	for _,notification in ipairs(notifications_visible) do
		local id, callback, params, cycle_objs, map_id = unpack_params(notification)
		params = params or {}
		local preset
		_, preset = GetOnScreenNotificationPreset(id, params, map_id)
		if not preset then
			preset = notification.custom_preset
		end
		assert(preset, "Failed to find on screen notification preset for " .. id)
		if preset then
			dlg:AddNotification(id, preset, callback, params, cycle_objs, map_id)
		end
	end
end

OnMsg.SwitchMap = UpdateDisplayedNotifications

GlobalVar("g_ActiveOnScreenNotifications", {}) -- currently active onscreen notifications
GlobalVar("g_ShownOnScreenNotifications",{})-- show once notifications support
function AddOnScreenNotification(id, callback, params, cycle_objs, map_id)
	assert(not cycle_objs or type(cycle_objs) == "table")
	params = params or {}
	local preset
	id, preset = GetOnScreenNotificationPreset(id, params, map_id)
	if not preset then
		return
	end
	if preset.show_once and g_ShownOnScreenNotifications[id] then
		return
	end
	
	id = params.override_id or id
	
	-- edit the existing one instead of creating new one on each update, e.g. SA_CustomNotification
	local entry = pack_params(id, callback, params, cycle_objs, map_id)
	local idx = table.find(g_ActiveOnScreenNotifications, 1, id) or (#g_ActiveOnScreenNotifications + 1)
	g_ActiveOnScreenNotifications[idx] = entry
	
	if not map_id or map_id == ActiveMapID then
		local dlg = GetDialog("OnScreenNotificationsDlg")
		if not dlg then
			if not GetInGameInterface() then
				return
			end
			dlg = OpenDialog("OnScreenNotificationsDlg", GetInGameInterface())
		end
		dlg:AddNotification(id, preset, callback, params, cycle_objs, ActiveMapID)
		g_ShownOnScreenNotifications[id] = true
		if preset.fx_action ~= "" then
			PlayFX(preset.fx_action)
		end
	end
	
	UpdateDisplayedNotifications(ActiveMapID)
	
	return id
end

--[[@@@
Display a custom on-screen notification.
@function void AddCustomOnScreenNotification(string id, string title, string text, string image, function callback, table params)
@param string id - unique identifier of the notification.
@param string title - title of the notification.
@param string text - body text of the notification.
@param string image - path to the notification icon.
@param function callback - optional. Function called when the user clicks the notification.
@param table params - optional. additional parameters.
@param string map_id - map the notification belongs to. Use false for global notifications (default=MainMapID).
Additional parameters are supplied to the translatable texts, but can also be used to tweak the functionality of the notification:
- _'cycle_objs'_ will cause the camera to cycle through a list of _GameObjects_ or _points_ when the user clicks the notification.
- _'priority'_ changes the priority of the notification (choose between _"Normal"_, _"Important"_ and _"Critical"_; default=_"Normal"_).
- _'dismissable'_ dictates the dismissability of the notification (default=_true_)
- _'close_on_read'_ will cause the notification to disappear when the user clicks on it (default=_false_).
- _'expiration'_ is the amount of time (in _milliseconds_) that the notification will stay on the screen (default=_-1_).
- _'game_time'_ decides if the expiration countdown is done in _RealTime_ or _GameTime_ (default=_false_).
- _'display_countdown'_ must be _true_ if the _expiration_ countdown will be displayed in the notification texts (will be formatted and supplied to the translatable texts as _'countdown'_ parameter; this requires _'game_time'_ to be _true_).
]]
function AddCustomOnScreenNotification(id, title, text, image, callback, params, map_id)
	assert(not OnScreenNotificationPresets[id], string.format("Custom OnScreenNotification: Duplicates the id of preset.(id - %s).",tostring(id)))
	params = params or {}
	local cycle_objs = params.cycle_objs
	
	if map_id == nil then
		map_id = MainMapID
	elseif map_id == false then
		assert(not cycle_objs)
		map_id = ""
	end
	
	id = id .. map_id
	local entry = pack_params(id, callback, params, cycle_objs, map_id)

	--The difference between this function and the original 'AddOnScreenNotification()' is that here we create a mock preset:
	--Note: this function is useful for modding, but not all functionality is documented.
	local data = {
		id = id,
		name = id,
		title = title,
		text = text,
		image = image,
	}
	table.set_defaults(data, params)
	setmetatable(data, OnScreenNotificationPreset)
	entry.custom_preset = data
	-- edit the existing one instead of creating new one on each update
	local idx = table.find(g_ActiveOnScreenNotifications, 1, id) or #g_ActiveOnScreenNotifications + 1
	g_ActiveOnScreenNotifications[idx] = entry
	
	local dlg = GetDialog("OnScreenNotificationsDlg")
	if not dlg then
		if not GetInGameInterface() then
			return
		end
		dlg = OpenDialog("OnScreenNotificationsDlg", GetInGameInterface())
	end
	dlg:AddCustomNotification(data, callback, params, cycle_objs, map_id)
	g_ShownOnScreenNotifications[id] = true
	
	if type(params.fx_action) == "string" and params.fx_action ~= "" then
		PlayFX(params.fx_action)
	end
end

function LoadCustomOnScreenNotification(notification)
	local data = notification.custom_preset or empty_table
	local id, callback, params, cycle_objs, map_id = unpack_params(notification)

	id = id .. map_id
	notification[notification_pack_id_index] = id

	g_ActiveOnScreenNotifications[#g_ActiveOnScreenNotifications + 1] = notification
	
	local dlg = GetDialog("OnScreenNotificationsDlg")
	if not dlg then
		if not GetInGameInterface() then
			return
		end
		dlg = OpenDialog("OnScreenNotificationsDlg", GetInGameInterface())
	end
	dlg:AddCustomNotification(data, callback, params, cycle_objs, map_id)
	g_ShownOnScreenNotifications[id] = true
	
	if type(params.fx_action) == "string" and params.fx_action ~= "" then
		PlayFX(params.fx_action)
	end
end

function RemoveOnScreenNotification(id, map_id)
	local dlg = GetDialog("OnScreenNotificationsDlg")
	if dlg then
		map_id = map_id or ""
		id = id .. map_id
		dlg:RemoveNotification(id)
		
		local idx = table.find(g_ActiveOnScreenNotifications, 1, id)
		if idx then
			table.remove(g_ActiveOnScreenNotifications, idx)
		end
		
		UpdateDisplayedNotifications(ActiveMapID)
	end
end

function PressOnScreenNotification(id)
	-- Pre-Piazzi save compatibility. Stored in game threads for delayed press.
end

function IsOnScreenNotificationShown(id)
	local dlg = GetDialog("OnScreenNotificationsDlg")
	return dlg and dlg:IsActive(id)
end

local function FixupNotificationPack_TrimMapId(notification)
	local map_id = notification[notification_pack_map_id_index]
	if string.len(map_id) == 0 then
		return
	end
	local start_index = 1
	local id = notification[notification_pack_id_index]
	local map_id_pos = string.find_lower(id, map_id, start_index)
	if map_id_pos then
		notification[notification_pack_id_index] = string.trim(id, map_id_pos - 1)
	end
end

function ShowNotifications() -- called on load game
	local notifications = g_ActiveOnScreenNotifications
	g_ActiveOnScreenNotifications = {}
	for _, notification in ipairs(notifications) do
		if notification[notification_pack_map_id_index] then
			FixupNotificationPack_TrimMapId(notification)
		end
		if notification.custom_preset then
			LoadCustomOnScreenNotification(notification)
		else		
			AddOnScreenNotification(unpack_params(notification))
		end
	end
	UpdateDisplayedNotifications(ActiveMapID)
end

function GetOnScreenNotificationCountForMap(map_id)
	local map_notifications = table.ifilter(g_ActiveOnScreenNotifications, function(k, v) return v[5] == map_id end)
	return #map_notifications
end

function HasOnScreenNotficationsOnMap(map_id)
	return GetOnScreenNotificationCountForMap(map_id) > 0
end

function HasOnScreenNotficationsOnMapOfPriority(map_id, priority)
	local map_notifications = table.ifilter(g_ActiveOnScreenNotifications, function(k, v) return v[5] == map_id end)
	for _, notification in ipairs(map_notifications) do
		local id, callback, params, cycle_objs, map_id = unpack_params(notification)
		local _, preset = GetOnScreenNotificationPreset(id, params, map_id)
		if not preset then
			preset = notification.custom_preset
		end
		if preset and table.find(priority, preset.priority) then
			return true
		end
	end
	return false
end

OnMsg.InGameInterfaceCreated = ShowNotifications

function OnMsg.AchievementUnlocked(xplayer, achievement)
	if Platform.desktop and not Platform.steam then
		local data = AchievementPresets[achievement]
		local params = { achievement = data.display_name, description = data.description }
		AddOnScreenNotification("AchievementUnlocked", nil, params)
	end
end

function OnMsg.GatherFXActions(list)
	list[#list + 1] = "NotificationDismissed"
end

function GetOnScreenNotificationDismissable(id, map_id)
	local notification = GetOnScreenNotification(id, map_id)
	if notification then
		return notification.dismissable
	end
end

function GetFormattedExpirationString(start_time, end_time)
	if not end_time then
		return T{""}
	end
	
	local time = end_time - start_time
	local sols = time / const.DayDuration
	local hours = (time % const.DayDuration) / const.HourDuration
	if time > const.DayDuration then
		if hours > 0 then
			return sols > 1 and T{4108, "<sols> Sols <hours> h", sols = sols, hours = hours} or T{4109, "1 Sol <hours> h", hours = hours}
		else
			return sols > 1 and T{4110, "<sols> Sols", sols = sols} or T(4111, "1 Sol")
		end
	else
		return T{4112, "<hours> h", hours = hours}
	end
end

function OnMsg.SafeAreaMarginsChanged()
	local notifications_dlg = GetDialog("OnScreenNotificationsDlg")
	if notifications_dlg then
		notifications_dlg:RecalculateMargins()
	end
end

