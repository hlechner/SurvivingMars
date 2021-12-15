DefineClass.RocketBase = {
	__parents = { "PinnableObject", "UniversalStorageDepot", "DroneControl", "WaypointsObj", "Renamable", "RechargeStationBase", "CommandObject", "CargoTransporter"},
		
	properties = {
		{ category = "Rocket", id = "name", name = T(1000037, "Name"), editor = "text", default = ""},
		{ template = true, category = "Rocket", name = T(702, "Launch Fuel"),      	id = "launch_fuel",      	editor = "number", default = 10*const.ResourceScale, min = 0*const.ResourceScale, max = 1000*const.ResourceScale, scale = const.ResourceScale, modifiable = true, help = "The amount of fuel it takes to launch the rocket.",},	
		{ template = true, category = "Rocket", name = T(11993, "Launch Fuel Expedition"),      	id = "launch_fuel_expedition",      	editor = "number", default = 0, min = 0*const.ResourceScale, max = 1000*const.ResourceScale, scale = const.ResourceScale, modifiable = true, help = "The amount of fuel it takes to launch the rocket for expedition.",},	
		{ template = true, category = "Rocket", name = T(758, "Max Export Storage"), id = "max_export_storage", editor = "number", scale = const.ResourceScale, default = 100*const.ResourceScale, min = 0, modifiable = true },
		{ template = true, category = "Rocket", name = T(8457, "Passenger Orbit Lifetime"), id = "passenger_orbit_life",      	editor = "number", default = 120*const.HourDuration, min = 1*const.HourDuration, scale = const.HourDuration, modifiable = true, help = "Passengers on board will die if the rocket doesn't land this many hours after arriving in orbit.",},
		{ template = true, category = "Rocket", name = T(9830, "Sponsor Selectable"), id = "sponsor_selectable", editor = "bool", default = true },
		{ template = true, category = "Rocket", name = T(9831, "Travel Time (to Mars)"), id = "custom_travel_time_mars", editor = "number", default = 0, scale = const.HourDuration },
		{ template = true, category = "Rocket", name = T(9832, "Travel Time (to Earth)"), id = "custom_travel_time_earth", editor = "number", default = 0, scale = const.HourDuration },
		
		{ id = "landed",	editor = "bool", default = false, no_edit = true }, -- true if working on Mars (controlling drones)
		{ id = "auto_export",	editor = "bool", default = false, no_edit = true },
		{ id = "allow_export",	editor = "bool", default = true, no_edit = true },
		{ id = "reserved_site", editor = "bool", default = false, no_edit = true },
		{ id = "landing_site", editor = "object", default = false, no_edit = true },
		{ id = "site_particle", editor = "object", default = false, no_edit = true },
	},
	
	display_icon = "UI/Icons/Buildings/orbital_probe.tga",
	pin_rollover = T(8030, "Carries supplies or passengers  from Earth. Can travel back to Earth when refueled."),
	pin_rollover_hint = T(7351, "<left_click> Place Rocket"),
	pin_rollover_hint_xbox = T(7352, "<ButtonA> Place Rocket"),
	pin_progress_value = "",
	pin_progress_max = "",
	pin_obvious_blink = true,
	show_pin_toggle = false,
	
	pin_rollover_arriving = T(707, "<RocketType><newline><image UI/Icons/pin_rocket_incoming.tga 1500>Travelling to Mars.<newline>Flight progress: <em><ArrivalTimePercent></em>%.<newline>Payload:<newline><CargoManifest>"),
	pin_rollover_in_orbit = T(710, "<image UI/Icons/pin_rocket_orbiting.tga 1500>Ready to land.<newline>Payload:<newline><CargoManifest>"),

	-- landing/takeoff parameters
	orbital_altitude = 2500*guim,
	orbital_velocity = 100*guim,
	-- second set for the first rocket
	orbital_altitude_first = 400*guim,
	orbital_velocity_first = 43*guim,	
	warm_up = 10000,
	
	-- pre-hit ground moments, all are relative to hit-ground
	pre_hit_ground = 10000,
	pre_hit_ground2 = 13000,
	pre_hit_groud_decal = 0,
	
	warm_down = 1000,
	fx_actor_base_class = "FXRocket",
	fx_actor_class = "SupplyRocket",
	show_logo = true,
	rocket_palette = { "rocket_base", "rocket_accent", "outside_dark", "outside_dark" }, -- "RocketStandard",
	landing_site_class = "RocketLandingSite",
	disembark_anim = "disembarkRocket",
	disembark_anim_walk = "disembarkRocket2",
	
	show_service_area = true,
	service_area_min = const.CommandCenterMinRadius,
	service_area_max = const.CommandCenterDefaultRadius,
	
	accumulate_dust = false,
	maintenance_resource_type = "no_maintenance", --doesnt require maintenance.
	accumulate_maintenance_points = false,
	use_shape_selection = false,
	default_label = false,

	cargo = false,
	placement = false,
	rovers = false,
	departures = false,
	boarding = false,
	boarded = false,
	disembarking = false,
	disembarking_confused = false,
	residence_search_radius = 1500*guim, -- radius around which to search for domes with free residences upon ordering	
	arrival_time = false,
	arrival_time_earth = false,
	first_arrival = false,
	status = false,
	category = false, -- cargo, passenger, founder, etc.
	orbit_arrive_time = false,
	owned = true,
	
	pin_status_img = false,
	is_demolishable_state = false, -- updated as the status updates
	
	-- ui related
	launch_time = false,
	flight_time = false,
	
	--drone control
	starting_drones = 0,
	working = false,
	drone_entry_spot = "Dronein", --where the drone should be to start the embark visuals.
	drone_spawn_spot = "Roverdock2",
	distance_to_provoke_go_home_cmd = 80 * guim,	
	auto_connect = false,
	
	--storage
	max_storage_per_resource = 60 * const.ResourceScale, --how much the rocket can hold as storage
	storable_resources = {"Concrete", "Metals", "Polymers", "Food", "Electronics", "MachineParts",},
	--refuel/export
	refuel_request = false,
	export_requests = false,
	unload_request = false,
	unload_fuel_request = false,
	exported_amount = false,
	custom_id = false,
	launch_after_unload = false,
	
	exclude_from_lr_transportation = true,
	
	drones_entering = false,
	drones_exiting = false,
	
	--enable/disable landing/launch, maintenance
	maintenance_request = false, -- false or a table with expedition params
	maintenance_requirements = {},
	landing_disabled = false,
	launch_disabled = false,
	
	--land/launch dust
	total_dust_time = 5000, --it will dust total_dust_time time before land and total_dust_time time after launch
	dust_tick = 100, --tick between dust application
	dust_radius = 10, --in hexes
	total_launch_dust_amount = 120000, --the total amount of dust applied during launch
	total_land_dust_amount = 120000, --the total amount of dust applied during landing
	
	decal_fade_time = 50*const.DayDuration,
	
	dust_thread = false,
	
	departure_tick = 1000 * 30,
	departure_thread = false,
	
	rocket_engine_decal_name = "DecRocketSplatter",
	accumulated_fuel = 0,
	prio_button = true,
	encyclopedia_id = "Rocket",
	
	can_pulse_recharge = false,
	can_change_skin = true,
	can_fly_colonists = true,
	
	compatibility_thread = false,
	dome_label = false,
	
	affected_by_dust_storm = true,
	waiting_resources = false,
	
	palette = false,
	
	launch_valid_cmd = {
		WaitLaunchOrder = true,
		Refuel = true, 
		Unload = true,
		Countdown = true,
		WaitMaintenance = true,
	},
	
	ui_status_func = {
		["arriving"] 				= "UIStatusArrive",
		["in orbit"] 				= "UIStatusInOrbit",
		["suspended in orbit"] 	= "UIStatusSuspendedInOrbit",
		["landing disabled"] 		= "UIStatusLandingDisabled",
		["landing"]				= "UIStatusLanding",
		["landed"] 				= "UIStatusLanded",
		["refueling"] 			= "UIStatusRefueling",
		["maintenance"] 			= "UIStatusMaintenance",
		["ready for launch"] 		= "UIStatusReadyForLaunch",
		["launch suspended"] 		= "UIStatusLaunchSuspended",
		["countdown"] 			= "UIStatusCountdown",
		["takeoff"] 				= "UIStatusTakeoff",
		["departing"] 			= "UIStatusDeparting",
	},
	
	LeadOut = CargoTransporter.LeadOut,
}

function RocketBase:GameInit()
	if self.landed then --pre saved rocket on map
		self:SetCommand("Refuel")
	elseif not self.command then
		self:SetCommand("OnEarth")		
	end
	
	if not self.show_logo then
		self:DestroyAttaches("Logo")
	end

	self:SetPalette(DecodePalette(self:GetRocketPalette(), self:GetColorScheme()))
	self:RefreshNightLightsState()
end

function RocketBase:Done()
	self:SetPinned(false)
	if IsValidThread(self.dust_thread) then
		DeleteThread(self.dust_thread)
	end
	if IsValid(self.landing_site) then
		DoneObject(self.landing_site)
		self.landing_site = nil
	end
	if self.site_particle then
		StopParticles(self.site_particle)
		self.site_particle = nil
	end
	self.dust_thread = false
	
	table.remove_entry(g_LandedRocketsInNeedOfFuel, self)
end

function RocketBase:AddToCityLabels()
	UniversalStorageDepot.AddToCityLabels(self)
	DroneControl.AddLabelsToCity(self)
	self.city:AddToLabel("AllRockets", self)
end

function RocketBase:RemoveFromCityLabels()
	UniversalStorageDepot.RemoveFromCityLabels(self)
	DroneControl.RemoveLabelsFromCity(self)
	self.city:RemoveFromLabel("AllRockets", self)
end

-- commands

function RocketBase:Idle()
	-- fallback if a command breaks for some reason
	self:SetCommand("OnEarth")
end

function RocketBase:OnEarth()
	self:OffPlanet()
	self:UpdateStatus("on earth")
	self:SetPinned(false)
	WaitWakeup()
end

