DefineClass.RCSafari = {
	__parents = {  "BaseRover", "ServiceBase", "ComponentAttach", },
	SelectionClass = "RCSafari",
	use_shape_selection = false,

	flags = { gofPermanent = true },

	properties = {
			{ template = true, name = T(765, "Pin Rollover"), id = "pin_rollover", category = "Pin",  editor = "text", translate = true, dont_save = true},
			{ id = "max_passengers", default = 10, scale = 1, name = T(12764, "Max passengers"), modifiable = true, editor = "number" , no_edit = true},
		},

	gamepad_auto_deselect = false,

	entity = "RoverSafari",
	work_spot_task = "Workrover",
	work_spot_deposit = "Workrover",
	work_spot_drone_recharge = "Workrover",
	work_spot_drone_repair = "Workrover",
	
	fx_actor_class = "RCSafari",
	
	--route
	safari_route = false, --[ from, ..., end ]
	waiting_to_start = false,
	visitors_on_their_way = false,
	visit_duration = 20, -- This is the maximum time tourists will stay on the safari.
	
	max_visitors = 12,
	usable_by_children = true,
	
	--resolve inheritance
	GetShapePoints = DroneBase.GetShapePoints,
	GetDisplayName = DroneBase.GetDisplayName,
	GetModifiedBSphereRadius = UngridedObstacle.GetModifiedBSphereRadius,
	priority = 3,
	DroneApproach = BaseRover.DroneApproach,
	DroneCanApproach = BaseRover.DroneCanApproach,
	reveal_range = 180,

	--ui
	display_name = T(12765, "RC Safari"),
	display_name_pl = T(12766, "RC Safaris"),
	description = T(12767, "Remote-controlled vehicle that takes Tourists on a Safari. Configure a route with waypoints near interesting sights to increase the Satisfaction awarded to Tourists."),
	display_icon = "UI/Icons/Buildings/rover_safari.tga",
	
	malfunction_start_state = "malfunction",
	malfunction_idle_state = "malfunctionIdle",
	malfunction_end_state = "malfunctionEnd",
	
	accumulate_maintenance_points = false,
	
	pin_rollover = T(12767, "Remote-controlled vehicle that takes Tourists on a Safari. Configure a route with waypoints near interesting sights to increase the Satisfaction awarded to Tourists."),
	encyclopedia_id = "RCSafari",
	prio_button = false,

	palette = {"rover_accent","rover_base","rover_dark","none"} ,
	
	ui_data_propagate = false, --when switching overview, using this to propagate route data.
	
	track_anim_moments = false,
	track_anim_moments_thread = false,
	amount_transfered_last_ct = 0,
	
	Select = BaseRover.Select,

	sight_range = 8,
	awarded_satisfaction = false,
	unknown_string = T(12896, "??"),
	last_awarded_satisfaction = T(12896, "??"),
	
	use_demolished_state = false,
	count_as_building = false,

	environment_entity = {
		base = "RoverSafari",
	}
}

function RCSafari:GameInit()
	self.safari_route = {}
	self.visitors_on_their_way = {}
end

function RCSafari:Done()
	DestroySafariRouteVisuals(self)
end

function RCSafari:Idle()
	self:Gossip("Idle")
	self:SetState("idle")
	Halt()
end

function RCSafari:ShouldShowRouteButton()
	return true
end

function RCSafari:EnterCreateRouteMode()
	local unit_ctrl_dlg = GetInGameInterfaceModeDlg()
	SetUnitControlInteractionMode(self, "route", SafariRouteInteractionHandler)
	unit_ctrl_dlg:SetFocus(true)
end

function RCSafari:ExitCreateRouteMode()
	UnitControlCreateRoute(self)
	SetUnitControlInteractionMode(self, false)
end

function RCSafari:ToggleCreateRouteMode()
	local unit_ctrl_dlg = GetInGameInterfaceModeDlg()
	assert(unit_ctrl_dlg:IsKindOf("UnitDirectionModeDialog"))

	if not self:CanBeControlled() then return end
	
	--ignore the button while c is down
	if terminal.IsKeyPressed(const.vkC) then return end
	if unit_ctrl_dlg.unit ~= self then return end
	
	local v = unit_ctrl_dlg.interaction_mode ~= "route" and "route" or false
	if v then
		self:EnterCreateRouteMode()
	else
		self:ExitCreateRouteMode()
	end
	
	unit_ctrl_dlg:SetCreateRouteMode(v)
	RebuildInfopanel(self)
