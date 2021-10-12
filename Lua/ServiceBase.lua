local stat_scale = const.Scale.Stat
DefineClass.StatsChangeBase = {
	__parents = { "InitDone"},
	properties = {
		{ category = "Service", template = true, modifiable = true, id = "health_change", name = T(728, "Health change on visit"), default = 0, scale = "Stat", editor = "number" },
		{ category = "Service", template = true, modifiable = true, id = "sanity_change", name = T(729, "Sanity change on visit"), default = 0, scale = "Stat", editor = "number" },
		{ category = "Service", template = true, modifiable = true, id = "service_comfort", name = T(730, "Service Comfort"), default = 40*stat_scale, editor = "number", scale = "Stat" },
		{ category = "Service", template = true, modifiable = true, id = "comfort_increase", name = T(731, "Comfort increase on visit"), default = 10*stat_scale, editor = "number", scale = "Stat"},
		{ category = "Service", template = true, modifiable = true, id = "satisfaction_change", name = T(12712, "Satisfaction change on visit"), default = 0, editor = "number", scale = "Stat"},
	},
}

function StatsChangeBase:GetEffectiveServiceComfort()
	return self.service_comfort
end

function StatsChangeBase:GetEffectivePerformance()
	return 100
end

function StatsChangeBase:Service(unit, reason)
	local performance = self:GetEffectivePerformance()
	unit:ChangeHealth(self.health_change * performance / 100, reason)
	unit:ChangeSanity(self.sanity_change * performance / 100, reason)
	unit:ChangeSatisfaction(self.satisfaction_change, reason)
end

DefineClass.ServiceBase = {
	__parents = { "StatsChangeBase" },
	
	properties = {
		{  category = "Service", template = true, id = "interest1",   name = T(732, "Service interest"), default = "",  editor = "combo", items = function() return ServiceInterestsList end},
		{  category = "Service", template = true, id = "interest2",   name = T(732, "Service interest"), default = "",  editor = "combo", items = function() return ServiceInterestsList end},
		{  category = "Service", template = true, id = "interest3",   name = T(732, "Service interest"), default = "",  editor = "combo", items = function() return ServiceInterestsList end},
		{  category = "Service", template = true, id = "interest4",   name = T(732, "Service interest"), default = "",  editor = "combo", items = function() return ServiceInterestsList end},
		{  category = "Service", template = true, id = "interest5",   name = T(732, "Service interest"), default = "",  editor = "combo", items = function() return ServiceInterestsList end},
		{  category = "Service", template = true, id = "interest6",   name = T(732, "Service interest"), default = "",  editor = "combo", items = function() return ServiceInterestsList end},
		{  category = "Service", template = true, id = "interest7",   name = T(732, "Service interest"), default = "",  editor = "combo", items = function() return ServiceInterestsList end},
		{  category = "Service", template = true, id = "interest8",   name = T(732, "Service interest"), default = "",  editor = "combo", items = function() return ServiceInterestsList end},
		{  category = "Service", template = true, id = "interest9",   name = T(732, "Service interest"), default = "",  editor = "combo", items = function() return ServiceInterestsList end},
		{  category = "Service", template = true, id = "interest10",   name = T(732, "Service interest"), default = "",  editor = "combo", items = function() return ServiceInterestsList end},
		{  category = "Service", template = true, id = "interest11",   name = T(732, "Service interest"), default = "",  editor = "combo", items = function() return ServiceInterestsList end},
		{  category = "Service", template = true, id = "max_visitors",    name = T(733, "Visitor slots per shift"), default = 5,  editor = "number", min = 1, modifiable = true}, 	
		{  category = "Service", template = true, id = "visit_duration",  name = T(734, "Visit duration"),        	 default = 5,  editor = "number", min = 1, max = 10,  slider = true, modifiable = true}, 	
		{  category = "Service", template = true, id = "usable_by_children",name = T(735, "Usable by children"),      default = false, editor = "bool"},
		{  category = "Service", template = true, id = "children_only",   name = T(736, "Children Only"),           default = false, editor = "bool"},
	},

	visitors = false,  -- colonists arrays being serviced
	visitors_per_day = false, 
	visitors_lifetime = false,
}

function ServiceBase:Init()
	self.visitors = {}	
	self.visitors_per_day = 0
	self.visitors_lifetime = 0
end

function ServiceBase:Done()
	self:OnDestroyed()
end

function ServiceBase:OnDestroyed()
	local visitors = self.visitors
	if #visitors == 0 then
		return
	end
	for i = #visitors, 1, -1 do
		local visitor = visitors[i]
		if IsValid(visitor) then
			self:Unassign(visitor)
		end
	end
	self.visitors = {}
end

function ServiceBase:GetServiceList()
	local interests = {}
	interests[#interests + 1] = GetInterestDisplayName(self.interest1)
	interests[#interests + 1] = GetInterestDisplayName(self.interest2)
	interests[#interests + 1] = GetInterestDisplayName(self.interest3)
	interests[#interests + 1] = GetInterestDisplayName(self.interest4)
	interests[#interests + 1] = GetInterestDisplayName(self.interest5)
	interests[#interests + 1] = GetInterestDisplayName(self.interest6)
	interests[#interests + 1] = GetInterestDisplayName(self.interest7)
	interests[#interests + 1] = GetInterestDisplayName(self.interest8)
	interests[#interests + 1] = GetInterestDisplayName(self.interest9)
	interests[#interests + 1] = GetInterestDisplayName(self.interest10)
	interests[#interests + 1] = GetInterestDisplayName(self.interest11)
	return TList(interests)
end

function ServiceBase:IsOneOfInterests(interest)
	return
		self.interest1 == interest 
		or self.interest2 == interest
		or self.interest3 == interest
		or self.interest4 == interest
		or self.interest5 == interest
		or self.interest6 == interest
		or self.interest7 == interest
		or self.interest8 == interest
		or self.interest9 == interest
		or self.interest10 == interest
		or self.interest11 == interest
end

function ServiceBase:HasFreeVisitSlots()
	return #self.visitors < self.max_visitors
end

ServiceFailure = {
	None = -1,
	NotTried = 0,
	NotFound = 1,
	Closed = 2,
	Full = 3,
	CanServiceFailed = 4,
}

function ServiceBase:CanBeUsedBy(colonist)
	if not self:HasFreeVisitSlots() then
		return false, ServiceFailure.Closed
	elseif not self:CanService(colonist) then
		return false, ServiceFailure.CanServiceFailed
	else
		return true, ServiceFailure.None
	end
end

function ServiceBase:CanService(unit)
	local is_child = unit.traits["Child"]
	if is_child and not self.usable_by_children or not is_child and self.children_only then
		return false
	end
	return true
end

function ServiceBase:Assign(unit)
	assert(self:HasFreeVisitSlots())
	table.insert(self.visitors, unit)
end

function ServiceBase:Unassign(unit)
	table.remove_entry(self.visitors, unit)
end

function ServiceBase:ServiceInternal(unit, duration)
	self.visitors_per_day = self.visitors_per_day + 1
	self.visitors_lifetime = self.visitors_lifetime + 1	
	duration = duration or self.visit_duration * const.HourDuration
	return duration
end
	
function ServiceBase:Service(unit, duration, daily_interest)
	duration = self:ServiceInternal(unit, duration)
	StatsChangeBase.Service(self, unit, daily_interest)
	return duration
end
