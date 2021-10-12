local rfSupply       = const.rfSupply
local rfDemand       = const.rfDemand
local rfStorageDepot       = const.rfStorageDepot
local rfSpecialDemandPairing       = const.rfSpecialDemandPairing
local rfSupplyDemand = rfSupply + rfDemand

local minimum_resource_amount_treshold = const.TransportMinResAmountTreshold
local dist_threshold = const.TransportDistThreshold

--1 cube == 10 * guim
local function t_to_prio(t)
	local as_dist = t / 10 --1s ~ 1guim
	return as_dist
end

local function d_to_prio(d)
	return d * -1
end

DefineClass.LRManager = {
	__parents = { "InitDone" },
	
	city = false,
	
	supply_queues = false,
	demand_queues = false,
	
	registered_storages = false,
	colonist_transport_tasks = false, --{[n] = ColonistTransportRequest}
	
	last_task_type = "resource", --so tasks can alternate between resources and colonists
	req_hystory = false,
}

function LRManager:Init()
	self.supply_queues = {}
	self.demand_queues = {}
	self.colonist_transport_tasks = {}
	self.req_hystory = {}
	self.registered_storages = {}
	
	BuildStorableResourcesArray()
	
	for i = 1, #StorableResources do
		local resource = StorableResources[i]
		self.supply_queues[resource] = {}
		self.demand_queues[resource] = {}
	end
end

function LRManager:AddColonistTransportRequest(req)
	table.insert(self.colonist_transport_tasks, req)
end

function LRManager:RemoveColonistTransportRequest(req)
	table.remove_entry(self.colonist_transport_tasks, req)
end

