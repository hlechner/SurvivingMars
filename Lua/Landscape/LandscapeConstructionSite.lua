local obstructor_work_cost_m = 3

DefineClass.LandscapeConstructionSite = {
	__parents = { "ClearWasteRockConstructionSite" },

	supply_request = false,
	demand_request = false,

	total_ls_progress = 0,
	cur_ls_progress = 0,
	last_ls_progress = 0,

	waste_rock_to_be_transported = 0,
	work_for_waste_rock_juggling = 0,
	waste_rock_from_rocks_underneath = 0,

	wr_requires = 0,
	wr_produced = 0,
}

function SavegameFixups.RestoreBlockPassToOldLSCS()
	MapForEach("map", "LandscapeConstructionSite", function(o)
		o:InitBlockPass() --in the olden times before this revision, lscs always block
	end)
end

function LandscapeConstructionSite:GetUnitsUnderneath()
	local units = {}
	LandscapeForEachUnit(self.mark, function(o)
		table.insert(units, o)
	end)
	
	return units
end

function LandscapeConstructionSite:Getdescription() 
	return T{12028, "<em>Landscaping project.</em> Drones will produce Waste Rock from excess soil or use Waste Rock to raise terrain.", self}
end


function LandscapeConstructionSite:IsConstructed()
	local result = ClearWasteRockConstructionSite.IsConstructed(self)
	if result and self.state ~= "init"
		and self.supply_request:GetActualAmount() <= 0
		and self.demand_request:GetActualAmount() <= 0
		and self.waste_rock_juggle_work_request:GetActualAmount() <= 0 then
		return true
	end
	return false
end

function LandscapeConstructionSite:IsWaitingResources()
	if self.waste_rock_to_be_transported ~= 0 then
		return true
	end
	return false
end

function LandscapeConstructionSite:GetExcessWasteRock()
	local total, current = ClearWasteRockConstructionSite.GetExcessWasteRock(self)
	total = total + self.wr_produced
	current = current + self:GetTotalActualSupply()
	return total, current
end

function LandscapeConstructionSite:GetRequiredWasteRock()
	return self.wr_required, self.wr_required - self:GetTotalActualDemand()
end

