--container for common stuffs between RC Commander and workshop rover.
DefineClass.BaseRover = {
	__parents = {
		"Demolishable",
		"DroneBase",
		"PinnableObject",
		"SkinChangeable",
		"TaskRequester",
		"DepositRevealer",
	},
	
	SelectionClass = "BaseRover",
	display_name_pl = T(12081, "Rovers"),

	move_speed = 1000,
	scale = 100,
	follow_camera_vertical_offset = 26 * guim,
	reveal_range = 180,

	pfclass = 1,
	radius = 6*guim,
	collision_radius = 6*guim,
	orient_mode = "terrain_large",

	--malfunction presentation
	malfunction_start_state = false,
	malfunction_idle_state = false,
	malfunction_end_state = false,

	fx_actor_base_class = "Rover",
	direction_arrow_scale = 260,
	
	-- pin section
	pin_on_start = true,
	dust_devil_malfunction_chance = 15,

	override_ui_status = false,
	
	auto_connect = false,
	repair_work_request = false,
	repair_work_amount_on_malfunction = 5000 * 45, --about 45 seconds of work for 1 drone
	
	--inheritance, wrapper functions because of load order
	Gossip = function(self, ...) Unit.Gossip(self, ...) end,
	GossipName = function(self, ...) Unit.GossipName(self, ...) end,
	ip_template = "ipRover",
	
	palette = false,
	
	work_spot_task = "Workrover",
	recharging_other_rover = false,
	
	on_demolish_resource_refund = { Metals = 5 * const.ResourceScale, Polymers = 5 * const.ResourceScale },
	operation_interrupted_reason = false,
	
	unreachable_objects = false,
	
	environment_fx = {
		base = "Rover",
		Asteroid = "RoverFlying",
	},
}

function BaseRover:CreateResourceRequests()
	self.repair_work_request = self:AddWorkRequest("repair", 0, 0, 3)
end

function BaseRover.RepairDroneCallback(drone)
	if drone.w_request:GetActualAmount() <= 0 then
		--maintenance finished cleanly.
		drone.target:Repair()
	end
end

function BaseRover:IsStorageFull()
end

function BaseRover:DroneWork(drone, request, resource, amount)
	if request == self.repair_work_request then
		amount = DroneResourceUnits.repair

		drone:PushDestructor(self.RepairDroneCallback)

		drone:ContinuousTask(request, amount, g_Consts.DroneBuildingRepairBatteryUse, "repairBuildingStart", "repairBuildingIdle", "repairBuildingEnd", "Repair")
		drone:PopAndCallDestructor()
	end
end

function BaseRover:ContinuousTask(request, amount, anim_start, anim_idle, anim_end, fx, fx_work_moment, work_time, add_res, reciprocal_request, total_amount)
end

function BaseRover:GameInit()
	SetPaletteFromClassMember(self)
	self:AddToLabels()
	self:SetState("idle")
	self:SetMoveSpeed(self.move_speed)
	self:SetMoveAnim("moveWalk")
	self:SetScale(self.scale)
	self:SetRotationTime(500)
		-- choose name
	if self.name == "" then
		self.name = GenerateMachineName(self.class)
	end
end

function BaseRover:Done()
	self:RemoveFromLabels()
	DiscardNewObjsNotif(g_DestroyedVehicles, self, self:GetMapID())
end

function BaseRover:AddToLabels()
	self.city:AddToLabel("Unit", self)
	self.city:AddToLabel("Rover", self)
	self.city:AddToLabel(self.class, self)
	
	DepositRevealer.AddToLabels(self)
end

function BaseRover:RemoveFromLabels()
	self.city:RemoveFromLabel("Unit", self)
	self.city:RemoveFromLabel("Rover", self)
	self.city:RemoveFromLabel(self.class, self)
	
	DepositRevealer.RemoveFromLabels(self)
end

function BaseRover:OnDemolish()
	local refund_resources = self.on_demolish_resource_refund or empty_table
	local pos = self:GetVisualPos()
	local angle = self:GetAngle()
	
	for resource, amount in pairs(refund_resources) do
		if amount > 0 then
			PlaceResourceStockpile_Delayed(pos, self:GetMapID(), resource, amount, angle, true)
		end
	end
