if FirstLoad then
	g_EditorModeDlg = false
end

g_PlacementStateToColor = {
	Blocked     = RGB(220, 10, 20),
	Placeable   = const.clrNoModifier,
	Problematic = RGB(255, 60, 0),
	Obstructing = RGB(255, 216, 0),
}

ConstructionStatusColors = {
	error   	= { color_tag = Untranslated("<color 249 53 55>") , color_tag_short = Untranslated("<color 255 83 83><shadowcolor 104 23 1>") },
	problem 	= { color_tag = Untranslated("<color 249 53 55>") , color_tag_short = Untranslated("<color 255 83 83><shadowcolor 104 23 1>") },
	warning 	= { color_tag = Untranslated("<color 244 228 117>"), color_tag_short = Untranslated("<color 255 231 70><shadowcolor 124 61 2>") },
	info 		= { color_tag = Untranslated("<color 255 255 255>") },
}

ConstructionStatus = {
	OnTopOfResourceSign =             { type = "warning", priority = 99,  text = T(7571, "May block access to deposit."), short = T(7572, "Overlaps deposit") }, --on top of deposit sign
	ElectricityRequired =             { type = "warning", priority = 93,  text = T(842, "This building requires Power."), short = T(843, "No cable connection")}, --no grids nearby
	ElectricityGridNotEnoughPower =   { type = "warning", priority = 92,  text = T(844, "Not enough Power for this building."), short =  T(193, "Not enough Power") }, --there are grids nearby, but they do not produce enough.
	VaporatorInRange =                { type = "warning", priority = 99, text = T(847, "Producing <water(number)> less than optimal due to the presence of other Moisture Vaporators in the vicinity."), short =  T(848, "Vaporator nearby")},
	ColdSensitive =                   { type = "warning", priority = 96,  text = T(849, "The building will consume <red><percent(pct)></red> more Power in cold areas."), short = T(850, "Cold terrain")},
	NoNearbyDome =                    { type = "warning", priority = 98, text = T(7702, "No operational Domes in walking distance."), short =  T(7703, "Far from operational Domes")}, --no dome nearby
	UnexploredSector =                { type = "warning", priority = 97, text = T(852, "This sector is not yet scanned. The construction will possibly make resource deposits or Anomalies unreachable.") , short =  T(853, "Unexplored sector")},

	NoDroneHub =                      { type = "problem", priority = 100, text = T(845, "Too far from working Drone commander."), short = T(8016, "Too far from working Drone commander")}, --outside the range of any drone command center
	NoNearbyWorkers =                 { type = "problem", priority = 100, text = T(190, "This building requires Colonists and is too far from your Domes."), short = T(876, "Too far from Domes")}, --no workers nearby
	
	RequiresCable =                   { type = "error", priority = 90, text = T(854, "Must be constructed over a power cable."), short = T(855, "Must be built on a cable")},
	RequiresCompletedCable =          { type = "error", priority = 90, text = T(9833, "Must be constructed over a completed power cable."), short = T(9834, "Must be built on a completed cable")},
	RequiresPipe =                    { type = "error", priority = 90, text = T(856, "Must be constructed over a pipe."), short = T(857, "Must be built on a pipe")},
	RequiresCompletedPipe =           { type = "error", priority = 90, text = T(9835, "Must be constructed over a completed pipe."), short = T(9836, "Must be built on a completed pipe")},
	RequiresPassage =                 { type = "error", priority = 90, text = T(8770, "Must be constructed over a passage."), short = T(8771, "Must be built on a passage")},
	RequiresCompletedPassage =        { type = "error", priority = 90, text = T(9758, "Must be constructed over a completed passage."), short = T(9759, "Must be built on a completed passage")},
	DontBuildHere =                   { type = "error", priority = 92, text = T(858, "Can't build on dust geysers."), short = T(7953, "Blocking objects")},
	BlockingObjects =                 { type = "error", priority = 97, text = T(860, "Objects underneath are blocking construction."), short = T(7953, "Blocking objects")},
	NoPlaceForSpire =                 { type = "error", priority = 97, text = T(9619, "No Spire Slot."), short = T(9620, "No Spire Slot")},
	UnevenTerrain =                   { type = "error", priority = 96, text = T(861, "Uneven terrain."), short = T(7954, "Uneven terrain")},
	OutOfBounds =                     { type = "error", priority = 100, text = T(13606, "Construction area is outside of the boundaries of the Colony."), short = T(12397, "Out of bounds")},
	ResourceRequired =                { type = "error", priority = 95, text = T(862, "There is none of the required resource nearby."),short =  T(863, "Requires a deposit") }, --no resource nearby.
	ResourceTechnologyRequired =      { type = "error", priority = 95, text = T(864, "You lack the technology to exploit nearby resources."), short = T(865, "Unexploitable deposits")}, --no resource nearby.
	DomeRequired =                    { type = "error", priority = 94, text = T(866, "Must be placed under a functioning Dome."), short =  T(867, "Requires a Dome") },
	DomeCanNotInteract =              { type = "error", priority = 94, text = T(11235, "Construction in Rogue Domes is forbidden."), short =  T(11236, "Rogue Dome") },
	NonBuildableInterior =            { type = "error", priority = 94, text = T(868, "Unbuildable area."), short = T(7955, "Unbuildable area")},
	DomeProhibited =                  { type = "error", priority = 93, text = T(869, "Cannot be placed in a Dome."), short =  T(870, "Outside building")},
	DomeCeilingTooLow =               { type = "error", priority = 93, text = T(871, "Cannot be placed at this location due to height constraints."), short =  T(872, "Too tall")},
	ParentFarmRequired =              { type = "error", priority = 98, text = T(873, "Must be placed adjacent to the farm or its fields."), },
	LineTooLong =                     { type = "error", priority = 95, text = T(874, "Section is too long."), short  =  T(875, "Too long")}, --cable/pipe too long
	TooFarFromTunnelEntrance =        { type = "error", priority = 100, text = T(6773, "Too far from tunnel entrance."), short =  T(846, "Too far")},
	RocketLandingDustStorm =          { type = "error", priority = 90, text = T(8524, "Rockets can't land during dust storms."), short = T(8525, "Can't Land")},
	PassageRequiresTwoDomes =         { type = "error", priority = 90, text = T(8772, "Passage must start and end in a dome."), short = T(8773, "No dome")},
	PassageRequiresDifferentDomes =   { type = "error", priority = 90, text = T(8928, "Passage must start and end in different domes."), short = T(8929, "Same dome")},
	PassageTooCloseToEntrance =       { type = "error", priority = 90, text = T(8774, "Too close to dome entrance."), short = T(8775, "Dome entrance blocking")},
	PassageTooCloseToLifeSupport =    { type = "error", priority = 90, text = T(9760, "Too close to pipe link."), short = T(9761, "Pipe blocking")},
	PassageAngleToSteep =             { type = "error", priority = 91, text = T(8930, "Too sharp curve."), short = T(8931, "Sharp curve")},
	CantExtendFromTiltedPipes =       { type = "error", priority = 100, text = T(12159, "Can't extend from tilted pipes"), short = T(12159, "Can't extend from tilted pipes")},
	
	DepositInfo =                     { type = "info",  priority = 97, text = T(877, "Available resource<right><resource><newline><left>Grade<right><grade><left>") },
	
	BeautyDepositNearby =             { type = "warning", priority = 95, text = T(11586, "Vista - Comfort of residences will be boosted."), short = T(11458, "Vista") },
	MoraleDepositNearby =             { type = "warning", priority = 95, text = T(13607, "Vista - Morale of residences will be boosted."), short = T(11458, "Vista") },
	ResearchDepositNearby =           { type = "warning", priority = 95, text = T(11587, "Research Site - all Research will be boosted."), short = T(11461, "Research Site") },

	-- tutorial-related
	TooFarFromTarget =                { type = "error", priority = 90, text = T(8932, "Too far from target location."), short = T(846, "Too far")},
	WrongBuilding =                   { type = "error", priority = 90, text = T(8933, "Wrong building selected."), short = T(8934, "Wrong building")},
}


GlobalVar("ConstructableArea", false)

function OnMsg.SwitchMap(map_id)
	local sizex, sizey = GetActiveTerrain():GetMapSize()
	local border = const.ConstructBorder
	ConstructableArea = box(border, border, (sizex or 0) - border, (sizey or 0) - border)
end

function SortConstructionStatuses(statuses)
	table.sort(statuses, function(a, b) 
		local a_p = a.type == "error" and a.priority + 100 or a.priority
		local b_p = b.type == "error" and b.priority + 100 or b.priority
		if a_p == b_p then return _InternalTranslate(a.text) < _InternalTranslate(b.text) end
		return a_p > b_p
	end)
end

function IsPlacingMultipleConstructions()
	if terminal.IsKeyPressed(const.vkShift) then
		return true
	end
	if GetUIStyleGamepad() then
		local function CheckForGamepadState(state_idx)
			local state = XInput.CurrentState[state_idx]
			return type(state) == "table" and (state.LeftTrigger or 0) > 0
		end
		if Platform.desktop then
			for i = 0, XInput.MaxControllers() - 1 do
				if CheckForGamepadState(i) then
					return true
				end
			end
		else
			return CheckForGamepadState(XPlayerActive)
		end
	end
end

function TryCloseAfterPlace(self)
	local is_wonder = self.template and ClassTemplates.Building[self.template].wonder
	if is_wonder or not IsPlacingMultipleConstructions() then
		CloseModeDialog()
	end
end

function UpdateConstructionCursorObject(controller)
	while true do
		WaitNextFrame()
		local function UpdateForGamepadState(state_idx)
			local state = XInput.CurrentState[state_idx]
			if type(state) == "table" and state.LeftThumb then
				local x, y = state.LeftThumb:xy()
				if x ~= 0 or y ~= 0 then
					local pos = GetTerrainGamepadCursor()
					pos = HexGetNearestCenter(pos)
					controller:UpdateCursor(pos)
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

DefineClass.ConstructionModeDialog = {
	__parents = { "InterfaceModeDialog" },
	mode_name = "construction",
	template = false,
	params = false,
	selected_dome = false,
	instant_build = false,
	template_variants = false, 
	TryCloseAfterPlace = TryCloseAfterPlace,
}

function ConstructionModeDialog:Init()
	self:SetModal()
	self:SetFocus()
	
	self:OnStartup()
	
	if not Platform.durango then
		HideMouseCursor("InGameInterface")
	end
	HideGamepadCursor("construction")
	ShowResourceIcons("construction")
	UICity:SetCableCascadeDeletion(false, "ConstructionModeDialog")
	
	if self.selected_dome then
		UICity:SelectDome(self.selected_dome) --should be already opened, select it in UICity to prevent the build menu from closing it.
	end
	
	if GetUIStyleGamepad() then
		self:CreateThread("GamepadCursorUpdate", UpdateConstructionCursorObject, GetConstructionController(self.mode_name))
	end
end

function ConstructionModeDialog:OnStartup()
	for k,v in pairs(self.context) do
		self[k] = v
	end
	local construction = GetConstructionController(self.mode_name)
	construction.template_variants = self.template_variants or false
	construction:Activate(self.template, self.params)
	local dlg = GetHUD()
	if dlg then 
		local ctrl = dlg.idtxtConstructionStatus
		ctrl:SetMargins(box(0,0,0,0))
		ctrl:AddDynamicPosModifier({id = "construction", target = construction.cursor_obj})
	end
end

function OpenConstructionInfopanel(dlg)
	if dlg ~= GetInGameInterfaceModeDlg() then
		return
	end
	local obj = GetConstructionController(dlg.mode_name)
	if obj then
		OpenXInfopanel(dlg, obj, obj.construction_ip)
	end
end

function OpenGridConstructionInfopanel()
	local obj = GetGridConstructionController()
	local constr_dlg = GetInGameInterfaceModeDlg()
	if obj and constr_dlg and constr_dlg:IsKindOf("GridConstructionDialog") then
		OpenXInfopanel(constr_dlg, obj, "ipGridConstruction")
	end
end

function OpenGridSwitchConstructionInfopanel()
	local obj = GetGridSwitchConstructionController()
	local constr_dlg = GetInGameInterfaceModeDlg()
	if obj and constr_dlg and constr_dlg:IsKindOf("GridSwitchConstructionDialog") then
		OpenXInfopanel(constr_dlg, obj, "ipGridConstruction")
	end
end

