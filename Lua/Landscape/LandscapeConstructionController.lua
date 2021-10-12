DefineClass.LandscapeConstructionDialog = {
	__parents = { "ConstructionModeDialog" },
	Cursor =  "UI/Cursors/CablePlacement.tga",
	success_sound = "LandscapeConstructionSuccess",
	mode_name = false,
}

function LandscapeConstructionDialog:OnStartup()
	local obj = GetConstructionController(self.mode_name)
	obj:Activate(self.context.template)
end

function LandscapeConstructionDialog:OnMouseButtonDown(pt, button)
	local obj = GetConstructionController(self.mode_name)
	local success, deactivate
	if button == "L" then
		success, deactivate = obj:Place()
		if success then
			PlayFX(self.success_sound, "start")
		else
			PlayFX("ConstructionFail", "start")
		end
	end
	if button == "R" or deactivate then
		obj:Deactivate(pt)
		PlayFX("LandscapeTerraceCancel", "start")
		CloseModeDialog()
		return "break"
	end
	if button == "M" then
		obj:Rotate(terminal.IsKeyPressed(const.vkAlt) and -1 or 1, true)
	end
end

LandscapeConstructionDialog.OnMouseButtonDoubleClick = LandscapeConstructionDialog.OnMouseButtonDown

function LandscapeConstructionDialog:OnKbdKeyDown(virtual_key, repeated)
	if virtual_key == const.vkEsc then
		self:OnMouseButtonDown(nil, "R")
		return "break"
	end
	return "continue"
end

function LandscapeConstructionDialog:OnShortcut(shortcut, source)
	if shortcut == "ButtonA" or shortcut == "LeftTrigger-ButtonA" then
		self:OnMouseButtonDown(GetTerrainGamepadCursor(), "L")
		return "break"
	elseif shortcut == "ButtonB" then
		self:OnMouseButtonDown(nil, "R") --cancel
		return "break"
	end
end

----

DefineClass.LandscapeConstructionController = {
	__parents = { "ConstructionController" },
	
	max_range = 100, --hexes
	
	brush_radius = 90*guim,
	brush_radius_step = 10*guim, --m
	brush_radius_min = 10*guim, --m
	brush_radius_max = 100*guim, --m
	
	placed = false,
	
	max_landscapes = false,
	place_block = false,
	mark_fail = false,
	out_of_bounds = false,
	
	last_pos = false,
	last_undo_pos = false,
	last_brush_radius = 0,
	obstruct_handles = empty_table,
	obstruct_marks = empty_table,
	resize_sign = 1,
	
	current_status = const.clrNoModifier,
	stockpiles_obstruct = true,
	
	waste_rock_from_colored_rocks = 0,
	waste_rock_from_colored_rocks_last_place = 0,
	template_class = false,
	ignore_domes = true,
}

function LandscapeConstructionController:Init()
	self.brush_radius = round((self.brush_radius_min + self.brush_radius_max) / 2, self.brush_radius_step)
end

function LandscapeConstructionController:PickCursorObjColor()
end

LandscapeConstructionController.SetTxtPosObj = GridConstructionController.SetTxtPosObj

function LandscapeConstructionController:Activate(template)
	self.waste_rock_from_colored_rocks = 0
	self.selected_domes = {}
	self.template_name = template
	self.placed = false
	local t_obj = BuildingTemplates[template]
	self.template_class = t_obj and t_obj.template_class
	self.template_obj = ClassTemplates.Building[template] or g_Classes[template]
	self.template_obj_points = self.template_obj and self.template_obj:GetBuildShape()
	local entity = self.template_obj.entity
	if IsValid(self.cursor_obj) then
		self.cursor_obj.entity = entity
		self.cursor_obj:ChangeEntity(entity)
	else
		self.cursor_obj = CursorBuilding:new{ template = self.template_obj, entity = entity }
		self.cursor_obj:ClearEnumFlags(const.efVisible)
	end
	self:SetTxtPosObj(self.cursor_obj)
	self:UpdateCursor()
end