function RocketBase:FlyToMars(cargo, cost, flight_time, initial, launch_time)
	self:OffPlanet()
	local tt = ((self.custom_travel_time_mars or 0) > 0) and self.custom_travel_time_mars or g_Consts.TravelTimeEarthMars
	flight_time = initial and 0 or (flight_time or tt)
	launch_time = launch_time or GameTime()
	
	if config.RocketInstantTravel then
		flight_time = 0
	end

	if IsGameRuleActive("FastRockets") then
		flight_time = flight_time / 10 -- Rockets & supply pods travel faster
	end
	
	-- mark arrival time for ui
	self.launch_time = launch_time
	self.flight_time = flight_time
	
	-- flight time correction for loading saves
	flight_time = Max(0, flight_time - GameTime() + launch_time)

	-- cargo/naming
	cargo = cargo or {}
	self.cargo = cargo
	if not self.name or self.name == "" then
		if cargo.rocket_name and cargo.rocket_name ~= "" then
			self.name = cargo.rocket_name 
		else
			self.name = GenerateRocketName(nil, type(self))
		end
	end
	
	if cost then
		UIColony.funds:ChangeFunding(-cost, "Import")
	end
	ResetCargo()
	
	if cargo then
		if table.find(cargo, "class", "Passengers") then
			self:SetCategory(g_ColonyNotViableUntil == -2 and "founder" or "passenger")
		else
			self:SetCategory("cargo")
		end
	end
	
	--@@@msg RocketLaunchFromEarth,rocket - fired when a rocket is launched toward Mars
	Msg("RocketLaunchFromEarth", self)
	
	if g_ActiveHints["HintPassengerRockets"] and #cargo > 0 then
		for i = 1, #cargo do
			if cargo[i].class == "Passengers" then
				HintDisable("HintPassengerRockets")
				break
			end
		end
	end
	
	self:UpdateStatus("arriving")
		
	if initial then -- special case: first rocket is already in orbit and lands faster
		self.first_arrival = true
	else
		WaitMsg("RocketInstantTravel", flight_time)
	end
	self:SetCommand("WaitInOrbit")
end

function RocketBase:LandingDisabled()
	self.landing_disabled = true
	self:SetPos(self:GetVisualPos())
	self:UpdateStatus("landing disabled")
	while self.landing_disabled do
		WaitMsg("LandingEnabled")
		self.landing_disabled = false
	end
	self:SetCommand("WaitInOrbit")
end

function RocketBase:RemovePassengers()
	local count
	local cargo = self.cargo
	for i = #cargo, 1, -1 do
		if cargo[i].class == "Passengers" then
			count = cargo[i].amount
			table.remove(cargo, i)
		end
	end
	return count
end

function RocketBase:GetDestination()
	return T(1233, "Mars")
end

function RocketBase:GetPassengerCapacity()
	return g_Consts.MaxColonistsPerRocket
end

function RocketBase:WaitInOrbit(arrive_time)
	self:OffPlanet()
	self.orbit_arrive_time = arrive_time
	self.cargo = self.cargo or {}
	local cargo = self.cargo
	local map_id = self:GetMapID()
	-- release probes immediately, mark orbit arrival time if carrying passengers
	for i = #cargo, 1, -1 do
		local item = cargo[i]
		if IsKindOf(g_Classes[item.class], "OrbitalProbe") then
			for j = 1, item.amount do
				PlaceObjectIn(item.class, map_id)
			end
			table.remove(cargo, i)
		elseif item.class == "Passengers" then
			self.orbit_arrive_time = self.orbit_arrive_time or GameTime()
		end
	end
	
	local landing_disabled = self.landing_disabled
	self:UpdateStatus(self:IsFlightPermitted() and (landing_disabled and "landing disabled" or "in orbit") or "suspended in orbit")
	
	if not self:IsLandAutomated() or not self:IsFlightPermitted() or landing_disabled then
		if self.orbit_arrive_time then
			Sleep(Max(0, self.passenger_orbit_life + GameTime() - self.orbit_arrive_time))
			-- kill the passengers, call GameOver if there are no colonists on Mars
			local count = self:RemovePassengers()
			if (count or 0) > 0 then
				if #(UIColony.city_labels.labels.Colonist or empty_table) == 0 then
					GameOver("last_colonist_died")
				else
					AddOnScreenNotification("DeadColonistsInSpace", nil, {count = count, destination = self:GetDestination() or T(1233, "Mars")})
				end
				self:OnPassengersLost()
			end
			self.orbit_arrive_time = nil
			self:UpdateStatus(self.status) -- force update to get rid of the passenger-specific texts in rollover/summary
		end
		WaitWakeup()
	end
	self:SetCommand("LandOnMars", self.landing_site)
end

function RocketBase:LandOnMars(site, from_ui)
	self.reserved_site = nil
	self.landing_site = site
	self.cargo = self.cargo or {}
	if from_ui then
		CloseModeDialog()
		self:PushDestructor(function()
			if IsValid(self.landing_site) and not self.reserved_site then
				DoneObject(self.landing_site)
				self.landing_site = nil
			end
		end)
		Msg("RocketLandAttempt", self)
		Sleep(1)
	end
	if not IsValid(self.landing_site) then
		assert(false, "Missing landing site for Land")
		self:SetCommand("OnEarth")
	end
	local spot = site:GetSpotBeginIndex("Rocket")
	local dest, angle = site:GetSpotLoc(spot)

	self:UpdateStatus("landing")

	self:TransferToMap(site:GetMapID())

	assert(GetTerrain(self):IsPointInBounds(dest))
	
	local altitude = self.orbital_altitude
	local velocity = self.orbital_velocity

	local first_arrival = self.first_arrival
	if first_arrival then	
		altitude = self.orbital_altitude_first
		velocity = self.orbital_velocity_first	
		self.first_arrival = nil
		
		HintDisable("HintRocket")
	end
	
	self.orbit_arrive_time = nil
	
	local pt = dest + point(0, 0, altitude)
	self:ClearEnumFlags(const.efVisible)
	self:SetPos(pt)
	self:SetAngle(angle)
	
	PlayFX("RocketLand", "start", self)	
	if not IsValid(self.site_particle) then
		self.site_particle = PlaceParticlesIn("Rocket_Pos", self:GetMapID())
		self.site_particle:SetPos(dest)
		self.site_particle:SetScale(200)
	end
	self:PushDestructor(function()
		if IsValid(self.site_particle) then
			StopParticles(self.site_particle)
			self.site_particle = nil
		end
	end)
	
	self:SetEnumFlags(const.efVisible + const.efSelectable)

	local a, t = self:GetAccelerationAndTime(dest, 0, velocity)
		
	if not IsValid(site.landing_pad) then
		self:StartDustThread(self.total_land_dust_amount, Max(0, t - self.total_dust_time))
	end
	
	self:SetAcceleration(a)
	self:SetPos(dest, t)
	
	assert(self.pre_hit_ground2 >  self.pre_hit_ground)
	assert(self.pre_hit_ground2 < t)
	assert(self.pre_hit_groud_decal < t)
	
	--spawn decal (delayed)
	if not IsValid(site.landing_pad) then
		self:PlaceEngineDecal(dest, Max(t - self.pre_hit_groud_decal, 0))
	end

	Sleep(Max(0, t - self.pre_hit_ground2)) -- t = T - pre_hit_ground2
	PlayFX("RocketLand", "pre-hit-ground2", self, false, dest)
	
	Sleep(Max(0, self.pre_hit_ground2 - self.pre_hit_ground)) -- t = T - pre_hit_ground
	PlayFX("RocketLand", "pre-hit-ground", self, false, dest)

	Sleep(Min(t, self.pre_hit_ground))
	PlayFX("RocketLand", "hit-ground", self, false, dest)
	self:PopAndCallDestructor()
	Sleep(self.warm_down)
	PlayFX("RocketLand", "end", self)
	self:UpdateStatus("landed")
	
	if HintsEnabled then
		if first_arrival then
			HintTrigger("HintBuildingConstruction")
			HintTrigger("HintCameraControls")
			HintTrigger("HintStorageDepot")
			HintTrigger("HintSuggestSensorTower")
			HintTrigger("HintResupply")
			HintTrigger("HintPriority")
			HintTrigger("HintGameSpeed")
			if UIColony:GetEstimatedRP() > 0 then
				HintTrigger("HintResearchAvailable")
			end
		end
		
		if not g_ActiveHints["HintRefuelingTheRocket"] then
			local rockets = self.city and self.city.labels.SupplyRocket or ""
			local has_available = false
			for i = 1, #rockets do
				if rockets[i] ~= self and rockets[i]:IsAvailable() then
					has_available = true
					break
				end
			end
			if not has_available then
				HintRefuelingTheRocket:TriggerLater()
			end
		end
	end

	self:SetIsNightLightPossible(true)

	--@@@msg RocketLanded,rocket- fired when a rocket has landed on Mars.
	Msg("RocketLanded", self)
	if from_ui then	
		self:PopDestructor() -- landing site cleanup
	end
	
	Sleep(1) -- Sleep to give events listening to RocketLanded a change to trigger before unloading
	if self.auto_export then
		self:AttachSign(true, "SignTradeRocket")
	end
	self:SetCommand("Unload")
end

function RocketBase:Unload()
	if not IsValid(self.landing_site) then
		assert(false, "Missing landing site for Unload")
		self:SetCommand("OnEarth")
	end
	self.cargo = self.cargo or {}
	self.rovers = self.rovers or self:SpawnRovers()
	self:AttachRovers(self.rovers)
	
	local drones_list = self:SpawnDronesFromEarth()
	self:OpenDoor()
	--needs to happen after rover's game init (so default desires have booted)
	--so we use opendoor's sleep to make sure all rovers are initialized.
	self:FillTransports() 
	GetFlightSystem(self):Remark(self)

	local rovers = self.rovers
	self.rovers = nil
	self.placement = {}

	for _,rover in ipairs(rovers) do
		if rover.disappeared then
			rover:Appear()
		end
	end
	local out = self:GetSpotPos(self:GetSpotBeginIndex("Roverout"))
	self:UnloadRovers(rovers, out)
	drones_list = #drones_list > 0 and drones_list or self.drones
	self:UnloadDrones(drones_list)
	self:UnloadCargoObjects(self.cargo, out)
	
	self.placement = nil
	
	Msg("RocketUnloaded", self)
	
	self:SetCommand(self.launch_after_unload and "Countdown" or "Refuel")
end

