const.BreakDrainModifierPct = 200
const.BreakDrainPowerMin = 10000
const.BreakDrainPowerMax = 15000
const.BreakDrainOxygenMin = 3000
const.BreakDrainOxygenMax = 6000
const.BreakDrainWaterMin = 4000
const.BreakDrainWaterMax = 8000

DefineClass.BreakableSupplyGridElement = {
	__parents = { "TaskRequester", },
	
	auto_connect = false,
	priority = 5, --very high consumption priority, so that leaks are serviced first by the grid
	
	supply_resource = false,
	air = false, --we are going to create/destroy this element when we break/repair, if we are pipe
	
	repair_resource_request = false,
	repair_work_request = false,
	fx_params = false,
}

GlobalVar("g_NewLeak", false)

function SavegameFixups.RestartHandleLeakDetectedNotifThread()
	RestartGlobalGameTimeThread("LeakDetectedNotif")
end

function HandleLeakDetectedNotif()	
	for _,map_id in ipairs(GetLoadedMaps()) do
		local pipe_leaks = table.ifilter(g_BrokenSupplyGridElements.water, function(k,v) return v:GetMapID() == map_id end)
		local cable_faults = table.ifilter(g_BrokenSupplyGridElements.electricity, function(k,v) return v:GetMapID() == map_id end)
		UpdateLeakDetectedNotification(pipe_leaks, cable_faults, map_id)
	end
end