function LandscapeConstructionController:Mark(test)
end

function LandscapeConstructionController:Place()
	assert(self.last_pos)
	local s = self:GetConstructionState()
	if s == "error" then
		return false
	end
	local pt = self.last_pos
	self.placed = pt
	local success, ready = self:Mark()
	self.last_undo_pos = pt
	self.waste_rock_from_colored_rocks_last_place = self.waste_rock_from_colored_rocks
	return success, ready
end

function LandscapeConstructionController:ValidateMark(test)
	return LandscapeMarkSmooth(test, self.obstruct_handles, self.obstruct_marks)
end

function LandscapeConstructionController:Rotate(step, mirror)
	if not mirror then
		self.brush_radius = Clamp(self.brush_radius + step * self.brush_radius_step, self.brush_radius_min, self.brush_radius_max)
	else
		self.brush_radius = self.brush_radius + self.resize_sign * step * self.brush_radius_step
		if self.brush_radius >= self.brush_radius_max then
			self.brush_radius = self.brush_radius_max
			self.resize_sign = -self.resize_sign
		elseif self.brush_radius <= self.brush_radius_min then
			self.brush_radius = self.brush_radius_min
			self.resize_sign = -self.resize_sign
		end
	end
	self:UpdateCursor(self.last_pos)
end

function LandscapeConstructionController:IsMarkSuitable(pt)
	pt = pt or self.last_pos
	local map_id = self:GetMapID()
	return IsInMapPlayableArea(map_id, pt) and LandscapeMarkBuildable(map_id, pt)
end

function LandscapeConstructionController:UpdateCursor(pt)
	pt = HexGetNearestCenter(pt or GetUIStyleGamepad() and GetTerrainGamepadCursor() or GetTerrainCursor())
	if self.last_pos and self.last_pos:Equal2D(pt) and self.last_brush_radius == self.brush_radius then
		return
	end
	self.last_pos = pt
	self.last_brush_radius = self.brush_radius
	
	if IsValid(self.cursor_obj) then
		local terrain = GetTerrain(self)
		self.cursor_obj:SetPos(FixConstructPos(terrain, pt))
	end
	
	self.obstruct_handles = {}
	self.obstruct_marks = {}
	self:ClearColorFromAllConstructionObstructors()
	
	self.mark_fail = nil
	self.max_landscapes = nil
	self.place_block = nil
	self.out_of_bounds = nil
	
	if not self.placed then
		local map_id = self:GetMapID()
		self.max_landscapes = not LandscapeMarkStart(map_id, pt)
		self.out_of_bounds = not IsInMapPlayableArea(map_id, pt)
		self.place_block = not self:IsMarkSuitable(pt)
	end
	local landscape = Landscapes[LandscapeMark]
	if landscape then
		self.mark_fail = not self:Mark(true)
		local fully_overlapped = (landscape.hexes or 0) == 0 and LandscapeCheck(GetLandscapeGrid(self), pt)
		if fully_overlapped then
			self.obstruct_marks[fully_overlapped] = true
		end
	end
	
	ObjModified(self)
	self:UpdateConstructionObstructors()
	self:UpdateConstructionStatuses(pt)
	self:UpdateShortConstructionStatus()

	hr.LandscapeInvalidMark = self:GetConstructionState() == "error" and LandscapeMark or 0
end

function GetCostsFromVolumeAndAbsVolume(volume, absvolume)
	local pt, nt = 0, 0
	nt = (absvolume - volume) / 2
	pt = absvolume - nt

	return pt, nt
end

function LandscapeConstructionController:ColorRocks(...)
	if self.template_class == "LandscapeTextureBuilding" then return end
	return ConstructionController.ColorRocks(self, ...)
end

function LandscapeConstructionController:GetConstructionSite()
	if self.template_class == "LandscapeClearWasteRockBuilding" then
		return g_Classes["ClearWasteRockConstructionSite"]
	end
	local is_tex_only = self.template_class == "LandscapeTextureBuilding"
	return is_tex_only and g_Classes["TerrainPaintConstructionSite"] or g_Classes["LandscapeConstructionSite"]