function OpenTunnelConstructionInfopanel(template)
	local obj = GetTunnelConstructionController()
	local constr_dlg = GetInGameInterfaceModeDlg()
	if obj and constr_dlg and constr_dlg:IsKindOf("TunnelConstructionDialog") then
		obj:Initialize(template)		
		OpenXInfopanel(constr_dlg, obj, "ipConstruction")
	end
end

function _ShowNearbyHexGrid(pos)
	if pos then
		hr.NearestHexCenterX = pos:x()
		hr.NearestHexCenterY = pos:y()
		hr.NearestHexCenterZ = GetActiveTerrain():GetSurfaceHeight(pos)
	else
		hr.NearestHexCenterZ = 0
	end
end

function ShowNearbyHexGrid(pos)
	DelayedCall(0, _ShowNearbyHexGrid, pos)
end

function ConstructionModeDialog:Open(...)
	InterfaceModeDialog.Open(self, ...)
	if IsEditorActive() then 
		return 
	end
	DelayedCall(0, OpenConstructionInfopanel, self) -- SelectionChange message is delayed, so we need to delay this infopanel.
		-- the separate infopanel handling is caused by the fact that the cursor_obj is not SelectedObj for now.
		-- when it is done, all this should be removed and we should simply call SelectObj(cursor_obj)
end

function ConstructionModeDialog:Close(...)
	InterfaceModeDialog.Close(self, ...)
	ShowMouseCursor("InGameInterface")
	ShowGamepadCursor("construction")
	HideResourceIcons("construction")
	GetConstructionController(self.mode_name):Deactivate()
	g_EditorModeDlg = false
	UICity:SetCableCascadeDeletion(true, "ConstructionModeDialog")
	
	if self.selected_dome then
		UICity:SelectDome(false)
	end
	if ShowResourceOverview then
		UpdateInfobarVisibility("force")
	end
	
	if self:IsThreadRunning("GamepadCursorUpdate") then
		self:DeleteThread("GamepadCursorUpdate")
	end
	local dlg = GetHUD()
	if dlg then dlg.idtxtConstructionStatus:SetVisible(false) end
	
	self:HideDetailedHexRanges()
end

function ConstructionModeDialog:OnMouseButtonDown(pt, button)
	if button == "L" then
		if not GetConstructionController(self.mode_name):Place(nil, nil, nil, nil, self.instant_build, true) then
			PlayFX("ConstructionFail", "start")
		else
			self:TryCloseAfterPlace()
		end
		return "break"
	elseif button == "R" then
		if not IsEditorActive() then
			if self.params and self.params.cancel_callback then
				self.params.cancel_callback()
			end
			PlayFX("CancelConstruction", "start")
			CloseModeDialog()
		else
			if GetInGameInterfaceModeDlg() == self then
				CloseModeDialog()
			end
			if self.window_state ~= "destroying" then
				self:Close()
			end
		end
		return "break"
	elseif button == "M" then
		GetConstructionController(self.mode_name):Rotate(-1)
		return "break"
	end
end

function ConstructionModeDialog:OnMouseButtonDoubleClick(pt, button)
	if button == "M" then
		return self:OnMouseButtonDown(pt, button)
	end
end

function ConstructionModeDialog:OnMousePos(pt)
	local pos = GetTerrainCursor()
	GetConstructionController(self.mode_name):UpdateCursor(pos)
	return "break"
end

function ConstructionModeDialog:ShowDetailedHexRanges(cursor_obj)
	if cursor_obj.template.accumulate_maintenance_points then
		ShowHexRanges(UICity, "TriboelectricScrubber", nil, "GetSelectionRadiusScale")
	end
	
	if cursor_obj.template:IsKindOf("ColdSensitive") then
		ShowHexRanges(UICity, "BaseHeater", nil, "GetSelectionRadiusScale")
	end
	
	ShowHexRanges(UICity, "DroneControl", nil, "GetSelectionRadiusScale")
	ShowHexRanges(UICity, "DustGenerator", nil, "GetDustRadius")
	ShowHexRanges(UICity, "RocketBase", nil, "GetDustRadius")
end

function ConstructionModeDialog:HideDetailedHexRanges()
	HideHexRanges(UICity, "TriboelectricScrubber")
	HideHexRanges(UICity, "BaseHeater")
	HideHexRanges(UICity, "DroneControl")	
	HideHexRanges(UICity, "DustGenerator")	
end

function ConstructionModeDialog:OnKbdKeyDown(virtual_key, repeated)
	if virtual_key == const.vkEsc then
		self:OnMouseButtonDown(nil, "R")
		return "break"
	end
	local construction = GetConstructionController(self.mode_name)
	if virtual_key == const.vkOpensq then
		if not repeated then
			if construction.template_variants and next(construction.template_variants) then
				construction:ChangeTemplateVariant(1)
			else
				construction:ChangeAlternativeEntity(1)
			end
		end
		return "break"
	end
	if virtual_key == const.vkClosesq then
		if not repeated then
			if construction.template_variants and next(construction.template_variants) then
				construction:ChangeTemplateVariant(-1)
			else
				construction:ChangeAlternativeEntity(-1)
			end
		end
		return "break"
	end
	
	if virtual_key == const.vkControl and not repeated and construction.cursor_obj then
		self:ShowDetailedHexRanges(construction.cursor_obj)
		return "break"
	end
	
	return "continue"
end

function ConstructionModeDialog:OnKbdKeyUp(virtual_key, repeated)
	local controller = GetConstructionController(self.mode_name)
	local cursor_obj = controller and controller.cursor_obj or false
	if virtual_key == const.vkControl and cursor_obj then
		self:HideDetailedHexRanges()
		cursor_obj:InitHexRanges()
		return "break"
	end
	
	return "continue"
end

function ConstructionModeDialog:OnShortcut(shortcut, source)
	local construction = GetConstructionController(self.mode_name)
	if shortcut == "ButtonA" or shortcut == "LeftTrigger-ButtonA" then
		self:OnMouseButtonDown(nil, "L") --place
		return "break"
	elseif shortcut == "ButtonB" then
		self:OnMouseButtonDown(nil, "R") --cancel
		return "break"
	elseif shortcut == "DPadLeft" then
		if construction.template_variants and next(construction.template_variants) then
			construction:ChangeTemplateVariant(1)
		else
			construction:ChangeAlternativeEntity(1)
		end
		return "break"
	elseif shortcut == "DPadRight" then
		if construction.template_variants and next(construction.template_variants) then
			construction:ChangeTemplateVariant(-1)
		else
			construction:ChangeAlternativeEntity(-1)
		end
		return "break"
	elseif shortcut == "Back" or shortcut == "TouchPadClick" then
		if DismissCurrentOnScreenHint() then
			return "break"
		end
	end
	
	if shortcut == "+ButtonY" then
		self:ShowDetailedHexRanges(construction.cursor_obj)
		return "break"
	end
	
	if shortcut == "-ButtonY" then
		self:HideDetailedHexRanges()
		GetConstructionController(self.mode_name).cursor_obj:InitHexRanges()
		return "break"
	end
	
	return "continue"
end

function ConstructionModeDialog:OnMouseWheelForward(...)
	GetConstructionController(self.mode_name):UpdateShortConstructionStatus()
	return "continue"
end

function ConstructionModeDialog:OnMouseWheelBack(...)
	GetConstructionController(self.mode_name):UpdateShortConstructionStatus()
	return "continue"
end

DefineClass.CursorBuilding = {
	__parents = { "Shapeshifter", "AutoAttachObject", "NightLightObject" },
	flags = { cfNoHeightSurfs = true, efCollision = false, efApplyToGrids = false, efWalkable = false, efBakedTerrainDecal = false },

	auto_attach = false,
	GetSelectionRadiusScale = false,
	GetDustRadius = false,
	entity = false,
	
	override_palette = false,
	dome_skin = false,
	rocket = false,
}

function CursorBuilding:GetShapePoints()
	return GridObject.GetShapePoints(self)
end

CursorBuilding.GetBuildShape = CursorBuilding.GetShapePoints
CursorBuilding.GetFlattenShape = CursorBuilding.GetShapePoints

function CursorBuilding:IsNightLightPossible()
	return self:GetGameFlags(const.gofNightLightsEnabled) ~= 0
end

function CursorBuilding:AreNightLightsAllowed()
	return true
end

local clear_enum_flags = const.efWalkable + const.efApplyToGrids + const.efCollision + const.efBakedTerrainDecal
function CursorBuilding:Init()
	self.entity = self.entity or self.template:GetEntity()
	self:ChangeEntity(self.entity)
	if self.dome_skin then
		self.template.AttachConfigurableAttaches(self, self.dome_skin[2])
	else
		self.template.AttachConfigurableAttaches(self, self.template.configurable_attaches)
	end
	if not self.rocket and not IsKindOf(self.template, "RocketLandingSite") then
		AutoAttachObjectsToPlacementCursor(self)
	else
		
		local rocket_e
		if self.rocket then
			rocket_e = self.rocket:GetEntity()
		else
			rocket_e = GetConstructionRocketEntity(self.template.construction_rocket_class)
		end
		local idx = self:GetSpotBeginIndex("idle", "Rocket")
		if idx > -1 then
			PlaceAtSpot(self, idx, rocket_e, "placementcursor")
		end
	end
	self:ForEachAttach(AutoAttachObjectsToPlacementCursor)
	AttachDoors(self, self.entity)

	local cm1, cm2, cm3, cm4
	if self.override_palette then
		if self.entity == "RocketLandingSite" and self.rocket then
			cm1, cm2, cm3, cm4 = DecodePalette(self.override_palette, self.rocket:GetColorScheme())
		else
			cm1, cm2, cm3, cm4 = DecodePalette(self.override_palette)
		end
	end
	if self.dome_skin then
		if Presets.DomeSkins[self.dome_skin] and next(Presets.DomeSkins[self.dome_skin].palette) then
			cm1, cm2, cm3, cm4 = DecodePalette(Presets.DomeSkins[self.dome_skin].palette)
		end
	end
	if not cm1 then
		cm1, cm2, cm3, cm4 = GetBuildingColors(GetCurrentColonyColorScheme(), self.template)
	end
	
	Building.SetPalette(self, cm1, cm2, cm3, cm4)

	if self.template:IsKindOf("SpireBase") then
		local e = SpireBase.GetFrameEntity(self, self.template)
		if e ~= "none" and IsValidEntity(e) then
			local frame = PlaceObjectIn("SpireFrame", self:GetMapID())
			frame:ChangeEntity(e)
			frame:SetAttachOffset( point(-1, 0, 4392) ) --Dome basic default frame offset
			self:Attach(frame, self:GetSpotBeginIndex("Origin"))
		end
	end
	
	-- attach tiles
	local shape = GetEntityOutlineShape(self.entity)
	for i = 1, #shape do
		local q, r = shape[i]:xy()
		local x, y = HexToWorld(q, r)
		local offset = point(x, y, 30)
		local tile = PlaceObjectIn("GridTile", self:GetMapID(), nil, const.cofComponentAttach)
		self:Attach(tile)
		tile:SetAttachOffset(offset)
	end
	
	if IsKindOf(self.template, "LifeSupportGridObject") then
		SetObjWaterMarkers(self, true)
	end
	
	--switch decal type
	if self.template.show_decals_on_placement then
		local att = self:GetAttaches()
		for i = 1, #att do
			if att[i]:GetEnumFlags(const.efBakedTerrainDecal) ~= 0 then
				att[i]:SetEnumFlags(const.efVisible)
			end
		end
	end
	self:ClearHierarchyEnumFlags(clear_enum_flags)
	if self.template.lights_on_during_placement then
		self:SetIsNightLightPossible(true, true)
	else
		self:ClearHierarchyGameFlags(const.gofNightLightsEnabled)
	end
end

function CursorBuilding:InitHexRanges()
	if self.template.show_range_all or g_BCHexRangeEnable[self.template.class] then
		ShowHexRanges(UICity, self.template.class)
	end
	if self.template.show_range_class ~= "" then
		ShowHexRanges(UICity, self.template.show_range_class)
	end
end

function CursorBuilding:GameInit()
	--setup animated indicators
	local class = self.template
	if IsKindOf(class, "StorageWithIndicators") then
		StorageWithIndicators.ResetIndicatorAnimations(self, class.indicator_class)
	end
	if IsKindOf(class, "VegetationPlant") then
		ShowSoilTransparentOverlay()
	end
	
	self:InitHexRanges()
	
	if class.construction_state ~= "idle" then
		self:SetState(class.construction_state)
		local a = self:GetAttaches()
		for i = 1, #(a or "") do
			if a[i].entity and a[i]:HasState(class.construction_state) then
				a[i]:SetState(class.construction_state)
			end
		end
	end