function LandscapeConstructionSite:GetResourceProgress()
	local lines = {}
	
	if self.state == "clear_stocks" then
		lines[#lines+1] = T(627, "The construction site is being cleared.")
	elseif self.state == "clean" then
		lines[#lines+1] = T{12160, "<em>Clearing the site</em><right><percent>%", percent = self:GetCleaningProgress()}
	elseif self.state == "transport" then
		if self.wr_required > 0 then
			lines[#lines+1] = T{12331, "<em>Delivering Waste Rock</em><right><percent>%", percent = self:GetTransportProgress()}
		else
			lines[#lines+1] = T{12332, "<em>Extracting Waste Rock</em><right><percent>%", percent = self:GetTransportProgress()}
		end
	else
		if IsKindOf(self.building_class_proto, "LandscapeTerraceBuilding") then
			lines[#lines+1] = T{12278, "<em>Leveling the ground</em><right><percent>%", percent = self:GetLevelingProgress()}
		elseif IsKindOf(self.building_class_proto, "LandscapeRampBuilding") then
			lines[#lines+1] = T{12279, "<em>Leveling the ramp</em><right><percent>%", percent = self:GetLevelingProgress()}
		end
	end	
	
	local excess_total, excess_current = self:GetExcessWasteRock()
	local required_total, required_current = self:GetRequiredWasteRock()
	if excess_total > 0 then
		lines[#lines+1] = T{11897, "<em>Excess Waste Rock</em><right><wasterock(remaining,total)>", remaining = excess_current, total = excess_total}
	end
	if required_total > 0 then
		lines[#lines+1] = T{11896, "<em>Required Waste Rock</em><right><wasterock(remaining,total)>", remaining = required_current, total = required_total}
	end
	
	return table.concat(lines, "<newline><left>")
end	

--[[
--for nanite testing
function City:IsTechResearched(tech_id)
	if tech_id == "LandscapingNanites" then return true end
	local status = self.tech_status[tech_id]
	return status and status.researched
end
]]
function LandscapeConstructionSite:GatherConstructionResources()
	if self.supply_request or self.demand_request then return end
	
	self.work_for_waste_rock_juggling = self.abs_volume - abs(self.volume)
	self.waste_rock_to_be_transported = self.volume
	self.total_ls_progress = self.abs_volume
	self.cur_ls_progress = 0

	local max_drones = self:GetMaxDrones()
	self.demand_request = self:AddDemandRequest("WasteRock", 0, 0, max_drones)
	self.supply_request = self:AddSupplyRequest("WasteRock", 0, const.rfCanExecuteAlone, max_drones)
	self.waste_rock_juggle_work_request = self:AddWorkRequest("construct", 0, 0, max_drones)

	--self.total_ls_progress = self.work_for_waste_rock_juggling + self.waste_rock_to_be_transported
	local is_producing = self.waste_rock_to_be_transported < 0
	local wr_produced = is_producing and abs(self.waste_rock_to_be_transported) or 0
	local wr_required = not is_producing and abs(self.waste_rock_to_be_transported) or 0
	local coef = UIColony:IsTechResearched("ConservationLandscaping") and 2 or 1
	if coef > 1 then
		if is_producing then
			self.total_ls_progress = self.total_ls_progress + wr_produced
			wr_produced = wr_produced * coef
			self.work_for_waste_rock_juggling = self.total_ls_progress - wr_produced --avoid round error
		else
			wr_required = wr_required / coef
			self.total_ls_progress = self.total_ls_progress - wr_required
			self.work_for_waste_rock_juggling = self.total_ls_progress - wr_required --avoid round error
		end
	end

	if UIColony:IsTechResearched("LandscapingNanites") then
		wr_produced = wr_produced / 2
		wr_required = wr_required / 2
		local rem = wr_required + wr_produced
		self.total_ls_progress = self.total_ls_progress - rem
		self.work_for_waste_rock_juggling = self.total_ls_progress - rem
	end

	self.wr_required = wr_required
	self.wr_produced = wr_produced

	self.construction_resources = {}
	self.construct_request = self.waste_rock_juggle_work_request

	LandscapeForEachStockpile(self.mark, function(stock, self)
		self.stockpiles_underneath = self.stockpiles_underneath or {}
		stock:InitUnderConstruction(self)
		table.insert(self.stockpiles_underneath, stock)
	end, self)

	ClearWasteRockConstructionSite.GatherConstructionResources(self)
end

function LandscapeConstructionSite:TryGoToNextState()
	if self.state == "clear_stocks" and #(self.stockpiles_underneath or "") <= 0 then
		self.state = "clear_stocks_done"
		self:UpdateState()
		return true
	end

	if ClearWasteRockConstructionSite.TryGoToNextState(self) then
		return true
	end

	if self.state == "transport" 
		and self.supply_request:GetActualAmount() <= 0
		and self.demand_request:GetActualAmount() <= 0
		and (not self.drone_working_on_amounts
		or ((self.drone_working_on_amounts[self.demand_request] or 0) <= 0
		and (self.drone_working_on_amounts[self.supply_request] or 0) <= 0)) then
		self.waste_rock_to_be_transported = 0
		self.state = "transport_done"
		self:UpdateState()
		return true
	end
	if self.state == "work"
		and self.waste_rock_juggle_work_request:GetActualAmount() <= 0 then
		self.state = "work_done"
		self:UpdateState()
		return true
	end
	
	return false
end

function LandscapeConstructionSite:UpdateState()
	local first = false
	if self.state == "init_done" then
		first = true
		if #(self.stockpiles_underneath or "") > 0 then
			self.state = "clear_stocks"
		else
			self.state = "clear_stocks_done"
		end
	end
	if self.state == "clear_stocks_done" then
		if self.work_for_obstructor_clearing > 0 then
			self.state = "clean"
			self.construction_resources.WasteRock = self.obstructors_supply_request
			self.clear_obstructors_request:AddAmount(self.work_for_obstructor_clearing)
		else
			self.state = "clean_done"
		end
	end
	if self.state == "clean_done" then
		if abs(self.waste_rock_to_be_transported) < (first and const.ResourceScale or 1) then
			self.state = "transport_done"
		else
			self.state = "transport"
			if self.wr_required > 0 then
				self.demand_request:AddAmount(self.wr_required)
				self.construction_resources.WasteRock = self.demand_request
			end
			if self.wr_produced > 0 then
				self.supply_request:AddAmount(self.wr_produced)
				self.construction_resources.WasteRock = self.supply_request
			end
		end
	end
	if self.state == "transport_done" then
		if self.work_for_waste_rock_juggling >= (first and const.ResourceScale or 1) then
			self.state = "work"
			self.waste_rock_juggle_work_request:AddAmount(self.work_for_waste_rock_juggling)
		else
			self.state = "work_done"
		end
	end
	if self.state == "work_done" then
		self.state = "complete"
		CreateGameTimeThread(self.Complete, self)
	end
end

function LandscapeConstructionSite:GetUIStatusOverrideForWorkCommand(request, drone)
	if self.state == "work" then
		return "WorkLSCS"
	else
		return ClearWasteRockConstructionSite.GetUIStatusOverrideForWorkCommand(self, request, drone)
	end
end

--
local reqs = false
local thread = false
local function interrupt_drones(req)
	local b = req:GetBuilding()
	b:InterruptDrones(nil, function(o) return (o.s_request == req or o.d_request == req) and o end)
	b:DisconnectFromCommandCenters()
end

local function exec()
	Sleep(1)
	local blds = {}
	for i = 1, #(reqs or "") do
		local req = reqs[i]
		if req:GetTargetAmount() < 0 and req:GetActualAmount() > 0 then
			req:SetTargetAmount(req:GetActualAmount())
		elseif req:GetTargetAmount() > 0 and req:GetActualAmount() < 0 then
			req:SetActualAmount(req:GetTargetAmount())
		else
			req:SetActualAmount(0)
			req:SetTargetAmount(0)
		end
		local b = req:GetBuilding()
		blds[b] = true
	end
	
	for b, _ in pairs(blds) do
		b:ConnectToCommandCenters()
		b:TryGoToNextState()
	end
	
	thread = false
	reqs = false
end

local function push_for_exec(req)
	reqs = reqs or {}
	reqs[#reqs + 1] = req
	interrupt_drones(req)
	if not thread then
		thread = CreateGameTimeThread(exec)
	end
end

local function fix_req(req)
	if req:GetTargetAmount() < 0 or req:GetActualAmount() < 0 then
		push_for_exec(req)
	end
end

function SavegameFixups.LandscapeConstructionSiteFixRequestsBelowZero()
	MapForEach("map", "LandscapeConstructionSite", function(o)
		fix_req(o.supply_request)
		fix_req(o.demand_request)
	end)
end
--
function LandscapeConstructionSite:DroneUnloadResource(drone, request, resource, amount)
	if request == self.demand_request then
		drone.override_ui_status = "DeliverLSCS"
		drone.delivery_state = "not_done"
		self.drone_working_on_amounts = self.drone_working_on_amounts or {[request] = 0}
		local reserved = self.drone_working_on_amounts
		reserved[request] = reserved[request] + amount
		drone:PushDestructor(function(drone)
			reserved[request] = reserved[request] - amount
			if drone.delivery_state ~= "done" then
				request:AddAmount(amount)
				drone:SetCarriedResource(resource, amount)
			end
			drone.override_ui_status = nil
		end)
		--presentation
		drone:SetCarriedResource(false)
		drone:Face(self:GetDroneFacePos(), 100)
		drone:StartFX("Construct", self)
		drone:PlayState("constructStart")
		drone:SetState("constructIdle")
		Sleep(MulDivRound(self:GetTimeToWork(), g_Consts.DroneTimeToWorkOnLandscapeMultiplier, 100))
		drone.delivery_state = "done"
		drone:PlayState("constructEnd")
		drone:PopAndCallDestructor()
		if not IsValid(self) then
			return
		end
		self:UpdateLSProgress(amount)
	end
end

function LandscapeConstructionSite:DroneLoadResource(drone, request, resource, amount, skip_presentation)
	if request == self.supply_request then
		drone.override_ui_status = "PickUpLSCS"
		self.drone_working_on_amounts = self.drone_working_on_amounts or {[request] = 0}
		local reserved = self.drone_working_on_amounts
		reserved[request] = reserved[request] + amount
		drone:PushDestructor(function(drone)
			reserved[request] = reserved[request] - amount
			drone.override_ui_status = nil
		end)
		--presentation
		drone:Face(self:GetDroneFacePos(), 100)
		drone:StartFX("Construct", self)
		drone:PlayState("constructStart")
		drone:SetState("constructIdle")
		Sleep(MulDivRound(self:GetTimeToWork(), g_Consts.DroneTimeToWorkOnLandscapeMultiplier, 100))
		drone:PlayState("constructEnd")
		drone:PopAndCallDestructor()
		if not IsValid(self) then
			return
		end
	elseif request == self.obstructors_supply_request then
		--pickup obstructor waste rock visuals
		self.wr_from_rocks_picked_up = self.wr_from_rocks_picked_up + amount
	end
	self:UpdateLSProgress(amount, request)
end


function SavegameFixups.PokeStuckLSCS()
	MapForEach("map", "LandscapeConstructionSite", LandscapeConstructionSite.ProcObstructors)
end

function LandscapeConstructionSite:UpdateConstructionVisualization(request)
	if self.state == "clean" then
		self:ProcObstructors()
		return
	end
	LandscapeProgress(self.mark, self.cur_ls_progress - self.last_ls_progress, self.total_ls_progress)
	self.last_ls_progress = self.cur_ls_progress
end

function LandscapeConstructionSite:GetConstructionBuildPointsProgress()
	if self.state == "work" then
		return MulDivRound(self.work_for_waste_rock_juggling - self.waste_rock_juggle_work_request:GetActualAmount(), 100, self.work_for_waste_rock_juggling)
	elseif self.state == "complete" or self.state == "work_complete" then
		return 100
	end
	return 0
end

function LandscapeConstructionSite:GetTotalActualSupply()
	if self.state == "transport" then
		return self.supply_request:GetActualAmount() + self:GetDroneWorkingAmount(self.supply_request)
	else
		return self.wr_produced
	end
end

function LandscapeConstructionSite:GetTotalActualDemand()
	if self.state == "transport" then
		return self.demand_request:GetActualAmount() + self:GetDroneWorkingAmount(self.demand_request)
	else
		return self.wr_required
	end
end

function LandscapeConstructionSite:GetTransportProgress()
	local total = self.wr_required + self.wr_produced
	local progress = 0
	if self.state == "transport" then
		if self.wr_required > 0 then
			progress = progress + (self.wr_required - self:GetTotalActualDemand())
		end
		if self.wr_produced > 0 then
			progress = progress + (self.wr_produced - self:GetTotalActualSupply())
		end
	elseif self.state == "work" then
		progress = total
	end
	
	return MulDivTrunc(progress, 100, total)
end

function LandscapeConstructionSite:GetLevelingProgress()
	local total = self.work_for_waste_rock_juggling
	local progress = 0
	if self.state == "work" then
		progress = self.work_for_waste_rock_juggling - self.waste_rock_juggle_work_request:GetActualAmount()
	end
	
	return total == 0 and 100 or MulDivTrunc(progress, 100, total)
end

function LandscapeConstructionSite:GetTotalLandscapeProgress()
	local work_for_obstructor_clearing = self.work_for_obstructor_clearing / obstructor_work_cost_m
	local total = work_for_obstructor_clearing * 2 + self.total_ls_progress
	local progress = 0
	if self.state == "clean" then
		local cleaned = work_for_obstructor_clearing - self.clear_obstructors_request:GetActualAmount() / obstructor_work_cost_m
		local remaining_wr = 0
		for i = 1, #self.obstructors_cache do
			local o = self.obstructors_cache[i]
			remaining_wr = remaining_wr + self.obstructor_to_cost[o]
		end
		local collected = (work_for_obstructor_clearing - remaining_wr)
								+ (self.wr_added_to_clean_wr_supply_req - self.obstructors_supply_request:GetActualAmount())
		progress = cleaned + collected
	elseif self.state == "transport" then
		progress = work_for_obstructor_clearing * 2
		
		if self.wr_required > 0 then
			progress = progress + (self.wr_required - self:GetTotalActualDemand())
		end
		if self.wr_produced > 0 then
			progress = progress + (self.wr_produced - self:GetTotalActualSupply())
		end
	elseif self.state == "work" then
		progress = work_for_obstructor_clearing * 2 + self.wr_required + self.wr_produced
						+ (self.work_for_waste_rock_juggling - self.waste_rock_juggle_work_request:GetActualAmount())
	end
	
	return MulDivTrunc(progress, 100, total)
end

function LandscapeConstructionSite:UpdateLSProgress(amount, request)
	if self.state == "transport" or self.state == "work" then
		self.cur_ls_progress = self.cur_ls_progress + abs(amount)
	elseif self.state == "clean" then
		if request == self.clear_obstructors_request then
			self.cur_clean_progress = self.cur_clean_progress + abs(amount)
		end
	end
	assert(request == self.clear_obstructors_request and self.state == "clean"
			or request ~= self.clear_obstructors_request)
	self:UpdateConstructionVisualization(request)
	self:TryGoToNextState()
end

function LandscapeConstructionSite:BuildingUpdateNanites(current_time)
	if not self.auto_construct_ts_ls then self.auto_construct_ts_ls = current_time end 

	if current_time - self.auto_construct_ts_ls >= construction_site_auto_construct_tick then
		self.auto_construct_ts_ls = current_time

		if self.state == "clean" then
			local work_req = self.clear_obstructors_request
			local a = work_req:GetActualAmount()
			local dec = Min(construction_site_auto_clean_amount, a)
			a = a - dec
			work_req:SetAmount(a)
			self:UpdateLSProgress(dec, work_req)

			self:UnloadRequest(self.obstructors_supply_request)
			RebuildInfopanel(self)
		elseif self.state == "transport" then
			local is_producing = self.waste_rock_to_be_transported < 0
			if is_producing then
				self:UnloadRequest(self.supply_request)
			else --requires wr
				local request = false
				local filter_func = function(o)
					local r = "WasteRock"
					if type(o.resource) == "table" then
						local req = o.supply[r]
						if req and req:GetTargetAmount() >= const.ResourceScale then
							request = req
							return "break"
						end
					elseif o.resource == r then
						local req = o.supply_request
						if req and req:GetTargetAmount() >= const.ResourceScale then
							request = req
							return "break"
						end
					end
					return false
				end
				local pos = table.rand(self.drone_dests_cache)
				GetRealm(self):MapForEach(pos, "hex", 30, "WasteRockStockpileBase", "WasteRockDumpSite", filter_func)
				if request then
					local a = Min(construction_site_auto_transfer_amount, request:GetTargetAmount())
					local my_req = self.demand_request
					a = Min(a, my_req:GetTargetAmount())
					
					my_req:AddAmount(-a)
					request:AddAmount(-a)
					local bld = request:GetBuilding()
					if bld:HasMember("DroneLoadResource") then
						bld:DroneLoadResource(nil, request, "WasteRock", a, true)
					end
					self:UpdateLSProgress(a, my_req)
				end
			end
		elseif self.state == "work" then
			local req = self.waste_rock_juggle_work_request
			local a = req:GetActualAmount()
			local dec = Min(construction_site_auto_construct_amount, a)
			a = a - dec
			req:SetAmount(a)
			self:UpdateLSProgress(dec, req)
			RebuildInfopanel(self)
		end
	end
end

function LandscapeConstructionSite:RoverWork(rover, request, resource, amount, total_amount, interaction_type)
	if resource == "construct" then
		rover:PushDestructor(function(rover)
			if IsValid(self) and not self:IsWaitingResources() and self:IsConstructed() then
				self:Complete()
			end
		end)
		local t = self.clear_obstructors_request ~= request and self:GetTimeToWork() / 2 or false
		local amount = amount * (request == self.waste_rock_juggle_work_request and (const.ResourceScale / DroneResourceUnits.construct) or 1)
		rover:ContinuousTask(request, amount, "constructStart", "constructIdle", "constructEnd", "Construct", nil, t, nil, nil, total_amount)
		rover:PopAndCallDestructor()
	elseif self.construction_resources[resource] == request then
		local t = self.obstructors_supply_request ~= request and self:GetTimeToWork() / 2 or g_Consts.RCRoverTransferResourceWorkTime
		rover:ContinuousTask(request, amount, "gatherStart", "gatherIdle", "gatherEnd", interaction_type ~= "load" and "Unload" or "Load", "step", t, "add resource")
	end
end