end

function LandscapeConstructionController:Deactivate(pt)
	local landscape = Landscapes[LandscapeMark]
	if not landscape then
		return
	end
	
	LandscapeMarkCancel()
	self:ValidateMark()
	LandscapeMarkEnd()
	
	if landscape.primes == 0 then
		LandscapeFinish(landscape.mark)
	else
		local is_tex_only = self.template_class == "LandscapeTextureBuilding"
		local cls = self:GetConstructionSite()
		local site = cls:new{
			hexes = landscape.hexes,
			mark = landscape.mark,
			abs_volume = landscape.volume,
			volume = landscape.material,
			waste_rock_from_rocks_underneath = not is_tex_only and self.waste_rock_from_colored_rocks_last_place or nil,
		}
		
		site:SetBuildingClass(self.template_name)
		site:SetPos(HexGetNearestCenter(landscape.start))
		landscape.site = site
	end
	
	self.last_undo_pos = false
	self.last_pos = false
	self.placed = false
	if IsValid(self.cursor_obj) then
		self.cursor_obj:delete()
		self.cursor_obj = false
	end
	self:ColorRocks()
	self:ClearColorFromAllConstructionObstructors()
	
	hr.LandscapeInvalidMark = 0
end

ConstructionStatus.LandscapeOverlapping = { type = "error", priority = 91, text = T(12029, "Overlaping landscaping projects."), short = T(12030, "Overlaping projects")}
ConstructionStatus.LandscapeUnavailable = { type = "error", priority = 91, text = T(12031, "Select a flat surface to extend."), short = T(12032, "Not flat")}
ConstructionStatus.LandscapeLowTerrain =  { type = "error", priority = 91, text = T(12033, "Landscaping excavation is too deep."), short = T(12034, "Excavation too deep")}
ConstructionStatus.LandscapeTooMany =     { type = "error", priority = 91, text = T(12163, "No more landscape projects can be placed."), short = T(12164, "Too many projects")}
ConstructionStatus.LandscapeTooLarge =    { type = "error", priority = 91, text = T(12165, "Project area covers too many hexes, or has become too wide."), short = T(12166, "Too large")}
ConstructionStatus.LandscapeOutOfBounds = { type = "error", priority = 92, text = T(12396, "Project area goes outside of the boundaries of the Colony."), short = T(12397, "Out of bounds")}

function LandscapeConstructionController:GetLimits()
	local max_boundary, max_hexes
	if self.template_obj then
		max_boundary = self.template_obj.max_boundary
		max_hexes = self.template_obj.max_hexes
	end
	if (max_boundary or 0) == 0 then
		max_boundary = const.Terraforming.LandscapeMaxBoundary
	end
	if (max_hexes or 0) == 0 then
		max_hexes = const.Terraforming.LandscapeMaxHexes
	end
	return max_boundary, max_hexes
end