end

function CursorBuilding:Done()
	if self.template.show_range_all or g_BCHexRangeEnable[self.template.class] then
		HideHexRanges(UICity, self.template.class)
	end
	if self.template.show_range_class ~= "" then
		HideHexRanges(UICity, self.template.show_range_class)
	end
	if IsKindOf(self.template, "VegetationPlant") and show_overlay == "soil_transparent" then
		HideOverlay()
	end
	for _, hex in ipairs(g_HexRanges[self] or empty_table) do
		DoneObject(hex)
		g_HexRanges[self] = nil
	end
end

function CursorBuilding:UpdateShapeHexes()
	local x0, y0, z0 = self:GetVisualPosXYZ()
	local game_map = GetGameMap(self)
	local buildable = game_map.buildable
	self:ForEachAttach("GridTile", function(tile, z0)
		local dx, dy = tile:GetAttachOffset():xy()
		local x, y = tile:GetVisualPosXYZ()
		local zmin = GetMaxHeightInHex(game_map, x, y) + 30
		tile:SetAttachOffset(dx, dy, Max(0, zmin - z0))
		tile:SetVisible(buildable:IsBuildableZone(x, y))
	end, z0)
end

function ChangeAlternativeEntity(cursor_bld, dir, controller)
	local t_n = cursor_bld.template.template_name
	
	if not t_n or t_n == "" then
		return
	end
	
	local current = cursor_bld:GetEntity()
	local skins, palettes = GetBuildingSkins(t_n)
	local class_name = cursor_bld.template.class
	local class = ClassTemplates.Building[class_name] or g_Classes[class_name]
	local is_open_air = GetOpenAirBuildings(cursor_bld:GetMapID())
	if class and is_open_air then
		local open_entity, closed_entity = class:CalcOpenAirEntity(current)
		current = closed_entity or current
	end
	local is_dome = IsKindOf(class, "Dome")
	local idx = table.find(skins, is_dome and 1 or current, is_dome and current or nil)
	local count = #skins
	if not idx or count <= 1 then
		return
	end
	idx = idx + dir
	if idx>count then idx = 1 end	
	if idx<1     then idx = count end	
	local new_ent = skins[idx]
	if class and is_open_air then
		new_ent = class:CalcOpenAirSkin(new_ent) or new_ent
	end
	local palette = palettes[idx]
	if controller then
		controller.dome_skin = is_dome and new_ent or false
	end
	new_ent = new_ent and is_dome and new_ent[1] or new_ent or current
	return new_ent, palette
end

function CursorBuilding:SetColorModifier(clr)
	AutoAttachObject.SetColorModifier(self,clr)
	local attaches = self:GetAttaches()
	if attaches then
		for i = 1, #attaches do
			local curr_attach = attaches[i]
			if not IsKindOf(curr_attach, "ParSystem") then
				curr_attach:SetColorModifier(clr)
			end
		end
	end
end

DefineClass.CursorSupply = {
	__parents = { "Shapeshifter", "AutoAttachObject" },
	flags = { efCollision = false, efApplyToGrids = false, efWalkable = false, },
}

function CursorSupply:Init()
	AutoAttachObjectsToPlacementCursor(self)
	self:ForEachAttach(AutoAttachObjectsToPlacementCursor)
	local class = g_Classes[self.template]
	local entity = class.entity
	self:ChangeEntity(entity)
	--switch decal type
	if self.template.show_decals_on_placement then
		local att = self:GetAttaches()
		for i = 1, #att do
			if att[i]:GetEnumFlags(const.efBakedTerrainDecal) ~= 0 then
				att[i]:SetEnumFlags(const.efVisible)
			end
		end
	end
	self:ClearHierarchyEnumFlags(clear_enum_flags)
end

function CursorSupply:SetColorModifier(clr)
	AutoAttachObject.SetColorModifier(self,clr)
	local attaches = self:GetAttaches()
	if attaches then
		for i = 1, #attaches do
			local curr_attach = attaches[i]
			curr_attach:SetColorModifier(clr)
		end
	end
end

DefineClass.ConstructionController = {
	__parents = { "InitDone" },
	cursor_obj = false,
	template_obj = false, --the building definition table
	template_obj_points = false,
	template = false,
	is_tempate = false,
	construction_obstructors = false, --keeps a list of all objects that are currenty obstructing, so we can tint them.
	dome_with_obstructed_roads = false,
	
	construction_statuses = false,
	
	properties = {
		{id = "construction_statuses_property", editor = "text", name = T{""}, translate = true},
	},
	
	construction_statuses_property = false,
	ignore_domes = false,
	selected_domes = false,
	snap_to_grid = true,
	amount = false,
	resource = false,
	supplied = false,
	prefab = false,
	placing_resource = false,
	template_variants = false,
	markers = false,
	ui_callback = false, -- function to call when the construction is placed; only works for placing through the UI
	is_template = false,
	
	dome_required = false,
	dome_forbidden = false,
	
	stockpiles_obstruct = false,
	
	rocks_underneath = false,
	
	dome_skin = false,
	rocket = false,
	snap_target = false,
	is_constructable_rocket = false,
	
	construction_ip = "ipConstruction",
	city = false,
}

function ConstructionController:Init()
	self.construction_statuses = {}
	self.rocks_underneath = {}
end

function ConstructionController:GetMapID()
	local city = self.city or UICity
	return city.map_id
end

function ConstructionController:CreateCursorObj(alternative_entity_t, template_obj, override_palette, map_id)
	local o
	if template_obj or self.is_template then
		template_obj = template_obj or self.template_obj
		local cursor_building_data = {
			template = template_obj, 
			entity = alternative_entity_t and alternative_entity_t.entity 
						or IsKindOf(template_obj, "Dome") and self.dome_skin and self.dome_skin[1] 
						or GetOpenAirBuildings(map_id) and template_obj:CalcOpenAirEntity() or template_obj:GetEntity(), 
			auto_attach_at_init = false,
			override_palette = alternative_entity_t and alternative_entity_t.palette or override_palette,
			dome_skin = self.dome_skin,
			rocket = self.rocket,
		}
		o = CursorBuilding:new(cursor_building_data, map_id)
		if template_obj and template_obj.starting_angle ~= 0 then
			o:SetAngle(template_obj.starting_angle)
		end
	else
		local cursor_supply_data = {template = self.template, auto_attach_at_init = false}
		o = CursorSupply:new(cursor_supply_data, map_id)
	end

	if o then
		local dlg = GetHUD()
		if dlg then 
			local ctrl = dlg.idtxtConstructionStatus
			ctrl:SetMargins(box(0,0,0,0))
			ctrl:AddDynamicPosModifier({id = "construction", target = o})
		end
		
		if self.template_obj then
			local ometa = getmetatable(o)

			setmetatable(o, {__index = self.template_obj})
			local success, points = procall(o.GetBuildShape, o)
			setmetatable(o, ometa)
			
			self.template_obj_points = success and points or {}
			assert(success)
		else
			--from sa place
			self.template_obj_points = o:GetBuildShape()
		end
	end
	
	return o
end

function ConstructionController:GetBuildGridRadius()
	local _, radius = self.cursor_obj:GetBSphere()
	return Max(radius * 3, 13000)
end

function FixConstructPos(terrain, pt)
	local z = pt:z() or 0
	local terrain_z = terrain:GetHeight(pt)
	return terrain_z ~= z and pt:SetZ(terrain_z) or pt
end

function GetConstructionTerrainPos(source)
	source = source or (GetUIStyleGamepad() and "gamepad" or "mouse")
	local pos = (source == "gamepad") and GetTerrainGamepadCursor() or GetTerrainCursor()
	return HexGetNearestCenter(pos)
end

function ConstructionController:EnableBuildGrid(show)
	if show then
		table.change(hr, "Construction", { RenderBuildGrid = self.snap_to_grid and 1 or 0, BuildGridRadius = self:GetBuildGridRadius() })
	else
		table.restore(hr, "Construction")
	end
end

function ConstructionController:Activate(template, params, alternative_entity_t)
	params = params or empty_table
	self.rocket = params.rocket
	self.amount, self.supplied, self.prefab, self.resource, self.ui_callback = params.amount, params.supplied, params.prefab, params.resource, params.ui_callback
	self.snap_to_grid = params.snap_to_grid
	self.placing_resource = params.placing_resource
	self.dome_required = params.dome_required
	self.dome_forbidden = params.dome_forbidden
	self.stockpiles_obstruct = params.stockpiles_obstruct
	self.snap_target = false
	self.is_constructable_rocket = false
	self.dome_skin = false
	self.selected_domes = {}
	SelectObj() --so "SelectionChanged" messages are correctly dispatched.

	local template_obj = ClassTemplates.Building[template]
	self.is_template = not not template_obj
	if not template_obj then
		template_obj = g_Classes[template]
	end
	
	self.template = template
	self.template_obj = template_obj
	self.template_obj_points = template_obj:GetBuildShape()
	local template_palette = false
	
	if IsKindOf(template_obj, "Dome") then
		local def_skin = GetMissionSponsor().default_skin
		local is_open_air = GetOpenAirBuildings(ActiveMapID)
		if def_skin and def_skin ~= "" then
			local skins = GetDomeSkins({entity = template_obj:GetEntity()}, template_obj)
			local skin = table.find_value(skins, "skin_category", def_skin)
			if skin then
				self.dome_skin = is_open_air and template_obj:CalcOpenAirSkin(skin) or skin
			end
		end
		if not self.dome_skin and is_open_air then
			local skin = template_obj:GetCurrentSkin()
			self.dome_skin = template_obj:CalcOpenAirSkin(skin)
		end
	elseif IsKindOf(template_obj, "BaseRoverBuilding") then
		local class = g_Classes[self.template_obj.rover_class]
		template_palette = class and class.palette
	end
	
	if params.stockpiles_obstruct == nil and IsKindOf(self.template_obj, "RocketLandingSite") then
		--constructable rocket
		self.stockpiles_obstruct = true
		self.is_constructable_rocket = true
		local rocket_class = self.template_obj.construction_rocket_class
		template_palette = GetConstructableRocketPalette(rocket_class)
	end

	self.cursor_obj = self:CreateCursorObj(alternative_entity_t, nil, template_palette or params.override_palette)
	
	if HintsEnabled then
		local is_dome = IsKindOf(self.cursor_obj.template, "Dome")
		if is_dome and not g_ActiveHints["HintDomePlacedTooEarly"] then
			local has_one_air_producer
			local a_grids = self.city.air
			for i = 1, #a_grids do
				if #a_grids[i].producers > 0 then
					has_one_air_producer = true
					break
				end
			end
			local has_one_water_producer
			local w_grids = self.city.water
			for i = 1, #w_grids do
				if #w_grids[i].producers > 0 then
					has_one_water_producer = true
					break
				end
			end
			if not has_one_air_producer or not has_one_water_producer then
				HintTrigger("HintDomePlacedTooEarly")
			end
		end
	end
	
	if params and IsKindOf(self.template_obj, "RocketLandingSite") then
		self.cursor_obj.GetSelectionRadiusScale = params.drones and const.CommandCenterDefaultRadius or 0
		self.cursor_obj.GetDustRadius = params.rocket and params.rocket:GetDustRadius() or 0
	else
		self.cursor_obj.GetSelectionRadiusScale = self.template_obj:HasMember("GetSelectionRadiusScale") and self.template_obj:GetSelectionRadiusScale()
		self.cursor_obj.GetDustRadius = self.template_obj:HasMember("GetDustRadius") and self.template_obj:GetDustRadius()
	end	
	
	PlayFX("ConstructionCursor", "start", self.cursor_obj, self.template_obj.class)
	if self.cursor_obj.GetSelectionRadiusScale then
		ShowHexRanges(self.city, false, self.cursor_obj, "GetSelectionRadiusScale")
	end
	if self.cursor_obj.GetDustRadius then
		ShowHexRanges(self.city, false, self.cursor_obj, "GetDustRadius")
	end
	
	-- NOTE: during construction it also means that the workplace should be in range of a dome(or its construction)
	if IsKindOf(self.template_obj, "Workplace") and self.template_obj.dome_forbidden then
		ShowHexRanges(self.city, "Workforce")
	end
	
	local terrain = GetActiveTerrain()
	local terrain_pos = GetUIStyleGamepad() and GetTerrainGamepadCursor() or GetTerrainCursor()
	local pos = self.is_template and HexGetNearestCenter(terrain_pos) or terrain_pos
	pos = terrain:ClampPoint(pos)
	
	self.cursor_obj:SetPos(FixConstructPos(terrain, pos))
	self:UpdateCursor(pos,"force")
	
	self:EnableBuildGrid(true)
	self:PickCursorObjColor()
	
	if template_obj:IsKindOf("SubsurfaceDepositConstructionRevealer") then
		template_obj:Reveal()
	end
