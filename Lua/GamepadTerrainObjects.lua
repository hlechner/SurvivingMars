if FirstLoad then
	g_GamepadObjects = false
end

DefineClass.GamepadTerrainObjects =
{
	__parents = { "InitDone", "MsgObj" },
	
	--visual state
	cursor_state = "idle", --cursor image
	actions = false, --allowed actions (mapped to buttons)
	
	--selected objlists
	units = false, --drones and colonists
	objects = false, --everything else
	
	--internals
	update_thread = false, --handle to update thread
	disable_update = false, --temporarily pauses updates
	last_selection = false, --keeps last selected object
	pos = false, --cursor terrain pos
	width = false, --cursor width
	
	cursor_disappear_time = 5*1000, --time after last xinput
}

function PlaceGamepadTerrainObjects()
	if IsValid(g_GamepadObjects) then 
		g_GamepadObjects:delete()
	end
	if GetUIStyleGamepad() and ActiveMapData.GameLogic then
		g_GamepadObjects = PlaceObject("GamepadTerrainObjects")
	else
		g_GamepadObjects = false
	end
	if UseHybridControls() and IsHybridGamepadCursorHidden() then
		ShowGamepadCursor("HybridNoInput")
	end
end

OnMsg.GamepadUIStyleChanged = PlaceGamepadTerrainObjects
OnMsg.LoadGame = PlaceGamepadTerrainObjects
OnMsg.NewMapLoaded = PlaceGamepadTerrainObjects
OnMsg.PostSwitchMap = PlaceGamepadTerrainObjects

function GamepadTerrainObjects:Init()
	self.units = {}
	self.objects = {}
	self.actions = { }
	
	self.update_thread = CreateMapRealTimeThread(function(self)
		while true do
			WaitMsg("OnRender")
			self:Update()
		end
	end, self)
end

function GamepadTerrainObjects:Done()
	if IsValidThread(self.update_thread) then
		DeleteThread(self.update_thread)
	end
end

