DefineClass.Workplace = {
	__parents = { "ShiftsBuilding", "Holder", "DomeOutskirtBld"},
	
	properties = {		
		{template = true, id = "max_workers",         name = T(833, "Max workers per shift"),        default = 5,     category = "Workplace", editor = "number", min = 0, max = 20, slider = true, modifiable = true}, 	
		{template = true, id = "specialist",          name = T(834, "Specialist"),                   default = "none",category = "Workplace", editor = "combo",  items = GetColonistSpecializationCombo()},
		{                 id = "performance",         name = T(835, "Current performance"), default = 100, modifiable = true, editor = "number" , no_edit = true},
		{template = true, id = "automation",          name = T(836, "Workplace Automation"),        default = 0,     category = "Workplace", editor = "number", modifiable = true, help = "Can work without workers if > 0"},
		{template = true, id = "auto_performance",    name = T(837, "Workplace Auto Performance"),  default = 0,     category = "Workplace", editor = "number", modifiable = true, help = "Performance when working in automation mode"}, 	
		{template = true, id = "incompatible_traits", name = T(12469, "Incompatible Traits"),              default = empty_table, category = "Workplace", editor = "string_list", item_default = "", items = function() return PresetsCombo("TraitPreset") end}, 	
	},
	
	workers = false,  -- workers arrays in shifts
	overtime = false, -- bool array per shift
	closed_workplaces = false,-- per shift
	current_accident_chance = false,
	force_lock_workplace = false,
	building_update_time = const.HourDuration / 4,
	
	specialist_enforce_mode = false,
	
	domes_query_version = false,
	domes_query_res = false,
	
	dome_label = "Workplace",
}

function Workplace:Init()
	self.workers = {}
	self.overtime = {}
	for i = 1, self.max_shifts do
		self.workers[i] = {}
		self.overtime[i] = false
	end
	self.closed_workplaces = {}
	self.current_accident_chance = 0
end

function Workplace:GameInit()
	self.city:AddToLabel("Workplace", self)
	self:CheckWorkForUnemployed()
end

function Workplace:Done()
	self.city:RemoveFromLabel("Workplace", self)
	self:KickAllWorkers()
end

function Workplace:OnDestroyed()
	self:KickAllWorkers()
	RebuildInfopanel()
end

function Workplace:ToggleSpecialistEnforce(broadcast)
	self:SetSpecialistEnforce(not self.specialist_enforce_mode)
	if broadcast then
		BroadcastAction(self, "SetSpecialistEnforce", self.specialist_enforce_mode)
	end
end

function Workplace:SetSpecialistEnforce(specialist_enforce_mode)
	specialist_enforce_mode = specialist_enforce_mode or false
	if self.specialist_enforce_mode == specialist_enforce_mode then
		return
	end
	self.specialist_enforce_mode = specialist_enforce_mode
	if not specialist_enforce_mode then
		self:CheckWorkForUnemployed()
		return
	end
	local specialist = self.specialist or "none"
	for _, list in ipairs(self.workers) do
		for i = #list,1,-1 do
			local worker = list[i]
			if (worker.specialist or "none") ~= specialist and not worker:IsDying() then
				worker:SetWorkplace(false)
				worker.user_forced_workplace = false
				worker:UpdateWorkplace()
			end
		end
	end
end

function Workplace:ToggleSpecialistEnforce_Update(button)
	local enforce = self.specialist_enforce_mode
	local specialist = self.specialist or "none"
	if not enforce then
		button:SetIcon("UI/Icons/IPButtons/specialization_all.tga")
		button:SetRolloverTitle(T(8742, "Workforce: No Restrictions"))
		button:SetRolloverText(T(8743, "Set accepted workforce for this building.<newline><newline>Current status: <em>No restrictions</em>"))
	elseif specialist == "none" then
		button:SetIcon("UI/Icons/IPButtons/specialization_off.tga")
		button:SetRolloverTitle(T(8744, "Workforce: Reject Specialists"))
		button:SetRolloverText(T(8745, "Set accepted workforce for this building.<newline><newline>Current status: <em>Specialists not accepted</em>"))
	else
		button:SetIcon("UI/Icons/IPButtons/specialization_on.tga")
		button:SetRolloverTitle(T(8746, "Workforce: Enforce Specialists"))
		button:SetRolloverText(T(8747, "Set accepted workforce for this building.<newline><newline>Current status: <em>Only specialists accepted</em>"))
	end
	
	if enforce then
		button:SetRolloverHint(T(8748, "<left_click> No restrictions <newline><em>Ctrl + <left_click></em> No restrictions for all <display_name_pl>"))
		button:SetRolloverHintGamepad(T(8749, "<ButtonA> No restrictions <newline><ButtonX> No restrictions for all <display_name_pl>"))
	elseif specialist == "none" then
		button:SetRolloverHint(T(8750, "<left_click> Reject specialists <newline><em>Ctrl + <left_click></em> Reject specialists for all <display_name_pl>"))
		button:SetRolloverHintGamepad(T(8751, "<ButtonA> Reject specialists <newline><ButtonX> Reject specialists for all <display_name_pl>"))
	else
		button:SetRolloverHint(T(8752, "<left_click> Enforce specialists <newline><em>Ctrl + <left_click></em> Enforce specialists for all <display_name_pl>"))
		button:SetRolloverHintGamepad(T(8753, "<ButtonA> Enforce specialists <newline><ButtonX> Enforce specialists for all <display_name_pl>"))
	end
end

function Workplace:GetWorkNotPossibleReason()
	if not self:HasNearByWorkers()  then
		return "TooFarFromWorkforce"
	elseif not self:HasWorkersForCurrentShift() then
		if self.active_shift == 0 and self:IsClosedShift(self.current_shift) and self:HasAnyWorkers() then
			return "InactiveWorkshift"
		else
			return "NotEnoughWorkers"
		end
	end
	return ShiftsBuilding.GetWorkNotPossibleReason(self)
end