end

GetOpenCityConstructionController = empty_func

function RefreshConstructionCursor()
	local construction = GetConstructionController()
	if construction and IsValid(construction.cursor_obj) then
		DelayedCall(0, construction.UpdateCursor, construction, construction.cursor_obj:GetPos(), "force")
	end
end

function OnMsg.CameraTransitionStart(eye, lookat, transition_time)
	if GetUIStyleGamepad() then
		if InGameInterfaceMode == "construction" then
			local construction = GetDefaultConstructionController(UICity)
			if construction and IsValid(construction.cursor_obj) then
				local terrain = GetActiveTerrain()
				local pos = FixConstructPos(terrain, lookat)
				construction.cursor_obj:SetPos(pos)
				construction:UpdateCursor(pos, "force")
			end
		end
	end
end

function ConstructionController:Deactivate()
	self:EnableBuildGrid(false)
	if self.cursor_obj then 
		PlayFX("ConstructionCursor", "end", self.cursor_obj, self.template_obj.class)
		self.cursor_obj:delete()
	end	
	
	if self.template_obj then
		if IsKindOf(self.template_obj, "SubsurfaceDepositConstructionRevealer") then
			self.template_obj:Hide()
		end
		-- NOTE: during construction it also means that the workplace shoud be in range of a dome(or its construction)
		if IsKindOf(self.template_obj, "Workplace") and self.template_obj.dome_forbidden then
			HideHexRanges(UICity, "Dome")
		end
	end
	
	self.cursor_obj = false
	self.template_obj = false
	self:ColorRocks()
	self:ClearColorFromAllConstructionObstructors()
	self.construction_obstructors = false
	
	--clear markers from dome with obstructed roads
	if self.dome_with_obstructed_roads then
		SetShapeMarkers(self.dome_with_obstructed_roads, false)
	end
	
	for i = 1, #self.selected_domes do
		self.selected_domes[i]:Close()
	end
	
	local markers = self.markers or ""
	for i = 1, #markers do
		if IsValid(markers[i]) then --building could be demolished while constructing and its attaches should already be dead.
			DoneObject(markers[i])
		end
	end
	
	self.markers = false
	ShowNearbyHexGrid(false)
end

function ConstructionController:ChangeCursorObj(dir)
	local pos = self.cursor_obj:GetPos()
	local angle = self.cursor_obj:GetAngle()
	local new_entity, new_palette = ChangeAlternativeEntity(self.cursor_obj, dir, self)
	if self.cursor_obj then 
		PlayFX("ConstructionCursor", "end", self.cursor_obj, self.template_obj.class)
		self.cursor_obj:delete()
	end
	self:ColorRocks()
	self:ClearColorFromAllConstructionObstructors()
	self.construction_obstructors = false
	self.cursor_obj = self:CreateCursorObj({entity = new_entity, palette = new_palette})
	
	self.cursor_obj.GetSelectionRadiusScale = self.template_obj:HasMember("GetSelectionRadiusScale") and self.template_obj:GetSelectionRadiusScale()
	self.cursor_obj.GetDustRadius = self.template_obj:HasMember("GetDustRadius") and self.template_obj:GetDustRadius()
	PlayFX("ConstructionCursor", "start", self.cursor_obj, self.template_obj.class)
	if self.cursor_obj.GetSelectionRadiusScale then
		ShowHexRanges(UICity, false, self.cursor_obj, "GetSelectionRadiusScale")
	end
	if self.cursor_obj.GetDustRadius then
		ShowHexRanges(UICity, false, self.cursor_obj, "GetDustRadius")
	end
	
	self.cursor_obj:SetAngle(angle)
	self.cursor_obj:SetPos(pos)
	self:PickCursorObjColor()
	self:UpdateCursor(pos,"force")
end

if FirstLoad then
	OrigColorMod = false
	ControllerMarkers = false
end

function OnMsg.NewMap()
	ControllerMarkers = {}
	OrigColorMod = {}
end

function OnMsg.LoadGame()
	assert(next(ControllerMarkers or empty_table) == nil) --leaked construction markers
	ControllerMarkers = {}
	OrigColorMod = {}
end

function GetMaxHeightInHex(game_map, x, y)
	local hex_radius = const.HexSize
	local terrain = game_map.terrain
	local h0 = terrain:GetHeight(x, y)
	local h1 = terrain:GetHeight(x - hex_radius, y)
	local h2 = terrain:GetHeight(x + hex_radius, y)
	local h3 = terrain:GetHeight(x, y - hex_radius)
	local h4 = terrain:GetHeight(x, y + hex_radius)
	return Max(h0, h1, h2, h3, h4)
end

