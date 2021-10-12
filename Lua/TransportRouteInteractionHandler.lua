TransportRouteInteractionHandler = {}
function TransportRouteInteractionHandler:NewRoute()
	return {from = false, to = false, obj_at_source = false}
end
function TransportRouteInteractionHandler:UpdateCursorText(dialog)
	local res_dlg = GetDialog("ResourceItems")
	local choosing_res = res_dlg and res_dlg.context and IsKindOf(res_dlg.context.object, "RCTransport")
	if not choosing_res then
		if not (dialog.created_route and dialog.created_route.from) then
			return T(7974, "Load Resource")
		else
			return T(7975, "Unload Resource")
		end
	end
end
	
function TransportRouteInteractionHandler:UpdateTooltip(dialog)
end

function TransportRouteInteractionHandler:UpdateRouteVisuals(dialog)
	if dialog.created_route and dialog.created_route.from and not dialog.created_route.to then
		if not dialog.route_visuals then
			dialog.route_visuals = { PlaceObjectIn("WireFramedPrettification", ActiveMapID, {entity = "RoverTransport", construction_stage = 0, GetSelectionRadiusScale = RCTransport_AutoRouteRadius}) }
			dialog.route_visuals[1]:SetAngle(0)
			ShowHexRanges(UICity, false, dialog.route_visuals[1])
			if IsValid(dialog.cursor_obj) then
				DoneObject(dialog.cursor_obj)
				dialog.cursor_obj = false
			end
		end
		dialog.route_visuals[1]:SetPos(dialog.created_route.from)
		--dialog.route_visuals:SetAngle(CalcOrientation(dialog.created_route.from, dialog.last_mouse_pos or point20))
	elseif not dialog.created_route or dialog.created_route and not dialog.created_route.from and not dialog.created_route.to then
		if dialog.route_visuals then
			DoneObjects(dialog.route_visuals)
			dialog.route_visuals = false
		end
	end
end

function TransportRouteInteractionHandler:CreateRoute(dialog, terrain_pt)
	if not dialog.created_route.from then
		if dialog.interaction_obj ~= dialog.created_route.obj_at_source then
			dialog.created_route.obj_at_source = dialog.interaction_obj
		end
		CityUnitController[UICity]:InteractWithObject(dialog.interaction_obj, dialog.interaction_mode)
		self:SetRoutePoint(dialog, "from", terrain_pt or GetTerrainCursor())
	else
		self:SetRoutePoint(dialog, "to", terrain_pt or GetTerrainCursor())
	end
	dialog:UpdateCursorText()
end

function TransportRouteInteractionHandler:OnRouteCreated(dialog)
	if dialog.created_route and dialog.created_route.from and dialog.created_route.to then
		CityUnitController[UICity]:SetTransportRoute(dialog.created_route)
		dialog.created_route = false
		SetUnitControlInteractionMode(dialog.unit, false)
		DoneObjects(dialog.route_visuals)
		dialog.route_visuals = false
		SetupRouteVisualsForTransport(dialog.unit)
		if self:IsThreadRunning("GamepadCursorUpdate") then
			self:DeleteThread("GamepadCursorUpdate")
		end
		if GetUIStyleGamepad() then
			self:UpdateCursorObj()
		end		
	end
end

function TransportRouteInteractionHandler:SetRoutePoint(dialog, type, pt)
	assert(dialog.created_route)
	if not dialog.created_route then
		return
	end
	
	dialog.created_route[type] = pt:SetTerrainZ(1*guim)

	if dialog.created_route.from and dialog.created_route.to then
		if dialog.created_route and dialog.created_route.from and dialog.created_route.to then
			CityUnitController[UICity]:SetTransportRoute(dialog.created_route)
			dialog.created_route = false
			SetUnitControlInteractionMode(dialog.unit, false)
			DoneObjects(dialog.route_visuals)
			dialog.route_visuals = false
			SetupRouteVisualsForTransport(dialog.unit)
			if dialog:IsThreadRunning("GamepadCursorUpdate") then
				dialog:DeleteThread("GamepadCursorUpdate")
			end
			if GetUIStyleGamepad() then
				dialog:UpdateCursorObj()
			end		
		end
	else
		self:UpdateRouteVisuals(dialog)
	end
end

function TransportRouteInteractionHandler:UpdateCursorObj(dialog, pos)
	--cursor obj management
	if not dialog.created_route.from and not dialog.cursor_obj then
		HideGamepadCursor("construction")
		dialog.cursor_obj = PlaceObjectIn("WireFramedPrettification", ActiveMapID, {entity = "RoverTransport", construction_stage = 0, GetSelectionRadiusScale = RCTransport_AutoRouteRadius})
		dialog.cursor_obj:SetAngle(0)
		local rad = PlaceObjectIn("RangeHexMovableRadius", ActiveMapID)
		dialog.cursor_obj:Attach(rad)
		rad:SetScale(RCTransport_AutoRouteRadius)
	elseif not dialog.created_route.from and dialog.cursor_obj.construction_stage == 1 then
		dialog.cursor_obj.construction_stage = 0
		dialog.cursor_obj:UpdateConstructionShaderParams()
	elseif dialog.created_route.from and not dialog.cursor_obj then
		HideGamepadCursor("construction")
		dialog.cursor_obj = PlaceObjectIn("WireFramedPrettification", ActiveMapID, {entity = "RoverTransport", construction_stage = 1, GetSelectionRadiusScale = RCTransport_AutoRouteRadius})
		dialog.cursor_obj:SetAngle(0)
		local rad = PlaceObjectIn("RangeHexMovableRadius", ActiveMapID)
		dialog.cursor_obj:Attach(rad)
		rad:SetScale(RCTransport_AutoRouteRadius)
	elseif dialog.created_route.from and dialog.cursor_obj.construction_stage == 0 then
		dialog.cursor_obj.construction_stage = 1
		dialog.cursor_obj:UpdateConstructionShaderParams()
	end
	dialog.cursor_obj:SetPos(pos:SetTerrainZ(1*guim))
end