function LandscapeConstructionController:AddConstructionStatuses(statuses)
	local landscape = Landscapes[LandscapeMark]
	if not landscape then
		return
	end
	local obstructed = self:IsObstructed()
	local overlapped = next(self.obstruct_marks)
	local max_boundary, max_hexes = self:GetLimits()
	if Max(landscape.bbox:sizexyz()) > max_boundary then
		statuses[#statuses + 1] = ConstructionStatus.LandscapeTooLarge
	end
	if landscape.hexes > max_hexes then
		statuses[#statuses + 1] = ConstructionStatus.LandscapeTooLarge
	end
	if self.max_landscapes then
		statuses[#statuses + 1] = ConstructionStatus.LandscapeTooMany
	elseif self.out_of_bounds or self.mark_fail and not obstructed and not overlapped then
		statuses[#statuses + 1] = ConstructionStatus.LandscapeOutOfBounds
	elseif self.place_block then
		statuses[#statuses + 1] = ConstructionStatus.LandscapeUnavailable
	elseif obstructed then
		statuses[#statuses + 1] = ConstructionStatus.BlockingObjects
	end
	if overlapped then
		statuses[#statuses + 1] = ConstructionStatus.LandscapeOverlapping
	end
	--[[
		if not IsCloser2D(self.placed_obj, self.cursor_obj, self.max_range * const.GridSpacing) then
			table.insert(self.construction_statuses, ConstructionStatus.TooFarFromLandscapeEntrance)
		end
	--]]
end

function LandscapeConstructionController:UpdateConstructionStatuses(pt)
	local old_t = self.construction_statuses
	
	local statuses = {}
	self:AddConstructionStatuses(statuses)
	self.construction_statuses = statuses

	self:FinalizeStatusGathering(old_t)
end

local function HandleCollect(handle, objects)
	local obj = HandleToObject[handle]
	if IsValid(obj) then
		if obj.class == "GridObjectList" then
			for _, handlei in ipairs(obj) do
				HandleCollect(handlei, objects)
			end
		else
			objects[obj] = true
		end
	end
end

function LandscapeConstructionController:UpdateConstructionObstructors()
	local obstructors = {}
	for handle in pairs(self.obstruct_handles or empty_table) do
		HandleCollect(handle, obstructors)
	end
	self.construction_obstructors = table.keys(obstructors)
	local objs = {}
	local wr = 0
	local passed = {}
	local function AddObj(obj)
		if not table.find(objs, obj) then
			objs[#objs + 1] = obj
			if obj:GetEnumFlags(const.efRemoveUnderConstruction + const.efBakedTerrainDecal + const.efBakedTerrainDecalLarge) == 0 then
				wr = wr + GetWasteRockAmountForObj(obj)
			end
		end
	end
	LandscapeForEachObstructor(LandscapeMark, AddObj)
	self.waste_rock_from_colored_rocks = wr
	self:ColorRocks(objs)
	ObjModified(self)
end

function LandscapeConstructionController:HasConstructionCost()
	return false
end

function LandscapeConstructionController:GetConstructionCost()
	local resource_name = Resources.WasteRock.display_name
	local coef = UIColony:IsTechResearched("ConservationLandscaping") and 2 or 1
	
	local total_cost, total_negative_cost, hexes, boundary = 0, 0, 0, 0
	local landscape = Landscapes[LandscapeMark]
	if landscape then
		total_cost, total_negative_cost = GetCostsFromVolumeAndAbsVolume(landscape.material, landscape.volume)
		hexes = landscape.hexes
		boundary = Max(landscape.bbox:sizexyz())
	end
	
	local modified_total_cost = total_cost / coef
	local modified_total_negative_cost = total_negative_cost * coef
	local lines = {}
	if modified_total_cost > modified_total_negative_cost and (modified_total_cost - modified_total_negative_cost > 99 or self.waste_rock_from_colored_rocks <= 0) then
		local required = modified_total_cost - modified_total_negative_cost
		lines[#lines+1] = T{11898, "<em>Required Waste Rock</em><right><wasterock(number)>", number = required, resource = "WasteRock" }
	elseif modified_total_cost < modified_total_negative_cost or self.waste_rock_from_colored_rocks > 0 then
		local excess = modified_total_negative_cost - modified_total_cost + self.waste_rock_from_colored_rocks
		lines[#lines+1] = T{11899, "<em>Excess Waste Rock</em><right><resource(number,resource)>", number = excess, resource = "WasteRock" }
	else
		lines[#lines+1] = T(12281, "<green>No need for additional Waste Rock</green>")
	end
	local max_boundary, max_hexes = self:GetLimits()
	lines[#lines+1] = T{12283, "<newline>Tool size<right><size>/<max_size>", size = self.brush_radius / self.brush_radius_step, max_size = self.brush_radius_max / self.brush_radius_step}
	lines[#lines+1] = T{12082, "Hexes covered<right><hexes>/<max_hexes>", hexes = hexes, max_hexes = max_hexes}
	lines[#lines+1] = T{12484, "Size Boundary<right><boundary>/<max_boundary>", boundary = boundary, max_boundary = max_boundary}
	return table.concat(lines, "<newline><left>")
end

---- Selection

function GetLandscapeConstructionAt(...)
	local mark = LandscapeCheck(GetActiveLandscapeGrid(), ...)
	local landscape = mark and Landscapes[mark]
	if not landscape then
		return
	end
	local site = landscape.site
	if not IsValid(site) then
		assert(false, "Missing landscape construction site!")
		return
	end
	return site
end

function OnMsg.GatherSelectedObjectsOnHexGrid(q, r, objs)
	local site = GetLandscapeConstructionAt(q, r, true)
	table.insert_unique(objs, site)
end

function OnMsg.GamepadGatherSelectedObjects(gamepad, objs)
	local site = GetLandscapeConstructionAt(gamepad.pos)
	table.insert_unique(objs, site)
end

GlobalVar("LandscapeConstructionSiteColoredRocks", {})

function ColorRocksLSConstruction(obj)
	ClearColorRocksLSConstruction(obj)
	LandscapeConstructionSiteColoredRocks[1] = obj
	local t = obj.obstructors_cache
	for i = 1, #(t or "") do
		local rock = t[i]
		if IsValid(rock) then
			rock:SetGameFlags(const.gofWhiteColored)
			table.insert(LandscapeConstructionSiteColoredRocks, rock)
		end
	end
end

function ClearColorRocksLSConstruction()
	if #LandscapeConstructionSiteColoredRocks == 0 then return end
	for i = #LandscapeConstructionSiteColoredRocks, 2, -1 do
		local rock = LandscapeConstructionSiteColoredRocks[i]
		if IsValid(rock) then
			rock:ClearGameFlags(const.gofWhiteColored)
		end
	end
	LandscapeConstructionSiteColoredRocks = {}
end

function OnMsg.SelectionChange()
	if not SelectedObj or SelectedObj ~= LandscapeConstructionSiteColoredRocks[1] then
		ClearColorRocksLSConstruction()
	end
	if IsKindOf(SelectedObj, "ClearWasteRockConstructionSite") then
		ColorRocksLSConstruction(SelectedObj)
	end
	local mark = SelectedObj and rawget(SelectedObj, "mark") or 0
	if LandscapeMark == 0 then
		hr.LandscapeCurrentMark = mark
	end
end

local function HasLandscapeConstructionVisuals(site)
	return IsKindOf(site.building_class_proto, "Building") and site.building_class_proto.landscape_construction_visuals and GetGameMap(site).landscape_grid
end

function OnMsg.ConstructionSitePlaced(site)
	if not HasLandscapeConstructionVisuals(site) then
		return
	end
	local pos = site:GetVisualPos()
	local landscape = LandscapeMarkStart(site:GetMapID(), pos)
	if not landscape then
		return
	end
	local x, y, z = pos:xyz()
	local mark = landscape.mark
	local bbox = box()
	local shape = site:GetBuildShape()
	local landscape_grid = GetLandscapeGrid(site)
	HexShapeForEach(shape, site, function(q, r)
		local sx, sy = HexToStorage(q, r)
		assert(landscape_grid:get(sx, sy) == 0)
		local l = bor(z, shift(mark, 16))
		landscape_grid:set(sx, sy, l)
		bbox = Extend(bbox, point(sx, sy))
	end)
	landscape.hexes = #shape
	landscape.primes = #shape
	landscape.bbox = bbox
	landscape.site = site
	rawset(site, "mark", mark)
	Landscape_SetGrid(landscape_grid, bbox)
	LandscapeMarkEnd()
end

function OnMsg.ConstructionSiteRemoved(site)
	if not HasLandscapeConstructionVisuals(site) then
		return
	end
	local mark = rawget(site, "mark") or 0
	local landscape = Landscapes[mark]
	if not landscape then
		return
	end
	Landscape_MarkErase(mark, landscape.bbox, GetLandscapeGrid(site))
	Landscapes[mark] = nil
	hr.RenderLandscape = next(Landscapes) and 1 or 0
end