function RocketBase:Refuel(initialized)
	if not IsValid(self.landing_site) then
		assert(false, "Missing landing site for Refuel")
		self:SetCommand("OnEarth")
	end
	local sol_refuel_start = self:GetRefuelProgress() == 0 and UIColony.day or 0
	if not initialized then
		self:ResetDemandRequests()
		table.insert_unique(g_LandedRocketsInNeedOfFuel, self)
		self:StartDroneControl()
	end
	if not IsValidThread(self.departure_thread) then
		self:StartDepartureThread()
	end
	self:UpdateStatus("refueling")
	while not self:HasEnoughFuelToLaunch() do
		WaitMsg("RocketRefueled")
	end
	if sol_refuel_start == UIColony.day then
		Msg("RocketRefueledInADay")
	end
	self:SetCommand("WaitLaunchOrder")
end

function RocketBase:WakeFromWaitingForResources()
	if self.waiting_resources then
		Wakeup(self.command_thread)
	end
end

function RocketBase:WaitForResources()
	assert(CurrentThread() == self.command_thread) -- self.waiting_resources causes Wakeup(self.command_thread) on a number of occasions
	self.waiting_resources = true
	WaitWakeup()
	self.waiting_resources = false
end

function RocketBase:ForceInterruptIncomingDrones()
	self:InterruptDrones(nil, function(drone)
									if (drone.target == self) or 
										(drone.d_request and drone.d_request:GetBuilding() == self) or
										(drone.s_request and drone.s_request:GetBuilding() == self) then
										return drone
									end
								end)
end

function RocketBase:WaitMaintenance(resource, amount)
	if not IsValid(self.landing_site) then
		assert(false, "Missing landing site for Maintenance")
		self:SetCommand("OnEarth")
	end
	
	if self.auto_connect then
		self:ForceInterruptIncomingDrones()
		self:DisconnectFromCommandCenters()
	end
	
	self.maintenance_request = self:AddDemandRequest(resource, amount, 0)
	self.maintenance_requirements = {resource = resource, amount = amount}
	self:UpdateStatus("maintenance")
	
	if self.auto_connect then
		self:ConnectToCommandCenters()
	else
		table.insert_unique(g_LandedRocketsInNeedOfFuel, self)
		self:StartDroneControl()
		self:OpenDoor()
	end
	
	while not self:MaintenanceDone() do
		assert(self.maintenance_request and self.maintenance_request:GetActualAmount() > 0)
		assert(self.auto_connect)
		self:AttachSign(true, "SignMalfunction")
		WaitMsg("RocketMaintenanceDone", 10000)
	end
	self:AttachSign(false, "SignMalfunction")
	self:SetCommand("WaitLaunchOrder")
end

function RocketBase:WaitLaunchOrder()
	while true do -- looped so UpdateFlightPermissions can just wakeup the thread instead of duplicating the checks
		local issue = self:GetLaunchIssue()
		local can_take_off = not issue
		local new_status = can_take_off and "ready for launch" or "launch suspended"
		if self.status~=new_status then
			self:UpdateStatus(new_status)
		end
		
		if self:IsLaunchAutomated() and not self:HasCargoSpaceLeft() and not issue then
			self:SetCommand("Countdown")
		end
		if issue == "unloading" then
			self:WaitForResources()
		else
			Sleep(5000)
		end
	end
end

function RocketBase:DropBrokenDrones(t)
	for i=#t, 1, -1 do
		local drone = t[i]
		if drone:IsBroken() or 
			not IsValid(drone) or
			drone.command == "WaitingCommand" then --fallback..
			if IsValid(drone) then
				if self:IsValidPos() then
					drone:SetPos(self:GetVisualPos2D())
				else
					drone:delete()
				end
			end
			table.remove(t, i)
		end
	end
end

function RocketBase:InterruptIncomingDronesAndDisconnect()
	local should_wait = false
	self:InterruptDrones(nil, function(drone)
										if (drone.target == self) or 
											(drone.d_request and drone.d_request:GetBuilding() == self) or
											(drone.s_request and drone.s_request:GetBuilding() == self) then
											if not table.find(self.drones_exiting, drone) and not table.find(self.drones_entering, drone) then
												--we'll wait up for those drones currently on the ramp, no further drones should enter the rocket though
												should_wait = true
												return drone
											end
										end
									end)
									
	self:DisconnectFromCommandCenters() --so no more drones climb the ramp.
	table.remove_entry(g_LandedRocketsInNeedOfFuel, self) -- needs to be after DisconnectFromCommandCenters
	self.working = false --so recharging drones exit.
	self.auto_connect = false --so ccs don't reconect us automatically anymore
	-- should be after disconnect so no further drones enter
	while self:IsCargoRampInUse() do
		should_wait = false
		self:DropBrokenDrones(self.drones_exiting)
		self:DropBrokenDrones(self.drones_entering)
		--wait for drones to exit and passengers to enter
		Sleep(1000)
	end
	self:StopDroneControl() --this removes waypoint splines so it should be after drones exit.
	if should_wait then
		Sleep(1) --wait for drone destros to fire correctly
	end
end

function RocketBase:Countdown(destination)
	self:UpdateStatus("countdown")
	Sleep(100) --give time so RocketManualLaunch trigger story bits can interrupt us before we do any actual work
	self:InterruptIncomingDronesAndDisconnect()
	self:StopDepartureThread()
	self:CloseDoor()
	local export_amount = Min(self:GetStoredExportResourceAmount(), self.max_export_storage)
	self.city:MarkPreciousMetalsExport(export_amount)
	self.exported_amount = export_amount
	self:SetCommand("Takeoff", destination)
end

function RocketBase:GetBoardedTourists()
	local tourists = {}
	for i=1, #(self.boarded or empty_table)do
		if self.boarded[i].traits.Tourist then
			table.insert(tourists, self.boarded[i])
		end
	end
	return tourists
end

function RocketBase:GetTourismRewardInfo()
	return {rocket_name = Untranslated(self.name), colonists = self:GetBoardedTourists{}}
end