function SetShapeMarkers(obj, set, color, shape_name)
	local markers = ControllerMarkers[obj]
	if not set then
		for i = 1, #(markers or "") do
			DoneObject(markers[i])
		end
		ControllerMarkers[obj] = nil
	else
		if not IsValid(obj) or not obj:IsValidPos() then return end
		if markers then 
			return
		end
		shape_name = shape_name or "Outline"
		local shape
		local method_name = string.format("Get%sShape", shape_name)
		if obj:HasMember(method_name) then
			shape = obj[method_name](obj)
		else
			local shape_getter = _G[string.format("GetEntity%sShape", shape_name)]
			if type(shape_getter) ~= "function" then
				assert(false, "No such function: " .. shape_getter)
				return
			end
			shape = shape_getter(obj:GetEntity())
		end
		local x0, y0, z0, angle0
		if IsKindOf(obj, "Building") and obj.orig_state then
			x0, y0, z0 = obj.orig_state[1]:xyz()
			angle0 = obj.orig_state[2]
		else
			x0, y0, z0 = obj:GetVisualPosXYZ()
			angle0 = obj:GetAngle()
		end
		markers = {}
		color = color or const.clrNoModifier
		local hex_angle = HexAngleToDirection(angle0)
		local hex_radius = const.HexSize
		local game_map = GetGameMap(obj)
		for i = 1, #shape do
			local q, r = shape[i]:xy()
			local x, y = HexToWorld(HexRotate(q, r, hex_angle))
			x = x + x0
			y = y + y0
			-- other tiles are height+30, but these are height+31 to avoid Z fighting
			local z = Max(z0, GetMaxHeightInHex(game_map, x, y)) + 31
			local tile = PlaceObjectIn("GridTile", game_map.map_id)
			tile:SetPos(x, y, z)
			tile:SetColorModifier(color)
			markers[#markers + 1] = tile
		end
		ControllerMarkers[obj] = markers
	end
end

local function ApplyColorMod(obj, color)
	OrigColorMod[obj] = OrigColorMod[obj] or obj:GetColorModifier()
	obj:SetColorModifier(color)
end
local function RestoreColorMod(obj)
	local color = OrigColorMod[obj]
	if color then
		obj:SetColorModifier(color)
		OrigColorMod[obj] = nil
	end
end

function ConstructionController:ClearColorFromAllConstructionObstructors()
	for i = 1, #(self.construction_obstructors or "") do
		local obstr = self.construction_obstructors[i]
		if IsValid(obstr) then
			RestoreColorMod(obstr)
		end
		SetShapeMarkers(obstr, false)
	end
end

function ConstructionController:ClearColorFromMissingConstructionObstructors(old, new)
	for i = 1, #(old or "") do
		if not table.find(new, old[i]) then
			if IsValid(old[i]) then
				RestoreColorMod(old[i])
			end
			SetShapeMarkers(old[i], false)
		end
	end
end

function ShouldConstructionObstructorShowShapeMarker(obstructor)
	return not IsKindOf(obstructor, "SurfaceDeposit")
end

function ConstructionController:SetColorToAllConstructionObstructors(color)
	if IsEditorActive() then return end
	local ignore_domes = self.ignore_domes
	local domes = {}
	for i = 1, #(self.construction_obstructors or "") do
		local obstr = self.construction_obstructors[i]
		if IsValid(obstr) then
			ApplyColorMod(obstr, color)
			if ShouldConstructionObstructorShowShapeMarker(obstr) then
				SetShapeMarkers(obstr, true, color)
			end
			if not ignore_domes and IsKindOf(obstr, "Dome") then
				table.insert(domes, obstr)
			end
		else
			assert(false, "Building is unexpectedly deleted.")
		end
	end
	if not ignore_domes and IsValid(self.cursor_obj) then
		local object_hex_grid = GetObjectHexGrid(self)
		local inside_dome = GetDomeAtPoint(object_hex_grid, self.cursor_obj)
		if inside_dome then table.insert(domes, inside_dome) end
		
		self:CloseSelectedDomes(domes)
	end
end

function ConstructionController:CloseSelectedDomes(domes)
	local selected_domes = self.selected_domes or empty_table
	for i = 1, #selected_domes do
		if UICity.selected_dome ~= selected_domes[i] and not table.find(domes, selected_domes[i]) then
			selected_domes[i]:Close()
		end
	end
	
	for i = 1, #domes do
		if not table.find(selected_domes, domes[i]) then
			domes[i]:Open()
		end
	end
	
	self.selected_domes = domes
end

function ConstructionController:IsObstructed()
	return self.construction_obstructors and #self.construction_obstructors > 0
end

local ObstructorsQuery = {
	classes = {"Building"},
	area = false,
	arearadius = false,
}

--marks ObjectGrid GridObjects that shouldn't block construction.
DefineClass.DoesNotObstructConstruction = {
	__parents = { "CObject" },
	flags = { gofTemporalConstructionBlock = true },
}

ConstructionController.AllUngridedBlockers = { }
local ungrided_stockpile_blockers = false --these should block and be able to receive resources when placing resouces
local ungrided_all_other_blockers = false --these should just block
function OnMsg.ClassesBuilt()
	ungrided_stockpile_blockers = ClassDescendantsList("UngridedObstacle", function(cls) 
																										local class_def = g_Classes[cls]
																										return IsKindOf(class_def, "ResourceStockpileBase") and not IsKindOf(class_def, "DoesNotObstructConstruction") end)
																										
	ungrided_all_other_blockers = ClassDescendantsList("UngridedObstacle", function(cls) 
																										local class_def = g_Classes[cls]
																										return not IsKindOfClasses(class_def, "ResourceStockpileBase", "DoesNotObstructConstruction") end)
																										
	table.iappend(ConstructionController.AllUngridedBlockers, ungrided_stockpile_blockers)
	table.iappend(ConstructionController.AllUngridedBlockers, ungrided_all_other_blockers)
end

function ConstructionController:AlignToObject(cursor_obj, obj)
	cursor_obj:SetPos(obj:GetPos())
	cursor_obj:SetAngle(obj:GetAngle())
end

function ConstructionController:GetSnapTarget(target_class)
	for _, obj in ipairs(self.construction_obstructors) do
		if obj:IsKindOf(target_class) then
			return obj
		end
	end
	return nil
end

function ConstructionController:SnapToTarget(cursor_obj, target, old_obstructors, pipe_filter, non_obstructors)
	self:AlignToObject(cursor_obj, target)
	self:ClearColorFromAllConstructionObstructors()
	self:ClearColorFromMissingConstructionObstructors(old_obstructors, empty_table)

	local object_hex_grid = GameMaps[self.city:GetMapID()].object_hex_grid.grid
	local obstructors = HexGridShapeGetObjectList(object_hex_grid, cursor_obj, self.template_obj_points, nil, non_obstructors, pipe_filter)
	self.construction_obstructors = table.ifilter(obstructors, function(obj) return IsKindOf(obj, target.class) end)
end

function ConstructionController:GetObstructors(position, angle, template_object, shape)
	local non_obstructors = "DoesNotObstructConstruction"
	if IsKindOf(template_object, "ResourceStockpile") then
		non_obstructors = nil
	elseif IsKindOf(template_object, "RocketLandingSite") then
		non_obstructors = "WasteRockObstructor"
	end
	
	local pipe_filter = function(o)
		if IsKindOf(o, "LifeSupportGridElement") then
			--its a pipe
			if self.is_template and self.template_obj.is_tall then return true end --any pipe blocks tall
			return o.pillar --pipes with pillars block short
		end
		
		return true
	end
	
	local object_hex_grid = GameMaps[self.city:GetMapID()].object_hex_grid.grid
	return HexGridShapeGetObjectList(object_hex_grid, position, angle, shape, nil, non_obstructors, pipe_filter)
end

function ConstructionController:GetAllObstructors(position, angle, template_object)
	local entity = template_object:GetEntity()
	local outline = GetEntityHexShapes(entity)
	local obstructors = self:GetObstructors(position, angle, template_object, outline)
	
	local blocking_classes = {
		"ResourceStockpile",
		"SurfaceDeposit",
		"WasteRockObstructor",
	}
	table.iappend(blocking_classes, ungrided_all_other_blockers)
	
	local realm = GetRealm(self)
	table.iappend(obstructors, HexGetUnits(realm, nil, entity, position, angle, nil, nil, blocking_classes))
	return obstructors
end

function ConstructionController:UpdateConstructionObstructors()
	local old_obstructors = self.construction_obstructors
	local non_obstructors = "DoesNotObstructConstruction"
	if IsKindOf(self.template_obj, "ResourceStockpile") then
		non_obstructors = nil
	elseif IsKindOf(self.template_obj, "RocketLandingSite") then
		non_obstructors = "WasteRockObstructor"
	end
	
	local am_i_tall = self.is_template and self.template_obj.is_tall
	local pipe_filter = function(o)
		if IsKindOf(o, "LifeSupportGridElement") then
			--its a pipe
			if am_i_tall then return true end --any pipe blocks tall
			return o.pillar --pipes with pillars block short
		end
		
		return true
	end
	--buildings
	local game_map = GetGameMap(self.city)
	local object_hex_grid = game_map.object_hex_grid.grid
	local realm = game_map.realm

	self.construction_obstructors = HexGridShapeGetObjectList(object_hex_grid, self.cursor_obj, self.template_obj_points, nil, non_obstructors, pipe_filter)
	self.snap_target = nil
	if self.construction_obstructors and #self.construction_obstructors > 0 then
		if self.template_obj.snap_target_type then
			local snap_target = self:GetSnapTarget(self.template_obj.snap_target_type)
			if snap_target and snap_target:CanSnapTo() then
				self:SnapToTarget(self.cursor_obj, snap_target, old_obstructors, pipe_filter)
				self.snap_target = snap_target
			end
		end
	end
	
	local force_extend_bb = self.template_obj:HasMember("force_extend_bb_during_placement_checks") and self.template_obj.force_extend_bb_during_placement_checks ~= 0 and self.template_obj.force_extend_bb_during_placement_checks or false
	--stockpiles
	local stockpiles = HexGetUnits(realm, self.cursor_obj, self.template_obj:GetEntity(), nil, nil, nil, function(obj) return obj:GetParent() == nil end, ungrided_stockpile_blockers, force_extend_bb, self.template_obj_points) --not test so we can color them
	if not self.placing_resource or #(stockpiles or "") > 1 or --not a stockpile or too many stockpiles already
		(stockpiles[1] and (stockpiles[1].resource ~= self.resource or --stockpile of different type
		Min(self.amount, const.ResourceUnitsInPile) > stockpiles[1]:GetMax() - stockpiles[1]:GetStoredAmount() / const.ResourceScale)) then --we cannot add any more resource.
		table.iappend(self.construction_obstructors, stockpiles)
	end
	if self.stockpiles_obstruct then
		--rocket.
		stockpiles = HexGetUnits(realm, self.cursor_obj, self.template_obj:GetEntity(), nil, nil, nil, function(obj) return obj:GetParent() == nil end, "ResourceStockpile", force_extend_bb, self.template_obj_points) --not attached regular stockpiles.
		table.iappend(self.construction_obstructors, stockpiles)
	end
	--surface deposits
	table.iappend(self.construction_obstructors, 
					HexGetUnits(realm, self.cursor_obj, self.template_obj:GetEntity(), nil, nil, nil, nil, "SurfaceDeposit", force_extend_bb, self.template_obj_points))
		
	if self.placing_resource then
		table.iappend(self.construction_obstructors, HexGetUnits(realm, self.cursor_obj, self.template_obj:GetEntity(), nil, nil, nil, nil, "WasteRockObstructor", force_extend_bb, self.template_obj_points))
	end
	--everything else
	--empty table catches everything
	if #ungrided_all_other_blockers > 0 then
		table.iappend(self.construction_obstructors, HexGetUnits(realm, self.cursor_obj, self.template_obj:GetEntity(), nil, nil, nil, nil, ungrided_all_other_blockers, force_extend_bb, self.template_obj_points))
	end
	
	self:ClearColorFromMissingConstructionObstructors(old_obstructors, self.construction_obstructors)
	
	--check if inside a dome and roads are obstructed
	if (not self.template_obj or self.template_obj.dome_spot == "none") then
		local dome = IsObjInDome(self.cursor_obj)
		local dome_is_obstructor = table.find(self.construction_obstructors, dome)
		if not dome_is_obstructor then
			if dome then
				--building has a dome
				local dome_hexes = dome:GetBuildableAreaShape()
				if dome_hexes and next(dome_hexes) then
					--only domes with build hexes can have their roads obstructed
					local obj_hexes = GetEntityOutlineShape(self.cursor_obj.entity)
					local offset = point(WorldToHex(self.cursor_obj:GetPos() - dome:GetPos()))
					local obj_rotation = HexAngleToDirection(self.cursor_obj:GetAngle())
					local dome_rotation = HexAngleToDirection(dome:GetAngle())
					if not CheckHexSurfaces(obj_hexes, dome_hexes, "subset", offset, obj_rotation, (dome_rotation-1)%6) then
						if not self.dome_with_obstructed_roads then
							--building just started obstructing the roads of its dome
							self.dome_with_obstructed_roads = dome
							SetShapeMarkers(self.dome_with_obstructed_roads, true, g_PlacementStateToColor.Obstructing, "InverseBuild")
						end
					elseif self.dome_with_obstructed_roads then
						--building stops obstructing the roads of its dome
						SetShapeMarkers(self.dome_with_obstructed_roads, false)
						self.dome_with_obstructed_roads = false
					end
				end
			elseif --[[not dome and]] self.dome_with_obstructed_roads then
				--building no longer has a dome, but previously obstructed the roads of one
				SetShapeMarkers(self.dome_with_obstructed_roads, false)
				self.dome_with_obstructed_roads = false
			end
		elseif self.dome_with_obstructed_roads then
			--dome had its roads obstructed, but now its walls now obstruct the building, which takes priority
			SetShapeMarkers(self.dome_with_obstructed_roads, false)
			self.dome_with_obstructed_roads = false
		end
	end
	
	--and now for something completely different.
	local new_rocks = HexGetUnits(realm, self.cursor_obj, self.template_obj:GetEntity(), nil, nil, nil, nil, "WasteRockObstructor", force_extend_bb, self.template_obj_points)
	self:ColorRocks(new_rocks)
	
	SetObjWaterMarkers(self.cursor_obj, "update")
	
	if self.cursor_obj:HasMember("UpdateShapeHexes") then
		self.cursor_obj:UpdateShapeHexes()
	end
end

function ConstructionController:ClearDomeWithObstructedRoads()
	if self.dome_with_obstructed_roads then
		--building stops obstructing the roads of its dome
		SetShapeMarkers(self.dome_with_obstructed_roads, false)
		self.dome_with_obstructed_roads = false
	end
end

function ConstructionController:ColorRocks(new_rocks)
	new_rocks = new_rocks or {}
	local old_rocks = self.rocks_underneath
	
	for i = 1, #(old_rocks or "") do
		local rock = old_rocks[i]
		if IsValid(rock) and not table.find(new_rocks, rock) then
			rock:ClearGameFlags(const.gofWhiteColored)
		end
	end
	
	for i = 1, #new_rocks do
		local rock = new_rocks[i]
		rock:SetGameFlags(const.gofWhiteColored)
	end
	
	self.rocks_underneath = new_rocks
end

local UnbuildableZ = buildUnbuildableZ()

function ConstructionController:UpdateCursor(pos, force)
	if IsValid(self.cursor_obj) then
		self.spireless_dome = false
		local hex_world_pos = HexGetNearestCenter(pos)
		local game_map = ActiveGameMap
		local build_z = game_map.buildable:GetZ(WorldToHex(hex_world_pos)) or UnbuildableZ
		local terrain = game_map.terrain
		if build_z == UnbuildableZ then
			build_z = pos:z() or terrain:GetHeight(pos)
		end
		hex_world_pos = hex_world_pos:SetZ(build_z)
		
		local placed_on_spot = false
		if self.is_template and not self.template_obj.dome_forbidden and self.template_obj.dome_spot ~= "none" then --dome not prohibited			
			local object_hex_grid = game_map.object_hex_grid
			local dome = GetDomeAtPoint(object_hex_grid, hex_world_pos)
			if dome and IsValid(dome) and IsKindOf(dome, "Dome") then
				if dome:HasSpot(self.template_obj.dome_spot) then
					local idx = dome:GetNearestSpot(self.template_obj.dome_spot, hex_world_pos)
					hex_world_pos = HexGetNearestCenter(dome:GetSpotPos(idx))
					placed_on_spot = true
					if self.template_obj.dome_spot == "Spire" then
						if self.template_obj:IsKindOf("SpireBase") then
							local frame = self.cursor_obj:GetAttach("SpireFrame")
							if frame then
								local spot = dome:GetNearestSpot("idle", "Spireframe", self.cursor_obj)
								local pos = dome:GetSpotPos(spot)
								frame:SetAttachOffset(pos - hex_world_pos)
							end
						end
					end
				elseif self.template_obj.dome_spot == "Spire" then
					self.spireless_dome = true
				end
			end
		end
		local new_pos = self.snap_to_grid and hex_world_pos or pos
		if not placed_on_spot then
			new_pos = FixConstructPos(terrain, new_pos)
		end

		if force or (FixConstructPos(terrain, self.cursor_obj:GetPos()) ~= new_pos and hex_world_pos:InBox2D(ConstructableArea)) then
			ShowNearbyHexGrid(hex_world_pos)
			self.cursor_obj:SetPos(new_pos)
			self:UpdateConstructionObstructors()
			self:UpdateConstructionStatuses() --should go after obstructors
			self:UpdateShortConstructionStatus()
			ObjModified(self)
		end
	end
end

function ConstructionController:IsTerrainFlatForPlacement(shape_data, pos, angle)
	if self:HasMember("template_obj") and self.template_obj and self.template_obj:IsKindOf("RegolithExtractor") then
		-- if placing a regolith mine, check for abandoned locations first
		local pos = self.cursor_obj:GetPos()
		local angle = self.cursor_obj:GetAngle()
		for i = 1, #OldMineLocations do
			if pos:Equal2D(OldMineLocations[i].pos) and angle == OldMineLocations[i].angle then
				return true
			end
		end
	end
	
	shape_data = shape_data or self.template_obj_points
	pos = pos or self.cursor_obj:GetVisualPos()
	angle = angle or self.cursor_obj:GetAngle()
	local buildable_grid = GetBuildableGrid(self.city)
	return IsTerrainFlatForPlacement(buildable_grid, shape_data, pos, angle)
end

g_NCF_FlatInner = HexGetSize()
g_NCF_FlatOuter = 3 * HexGetSize()

function FlattenTerrainInBuildShape(shape_data, obj, flatten_unbuildable) --shape_data == nil => { 0, 0 } shape
	--[[
	-- !!! implement in C, even better - aggregate calls from higher level (cables/pipes call this many times hex by hex)
	local dir = HexAngleToDirection(obj:GetAngle())
	local q, r = WorldToHex(obj:GetPos())
	for _, shape_pt in ipairs(shape_data or {point(0, 0)}) do
		local x, y = HexRotate(shape_pt:x(), shape_pt:y(), dir)
		local z = buildable:GetZ(q+x, r+y)
		if z ~= UnbuildableZ then
			terrain:SetHeightCircle(point(HexToWorld(q+x, r+y)), g_NCF_FlatInner, g_NCF_FlatOuter, z)
		end
	end
	]]
	local unbuildable = flatten_unbuildable and -1 or UnbuildableZ
	shape_data = shape_data or empty_table
	local map_to_flatten = GameMaps[obj:GetMapID()]
	local bbox = FlattenTerrainInShape(shape_data, obj, map_to_flatten.buildable.z_grid, map_to_flatten.object_hex_grid.grid, g_NCF_FlatInner, g_NCF_FlatOuter, unbuildable)
	-- if bbox then
	-- DbgAddTerrainRect(bbox)
	-- end
	return bbox
end

local HexNeighbours = {
	point(1, 0),
	point(0, 1),
	point(-1, 1),
	point(-1, 0),
	point(0, -1),
	point(1, -1),
}

function ConstructionController:DontBuildHere()
	local dont_build_here = g_DontBuildHere[self.cursor_obj:GetMapID()]
	return dont_build_here and dont_build_here:Check(self.cursor_obj:GetPos())
end

function ConstructionController.BlockingUnitsFilter(obj)
	return (IsKindOfClasses(obj, "Drone") and obj:IsDisabled()) or IsKindOf(obj, "BaseRover")
end
--
function ConstructionController:HasDepositUnderneath()
	local realm = GetRealm(self)
	local force_extend_bb = self.template_obj:HasMember("force_extend_bb_during_placement_checks") and self.template_obj.force_extend_bb_during_placement_checks ~= 0 and self.template_obj.force_extend_bb_during_placement_checks or false
	local excluded_resource = IsKindOf(self.template_obj, "DepositExploiter") and self.template_obj.exploitation_resource or false
	return HexGetUnits(realm, self.cursor_obj, self.template_obj:GetEntity(), nil, nil, true, function(o) return not IsKindOfClasses(o, "SubsurfaceAnomaly", "EffectDeposit") and excluded_resource ~= o.resource end, "Deposit", force_extend_bb, self.template_obj_points)
end

ConstructionController.BlockingUnitClasses = {"Unit"}

--combine this with the above test for perf?
function ConstructionController:AreThereBlockingUnitsUnderneath()
	local realm = GetRealm(self)
	if self.resource then return false end
	local force_extend_bb = self.template_obj:HasMember("force_extend_bb_during_placement_checks") and self.template_obj.force_extend_bb_during_placement_checks ~= 0 and self.template_obj.force_extend_bb_during_placement_checks or false
	return HexGetUnits(realm, self.cursor_obj, self.template_obj:GetEntity(),
							self.cursor_obj:GetVisualPos(), self.cursor_obj:GetAngle(),
							true, ConstructionController.BlockingUnitsFilter, ConstructionController.BlockingUnitClasses, force_extend_bb, self.template_obj_points)
end

local function ConstructionEffects_ForEachFn(deposit, building, effects_set)
	if deposit.ConstructionStatusName and deposit:CanAffectBuilding(building) then
		local list = effects_set[deposit.class] or { }
		effects_set[deposit.class] = list
		table.insert(list, deposit)
	end
end

function ConstructionController:UpdateConstructionStatuses(dont_finalize)
	local old_t = self.construction_statuses
	self.construction_statuses = {}
	
	local ctarget = g_Tutorial and g_Tutorial.ConstructionTarget
	if ctarget then
		if ctarget.class and self.template ~= ctarget.class then
			self.construction_statuses[1] = ConstructionStatus.WrongBuilding
			return
		end
		if ctarget.loc then
			local dist = ctarget.radius or 3
			if ctarget.strict then
				local spot = ctarget.spot and self.cursor_obj:GetSpotBeginIndex(ctarget.spot) or -1
				local pt = self.cursor_obj:GetSpotLoc(spot)
				if HexAxialDistance(ctarget.loc, pt) > ctarget.radius then
					self.construction_statuses[1] = ConstructionStatus.TooFarFromTarget
					return
				end
			else
				if not IsBuildingInRange(self.cursor_obj, ctarget.loc, dist) then
					self.construction_statuses[1] = ConstructionStatus.TooFarFromTarget
					return
				end
			end
		end
		if ctarget.hex then
			local spot = ctarget.spot and self.cursor_obj:GetSpotBeginIndex(ctarget.spot) or -1
			local pt = self.cursor_obj:GetSpotLoc(spot)
			if HexAxialDistance(ctarget.hex, pt) > 0 then
				self.construction_statuses[1] = ConstructionStatus.TooFarFromTarget
				return
			end
		end
	end
	
	if self:DontBuildHere() then
		self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.DontBuildHere
	end
	
	if self:IsObstructed() or self:AreThereBlockingUnitsUnderneath() then
		self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.BlockingObjects
	end
	
	if  self.template_obj.dome_spot == "Spire" and self.spireless_dome then
		self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.NoPlaceForSpire
	end

	if not IsInMapPlayableArea(self.city.map_id, self.cursor_obj:GetPos()) then
		self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.OutOfBounds
		ShowNearbyHexGrid(false)
	else
		local interior = GetEntityInteriorShape(self.template_obj:GetEntity())
		local ignore_terrain = self.template_obj:IsKindOf("OrbitalProbe") or self.template_obj.only_build_on_snapped_locations
		if not ignore_terrain and (not self:IsTerrainFlatForPlacement() or (next(interior) and not self:IsTerrainFlatForPlacement(interior))) then
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.UnevenTerrain
			-- ShowNearbyHexGrid(false)
		end
	end

	if self:HasDepositUnderneath() then
		self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.OnTopOfResourceSign
	end
	
	--check if the building is poking through the dome cupola
	local dome = IsObjInDome(self.cursor_obj)
	if dome and dome.cupola_attach and not GetOpenAirBuildings(self.city.map_id) then
		local sticks_outside_cupola
		local esCollision = EntitySurfaces.Collision
		local start_id, end_id = self.cursor_obj:GetAllSpots(self.cursor_obj:GetState())
		for i = start_id, end_id do
			--each building should have a bunch of "Heightlimit" spots on its roof
			local spot_name = self.cursor_obj:GetSpotName(i)
			if spot_name == "Heightlimit" then
				local height_limit_pos = self.cursor_obj:GetSpotPos(i)
				local high_point = height_limit_pos:AddZ(10000*guim) --should be high engouh for any case
				for _, obj in ipairs(dome.cupola_attach) do
					--if rays straight up from these spots don't intersect the dome's glass
					--that means the spot is outside the dome, poking through it, which shouldn't happen
					if IsValid(obj) and not IntersectRayWithObject(height_limit_pos, high_point, obj, esCollision) then
						self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.DomeCeilingTooLow
						sticks_outside_cupola = true
						break
					end
				end
			end
			
			if sticks_outside_cupola then break end
		end
	end
	
	local realm = GetRealm(self)
	local filter = function(center, obj)
		return (IsKindOf(center, "DroneHub") or center.working) and HexAxialDistance(center, obj) <= center.work_radius
	end

	if not self.template_obj:IsKindOf("RocketLandingSite") then
		local drone_connection = false
		drone_connection = drone_connection or dome and #dome.command_centers > 0
		drone_connection = drone_connection or realm:MapCount(self.cursor_obj, "hex", const.CommandCenterMaxRadius, "DroneNode", filter, self.cursor_obj) > 0
		drone_connection = drone_connection or #(self.city.labels.AncientArtifactInterface or "") > 0

		if not drone_connection then
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.NoDroneHub
		end
	end
	
	if self.template_obj:IsKindOf("MoistureVaporator") then
		if realm:MapCount(self.cursor_obj, "hex", const.MoistureVaporatorRange, "MoistureVaporator"  ) > 0 then
			local status = table.copy(ConstructionStatus.VaporatorInRange)
			status.text = T{status.text, {number = MulDivRound(self.template_obj.water_production, const.MoistureVaporatorPenaltyPercent, 100)}}
			self.construction_statuses[#self.construction_statuses + 1] = status
		end
	end
	
	if self.template_obj:IsKindOf("RocketLandingSite") then
		if HasDustStorm(self:GetMapID()) and (not self.rocket or self.rocket.affected_by_dust_storm) and not self.template_obj:IsKindOf("RocketBuildingBase") then
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.RocketLandingDustStorm
		end
		local constr_dlg = GetInGameInterfaceModeDlg()
		if constr_dlg and constr_dlg.class == "ConstructionModeDialog" and constr_dlg.params and constr_dlg.params.passengers then	
			local domes = GetDomesInWalkableDistance(self.city, self.cursor_obj:GetPos())
			if #domes == 0 then
				self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.NoNearbyDome
			end
		end
	end
	
	local sector = IsExplorationAvailable_Queue(self.city) and GetMapSector(self.city, self.cursor_obj) or nil
	if sector and sector.status == "unexplored" then
		self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.UnexploredSector
	end
	
	local dome_required = self.is_template and self.template_obj.dome_required or self.dome_required
	local dome_forbidden = self.is_template and self.template_obj.dome_forbidden or self.dome_forbidden
	
	if self.dome_with_obstructed_roads and not dome_forbidden and (not self.template_obj or self.template_obj.dome_spot == "none") then
		self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.NonBuildableInterior
	end
	if dome and not dome:GetUIInteractionState() then
		self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.DomeCanNotInteract
	end
	if dome_required or dome_forbidden then
		if dome_required and not dome then --dome.
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.DomeRequired
		elseif dome_forbidden and dome then
			self.construction_statuses[#self.construction_statuses + 1] = ConstructionStatus.DomeProhibited
		end
	end
	
	--find nearby effect deposits
	local effects_set = { }
	realm:MapForEach(self.cursor_obj, "hex", GetBuildingAffectRange(self.template_obj), "EffectDeposit", ConstructionEffects_ForEachFn, self.template_obj, effects_set)
	for classname, all_deposits in pairs(effects_set) do
		local classdef = g_Classes[classname]
		local status = ConstructionStatus[classdef.ConstructionStatusName]
		local text_override = classdef.GetConstructionStatusText(self.template_obj, all_deposits)
		if text_override then
			status = table.copy(status)
			status.text = text_override
		end
		self.construction_statuses[#self.construction_statuses + 1] = status
	end
	
	-- Snapping errors
	if self.template_obj.only_build_on_snapped_locations then
		if not self.snap_target or not IsKindOf(self.snap_target, self.template_obj.snap_target_type) then
			table.insert(self.construction_statuses, self.template_obj:GetSnapError())
		end
	end
		
	if self.is_template then
		-- make the template object look like a valid object
		local cobj = rawget(self.cursor_obj, true)
		local tobj = setmetatable({[true] = cobj, city = self.city, parent_dome = dome}, {__index = self.template_obj})
		tobj:GatherConstructionStatuses(self.construction_statuses)
	end
	
	if not dont_finalize then
		self:FinalizeStatusGathering(old_t)
	else
		return old_t
	end
end

function ConstructionController:FinalizeStatusGathering(old_t)
	SortConstructionStatuses(self.construction_statuses)
	if not table.iequals(old_t, self.construction_statuses) then
		self:PickCursorObjColor()
		ObjModified(self)
	else
		self:SetColorToAllConstructionObstructors(g_PlacementStateToColor.Obstructing)
	end
end

function ConstructionController:GetShortConstructionStatusPos(obj)
	local obj = obj or self.cursor_obj
	local spot = obj:GetSpotBeginIndex("Center")
	local pos = obj:GetSpotPos(spot) 
	local radius = Min(20*guim,obj:GetRadius())
	local camera_pos = camera.GetPos()
	local len = pos:Dist2D(camera_pos)
	pos = pos +  MulDivRound((camera_pos-pos),radius, len)
	local ok, pt  = GameToScreen(pos:SetZ(GetActiveTerrain():GetHeight(pos)))
	return pt
end

function ConstructionController:UpdateShortConstructionStatus()
	local dlg = GetHUD()
	if not dlg then return end
	local ctrl = dlg.idtxtConstructionStatus
	local text = ""
	if #self.construction_statuses > 0 then
		for i = 1, #self.construction_statuses do
			local st = self.construction_statuses[i]
			if st.short then
				text = T{878, "<col><short></color>", col = ConstructionStatusColors[st.type].color_tag_short, st}
				break
			end
		end
	end
	ctrl:SetText(text)
	ctrl:SetVisible(text~="") 
	ctrl:SetMargins(box(-ctrl.text_width/2,30,0,0))
	return text, ctrl
end

function ConstructionController:GetConstructionState()
	if self.construction_statuses[1] then
		return self.construction_statuses[1].type
	else
		return "clear"
	end
end

function ConstructionController:PickCursorObjColor()
	local clr
	local s = self:GetConstructionState()
	if s == "error" then
		self:SetColorToAllConstructionObstructors(g_PlacementStateToColor.Obstructing)
		clr = g_PlacementStateToColor.Blocked
	else
		self:ClearColorFromAllConstructionObstructors()
		clr = s == "problem" and g_PlacementStateToColor.Problematic or g_PlacementStateToColor.Placeable
		self.construction_obstructors = false
	end
	self.cursor_obj:SetColorModifier(IsEditorActive() and const.clrNoModifier or clr) 
end

function ConstructionController:ChangeAlternativeEntity(dir)
	if not self:HasVariants() then return end
	self:ChangeCursorObj(dir)
end

function ConstructionController:ChangeTemplateVariant(dir)
	local pos = self.cursor_obj:GetPos()
	local angle = self.cursor_obj:GetAngle()
	
	local idx = table.find(self.template_variants,self.template)
	idx = idx + dir
	if idx<1 then idx = #self.template_variants end
	if idx>#self.template_variants then idx = 1 end
	local template = self.template_variants[idx]
	self:Deactivate()
	self:Activate(template)

	self.cursor_obj:SetAngle(angle)
	self.cursor_obj:SetPos(pos)
	self:PickCursorObjColor()
	self:UpdateCursor(pos,"force")
end

function AdjustBuildPos(city, pos)
	if not GetDomeAtPoint(GetObjectHexGrid(city), pos) then
		local buildable_grid = GameMaps[city.map_id].buildable
		local build_z = buildable_grid:GetZ(WorldToHex(pos)) or UnbuildableZ
		if build_z ~= UnbuildableZ then
			return pos:SetZ(build_z)
		end
	end
	return pos
end

function ConstructionController:AddConstructionData(data)
end

--use external_template_name for calls outside of normal construction process
function ConstructionController:Place(external_template_name, pos, angle, param_t, force_instant_build, from_ui, flatten_unbuildable)
	local is_external = not not external_template_name
	local in_editor = IsEditorActive()
	
	if g_Tutorial then
		if table.find(self.construction_statuses or empty_table, ConstructionStatus.NoDroneHub) then
			ShowPopupNotification("Tutorial1_Popup7_DroneRange", false, false, GetInGameInterface())
			return
		end
	end
	
	if not is_external then
		if not self.cursor_obj then return end
		if self:IsObstructed() then return end
		if not in_editor and self.construction_statuses and self.construction_statuses[1] and self.construction_statuses[1].type=="error" then return end
	end

	local city = self.city or UICity
	assert(city.cascade_cable_deletion_enabled == false, "Building placement should not del cables in bulk!")
	local map_id = city.map_id

	local template_name = external_template_name or self.template
	local template_obj = not is_external and self.template_obj or ClassTemplates.Building[template_name]
	local cursor_obj = not is_external and self.cursor_obj or self:CreateCursorObj(nil, template_obj, nil, map_id)
	local game_map = GameMaps[map_id]
	local realm = game_map.realm
	local terrain = game_map.terrain

	realm:SuspendPassEdits("ConstructionController.Place")
	SuspendTerrainInvalidations("ConstructionController.Place")

	if pos and angle then
		cursor_obj:SetPos(FixConstructPos(terrain, pos))
		cursor_obj:SetAngle(angle)
	end
	
	local dome = IsObjInDome(cursor_obj)

	--clear cables (Units don't clear cables)
	--[[
	if not IsKindOf(template_obj, "Unit") then
		self:DestroyCablesUnderneathCursor(cursor_obj, template_obj)
	end]]
	
	--gather WasteRock rocks
	local force_extend_bb = template_obj:HasMember("force_extend_bb_during_placement_checks") and template_obj.force_extend_bb_during_placement_checks ~= 0 and template_obj.force_extend_bb_during_placement_checks or false
	local rocks = HexGetUnits(realm, cursor_obj, template_obj:GetEntity(), nil, nil, nil, nil, "WasteRockObstructor", force_extend_bb, self.template_obj_points)
	local stockpiles = HexGetUnits(realm, cursor_obj, template_obj:GetEntity(), nil, nil, nil, function(obj) return obj:GetParent() == nil and IsKindOf(obj, "DoesNotObstructConstruction") and not IsKindOf(obj, "Unit") end, "ResourceStockpileBase", force_extend_bb, self.template_obj_points)
	
	-- ApplyToGrids is done in GridObject:GameInit()
	-- here it is applied speculativelty to mark the spot so no other buildings can occupy it before GameInit is called (from a thread)
	-- in addition, early application helps detection of objects to delete in RemoveUnderConstruction
			
	local bld
	local blck_pass = true
	local prefab_exit_mode = false
	if is_external or self.is_template then
		local construction_data = {}
		self:AddConstructionData(construction_data)
		
		local orig_terrain1, orig_terrain2
		if not terrain:HasRestoreType() and template_obj then
			local all_tiles, terrain1, tiles1, terrain2, tiles2 = TerrainDeposit_CountTiles(template_obj:GetBuildShape(), cursor_obj)
			orig_terrain1 = terrain1
			orig_terrain2 = terrain2
		end
		local no_flatten = not not dome or template_obj and template_obj.only_build_on_snapped_locations
		local place_pos, place_angle = cursor_obj:GetPos(), cursor_obj:GetAngle()
		if force_instant_build or in_editor or (#stockpiles == 0 and #rocks == 0 and template_obj and template_obj.instant_build) then
			for i = 1, #(rocks or empty_table) do
				DoneObject(rocks[i])
			end

			for i = 1, #(stockpiles or empty_table) do
				DoneObject(stockpiles[i])
			end
			
			if not no_flatten then
				FlattenTerrainInBuildShape(template_obj:GetFlattenShape(), cursor_obj, flatten_unbuildable)
			end

			local instance = param_t or {}
			instance.city = city
			instance.orig_terrain1 = orig_terrain1
			instance.orig_terrain2 = orig_terrain2
			instance.construction_data = construction_data
			
			Msg("InstantBuild", template_name, place_pos, place_angle, instance)
			
			bld = PlaceBuildingIn(template_name, map_id, instance, {alternative_entity_t = {entity = cursor_obj:GetEntity(), palette = cursor_obj.override_palette}})
			bld:SetAngle(place_angle)
			bld:SetPos(AdjustBuildPos(city, place_pos))
			if dome then
				DeleteUnattachedRoads(bld, dome)
				UpdateCoveredGrass(bld, dome, "build")
			end
			bld:ApplyToGrids()
			RemoveUnderConstruction(bld)
			Msg("ConstructionComplete", bld) --@@@msg ConstructionComplete, building - fired when the construction of a building is complete
		else
			local instance = param_t or {supplied = self.supplied, prefab = self.prefab, alternative_entity_t = {entity = cursor_obj:GetEntity(), palette = cursor_obj.override_palette}}
			instance.orig_terrain1 = orig_terrain1
			instance.orig_terrain2 = orig_terrain2
			instance.construction_data = construction_data
			instance.dome_skin = self.dome_skin
			
			blck_pass = #rocks == 0 and #stockpiles == 0
			-- PlaceConstructionSite calls ApplyToGrids internally
			if template_obj:HasMember("PlaceConstructionSite") then
				bld = template_obj:PlaceConstructionSite(city, template_name, place_pos, place_angle, instance, not blck_pass, no_flatten)
			else
				bld = PlaceConstructionSite(city, template_name, place_pos, place_angle, instance, not blck_pass, no_flatten)
			end
			bld:AppendWasteRockObstructors(rocks)
			bld:AppendStockpilesUnderneath(stockpiles)
			bld:ClearHierarchyGameFlags(const.gofNightLightsEnabled)
			
			if self.prefab and city:GetPrefabs(template_name) <= 1 then
				prefab_exit_mode = true
			end
		end
	else
		print("unexpected construction placement type")
	end

	if bld then
		bld:SetDome(dome)
		local bld_obj = GetBuildingObj(bld)
		if bld and bld.show_range_all then
			if bld:IsKindOf("ConstructionSite") then
				PlayFX("Select", "start", bld, bld_obj.class)
			else
				PlayFX("Select", "start", bld)
			end
		end
		
		if not IsKindOf(bld, "RocketLandingSite") then
			HintDisable("HintBuildingConstruction")
		end
		
		if in_editor then 
			bld:SetGameFlags(const.gofPermanent)
		end
		
		blck_pass = bld:HasMember("IsBlockerClearenceComplete") and bld:IsBlockerClearenceComplete() or blck_pass
		bld:SetCollision(blck_pass)
		bld:SetBlockPass(blck_pass)

		-- Send over the RCRover to build this construction
		if BuildingWithRCRover then
			CreateGameTimeThread(function(bld)
				BuildingWithRCRover:Construct(bld)
				BuildingWithRCRover = false
			end, bld)
		end
		if from_ui and self.ui_callback then
			self.ui_callback(bld)
		end
		
		if self.snap_target then
			self.snap_target:SnappedObjectPlaced(bld)
			bld:SnappedTo(self.snap_target)
		end
	end

	if self.cursor_obj and self.template_obj then
		self:UpdateConstructionObstructors()
		self:UpdateConstructionStatuses()
		self:UpdateShortConstructionStatus()
	end

	realm:ResumePassEdits("ConstructionController.Place")
	ResumeTerrainInvalidations("ConstructionController.Place")

	if not is_external then
		if self.amount and self.amount<=0 or prefab_exit_mode then
			CloseModeDialog()
			return true
		end
	else
		DoneObject(cursor_obj)
	end

	return is_external and bld or true
end

function ConstructionController:DestroyCablesUnderneathCursor(cursor_obj, template_obj)
	local cursor_obj = cursor_obj or self.cursor_obj
	local template_obj = template_obj or self.template_obj
	local object_hex_grid = GameMaps[self.city:GetMapID()].object_hex_grid.grid
	for _, cable in ipairs(HexGridShapeGetObjectList(object_hex_grid, cursor_obj, template_obj:GetShapePoints(), "ElectricityGridElement")) do
		DoneObject(cable)
	end
	local interior = GetEntityInteriorShape(template_obj:GetEntity())
	if interior and next(interior) then
		for _, cable in ipairs(HexGridShapeGetObjectList(object_hex_grid, cursor_obj, interior, "ElectricityGridElement")) do
			DoneObject(cable)
		end
	end
end

function ConstructionController:Rotate(delta)
	if self.cursor_obj and (not self.is_template or self.template_obj.can_rotate_during_placement) then
		PlayFX("RotateConstruction", "start", self.cursor_obj)
		self.cursor_obj:SetAngle(self.cursor_obj:GetAngle() + delta*60*60)
		self:UpdateConstructionObstructors()
		self:UpdateConstructionStatuses()
		self:UpdateShortConstructionStatus()
	end
	return "break"
end

function ConstructionController:Getconstruction_statuses_property()
	local items = {}
	if #self.construction_statuses > 0 then --we have statuses, display first 3
		for i = 1, Min(#self.construction_statuses, 3) do
			local st = self.construction_statuses[i]
			items[#items+1] = T{879, "<col><text></color>", col = ConstructionStatusColors[st.type].color_tag, text = st.text}
		end
		if #self.construction_statuses < 2 then
			local constr_dlg = GetInGameInterfaceModeDlg()
			if constr_dlg and constr_dlg.class == "ConstructionModeDialog" and constr_dlg.params and constr_dlg.params.passengers then
				local domes = GetDomesInWalkableDistance(self.city, self.cursor_obj:GetPos())
				items[#items+1] = T{7688, "<green>Domes in walkable distance: <number></color></shadowcolor>", number = #domes}
			end
		end
	else
		local constr_dlg = GetInGameInterfaceModeDlg()
		if constr_dlg and constr_dlg.class == "ConstructionModeDialog" and constr_dlg.params and constr_dlg.params.passengers then
			local domes = GetDomesInWalkableDistance(self.city, self.cursor_obj:GetPos())
			items[#items+1] = T{7688, "<green>Domes in walkable distance: <number></color></shadowcolor>", number = #domes}
		else
			items[#items+1] = T(880, "<green>All Clear!</green>")
		end
	end
	return table.concat(items, "\n")
end

function ConstructionController:GetDisplayName()
	return self.template_obj:GetDisplayName()
end

function ConstructionController:GetDescription()
	return T{self.template_obj.description, self.template_obj}
end

function ConstructionController:HasConstructionCost()
	return not self.template_obj:IsKindOfClasses("Vehicle", "ResourcePile", "ResourceStockpile", "OrbitalProbe", "RocketLandingSite")
end

function ConstructionController:GetConstructionCostAmounts()
	if not self:HasConstructionCost() then
		return
	end
	
	local costs = {}
	local mod_o = GetModifierObject(self.template_obj.template_name)
	for _,resource in ipairs(ConstructionResourceList) do
		local amount = UIColony.construction_cost:GetConstructionCost(self.template_obj, resource, mod_o)
		if amount > 0 then
			costs[resource] = amount
		end
	end
	
	return costs
end

function ConstructionController:GetConstructionCost()
	local costs = self:GetConstructionCostAmounts()
	if costs and next(costs) then
		local lines = { }
		for resource, amount in pairs(costs) do
			lines[#lines + 1] = T{901, "<resource_name><right><resource(number,resource)>", resource_name = GetResourceInfo(resource).display_name, number = amount, resource = resource }
		end
		return table.concat(lines, "<newline><left>")
	else
		return T(902, "Doesn't require construction resources")
	end
end

function ConstructionController:HasConsumption()
	local obj = self.template_obj
	local props = obj.properties
	for i = 1, #maintenance_props do
		local prop = table.find_value(props, "id", maintenance_props[i][1])
		if prop and obj[prop.id] ~= 0 then
			return true
		end
	end
end

function ConstructionController:GetConsumptionAmounts()
	local consumption = {}
	local obj = self.template_obj
	local modifier_obj = GetModifierObject(obj.template_name)
	for i = 1, #maintenance_props do
		local prop = table.find_value(obj.properties, "id", maintenance_props[i][1])
		local disable_prop = table.find_value(obj.properties, "id", "disable_" .. maintenance_props[i][1])
		
		if prop and obj[prop.id] ~= 0 then
			local val = disable_prop and modifier_obj:ModifyValue(obj[disable_prop.id], disable_prop.id) >= 1
							and 0 or modifier_obj:ModifyValue(obj[prop.id], prop.id)
			
			local amount = val
			local resource = maintenance_props[i][2]
			consumption[resource] = amount
		end
	end
	return consumption
end

function ConstructionController:GetConsumption()
	local consumption = self:GetConsumptionAmounts()
	
	local lines = { }
	for i = 1, #maintenance_props do
		local resource = maintenance_props[i][2]
		local amount = consumption[resource]
		local resource_name = maintenance_props[i][3]
		if amount then
			lines[#lines + 1] = T{901, "<resource_name><right><resource(number,resource)>", resource_name = resource_name, number = amount, resource = resource }
		end
	end
	
	return table.concat(lines, "<newline><left>")
end

function ConstructionController:GetElevationBoost()
	local pos = self.cursor_obj:GetPos()
	local map_id = self:GetMapID()
	return GetElevation(pos, map_id) * self.template_obj.bonus_per_kilometer_elevation / 1000
end

function ConstructionController:GetAvgSoilQualityInRange()
	return GetAvgSoilQualityInShape(self.template_obj:GetDefaultPlantShape(self.cursor_obj:GetPos()))
end

function ConstructionController:GetHighestSoilQualityInRange()
	return GetHighestSoilQualityInShape(self.template_obj:GetDefaultPlantShape(self.cursor_obj:GetPos()))
end

function ConstructionController:HasVariants()
	return #GetBuildingSkins(self.template) > 1
end

function ConstructionController:HasTemplateVariants()
	return self.template_variants and next(self.template_variants)
end

function ConstructionController:AlignToLandingPad(cursor_obj, landing_pad)
	local angle = landing_pad:GetAngle()
	local pos = landing_pad:GetPos()
	if self.template == "PodLandingSite" then
		angle = angle - 60*60
		pos = landing_pad:GetSpotLoc(landing_pad:GetSpotBeginIndex("Rocket"))
	end 
	cursor_obj:SetPos(pos)
	cursor_obj:SetAngle(angle)
end

------------------------------------------Demolish--------------------------------
DefineClass.DemolishModeDialog = {
	__parents = { "InterfaceModeDialog" },
	mode_name = "demolish",
	MouseCursor = "UI/Cursors/Salvage.tga",
	
	last_mouse_hex_pos = false,
	selected_dome = false,
}

function DemolishPropagate(obj)
	PlayFX("DemolishPropagate", "start")
	if obj:IsKindOf("RechargeStation") and obj.hub then
		return obj.hub
	end
	return obj
end

function DemolishModeDialog:Init()
	self:SetModal()
	CreateRealTimeThread(OpenAllDomes)
end

function DemolishModeDialog:Close(...)
	InterfaceModeDialog.Close(self, ...)
	CloseAllDomes()
	if IsValid(self.selected_dome) then 
		self.selected_dome:Close() 
	end
end

function DemolishModeDialog:CanDemolish(pt, obj)
	--Get object under mouse
	local obj = obj or SelectionMouseObj()
	
	--No object or an invalid one - ignore
	if not obj or  not IsValid(obj) then
		return false
	end
	
	--A Drone is a Unit, but can be demolished
	if IsKindOf(obj, "DroneBase") and obj:CanDemolish() then
		return true
	end
	
	--Any Unit (besides Drone) and etc. are ignored - no action for them
	if IsKindOfClasses(obj, "Unit", "SurfaceDeposit", "SubsurfaceDeposit") then
		return false
	end	
	
	obj = DemolishPropagate(obj)
	if IsKindOf(obj, "Building") 	then
		if obj:CanDemolish() then
			return true
		end
	elseif IsKindOf(obj, "SupplyGridObject") then	
		return true
	end
	
	return false
end

function DemolishModeDialog:OnMouseButtonDown(pt, button, obj)
	if button == "L" then
		--Get object under mouse
		local obj = obj or SelectionMouseObj()
		
		--No object or an invalid one - ignore
		if not obj or  not IsValid(obj) then
			return "break"
		end
		
		--A Drone is a Unit, but can be demolished
		if IsKindOf(obj, "DroneBase") then
			if obj:CanDemolish() then
				obj:ToggleDemolish()
			end
		end
		
		--Any Unit (besides Drone) and etc. are ignored - no action for them
		if IsKindOfClasses(obj, "Unit", "SurfaceDeposit", "SubsurfaceDeposit") then
			return "break"
		end	
		
		obj = DemolishPropagate(obj)
		if IsKindOf(obj, "Building") then
			if obj:CanDemolish() then
				obj:ToggleDemolish()
			else
				obj:DestroyedClear()
			end
		elseif IsKindOf(obj, "SupplyGridObject") then -- cables and pipes
			obj:Demolish()
		end
		
		return "break"
	elseif button == "R" then
		CloseModeDialog()
		PlayFX("DemolishCancel", "start")
		return "break"
	end
end

function DemolishModeDialog:OnMousePos(pt)
	local mouse_hex_pos_pt = point(WorldToHex(GetTerrainCursor()))
	
	if mouse_hex_pos_pt ~= self.last_mouse_hex_pos then
		self.last_mouse_hex_pos = mouse_hex_pos_pt
		local cursor = self:CanDemolish(mouse_hex_pos_pt) and "UI/Cursors/Salvage.tga" or "UI/Cursors/Salvage_no.tga"
		self:SetMouseCursor(cursor)	
	end
end

function DemolishModeDialog:OnShortcut(shortcut, source)
	if shortcut == "+ButtonA" or shortcut == "+LeftTrigger-ButtonA" then
		local center = self.box:Center()
		local object = SelectionGamepadObj(center)
		if object then
			self:OnMouseButtonDown(center, "L", object)
		end
		return "break"
	elseif shortcut == "+ButtonB" or shortcut == "Escape" then
		return self:OnMouseButtonDown(nil, "R")
	elseif shortcut == "Back" or shortcut == "TouchPadClick" then
		if DismissCurrentOnScreenHint() then
			return "break"
		end
	end
end

----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

---gui
maintenance_props = {
	{"electricity_consumption", "Power", T(79, "Power")},
	{"air_consumption", "Air", T(891, "Air")},
	{"water_consumption", "Water", T(681, "Water")},
}

function OnMsg.GatherFXActions(list)
	list[#list + 1] = "ConstructionCursor"
	list[#list + 1] = "RotateConstruction"
end

function OnMsg.GatherFXActors(list)
	list[#list + 1] = "CursorBuilding"
end

DefineClass.GridTile = {
	__parents = { "CObject" },
	flags = { cfConstructible = false, gofRealTimeAnim = true },
	entity = "GridTile",
	SetDust = empty_func,
}

DefineClass.GridTileWater = {
	__parents = { "CObject" },
	flags = { cfConstructible = false, gofRealTimeAnim = true },
	entity = "GridTileWater",
	SetDust = empty_func,
}

GlobalVar("WaterMarkerCollisionDetector", false)

function HexToStorage(q, r)
	return q + r/2, r
end

function StorageToHex(x, y)
	return x - y / 2, y
end

function SetObjWaterMarkers(obj, show, list)
	if not IsValid(obj) then
		return
	end
	if show and IsKindOf(obj, "Building") and obj.destroyed then
		show = false
	end
	local marker_class = "GridTileWater"
	if not show then
		obj:DestroyAttaches(marker_class)
		return
	end
	local spot_name = "Lifesupportgrid"
	if not obj:HasSpot(spot_name) then
		return
	end
	local custom_visible = obj:HasMember("GetMarkerVisibility")

	local game_map = GetGameMap(obj)
	local object_hex_grid = game_map.object_hex_grid
	local buildable = game_map.buildable

	if show == "update" then
		obj:ForEachAttach(marker_class, function(marker)
			local spot = marker:GetAttachSpot()
			local x, y, z = obj:GetSpotPosXYZ(spot)
			local q, r = WorldToHex(x, y)
			local zmin = GetMaxHeightInHex(game_map, x, y) + 30
			marker:SetAttachOffset(0, 0, Max(0, zmin - z))
			local visible = buildable:IsBuildable(q, r) and not HexGetBuilding(object_hex_grid, q, r)
			if visible and custom_visible and not obj:GetMarkerVisibility(marker) then
				visible = false
			end
			if WaterMarkerCollisionDetector then
				local sx, sy = HexToStorage(q, r)
				local key = sx + sy*game_map.hex_width
				local v = WaterMarkerCollisionDetector[key]
				visible = visible and not v
				WaterMarkerCollisionDetector[key] = v or visible
			end
			marker:SetVisible(visible)
		end)
	elseif obj:CountAttaches(marker_class) == 0 then
		local all_spots
		if IsKindOf(obj, "PropertyObject") and obj:HasMember("GetAllPipeSpots") then
			all_spots = obj:GetAllPipeSpots()
		else
			all_spots = { }
			local first, last = obj:GetSpotRange(spot_name)
			for idx = first, last do
				all_spots[idx - first + 1] = idx
			end
		end
		for i=1,#all_spots do
			local idx = all_spots[i]
			local marker = PlaceObjectIn(marker_class, game_map.map_id, nil, const.cofComponentAttach)
			obj:Attach(marker, idx)
			marker:SetAttachAngle(- marker:GetAngle())
			local x, y, z = marker:GetVisualPosXYZ()
			local q, r = WorldToHex(x, y)
			local zmin = GetMaxHeightInHex(game_map, x, y) + 30
			marker:SetAttachOffset(0, 0, Max(0, zmin - z))
			local visible = buildable:IsBuildable(q, r) and not HexGetBuilding(object_hex_grid, q, r)
			if visible and custom_visible and not obj:GetMarkerVisibility(marker) then
				visible = false
			end
			marker:SetVisible(visible)
			if list then
				list[#list + 1] = marker
			end
		end
	end
	return true
end

function SavegameFixups.RemoveStuckDomeShapeHexes()
	MapDelete("map", "GridTile")
end


----

function OnMsg.Demolished(obj)
	SetObjWaterMarkers(obj, false)
	--update construction controller
	local constr_dlg = GetInGameInterfaceModeDlg()
	if not constr_dlg then
		return
	end
	local obj = GetConstructionController(constr_dlg.mode_name)
	if not obj then
		return
	end
	if constr_dlg:IsKindOf("GridConstructionDialog") then
		local terrain_pos = HexGetNearestCenter(GetTerrainCursor())
		local terrain = GetTerrain(obj)
		if terrain:IsPointInBounds(terrain_pos) then
			obj:UpdateVisuals(terrain_pos)
		end
	else
		obj:UpdateConstructionObstructors()
		obj:UpdateConstructionStatuses() --should go after obstructors
		obj:UpdateShortConstructionStatus()
	end
end

function dbg_GetCursorObj()
	return GetDefaultConstructionController().cursor_obj
end
