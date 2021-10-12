local time_to_work = 100000
local time_to_work_for_tex_painting = 1000
local function GetTimeToWork(t)
	t = t or time_to_work
	if UIColony:IsTechResearched("LandscapingNanites") then
		return t / 2
	end
	return t
end

DefineClass.LandscapeBuilding = {
	__parents = { "Building" },
	entity = "InvisibleObject",
	properties = {
		{ template = true, name = T(12482, "Custom Max Boundary (hexes)"), id = "max_boundary", category = "General", editor = "number", default = 0 },
		{ template = true, name = T(12483, "Custom Max Hex Count"),        id = "max_hexes",    category = "General", editor = "number", default = 0 },
	},
	construction_mode = "",
	count_as_building = false,
	can_resize_during_placement = true,
	can_rotate_during_placement = false,
}
	
DefineClass.LandscapeConstructionSiteBase = {
	__parents = { "ConstructionSite" },
	ApplyToGrids = empty_func,
	RemoveFromGrids = empty_func,
	drone_dests_cache = false,
	periphery_shape = false,
	mark = 0,
	state = "init",
	auto_construct_ts_ls = false,
	max_drones = false,
	hexes = 0,
	auto_rovers = 0,
	pin_progress_max = "TotalForPin",
	pin_progress_value = "TotalLandscapeProgress",
}

function LandscapeConstructionSiteBase:GetMaxDrones()
	if not self.max_drones then
		self.max_drones = Min(5 + self.hexes / 100, 200)
	end
	return self.max_drones
end

function LandscapeConstructionSiteBase:GameInit()
	local drone_dests_cache = {}
	local p_shape = {}
	local mq, mr = WorldToHex(self)
	local landscape_grid = GetLandscapeGrid(self)
	
	LandscapeForEachHex(self:GetMapID(), self.mark, function(q, r, cache, p_shape, mq, mr)
		local p = point(HexToWorld(q, r))
		KillVegetationInHex(q, r, p)
		local mark, height, border = LandscapeCheck(landscape_grid, q, r, true)
		if border then
			table.insert(cache, p)
			table.insert(p_shape, point(q - mq, r - mr))
		end
	end, drone_dests_cache, p_shape, mq, mr)
		
	self.drone_dests_cache = drone_dests_cache
	self.periphery_shape = p_shape
end

function LandscapeConstructionSiteBase:Done()
	LandscapeFinish(self.mark)
end

function LandscapeConstructionSiteBase:InterruptLandscapingDrones()
	local now = GameTime()
	self:InterruptDrones(nil, function(o)
		local b1 = o.w_request and o.w_request:GetBuilding()
		local b2 = o.s_request and o.s_request:GetBuilding()
		local b3 = o.d_request and o.d_request:GetBuilding()
		if b1 == self or b2 == self or b3 == self then
			local ts = GetThreadStatus(o.command_thread)
			if type(ts) == "number" and ts - now >= 1000 then
				return o
			end
		end
	end)
end

function LandscapeConstructionSiteBase:CompleteLandscape(quick_build)
	local mark = self.mark
	local landscape = Landscapes[mark]
	if landscape then
		landscape.completed = true
		LandscapeProgress(mark, 100, 100)
		LandscapeFinish(mark)
		Msg("LandscapeCompleted", landscape)
	end
end

function LandscapeConstructionSiteBase:Complete(quick_build) --quick_build - cheat build
	if not IsValid(self) then return end -- happens when the user spams quick build and manages to complete the same site twice.

	if quick_build then
		self:OnQuickBuild()
	end

	self:CompleteLandscape(quick_build)
	self:InterruptLandscapingDrones()

	DoneObject(self)
end

function LandscapeConstructionSiteBase:UpdateLSProgress()
end

function LandscapeConstructionSiteBase:UpdateConstructionVisualization()
end

function LandscapeConstructionSiteBase:DoesWasteRockFromRocksNeedWorkers()
	return false
end

function LandscapeConstructionSiteBase:GetDroneWorkAmount(drone, request, resource, amount)
	return MulDivRound(amount, const.ResourceScale, DroneResourceUnits[resource])
end

function LandscapeConstructionSiteBase:DroneWork(drone, request, resource, amount)
	drone:PushDestructor(function(drone)
		local self = drone.target
		if IsValid(self) then
			self:TryGoToNextState()
		end
	end)
	
	self:UpdateLSProgress(drone.request_amount, request) --unit assignment + fullfillment progressed this much
	
	amount = self:GetDroneWorkAmount(drone, request, resource, amount)
	drone:ContinuousTask(request, amount, g_Consts.DroneConstructBatteryUse, "constructStart", "constructIdle", "constructEnd", "Construct",
		function(drone, req, amount)
			local self = drone.target
			if self.state == "work" and req:GetActualAmount() > 0 then
				--drone always sleeps 1k
				local t = MulDivRound(self:GetTimeToWork(), g_Consts.DroneTimeToWorkOnLandscapeMultiplier, 100) - 1000
				if t > 0 then
					Sleep(t)
					if not IsValid(self) then
						return
					end
				end
			end
			local force_reset = self:DoesWasteRockFromRocksNeedWorkers()
			self:UpdateLSProgress(amount, req)
			if force_reset then
				local req = self.obstructors_supply_request
				drone:SetCommand("PickUp", req, nil, "WasteRock", Min(req:GetTargetAmount(), DroneResourceUnits.WasteRock))
			end
		end)
	drone:PopAndCallDestructor()
end

function LandscapeConstructionSiteBase:TryGoToNextState()
end

function LandscapeConstructionSiteBase:StartConstructionPhase()
	local result = self:TryGoToNextState()
	return result or self.state == "work"
end

function LandscapeConstructionSiteBase:GetIPStatus()
	return self:GetResourceProgress()
end

function LandscapeConstructionSiteBase:DroneApproach(drone, resource, is_closest)
	local q, r = WorldToHex(drone)
	local landscape_grid = IsValid(self) and GetLandscapeGrid(self) or GetLandscapeGrid(drone)
	if self.mark and self.mark == LandscapeCheck(landscape_grid, q, r, true) then
		--already there
		return true
	end
	if not drone:ExitHolder() then return end
	if not IsValid(self) or not IsValid(drone) then return end
	assert(self.drone_dests_cache)
	return drone:Goto(self.drone_dests_cache)
end

function LandscapeConstructionSiteBase:GetTimeToWork()
	local t = self.class == "ClearWasteRockConstructionSite" and time_to_work or time_to_work_for_tex_painting
	return GetTimeToWork(t)
end

function LandscapeConstructionSiteBase:GetTotalForPin()
	return 100
end
