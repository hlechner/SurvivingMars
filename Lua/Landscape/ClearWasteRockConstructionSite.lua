local obstructor_cost_per_cm_r = 3
local obstructor_work_cost_m = 3

function GetWasteRockAmountForObj(obj, m)
	local c = WasteRockAmountsByEntity[obj.entity]
	if c then
		return c * const.ResourceScale
	end
	
	return obj:GetRadius() * obstructor_cost_per_cm_r
end

function RemoveRock(rock)
	GetFlightSystem(rock):Unmark(rock)
	if IsKindOf(rock, "WasteRockObstructor") then
		if not rock.auto_connect then
			rock:OnDeleted()
		end
	elseif IsDlcAvailable("armstrong") and rock:GetMapID() == MainMapID then
		local realm = GetRealm(rock)
		realm:Vegetation_OnRockRemoved(VegetationGrid, forbid_growth, rock)
	end
	DoneObject(rock)
end

DefineClass.ClearWasteRockConstructionSite = {
	__parents = { "LandscapeConstructionSiteBase" },
	
	sign_spot = false,
	sign_offset = point(0, 0, 12*guim),
	
	place_stockpile = false,
	
	waste_rock_juggle_work_request = false,
	clear_obstructors_request = false,
	obstructors_supply_request = false,
	can_complete_during_init = false,
	
	obstructors_cache = false,
	obstructor_to_cost = false,
	cur_obstructor_clean = false,
	cur_obstructors_providing_rocks = false,
	
	abs_volume = 0,
	volume = 0,
	
	rocks_removed = 0,
	work_for_obstructor_clearing = 0,
	
	wr_added_to_clean_wr_supply_req = 0,
	wr_from_rocks_picked_up = 0,
	cur_clean_progress = 0,
	min_obstructor_cost = max_int,
	auto_connect = true,
	use_control_construction_logic = false,
	
	auto_construct_output_pile = false,
	drone_working_on_amounts = false,
}

function ClearWasteRockConstructionSite:GameInit()
	if self.state == "complete" then return end
	local ls = Landscapes[self.mark]
	local b = LandscapeProgressInit(ls)
	if not self.stockpiles_underneath then
		self:InitBlockPass(ls)
	end
end

function ClearWasteRockConstructionSite:InitBlockPass(ls)
	ls = ls or Landscapes[self.mark]
	ls.apply_block_pass = true
	local terrain = GetTerrain(self)
	terrain:RebuildPassability(ls.pass_bbox)
	self:ScatterUnitsUnderneath()
end

function ClearWasteRockConstructionSite:Getdescription() 
	return T{13701, "<em>Landscaping project.</em> Drones will produce Waste Rock from objects.", self}
end

function ClearWasteRockConstructionSite:Done()
	if IsValid(self.auto_construct_output_pile) and self.auto_construct_output_pile:GetStoredAmount() <= 0 then
		DoneObject(self.auto_construct_output_pile)
		self.auto_construct_output_pile = false
	end
end

function ClearWasteRockConstructionSite:IsConstructed()
	if self.state ~= "init"
		and self.clear_obstructors_request:GetActualAmount() <= 0 then
		return true
	end
	return false
end

function ClearWasteRockConstructionSite:GetExcessWasteRock()
	local total = self.work_for_obstructor_clearing / obstructor_work_cost_m
	local current = total - self.wr_from_rocks_picked_up
	return total, current
end

