DefineClass.StatsChange = {
	__parents = { "StatsChangeBase", "Building"},
}

g_DiffDomeStrId = "_diff_dome"

function StatsChange:Service(unit, duration, reason, comfort_threshold, interest)
	-- comfort on visit
	local comfort_threshold = comfort_threshold or self:GetEffectiveServiceComfort()
	local is_diff_dome = self.parent_dome and unit.dome ~= self.parent_dome
	comfort_threshold = comfort_threshold - (not is_diff_dome and 0 or g_Consts.NonHomeDomeServiceThresholdDecrement)
	reason = reason or self.template_name
	interest = interest or false
	if is_diff_dome then
		reason = string.format("%s%s", reason, g_DiffDomeStrId)
	end
	
	if unit.stat_comfort < comfort_threshold then
		local comfort_increase = self.comfort_increase
		if unit.traits.Hippie and (self:GetBuildMenuCategory() == "Decorations" or self.template_name == "HangingGardens") then
			comfort_increase = 2 * comfort_increase
		end
		
		unit:ChangeComfort(comfort_increase, reason)
	end

	StatsChangeBase.Service(self, unit, reason)

	self:ConsumeOnVisit(unit, interest)
	if duration then
		unit:PlayPrg(GetVisitPrg(self), duration, self)
	end
end

local typeVisit = g_ConsumptionType.Visit
function StatsChange:ConsumeOnVisit(unit)
	if self:DoesHaveConsumption() and self.consumption_type == typeVisit then
		self:Consume_Visit(unit)
	end
end

DefineClass.Service = {
	__parents = { "StatsChange", "ServiceBase", "Holder" },
}

function Service:GetIPDescription()
	return 
		T{737, "<description>\nServices: <em><list></em>", 
			description = self.description, 
			list = self:IsKindOf("Service") and self:GetServiceList() or Service.GetServiceList(self)}
end

function Service:SetCustomLabels(obj, add)
	Building.SetCustomLabels(self, obj, add)
	local label = add and obj.AddToLabel or obj.RemoveFromLabel
	label(obj, "Service", self)
	local interest1 = self.interest1
	local interest2 = self.interest2
	local interest3 = self.interest3
	local interest4 = self.interest4
	local interest5 = self.interest5
	local interest6 = self.interest6
	local interest7 = self.interest7
	local interest8 = self.interest8
	local interest9 = self.interest9
	local interest10 = self.interest10
	local interest11 = self.interest11
	local service_interests = {}
	if interest1 ~= "" then
		service_interests[#service_interests + 1] = interest1
		label(obj, interest1, self)
	end
	if interest2 ~= "" and not table.find(service_interests, interest2) then
		service_interests[#service_interests + 1] = interest2
		label(obj, interest2, self)
	end
	if interest3 ~= "" and not table.find(service_interests, interest3) then
		service_interests[#service_interests + 1] = interest3
		label(obj, interest3, self)
	end
	if interest4 ~= "" and not table.find(service_interests, interest4) then
		service_interests[#service_interests + 1] = interest4
		label(obj, interest4, self)
	end
	if interest5 ~= "" and not table.find(service_interests, interest5) then
		service_interests[#service_interests + 1] = interest5
		label(obj, interest5, self)
	end
	if interest6 ~= "" and not table.find(service_interests, interest6) then
		service_interests[#service_interests + 1] = interest6
		label(obj, interest6, self)
	end
	if interest7 ~= "" and not table.find(service_interests, interest7) then
		service_interests[#service_interests + 1] = interest7
		label(obj, interest7, self)
	end
	if interest8 ~= "" and not table.find(service_interests, interest8) then
		service_interests[#service_interests + 1] = interest8
		label(obj, interest8, self)
	end
	if interest9 ~= "" and not table.find(service_interests, interest9) then
		service_interests[#service_interests + 1] = interest9
		label(obj, interest9, self)
	end
	if interest10 ~= "" and not table.find(service_interests, interest10) then
		service_interests[#service_interests + 1] = interest10
		label(obj, interest10, self)
	end
	if interest11 ~= "" and not table.find(service_interests, interest11) then
		label(obj, interest11, self)
	end
end

function Service:BuildingDailyUpdate(...)
	self.visitors_per_day = 0
end

function Service:CanBeUsedBy(colonist)
	if not self.working then
		return false, ServiceFailure.Closed
	else
		return ServiceBase.CanBeUsedBy(self, colonist)
	end
end

function Service:CanService(unit)
	if ServiceBase.CanService(self, unit) then
		local insufficient_consumptions = self:DoesHaveConsumption() and self.consumption_type == g_ConsumptionType.Visit and self.consumption_stored_resources <= 0
		return not insufficient_consumptions
	end
	return false
end

function Service:Assign(unit)
	ServiceBase.Assign(self, unit)
	self:UpdateServiceOccupation()
end

function Service:Unassign(unit)
	ServiceBase.Unassign(self, unit)
	self:UpdateServiceOccupation()
end

function Service:UpdateServiceOccupation()
	self:UpdateOccupation(#self.visitors, self.max_visitors)
end

function Service:Service(unit, duration, daily_interest)
	duration = ServiceBase.ServiceInternal(self, unit, duration, daily_interest)
	local comfort_threshold = self:GetEffectiveServiceComfort()
	local reason
	if unit.traits.Extrovert and self:IsOneOfInterests("interestSocial") and unit.dome and #unit.dome.labels.Colonist>30 then -- party animal		
		comfort_threshold = comfort_threshold + g_Consts.ExtrovertIncreaseComfortThreshold
		reason = "party animal"
	end
	StatsChange.Service(self, unit, duration, reason, comfort_threshold, daily_interest)
end

DefineClass.ServiceWorkplace = {
	__parents = { "Service", "Workplace"},
}

function ServiceWorkplace:OnChangeWorkshift(old, new)
	Workplace.OnChangeWorkshift(self, old, new)
	local visitors = table.icopy(self.visitors)
	for _, visitor in ipairs(visitors) do
		visitor:AssignToService(false) -- unassign from building when interupted
		visitor:InterruptCommand()
	end
	self.visitors = {}
	self.free_visitor_slots = self.max_visitors	
end

function ServiceWorkplace:GetEffectiveServiceComfort()
	-- performace effect on service quality
	local effect = g_Consts.PerformanceEffectOnServiceComfort
	return self.service_comfort + effect * (self:GetEffectivePerformance() - 100) / 100
end

function ServiceWorkplace:GetEffectivePerformance()
	-- if a workshift is stopped or the building is stopped ,services show a parameter for Service Quality at 100 performance
	if not self.ui_working or (self.active_shift == 0 and self:IsClosedShift(self.current_shift) and self:HasAnyWorkers() and self.automation <= 0) then
		return 100
	end
	-- performance for working building
	return self.performance
end

function ServiceWorkplace:UpdateServiceOccupation()
	self:UpdateOccupation(#self.visitors + #self.workers[CurrentWorkshift], self.max_visitors + self.max_workers)
end

function ServiceWorkplace:AddWorker(worker, shift)
	Workplace.AddWorker(self, worker, shift)
	self:UpdateServiceOccupation()
end

function ServiceWorkplace:RemoveWorker(worker)
	Workplace.RemoveWorker(self, worker, shift)
	self:UpdateServiceOccupation()
end

DefineClass.LifeSupportConsumerService = {
	__parents = { "LifeSupportConsumer", "Service" },
}
