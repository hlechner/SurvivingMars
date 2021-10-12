SafariRouteInsertWaypointHandler = {
	insert_after_index = 0,
}

function SafariRouteInsertWaypointHandler:UpdateCursorText(dialog)
	if dialog.created_route and #dialog.created_route > 0 then
		local next_route = table.copy(dialog.created_route)
		table.insert(next_route, self.insert_after_index + 1, GetCursorWorldPos())
		
		local length = CalculateRouteLength(next_route)
		if length < MaxRouteLength then
			return T(12747, "Route Length: ") .. Untranslated(length)
		else
			return T(12748, "Route too long!")
		end
	end
	return T(12749, "Select Start")
end

function SafariRouteInsertWaypointHandler:UpdateTooltip(dialog)
end

function SafariRouteInsertWaypointHandler:UpdateRouteVisuals(dialog)
	UpdateSafariRouteVisuals(dialog)
end

function SafariRouteInsertWaypointHandler:CreateRoute(dialog, terrain_pt)
	if ValidPointForRoute(dialog.created_route, terrain_pt) then
		table.insert(dialog.created_route, self.insert_after_index + 1, terrain_pt)
		dialog:UpdateCursorText()
		UnitControlCreateRoute(dialog.unit)
	end
end

function SafariRouteInsertWaypointHandler:OnRouteCreated(dialog)
	CreateSafariRoute(dialog)
end

function SafariRouteInsertWaypointHandler:UpdateCursorObj(dialog, pos)
	if not dialog.cursor_obj then
		HideGamepadCursor("construction")
		dialog.cursor_obj = PlaceObjectIn("WireFramedPrettification", ActiveMapID, {entity = "RoverSafari", construction_stage = 0, GetSelectionRadiusScale = RCTransport_AutoRouteRadius})
		dialog.cursor_obj:SetAngle(0)
	end
	dialog.cursor_obj:SetPos(pos:SetTerrainZ(1*guim))
end