function ClearWasteRockConstructionSite:GetResourceProgress()
	local lines = {}

	if self.state == "clean" then
		lines[#lines+1] = T{12160, "<em>Clearing the site</em><right><percent>%", percent = self:GetCleaningProgress()}
	end

	local total, remaining = self:GetExcessWasteRock()
	if total > 0 then
		lines[#lines+1] = T{11897, "<em>Excess Waste Rock</em><right><wasterock(remaining,total)>", remaining = remaining, total = total}
	end
	
	return table.concat(lines, "<newline><left>")
end

function ClearWasteRockConstructionSite:CompleteLandscape(quick_build)
	local mark = self.mark
	local landscape = Landscapes[mark]
	if landscape then
		landscape.completed = true
		LandscapeProgress(mark, 100, 100)
		if not landscape.changed and (self.rocks_removed > 0 or quick_build) then
			-- Force buildable fix as it wont be called if the landscape isn't changed 
			LandscapeFixBuildable(landscape)
		end
		LandscapeFinish(mark)
		Msg("LandscapeCompleted", landscape)
	end
end

function ClearWasteRockConstructionSite:OnQuickBuild()
	LandscapeForEachObstructor(self.mark, RemoveRock)
	LandscapeConstructionSiteBase.OnQuickBuild(self)
end

function ClearWasteRockConstructionSite:GatherConstructionResources()
	if self.clear_obstructors_request then return end
	
	local obstructors_cache = {}
	local obstructor_to_cost = {}
	local passed = {}
	local work_for_obstructor_clearing = 0
	local min = max_int
	LandscapeForEachObstructor(self.mark, function(obj)
		if not passed[obj] then
			if obj:GetEnumFlags(const.efRemoveUnderConstruction + const.efBakedTerrainDecal + const.efBakedTerrainDecalLarge) ~= 0 then
				DoneObject(obj)
			else
				local c = GetWasteRockAmountForObj(obj)
				local work_cost = c * obstructor_work_cost_m
				work_for_obstructor_clearing = work_for_obstructor_clearing + work_cost
				table.insert(obstructors_cache, obj)
				obstructor_to_cost[obj] = c
				min = Min(min, work_cost)
			end
			passed[obj] = true
		end
	end)
	self.obstructors_cache = obstructors_cache
	self.obstructor_to_cost = obstructor_to_cost
	self.min_obstructor_cost = min
	self.work_for_obstructor_clearing = work_for_obstructor_clearing
	
	local max_drones = self:GetMaxDrones()
	self.clear_obstructors_request = self:AddWorkRequest("clear", 0, 0, max_drones)
	self.obstructors_supply_request = self:AddSupplyRequest("WasteRock", 0, const.rfCanExecuteAlone, max_drones)

	self.construction_resources = {}
	self.construct_request = self.obstructors_supply_request
	
	self.state = "init_done"
	self:UpdateState()
end

function ClearWasteRockConstructionSite:OnBlockerClearenceComplete()
	self:InitBlockPass()
	if self.ui_working then --i.e. we are turned on
		self.auto_connect = true
		self:ConnectToCommandCenters()
	end
	self:Initialize()
	self:TryGoToNextState()
	RebuildInfopanel(self)
end

function ClearWasteRockConstructionSite:TryGoToNextState()
	if self.state == "clean" and self.clear_obstructors_request:GetActualAmount() <= 0
		and self.obstructors_supply_request:GetActualAmount() <= 0 
		and #self.obstructors_cache <= 0 then
		self.state = "clean_done"

		self.obstructor_to_cost = nil
		self.obstructors_cache = nil
		self:UpdateState()
		return true
	end
	
	return false
end

function ClearWasteRockConstructionSite:UpdateState()
	if self.state == "init_done" then
		if self.work_for_obstructor_clearing > 0 then
			self.state = "clean"
			self.construction_resources.WasteRock = self.obstructors_supply_request
			self.clear_obstructors_request:AddAmount(self.work_for_obstructor_clearing)
		else
			self.state = "clean_done"
		end
	end

	if self.state == "clean_done" then
		self.state = "complete"
		CreateGameTimeThread(self.Complete, self)
	end
end

function ClearWasteRockConstructionSite:GetDroneFacePos()
	return self:GetBBox():Center()
end

function ClearWasteRockConstructionSite:GetBBox(grow)
	local ls = Landscapes[self.mark]
	assert(ls)
	return ls and HexStoreToWorld(ls.bbox, grow) or box()
end

function ClearWasteRockConstructionSite:DroneLoadResource(drone, request, resource, amount, skip_presentation)
	if request == self.obstructors_supply_request then
		--pickup obstructor waste rock visuals
		self.wr_from_rocks_picked_up = self.wr_from_rocks_picked_up + amount
	end
	self:UpdateLSProgress(amount, request)
end

function ClearWasteRockConstructionSite:DoesWasteRockFromRocksNeedWorkers()
	local request = self.obstructors_supply_request
	if request then
		local amount = request:GetTargetAmount()
		if amount > 5000 then
			local workers = 100 - MulDivRound(request:GetFreeUnitSlots(), 100, self:GetMaxDrones())
			if workers <= 50 then
				return true
			end
		end
	end
	return false
end

function ClearWasteRockConstructionSite:ProcObstructors()
	local points = self.cur_clean_progress
	local min = self.min_obstructor_cost
	local rocks = self.cur_obstructors_providing_rocks or {}
	self.cur_obstructors_providing_rocks = rocks
	local no_further_work_in_req = self.clear_obstructors_request:GetActualAmount() <= 0
	
	if points >= min or no_further_work_in_req then
		local new_min = max_int
		local added = 0
		for i = #(self.obstructors_cache or ""), 1, -1 do
			local o = self.obstructors_cache[i]
			if not rocks[o] then
				if IsValid(o) then
					local res_cost = self.obstructor_to_cost[o]
					local work_cost = res_cost * obstructor_work_cost_m
					if points >= work_cost or no_further_work_in_req then
						self.obstructors_supply_request:AddAmount(res_cost)
						added = added + res_cost
						table.insert(rocks, o)
						rocks[o] = true
						points = points - work_cost
					else
						new_min = Min(new_min, work_cost)
					end
				else
					table.remove(self.obstructors_cache, i)
				end
			end
		end
		
		assert(points >= 0 or no_further_work_in_req)
		if points < 0 then
			print("<color 0 255 0>Initial work was not enough to finish cleaning landscape cs!", points, "</color>")
		end
		self.wr_added_to_clean_wr_supply_req = self.wr_added_to_clean_wr_supply_req + added
		self.cur_clean_progress = Max(points, 0)
		self.min_obstructor_cost = new_min
	end
	
	points = self.wr_added_to_clean_wr_supply_req - self.obstructors_supply_request:GetActualAmount()
	if points > 0 and #rocks > 0 then
		local realm = GetRealm(self)
		realm:SuspendPassEdits("ProcObstructors")
		
		for i = #rocks, 1, -1 do
			local o = rocks[i]
			if IsValid(o) then
				local cost = self.obstructor_to_cost[o]
				if cost <= points then
					points = points - cost
					RemoveRock(o)
					table.remove(rocks, i)
					rocks[o] = nil
					table.remove_entry(self.obstructors_cache, o)
					self.rocks_removed = self.rocks_removed + 1
				end
			else
				table.remove(rocks, i)
				rocks[o] = nil
			end
		end
		
		self.wr_added_to_clean_wr_supply_req = self.obstructors_supply_request:GetActualAmount() + points
		realm:ResumePassEdits("ProcObstructors")
		
		if #rocks <= 0 then
			self:TryGoToNextState()
		end
	end
end

function ClearWasteRockConstructionSite:UpdateConstructionVisualization(request)
	if self.state == "clean" then
		self:ProcObstructors()
		return
	end
end

function ClearWasteRockConstructionSite:GetCleaningProgress()
	local work_for_obstructor_clearing = self.work_for_obstructor_clearing / obstructor_work_cost_m
	local total = (work_for_obstructor_clearing * 2)
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
	else
		progress = (work_for_obstructor_clearing * 2)
	end
	
	return MulDivTrunc(progress, 100, total)
end

function ClearWasteRockConstructionSite:GetTotalLandscapeProgress()
	return self:GetCleaningProgress()
end

function ClearWasteRockConstructionSite:GetDroneWorkingAmount(req)
	return self.drone_working_on_amounts and self.drone_working_on_amounts[req] or 0
end

function ClearWasteRockConstructionSite:UpdateLSProgress(amount, request)
	if self.state == "clean" then
		if request == self.clear_obstructors_request then
			self.cur_clean_progress = self.cur_clean_progress + abs(amount)
		end
	end
	assert(request == self.clear_obstructors_request and self.state == "clean"
			or request ~= self.clear_obstructors_request)
	self:UpdateConstructionVisualization(request)
	self:TryGoToNextState()
end

function ClearWasteRockConstructionSite:GetUIStatusOverrideForWorkCommand(request, drone)
	if self.state == "clean" then
		return "CleanLSCS"
	end
	return "Work"
end

function ClearWasteRockConstructionSite:GetEmptyStorage(resource)
	--rover compat
	return max_int
end

function ClearWasteRockConstructionSite:RoverLoadResource(amount, resource, request)
	self:AddResource(amount, resource, true)
end

function ClearWasteRockConstructionSite:AddResource(amount, resource)
	if resource == "construct" then
		self.waste_rock_juggle_work_request:AddAmount(amount)
		self:UpdateLSProgress(amount)
		return
	elseif resource == "clear" then
		local req = self.clear_obstructors_request
		local to_add = -(Min(abs(amount), req:GetActualAmount()))
		if to_add ~= 0 then
			req:AddAmount(to_add)
			self:UpdateLSProgress(to_add, req)
		end
		return
	elseif self.state == "clean" and resource == "WasteRock" then
		local req = self.obstructors_supply_request
		req:AddAmount(amount)
		self:UpdateLSProgress(amount, req)
		self.wr_from_rocks_picked_up = self.wr_from_rocks_picked_up + amount
		return
	end
	local req = self.construction_resources[resource]
	req:AddAmount(req:IsAnyFlagSet(const.rfDemand) and -amount or amount)
	self:UpdateLSProgress(amount)
end

function ClearWasteRockConstructionSite:ConnectToCommandCenters()
	local b =  self:GetBBox(const.CommandCenterMaxRadius * const.GridSpacing)
	GetRealm(self):MapForEach(b, "DroneControl", DroneControl.ConnectLandscapeConstructions)
end

local max_t = 10
function ClearWasteRockConstructionSite:GetOuputPile()
	local p = self.auto_construct_output_pile
	if not IsValid(p) or p:GetEmptyStorage() <= 0 then
		local res, q, r
		local mq, mr = WorldToHex(self)
		local count, passed, now = 0, {}, GameTime()
		
		local game_map = GetGameMap(self)
		while not res and count < max_t do
			local sp = table.rand(self.periphery_shape)
			if not passed[sp] then
				res, q, r = TryFindStockpileDumpSpotIn(game_map, mq + sp:x(), mr + sp:y(), 0, HexSurroundingsCheckShapeLarge, HexGetLandscapeOrAnyObjButToxicPool, "for WasteRock resource")
				passed[sp] = true
			end
			count = count + 1
		end
		
		if res then
			p = PlaceObjectIn("WasteRockStockpileUngrided", self:GetMapID(),
				{has_demand_request = true, apply_to_grids = true, has_platform = false, snap_to_grid = true, 
				additional_demand_flags = const.rfSpecialDemandPairing})
			p:SetPos(point(HexToWorld(q, r)))
		else
			p = false
		end
	end
	self.auto_construct_output_pile = p
	return p
end

local construction_site_auto_construct_tick = ConstructionSite.building_update_time --wont go faster, but doesn't do much else
construction_site_auto_transfer_amount = 2000
construction_site_auto_clean_amount = 5000
function ClearWasteRockConstructionSite:UnloadRequest(req)
	assert(req:IsAnyFlagSet(const.rfSupply))
	local sup_req = req
	if sup_req:GetTargetAmount() > 0 then
		local stock = self:GetOuputPile()
		if stock then
			local dreq = stock.demand_request
			if not dreq then return end --stock not initialized yet, skip pass
			local a = Min(construction_site_auto_transfer_amount, sup_req:GetTargetAmount())
			a = Min(a, dreq:GetTargetAmount())
			sup_req:AddAmount(-a)
			dreq:AddAmount(-a)
			if stock:HasMember("DroneUnloadResource") then
				stock:DroneUnloadResource(nil, dreq, "WasteRock", a, true)
			end
			self:UpdateLSProgress(a, sup_req)
		end
	end
end

function ClearWasteRockConstructionSite:BuildingUpdateNanites(current_time)
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
		end
	end
end

function ClearWasteRockConstructionSite:BuildingUpdate(delta, day, hour)
	if self.state == "clean" and #(self.obstructors_cache or "") > 0 then
		local removed = false
		for i = #self.obstructors_cache, 1, -1 do
			if not IsValid(self.obstructors_cache[i]) then
				table.remove(self.obstructors_cache, i)
				removed = true
			end
		end
		if removed then
			self:TryGoToNextState()
		end
	end
	
	if UIColony:IsTechResearched("LandscapingNanites") then
		local current_time = GameTime()
		self:BuildingUpdateNanites(current_time)
	end
end