end

function BaseRover:ShowUISectionElectricityProduction()
end

function BaseRover:ShowUISectionElectricityGrid()
end

function BaseRover:GetSelectorItems()
end

function BaseRover:GetRefundResources()
	local data = self.on_demolish_resource_refund or empty_table
	local t = {}
	for res, amount in sorted_pairs(data) do
		t[#t+1] = {resource = res, amount = amount}
	end
	return t
end

function BaseRover:AddDust(dust)
	local dust_max = self.dust_max * (100 + g_Consts.DroneMaxDustBonus) / 100
	self.dust = Max(Min(dust_max, self.dust + dust), 0)
	local normalized_dust = MulDivRound(self.dust, 255, dust_max)
	self:SetDust(normalized_dust, const.DustMaterialExterior)
end

function BaseRover:CheatAddDustRC()
	self:AddDust(self.dust_max)
end

function BaseRover:CheatRemoveDustRC()
	self:AddDust(-self.dust_max)
end

function OnMsg.SelectionAdded(obj)
	if IsKindOf(obj, "BaseRover") then
		SetSubsurfaceDepositsVisible(true)
	end
end

function OnMsg.SelectionRemoved(obj)
	if IsKindOf(obj, "BaseRover") then
		local no_rovers = true
		for i=1,#Selection do
			if IsKindOf(Selection[i], "BaseRover") then
				no_rovers = false
				break
			end
		end
		if no_rovers then
			SetSubsurfaceDepositsVisible(false)
		end
	end
end

function BaseRover:CancelUnitDirectionMode()
	ResetUnitControlInteractionMode(false, self)
end

function BaseRover:Malfunction(suppress_repair_request)
	DroneBase.Malfunction(self)
	
	self:StartFX("Breakdown")
	
	self:CancelUnitDirectionMode()
	self:SetPos(self:GetVisualPos())
	
	if not suppress_repair_request then
		self.repair_work_request:AddAmount(self.repair_work_amount_on_malfunction)
		if not self.auto_connect then
			self.auto_connect = true
			self:ConnectToCommandCenters()
		end
	end
	
	RebuildInfopanel(self)
	
	if self.malfunction_start_state then
		self:PlayState(self.malfunction_start_state, 1)
		if not IsValid(self) then return end
	end
	
	self:SetEnumFlags(const.efCollision + const.efApplyToGrids)
	self:PushDestructor(function(self)
		if IsValid(self) then
			self:ClearEnumFlags(const.efCollision + const.efApplyToGrids)
		end
	end)
	
	if self.malfunction_idle_state then
		self:SetState(self.malfunction_idle_state)
	else
		self:SetState("idle")
	end
	
	ObjModified(self)
	Halt()
end

function BaseRover:CheatMalfunction()
	self.dust = self.dust_max + 10 
	self:SetCommand("Malfunction")
end

function BaseRover:CheatRepair()
	self.command = ""
	self:SetCommand("Repair")
end

function BaseRover:Repair()
	DroneBase.Repair(self)
	
	if not self:IsMalfunctioned() or not IsValid(self) then return end
	
	self.auto_connect = false
	self:DisconnectFromCommandCenters()
	
	if self.malfunction_end_state then
		self:PlayState(self.malfunction_end_state, 1)
		if not IsValid(self) then return end
	end
	
	self:SetState("idle")
	self:AddDust(-self.dust_max)
	
	Msg("Repaired", self)
	
	--hacky command exit
	self.command = "" --so we get around BaseRover:SetCommand's "Malfunction" early out.
	self:SetCommand("Idle")
	
	RebuildInfopanel(self)
end

local function GetDroneApproachPos(object, drone)
		local c, r = object:GetBSphere()
		local d_r = drone:GetRadius()
		local v = object:GetPos() - drone:GetPos()
		v = SetLen(Rotate(v, InteractionRand(360*60, "drone goto pos")), r + d_r) --better randomize it then closest to avoid drone collisions
		v = v + object:GetPos()
	return v
end

function BaseRover:DroneCanApproach(drone, reason)
	if not IsValid(self) then return false end
	
	if not self:HasSpot(self:GetState(), drone.work_spot_task) then
		local v = GetDroneApproachPos(self, drone)
		return drone:HasPath(v)
	else
		return drone:CanReachBuildingSpot(self, drone.work_spot_task)
	end
end

function BaseRover:DroneApproach(drone, reason)
	drone:ExitHolder(self)
	
	if not IsValid(self) then return false end
	
	if not self:HasSpot(self:GetState(), drone.work_spot_task) then
		local v = GetDroneApproachPos(self, drone)
		return drone:Goto(v)
	else
		return drone:GotoBuildingSpot(self, drone.work_spot_task)
	end
end

function BaseRover:GetMalfunctionRepairProgress()
	return self.command == "Malfunction" and 100 - MulDivRound(self.repair_work_request:GetActualAmount(), 100, self.repair_work_amount_on_malfunction) or 0
end

function BaseRover:SetCommandUserInteraction(...)
	GetCommandFunc(self)(self, ...)
end

function BaseRover:SetCommand(command, ...)
	if command == "Malfunction" and self.command == "Malfunction" then
		self.dont_clear_queue = nil
		return
	elseif command and self.command == "Malfunction" then --don't interrupt "Malfunction", wait for it to end on its own
		self.dont_clear_queue = nil
		return
	end
	
	DroneBase.SetCommand(self, command, ...)
end

BaseRover.SetDisablingCommand = BaseRover.SetCommand
BaseRover.OnDead = empty_func

function BaseRover:Dead()
	self.dont_interrupt_current_command = true
	
	for i, entry in ipairs(RCRoverResources) do
		local res = entry.resource
		local amount = self.resource_storage[res]
		PlaceResourceStockpile_Delayed(self:GetVisualPos(), self:GetMapID(), res, amount, self:GetAngle(), true)
	end

	if not g_Tutorial then
		RequestNewObjsNotif(g_DestroyedVehicles, self, self:GetMapID())
	end

	self:OnDead()

	RebuildInfopanel(self)
	self:Gossip("Dead")
	self:StartFX("Dead")
	--stop
	self:ClearPath()
	self:SetPos(self:GetVisualPos())
	--play animations
	self:PlayState("destroyed", 1)
	self:SetState("destroyedIdle")
	self:SetIsNightLightPossible(false)
	self:SetEnumFlags(const.efCollision + const.efApplyToGrids)
	Halt()
end

function BaseRover:MoveSleep(time)
	Sleep(time)
	PlayFX("Moving", "move", self)
end

function BaseRover:GetDisplayName()
	return Untranslated(self.name)
end
	
function OnMsg.GatherLabels(labels)
	labels.Unit = true
	labels.Rover = true
	labels.RCRover = true
	labels.ExplorerRover = true
	labels.RCTransport = true
end

local charge_range = 2
function BaseRover:GetCableNearby(rad) --within charge range
	rad = (rad or charge_range)
	
	local lst = GetRealm(self):MapGet(self, "hex", rad + 1, "ElectricityGridElement", function(o) return o:GetGameFlags(const.gofUnderConstruction) == 0 end  )
	local c = FindNearestObject(lst, self)
	return c and HexAxialDistance(c, self) <= rad and c or false
end

function BaseRover:CanInteractWithObject(obj, interaction_mode)
	if not IsValid(obj) then return false end
	if self.command == "Dead" then return false end
	if obj:HasMember("IsShroudedInRubble") and obj:IsShroudedInRubble() then
		return false, NotWorkingWarning.ShroudedInRubble
	end
	
	local can_interact, action = DroneBase.CanInteractWithObject(self, obj, interaction_mode)
	if can_interact then
		return can_interact, action
	end
	
	if IsMoveInteractionMode(self.interaction_mode) then
		if IsKindOf(obj, "Tunnel") and obj.working then
			return true, T{9616, "<UnitMoveControl('ButtonA',interaction_mode)>: Use Tunnel",self} --UseTunnel
		end
	end
	
	return false
end

function BaseRover:InteractWithObject(obj, interaction_mode)
	if not IsValid(obj) then return false end
	if self.command=="Dead" then return false end
	
	local interacted = DroneBase.InteractWithObject(self, obj, interaction_mode)
	
	if not interacted and IsMoveInteractionMode(self.interaction_mode) then
		if IsKindOf(obj, "Tunnel") and obj.working then
			GetCommandFunc(self)(self, "UseTunnel", obj)
			SetUnitControlInteractionMode(self, false) --toggle button
		end
	end
end

function BaseRover:CanBeControlled()
	if self.command=="Dead" or self.command == "Malfunction" then return false end
	return DroneBase.CanBeControlled(self)
end

--while we are part of the electricity grid we need to implement these
function BaseRover:GetSupplyGridConnectionShapePoints(supply_resource) 
	return self:GetShapePoints()
end

function BaseRover:GetUIWarning()
	if self.demolishing then
		return T{7322, "The Rover will be salvaged in <em><countdown></em> sec.",
			countdown = self.demolishing_countdown / 1000,
		}
	elseif self.command == "Malfunction" then
		return T(65, "Malfunctioned")
	end
	return self.operation_interrupted_reason
end

function BaseRover:OperationInterrupted(reason)
	if self:HasMoreCommandsAfterThis() then return end --dont halt in err state if there are things to do
	
	self:SetState("idle")
	self.operation_interrupted_reason = reason
	RebuildInfopanel(self)
	self:PushDestructor(function(self)
		self.operation_interrupted_reason = false
		RebuildInfopanel(self)
	end)
	Halt()
end

function RoverStatus()
	return 
	{
		section = {name = T(49, "Status"), icon = "UI/Icons/Sections/sensor.tga", rollover_t = {
			content = {title = T(49, "Status"), descr = T(50, "Status and current task of this vehicle.")}
		}},
		T(51, "<ui_command>"),
		
		function(obj)
			if obj.command == "Siege" or obj.command == "Unsiege" then
				return false
			end	
			if obj.command=="Analyze" then
				return {
					{
						id = "ScanAnomalyProgress",
						ui = "simple_progress_bar",
						rollover_t = {content = {title = T(25, "Anomaly Scanning"), descr = T(52, "Progress<right><percent(ScanAnomalyProgress)>")}},
					},
					{id = false, ui = "space"},
				}
			elseif obj.command == "Malfunction" then
				return {
				{
					id = "MalfunctionRepairProgress",
					ui = "simple_progress_bar",
					rollover_t = {content = {title = T(53, "Malfunction"), descr = T(54, "This vehicle has malfunctioned. It has to be repaired by Drones.")}},
				},
				{id = false, ui = "space"},
				}
			end
		end,
		
	}
end

RoverCommands = {
	Analyze = T(55, "Analyzing an Anomaly"),
	AutoTransportRoute = T(56, "On a transport route"),
	RunSafariRoute = T(12704, "On a Safari"),
	Construct = T(57, "Constructing"),
	Dead = T(58, "<red>This unit has been destroyed. Salvage for materials.<red>"),
	Disembarking = T(59, "Disembarking"),
	DumpCargo = T(60, "Unloading cargo at target coordinates"),
	EqualizePowerWithOtherRover = T(61, "Transfering power between vehicles"),
	ExitImpassable = T(62, "Moving to avoid obstruction"),
	Goto = T(63, "Travelling"),
	GotoFromUser = T(63, "Travelling"),
	Idle = T(6722, "Idle"),
	Load = T(64, "Loading resources at target coordinates"),	
	LoadWithNoTarget = T(64, "Loading resources at target coordinates"),	
	Malfunction = T(7610, "Waiting for repairs"),
	BeingRepaired = T(8028, "Undergoing repairs"),
	PickupResource = T(67, "Loading resources"),
	RepairDrone = T(70, "Repairing Drones"),
	Siege = T(71, "Commanding Drones"),
	TransferAllResources = T(72, "Transferring resources"),
	TransferResources = T(72, "Transferring resources"),
	Unload = T(73, "Unloading resources at target coordinates"),
	Unsiege = T(74, "Recalling remote Drones"),
	WaitingResources = T(7683, "Waiting for resources at construction site"),
	Work = T(76, "Performing maintenance"),
	RepairBuilding = T(76, "Performing maintenance"),
	UseTunnel = T(6723, "Going through a tunnel"),
	LoadingComplete = T(8490, "Loading complete"),
	OperationInterrupted = T(9827, "Command interrupted"),
	CleaningObstructors = T(12151, "Removing obstructing objects"),
	GatheringWasteRock = T(12329, "Gathering Waste Rock for landscape project"),
	DeliveringWasteRock = T(12330, "Delivering Waste Rock to landscape project"),
	-- attack rover commands
	Roam = T(6724, "Roaming"),
	Attack = T(6725, "Attacking"),
	Reload = T(6726, "Reloading"),
	GotoAndEmbark =  T(11216, "Boarding Rocket"),
	Landscaping = T(12424, "Landscaping"),
	UseElevator = T(13878, "Going to an elevator"),
	ClearRubble = T(13948, "Clearing Rubble"),
}

function BaseRover:Getui_command(for_cmd)
	local ui_command = for_cmd or self.override_ui_status and RoverCommands[self.override_ui_status] and self.override_ui_status or self.command
	
	if ui_command == "Malfunction" and self:GetMalfunctionRepairProgress() > 0 then
		ui_command = "BeingRepaired"		
	end
	
	return RoverCommands[ui_command] or T(77, "Unknown")
end

function BaseRover:Getui_command_queue()
	local lines = {}
	local q = self.command_queue
	local count = Min(#(q or ""), 10)
	for i = 1, count do
		local cmd = type(q[i] == "table") and q[i][1] or q[i]
		local cmd_str = self:Getui_command(cmd)
		table.insert(lines, cmd_str)
	end
	
	return table.concat(lines, "\n")
end

function BaseRover:Getui_command_queue_title()
	local tasks = (IsKindOf(self, "AutoMode") and self:IsAutoModeEnabled() and T(12259, "Automated")) or #(self.command_queue or "")
	return T{12260, "Queued tasks<right><number>", number = tasks}
end

local function SelectRover(dir)
	local igi = GetInGameInterface()
	local dlg = GetHUD()
	if igi and dlg and dlg:GetVisible() and igi:GetVisible() then
		local rovers = UICity.labels.Rover or {}
		local idx = table.find(rovers, SelectedObj)
		local rover = idx and rovers[idx + dir] or rovers[dir == 1 and 1 or #rovers]
		ViewAndSelectObject(rover)
	end
end

function CycleRovers()
	NextRover()
end

function NextRover()
	SelectRover(1)
end

function PreviousRover()
	SelectRover(-1)
end

function PlaceRover()
	local o = PlaceObject("RCRover")
	o:SetPos(GetTerrainCursor())
end

function SetPaletteFromClassMember(obj)
	local cm1, cm2, cm3, cm4 = DecodePalette(obj.palette)
	SetObjectPaletteRecursive(obj, cm1, cm2, cm3, cm4)
end

function BaseRover:GetSkins()
	local trailblazer_entity = g_TrailblazerSkins[self.class]
	local entity = g_Classes[self.class].entity
	if entity and trailblazer_entity then
		return { entity, trailblazer_entity }, { self.palette, self.palette }
	end
	return empty_table, empty_table
end

--ui hyper links use this
function BaseRover:Select()
	SelectObj(self)
	ViewObjectMars(self:GetLogicalPos())
end

function BaseRover:CanDemolish()
	return not g_Tutorial and Demolishable.CanDemolish(self)
end

----

if Platform.editor then

function OnMsg.GatherFXActors(list)
	list[#list + 1] = "Rover"
end

end

--TODO: remove after saves prior lua rev 233621 stop being supported:
BaseRover.ApplyBatteryChange = empty_func
BaseRover.StopBatteryThread = empty_func
BaseRover.SetSupply = empty_func
BaseRover.TryRechargeFromRoute = empty_func

DefineClass.NotifyMeOnCableDeath = {
	__parents = {"Object"},
	entity = "InvisibleObject",
	parent_rover = false,
}

function NotifyMeOnCableDeath:Dispose()
	if IsValid(self) then
		self.parent_rover = nil
		DoneObject(self)
	end
end

function NotifyMeOnCableDeath:Done()
	if self.parent_rover then
		self.parent_rover:OnChargingCableDestroyed()
		self.parent_rover = nil
	end
end
--end: TODO: remove after saves prior lua rev 233621 stop being supported:
function BaseRover:Work(request, resource, amount)
	if not request:AssignUnit(amount) then
		return
	end
	self:PushDestructor(function(self)
		request:UnassignUnit(amount, false)
	end)
	
	local building = request:GetBuilding()
	if not IsValid(building) then
		self:PopAndCallDestructor()
		Sleep(1000)
		return
	end
	self:Gossip("Work", building:GossipName(), building.handle, resource, amount)
	if not building:DroneApproach(self, resource) then
		self:PopAndCallDestructor()
		Sleep(1000)
		return
	end
	self:Gossip("working", building:GossipName(), building.handle, resource, amount)
	building:RoverWork(self, request, resource, amount)
	self:PopAndCallDestructor()
end

local function OnRoverCommandAIResearched()
	g_RoverAIResearched = true
	MapsForEach("map", "BaseRover", function(r)
		if IsKindOf(r, "AutoMode") and (r.command == "Idle" or r.command == "LoadingComplete") then
			r:SetCommand(r.command)
			if r == SelectedObj then
				ObjModified(r)
			end
		end
	end)
end

GlobalVar("g_RoverAIResearched", false)
function OnMsg.TechResearched(tech_id, research, first_time)
	if tech_id == "RoverCommandAI" then
		OnRoverCommandAIResearched()
	end
end

function SavegameFixups.BootNewRoverCommandAI()
	if UIColony:IsTechResearched("RoverCommandAI") then
		OnRoverCommandAIResearched()
	end
end

function SavegameFixups.AddRoverChildrenLabels()
	for _,city in ipairs(Cities) do
		for _,rover in ipairs(city.labels.RCTransport or empty_table) do
			city:AddToLabel("RCTransportAndChildren", rover)
		end

		for _,rover in ipairs(city.labels.RCRover or empty_table) do
			city:AddToLabel("RCRoverAndChildren", rover)
		end
	end
end

function BaseRover:UnreachableObjectsInvalidated()
	self.unreachable_objects = false
end

function BaseRover:GetUnreachableObjectsTable()
	if not self.unreachable_objects then
		self.unreachable_objects = setmetatable({}, weak_keys_meta)
	end
	return self.unreachable_objects
end

function BaseRover:GotoAndEmbark(rocket)
	self:PushDestructor(function(self)
		self.control_override = nil
		self.embark_target = nil
	end, self)
	self.control_override = true
	self.embark_target = rocket

	local pos, angle = rocket:GetSpotLoc(rocket:GetSpotBeginIndex("Roverout"))
	self:Unsiege()
	self:Goto(pos)
	self:SetPos(pos, 250)
	self:SetAngle(angle, 250)

	if not IsValid(rocket) or not rocket:IsValidPos() or not rocket:IsBoardingAllowed() then 
		self:PopAndCallDestructor()
		return 
	end

	table.insert(rocket.boarding, self)
	self:PushDestructor(function(self)
		table.remove_value(rocket.boarding, self)
		rocket.expedition.rover = self
	end)
	
	self:SetAnim(1, "disembarkLoad2")
	Sleep(self:TimeToAnimEnd())

	self:PopAndCallDestructor()
	
	if not IsValid(rocket) then return end

	self:SetHolder(rocket)
	self:SetCommand("Disappear", "keep in holder")
end

function BaseRover:IsDisabled()
	return not self:IsMalfunctioned() and self.command == "Dead"
end


local function InvalidateAllRoverUnreachables()
	MapsForEach("map", "BaseRover", function(r)
		if IsKindOf(r, "AutoMode") then
			r:Notify("UnreachableObjectsInvalidated")
		end
	end)
end

OnMsg.PFTunnelChanged = InvalidateAllRoverUnreachables
OnMsg.LandscapeCompleted = InvalidateAllRoverUnreachables