function LRManager:AddBuilding(building)	
	if self.registered_storages[building] then return end

	local supply_queues = self.supply_queues
	local demand_queues = self.demand_queues
	
	for _, request in ipairs(building.task_requests or empty_table) do
		if request:IsAnyFlagSet(rfSupplyDemand) then
			local queue = request:IsAnyFlagSet(rfSupply) and supply_queues or demand_queues
			local request_resource = request:GetResource()
			if table.find(StorableResources, request_resource) then
				queue[request_resource][#queue[request_resource] + 1] = request
			end
		end
	end
	
	table.insert(self.registered_storages, building)
	self.registered_storages[building] = true
end

function LRManager:RemoveBuilding(building)
	if not self.registered_storages[building] then return end
	
	local task_requests = building.task_requests or empty_table
	local s_requests = self.supply_queues
	local d_requests = self.demand_queues
	for _, request in ipairs(task_requests) do
		local resource = request:GetResource()
		if request:IsAnyFlagSet(rfSupply) then
			table.remove_entry(s_requests[resource], request)
		else
			table.remove_entry(d_requests[resource], request)
		end
	end	
	
	local element_was_removed = table.remove_entry(self.registered_storages, building)
	assert(element_was_removed)
	self.registered_storages[building] = nil
end

local function CalcDemandPrio(req, bld, requestor)
	local d = bld:GetDist2D(requestor)
	--time since serviced, dist (closer is better), if any resource set to import + 100000 + needed amount
	return t_to_prio(now() - req:GetLastServiced()) + req:GetTargetAmount() + d_to_prio(d)
end

local function CalcSupplyPrio(s_req, s_bld, d_req, d_bld, requestor, demand_score)
	local d = s_bld:GetDist2D(d_bld)
	local d2 = s_bld:GetDist2D(requestor)
	return s_req:GetTargetAmount() + d_to_prio(d) + d_to_prio(d2) + demand_score
end

local function CheckMinDist(bld1, bld2)
	if bld1:IsCloser2D(bld2, dist_threshold) then
		local did_reach, len = pf.PosPathLen(bld1:GetPos(), 0, bld2:GetPos()) --cant cache :(
		return not did_reach or len > dist_threshold 
	end
	return true
end

function LRManager:CleanQueues()
	local tbl = self.demand_queues
	local storages = self.registered_storages
	for k, v in pairs(tbl) do
		for i = #v, 1, -1 do
			local bld = v[i]:GetBuilding()
			if not IsValid(bld)
				or not IsKindOf(bld, "ShuttleLanding") 
				or (v[i]:IsAnyFlagSet(const.rfMechanizedStorage) and not table.find(storages, bld)) then
				table.remove(v, i)
			end
		end
	end
	tbl = self.supply_queues
	for k, v in pairs(tbl) do
		for i = #v, 1, -1 do
			if not IsValid(v[i]:GetBuilding()) 
				or not IsKindOf(v[i]:GetBuilding(), "ShuttleLanding") then
				table.remove(v, i)
			end
		end
	end
end

function LRManager:TestLRQueues()
	local dq = self.demand_queues
	for k, v in pairs(dq) do
		for i = 1, #v do
			assert(IsValid(v[i]:GetBuilding()))
		end
	end
	
	dq = self.supply_queues
	
	for k, v in pairs(dq) do
		for i = 1, #v do
			assert(IsValid(v[i]:GetBuilding()))
		end
	end
	
	local t = self.registered_storages
	for k, v in ipairs(t) do
		assert(IsValid(v))
	end
end

function CleanLRManagerQueues()
	for _, map in pairs(GameMaps) do
		map.lr_manager:CleanQueues()
	end
end

SavegameFixups.CleanLRManagerQueues = CleanLRManagerQueues
SavegameFixups.CleanLRManagerQueuesAgain = CleanLRManagerQueues
SavegameFixups.CleanLRManagerQueuesThirdTimeIsTheCharm = CleanLRManagerQueues

local hystory_time = 3*const.HourDuration
function LRManager:FindTransportTask(requestor, demand_only, force_resource, capacity, transport_mode)
	transport_mode = transport_mode or "all"
	local colonist_task
	local colonist_tasks = self.colonist_transport_tasks or ""
	if transport_mode ~= "cargo" and not demand_only and not force_resource then
		for i = 1,#colonist_tasks do
			if colonist_tasks[i]:CanExecute() then
				colonist_task = colonist_tasks[i]
				if transport_mode == "people" then
					return colonist_task
				elseif self.last_task_type == "resource" then
					self.last_task_type = "colonist"
					return colonist_task
				end
				break
			end
		end
		
		if transport_mode == "people" then
			return
		end
	end
	
	local resources = force_resource and { force_resource } or StorableResourcesForSession
	local demand_queues = self.demand_queues
	local supply_queues = self.supply_queues
	
	--[[
	local res_prio, res_s_req, res_d_req, res_resource = min_int, false, false, false
	for k = 1, #resources do
		local resource = resources[k]
		local d_queue = demand_queues[resource]
		local s_queue = supply_queues[resource] or empty_table
		for i = 1, #d_queue do
			local d_req = d_queue[i]
			if d_req:CanAssignUnit() then
				local d_bld = d_req:GetBuilding()
				if d_bld.has_free_landing_slots and ShouldIncludeAutoDemandRequest(d_req, resource) then
					local d_prio = CalcDemandPrio(d_req, d_bld, requestor)
					if not demand_only then
						for j = 1, #s_queue do
							local s_req = s_queue[j]
							local s_bld = s_req:GetBuilding()
							if s_bld ~= d_bld
							and s_req:GetTargetAmount() > minimum_resource_amount_treshold
							and s_bld.has_free_landing_slots
							and CheckMinDist(s_bld, d_bld)
							then
								local s_prio = CalcSupplyPrio(s_req, s_bld, d_req, d_bld, requestor, d_prio)
								if res_prio < s_prio then
									res_prio, res_s_req, res_d_req, res_resource = s_prio, s_req, d_req, resource
								end
							end
						end
					elseif res_prio < d_prio then
						res_prio, res_d_req, res_resource = d_prio, d_req, resource
					end
				end
			end
		end
	end
	--]]
	local res_s_req, res_d_req, res_prio, res_resource, req_count = 
	Request_FindShuttleTask(requestor, resources, demand_queues, supply_queues, demand_only, capacity)
	
	local hystory = self.req_hystory or {}
	self.req_hystory = hystory
	local last_entry = hystory[#hystory]
	local time = GameTime()
	local count = req_count + #colonist_tasks
	local next_idx = last_entry and last_entry:x() == time and #hystory or #hystory+1
	hystory[next_idx] = point(time, count)
	while #hystory > 10 and time - hystory[1]:x() >= hystory_time do
		table.remove(hystory, 1)
	end
	
	local best_task = res_prio and {res_prio, res_s_req, res_d_req, res_resource}
	if demand_only then
		return best_task
	elseif best_task then
		if transport_mode == "all" then
			self.last_task_type = "resource"
		end
		return best_task
	elseif colonist_task then
		self.last_task_type = "colonist"
		return colonist_task
	end
end

function LRManager:GetLastTaskCount()
	local hystory = self.req_hystory or empty_table
	local last_entry = hystory[#hystory] or point20
	local time, tasks = last_entry:xy()
	return tasks
end

function LRManager:EstimateTaskCount()
	local hystory = self.req_hystory or empty_table
	local time_now = GameTime()
	local avg_tasks, total_weight = 0, 0
	for i=#hystory,1,-1 do
		local time, tasks = hystory[i]:xy()
		local weight = hystory_time - (time_now - time)
		if weight <= 0 then
			break
		end
		avg_tasks = avg_tasks + tasks * weight
		total_weight = total_weight + weight
	end
	return total_weight > 0 and (avg_tasks / total_weight) or self:GetLastTaskCount()
end