local function PropagateObjectList(objects)
	local result = {}

	for i,obj in ipairs(objects) do
		local remapped_obj = SelectionPropagate(obj)
		if IsKindOf(remapped_obj, "SurfaceDeposit") then
			local group = remapped_obj:GetDepositGroup()
			remapped_obj = group and group.holder or remapped_obj
		end
		if not table.find(result, remapped_obj) then
			result[#result + 1] = remapped_obj
		end
	end
	
	return result
end

function GamepadTerrainObjects:Update()
	if UseHybridControls() and not IsHybridGamepadCursorHidden() then
		if RealTime() - XInput.LastPressTime > self.cursor_disappear_time then
			HideGamepadCursor("HybridNoInput")
		end
	elseif UseHybridControls() and IsHybridGamepadCursorHidden() and RealTime() - XInput.LastPressTime < self.cursor_disappear_time then
		ShowGamepadCursor("HybridNoInput")
	end
	
	local xcursor = GetGamepadCursor()
	if not xcursor then
		return
	end
	
	local extend = const.GridExtendDist or 0
	local xpos = GetTerrainGamepadCursor(-extend)
	if not xpos or xpos == InvalidPos() or not GetActiveTerrain():IsPointInBounds(xpos, -extend) or self.disable_update then
		return
	end
	
	local angle = hr.FovAngle / 2
	local pos = cameraRTS.GetPosLookAt()
	local screen_width = UIL.GetScreenSize():x() / 2
	local s, c = sincos(angle)
	local d = pos:Dist(xpos)
	local zoom = cameraRTS.GetZoom()
	
	-- The divisor can overflow with cos(small fov angles), so we divide twice
	-- local width = MulDivTrunc(zoom * d / 2, GetXCursorWidth() * s, 1000 * screen_width * c)
	
	local xcursor_width = MulDivRound(xcursor.box:sizex(), 100, GetUIScale())
	self.width = MulDivTrunc(zoom * d / 2, xcursor_width * s, 100 * screen_width * c) / 10
	self.pos = xpos
	
	local game_mode = GetInGameInterfaceMode() or "none"
	local mode_dialog = GetInGameInterfaceModeDlg()
	
	--selection or not using UnitControl
	if game_mode == "selection" and not mode_dialog.interaction_mode then
		self.units = PropagateObjectList(self:GatherUnits())
		local cable_recharging = IsKindOf(SelectedObj, "BaseRover")
		self.objects = PropagateObjectList(self:GatherObjects(cable_recharging))
		
		self:SetState("idle", {
			SelectObj = #self.objects > 0,
			SelectUnit = #self.units > 0,
		})
	--using UnitControl
	elseif mode_dialog:IsKindOf("UnitDirectionModeDialog") and mode_dialog.interaction_mode then
		self.objects = PropagateObjectList(self:GatherObjects("cables"))
		self:FindInteractableObj()
		--actions that require a target
		if mode_dialog.interaction_obj then
			self:SetState("action2", {
				SelectObj = #self.objects > 0,
			})
		--actions that don't require a target, but a location
		else
			self:SetState("action", {
				SelectObj = true
			})
		end
	elseif game_mode == "demolish" then
		local center = mode_dialog.box:Center()
		local obj = SelectionGamepadObj(center)
		self:SetState(obj and mode_dialog:CanDemolish(nil, obj) and "action2" or "action", { })
	end
	
	--Deselect objects that are outside the gamepad cursor
	-- do not deselect objects when moving away with camera
	-- self:CheckSelectionLost(self.last_selection)
end

function GamepadTerrainObjects:FindInteractableObj()
	local mode_dialog = GetInGameInterfaceModeDlg() or false
	if not mode_dialog or not mode_dialog:IsKindOf("UnitDirectionModeDialog") then return end
	
	local pos = GetTerrainGamepadCursor()
	mode_dialog.interaction_obj = false
		
	for i = 1, #(self.objects or "") do
		local o = self.objects[i]
		if IsValid(o) then
			mode_dialog:UpdateInteractionObj(o, pos)
			if mode_dialog.interaction_obj then
				break
			end
		end
	end
	if not mode_dialog.interaction_obj then
		mode_dialog:UpdateInteractionObj(false, pos)
	end
end

function GamepadTerrainObjects:CheckSelectionLost(sel_obj)
	sel_obj = sel_obj or self.last_selection 
	if not IsValid(sel_obj) then return end
	
	if sel_obj:HasMember("gamepad_auto_deselect") and sel_obj.gamepad_auto_deselect then
		while IsValid(sel_obj) do
			if self.units:Find(sel_obj) or self.objects:Find(sel_obj) then
				return --found, do nothing
			end
			sel_obj = sel_obj:GetParent()			
		end
		
		-- the object, or any of its parents were not found, so it's not under the cursor any more - deselect
		SelectObj()
	end
end

local StateToImage =
{
	idle = "Cursor",
	action = "CursorAction",
	action2 = "CursorAction_2",
}

function GamepadTerrainObjects:GetCursorStateImage()
	return StateToImage[self.cursor_state]
end

local ButtonToAction =
{
	ButtonA = "SelectObj",
	ButtonX = "SelectUnit",
}

function GamepadTerrainObjects:IsButtonActive(button)
	return self.actions[ButtonToAction[button]]
end

function GamepadTerrainObjects:SetState(cursor_state, actions)
	self.cursor_state = cursor_state or "idle"
	self.actions = actions or { }
	ObjModified(self)
end

function GamepadTerrainObjects:MsgPresave()
	self.disable_update = true
end

function GamepadTerrainObjects:MsgPostsave()
	self.disable_update = false
end

function OnMsg.SelectionAdded(obj)
	if not g_GamepadObjects then return end
	if not obj or not obj:HasMember("gamepad_auto_deselect") or not obj.gamepad_auto_deselect then
		g_GamepadObjects.last_selection = false
	end
end

function OnMsg.SelectionRemoved(obj)
	if not g_GamepadObjects then return end
	g_GamepadObjects.last_selection = false
end

local function PointInsideEllipse(pt, ellipse_center, width, height)
	local dx = pt:x() - ellipse_center:x()
	local dy = pt:y() - ellipse_center:y()
	
	local w2 = width * width + 1   -- to avoid division by zero
	local h2 = height * height + 1 -- to avoid division by zero
	
	return (MulDivTrunc(1000 * dx, dx, w2) + MulDivTrunc(1000 * dy, dy, h2)) <= 1000
end

-- checks if a point lies in the cursor ellipse
function GamepadTerrainObjects:PointInside(pt, width)
	if not pt:IsValid() then
		assert(pt == InvalidPos())
		return false
	end
	
	local xcursor = GetGamepadCursor()
	if not xcursor then
		return false
	end
	
	width = width or self.width
	local xcursor_box = xcursor.box
	local xcursor_sizey = xcursor_box:sizey()
	if xcursor_sizey > 0 then
		local aspect = MulDivRound(xcursor_box:sizex(), 1000, xcursor_box:sizey())
		local height = MulDivRound(width, aspect, 1000)
		
		return PointInsideEllipse(pt, self.pos, width, height)
	else
		return false
	end
end

local function propagate_object_list(list)
	local objset = { }
	local result = { }
	for i=1,#list do
		local obj = SelectionPropagate(list[i])
		if IsValid(obj) and not objset[obj] then
			objset[obj] = true
			result[#result + 1] = obj
		end
	end
	
	return result
end

local UnitClasses = {"Drone", "Colonist"}
function GamepadTerrainObjects:GatherUnits()
	local objs = { }
	self:GatherObjectsOfTypes(objs, UnitClasses, nil)
	
	--@@@msg GamepadGatherSelectedUnits,gamepad_terrain_objects, objects- use this message to queue custom units for gamepad selection.
	Msg("GamepadGatherSelectedUnits", self, objs)
	
	return propagate_object_list(objs)
end

local SelectionClasses = {"ResourceStockpileBase", "Deposit", "Unit", "AlienDigger"}
function GamepadTerrainObjects:GatherObjects(...)
	--gather standard objects
	local objs = { }
	self:GatherBuildings(objs, ...)
	self:GatherObjectsUnderCursor(objs, "FlyingObject")
	self:GatherObjectsOfTypes(objs, SelectionClasses, "Drone", "Colonist", "FlyingObject")
	
	--@@@msg GamepadGatherSelectedObjects,gamepad_terrain_objects, objects- use this message to queue custom big objects for gamepad selection.
	Msg("GamepadGatherSelectedObjects", self, objs)
	
	return propagate_object_list(objs)
end

function GamepadTerrainObjects:FilterBuilding(obj, include_cables)
	if IsKindOf(obj, "DomeInterior") then
		obj = obj.dome
	end
	
	if IsKindOf(obj, "Building") and not obj.disable_selection then
		local propagated_obj = SelectionPropagate(obj)
		obj = IsKindOf(propagated_obj, "Building") and propagated_obj or obj
		return obj
	elseif IsKindOf(obj, "SupplyGridSwitch") and obj.is_switch then
		return obj
	elseif include_cables and IsKindOf(obj, "ElectricityGridElement") then
		return obj
	elseif IsKindOf(obj, "LifeSupportGridElement") and obj.pillar then
		return obj
	elseif IsKindOf(obj, "ToxicPool") and obj:CanBeCleaned() then
		return obj
	end
end

local building_additional_range = const.GridSpacing*2/3
function GamepadTerrainObjects:GatherBuildings(buildings, cables)
	local xpos, width = self.pos, self.width
	local range = Clamp((width + building_additional_range) / const.GridSpacing, 0, 8)
	
	local blds
	local q, r = WorldToHex(xpos)
	local object_hex_grid = GetActiveObjectHexGrid()
	if range == 0 then
		blds = object_hex_grid:GetObjects(q, r)
	else
		blds = HexGridGetObjectsInRange(object_hex_grid.grid, q, r, range)
	end
	
	--handle buildings
	for i=1,#blds do
		local bld = blds[i]
		if bld:GetVisible() then
			bld = self:FilterBuilding(bld, cables)
			if bld then
				table.insert_unique(buildings, bld)
			end
		end
	end
		
	--look for rockets and treat them as buildings
	self:GatherObjectsOfTypes(buildings, "RocketBase")
end

function GamepadTerrainObjects:GatherObjectsUnderCursor(objs, ...)
	--precise, but slow - use only for low number of objects
	local cursor_point1  = camera.GetEye()
	local cursor_point2  = GetTerrainGamepadCursor()
	local cursor_radius = 20*guim
	local candidates = MapGet(cursor_point1, cursor_point2, cursor_radius, ...)
	
	local xcursor_box = GetGamepadCursor().box
	local center = xcursor_box:Center()
	local width, height = xcursor_box:sizexyz()
	
	local obj = ClosestObjInsideEllipse(candidates, empty_table, center, width/2, height/2)
	if obj then
		table.insert_unique(objs, obj)
	end
end

function GamepadTerrainObjects:GatherObjectsOfTypes(objs, classes, ...)
	--12 meters is the maximum step length that the pathfinder allows (bug:0132040)
	local query_width = self.width + 12 * guim
	local query_filter = function(obj, gamepad_objs, width, ...)
		local pos = obj:GetVisualPos()
		if not GetActiveTerrain():IsPointInBounds(pos) or IsKindOfClasses(obj, ...) then
			return false
		end
		return gamepad_objs:PointInside(pos, width)
	end
	local new_objs = MapGet(self.pos, query_width, classes, const.efSelectable + const.efVisible, query_filter, self, query_width, ...)
	for i=1,#new_objs do
		table.insert_unique(objs, new_objs[i])
	end
end

local function GetNextObj(list, obj)
	return list[(table.find(list, obj) or 0) + 1] or list[1] or false
end

function GamepadTerrainObjects:GetNextClosestUnit(current_unit)
	return GetNextObj(table.validate(self.units), current_unit)
end

function GamepadTerrainObjects:GetNextClosestObject(current_object)
	return GetNextObj(table.validate(self.objects), current_object)
end

function GamepadTerrainObjects:GetObject()
	local closest_obj = self:GetNextClosestObject(SelectedObj)
	local obj = SelectionPropagate(closest_obj)
	self.last_selection = obj
	return obj
end

function GamepadTerrainObjects:GetUnit()
	local closest_unit = self:GetNextClosestUnit(SelectedObj)
	local obj = SelectionPropagate(closest_unit)
	self.last_selection = obj
	return obj
end

function SelectionPropagate(obj)
	local topmost = GetTopmostParent(obj)
	local prev = topmost
	while IsValid(topmost) and topmost:HasMember("SelectionPropagate") do
		topmost = topmost:SelectionPropagate()
		if prev == topmost then break end
		prev = topmost or prev
	end
	return prev
end