function Workplace:HasWorkforce()
	local workshift = self.active_shift>0 and self.active_shift or self.current_shift
	return (self.automation > 0) or (workshift and #self.workers[workshift] > 0)
end

function Workplace:GetWorkingWorkers()
	local workshift = self.active_shift>0 and self.active_shift or self.current_shift
	local workers = self.workers[workshift]
	local working = {}
	for i = 1, #workers do
		if workers[i]:IsInWorkCommand() then
			working[#working + 1] = workers[i]
		end
	end
	return working
end

function Workplace:HasAnyWorkers()
	for _,v in ipairs(self.workers) do
		if #v > 0 then
			return true
		end
	end
	return self.automation > 0
end

function Workplace:SetWorkshift(workshift)
	if self.destroyed then 
		return 
	end
	if self:HasMember("electricity") and not self.electricity then -- in case it gets called before the building is properly initilized
		assert(false, string.format("%s,Workshift will not be changed", self.class))
		return
	end
	ShiftsBuilding.SetWorkshift(self, workshift)
	self:UpdatePerformance()
end

function Workplace:GetWorkshiftPerformance(shift)
	if self:IsShroudedInRubble() then
		return 0
	end

	if self.active_shift > 0 then
		-- single shift buildings work all the time, their performance = performance of the active shift
		shift = self.active_shift
	end
	
	local workers = self.workers[shift] or empty_table
	local overtimed = self.overtime[shift] 
	
	if self.automation > 0 and (#workers == 0 or self.max_workers == 0) then
		return self.auto_performance
	end
	
	local part_per_worker = 100/self.max_workers
	local part_rem_add = 100%self.max_workers
	local performance = 0
	if #workers>0 then
		for _, worker in ipairs(workers) do
			performance = performance + MulDivRound(Max(worker.performance, 25), part_per_worker + part_rem_add, 100)
			part_rem_add = 0
		end
	
		--overtimed workers
		if overtimed then
			performance = performance + g_Consts.OvertimedShiftPerformance
		end
	end
	return performance
end

function Workplace:UpdatePerformance()
	if self.max_workers <= 0 then
		self:SetBase("performance", self.automation > 0 and self.auto_performance or 0)
		ObjModified(self)
		return
	end
	
	local shift = self.active_shift > 0 and self.active_shift or self.current_shift
	self:SetBase("performance", self:GetWorkshiftPerformance(shift))
	ObjModified(self)	
end

function OnMsg.TechResearched(tech_id, research)
	if tech_id == "SustainedWorkload" then
		UIColony:ForEachLabelObject("Workplace", "UpdatePerformance")
	end
end

function Workplace:GetPerformanceEffects(shift)
	local texts = {}
	if shift then
		local count = #self.workers[shift]
		texts[#texts +1] = T{838, "Workers: <workers> of <max_workers>", workers = count} 
	end
	table.iappend(texts, self:GetPropertyModifierTexts("performance") or empty_table)
	return texts
end

function Workplace:GetPerformanceReasons(shift)
	local texts = {}
	-- workers
	if self.max_workers <= 0 then
		if self.automation > 0 then
			texts[#texts +1] = T(7628, "<green>Automation +<auto_performance></green>")--	automation,self.automation > 0 and self.auto_performance or 0
		end	
	else
		local shift = self.active_shift > 0 and self.active_shift or shift
		--workshift,self:GetWorkshiftPerformance(shift)), from workers
		local overtimed = self.overtime[shift]
		texts[#texts +1] = T{7629, "<green>Workshift workers +<amount></green>",amount = self:GetWorkshiftPerformance(shift) - (overtimed and g_Consts.OvertimedShiftPerformance or 0) }
		-- + overtimed
		if overtimed then
			texts[#texts +1] = T{7630, "<green>Heavy workload +<amount></green>",amount = g_Consts.OvertimedShiftPerformance }
		end
	end
	-- add upgrades 
	for upgrade_id, modifiers in pairs(self.upgrade_id_to_modifiers or empty_table) do
		for i=1, #modifiers do
			local modifier = modifiers[i]
			if modifier.prop=="performance" then
				local tier = self:GetUpgradeTier(upgrade_id)
				local upgrade_name = self["upgrade"..tier.."_display_name"]
				local amount = modifier.percent				
				local sign = amount>0 and Untranslated("+") or ""
				local color
				if amount~=0 then
					color = amount>0 and TLookupTag("<green>") or TLookupTag("<red>")				
					sign = amount>0 and Untranslated("+") or ""
					texts[#texts +1] = T{7631, "<clr>Upgrade <amount>% (<upgrade>)</color>",clr = color, amount = sign..Untranslated(amount), upgrade = upgrade_name}
				else
					amount = modifier.amount
					if amount~=0 then
						color = amount>0 and TLookupTag("<green>") or TLookupTag("<red>")				
						sign = amount>0 and Untranslated("+") or ""
						texts[#texts +1] = T{7632, "<clr>Upgrade <amount> (<upgrade>)</color>",clr = color, amount = sign..Untranslated(amount), upgrade = upgrade_name}
					end
				end	
			end
		end
	end
	-- mission sponsor
	local sponsor = GetMissionSponsor()
	for _, effect in ipairs(sponsor) do
		if IsKindOf(effect, "Effect_ModifyLabel") 
			and effect.Prop == "performance" 
			and self.city:IsInLabel(effect.Label, self) 
		then
			local amount = effect.Percent
			local sign = amount>0 and Untranslated("+") or ""
			local color = amount>0 and TLookupTag("<green>") or TLookupTag("<red>")	
			texts[#texts +1] = T{7633, "<clr>Mission sponsor <amount>%</color>",clr = color, amount = sign..Untranslated(amount)}
		end
	end
	-- tech
	-- modifiers, labelmodifiers
	table.iappend(texts, self:GetPropertyModifierTexts("performance") or empty_table)
	return texts
end

function Workplace:CanTrain(unit)
	return false
end

function Workplace:HasWorkersForCurrentShift()
	return		self.automation > 0 or
				self.current_shift and #self.workers[self.current_shift] > 0 or 
				self.active_shift>0 and #self.workers[self.active_shift] > 0
end

function Workplace:AddWorker(worker, shift)
	self.workers[shift] = self.workers[shift] or {}
	table.insert(self.workers[shift], worker)	

	self:UpdatePerformance()
	self:SetWorkplaceWorking()
	self:UpdateAttachedSigns()
end

function Workplace:RemoveWorker(worker)
	for i=1,#self.workers do
		table.remove_entry(self.workers[i], worker)
	end	
	self:SetWorkplaceWorking()
	self:StopWorkCycle(worker)
	if worker:IsInWorkCommand() then
		worker:InterruptCommand()
	end
	self:UpdateAttachedSigns()
end

function Workplace:OnSetUIWorking(work)
	ShiftsBuilding.OnSetUIWorking(self, work) --might wna call super
	if not work then
		self:KickAllWorkers()
		self:InterruptUnitsInHolder()
	else
		self:CheckWorkForUnemployed()
	end
end

function Workplace:OnModifiableValueChanged(prop, old_value, new_value)
	if prop == "max_workers" then
		if old_value > new_value then
			for i=1,self.max_shifts do
				local shift_workers = self.workers[i]
				if #shift_workers>new_value then
					for j = old_value, new_value + 1, -1 do
						local worker = shift_workers[j]
						if IsValid(worker) then
							self:FireWorker(worker)
						end
					end
				end
			end
		end

		if new_value == 0 or self.closed_workplaces then
			local is_automated = self.automation >= 1
			local closed_shifts = self.closed_shifts or empty_table
			for i=1, self.max_shifts do
				if new_value == 0 --close if no workers
					or (old_value > 0 and self.closed_workplaces[i] == old_value) --close if it was already closed with the old check
					or closed_shifts[i] then --close if already closed with the new check
					if is_automated and not closed_shifts[i] then
						self:CloseAllWorkplacesWithoutClosingShift(i)
					else
						self:CloseShift(i)
					end
				end
			end
		end
		self:SetWorkshift(self.current_shift)
		self:CheckWorkForUnemployed()
		self:UpdatePerformance()
		RebuildInfopanel(self)
	elseif prop == "automation" or prop == "auto_performance" then
		if not GameInitThreads[self] then			
			self:SetWorkshift(self.current_shift)	-- NOTE: ShiftsBuilding:GameInit() will do the proper job
		end
	end
end

function Workplace:IsShiftUIActive(shift)
--	if self:IsClosedShift(shift) then return false end	
	if not self.current_shift then return false end
	if self.current_shift==shift then return true end
	
	local prev_shift = self.current_shift - 1
	if prev_shift<=0 then
		prev_shift = self.max_shifts
	end	
end

function Workplace:CloseShift(shift)
	ShiftsBuilding.CloseShift(self, shift)
	self:CloseAllWorkplacesWithoutClosingShift(shift)
end

function Workplace:CloseAllWorkplacesWithoutClosingShift(shift)
	self.closed_workplaces[shift] = self.max_workers
	local workers = self.workers[shift]
	for i=#workers,1, -1 do
		local worker = workers[i]
		worker:SetWorkplace(false)
		worker:UpdateWorkplace()
	end
	assert(#workers == 0)
end

function Workplace:OpenShift(shift)
	ShiftsBuilding.OpenShift(self, shift)
	self.closed_workplaces[shift] = 0	
	self:Notify("CheckWorkForUnemployed")	
end

function Workplace:ToggleOvertime(shift, broadcast)
	local old_overtime = self.overtime[shift]
	if broadcast then
		BroadcastAction(self, function(obj)
			if obj.overtime[shift] == old_overtime then
				obj:ToggleOvertime(shift)
			end
		end)
		return
	end
	self.overtime[shift] = not self.overtime[shift]
	self:UpdatePerformance()
end

function Workplace:ClosePositions(shift, idx)
	self.closed_workplaces[shift] = Clamp(self.max_workers - idx + 1, 0,self.max_workers - #self.workers[shift])
	RebuildInfopanel(self)
end

function Workplace:OpenPositions(shift, idx)
	self.closed_workplaces[shift] = Clamp(self.max_workers - idx, 0, self.max_workers - #self.workers[shift])
	RebuildInfopanel(self)
end

function Workplace:FireWorker(worker)
	worker:GetFired()
	RebuildInfopanel(self)
end

function UpdateWorkplaces(colonists)
	local forced_only = true
	for k=1,2 do
		for i = #(colonists or ""), 1, -1 do
			local col = colonists[i]
			local forced = col:CheckForcedWorkplace()
			if forced_only and forced or not forced_only and not forced then
				col:UpdateWorkplace()
			end
		end
		forced_only = false
	end
end

function Workplace:IsSuitable(colonist)
	return colonist:CanWork() and self:CanWorkHere(colonist) and self:CanWorkTrainHereDomeCheck(colonist)
end

local function HasIncompatibleTraits(workplace, unit_traits)
	for _, trait in ipairs(workplace.incompatible_traits) do
		if unit_traits[trait] then
			return true
		end
	end
end

function Workplace:CanWorkHere(colonist)
	return (not self.specialist_enforce_mode or (self.specialist or "none") == (colonist.specialist or "none"))
		and not HasIncompatibleTraits(self, colonist.traits)
end

function Workplace:ColonistCanInteract(col)
	local traits = col.traits
	if traits.Child or (traits.Senior and not g_SeniorsCanWork) then 
		return false, T(4310, "<red>Seniors and children can't be assigned to work</red>")
	end
	if self.specialist_enforce_mode and (self.specialist or "none") ~= (col.specialist or "none") then
		return false, T(8769, "Required specialization mismatch")
	end
	if col.workplace == self then
		return false, T(4311, "Current Workplace")
	end
	if not col:CanReachBuilding(self) then
		return false, T(4308, "<red>Out of reach</red>")
	end
	if not self:HasOpenWorkSlots() then
		return false, T(4312, "<red>Current work shift is closed</red>")
	end
	if HasIncompatibleTraits(self, traits) then
		return false, T(12595, "<red>Can't work here</red>")
	end
	return true, T{4313, "<UnitMoveControl('ButtonA', interaction_mode)>: Set Workplace", col}
end

function Workplace:CheckServicedDome(test_dome)
	local dome = self.parent_dome
	if dome then
		return dome
	end
	if test_dome and test_dome:IsBuildingInWorkRange(self) then
		return test_dome
	end
	return FindNearestObject(self.city.labels.Dome, self)
end

function Workplace:ColonistInteract(col)
	if col.workplace == self then return end
	local current_shift
	if self.active_shift == 0 then
		current_shift = CurrentWorkshift --should be the shift @ click moment
		for i = 1, 3 do
			if self:HasFreeWorkSlots(current_shift) then
				break
			end
			current_shift = current_shift + 1
			current_shift = current_shift > 3 and current_shift  % 3 or current_shift
		end
	else
		current_shift = self.active_shift
	end
	col.user_forced_workplace = {self, current_shift, GameTime()}
	
	local col_dome = col.dome
	local best_dome = self:CheckServicedDome(col_dome)
	if AreDomesConnected(best_dome, col_dome) then
		col:UpdateWorkplace()
	else
		col:SetForcedDome(best_dome)
	end
	return true
end

function Workplace:CheckWorkForUnemployed()
	if not ValidateBuilding(self) then
		return
	end
	if self.parent_dome then
		UpdateWorkplaces(self.parent_dome.labels.Unemployed)
	else
		for _, workforce in ipairs(self.city.labels.Workforce or empty_table) do
			if workforce:IsBuildingInWorkRange(self) then
				UpdateWorkplaces(workforce.labels.Unemployed)
			end
		end
	end
	self:UpdatePerformance()
end

function Workplace:KickAllWorkers()
	for i = 1, #self.workers do
		local shift = self.workers[i]
		for j = #shift,1,-1 do
			local worker = shift[j]
			if not worker:IsDying() then
				worker:SetWorkplace(false)
				worker:UpdateWorkplace()
			end
		end
	end
end

function Workplace:MoveWorkers(from_shift, to_shift)
	if from_shift == to_shift then return end
	local shift = to_shift
	from_shift = self.workers[from_shift]
	to_shift = self.workers[to_shift]
	local c = 1
	while #from_shift > 0 do
		local fworker = from_shift[1]
		local tworker = to_shift[c]
		c = c + 1
		if fworker and not fworker:IsDying() then
			if tworker then
				tworker:SetWorkplace(false)
			end
			
			fworker:SetWorkplace(self, shift)
			
			if tworker and not tworker:IsDying() then
				tworker:UpdateWorkplace()
			end
		end
	end
end

function Workplace:GetUnitsInShifts()
	return self.workers or empty_table
end

-- open positions only
function Workplace:GetFreeWorkSlots(shift)
	shift = shift or self.active_shift or 0
	local max = self.max_workers
	local occupied = self.workers or empty_table
	local closed = self.closed_workplaces or empty_table
	local sum = 0
	local from, to = shift > 0 and shift or 1, shift > 0 and shift or self.max_shifts
	for i = from, to do
		sum = sum + Max(0, max - #occupied[i] - (closed[i] or 0))
	end
	return sum
end

function Workplace:HasFreeWorkSlots(shift)
	shift = shift or self.active_shift or 0
	local max = self.max_workers
	local occupied = self.workers or empty_table
	local closed = self.closed_workplaces or empty_table
	local from, to = shift > 0 and shift or 1, shift > 0 and shift or self.max_shifts
	for i = from, to do
		if max - #occupied[i] - (closed[i] or 0) > 0 then
			return true
		end
	end
end

function Workplace:HasOpenWorkSlots(shift)
	shift = shift or self.active_shift or 0
	local max = self.max_workers
	local closed = self.closed_workplaces or empty_table
	local from, to = shift > 0 and shift or 1, shift > 0 and shift or self.max_shifts
	for i = from, to do
		if max - (closed[i] or 0) > 0 then
			return true
		end
	end
end

-- closed positions only
function Workplace:GetClosedSlots()
	local closed = self.closed_workplaces or empty_table
	if self.active_shift > 0 then
		return closed[self.active_shift] or 0
	end	
	local sum = 0
	for i = 1, self.max_shifts do
		sum = sum + (closed[i] or 0)
	end
	return sum
end

function Workplace:GetWorstWorker(unit, shift)
	local shift_found
	local worst = unit
	local specialist = self.specialist or "none"
	local check_forced = true
	for k = 1,2 do
		for s = shift or 1, shift or #self.workers do
			for _, worker in ipairs(self.workers[s]) do
				local found = true
				if check_forced and worker:CheckForcedWorkplace() == self then
					found = false
				elseif worst then
					local worker_specialist_match = (worker.specialist or "none") == specialist
					local worst_specialist_match = (worst.specialist or "none") == specialist
					if worker_specialist_match ~= worst_specialist_match then
						found = worst_specialist_match
					else
						local worker_renegade = worker.traits.Renegade or false
						local worst_renegade = worst.traits.Renegade or false
						if worker_renegade ~= worst_renegade then
							found = worker_renegade
						else
							found = worker.performance < worst.performance
						end
					end
				end
				if found then
					worst = worker
					shift_found = s
				end
			end
		end
		if shift_found then
			return worst, shift_found
		end
		check_forced = false
	end
	
	return nil, shift
end

function Workplace:FindFreeSlotForced(shift)
	if self.active_shift == 0 then
		for i = 1, 3 do
			if self:HasFreeWorkSlots(shift) then
				return shift
			end
			shift = shift + 1
			shift = shift > 3 and shift % 3 or shift
		end
		
		for i = 1, 3 do
			if self:HasOpenWorkSlots(shift) then
				break
			end
			
			shift = shift + 1
			shift = shift > 3 and shift % 3 or shift
		end
	else
		shift = self.active_shift
		
		if self:HasFreeWorkSlots(shift) then
			return shift
		end
	end
	
	if not self:HasOpenWorkSlots(shift) then
		--shift is closed
		return
	end
	
	local to_kick
	to_kick, shift = self:GetWorstWorker(nil, shift)
	if to_kick then
		to_kick.user_forced_workplace = nil
		return shift, to_kick
	end
	
	return shift
end

function Workplace:OnChangeWorkshift(old, new)
	if old then
		local g_consts = g_Consts
		local martianborn_resilience = self.city.colony:IsTechResearched("MartianbornResilience")
		local dark_penalty = IsDarkHour(UIColony.hour - 4) and -g_consts.WorkDarkHoursSanityDecrease
		local overtime = self.overtime[old]
		local outside_sanity_decrease = not self.parent_dome and not GetAtmosphereBreathable(self:GetMapID()) and -g_consts.OutsideWorkplaceSanityDecrease
		for _, worker in ipairs(self.workers[old] or empty_table) do
			if dark_penalty then
				worker:ChangeSanity(dark_penalty, "work in dark hours")
			end
			local traits = worker.traits
			if overtime and worker:IsWorking() and not traits.Workaholic then
				worker:ChangeHealth(-g_consts.WorkOvertimeHealth, "overtime")
				worker:ChangeSanity(-g_consts.WorkOvertimeSanityDecrease, "overtime")
			end	
			if outside_sanity_decrease and not (martianborn_resilience and traits.Martianborn) then
				worker:ChangeSanity(outside_sanity_decrease, "outside workplace")
			end
			worker:InterruptVisit()
		end
	end
	if new then
		-- try to force the workers in the new shift to come to work
		for _, worker in ipairs(self.workers[new] or empty_table) do
			if worker:CanChangeCommand() then
				local cmd = worker.command
				if cmd == "VisitService" or cmd == "Rest" then
					worker:InterruptVisit()
				elseif cmd == "Idle" then
					worker:SetCommand("Work")
				end
			end
		end
	end
	RebuildInfopanel(self)
end

function Workplace:ShouldHideNoWorkersSign()
	if not self.ui_working then
		return true
	end
	return false
end

function Workplace:UpdateAttachedSigns()
	local shift_closed = self:IsClosedShift(self.current_shift)
	
	self:AttachSign(not self:ShouldHideNoWorkersSign() and 
		(not self:HasAnyWorkers() or (not shift_closed and not self:HasWorkforce())), "SignNoWorkers")
end

function Workplace:StartWorkCycle(unit)
	self:UpdatePerformance()
end

function Workplace:StopWorkCycle(unit)
	self:UpdatePerformance()
end

local workforce_query_func = function(workforce, workplace)
	local workforce_class = workforce
	if IsKindOf(workforce, "ConstructionSite") then
		if IsKindOf(workforce.building_class_proto, "Workforce") then
			workforce_class = workforce.building_class_proto
		else
			return
		end
	end
	local range = workforce_class and workforce_class:GetOutsideWorkplacesDist()
	if not workforce_class.IsBuildingInWorkRange(workforce, workplace, range) then
		return
	end
	workplace.domes_query_res = true
	return "break"
end

-- for UI warning
function Workplace:HasNearByWorkers()
	if self.automation > 0 or IsObjInDome(self) then
		return true
	end
	if self.domes_query_version == g_DomeVersion then
		return self.domes_query_res
	end
	self.domes_query_version = g_DomeVersion
	self.domes_query_res = false

	-- 50 is hardcoded... why?
	local realm = GetRealm(self)
	realm:MapForEach(self, "hex", g_Consts.DefaultOutsideWorkplacesRadius + 50, "ConstructionSite", "Workforce", workforce_query_func, self)
	return self.domes_query_res
end

function Workplace:GatherConstructionStatuses(statuses) 
	if not self:HasNearByWorkers() then
		statuses[#statuses + 1] = ConstructionStatus.NoNearbyWorkers
	end 
	Building.GatherConstructionStatuses(self, statuses)
end

function Workplace:OnSelected()
	SelectionArrowAdd(self.workers)
end

Workplace.InitInside = InitInsideTrainingAndWorkplaceBld
--------------------------------------------- Choose workplace -----------------------------------------------------------------------------------------------------------
function FindTrainingSlot(bld, unit)
	local active_shift = bld.active_shift or 0
	local max = bld.max_visitors
	local visitors = bld.visitors or empty_table
	local closed = bld.closed_visitor_slots or empty_table
	local min_shift_occupation, next_shift_occupation = max_int, max_int
	local shift_found
	local from, to = active_shift > 0 and active_shift or 1, active_shift > 0 and active_shift or bld.max_shifts
	for shift = from, to do
		local units = #visitors[shift]
		local total = max - (closed[shift] or 0)
		if total > units then
			local occupation = MulDivRound(units, 100, total)
			if min_shift_occupation > occupation then
				min_shift_occupation = occupation
				next_shift_occupation = MulDivRound(units + 1, 100, total)
				shift_found = shift
			end	
		end
	end
	
	return shift_found, min_shift_occupation, next_shift_occupation
end

function ChooseTraining(unit, training_buildings, bb_in, bws_in)
	local current_bld, current_shift = bb_in or unit.workplace, bws_in or unit.workplace_shift
	local avoid_workplace = unit.avoid_workplace
	if avoid_workplace and (not unit.avoid_workplace_start or unit.avoid_workplace_start + g_Consts.AvoidWorkplaceSols < UIColony.day) then
		avoid_workplace = false
	end
	local min_occupation, control_occupation = max_int, max_int
	local best_bld, best_shift, best_priority = false, false, -1
	if current_bld and current_bld:CanTrain(unit) then
		local total = current_bld.max_visitors - (current_bld.closed_visitor_slots[current_shift] or 0)
		if total > 0 then
			best_bld, best_shift, best_priority = current_bld, current_shift, current_bld.priority
			local units = #best_bld.visitors[best_shift]
			min_occupation = MulDivRound(units, 100, total)
			control_occupation = MulDivRound(units - 1, 100, total)
		end
	end
	
	training_buildings = training_buildings or (unit.dome and unit.dome.labels.TrainingBuilding) or empty_table
	
	for _, bld in ipairs(training_buildings) do
		if bld:CanTrain(unit)
			and not bld.destroyed and not bld.demolishing 
			and bld.ui_working
			and bld ~= avoid_workplace
			and bld.priority >= best_priority
		then
			local shift_found, min_shift_occupation, next_shift_occupation = FindTrainingSlot(bld, unit)
			if shift_found
			and (best_priority < bld.priority
				or min_occupation > min_shift_occupation and next_shift_occupation < control_occupation) then
				-- higher priority OR worst visitors count
				min_occupation = min_shift_occupation
				best_shift = shift_found
				best_bld = bld
				best_priority = bld.priority
			end
		end
	end
	return best_bld, best_shift
end
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

function ValidateBuilding(building)
	return IsValid(building) and not building.destroyed and not building.demolishing and not building.refab_work_request and building or false
end
local ValidateBuilding = ValidateBuilding

local function ShouldProc(bld, avoid_workplace, specialist, traits)
	return ValidateBuilding(bld) and avoid_workplace ~= bld and bld.ui_working and bld.max_workers > 0 
	and (not bld.specialist_enforce_mode or (bld.specialist or "none") == specialist)
	and not HasIncompatibleTraits(bld, traits)
end

function GetWorkplaceOccupation(bld, shift)
	if not IsKindOf(bld, "Workplace") then return 0 end
	local max = bld.max_workers
	local closed = bld.closed_workplaces or empty_table
	local total = max - (closed[shift] or 0)
	local workers = bld.workers or empty_table
	local list = workers[shift]
	local units = #list
	local r = MulDivRound(units, 100, total)
	return r
end

function FindWorkSlot(bld, unit, current_bld, current_shift, specialist, renegade)
	current_bld = current_bld or ValidateBuilding(unit.workplace)
	current_shift = current_shift or unit.workplace_shift
	local max = bld.max_workers
	local active_shift = bld.active_shift or 0
	local workers = bld.workers or empty_table
	local closed = bld.closed_workplaces or empty_table
	local min_shift_occupation = max_int
	local shift_found, shift_to_kick, possible_replacement
	local no_workers = bld.automation == 0
	local required_specialist = bld.specialist or "none"
	local specialist_match = specialist == required_specialist
	local from, to = active_shift > 0 and active_shift or 1, active_shift > 0 and active_shift or bld.max_shifts

	for shift = from, to do
		local list = workers[shift]
		local units = #list
		local is_current_workplace = bld == current_bld and shift == current_shift
		if is_current_workplace then
			assert(current_bld == ValidateBuilding(unit.workplace) and current_shift == unit.workplace_shift)
			assert(table.find(list, unit))
			units = units - 1
		end
		if units > 0 then
			no_workers = false
		end
		local to_kick
		if specialist_match then
			-- in case of a new specialist matching the workplace specialization, count only the workers that cannot be replaced
			for i=#list,1,-1 do
				local worker = list[i]
				local can_replace
				if not worker:CheckForcedWorkplace() then
					-- cannot replace forced workers
					local specialist = worker.specialist or "none"
					if specialist ~= required_specialist then
						can_replace = true
					else
						local worker_renegade = worker.traits.Renegade or false
						if worker_renegade ~= renegade then
							can_replace = worker_renegade
						end
					end
				end
				if can_replace then
					to_kick = worker
					units = units - 1
				end
			end
		end
		local total = max - (closed[shift] or 0)
		if total > units then
			-- empty space is found, or there is someone we can replace
			local occupation = MulDivRound(units + (to_kick and 1 or 0), 100, total)
			if min_shift_occupation > occupation or (is_current_workplace and (min_shift_occupation == occupation or min_shift_occupation == max_int)) then
				min_shift_occupation = occupation
				shift_found = shift
				shift_to_kick = total - units == 1 and to_kick or nil
				possible_replacement = not shift_to_kick and to_kick or nil
			end
		end
	end
	
	return shift_found, shift_to_kick, min_shift_occupation, specialist_match, no_workers, possible_replacement
end

function DbgAddWorkVector(unit, bld, color)
	if bld and bld ~= unit.workplace then
		local pos = unit:GetLogicalPos()
		DbgAddVector(pos, bld:GetPos() - pos, color)
	end
end

function ChooseWorkplace(unit, workplaces, allow_exchange)
	local current_bld = ValidateBuilding(unit.workplace)
	local current_shift = unit.workplace_shift
	assert(not current_bld or not current_bld.force_lock_workplace)
	local avoid_workplace = unit.avoid_workplace
	if avoid_workplace and (not unit.avoid_workplace_start or unit.avoid_workplace_start + g_Consts.AvoidWorkplaceSols < UIColony.day) then
		avoid_workplace = false
	end
	local traits = unit.traits
	local renegade = traits.Renegade or false
	local specialist = unit.specialist or "none"
	local min_occupation, min_exchange_occupation = max_int, max_int
	local best_priority, exchange_priority = 0, 0
	local best_bld, best_shift, best_to_kick, best_specialist_match, best_no_workers
	local exchange_bld, exchange_shift, exchange_worker, best_dome_idx, exchange_best_dome_idx
	
	local tbl1 = type(workplaces[1]) == "table" and not IsValid(workplaces[1]) and workplaces or {workplaces}
	for i = 1, #tbl1 do
		workplaces = tbl1[i]
		for _, bld in ipairs(workplaces or empty_table) do
			local priority = bld.priority
			if ShouldProc(bld, avoid_workplace, specialist, traits) and (allow_exchange or priority >= best_priority) then
				local shift_found, shift_to_kick, min_shift_occupation, specialist_match, no_workers, possible_replacement = FindWorkSlot(bld, unit, current_bld, current_shift, specialist, renegade)
				if shift_found then
					if best_priority < priority -- workplaces with higher priority are always prefered
					or best_priority == priority  -- for buildings with the same priority,
					and (specialist_match and not best_specialist_match --choose if specialist match
						or specialist_match == best_specialist_match
							and (min_occupation > min_shift_occupation -- chose if that would improve the worker percentage
							or no_workers and not best_no_workers -- or try to avoid having buildings with no workers
							or bld == current_bld and shift_found == current_shift -- try to preserve the current workplace if all of the above conditions are met
							or best_dome_idx < i and i == #tbl1)) --if evertything else is the same, pick own dome
					then
						min_occupation = min_shift_occupation
						best_shift = shift_found
						best_bld = bld
						best_priority = priority
						best_specialist_match = specialist_match
						best_to_kick = shift_to_kick
						best_no_workers = no_workers
						best_dome_idx = i
					end
					
					-- check for possible exchange if the best building isn't a good match for this specific worker
					if allow_exchange and (shift_to_kick or possible_replacement)
					and (exchange_priority < priority
						or exchange_priority == priority
						and min_exchange_occupation > min_shift_occupation
							or min_exchange_occupation == min_shift_occupation
								and exchange_best_dome_idx < i and i == #tbl1)
					then
						assert(specialist_match and shift_found and not no_workers)
						exchange_bld = bld
						exchange_shift = shift_found
						exchange_priority = priority
						exchange_worker = shift_to_kick or possible_replacement
						min_exchange_occupation = min_shift_occupation
						exchange_best_dome_idx = i
					end
				end
			end
		end
	end
	-- in case the the choosen building isn't the best building, exchange the colonists between workplaces
	if exchange_worker and not best_to_kick
	and best_bld and exchange_bld ~= best_bld
	and exchange_priority >= best_priority and not best_specialist_match
	and best_bld:IsSuitable(exchange_worker) then
		--DbgAddWorkVector(exchange_worker, best_bld, red)
		exchange_worker:SetWorkplace(best_bld, best_shift)
		best_bld, best_shift, best_specialist_match = exchange_bld, exchange_shift, true
	end
	--DbgAddWorkVector(unit, best_bld, green)
	return best_bld, best_shift, best_to_kick, best_specialist_match
end

function CompareWorkplaces(bld1, bld2, unit)
	local avoid_workplace = unit.avoid_workplace
	local specialist = unit.specialist or "none"
	local traits = unit.traits
	local p1, p2 = ShouldProc(bld1, avoid_workplace, specialist, traits), ShouldProc(bld2, avoid_workplace, specialist, traits)
	if not p1 and not p2 then --equally unaccpetable
		return nil	
	end
	if p1 ~= p2 then
		return p1 and bld1 or bld2
	end
	
	local current_bld = ValidateBuilding(unit.workplace)
	local current_shift = unit.workplace_shift
	local renegade = traits.Renegade or false
	local sf1, stk1, mso1, sm1, nw1 = FindWorkSlot(bld1, unit, current_bld, current_shift, specialist, renegade)
	local sf2, stk2, mso2, sm2, nw2 = FindWorkSlot(bld2, unit, current_bld, current_shift, specialist, renegade)
	sf1 = not not sf1
	sf2 = not not sf2
	
	if sf1 ~= sf2 then
		return sf1 and bld1 or bld2
	end
	if bld1.priority ~= bld2.priority then
		return bld1.priority > bld2.priority and bld1 or bld2
	end
	if sm1 ~= sm2 then
		return sm1 and bld1 or bld2
	end
	if mso1 ~= mso2 then
		return mso1 < mso2 and bld1 or bld2
	end
	if nw1 ~= nw2 then
		return nw1 and bld1 or bld2
	end
	
	return bld2 == current_bld and sf2 == current_shift and bld2 or bld1
end

function Workplace:GetUISpecialization()
	return GetSpecialization(self.specialist).display_name_plural
end

local WorkerSlot = {
	"RolloverTitle", T(7305, "<DisplayName>"),
	"RolloverText", T(6768, "A colonist working in this building.<newline><newline>Specialization: <em><Specialization></em><newline>Worker Performance: <em><performance></em><newline><PerformanceReasons><TraitsWarnings>"),
	"RolloverHint", T(12184, "<left_click> Select  <right_click> Fire worker"),
	"RolloverHintGamepad", T(12185, "<ButtonA> Select  <ButtonX> Fire worker"),
}

local WorkerSlotForced = {
	"RolloverTitle", T(7305, "<DisplayName>"),
	"RolloverText", T(12394, "A colonist assigned to work in this building.<newline><newline>Assignment Remaining: <em><time(WorkAssignmentRemaining)></em><newline>Specialization: <em><Specialization></em><newline>Worker Performance: <em><performance></em><newline><PerformanceReasons><TraitsWarnings>"),
	"RolloverHint", T(12184, "<left_click> Select  <right_click> Fire worker"),
	"RolloverHintGamepad", T(12185, "<ButtonA> Select  <ButtonX> Fire worker"),
}

local OpenSlot = {
	"Icon", "UI/Infopanel/colonist_empty.tga",
	"RolloverTitle", T(4218, "Free Work Slot"),
	"RolloverText", T(4219, "Free work slot. Unemployed Workers automatically seek jobs within their Dome.<newline><newline><red>Free work slots reduce workplace performance.</red>"),
	"RolloverHint", T(7529, "<right_click> Close this work slot"),
	"RolloverHintGamepad", T(4220, "<ButtonX> Close this work slot"),
}

local ClosedSlot = {
	"Icon", "UI/Infopanel/colonist_closed.tga",
	"RolloverTitle", T(4222, "Closed Work Slot"),
	"RolloverText", T(4223, "This work slot is closed. Workers will never occupy it.<newline><newline><red>Closed work slots reduce workplace performance.</red>"),
	"RolloverHint", T(7530, "<right_click> Open this work slot"),
	"RolloverHintGamepad", T(4224, "<ButtonX> Open this work slot"),
}

local shift_names = {
	T(541987944858, --[[sectionWorkshifts RolloverTitle]] "First Shift"),
	T(159665176435, --[[sectionWorkshifts RolloverTitle]] "Second Shift"),
	T(994186128274, --[[sectionWorkshifts RolloverTitle]] "Night shift"),
}


-- sub-controls idCurrentShift, idShift, idOvertime
function UIWorkshiftUpdate(self, building, shift)
	self:SetRolloverTitle(shift_names[shift])
	local training = building:IsKindOf("TrainingBuilding") and building.max_visitors > 0
	local workplace = building:IsKindOf("Workplace") and building.max_workers > 0
	local shift_active = building:IsShiftUIActive(shift)
	local shift_closed = building:IsClosedShift(shift)
	local shift_overtime = workplace and building.overtime[shift]
	local single_shift = workplace and building.active_shift ~= 0
	
	if self.Id == "" then
		self:SetId("idWorkshift" .. shift)
	end
	-- idCurrentShift
	self.idActive:SetVisible(shift_active)
	-- idShift & idStoppedWorkshift
	if shift_closed then
		if single_shift then
			self:SetIcon("UI/Icons/Sections/workshifts_stop.tga")
			self:SetTitle(T(130, "N/A"))
		else
			self:SetIcon("UI/Icons/Sections/workshifts_pause.tga")
			self:SetTitle((workplace or training) and T(7359, "Stopped Work Shift") or T(6771, "<red>OFF</red>"))
		end
	else
		self:SetIcon("UI/Icons/Sections/workshifts_active.tga")
		self:SetTitle((workplace or training) and "" or T(6772, "<green>ON</green>"))
	end
	rawset(self, "ProcessToggle", function(self, context, broadcast)
		local building = ResolvePropObj(context)
		if broadcast then
			local closed = not not building:IsClosedShift(context.shift)
			BroadcastAction(building, function(obj)
				if closed == not not obj:IsClosedShift(context.shift) then
					obj:ToggleShift(context.shift)
				end
			end)
		else
			building:ToggleShift(context.shift)
		end
		RebuildInfopanel(building)
	end)
	self.OnActivate = function (self, context, gamepad)
		self:ProcessToggle(context, not gamepad and IsMassUIModifierPressed())
	end
	self.OnAltActivate = function(self, context, gamepad)
		if gamepad then
			self:ProcessToggle(context, true)
		end
	end
	-- idWorkers
	local max_workers = IsKindOf(building, "TrainingBuilding") and building.max_visitors or IsKindOf(building, "Workplace") and building.max_workers or 0
	if #self.idWorkers ~= max_workers then
		self.idWorkers:DeleteChildren()
		for i = 1, max_workers do
			local person = XTemplateSpawn("InfopanelPerson", self.idWorkers)
			person.OnPress = function(self)
				if self.context then
					self.context:Select(WorkplaceCycle)
				end
			end
			person.OnAltPress = function(self)
				local i = table.find(self.parent, self)
				if self.context then
					self.context:GetFired()
				elseif self:GetIcon() == "UI/Infopanel/colonist_empty.tga" then
					building:ClosePositions(shift, i)
				else
					building:OpenPositions(shift, i)
				end
				ObjModified(building)	
				if GetUIStyleGamepad() then
					RolloverWin:UpdateRolloverContent()
				end
			end
		end
		self.idWorkers:ResolveRelativeFocusOrder()
	end
	self.idWorkers:SetVisible(max_workers > 0 and not shift_closed)
	if max_workers > 0 then
		local closed_slots = training and (building.max_visitors - (building.closed_visitor_slots[shift] or 0))
			or (building.max_workers - (building.closed_workplaces[shift] or 0))
		local workers = training and building.visitors[shift] or building.workers[shift]
		for i, win in ipairs(self.idWorkers) do
			local worker = workers[i]
			win.idSpecialization:SetVisible(worker)
			if worker then
				win:SetIcon(worker:GetInfopanelIcon())
				win.idSpecialization:SetImage(worker.ip_specialization_icon)
				if worker:CheckForcedWorkplace() == building then
					SetObjPropertyList(win, WorkerSlotForced)
				else
					SetObjPropertyList(win, WorkerSlot)
				end
			elseif i <= closed_slots then
				SetObjPropertyList(win, OpenSlot)
			else
				SetObjPropertyList(win, ClosedSlot)
			end
			win:SetContext(worker)
			XRecreateRolloverWindow(win)
		end
	end
	-- idOvertime
	self.idOvertime:SetVisible(workplace)
	if workplace then
		if shift_overtime then
			self.idOvertime:RemoveModifier("desat")
		else
			self.idOvertime:AddInterpolation{id = "desat", type = const.intDesaturation, startValue = 255}
		end
		self.idOvertime:SetRow(shift_active and 2 or 1)
		self.context.UIOvertimeText = shift_overtime and T(4212, "Heavy workload") or T(4213, "Normal workload")
	end
	-- rollover
	self.GetRolloverText = function (self)
		local shift = self.context.shift
		local building = ResolvePropObj(self.context)
		local items = {
			T(7360, "Toggle the current work shift ON or OFF. The building will operate only during active work shifts.")
		}
		local is_workplace = building:IsKindOf("Workplace")
		if is_workplace then
			if building.active_shift > 0 then
				items[#items + 1] = T(228, "<em>This building operates on a single work shift</em>")
			else
				items[#items + 1] = T(7361, "You???ll need a separate crew of workers for each shift.")
			end
			if building.active_shift > 0 or shift == 3 then
				items[#items + 1] = ""
				if shift == 3 then
					items[#items + 1] = T(7362, "<em>Workers will lose Sanity if they work during the night shift.</em>")
				end
			end
		end
		items[#items + 1] = ""
		items[#items + 1] = T{7363, "Working hours<right><number1>-<number2>h", number1 = const.DefaultWorkshifts[shift][1], number2 = const.DefaultWorkshifts[shift][2]}
		items[#items + 1] = T{7364, "Status: <status>", status = building:IsClosedShift(shift) and T(6771, "<red>OFF</red>") or T(6772, "<green>ON</green>")}
		if is_workplace and not building:IsClosedShift(shift) then
			items[#items + 1] = Untranslated("\n")
			items[#items + 1] = shift==building.current_shift and T(7634, "Building performance<right><performance>") or T(7635, "Building performance")
			local texts = building:GetPerformanceReasons(shift)
			texts = table.concat(texts,'\n')
			items[#items + 1] = T{texts, building}
		end
		return table.concat(items, "<newline><left>")
	end
end