end

function RCSafari:ToggleCreateRouteMode_Update(button)
	local to_mode = self.interaction_mode ~= "route"
	button:SetIcon(to_mode and "UI/Icons/IPButtons/transport_route.tga" or "UI/Icons/IPButtons/cancel.tga")
	button:SetEnabled(self:CanBeControlled())
	button:SetRolloverTitle(T(12768, "Create Safari Route"))
	button:SetRolloverText(T(12769, "Create a safari route. Add waypoints that the RC Safari will travel between. Ensure the starting point is close to a Dome so Tourists can board the vehicle. Click on the first waypoint to <em>Finish Route</em>"))
	button:SetRolloverHint(to_mode and T(7555, "<left_click> Create route mode") 
		or T(7408, "<left_click>Set Source  <em><left_click> (again)</em> Set Destination<newline><right_click> Cancel"))
	button:SetRolloverHintGamepad(to_mode and T(7556, "<ButtonA> Create route mode") or T(7512, "<ButtonA> Cancel"))
end

function RCSafari:ClearRoute()
	self.safari_route = nil
	ReopenInfoPanel(self)
	DestroySafariRouteVisuals(self)
	self:SetCommand("Idle")
end

function RCSafari:ClearRoute_Update(button)
	button:SetIcon("UI/Icons/IPButtons/cancel.tga")
	button:SetEnabled(self.safari_route ~= false and #self.safari_route > 0)
	button:SetRolloverTitle(T(12770, "Clear Safari Route"))
	button:SetRolloverText(T(12771, "Clears route and stops the vehicle"))
	button:SetRolloverHint(T(12772, "<left_click> Clear Safari Route"))
	button:SetRolloverHintGamepad(T(12773, "<ButtonA> Clear Safari Route"))
end

function RCSafari:SetSafariRoute(route)
	self:SetCommand("RunSafariRoute", route)
end

function RCSafari:HasCompletedTestTrip()
	return self.last_awarded_satisfaction ~= self.unknown_string
end

function RCSafari:AreVisitorsOnTheirWay()
	return self.visitors_on_their_way and #self.visitors_on_their_way > 0
end

function RCSafari:Wait(wait_time)
	self:SetState("idle")
	Sleep(wait_time)
	self:SetState("moveWalk")
end

function RCSafari:DisembarkAllVisitors()
	for _,tourist in ipairs(self.visitors) do
		tourist:InterruptVisit()
	end
end

function RCSafari:DetachFromRealm()
	self:DisembarkAllVisitors()
end

local minimalWaitTime = 5000
local timeBetweenVisitorChecks = 2000
local timeAtEachWaypoint = 1000
function RCSafari:RunSafariRoute(route)
	if not route then
		return 
	end
	
	self:PushDestructor(function(self)
		self.safari_route = nil
		ReopenInfoPanel(self)
		DestroySafariRouteVisuals(self)
		self.last_awarded_satisfaction = self.unknown_string
		self:DisembarkAllVisitors()
	end)
	self.safari_route = route
	ReopenInfoPanel(self)
	SetupRouteVisualsForSafari(self)
	
	while IsValid(self) and self.safari_route do
		for i,pos in ipairs(self.safari_route) do
			self:Goto(pos)
			if i == 1 then
				self.awarded_satisfaction = false
				self.seen_sights = false
				self.waiting_to_start = true

				self:Wait(minimalWaitTime)
				
				while (self:HasCompletedTestTrip() and #self.visitors < 1) or self:AreVisitorsOnTheirWay() do
					self:Wait(timeBetweenVisitorChecks)
				end
				
				self.waiting_to_start = false
			end
			ObserveSights(self)
			self:Wait(timeAtEachWaypoint)
		end
		
		self:Goto(self.safari_route[1])
		if self.awarded_satisfaction then
			self.last_awarded_satisfaction = self.awarded_satisfaction.total
		end
		
		self:DisembarkAllVisitors()
	end
end

function RCSafari:GetDisplayName()
	return Untranslated(self.name)
end

GlobalVar("transport_route_wireframes", { })
GlobalVar("transport_route_labels", {})

function SetupRouteVisualsForSafari(obj)
	local route = obj.safari_route
	
	if not route then return end
	
	if transport_route_wireframes[obj] then
		DestroySafariRouteVisuals(obj)
	end

	local new_wireframes = {}
	transport_route_wireframes[obj] = new_wireframes
	local new_texts = {}
	transport_route_labels[obj] = new_texts
	
	for i,pos in ipairs(route) do
		new_wireframes[i] = PlaceObjectIn("WireFramedPrettification", obj:GetMapID(), {
			entity = "RoverSafari",
			construction_stage = 0,
		})
		new_wireframes[i]:SetPos(pos)
		
		new_texts[i] = CreateWaypointLabel(i)
		new_texts[i]:SetPos(pos:SetZ(pos:z()))
		
		assert(#route > 1)
		local next_pos = (i < #route and route[i+1] or route[1])
		local angle = CalcOrientation(pos, next_pos)
		new_wireframes[i]:SetAngle(angle)
	end
end

function OnMsg.SelectionAdded(obj)
	if IsKindOf(obj, "RCSafari") then
		SetupRouteVisualsForSafari(obj)
	end
end

function DestroySafariRouteVisuals(obj)
	local visuals = transport_route_wireframes[obj]
	if visuals then
		DoneObjects(visuals)
	end
	transport_route_wireframes[obj] = nil
	
	local texts = transport_route_labels[obj]
	if texts then
		DoneObjects(texts)
	end
	transport_route_labels[obj] = nil
end

function OnMsg.SelectionRemoved(obj)
	DestroySafariRouteVisuals(obj)
end

function RCSafari:Assign(unit)
	table.insert(self.visitors_on_their_way, unit)
	ServiceBase.Assign(self, unit)
end

function RCSafari:Unassign(unit)
	if table.find(self.visitors_on_their_way, unit) then
		table.remove_entry(self.visitors_on_their_way, unit)
	end
	ServiceBase.Unassign(self, unit)
end

function RCSafari:Service(unit, duration)
	if not self.waiting_to_start then return end
	
	if unit.daily_interest == "interestSafari" then
		unit.daily_interest = ""
	end
	table.remove_entry(self.visitors_on_their_way, unit)
	duration = ServiceBase.Service(self, unit, duration)
	
	if duration then
		unit:PlayPrg(nil, duration, self)
	end
end

function RCSafari:GetEntrance(target, entrance_type, spot_name, unit)
	return self:GetEntranceFallbackUncached()
end

function RCSafari:InsertWaypointAfter(waypoint_index)
	local unit_ctrl_dlg = GetInGameInterfaceModeDlg()
	SafariRouteInsertWaypointHandler.insert_after_index = waypoint_index
	SetUnitControlInteractionMode(self, "route", SafariRouteInsertWaypointHandler, self.safari_route)
	unit_ctrl_dlg:SetFocus(true)
end

function RCSafari:MoveWaypoint(waypoint_index)
	local unit_ctrl_dlg = GetInGameInterfaceModeDlg()
	SafariRouteMoveWaypointHandler.moved_waypoint_index = waypoint_index
	local route = table.copy(self.safari_route)
	table.remove(route, waypoint_index)
	SetUnitControlInteractionMode(self, "route", SafariRouteMoveWaypointHandler, route)
	unit_ctrl_dlg:SetFocus(true)
end

function RCSafari:CanBeUsedBy(unit)
	if self.waiting_to_start and self.safari_route then
		return ServiceBase.CanBeUsedBy(self, unit)
	end
	return false, 2 -- 2 means closed
end

function CreateWaypointLabel(index)
	assert(1 <= index and index <= 10)
	return g_Classes["ArrowWaypoint"..index]:new()
end

function SavegameFixups.RCSafariBuilding()
	MapForEach(true, "RCSafari", function(o)
		DeleteThread(o.update_thread)
	end)
end