function UpdateLeakDetectedNotification(pipe_leaks, cable_faults, map_id)
	if #pipe_leaks + #cable_faults == 0 then
		RemoveOnScreenNotification("LeakDetected", map_id)
	elseif g_NewLeak or IsOnScreenNotificationShown("LeakDetected") then
		g_NewLeak = false
		local air_lost = 0
		local water_lost = 0
		for i = 1, #pipe_leaks do
			if pipe_leaks[i].air and pipe_leaks[i].air.current_consumption then
				air_lost = air_lost + pipe_leaks[i].air.current_consumption
			end
			if pipe_leaks[i].water and pipe_leaks[i].water.current_consumption then
				water_lost = water_lost + pipe_leaks[i].water.current_consumption
			end
		end
		local power_lost = 0
		for i = 1, #cable_faults do
			if cable_faults[i].electricity and cable_faults[i].electricity.current_consumption then
				power_lost = power_lost + cable_faults[i].electricity.current_consumption
			end
		end
		local displayed_in_notif = table.iappend(table.copy(pipe_leaks), cable_faults)
		local text
		if #cable_faults > 0 then
			if #pipe_leaks > 0 then
				text = T{10981, "<power(power)> <air(air)> <water(water)>", power = power_lost, air = air_lost, water = water_lost}
			else
				text = T{10982, "<power(power)>", power = power_lost}
			end
		elseif #pipe_leaks > 0 then
			text = T{10983, "<air(air)> <water(water)>", air = air_lost, water = water_lost}
		end
		local rollover = T{10984, "Cable faults: <cables><newline>Pipe leaks: <pipes>", cables = #cable_faults, pipes = #pipe_leaks}
		AddOnScreenNotification("LeakDetected", nil, { leaks = text, rollover_title = T(522588249261, "Leak Detected"), rollover_text = rollover }, displayed_in_notif, map_id)
	end
end

GlobalGameTimeThread("LeakDetectedNotif", function()
	while true do
		Sleep(3000)
		HandleLeakDetectedNotif()
	end
end)

function BreakableSupplyGridElement:Init()
	if IsKindOf(self, "ElectricityGridElement") then
		self.supply_resource = "electricity"
	else
		self.supply_resource = "water"
	end
end

function BreakableSupplyGridElement:InternalCreateResourceRequests()
	self.repair_resource_request = self:AddDemandRequest("Metals", 0, 0, 1)
	self.repair_work_request = self:AddWorkRequest("repair", 0, 0, 1)
end

function SavegameFixups.ClearSupplyGridElementRequests()
	MapForEach("map", "BreakableSupplyGridElement", function(o)
			if not o.auto_connect then
				o.task_requests = {}
			else
				o:DisconnectFromCommandCenters()
				for i = #o.task_requests, 1, -1 do
					local r = o.task_requests[i]
					if r ~= o.repair_resource_request
						and r ~= o.repair_work_request then
						table.remove(o.task_requests, i)
					end
				end
				o:ConnectToCommandCenters()
			end
		end)
end

function BreakableSupplyGridElement:InternalDestroyResourceRequests()
	assert(#self.command_centers == 0)
	table.remove_entry(self.task_requests, self.repair_resource_request)
	self.repair_resource_request = nil --lua tables, just kill reference
	table.remove_entry(self.task_requests, self.repair_work_request)
	self.repair_work_request = nil
end

function BreakableSupplyGridElement:GetPriorityForRequest(req)
	if req == self.repair_resource_request or req == self.repair_work_request then
		return 3 --Drones automatically repair cables with the priority of cable construction.
	else
		--we use our priority to force our consumer element to be serviced first, 
		--however asserts will happen if we go above or below known priorities in DroneHub.lua code
		return Clamp(TaskRequester.GetPriorityForRequest(self, req), -1, const.MaxBuildingPriority)
	end
end

GlobalVar("g_BrokenSupplyGridElements", function() return { electricity = {}, water = {} } end)

function BreakableSupplyGridElement:IsBroken()
	return self.auto_connect == true
end

function BreakableSupplyGridElement:CanBreak()
	if self.auto_connect == true then return false end --broken
	if self.is_switch then return false end --switch
	if self.chain then return false end --in unbuildable
	
	return true
end

function BreakableSupplyGridElement:Break()
	assert(IsValid(self))
	if not self:CanBreak() then return end
	--remove our supply element, upgrade it to a consumption element, add it again
	local element = self[self.supply_resource]
	local grid = element.grid
	grid:RemoveElement(element)
	
	element.variable_consumption = true --consume as much as available
	if self.supply_resource == "electricity" then
		local consumption = self:Random(const.BreakDrainPowerMax - const.BreakDrainPowerMin) + const.BreakDrainPowerMin
		consumption = MulDivRound(consumption, const.BreakDrainModifierPct, 100)
		element.consumption = consumption
	else
		local consumption = self:Random(const.BreakDrainWaterMax - const.BreakDrainWaterMin) + const.BreakDrainWaterMin
		consumption = MulDivRound(consumption, const.BreakDrainModifierPct, 100)
		element.consumption = consumption
		
		self.air = NewSupplyGridConsumer(self, true)
		self.air.is_cable_or_pipe = true
		local air_consumption = self:Random(const.BreakDrainOxygenMax - const.BreakDrainOxygenMin) + const.BreakDrainOxygenMin
		air_consumption = MulDivRound(air_consumption, const.BreakDrainModifierPct, 100)
		self.air:SetConsumption(air_consumption)
	end
	
	grid:AddElement(element)
	
	--create reqs
	self:InternalCreateResourceRequests()
	--post repair request
	self.repair_resource_request:AddAmount(1 * const.ResourceScale)
	self.auto_connect = true
	self:ConnectToCommandCenters()
	
	--presentation
	self:Presentation(true)
end

function BreakableSupplyGridElement:GetLeakParticleScale()
	return 25
end

function BreakableSupplyGridElement:Presentation(start)
	if start then
		assert(IsValid(self), "Trying to break dead cable/pipe!")
		table.insert(g_BrokenSupplyGridElements[self.supply_resource], self)
		g_NewLeak = true
		local leak_spot_id
		if self.supply_resource == "electricity" then
			leak_spot_id = self:GetSpotBeginIndex("Sparks")
		else
			-- NOTE: pfff, emulate obj:GetSpotRange("Leak") !!!
			local leak_spots = 0
			while self:HasSpot("Leak" .. (leak_spots + 1)) do
				leak_spots = leak_spots + 1
			end
			leak_spot_id = self:GetSpotBeginIndex("Leak" .. (1 + self:Random(leak_spots)))
		end
		
		if leak_spot_id == -1 then
			leak_spot_id = self:GetSpotBeginIndex("Origin")
		end
		
		local pos = self:GetSpotPos(leak_spot_id)
		local angle, axis = self:GetSpotRotation(leak_spot_id)
		local particle_axis = RotateAxis(axis_z, axis, angle) --get the z axis of the spot
		PlayFX("OxygenLeak", "start", self, nil, pos, particle_axis)
		self.fx_params = table.pack("OxygenLeak", "end", self, nil, pos, particle_axis)
	elseif self.fx_params then
		table.remove_entry(g_BrokenSupplyGridElements[self.supply_resource], self)
		PlayFX(table.unpack(self.fx_params))
		self.fx_params = false
	end
	self:UpdateAttachedSigns()
end

function BreakableSupplyGridElement:Done()
	if self.fx_params then
		self:Presentation()
	end
end

function BreakableSupplyGridElement:DroneUnloadResource(drone, request, resource, amount)
	if request == self.repair_resource_request then
		if self.repair_resource_request:GetActualAmount() <= 0 then
			self:StartSupplyGridElementWorkPhase(drone)
		end
	end
end

function BreakableSupplyGridElement:DroneWork(drone, request, resource, amount)
	if request == self.repair_work_request then
		amount = DroneResourceUnits.repair
		drone:PushDestructor(function(drone)
			local self = drone.target
			if IsValid(self) and drone.w_request:GetActualAmount() <= 0 then
				self:Repair()
			end
		end)
		drone:ContinuousTask(request, amount, g_Consts.DroneBuildingRepairBatteryUse, "repairBuildingStart", "repairBuildingIdle", "repairBuildingEnd", "Repair")
		drone:PopAndCallDestructor()
	end
end

function BreakableSupplyGridElement:StartSupplyGridElementWorkPhase(drone)
	self.repair_work_request:AddAmount(g_Consts.DroneRepairSupplyLeak * g_Consts.DroneBuildingRepairAmount)
	if drone then
		drone:SetCommand("Work", self.repair_work_request, "repair", Min(g_Consts.DroneBuildingRepairAmount, self.repair_work_request:GetActualAmount()))
	end
end

function BreakableSupplyGridElement:Repair()
	if not IsValid(self) or self.auto_connect == false then return end
	--remove our element, restore to non-functional element, re-add
	local element = self[self.supply_resource]
	local grid = element.grid
	grid:RemoveElement(element)
	
	element.variable_consumption = false
	element.consumption = false
	self.air = false
	
	grid:AddElement(element)
	
	--disconnect from command centers
	self.auto_connect = false
	self:DisconnectFromCommandCenters()
	--destroy requests
	self:InternalDestroyResourceRequests()
	
	--presentation
	self:Presentation()
	
	Msg("Repaired", self)
	
	if SelectedObj == self then
		SelectObj(false)
	end
	
	if self:IsPinned() then
		self:TogglePin()
	end
end

function BreakableSupplyGridElement:GetDisplayName()
	if self.repair_resource_request then
		return self.supply_resource == "electricity" and T(3890, "Cable Fault") or T(3891, "Pipe Leak")
	elseif IsKindOf(self, "SupplyGridSwitch") then
		return SupplyGridSwitch.GetDisplayName(self)
	else
		return self.display_name
	end
end

function BreakableSupplyGridElement:Getdescription()
	if self.auto_connect then
		return T{3892, "This section of the grid has malfunctioned and it's now leaking. It can be repaired by Drones for <metals(number)>.\n\nLarger networks will malfunction more often.", number = 1000}
	else
		return self.description
	end
end

function BreakableSupplyGridElement:UpdateAttachedSigns()
	local has_repair_work_request = self.repair_work_request and self.repair_work_request:GetActualAmount() > 0
	local has_repair_resource_request = self.repair_resource_request and self.repair_resource_request:GetActualAmount() > 0
	local is_broken = has_repair_work_request or has_repair_resource_request
	if self.supply_resource == "electricity" then
		self:AttachSign(is_broken, "SignBrokenElectricityCable")
	else
		self:AttachSign(is_broken, "SignBrokenPipeConnection")
	end
end

function BreakableSupplyGridElement:CheatBreak()
	self:Break()
end

function BreakableSupplyGridElement:CheatRepair()
	self:Repair()
end

function TestSupplyGridUpdateThreads()
	local total = 0
	local dead = 0
	local function do_work(c)
		for i = 1, #(c or "") do
			total = total + 1
			if not IsValidThread(c[i].update_thread) then
				dead = dead + 1
			end
		end
	end
	do_work(UICity.electricity)
	do_work(UICity.water)
	print("<green>total grids", total, "</green>")
	print("<red>dead update threads", dead, "</red>")
	print("<em>ele production thread", IsValidThread(UICity.electricity.production_thread) and "alive" or "dead", "water p thread",  IsValidThread(UICity.water.production_thread) and "alive" or "dead", "air p thread", IsValidThread(UICity.air.production_thread)and "alive" or "dead", "</blue>")
end

GlobalVar("g_SplitSupplyGridPositions", function() return { electricity = {}, water = {} } end)

GlobalGameTimeThread("SplitPowerGridNotif", function()
	HandleNewObjsNotif(g_SplitSupplyGridPositions.electricity, "SplitPowerGrid", nil, nil, false)
end)

GlobalGameTimeThread("SplitLifeSupportGridNotif", function()
	HandleNewObjsNotif(g_SplitSupplyGridPositions.water, "SplitLifeSupportGrid", nil, nil, false)
end)
