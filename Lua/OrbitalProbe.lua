DefineClass.OrbitalProbe = {
	__parents = { "BaseBuilding", "CityObject", "Shapeshifter", "PinnableObject" },
	flags = { efWalkable = false, efCollision = false, efApplyToGrids = false },
	properties = {
		{ id = "display_name", default = T(3525, "Orbital Probe") },
		{ id = "display_icon", default = "UI/Icons/Buildings/orbital_probe.tga" },
		{ id = "description", default = T(10086, "Reveals underground deposits in the scanned area.")},
	},
	entity = "InvisibleObject",
	range = 160*guim,
	duration = 2*const.HourDuration,
	detected_classes = { "SubsurfaceDepositMetals", "SubsurfaceDepositWater", "SubsurfaceDepositMinerals" },
	
	show_pin_toggle = false,
	pin_on_start = false,
	pin_rollover = T(3680, "Immediately scans a Sector for deposits and Anomalies.<DeepScanWarning><newline><newline>Available Orbital Probes<right><NumProbes>"),
	pin_rollover_hint = T(3681, "<left_click> Select Sector"),
	pin_rollover_hint_xbox = T(7882, "<PinRolloverGamepadHint>"),
	pin_progress_value = "",
	pin_progress_max = "",
	pin_summary1 = T(3683, "<NumProbes>"),
	scan_pattern = { point(0, 0) },
	
	--resolve inheritance
	Random = CityObject.Random
}

function OrbitalProbe:GetPinRolloverGamepadHint()
	if GetInGameInterfaceMode() ~= "overview" then
		return T(3682, "<ButtonA> Overview")
	else
		return T(8569, "<ButtonA> Select Sector")
	end
end

function OrbitalProbe:GameInit()
	if self.city.MapSectors then
		local _, fully_scanned = UnexploredSectorsExist(self.city)
		if fully_scanned then
			self:Notify("delete")
			return
		end
	end
	
	self.city:AddToLabel("OrbitalProbe", self)
	if not self.city.labels.OrbitalProbe or #self.city.labels.OrbitalProbe == 1 then
		self:TogglePin()
	end
end

function OrbitalProbe:UpdateNotWorkingBuildingsNotification()
end

function OrbitalProbe:Done()
	self.city:RemoveFromLabel("OrbitalProbe", self)
end

function OrbitalProbe:GetNumProbes()
	local city = self and self.city or MainCity
	local probes = city and city.labels.OrbitalProbe
	return probes and #probes or 0
end

function OrbitalProbe:GetDeepScanWarning()
	if self.city.colony:IsTechResearched("AdaptedProbes") then
		return ""
	end
	return T(3684, "<newline><em>Deep scanning of the Sector is not possible with the current technology</em>")
end

function OrbitalProbe:GetAffectedSectors(sector)
	local list = {}
	
	local exploration = self.city
	for _, offset in ipairs(self.scan_pattern) do
		local x, y = offset:xy()
		local col = sector.col + x
		local row = sector.row + y
		local s = exploration.MapSectors[col] and exploration.MapSectors[col][row]
		if s then
			list[#list + 1] = s
		end
	end
	return list
end

function OrbitalProbe:ScanSector(sector)
	assert(not sector:HasBlockers())
	if g_Tutorial and not g_Tutorial.EnableOrbitalProbes or sector:HasBlockers() then
		return
	end

	local deep = UIColony:IsTechResearched("AdaptedProbes")
	
	local list = self:GetAffectedSectors(sector)
	local mode = deep and "deep scanned" or "scanned"
	for _, s in ipairs(list) do
		s:Scan(mode, "probe")
	end
	
	local realm = GetRealm(self)
	local scan_pos = sector.area:Center()
	scan_pos = realm:SnapToTerrain(scan_pos)

	PlayFX({
		actionFXClass = "OrbitalProbeScan",
		actionFXMoment = "start",
		action_pos = scan_pos,
		action_map_id = self:GetMapID(),
	})
	HintDisable("HintProbes")

	local label = self.city.labels.OrbitalProbe
	DoneObject(label[#label])
	ObjModified(self)
end

function OrbitalProbe:CanBeUnpinned()
	local label = self.city.labels.OrbitalProbe
	return not label or not next(label)
end

function OrbitalProbe:OnPinClicked(gamepad)
	local dlg = GetInGameInterface()
	assert(dlg)
	if not CameraTransitionThread and dlg.mode ~= "overview" then
		dlg:SetMode("overview")
	end
	assert(dlg.mode == "overview" and dlg.mode_dialog:IsKindOf("OverviewModeDialog"))
	
	--gamepad doesn't go into this state (fix:0129799)
	if not gamepad then
		dlg.mode_dialog:SetScan(true)
	end
	
	--if a pin is selected (it must be this object) -> deselect it (fix:0129807)
	local focus = terminal.desktop:GetKeyboardFocus()
	if focus and IsKindOf(focus.parent, "PinsDlg") then
		GetDialog("PinsDlg"):SetFocus(false, true)
	end
	
	if HintsEnabled then
		HintTrigger("HintProbes")
	end
	
	return true
end

function OrbitalProbe:GetDisplayName()
	return self.display_name
end

DefineClass.AdvancedOrbitalProbe = {
	__parents = { "OrbitalProbe" },

	pin_rollover = T(11413, "Immediately scans a Sector and the four adjacent Sectors for deposits and anomalies.<DeepScanWarning><newline><newline>Available Orbital Probes<right><NumProbes>"),

	properties = {
		{ id = "display_name", default = T(10087, "Advanced Orbital Probe") },
		{ id = "display_icon", default = "UI/Icons/Buildings/orbital_probe.tga" },
	},
	scan_pattern = {
		point(0, 0),
		point(-1, 0),
		point(1, 0),
		point(0, 1),
		point(0, -1),
	},
}