function RocketBase:ApplyTouristRewards()
	local boarded_tourists = self:GetBoardedTourists()
	if #boarded_tourists > 0 then
		local money_reward, applicant_reward = HolidayRating:ApplyRewards(boarded_tourists)
		local notification_params = {tourist_count = #boarded_tourists, funds = money_reward, applicants = applicant_reward}
		local reward_info = self:GetTourismRewardInfo()
		
		AddOnScreenNotification("HolidayRewards", function()
			HolidayRating:OpenTouristOverview(reward_info)
		end, notification_params)
	end
	self:ClearDepartures()
end

function RocketBase:ClearDepartures()
	self.departures = {}
	self.boarding = {}
	self.boarded = {}
end

function RocketBase:Takeoff(destination)
	self:AttachSign(false, "SignTradeRocket")
	self:UpdateStatus("takeoff")
	if SelectedObj == self then
		SelectObj(false)
	end
	if not self.auto_export then
		self:ClearEnumFlags(const.efSelectable)
	end
	
	self:ApplyTouristRewards()
	self:AbandonAllDrones()
	self:ClearAllResources()
	self:ResetDemandRequests()
	
	self:SetIsNightLightPossible(false)
	--@@@msg RocketLaunched,rocket - fired when a rocket takes off from Mars
	Msg("RocketLaunched", self)
	
	local pt = self:GetPos()
	local dest = pt + point(0, 0, self.orbital_altitude)
	
	PlayFX("RocketEngine", "start", self)
	Sleep(self.warm_up)
	
	local has_pad = IsValid(self.landing_site) and IsValid(self.landing_site.landing_pad)
	if not has_pad then
		self:PlaceEngineDecal(pt, 0)
	end
	
	PlayFX("RocketEngine", "end", self)
	PlayFX("RocketLaunch", "start", self)
	local a, t = self:GetAccelerationAndTime(dest, self.orbital_velocity, 0)
	
	if not has_pad then
		self:StartDustThread(self.total_launch_dust_amount)
	end
	self:SetAcceleration(a)
	self:SetPos(dest, t)

	Sleep(t)
	
	if IsValid(self.landing_site) and not self.auto_export then
		DoneObject(self.landing_site)
		self.landing_site = nil
	else
		self.reserved_site = true
		if not IsValid(self.site_particle) then
			self.site_particle = PlaceParticlesIn("Rocket_Pos", self:GetMapID())
			self.site_particle:SetPos(pt)
			self.site_particle:SetScale(200)
		end
		self:PushDestructor(function()
		if IsValid(self.site_particle) then
			StopParticles(self.site_particle)
			self.site_particle = nil
		end
		end)
	end
	if not IsValid(self) then return end
	PlayFX("RocketLaunch", "end", self)
	
	self:ClearEnumFlags(const.efVisible)
	
	local next_command = destination and "FlyToSpot" or "FlyToEarth"
	self:SetCommand(next_command, destination)
end

GlobalVar("g_ExportsFunding", 0)

function RocketBase:FlyToEarth(flight_time, launch_time)
	local tt = ((self.custom_travel_time_earth or 0) > 0) and self.custom_travel_time_earth or g_Consts.TravelTimeMarsEarth
	flight_time = flight_time or tt
	
	if config.RocketInstantTravel then
		flight_time = 0
	end
	
	if IsGameRuleActive("FastRockets") then
		flight_time = flight_time / 10 -- Rockets & supply pods travel faster
	end
	
	self.launch_time = launch_time or GameTime()
	self.flight_time = flight_time

	-- flight time correction for loading saves
	flight_time = Max(0, flight_time - GameTime() + self.launch_time)

	self:UpdateStatus("departing")
	self:OffPlanet()
	
	GetFlightSystem(self):Unmark(self)
		
	WaitMsg("RocketInstantTravel", flight_time)

	self:UpdateStatus("on earth")
	--@@@msg RocketReachedEarth,rocket - fired when a rocket finishes its travel from Mars to Earth
	Msg("RocketReachedEarth", self)
	
	local export_funding = UIColony.funds:CalcBaseExportFunding(self.exported_amount)
	if export_funding > 0 then
		export_funding = UIColony.funds:ChangeFunding(export_funding, "Export")
		if not g_ExportsFunding or not IsOnScreenNotificationShown("RareMetalsExport") then
			g_ExportsFunding = 0
		end
		g_ExportsFunding = g_ExportsFunding + export_funding
		AddOnScreenNotification("RareMetalsExport", nil, { funding = g_ExportsFunding })
	end
	self.exported_amount = nil
	
	if self.auto_export then
		self:SetCommand("FlyToMars")
	else
		self:SetCommand("OnEarth")
	end
end

-- end commands

function RocketBase:IsRefueling()
	return self.command == "Refuel"
end

function RocketBase:IsDeparting()
	return table.find({"Countdown", "Takeoff", "FlyToSpot", "FlyToMars"}, self.command)
end

function RocketBase:UpdateRefuelRequests(old_val, new_val)
	local delta = new_val - old_val
	local stored = old_val - self.refuel_request:GetActualAmount()
	self.refuel_request:AddAmount(delta)
	self:InterruptDrones(nil, function(drone) return drone.d_request == self.refuel_request and drone end)
	
	if self:HasEnoughFuelToLaunch() then
		local extra = stored - new_val
		if extra > 0 then
			local unit_count = 1 + (new_val / (const.ResourceScale * 5)) --1 per 5
			self.unload_fuel_request = self:AddSupplyRequest("Fuel", extra, const.rfPostInQueue, unit_count)
			self.refuel_request:SetAmount(0)
		end
		Msg("RocketRefueled", self)
	end
end

function RocketBase:OnModifiableValueChanged(prop, old_val, new_val)
	if prop == "launch_fuel" then
		if self.refuel_request then
			self:UpdateRefuelRequests(old_val, new_val)
		end
	elseif prop == "max_export_storage" then
		if self.export_requests then
			if #self.export_requests == 1 then
				local export_request = self.export_requests[1]
				local stored = old_val - export_request:GetActualAmount()
				local delta = new_val - old_val
				export_request:AddAmount(delta)
				
				local extra = stored - new_val
				if extra > 0 then
					if not self.unload_request then
						local unit_count = 1 + (new_val / (const.ResourceScale * 5)) --1 per 5
						self.unload_request = self:AddSupplyRequest("PreciousMetals", extra, const.rfPostInQueue, unit_count)
					end
					export_request:SetAmount(0)
					self.unload_request:SetAmount(extra)
				end
				
				self:InterruptDrones(nil, function(drone) return drone.d_request == export_request and drone end)
				if self.waiting_resources then
					Wakeup(self.command_thread)
				end
				
			end
		end
	end
end

function RocketBase:BuildingUpdate(dt, day, hour)
	if GetMissionSponsor().id == "IMM" and (self.command == "Refuel" or self.command == "ExpeditionRefuelAndLoad") then
		self.accumulated_fuel = self.accumulated_fuel + MulDivRound(dt, self:GetLaunchFuel()/10, const.DayDuration)
		local amount = self.accumulated_fuel - self.accumulated_fuel % const.ResourceScale
		self.accumulated_fuel = self.accumulated_fuel - amount
		local refuel_request = self.refuel_request
		local refueling, exporting
		if refuel_request:GetTargetAmount() > 0 then
			refueling = true
		elseif self.export_requests then
			for _, request in ipairs(self.export_requests) do
				if request:GetResource() == "Fuel" and request:GetTargetAmount() > 0 then
					refuel_request = request
					exporting = true
				end
			end		
		end
		refuel_request:AddAmount( -Min(amount, refuel_request:GetTargetAmount() ) )
		if refueling and self:HasEnoughFuelToLaunch() then
			--@@@msg RocketRefueled,rocket - fired when a rocket is completely refueled for its trip back to Earth
			Msg("RocketRefueled", self)
		end
		if exporting and self.waiting_resources then
			Wakeup(self.command_thread)
		end
	end
end

function RocketBase:CompatConvertToCommand()
	if self.command then
		return
	end
	if self.status == "on earth" then
		self:SetCommand("OnEarth")
	elseif self.status == "refueling" then
		self:SetCommand("Refuel")
	elseif self.status == "landed" then
		self:SetCommand("Unload")
	elseif self.status == "departing" then
		self:SetCommand("FlyToEarth")
	end
end

function RocketBase:UpdateStatus(status)
	self.status = status
	self:SetPinned(self:IsPinned() or self:ShouldBePinned())
	
	local could_change_skin = self.can_change_skin
	
	local template = BuildingTemplates[self.template_name]		
	self:CompatConvertToCommand()
	local func_name = self.ui_status_func[status]
	if func_name then
		self[func_name](self, template)
	end
		
	if self == SelectedObj then
		if self.can_change_skin == could_change_skin then
			RebuildInfopanel(self)
		else
			ReopenSelectionXInfopanel()
		end
	end
	
	--@@@msg RocketStatusUpdate,rocket,status - fired when rocket's status is updated. 'status' can be one of "on earth", "arriving", "in orbit", "suspended in orbit", "landing", "landed", "refueling", "maintenance", "ready for launch", "launch suspended", "countdown", "takeoff" or "departing"
	Msg("RocketStatusUpdate", self, status)
end

function RocketBase:OffPlanet()
	if self:IsValidPos() then
		self:DetachFromMap()
	end
	if IsValid(self.landing_site) and not self.auto_export and not self:IsKindOf("ForeignTradeRocket") then
		DoneObject(self.landing_site)
		self.landing_site = nil
	end
	if SelectedObj == self then
		SelectObj(false)
	end
end

function RocketBase:GetSelectionRadiusScale()
	return self.work_radius
end

function RocketBase:GetLogicalPos()
	if IsValid(self.landing_site) then
		return self.landing_site:GetVisualPos()
	end
	return self:GetVisualPos()
end


function RocketBase:UpdateNotWorkingBuildingsNotification()
end

function RocketBase:GetDustRadius()
	return self.dust_radius
end

function RocketBase:StartDustThread(total_dust_to_apply, delay)
	if IsValidThread(self.dust_thread) then
		DeleteThread(self.dust_thread)
	end
	
	self.dust_thread = CreateGameTimeThread(function(self, total_dust_to_apply, delay)
		if delay and delay > 0 then
			Sleep(delay)
		end
				
		local total_dust_time = self.total_dust_time
		local dust_tick = self.dust_tick
		local total_dust_applied = 0
		local dust_to_apply_per_tick = (total_dust_to_apply / total_dust_time) * dust_tick
		assert(dust_to_apply_per_tick > 0 and dust_to_apply_per_tick * (total_dust_time / dust_tick) == total_dust_to_apply, "Rounding error in rocket dust application")
		local realm = GetRealm(self)
		while IsValid(self) and total_dust_applied < total_dust_to_apply do
			realm:MapForEach(self, "hex", self.dust_radius, "Building", "DustGridElement", "DroneBase", function(o, amount) o:AddDust(amount) end, dust_to_apply_per_tick )
			total_dust_applied = total_dust_applied + dust_to_apply_per_tick
			Sleep(self.dust_tick)
		end
	end, self, total_dust_to_apply, delay)
end

function RocketBase:StartDepartureThread()
	self:GenerateDepartures(true, false)
	self.departure_thread = CreateGameTimeThread(function(self)
		while IsValid(self) do
			self:GenerateDepartures(false, true)
			Sleep(self.departure_tick)
		end
	end, self)
end

function RocketBase:StopDepartureThread()
	if IsValidThread(self.departure_thread) then
		DeleteThread(self.departure_thread)
	end
end

function RocketBase:GetWorkNotPossibleReason()
	if not self.landed then
		return "NotLanded"
	end
	return BaseBuilding.GetWorkNotPossibleReason(self)
end

function RocketBase:IsAvailable()
	return self.command == "OnEarth" and not self.auto_export
end

function RocketBase:BuildWaypointChains()
	--intentionally empty
end

function RocketBase:CanDemolish()
	return self.can_demolish and self.is_demolishable_state
end

function RocketBase:OnDemolish()
	if IsValid(self.landing_site) then
		DoneObject(self.landing_site)
		self.landing_site = nil
	end
	
	self:ReturnStockpiledResources()
	-- check for loaded fuel/metals & return
	if self.refuel_request then
		local amount = self:GetLaunchFuel() - self.refuel_request:GetActualAmount()
		if amount > 0 then
			PlaceResourceStockpile_Delayed(self:GetVisualPos(), self:GetMapID(), "Fuel", amount, self:GetAngle(), true)
		end
	end
	
	if self.unload_fuel_request then
		local amount = self.unload_fuel_request:GetActualAmount()
		if amount > 0 then
			PlaceResourceStockpile_Delayed(self:GetVisualPos(), self:GetMapID(),  "Fuel", amount, self:GetAngle(), true)
		end
	end
	
	if self.export_requests then
		assert(#self.export_requests == 1) -- trade rockets can't be salvaged
		local amount = self.max_export_storage - self.export_requests[1]:GetActualAmount()
		if amount > 0 then
			PlaceResourceStockpile_Delayed(self:GetVisualPos(), self:GetMapID(),  "PreciousMetals", amount, self:GetAngle(), true)
		end
	end
	
	if self.unload_request then
		local amount = self.unload_request:GetActualAmount()
		if amount > 0 then
			PlaceResourceStockpile_Delayed(self:GetVisualPos(), self:GetMapID(),  "PreciousMetals", amount, self:GetAngle(), true)
		end
	end
	
	Building.OnDemolish(self)
end

function RocketBase:SetPinned(pinned)
	pinned = not not pinned
	if pinned ~= self:IsPinned() then
		self:TogglePin("force")
	end
end

function RocketBase:GetRocketType()
	if #self.cargo > 0 then
		for i,cargo in ipairs(self.cargo) do
			if cargo.class == "Passengers" then
				return RocketTypeNames.Passenger
			end
		end
		
		return RocketTypeNames.Cargo
	end
	
	return RocketTypeNames.Fallback
end

function RocketBase:GetColorScheme()
	return GetCurrentColonyColorScheme()
end

function RocketBase:GetRocketPalette(ccs)
	if not ccs then
		ccs = self:GetColorScheme()
	end
	if #self.rocket_palette ~= 4 then
		self.rocket_palette = g_Classes[self.class].rocket_palette
	end
	return GetAdjustedRocketPalette(self.entity, self.rocket_palette, ccs)
end

function RocketBase:SetCategory(cat)
	self.category = cat
end

---------------- UI status funcs ----------------
function RocketBase:UIStatusArrive(template)
	self.pin_blink = false
	self.pin_rollover = self.pin_rollover_arriving
	self.pin_summary1 = T(708, "<ArrivalTimePercent>%")
	self.pin_rollover_hint = ""
	self.pin_rollover_hint_xbox = ""
	self.pin_status_img = "UI/Icons/pin_rocket_incoming.tga"
	self.is_demolishable_state = false
	self.can_change_skin = false
end
function RocketBase:UIStatusInOrbit(template)
	self.pin_blink = true
	self.pin_rollover = self.pin_rollover_in_orbit
	if template then
		self.pin_rollover_hint = template.pin_rollover_hint
		self.pin_rollover_hint_xbox = template.pin_rollover_hint_xbox
	end
	if self.orbit_arrive_time then
		self.pin_rollover = self.pin_rollover .. "<newline><newline><left>" .. T(8052, "Passengers on board will die if the rocket doesn't land in <em><UIOrbitTimeLeft> h</em>.")
	end
	self.pin_summary1 = nil
	self.pin_status_img = "UI/Icons/pin_rocket_orbiting.tga"
	self.is_demolishable_state = false
	self.can_change_skin = false
end
function RocketBase:UIStatusSuspendedInOrbit(template)
	self:UIStatusInOrbit(template)
	self.pin_blink = false
	self.pin_rollover = self.pin_rollover .. "<newline><newline>" .. T(8523, "<red>Rockets can't land during dust storms.</red>")
end

function RocketBase:UIStatusLandingDisabled(template)
	self.pin_blink = false
	self.pin_rollover = self.pin_rollover_in_orbit
	if template then
		self.pin_rollover_hint = template.pin_rollover_hint
		self.pin_rollover_hint_xbox = template.pin_rollover_hint_xbox
	end
	if self.orbit_arrive_time then
		self.pin_rollover = self.pin_rollover .. "<newline><newline>" .. T(8052, "Passengers on board will die if the rocket doesn't land in <em><UIOrbitTimeLeft> h</em>.")
	end
	self.pin_rollover = self.pin_rollover .. "<newline><newline>" .. T(11166, "<red>Rocket landing is suspended.</red>")
	self.pin_summary1 = nil
	self.pin_status_img = "UI/Icons/pin_rocket_orbiting.tga"
	self.is_demolishable_state = false
	self.can_change_skin = false
end
function RocketBase:UIStatusLanding(template)
	self.pin_blink = false
	self.pin_rollover = T(711, "Landing in progress.")
	if template then
		self.pin_rollover_hint = ""
		self.pin_rollover_hint_xbox = ""
	end
	self.pin_summary1 = nil
	self.pin_status_img = nil
	self.is_demolishable_state = false
	self.can_change_skin = false
end

function RocketBase:UIStatusLanding(template)
	self.pin_blink = false
end

function RocketBase:UIStatusLanded(template)
	self.pin_blink = false
	if template then
		self.pin_rollover = template.pin_rollover
		self.pin_rollover_hint = PinnableObject.pin_rollover_hint
		self.pin_rollover_hint_xbox = PinnableObject.pin_rollover_hint_xbox
	end
	self.pin_summary1 = nil
	self.pin_status_img = nil
	self.is_demolishable_state = false
	self.can_change_skin = false
end

function RocketBase:UIStatusRefueling(template)
	self.pin_blink = false
	if template then
		self.pin_rollover = template.pin_rollover
		self.pin_rollover_hint = PinnableObject.pin_rollover_hint
		self.pin_rollover_hint_xbox = PinnableObject.pin_rollover_hint_xbox
	end
	self.pin_summary1 = nil
	self.pin_status_img = nil
	self.is_demolishable_state = true
	self.can_change_skin = true
end

function RocketBase:UIStatusMaintenance(template)
	self.pin_blink = false
	if template then
		self.pin_rollover = template.pin_rollover
		self.pin_rollover_hint = PinnableObject.pin_rollover_hint
		self.pin_rollover_hint_xbox = PinnableObject.pin_rollover_hint_xbox
	end
	self.pin_summary1 = nil
	self.pin_status_img = nil
	self.is_demolishable_state = false
	self.can_change_skin = false
end

function RocketBase:UIStatusReadyForLaunch(template)
	self.pin_blink = not self:IsLaunchAutomated()
	if template then
		self.pin_rollover = template.pin_rollover
		self.pin_rollover_hint = PinnableObject.pin_rollover_hint
		self.pin_rollover_hint_xbox = PinnableObject.pin_rollover_hint_xbox
	end
	self.pin_summary1 = nil
	self.pin_status_img = "UI/Icons/pin_rocket_outgoing.tga"
	self.is_demolishable_state = true
	self.can_change_skin = true
end

function RocketBase:UIStatusLaunchSuspended(template)
	self.pin_blink = false
	if template then
		self.pin_rollover = template.pin_rollover
		self.pin_rollover_hint = PinnableObject.pin_rollover_hint
		self.pin_rollover_hint_xbox = PinnableObject.pin_rollover_hint_xbox
	end
	if not self:IsFlightPermitted() then
		self.pin_rollover = self.pin_rollover .. "<newline><newline>" .. T(12467, "<red>Rockets can't launch during dust storms.</red>")
	end
	self.pin_summary1 = nil
	self.pin_status_img = "UI/Icons/pin_rocket_outgoing.tga"
	self.is_demolishable_state = true
	self.can_change_skin = true
end

function RocketBase:UIStatusCountdown(template)
	self.pin_blink = false
	if template then
		self.pin_rollover = template.pin_rollover
		self.pin_rollover_hint = PinnableObject.pin_rollover_hint
		self.pin_rollover_hint_xbox = PinnableObject.pin_rollover_hint_xbox
	end
	self.pin_summary1 = nil
	self.pin_status_img = "UI/Icons/pin_rocket_outgoing.tga"
	self.is_demolishable_state = false
	self.can_change_skin = false
end

function RocketBase:UIStatusTakeoff(template)
	self.pin_blink = false
	self.pin_rollover = T(713, "<image UI/Icons/pin_rocket_outgoing.tga 1500>Take-off in progress.")
	if template then
		self.pin_rollover_hint = T(714, "Taking off...")
		self.pin_rollover_hint_xbox = T(714, "Taking off...")
	end
	self.pin_summary1 = nil
	self.pin_status_img = "UI/Icons/pin_rocket_outgoing.tga"
	self.is_demolishable_state = false
	self.can_change_skin = false
end

function RocketBase:UIStatusDeparting(template)
	self.pin_blink = false
	self.pin_rollover = T(715, "<image UI/Icons/pin_rocket_outgoing.tga 1500>Travelling to Earth.<newline>Flight progress: <em><ArrivalTimePercent></em>%.")
	if (self.exported_amount or 0) > 0 then
		self.pin_rollover = self.pin_rollover .. "<newline>" .. T{7674, "Exporting <resource(amount,res)>", amount = self.exported_amount, res = "PreciousMetals"}
	end
	self.pin_summary1 = T(708, "<ArrivalTimePercent>%")
	self.pin_rollover_hint = ""
	self.pin_rollover_hint_xbox = ""
	self.pin_status_img = "UI/Icons/pin_rocket_outgoing.tga"
	self.is_demolishable_state = false
	self.can_change_skin = false
end
---------------- End UI status funcs ----------------

local s_ShouldBeNotPinned = {["on earth"] = true, ["landing"] = true, ["countdown"] = true, ["takeoff"] = true}
function RocketBase:ShouldBePinned()
	local pinned = self.first_arrival or not s_ShouldBeNotPinned[self.status]
	if self:IsKindOf("SupplyPod") and not self.command then
		pinned = false
	end
	
	return pinned
end

function RocketBase:CanBeUnpinned()
	return false
end

function RocketBase:OnPinClicked(gamepad)
	HintDisable("HintGameStart")
	if HintsEnabled then
		HintTrigger("HintRocket")
	end
	if self.command == "OnEarth" or 
		self.command == "FlyToMars" or 
		self.command == "FlyToEarth" or
		self.command == "FlyToColony" or
		self.command == "FlyToSpot" or
		self.command == "Takeoff" or
		self.command == "LandingDisabled"
	then
		return true
	end

	if self:IsValidPos() then
		return false -- use default logic (select/view)
	end
	local cargo = self.cargo or empty_table
	local passengers, drones
	for i = 1, #cargo do
		local cls = cargo[i].class
		if cls == "Passengers" then
			passengers = true
		elseif IsKindOf(g_Classes[cls], "Drone") and cargo[i].amount > 0 then
			drones = true
		end
	end
	
	local igi = GetInGameInterface()
	if gamepad and (igi.mode == "overview" or IsKindOf(igi.mode_dialog, "OverviewModeDialog")) then
		local mode_dlg = igi.mode_dialog
		local sector = mode_dlg.target_obj or mode_dlg.sector_obj
		--mode_dlg.exit_to = sector and sector:GetPos()
	end
	igi:SetMode("construction", { 
		template = self.landing_site_class, --"RocketLandingSite",
		instant_build = true,
		params = {
			amount = 0,
			passengers = passengers,
			drones = drones,
			stockpiles_obstruct = true,
			override_palette = self:GetRocketPalette(),
			rocket = self,
			ui_callback = function(site)
				self:SetCommand("LandOnMars", site, "from ui")
				self:UpdateStatus("landing")
			end,
		}
	})
	return true
end

function RocketBase:PlaceEngineDecal(pos, delay)
	local obj = PlaceObjectIn("FadingDecal", self:GetMapID(), {delay = delay, decal_name = self.rocket_engine_decal_name, decal_fade_time = self.decal_fade_time, })
	obj:SetPos(pos)
end

function RocketBase:SetPriority(priority)
	if self.priority == priority then return end
	for _, center in ipairs(self.command_centers) do
		center:RemoveRocket(self)
	end
	Building.SetPriority(self, priority)
	for _, center in ipairs(self.command_centers) do
		center:AddRocket(self)
	end
end

function RocketBase:AddCommandCenter(center)
	if TaskRequester.AddCommandCenter(self, center) then
		center:AddRocket(self)
	end
end

function RocketBase:RemoveCommandCenter(center)
	if TaskRequester.RemoveCommandCenter(self, center) then
		center:RemoveRocket(self)
	end
end

function RocketBase:Debug_InterruptTest()
	self:InterruptDrones(nil, function(drone)
										if (drone.target == self) or 
											(drone.d_request and drone.d_request:GetBuilding() == self) or
											(drone.s_request and drone.s_request:GetBuilding() == self) then
											return drone
										end
									end)
end

--drones
function RocketBase:StartDroneControl()
	WaypointsObj.BuildWaypointChains(self)
	self.landed = true
	self.working = true
	self.auto_connect = true
	self.accept_requester_connects = true
	self.under_construction = {} --init early or we get asserts in finddemandrequest till the update constructions thread boots up
	self:ConnectTaskRequesters()
	self:GatherOrphanedDrones()
	self:ConnectToCommandCenters()
end

function RocketBase:StopDroneControl()
	self:DisconnectTaskRequesters()
	self.landed = false
	self.under_construction = false
	self.working = false
	self.auto_connect = false
	self.accept_requester_connects = false
	self.waypoint_chains = false
end

const.RocketMaxDrones = 20 --needs to be accounted for in resupply menu
function RocketBase:GetMaxDrones()
	return const.RocketMaxDrones
end

function RocketBase:CanHaveMoreDrones()
	return self.landed and DroneControl.CanHaveMoreDrones(self)
end

function RocketBase:GetEntrancePoints(entrance_type, spot_name)
	return WaypointsObj.GetEntrancePoints(self, entrance_type or "rocket_entrance", spot_name)
end

function RocketBase:GetEntrance(target, entrance_type, spot_name)
	return WaypointsObj.GetEntrance(self, target, entrance_type or "rocket_entrance", spot_name)
end

--override of leadin and leadout that don't use goto, so that Step(cpp) doesn't switch our axis
--mostly cpy paste from WaypointsObj
function RocketBase:LeadIn(unit)
	if unit.holder == self then return end
	unit:PushDestructor(function(unit)
		if not IsValid(unit) then 
			table.remove_entry(self.drones_exiting, unit)
			return 
		end
		self:LeadOut(unit)
	end)		
	if IsKindOf(unit, "Drone") then
		table.insert(self.drones_entering, unit)
		unit:ClearGameFlags(const.gofSpecialOrientMode)
	end
	unit:PushDestructor(function(unit)
		-- uninterruptible code:
		if not IsValid(unit) then return end
		local entrance = self.waypoint_chains and self.waypoint_chains.rocket_entrance[1]
		if entrance then
			local open = entrance.openOutside
			local speed = unit:GetSpeed()
			local count = #entrance
			local first_pt = count
			if unit:IsValidPos() then
				local p1 = entrance[count]
				local p2 = entrance[count - 1]
				local p = unit:GetPos()
				if p ~= p1 and p ~= p2 then
					local init_at = count
					if IsCloser2D(p, p2, p1:Dist2D(p2)) then
						init_at = init_at - 1
					end
					unit:Goto(entrance[init_at]) --use goto to reach first pt
				end
				if IsValid(self) and IsValid(unit) and unit:IsValidPos() then
					if IsKindOf(unit, "Drone") then
						for i = count - 1, 1, -1 do
							local p1 = entrance[i + 1]
							local p2 = entrance[i]
							local p3 = unit:GetPos()
							if p2 ~= p3 then
								unit:Face(p2)
								self:OnWaypointStartGoto(unit, p1, p2)
								local t = p3:Dist(p2) * 1000 / speed
								unit:SetPos(p2, t)
								Sleep(t)
								if not IsValid(self) or not IsValid(unit) or not unit:IsValidPos() then
									break
								end
							end
						end
					else
						WaypointsObj.LeadIn(self, unit, entrance)
					end
				end
			end
		end
		if IsValid(self) and IsValid(unit) then
			unit:DetachFromMap()
			unit:SetHolder(self)
		end
		if IsKindOf(unit, "Drone") then
			table.remove_entry(self.drones_entering, unit)
			table.insert_unique(self.drones_exiting, unit)
			if IsValid(unit) then
				unit:SetGameFlags(const.gofSpecialOrientMode)
				unit:SetAxis(axis_z)
				if self == SelectedObj and table.find(self.drones, unit) then
					SelectionArrowRemove(unit)
				end
			end
		end
	end)
	unit:PopAndCallDestructor()
	unit:PopDestructor()
end

function RocketBase:DroneExitQueue(drone)
	RechargeStationBase.DroneExitQueue(self, drone)
	if drone.holder == self and
		(not self.working or drone.command ~= "EmergencyPower") then --since approach is hacked to lead in we have to leadout hackily as well
		self:LeadOut(drone)
	end
end

function RocketBase:SetCount()
	--intentionally empty.
end

function RocketBase:GetLaunchFuel()
	return self.launch_fuel
end

function RocketBase:CreateResourceRequests()
	UniversalStorageDepot.CreateResourceRequests(self)
	
	--remove demand reqs (keep actual reqs so that everything works in unistorage)
	for k, v in pairs(self.demand) do
		table.remove_entry(self.task_requests, v)
	end
	--remove storage flags
	for k, v in pairs(self.supply) do
		v:ClearFlags(const.rfStorageDepot)
		v:AddFlags(const.rfPostInQueue)
	end
	
	local unit_count = self:GetRequestUnitCount(self:GetLaunchFuel())
	self.refuel_request = self:AddDemandRequest("Fuel", self:GetLaunchFuel(), const.rfRestrictorRocket, unit_count)
	
	self:CreateExportRequests()
end

function RocketBase:CreateExportRequests()
	if self.allow_export then
		local unit_count = self:GetRequestUnitCount(self.max_export_storage)
		self.export_requests = { self:AddDemandRequest("PreciousMetals", self.max_export_storage, 0, unit_count) }
	else
		self.export_requests = nil
	end	
end


function RocketBase:GetExportRequest(rocket, res)
	local rocket = rocket or self
	local res = res or "PreciousMetals"
	for _, req in ipairs(rocket.export_requests or empty_table) do
		if req:GetResource() == res then
			return req
		end
	end
end		

function RocketBase:ResetFuelDemandRequests()			
	if #self.command_centers > 0 then
		--reseting reqs with drones working on them may leave them in a broken state,
		--as far as i can tell this can be called from an old thread without passing countdown
		self:InterruptIncomingDronesAndDisconnect()
	end
	
	self.refuel_request:ResetAmount(self:GetLaunchFuel())
	if self.unload_request then
		table.remove_entry(self.task_requests, self.unload_request)
		self.unload_request = nil
	end
	if self.unload_fuel_request then
		table.remove_entry(self.task_requests, self.unload_fuel_request)
		self.unload_fuel_request = nil
	end
end

function RocketBase:ResetDemandRequests()			
	self:ResetFuelDemandRequests()
	local req = self:GetExportRequest()
	if self.allow_export then
		if req then			
			 req:ResetAmount(self.max_export_storage)
		else
			local unit_count = self:GetRequestUnitCount(self.max_export_storage)
			self.export_requests = self.export_requests or {}
			self.export_requests[#self.export_requests + 1] = self:AddDemandRequest("PreciousMetals", self.max_export_storage, 0, unit_count)
		end
	else
		if self.export_requests then
			table.remove_entry(self.task_requests, req)
		end
		self.export_requests = nil
	end
end

function RocketBase:GetStoredExportResourceAmount()
	local amount = 0
	if self.unload_request then
		amount = amount + self.unload_request:GetActualAmount()
	end
	if not self.export_requests then
		return amount
	end
	return amount + self.max_export_storage - self.export_requests[1]:GetActualAmount()
end

local special_cmd = {
	PickUp = true,
	Deliver = true,
	TransferResources = true,
	TransferAllResources = true,
	EmergencyPower = true,
}

function RocketBase:DroneCanApproach(drone, r)
	return true
end

function RocketBase:DroneApproach(drone, r)
	drone:ExitHolder(self)
	if not IsValid(self) then return end
	if special_cmd[drone.command] then
		if IsKindOf(drone, "Drone") then
			if not self:HasSpot(self.drone_entry_spot) or
				drone:GotoBuildingSpot(self, self.drone_entry_spot, nil, 5*guim) and IsValid(self) then
				if self.working then --lead in only if working, no need for drones to climb up to figure out that they have to climb down
					self:LeadIn(drone)
				end
				return true
			end
			return false
		else
			--cpy paste from wasterock droneapproach
			if not self:HasSpot("idle", drone.work_spot_task) then
				--some hacks so drones don't go into the rocks
				local r = 40 * guim --actual rocket rad is huge, so just use this for now
				local d_r = drone:GetRadius()
				local v = self:GetPos() - drone:GetPos()
				v = SetLen(Rotate(v, InteractionRand(360*60, "drone goto pos")), r + d_r)
				v = v + self:GetPos()
				return drone:Goto(v)
			else
				return drone:GotoBuildingSpot(self, drone.work_spot_task)
			end
		end
	else
		return drone:GotoBuildingSpot(self, drone.work_spot_task)
	end
end

function RocketBase:RoverWork(rover, request, resource, amount, reciprocal_req, interaction_type, total_amount)
	StorageDepot.RoverWork(self, rover, request, resource, amount, reciprocal_req, interaction_type, total_amount)
	
	if resource ~= "clean" and resource ~= "repair" 
		and self.export_requests and table.find(self.export_requests, request) then
		
		rover:ContinuousTask(request, interaction_type == "unload" and abs(amount) or amount, "gatherStart", "gatherIdle", "gatherEnd",
		interaction_type == "load" and "Load" or "Unload",	"step", g_Consts.RCRoverTransferResourceWorkTime, "add resource", reciprocal_req, total_amount)
	end
end

function RocketBase:RoverLoadResource(amount, resource, request)
	self:AddResource(amount, resource, true)
end

function RocketBase:AddResource(amount, resource)
	if self.export_requests and #self.export_requests > 0 then
		local idx = table.ifind_if(self.export_requests, function(r) return r:GetResource() == resource end)
		if idx then
			self.export_requests[idx]:AddAmount(-amount)
			return
		end
	end
	UniversalStorageDepot.AddResource(self, amount, resource)
end

function RocketBase:OpenDoor()
	-- open bay door
	self:SetAnim(1, "disembarkStart")
	PlayFX("RocketDoorOpen", "start", self)
	Sleep(self:TimeToAnimEnd())
	self:SetAnim(1, "disembarkIdle")
	PlayFX("RocketDoorOpen", "end", self)
end

function RocketBase:CloseDoor()
	-- close bay door
	self:SetAnim(1, "disembarkEnd")
	PlayFX("RocketDoorClose", "start", self)
	Sleep(self:TimeToAnimEnd())
	self:SetAnim(1, "idle")
	PlayFX("RocketDoorClose", "end", self)
end

function RocketBase:SpawnDronesFromEarth()
	local idx = table.find(self.cargo, "class", "Drone")
	if not idx then
		idx = self.cargo["Drone"] and "Drone"
	end
	
	local spawned_drones = {}

	if idx then
		local number_of_carried_drones = self.cargo[idx].amount
		
		for i = 1, number_of_carried_drones do
			local drone = self:SpawnDrone()
			if drone then table.insert(spawned_drones, drone) end
		end
		
		self.cargo[idx].amount = 0
	end
	
	return spawned_drones
end

function RocketBase:SpawnDrone()
	if #self.drones >= self:GetMaxDrones() then
		return
	end
	
	local drone = self.city:CreateDrone()
	drone:SetCommandCenter(self)
	
	local spawn_pos = self:GetSpotLoc(self:GetSpotBeginIndex(self.drone_spawn_spot))
	drone:SetPos(spawn_pos)
	CreateGameTimeThread(Drone.SetCommand, drone, "Embark")
	return drone
end

function RocketBase:FillTransports() --needs to happen after rover's game init (so default desires have booted)
	local transports = self.rovers.transports
	self.rovers.transports = nil
	
	--get only resources so we don't have to iterate for every rover
	local resources_cargo = {}
	for i = 1, #self.cargo do
		local item = self.cargo[i]
		if GetResourceInfo(item.class) then
			resources_cargo[item.class] = item
		end
	end
	
	for i = 1, #(transports or empty_table) do
		self:FillRCTransportFromCargo(transports[i], resources_cargo)
	end
end

function RocketBase:FillRCTransportFromCargo(rover, resources_cargo)
	for resource, amount in pairs(rover.desired_resource_levels) do
		if amount > 0 and resources_cargo[resource] and resources_cargo[resource].amount > 0 then
			local amount_to_add = Min(amount, resources_cargo[resource].amount * const.ResourceScale)
			rover:AddResource(amount_to_add, resource)
			resources_cargo[resource].amount = resources_cargo[resource].amount - (amount_to_add / const.ResourceScale)
		end
	end
end

function RocketBase:DroneUnloadResource(drone, request, resource, amount)
	drone:PushDestructor(function(drone)
		self:LeadOut(drone)
	end)
	drone:SetCarriedResource(false)
	UniversalStorageDepot.DroneUnloadResource(self, drone, request, resource, amount)
	if request == self.refuel_request then
		self.city:FuelForRocketRefuelingDelivered(amount)
		if self:HasEnoughFuelToLaunch() then
			Msg("RocketRefueled", self)
		end
	elseif request == self.maintenance_request then
		if self:MaintenanceDone() then
			Msg("RocketMaintenanceDone", self)
		end
	elseif self.waiting_resources then
		Wakeup(self.command_thread)
	end
	RebuildInfopanel(self)
	drone:PopAndCallDestructor()
end

function RocketBase:Disembark(crew)
	local domes, safety_dome = GetDomesInWalkableDistance(self.city, self:GetPos())
	for _,unit in pairs(crew) do
		-- disembark colonists & leave them to their affairs
		unit:Appear(self)
		unit:SetCommand("ReturnFromExpedition", self, ChooseDome(unit.traits, domes, safety_dome))
		-- sleep to avoid all colonists disembarking at once
		Sleep(1000 + SessionRandom:Random(0, 500))
	end
end

function RocketBase:DroneLoadResource(drone, request, resource, amount)
	if not drone then
		return UniversalStorageDepot.DroneLoadResource(self, drone, request, resource, amount, true)
	end
	drone:PushDestructor(function(drone)
		self:LeadOut(drone)
	end)
	UniversalStorageDepot.DroneLoadResource(self, drone, request, resource, amount, true)
	drone:SetCarriedResource(resource, amount) --hack
	if self.waiting_resources then
		Wakeup(self.command_thread)
	end
	RebuildInfopanel(self)
	drone:PopAndCallDestructor()
end


function RocketBase:CheckDisembarkationTable()
	local t = (self.disembarking or "")
	for i = #t, 1, -1 do
		local c = t[i]
		if not IsValid(c) or
			not (c.command == false or c.command == "Arrive" or (c.command == "Idle" and c.arriving == self)) then
			table.remove(t, i)
		end
	end
end

function RocketBase:GenerateArrivals(amount, applicants)
	if (amount or 0) <= 0 then
		return
	end
	
	self.disembarking = {}
	self.disembarking_confused = false
	
	local city = self.city
	local domes, safety_dome = GetDomesInWalkableDistance(city, self:GetPos())
	local num_colonists = 0
	local num_tourists = 0
	
	for i = 1, amount do
		local applicant = table.remove(applicants)
		if not applicant then
			break
		else
			if applicant.traits.Tourist then
				num_tourists = num_tourists + 1
			else
				num_colonists = num_colonists + 1
			end
		end
		
		if city.colony:IsTechResearched("SpaceRehabilitation") and city:Random(100) < TechDef.SpaceRehabilitation.param1 then
			for trait in pairs(applicant.traits) do
				local trait_def = TraitPresets[trait]
				-- check trait_def: traits include nationality which doesn't have corresponding data instance
				if trait_def and trait_def.group == "Negative" then
					applicant.traits[trait] = nil
					break
				end
			end
		end
		
		local dome = ChooseDome(applicant.traits, domes, safety_dome)
		
		applicant.emigration_dome = dome -- the colonist will try to reach the dome by foot:
		applicant.city = dome and dome.city or city
		applicant.arriving = self
		assert(not IsValid(applicant))
		local colonist = Colonist:new(applicant, self:GetMapID())
		self.disembarking[#self.disembarking + 1] = colonist
		local colonist_funding = GetMissionSponsor().colonist_funding_on_arrival or 0
		if colonist_funding > 0 then
			UIColony.funds:ChangeFunding(colonist_funding, "Sponsor")
		end
		-- sleep to avoid all colonists disembarking at once
		Sleep(1000 + Random(0, 500))
	end
	
	while #self.disembarking > 0 do
		self:CheckDisembarkationTable()
		Sleep(100)
	end
	self.disembarking = nil
	
	if num_colonists > 0 then
		AddOnScreenNotification("NewColonists", nil, {count = num_colonists}, {self}, self:GetMapID())
	end
	if num_tourists > 0 then
		AddOnScreenNotification("NewTourists", nil, {count = num_tourists}, {self}, self:GetMapID())
	end
	if self.disembarking_confused then
		AddOnScreenNotification("ConfusedColonists", nil, {}, {self:GetPos()}, self:GetMapID())
	end
	if amount > 0 then
		Msg("ColonistsLanded")
	end
end

function RocketBase:EjectColonists()
	local city = self.city or UICity
	for _, item in ipairs(self.cargo or empty_table) do
		if item.class == "Passengers" then
			local applicants = item.applicants_data
			local amount = #applicants
			for i = 1, amount do
				local applicant = table.remove(applicants)
				local domes, safety_dome = GetDomesInWalkableDistance(city, self:GetPos())
				local dome = ChooseDome(applicant.traits, domes, safety_dome)
				applicant.emigration_dome = dome
				applicant.city = dome and dome.city or city
				local colonist = Colonist:new(applicant, self:GetMapID())
				local pt = GetRandomPassableAroundOnMap(self:GetMapID(), self:GetPos(), 10 * guim)
				colonist:SetPos(pt)
				colonist.outside_start = GameTime()
			end
		end
	end
end

function RocketBase:GenerateDepartures(count_earthsick, count_tourists)
end

function RocketBase:HasEnoughFuelToLaunch()
	return self.refuel_request and self.refuel_request:GetActualAmount() <= 0
end

function RocketBase:HasExtraFuel()
	return self.unload_fuel_request and self.unload_fuel_request:GetActualAmount() > 0
end

function RocketBase:MaintenanceDone()
	return not self.maintenance_request or self.maintenance_request:GetActualAmount() <= 0
end

function RocketBase:HasCargoSpaceLeft()
	for i = 1, #(self.export_requests or empty_table) do
		if self.export_requests[i]:GetActualAmount() > 0 then
			return true
		end
	end
end

function RocketBase:IsLaunchValid()
	return self.launch_valid_cmd[self.command]
end

RocketLaunchIssues = {
	missions_suspended = T(14312, "Missions suspended"),
	dust_storm = T(14313, "Dust storm active"),
	not_landed = T(14314, "Rocket has not landed"),
	fuel = T(13852, "Not enough fuel"),
	maintenance = T(14315, "Rocket requires maintenance"),
	disabled = T(14316, "Launch disabled"),
	no_target = T(13850, "No destination set"),
	unloading = T(11409, "Unloading cargo"),
	loading = T(13851, "Loading requested resources")
}

function RocketBase:GetLaunchIssue(skip_flight_ban)
	if not skip_flight_ban and g_Consts.SupplyMissionsEnabled ~= 1 then
		return "missions_suspended"
	end

	if HasDustStorm(self:GetMapID()) and self.affected_by_dust_storm then
		return "dust_storm"
	end
	
	if not self.landed then
		return "not_landed"
	end
	
	if not self:HasEnoughFuelToLaunch() then
		return "fuel"
	end
	
	if not self:MaintenanceDone() then
		return "maintenance"
	end
	
	if self.launch_disabled then
		return "disabled"
	end
	
	local fuel = self:HasExtraFuel()
	if fuel then 
		return "unloading"
	end
	
	if self:IsUnloadingCargo() then
		return "unloading"
	end
end

function RocketBase:IsUnloadingCargo()
	return self:GetStoredAmount() > 0
end

local function CargoLaunchIssue(rocket, host)
	CreateRealTimeThread(function(rocket)
		local res = WaitPopupNotification("LaunchIssue_Cargo", {
			choice1 = T(8013, "Launch anyway (resources will be lost)."), 
			choice2 = T(8014, "Abort the launch sequence."),
		}, false, host)
		
		if res and res == 1 then
			rocket:DepartNow()
		end
	end, rocket)
end

function RocketBase:GetLaunchIssuePopups()
	local launch_issue_popups = { ["missions_suspended"] = function(rocket, host) ShowPopupNotification("LaunchIssue_MissionSuspended", false, false, host) end,
		["dust_storm"] = function(rocket, host) ShowPopupNotification("LaunchIssue_DustStorm", false, false, host) end,
		["not_landed"] = function(rocket, host) ShowPopupNotification("LaunchIssue_NotLanded", false, false, host) end,
		["fuel"] = function(rocket, host) ShowPopupNotification("LaunchIssue_Fuel", false, false, host) end,
		["maintenance"] = function(rocket, host) ShowPopupNotification("LaunchIssue_Maintenance", false, false, host) end,
		["disabled"] = function(rocket, host) ShowPopupNotification("LaunchIssue_Disabled", false, false, host) end,
		["unloading"] = function(rocket, host) CargoLaunchIssue(rocket, host) end,
	}
	return launch_issue_popups
end

function RocketBase:PromptLaunchIssue()
	local issue = self:GetLaunchIssue()
	if issue then
		local popups = self:GetLaunchIssuePopups()
		if popups[issue] then
			popups[issue](self, GetInGameInterface())
			return true
		end
	end
	return false
end

function RocketBase:UILaunch() -- blizzard promised no broadcast	
	if self:IsDemolishing() then
		self:ToggleDemolish()
	end
	
	if not self:PromptLaunchIssue() then
		self:DepartNow()
	end
end

function RocketBase:DepartNow()
	-- all ok
	if self.command~="Countdown" and self.command~="TakeOff" then	
		self:SetCommand("Countdown")
	end
	Msg("RocketManualLaunch", self)
end

function RocketBase:UILaunch_Update(button)
	button:SetEnabled(self.command~="Countdown" and self.command~="TakeOff")
end

function RocketBase:GetUIWarning()
	if not self:MaintenanceDone() then
		return T{12393, "This rocket has malfunctioned and needs <resource(number, maintenance_resource)>.", number = self.maintenance_requirements.amount, maintenance_resource = self.maintenance_requirements.resource}
	end
end

function RocketBase:IsLaunchAutomated()
	return self.auto_export
end

function RocketBase:IsLandAutomated()
	return self.auto_export and IsValid(self.landing_site)
end

function RocketBase:IsBoardingAllowed()
	return self.command == "Refuel" or self.command == "WaitLaunchOrder" or (self.command == "Countdown" and self:IsCargoRampInUse())
end

function RocketBase:IsRocketLanded()
	return self.command == "Refuel" or self.command == "WaitLaunchOrder" or self.command == "Idle"
end

function RocketBase:IsCargoRampInUse()
	return #(self.drones_exiting or empty_table) > 0 or 
			#(self.drones_entering or empty_table) > 0 or 
			#(self.boarding or empty_table) > 0
end

function RocketBase:IsFlightPermitted()
	return (not HasDustStorm(self:GetMapID()) or not self.affected_by_dust_storm)
end

function RocketBase:NeedsRefuel()
	return self.command == "Refuel"
end

function RocketBase:OnPassengersLost()
end

function RocketBase:GetSkins()
	if not self.can_change_skin then
		return empty_table, empty_table
	end
	local trailblazer_entity = g_TrailblazerSkins[self.class]
	local entity = BuildingTemplates[self.template_name].entity
	if entity and trailblazer_entity then
		return { entity, trailblazer_entity }, { self.rocket_palette, self.rocket_palette }
	end
	return empty_table, empty_table
end

-- ui getters
function RocketBase:GetRefuelProgress()
	local extra = self.unload_fuel_request and self.unload_fuel_request:GetActualAmount() or 0
	return self:GetLaunchFuel() - self.refuel_request:GetActualAmount() + extra
end

function RocketBase:GetArrivalTimePercent()
	if not self.launch_time or (self.flight_time or 0) <= 0 then
		return 100
	end
	local t = GameTime() - self.launch_time
	return Min(100, MulDivRound(t, 100, self.flight_time))
end

function RocketBase:GetCargoManifest()
	return FormatCargoManifest(self.cargo)
end

function FormatCargoManifest(cargo)
	if not cargo or #cargo == 0 then
		return T(720, "Nothing")
	end
	
	local texts, resources = {}, {}
	local passenger_texts = {}
	
	for i = 1, #cargo do
		local item = cargo[i]
		if item.amount and item.amount > 0 then
			if item.class == "Passengers" then
				texts[#texts + 1] = T{721, "<number> Passengers", number = item.amount}
			elseif GetResourceInfo(item.class) then
				resources[#resources + 1] = T{722, "<resource(amount,res)>", amount = item.amount*const.ResourceScale, res = item.class}
			elseif BuildingTemplates[item.class] then
				local def = BuildingTemplates[item.class]
				local name = item.amount > 1 and def.display_name_pl or def.display_name
				texts[#texts + 1] = T{723, "<number> <name>", number = item.amount, name = name}
			elseif table.find(GetSortedColonistSpecializationTable(), item.class) then
				local name = const.ColonistSpecialization[item.class].display_name
				table.insert(passenger_texts, T{723, "<number> <name>", number = item.amount, name = name})
			else
				local def = g_Classes[item.class]
				if def then
					texts[#texts + 1] = T{723, "<number> <name>", number = item.amount, name = def.display_name}
				else
					assert(false, "invalid class (" .. tostring(item.class) .. ") in rocket cargo")
				end
			end
		end
	end
	
	if #resources > 0 then
		table.sortby_field(resources, "res")
		texts[#texts + 1] = table.concat(resources, " ")
	end
	
	table.iappend(texts, passenger_texts)
	
	if #texts == 0 then
		return T(10887, "No Cargo")
	end
	
	return table.concat(texts, "<newline>")
end

function RocketBase:GetDisplayName()
	if self:HasMember("name") then
		return Untranslated(self.name)
	end
	
	return self.display_name
end

function RocketBase:GetUIOrbitTimeLeft()
	if not self.orbit_arrive_time then
		return ""
	end
	
	local ttd = (self.orbit_arrive_time + self.passenger_orbit_life - GameTime()) / const.HourDuration
	if ttd <= 0 then
		return T(8053, "< 1")
	end	
	return ttd
end

function RocketBase:ApplyToGrids()
	--intentionally empty, rocket landing site applies/removes buildability for us
end

function RocketBase:RemoveFromGrids()
	--intentionally empty, rocket landing site applies/removes buildability for us
end

function RocketBase:CheatRefuel()
	if not self:HasEnoughFuelToLaunch() then
		self.refuel_request:ResetAmount(0)
	end
	
	if self.command == "Refuel" then
		self:Refuel(true)
	end
end

function RocketBase:CheatLaunch()
	self:SetCommand("Countdown")
end

function RocketBase:GetStoredAmount(resource)
	local stored = UniversalStorageDepot.GetStoredAmount(self, resource)
	local unload = 0
	if self.unload_request and (not resource or self.unload_request:GetResource() == resource) then
		unload = self.unload_request:GetActualAmount()
		stored = stored + unload
	end
	return stored, unload
end

function RocketBase:GetUIExportStatus()
end

function RocketBase:GetUIRocketStatus()
	if self.command == "FlyToMars" or self.command == "FlyToEarth" then
		return T(709, "In transit")
	end
	if self.command == "LandOnMars" then
		return T(7897, "<green>Landing</green>")
	end
	if self.command == "Unload" then
		return T(7898, "<green>Unloading cargo</green>")
	end
	if self.exported_amount and self.command == "FlyToEarth" then
		return T(284, "<green>Exporting</green><right><preciousmetals(exported_amount, max_export_storage)>")
	end
	local items = {}
	if self:GetLaunchFuel()~=0 then
		items[#items +1] = T{285, "Refueling<right><current>/<fuel(launch_fuel)>", current = self:GetRefuelProgress() / const.ResourceScale}
	end	
	local export_status = self:GetUIExportStatus()
	if export_status then
		items[#items + 1] = export_status
	end
	if self.departures then
		items[#items +1] = T(12711, "Departing Tourists<right><tourist(NumBoardedTourists)>")
	end
	
	if self.command == "Refuel" then
		items[#items+1] = T(7901, "<green>Waiting to refuel</green>")
	elseif self.command == "WaitLaunchOrder" then	
		if self:GetStoredAmount() > 0 then
			items[#items+1] = T(7899, "<green>Waiting for resource unload</green>")
		elseif self:IsLaunchAutomated() and self:HasCargoSpaceLeft() then
			items[#items+1] = T(8493, "Waiting cargo")
		elseif self.departures and #self.departures > 0 then
			items[#items+1] = T(288, "<green>Waiting departures</green>")
		else
			items[#items+1] = T(8033, "<green>Ready for take-off</green>")
		end
	elseif self.command == "WaitMaintenance" then
		local maintenance_request = self.maintenance_request
		local maintenance_requirements = self.maintenance_requirements
		items[#items + 1] = T{11067, "Maintenance<right><current>/<resource(maintenance_amount, maintenance_resource)>", current = (maintenance_requirements.amount - maintenance_request:GetActualAmount()) / const.ResourceScale, maintenance_amount = maintenance_requirements.amount, maintenance_resource = maintenance_requirements.resource}
	elseif self.command == "Countdown" then
		items[#items+1] = T(7900, "<green>Take-off in progress</green>")
	elseif self.command == "Takeoff" then
		items[#items+1] = T(7900, "<green>Take-off in progress</green>")
	end
	return table.concat(items, "<newline><left>")
end

function RocketBase:GetUILaunchStatus()
	if self.command == "FlyToMars" or self.command == "FlyToEarth" then
		return T(709, "In transit")
	end
	if self.command == "LandOnMars" then
		return T(282, "Landing")
	end
	if self.command == "Unload" then
		return T(11409, "Unloading cargo")
	end
	if self.command == "Countdown" or self.command == "Takeoff" then
		return T(289, "Take-off in progress")
	end
	if self.command == "Refuel" then
		return T(7353, "Waiting to refuel")
	end
	if self.command == "WaitMaintenance" then
		return T(11068, "Waiting for maintenance")
	end
	if self.command == "WaitLaunchOrder" and self:GetStoredAmount() > 0 then
		return T(287, "Waiting for resource unload")
	end
	if self:IsLaunchAutomated() and self:HasCargoSpaceLeft() then
		return T(8493, "Waiting cargo")
	end
	return T(8015, "Ready for take-off")
end

function RocketBase:GetDronesCount()
	return #(self.drones or "")
end

function RocketBase:IsRocketStatus(status)
	if status == "on earth" then return self.command == "OnEarth" end
	if status == "arriving" then return self.command == "FlyToMars" end
	if status == "in orbit" then return self.command == "WaitInOrbit" end
	if status == "landed" then
		return self.command == "Unload" or self.command == "Refuel" or self.command == "WaitLaunchOrder"
	end
	if status == "takeoff" then
		return self.command == "Countdown" or self.command == "Takeoff"
	end
	if status == "departing" then return self.command == "FlyToEarth" end
end

function RocketBase:AreNightLightsAllowed()
	return true
end
