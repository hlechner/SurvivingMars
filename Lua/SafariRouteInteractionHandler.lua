SafariRouteInteractionHandler = {}
function SafariRouteInteractionHandler:NewRoute()
	return {}
end

function CalculateRouteLength(route)
	assert(#route > 1)
	
	local length = 0
	for i,pos in ipairs(route) do
		local next_pos = (i < #route and route[i+1] or route[1])
		length = length + HexAxialDistance(pos, next_pos)
	end
	return length
end

function ValidPointForRoute(route, point)
	for _,route_pt in ipairs(route) do
		if HexAxialDistance(route_pt, point) < 1 then
			return false
		end
	end
	return true
end

function ReopenInfoPanel(unit)
	CloseXInfopanel()
	OpenXInfopanel(nil, unit)
end

MaxRouteLength = 300
function UpdateSafariRouteVisuals(dialog)
	if dialog.created_route then
		if not dialog.route_visuals then dialog.route_visuals = {} end
		if not dialog.route_texts then dialog.route_texts = {} end
		for i,pos in ipairs(dialog.created_route) do
			if not dialog.route_visuals[i] then
				dialog.route_visuals[i] = PlaceObjectIn("WireFramedPrettification", ActiveMapID, {entity = "RoverSafari", construction_stage = 0, GetSelectionRadiusScale = 0})
				dialog.route_texts[i] = CreateWaypointLabel(i)
				
				dialog.route_visuals[i]:SetAngle(0)
				ShowHexRanges(UICity, false, dialog.route_visuals[i])
				if IsValid(dialog.cursor_obj) then
					DoneObject(dialog.cursor_obj)
					dialog.cursor_obj = false
				end
			end
			dialog.route_visuals[i]:SetPos(pos)
			dialog.route_texts[i]:SetPos(pos:SetZ(pos:z()))
		end
	else
		if dialog.route_visuals then
			DoneObjects(dialog.route_visuals)
			dialog.route_visuals = false
			DoneObjects(dialog.route_texts)
			dialog.route_texts = false
		end
	end
end

function CreateSafariRoute(dialog)
	if not dialog.created_route then return end
	
	if #dialog.created_route > 1 and CalculateRouteLength(dialog.created_route) < MaxRouteLength then
		CityUnitController[UICity]:SetSafariRoute(dialog.created_route)
	end
	
	dialog.created_route = false
	SetUnitControlInteractionMode(dialog.unit, false)
	if dialog.route_visuals then
		DoneObjects(dialog.route_visuals)
	end
	
	dialog.route_visuals = false
	if dialog.route_texts then
		DoneObjects(dialog.route_texts)
	end
	
	dialog.route_texts = false
	SetupRouteVisualsForSafari(dialog.unit)
	if dialog:IsThreadRunning("GamepadCursorUpdate") then
		dialog:DeleteThread("GamepadCursorUpdate")
	end
	if GetUIStyleGamepad() then
		dialog:UpdateCursorObj()
	end
end

local near_start_finish_radius = const.HexHeight
function SafariRouteInteractionHandler:GetCursorTextHeader(dialog)
	if not dialog.created_route or #dialog.created_route == 0 then
		return T(12749, "Select Start")
	end
	
	local terrain_pt = GetCursorWorldPos()
	if terrain_pt:Dist(dialog.created_route[1]) < near_start_finish_radius then
		return T(12750, "<em>Finish Route</em>")
	end
	
	local next_route = table.copy(dialog.created_route)
	table.insert(next_route, terrain_pt)
	local length = CalculateRouteLength(next_route)
	if length < MaxRouteLength then
		return T(12747, "Route Length: ") .. Untranslated(length)
	else
		return T(12748, "Route too long!")
	end
end

function SafariRouteInteractionHandler:UpdateCursorText(dialog)
	return self:GetCursorTextHeader(dialog) .. Untranslated("\n")
end

function GetSightsTooltipText(sights)
	local text = ""
	for _, sight in ipairs(sights) do
		text = text .. sight:GetName() .. Untranslated("\n")
	end
	return text
end

function ShowTooltip(show)
	local control = GetHUD().idSightsStatus
	control:SetVisible(show)

	-- We have to hide the children aswell
	control.idBackground:SetVisible(show)
	control.idTitle:SetVisible(show)
	control.idContent:SetVisible(show)
end

function SafariRouteInteractionHandler:UpdateTooltip(dialog)
	local realm = ActiveGameMap.realm
	local terrain_pt = GetCursorWorldPos()
	local sights = GetVisibleSights(realm, terrain_pt, dialog.unit.sight_range)
	
	if #sights > 0 then
		ShowTooltip(true)
		local text = GetSightsTooltipText(sights)
		GetHUD().idSightsStatus.idContent:SetText(text)
	else
		ShowTooltip(false)
	end	
end

function SafariRouteInteractionHandler:UpdateRouteVisuals(dialog)
	UpdateSafariRouteVisuals(dialog)
end

function SafariRouteInteractionHandler:CreateRoute(dialog, terrain_pt)
	if dialog.created_route[1] and terrain_pt:Dist(dialog.created_route[1]) < near_start_finish_radius then
		CreateSafariRoute(dialog)
		return
	end

	if ValidPointForRoute(dialog.created_route, terrain_pt) then
		self:AddRoutePoint(dialog, terrain_pt or GetCursorWorldPos())
		dialog:UpdateCursorText()
		
		if #dialog.created_route == g_Consts.RCSafariMaxWaypoints then
			CreateSafariRoute(dialog)
		end
	end
end

function SafariRouteInteractionHandler:OnRouteCreated(dialog)
	CreateSafariRoute(dialog)
end

function SafariRouteInteractionHandler:AddRoutePoint(dialog, pt)
	assert(dialog.created_route)
	if not dialog.created_route then
		return
	end
	
	dialog.created_route[#dialog.created_route+1] = pt:SetTerrainZ(1*guim)
	self:UpdateRouteVisuals(dialog)
end

function SafariRouteInteractionHandler:UpdateCursorObj(dialog, pos)
	if not dialog.cursor_obj then
		HideGamepadCursor("construction")
		dialog.cursor_obj = PlaceObjectIn("WireFramedPrettification", ActiveMapID, {entity = "RoverSafari", construction_stage = 0, GetSelectionRadiusScale = RCTransport_AutoRouteRadius})
		dialog.cursor_obj:SetAngle(0)
	end
	dialog.cursor_obj:SetPos(pos:SetTerrainZ(1*guim))
end