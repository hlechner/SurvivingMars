--[[
- internal structures:
Research.tech_status[tech_id] = {
	researched = nil/number of times researched
   discovered = nil/index of discovery
   points = 0,
   cost = 0,
   new = nil/true, -- is this tech still not seen by the player?
   queued = nil/true,
   repeatable = nil,false/true, -- used to override the default 'repeatable' status
 }
Research.tech_field[field_id] = {tech_id, ...} -- an array of tech_ids
Research.research_queue = {tech_id, ...} -- an array of tech_ids
--]]

GlobalVar("g_OutsourceDisabled", false)
GlobalVar("g_ResearchScroll", 0)
GlobalVar("g_ResearchFocus", point(1, 1))

function StableShuffle(tbl, rand, max)
	rand = rand or AsyncRand
	max = max or #tbl
	assert(#tbl < max)
	max = Max(max, #tbl)
	local tmp = {}
	while #tbl > 1 do
		local idx = 1 + rand(max)
		if idx <= #tbl then
			tmp[#tmp + 1] = tbl[idx]
			table.remove(tbl, idx)
		end
	end
	for i = #tmp,1,-1 do
		tbl[#tbl + 1] = tmp[i]
	end
end

function GetAvailablePresets(all_presets)
	local preset_filter = function(_,preset)		
		return IsDlcAccessible(preset.save_in)
	end
	return table.ifilter(all_presets, preset_filter)
end

DefineClass.Research = {
	__parents = { "PropertyObject" },
	discover_idx = 0,

	tech_status = false,
	tech_field = false,
	research_queue = false,
	TechBoostPerField = false,
	TechBoostPerTech = false,

	OutsourceResearchPoints = false,
	OutsourceResearchOrders = false,
	paused_sponsor_research_end_time = false,
	paused_outsource_research_end_time = false,

	wasted_electricity_for_rp = 0,
	tech_will_be_granted = false,
}

function Research.CopyMove(self, other)
	CopyMoveClassFields(other, self,
	{
		"discover_idx",
		"tech_status",
		"tech_field",
		"research_queue",
		"TechBoostPerField",
		"TechBoostPerTech",
		"OutsourceResearchPoints",
		"OutsourceResearchOrders",
		"paused_sponsor_research_end_time",
		"paused_outsource_research_end_time",
		"wasted_electricity_for_rp",
		"tech_will_be_granted",
	})
end

function Research.ForwardCalls(source, target)
	for _, call in pairs({"GetEstimatedRP", "IsTechDiscovered", "IsTechResearched", "IsTechResearchable"}) do
		source[call] = function(old_target, ...)
			return target[call](target, ...)
		end
	end
end

function Research:InitResearch()
	self.tech_status = {}
	self.tech_field = {}
	self.research_queue = {}
	self.TechBoostPerField = {}
	self.TechBoostPerTech = {}
	self.OutsourceResearchPoints = {}
	self.OutsourceResearchOrders = {}
	
	local initial_unlocked = GetMissionSponsor().initial_techs_unlocked
	local defs = TechDef
	local fields = GetAvailablePresets(Presets.TechFieldPreset.Default)
	for i=1,#fields do
		local field = fields[i]
		local field_id = field.id
		if (field_id or "") ~= "" then
			local list = self.tech_field[field_id] or {}
			self.tech_field[field_id] = list
			for _, tech in ipairs(Presets.TechPreset[field_id] or empty_table) do
			if self:TechAvailableCondition(tech) then
					if not table.find(list, tech.id) and (tech.id or "") ~= "" then
						list[#list + 1] = tech.id
					end
				end
			end
			local discoverable = field.discoverable
			if discoverable then
				if IsGameRuleActive("ChaosTheory") then
					table.shuffle(list)
				else
					local function IsInRange(idx)
						local tech = defs[list[idx]]
						if not tech then return false end
						local min, max = Max(tech.position.from, 1), Min(tech.position.to, #list)
						return idx >= min and idx <= max, min, max
					end
					StableShuffle(list, self:CreateResearchRand("InitResearch", field.id), 100)
					local retries = 0
					while true do
						local changed
						for j=1,#list - 1 do
							local ok1, min1, max1 = IsInRange(j)
							local ok2, min2, max2 = IsInRange(j + 1)
							local target1 = (min1 + max1 + 1) / 2
							local target2 = (min2 + max2 + 1) / 2
							if target1 > target2 then
								list[j], list[j + 1] = list[j + 1], list[j]
								changed = true
							end
						end
						retries = retries + 1
						if not changed or retries >= #list then
							break
						end
					end
					for j=1,#list do
						if not IsInRange(j) then
							print("Failed to find correct places for all techs in", field.id)
							break
						end
					end
				end
			end
			local costs = field.costs or empty_table
			for j = 1, #list do
				local cost
				if discoverable then
					cost = costs[j]
					if not cost then
						assert(j > #costs)
						local last_cost = costs[#costs] or 0
						local last_diff = last_cost - (costs[#costs - 1] or 0)
						cost = last_cost + (j - #costs) * last_diff
					end
				end
				local tech_id = list[j]
				local tech = defs[tech_id]
				self.tech_status[tech_id] = {
					cost = cost,
					points = 0,
					field = field_id,
				}
				if IsGameRuleActive("EasyResearch") and discoverable then
					self:SetTechDiscovered(list[j])
				end
			end
			if discoverable then
				for i=1,initial_unlocked do
					self:DiscoverTechInField(field_id)
				end
			end
		end
	end
end

function Research:TechAvailableCondition(tech)
	local current_mystery = UIColony.mystery_id
	return (tech.mystery or current_mystery) == current_mystery and tech:condition()
end

function Research:GameInitResearch()
	for id in pairs(self.tech_status) do
		local preset = TechDef[id]
		if preset then
			preset:EffectsInit(UIColony)
		end
	end
end

----

function Research:IsTechDiscovered(tech_id)
	local status = self.tech_status[tech_id]
	return status and status.discovered
end

function Research:IsTechDiscoverable(tech_id)
	local status = self.tech_status[tech_id]
	local field = status and TechFields[status.field]
	return field and field.discoverable
end

--[[
- returns the id of a tech set to discovered in the field (if any is available)
--]]
function Research:DiscoverTechInField(field_id)
	local list = self.tech_field[field_id] or ""
	for i=1,#list do
		local tech_id = list[i]
		if self:SetTechDiscovered(tech_id) then
			return tech_id
		end
	end
end

--[[
- updates the tech status to discovered (set new)
--]]
function Research:SetTechDiscovered(tech_id)
	local status = self.tech_status[tech_id]
	if not status or status.discovered then
		return
	elseif not status.cost then
		local costs = TechFields[status.field].costs
		local idx = Min(#costs, self:TechCount(status.field, "discovered") + 1)
		status.cost = costs[idx]
	end
	self.discover_idx = self.discover_idx + 1
	status.discovered = self.discover_idx
	status.new = GameTime()
	return true
end

----

function Research:IsNewResearchAvailable(field_id)
	local fields = self.tech_field or empty_table
	if field_id then
		local status_all = self.tech_status or empty_table
		for _, tech_id in ipairs(fields[field_id] or empty_table) do
			local status = status_all[tech_id] or empty_table
			if status.discovered and not status.researched then
				return true
			end
		end
	else
		for field_id in pairs(fields) do
			if self:IsNewResearchAvailable(field_id) then
				return true
			end
		end
	end
end

----

GlobalVar("g_BreakthroughsResearched", 0)
--[[
- updates the tech status to researched (clear new)
--]]
function Research:SetTechResearched(tech_id, notify)
	local current_research = self.research_queue[1]
	tech_id = tech_id or current_research
	local status = self.tech_status[tech_id]
	if not status then
		return
	end
	self:SetTechDiscovered(tech_id)
	local tech = TechDef[tech_id]
	if not tech then
		return -- Deliberately early out if not found
	end

	if status.researched then
		if not self:IsTechRepeatable(tech_id) then
			return
		end
		status.researched = status.researched + 1
		status.new = nil
	else
		status.researched = 1
		status.new = GameTime()
		local field_id = status.field
		if TechFields[field_id].discoverable then
			if tech_id == current_research or not self:IsNewResearchAvailable(field_id) then
				self:DiscoverTechInField(field_id)
			end
		end
		if tech.group == "Breakthroughs" then
			g_BreakthroughsResearched = g_BreakthroughsResearched + 1
		end
	end
	status.points = 0
	tech:EffectsApply(UIColony)
	self:DequeueResearch(tech_id)
	--@@@msg TechResearched,tech_id, city, first_time - fired when a tech has been researched.
	Msg("TechResearched", tech_id, self, status.researched == 1)
	Msg("TechResearchedTrigger", TechDef[tech_id]) -- for StoryBits
	if notify then
		AddOnScreenNotification("ResearchComplete", OpenResearchDialog, {name = tech.display_name, context = tech, rollover_title = tech.display_name, rollover_text = tech.description})
	end
	return true
end

function Research:IsTechRepeatable(tech_id)
	local status = self.tech_status[tech_id]
	if not status then
		return
	elseif status.repeatable ~= nil then
		return status.repeatable
	end
	local tech = TechDef[tech_id]
	return tech and tech.repeatable or false
end

function Research:IsTechResearched(tech_id)
	local status = self.tech_status[tech_id]
	return status and status.researched or false
end

function Research:IsTechResearchable(tech_id)
	local status = self.tech_status[tech_id]
	return status and status.discovered and (not status.researched or self:IsTechRepeatable(tech_id))
end

----

function Research:ChangeResearchCost(tech_id, points)
	local status = self.tech_status[tech_id]
	if not status then
		assert(false, "No such tech")
		return
	end
	status.cost = points
end

function Research:ChangeTechRepeatable(tech_id, repeatable)
	local status = self.tech_status[tech_id]
	if not status then
		assert(false, "No such tech")
		return
	end
	status.repeatable = repeatable
end

function Research:TechCost(tech_id)
	local status = self.tech_status[tech_id]
	if not status then
		assert(false, "No such tech")
		return 0
	end
	-- reduce the cost for the tutorial
	if g_Tutorial and g_Tutorial[tech_id] then
		return g_Tutorial[tech_id]
	end
	
	local cost_boost = 0
	if TechFields[status.field] and not TechFields[status.field].discoverable then
		cost_boost = 100 - g_Consts.BreakThroughTechCostMod -- e.g. author commander: 100 - (100 - 30) = 30
	end
	local field_boost = self.TechBoostPerField[status.field] or 0
	local tech_boost = self.TechBoostPerTech[tech_id] or 0
	local boost = Min(80, field_boost + tech_boost + cost_boost)
	
	local cost = status.cost or 0
	if self:IsTechRepeatable(tech_id) then
		local cost_increase = (TechDef[tech_id] or empty_table).cost_increase or 0
		local research_count = status.researched or 0
		cost = cost + MulDivRound(cost, research_count * cost_increase, 100)
	end
	return MulDivRound(cost, 100 - boost, 100)
end

function Research:ResearchQueueCost(tech_id, queue_idx)
	local status = self.tech_status[tech_id] or {}
	local researched = status.researched
	local count = 0
	local queue = self.research_queue or ""
	for i=1,Min(#queue, queue_idx - 1) do
		if queue[i] == tech_id then
			count = count + 1
		end
	end
	status.researched = (researched or 0) + count
	local cost = self:TechCost(tech_id)
	status.researched = researched
	return cost
end

function Research:BoostTechField(tech_field, boost_percent)
	local boost = self.TechBoostPerField
	if not tech_field or tech_field == "" then
		for field_id in pairs(TechFields) do
			boost[field_id] = (boost[field_id] or 0) + boost_percent
		end
	else
		boost[tech_field] = (boost[tech_field] or 0) + boost_percent
	end
end

--[[@@@
Boost technology research speed by reducing the needed research points of all technologies in that field with given percent. Calling multiple times, sums percents before applying them.
@function void Gameplay@BoostTechField(string field, int percent)
@param string field - technology field. Passing "" to that parameter sets boost percent for all technology fields.
@param int percent - boost persent change.
--]]
function BoostTechField(field, percent)
	return UIColony:BoostTechField(field, percent)
end

--[[@@@
Boost specific technology research speed by reducing the needed research points for it with given percent. Calling multiple times, sums percents before applying them.
@function void Gameplay@BoostTech(string tech_id, int percent)
@param string tech_id - technology id.
@param int percent - boost persent change.
--]]
function BoostTech(tech_id, percent)
	 UIColony.TechBoostPerTech[tech_id] = (UIColony.TechBoostPerTech[tech_id] or 0) + percent
end

--[[
- returns queue index, nil if not in queue
--]]
function Research:TechQueueIndex(tech_id)
	return table.find(self.research_queue, tech_id)
end

--[[
-- adds to the queue
--]]
function Research:QueueResearch(tech_id, first)
	if not self:IsTechResearchable(tech_id) 
	or #self.research_queue > const.ResearchQueueSize 
	or not self:IsTechRepeatable(tech_id) and self:TechQueueIndex(tech_id) then
		return
	end
	
	HintDisable("HintResearchAvailable")
	
	if first then
		table.insert(self.research_queue, 1, tech_id)
	else
		table.insert(self.research_queue, tech_id)
	end
	Msg("ResearchQueueChange", self, tech_id)
	return true
end

--[[
- removed from the queue
--]]
function Research:DequeueResearch(tech_id, all)
	local queue = self.research_queue
	local success
	for i = #queue, 1, -1 do
		if queue[i] == tech_id then
			table.remove(queue, i)
			success = true
			if not all then
				break
			end
		end
	end
	if success then
		Msg("ResearchQueueChange", self, tech_id)
		return true
	end
end

--[[
- move research within the queue
--]]
function Research:PrioritizeQueueResearch(tech_id, delta, suppress_event)
	local queue = self.research_queue
	local old_index = table.find(queue, tech_id)
	local target_index = old_index - delta
	if target_index >= 1 and target_index <= #queue then
		local temp = queue[target_index]
		queue[target_index] = queue[old_index]
		queue[old_index] = temp

		if not suppress_event then
			local other_tech_id = self.research_queue[old_index]
			Msg("ResearchQueueSwap", self, tech_id, other_tech_id)
		end
		return old_index, target_index
	end
end

function OnMsg.ResearchQueueChange(research, tech_id)
	ObjModified(TechDef[tech_id])
	ObjModified(research.research_queue)
	for i, id in ipairs(research.research_queue) do
		ObjModified(TechDef[id])
	end
	research:CheckAvailableTech()
end

function OnMsg.ResearchQueueSwap(research, tech_id, other_tech_id)
	ObjModified(research.research_queue)
	ObjModified(TechDef[tech_id])
	ObjModified(TechDef[other_tech_id])
	research:CheckAvailableTech()
end

--[[
- returns a queue with tech ids
--]]
function Research:GetResearchQueue()
	return self.research_queue
end

--[[
- count the number of tech in a field with a specific state (false/"discovered"/"researched")
--]]
function Research:TechCount(field_id, state)
	local list = self.tech_field[field_id] or empty_table
	local count = 0
	for i=1,#list do
		if state == "researched" and self:IsTechResearched(list[i])
		or state == "discovered" and self:IsTechDiscovered(list[i])
		or not state and not self:IsTechDiscovered(list[i])
		then
			count = count + 1
		end
	end
	return count, #list
end

function Research:DiscoveredTechCount()
	local count = 0
	for field_id in pairs(self.tech_field or empty_table) do
		count = count + self:TechCount(field_id, "discovered")
	end
	return count
end

function Research:ResearchedTechCount()
	local count = 0
	for field_id in pairs(self.tech_field or empty_table) do
		count = count + self:TechCount(field_id, "researched")
	end
	return count
end

GlobalVar("TechLastSeen", 0)

function Research:IsTechNew(tech_id)
	local status = self.tech_status[tech_id]
	local new_since = status and status.new
	if new_since == true then
		new_since = GameTime()
		status.new = new_since
	end
	return (new_since or 0) > TechLastSeen
end

function Research:SetTechNew(tech_id, is_new)
	local status = self.tech_status[tech_id]
	if not status then
		assert(false, "No such tech")
		return
	end
	status.new = is_new and GameTime() or nil
	return true
end

function Research:ModifyResearchPoints(research_points, tech_id)
	tech_id = tech_id or self.research_queue[1]
	if tech_id and not self:IsTechDiscoverable(tech_id) then
		research_points = MulDivRound(research_points, g_Consts.BreakthroughResearchSpeedMod, 100)
	else
		research_points = MulDivRound(research_points, g_Consts.ExperimentalResearchSpeedMod, 100)
	end
	return MulDivRound(research_points, 100 + OmegaTelescopeResearchBoostPercent(self), 100)
end

function Research:UnmodifyResearchPoints(research_points, tech_id)
	tech_id = tech_id or self.research_queue[1]
	research_points = MulDivRound(research_points, 100, 100 + OmegaTelescopeResearchBoostPercent(self))
	if tech_id and not self:IsTechDiscoverable(tech_id) then
		research_points = MulDivRound(research_points, 100, g_Consts.BreakthroughResearchSpeedMod)
	else
		research_points = MulDivRound(research_points, 100, g_Consts.ExperimentalResearchSpeedMod)
	end
	return research_points
end

function Research:GetCheapestTech()
	local field_ids = table.keys(self.tech_field)
	table.sort(field_ids, function(f1, f2) return TechFields[f1].SortKey < TechFields[f2].SortKey end)
	local cheapest_cost, cheapest_tech = max_int
	for _, field_id in ipairs(field_ids) do
		for _, tech_id in ipairs(self.tech_field[field_id]) do
			local status = self.tech_status[tech_id]
			if status and status.discovered and not status.researched then
				if not (self.tech_will_be_granted and self.tech_will_be_granted[tech_id]) then
					local cost = self:TechCost(tech_id)
					if cheapest_cost > cost then
						cheapest_cost = cost
						cheapest_tech = tech_id
					end
				end
			end
		end
	end
	return cheapest_tech
end

function Research:AddResearchPoints(research_points, tech_id)
	if research_points <= 0 then
		return
	end
	local current_research = self.research_queue[1]
	tech_id = tech_id or current_research or self:GetCheapestTech()
	if not tech_id then
		return
	end
	if not self:IsTechResearchable(tech_id) then
		assert(false, "Trying to add RP to a non-researchable tech!")
		return
	end
	local scale = const.ResearchPointsScale
	local available_points = self:ModifyResearchPoints(research_points * scale, tech_id)
	local status = self.tech_status[tech_id]
	if not status then
		assert(false, "No such tech!")
		return
	end
	local research_cost = self:TechCost(tech_id)
	assert(research_cost > 0)
	status.points = status.points + available_points
	local remaining_points = status.points - research_cost * scale
	if remaining_points < 0 then
		-- research isn't completed
		return
	end
	if not self:SetTechResearched(tech_id, "notify") then
		assert(false, "Tech research failed!?")
		return
	end
	research_points = self:UnmodifyResearchPoints(remaining_points, tech_id) / scale
	return self:AddResearchPoints(research_points)
end

function Research:CheckAvailableTech()
	if g_Tutorial and not g_Tutorial.EnableResearchWarning then
		return
	end
	if self.research_queue[1] then
		RemoveOnScreenNotification("ResearchAvailable")
		return
	elseif IsOnScreenNotificationShown("ResearchAvailable") then
		return
	end
	for field, techs in pairs(self.tech_field) do
		for i=1,#techs do
			if self:IsTechResearchable(techs[i]) then
				AddOnScreenNotification("ResearchAvailable", OpenResearchDialog)
				return
			end
		end
	end
end

--[[
- returns tech_id, points, max_points
--]]
function Research:GetResearchInfo(tech_id)
	tech_id = tech_id or self.research_queue[1]
	local status = tech_id and self.tech_status[tech_id]
	if not status then
		return false
	end
	return tech_id, status.points / const.ResearchPointsScale, self:TechCost(tech_id), status.researched
end

--[[
- returns percentage of current research
--]]
function Research:GetResearchProgress(tech_id)
	local tech_id, points, max_points = self:GetResearchInfo(tech_id)
	if not tech_id then return 0 end
	if max_points <= 0 then return 0 end
	return MulDivRound(100, points, max_points)
end

----

function Research:GetEstimatedRP_Outsource()
	local time = const.DayDuration
	if self.paused_outsource_research_end_time then
		time = Max(time - Max(self.paused_outsource_research_end_time - GameTime(), 0), 0)
	end
	return self:CalcOutsourceRP(time)
end

function Research:CalcOutsourceRP(time)
	time = time or const.DayDuration
	local hours = time / const.HourDuration
	local list = self.OutsourceResearchPoints
	local pts = 0
	for i=1,Min(hours, #list) do
		pts = pts + list[i]
	end
	return pts
end

function Research:OutsourceResearch(points, time, orders)
	points = points or 500
	time = time or 5*const.DayDuration
	local list = self.OutsourceResearchPoints
	local uses = self.OutsourceResearchOrders
	local hours = time / const.HourDuration
	for i = 1, hours do
		list[i] = (list[i] or 0) + points * i / hours - points * (i - 1) / hours
		uses[i] = (uses[i] or 0) + (orders or 1)
	end
	ObjModified(self)
end

function Research:GetEstimatedRP()
	local estimate = self:GetEstimatedRP_ResearchBuildings()
		+ self:GetEstimatedRP_Genius()
		+ self:GetEstimatedRP_Sponsor()
		+ self:GetEstimatedRP_Outsource()
		+ self:GetEstimatedRP_Explorer()
		+ self:GetEstimatedRP_SuperconductingComputing()
	return self:ModifyResearchPoints(estimate)
end

function Research:GetEstimatedRP_ResearchBuildings()
	local total = 0
	for _, city in ipairs(Cities) do
		for _, lab in ipairs(city.labels.ResearchBuildings or empty_table) do
		total = total + lab:GetEstimatedDailyProduction()
	end
	end
	return total
end

function Research:GetEstimatedRP_Genius()
	local count = 0
	for _, city in ipairs(Cities) do
		for _, dome in ipairs(city.labels.Dome or empty_table) do
		for __, col in ipairs(dome.labels.Genius or empty_table) do
			if col.stat_sanity >= g_Consts.HighStatLevel then
				count = count + 1
			end
		end
	end
	end
	return count * TraitPresets.Genius.param
end

function Research:GetEstimatedRP_Sponsor()
	local research = g_Consts.SponsorResearch
	if IsGameRuleActive("EasyResearch") then
		research = research + 3000
	end
	if self.paused_sponsor_research_end_time then
		local time_remaining = Max(self.paused_sponsor_research_end_time - GameTime(), 0)
		if time_remaining < const.DayDuration then
			local hours_remaining = time_remaining / const.HourDuration + 1
			research = MulDivRound(const.HoursPerDay-hours_remaining, research, const.HoursPerDay)
		else
			research = 0
		end
	end
	
	return research
end

function Research:GetEstimatedRP_SuperconductingComputing()
	if g_Consts.ElectricityForResearchPoint ~= 0 then
		local waste = 0
		for _, city in ipairs(Cities) do
			for i = 1, #city.electricity do
				waste = waste + city.electricity[i].current_waste
			end
		end
		local rp, rem = self:ElectricityToResearch(waste, const.HoursPerDay)
		return rp
	end
	return 0
end

function Research:CalcExplorerResearchPoints(dt, log)
	local total,rp = 0, 0
	if self:IsTechResearched("ExplorerAI") then
		local one_rover_rp = MulDivRound(g_Consts.ExplorerRoverResearchPoints, dt, const.DayDuration)
		local count = 0
		for _, city in ipairs(Cities) do
			for _, rover in ipairs(city.labels.ExplorerRover or empty_table) do
			if not ExplorerRover.StopResearchCommands[rover.command] then
				count = count + 1
				if log then
					rover:LogRP(one_rover_rp)
				end
			end
		end
		end
		rp = count * one_rover_rp
		total = rp
		if count > 1 then
			local collaboration = Min(g_Consts.MaxResearchCollaborationLoss, (count - 1) * 10)
			rp = MulDivRound(rp, 100 - collaboration, 100)
		end
	end
	return rp, total - rp
end

function Research:AddExplorerResearchPoints()
	local tech_id =  self.research_queue[1]
	if not tech_id or not self:IsTechResearchable(tech_id) then
		return 0
	end

	return self:CalcExplorerResearchPoints(const.HourDuration, "log")
end

function Research:GetEstimatedRP_Explorer()
	return self:CalcExplorerResearchPoints(const.DayDuration)
end

function Research:ElectricityToResearch(amount, hours)
	if g_Consts.ElectricityForResearchPoint <= 0 then
		return 0
	end
	
	local full_effect_threshold = 500 * const.ResourceScale
	local full_effect_amount = Min(full_effect_threshold, amount)
	local partial_effect_amount = Max(0, amount - full_effect_threshold)
	
	hours = hours or 1
	local rp, rem
	
	rp = MulDivRound(full_effect_amount, hours, g_Consts.ElectricityForResearchPoint)
	if partial_effect_amount > 0 then
		rp = rp + MulDivRound(partial_effect_amount, hours, 4 * g_Consts.ElectricityForResearchPoint)
		rem = partial_effect_amount % (4 * g_Consts.ElectricityForResearchPoint)
	else
		rem = full_effect_amount % g_Consts.ElectricityForResearchPoint
	end
	
	return rp, rem
end

function Research:UpdatePauseEndTimeProp(prop)
	if self[prop] then
		if GameTime() >= self[prop] then
			self[prop] = false
		end
	end
end

function Research:HourlyResearch(hour)
	local rp = 0 
	-- calculate with accumulation for precision, as RPs aren't scaled up
	if g_Consts.ElectricityForResearchPoint ~= 0 then
		for _, city in ipairs(Cities) do
			for i = 1, #city.electricity do
				self.wasted_electricity_for_rp = self.wasted_electricity_for_rp + city.electricity[i].current_waste 
			end
		end
		local pts, remainder = self:ElectricityToResearch(self.wasted_electricity_for_rp)
		rp = rp + pts
		self.wasted_electricity_for_rp = remainder
	end

	self:UpdatePauseEndTimeProp("paused_sponsor_research_end_time")
	if not self.paused_sponsor_research_end_time then
		rp = rp + self:CalcSponsorResearchPoints(const.HourDuration)
	end
	
	rp = rp + self:AddExplorerResearchPoints()

	self:UpdatePauseEndTimeProp("paused_outsource_research_end_time")
	local pts = self.OutsourceResearchPoints[1]
	if pts and not self.paused_outsource_research_end_time then
		table.remove(self.OutsourceResearchPoints, 1)
		table.remove(self.OutsourceResearchOrders, 1)
		rp = rp + pts
	end
	
	self:AddResearchPoints(rp)
end

function Research:CalcSponsorResearchPoints(delta)
	local research_per_sol = g_Consts.SponsorResearch
	if IsGameRuleActive("EasyResearch") then
		research_per_sol = research_per_sol + 3000
	end
	return MulDivRound(delta, research_per_sol, const.DayDuration)
end

function Research:GetUIResearchProject()
	local research = self:GetResearchInfo()
	if research then return TechDef[research].display_name end
	return T(7350, "<red>No active research</red>")
end

----

function OpenResearchDialog()
	OpenDialog("ResearchDlg")
end

function CloseResearchDialog()
	CloseDialog("ResearchDlg")
end

----

function Research:LoadMapStoredTechs()	
	--Blank (random) maps should not have prediscovered/preresearched techs (mantis:0130773)
	if ActiveMapData.IsRandomMap then
		return
	end
	
	local tech_state = ActiveMapData.TechState or ""
	for i=1,#tech_state,2 do
		local tech_id = tech_state[i]
		local tech_state = tech_state[i+1]
		if tech_state == "researched" then
			self:SetTechResearched(tech_id)
		elseif tech_state == "discovered" then
			self:SetTechDiscovered(tech_id)
		end
	end
end
function Research:SaveMapStoredTechs()	
	local tech_state
	for field_id, list in sorted_pairs(self.tech_field) do
		for i=1,#list do
			local tech_id = list[i]
			local status = self:IsTechResearched(tech_id) and "researched" or self:IsTechDiscovered(tech_id) and "discovered" or nil
			if status then
				tech_state = tech_state or {}
				tech_state[#tech_state + 1] = tech_id
				tech_state[#tech_state + 1] = status
			end
		end
	end
	assert(not (ActiveMapData.IsRandomMap and tech_state), "Blank (random) maps should not have prediscovered/preresearched techs") --(mantis:0130773)
	ActiveMapData.TechState = tech_state
end

----

function Research:UITechField(field_id)
	local field_def = TechFields[field_id]
	if not field_def or field_def.show_in_field ~= "" then
		return empty_table
	end
	local list = table.icopy(self.tech_field[field_id])
	if not list then return end
	-- link common lists
	for field_i, list_i in sorted_pairs(self.tech_field) do
		local tech_field = TechFields[field_i]
		if tech_field and tech_field.show_in_field == field_id then
			table.iappend(list, list_i)
		end
	end
	if not field_def.discoverable then
		-- hide not-yet-unlocked techs in the non-discoverable fields
		for i=#list,1,-1 do
			if not self:IsTechDiscovered(list[i]) then
				table.remove(list, i)
			end
		end
		local status = self.tech_status
		table.stable_sort(list, function(a, b) return (status[a].discovered or max_int) < (status[b].discovered or max_int) end)
	end
	return list
end

function ResearchDlgOnShortcut(self, shortcut, source)
	local f = self.desktop.keyboard_focus
	if f and f.FocusOrder and f.FocusOrder:x() == 0 and shortcut == "RightShoulder" then
		local log = self.desktop.focus_log
		for i = #log, 1, -1 do
			local win = log[i]
			if log[i]:IsKindOf("XTechControl") and win.FocusOrder and win.FocusOrder:x() < 1000 then
				win:SetFocus()
				return "break"
			end
		end
		local f = self:GetRelativeFocus(point(1, 1), "exact")
		if f then
			f:SetFocus()
		end
		return "break"
	end
	if shortcut == "LeftShoulder" then
		local f = self:GetRelativeFocus(point(0, 1), "exact")
		if f then
			f:SetFocus()
		end
		return "break"
	elseif shortcut == "Back" or shortcut == "TouchPadClick" then
		if DismissCurrentOnScreenHint() then
			return "break"
		end
	end
	return XDialog.OnShortcut(self, shortcut, source)
end

function ResearchUIPrioritizeQueue(research_item, delta)
	local parent = research_item.parent
	local tech_id = research_item.context.id
	local old_index, new_index = UIColony:PrioritizeQueueResearch(tech_id, delta, true)
	if new_index then
		local other_tech_id = UIColony.research_queue[old_index]
		parent:SwapItemAt(old_index, new_index)
		Msg("ResearchQueueSwap", UIColony, tech_id, other_tech_id)
		PlayFX("DequeueResearch", "start")
	else
		PlayFX("UIDisabledButtonPressed", "start")
	end
end

local gamepad_prioritize = T(13787, "<LeftTrigger> Prioritize research")
local gamepad_deprioritize = T(13788, "<RightTrigger> Deprioritize research")

function GetUIResearchQueueGamepadHint(research_queue_index)
	local hint = "<center>" .. T(3924, "<ButtonX> Remove from research queue")
	local research_queue_count = #UIColony.research_queue
	if research_queue_index < research_queue_count then
		hint = hint .. "<newline><center>" .. gamepad_deprioritize
	end
	if research_queue_index > 1 then
		hint = hint .."<newline><center>" .. gamepad_prioritize
	end
	return hint
end

----- XTechControl

DefineClass.XTechControl = {
	__parents = {"XContextControl"},
	RolloverDrawOnTop = true,
	RolloverOnFocus = true,
	MinWidth = 200,
	MaxWidth = 200,
	RolloverZoom = 1100,
	RolloverTemplate = "Rollover",
	FXMouseIn = "TechMouseIn",
	HandleMouse = false,
}

function XTechControl:Init(parent, tech)
	local research = UIColony
	self:SetFocusOrder(point(rawget(self.context, "field_pos") or 1, #parent))
	local tech_id = tech.id
	local icon = research:IsTechDiscovered(tech_id) and tech.icon
	local researched = research:IsTechResearched(tech_id) and not research:IsTechRepeatable(tech_id)
	local progress = research:GetResearchProgress(tech_id)
	local content = XWindow:new({
		Id = "idContent",
		HAlign = "center",
		VAlign = "center",
		Shape = "InHHex",
		HandleMouse = true,
	}, self)
	XImage:new({
		Id = "idIcon",
		Image = icon or "UI/Icons/Research/rm_unknown.tga",
		ImageFit = "smallest",
	}, content)
	
	local queue_win = XWindow:new({
		Id = "idQueueWin",
	}, content)
	XImage:new({
		Image = "UI/Icons/Research/rm_research_on.tga",
		ImageFit = "smallest",
	}, queue_win)
	local hex = XImage:new({
		HAlign = "right",
		VAlign = "bottom",
		Margins = box(0,0,26,4),
		ScaleModifier = point(1200,1200),
		Image = "UI/Icons/Research/rm_hex.tga",
		Columns = 2,
		Column = 2,
		IdNode = false,
	}, queue_win)
	XLabel:new({
		Id = "idQueueIndex",
		HAlign = "center",
		VAlign = "center",
		TextStyle = "Action",
		ScaleModifier = point(1200,1200),
	}, hex)

	if researched then
		XImage:new({
			Image = "UI/Icons/Research/rm_completed.tga",
			ImageFit = "smallest",
		}, content)
		XImage:new({
			Image = "UI/Icons/Research/rm_researched_2.tga",
			ImageFit = "smallest",
		}, content)
	elseif progress > 0 then
		local progress_info = XWindow:new({
			Id = "idProgressInfo"
		}, content)
		XImage:new({
			Image = "UI/Icons/Research/rm_partially_researched.tga",
			ImageFit = "smallest",
		}, progress_info)
		local percent_text = XText:new({
			Translate = true,
			HAlign = "center",
			VAlign = "center",
			TextHAlign = "center",
			TextVAlign = "center",
			Padding = box(0,0,0,0),
			HandleMouse = false,
			TextStyle = "ResearchPartialProgress",
		}, progress_info)
		percent_text:SetText(T{12562, "<percent(progress)>", progress = progress})

		local active_progress_info = XWindow:new({
			Id = "idProgressInfoActive"
		}, content)
		local active_percent_text = XText:new({
			Translate = true,
			HAlign = "center",
			VAlign = "center",
			TextHAlign = "center",
			TextVAlign = "center",
			Padding = box(0,0,0,0),
			HandleMouse = false,
			TextStyle = "ResearchQueuedProgress",
		}, active_progress_info)
		active_percent_text:SetText(T{12562, "<percent(progress)>", progress = progress})
	elseif research:IsTechDiscovered(tech_id) then
		XImage:new({
			Image = "UI/Icons/Research/rm_available.tga",
			ImageFit = "smallest",
		}, content)
	end
	
	XImage:new({
		Id = "idRollover",
		Image = "UI/Icons/Research/rm_shine.tga",
		Transparency = icon and 0 or 125,
		ImageFit = "smallest",
	}, content):SetVisible(false)
	if research:IsTechNew(tech_id) and research:IsTechDiscovered(tech_id) then
		local glow = XImage:new({
			Id = "idUnseenGlow",
			Image = "UI/Icons/Research/rm_shine.tga",
			ImageFit = "smallest",
		}, content)
		glow:AddInterpolation{
			type = const.intAlpha,
			startValue = 80,
			endValue = 255,
			duration = 1500,
			easing = const.Easing.SinInOut,
			flags = const.intfPingPong + const.intfLooping,
		}
	end
end

function XTechControl:OnShortcut(shortcut, source)
	local research = UIColony
	local tech_id = self.context.id
	if shortcut == "MouseL" or shortcut == "ButtonA" then -- add
		if research:QueueResearch(tech_id) then
			PlayFX("EnqueueResearch", "start")
		else
			PlayFX("UIDisabledButtonPressed", "start")
		end
		return "break"
	end
	if shortcut == "MouseR" or shortcut == "ButtonX" then -- remove
		if research:DequeueResearch(tech_id) then
			PlayFX("DequeueResearch", "start")
		else
			PlayFX("UIDisabledButtonPressed", "start")
		end
		return "break"
	end
	if shortcut == "Ctrl-MouseL" or shortcut == "RightTrigger-ButtonA" then -- add to queue start
		if not research:IsTechResearchable(tech_id) then
			PlayFX("UIDisabledButtonPressed", "start")
			return "break"
		end
		if research:TechQueueIndex(tech_id) and not research:IsTechRepeatable(tech_id) then
			research:DequeueResearch(tech_id)
		end
		if #research.research_queue > const.ResearchQueueSize then
			research:DequeueResearch(research.research_queue[#research.research_queue])
		end
		if research:QueueResearch(tech_id, true) then
			PlayFX("EnqueueResearch", "start")
		else
			PlayFX("UIDisabledButtonPressed", "start")
		end
		return "break"
	end
end

function XTechControl:OnSetRollover(rollover)
	if rollover and GetUIStyleGamepad() then
		-- XScrollArea
		local area = GetParentOfKind(self, "XScrollArea")
		if area then
			area:ScrollIntoView(self)
		end
	end
	XContextControl.OnSetRollover(self, rollover)
end

function XTechControl:OnContextUpdate(tech)
	local index = UIColony:TechQueueIndex(tech.id)
	self.idQueueWin:SetVisible(index)

	local progress_info = self:ResolveId("idProgressInfo")
	if progress_info then
		progress_info:SetVisible(not index)
	end

	local active_progress_info = self:ResolveId("idProgressInfoActive")	
	if active_progress_info then
		active_progress_info:SetVisible(index and index ~= 1)
	end

	if index then
		self.idQueueIndex:SetText(index)
	end
end

function XTechControl:CreateRolloverWindow(gamepad, context, pos)
	if rawget(self, "idUnseenGlow") then
		CreateRealTimeThread(function(self)
			Sleep(400)
			if RolloverControl == self then
				UIColony:SetTechNew(self.context.id, false)
				self.idUnseenGlow:SetVisible(false)
			end
		end, self)
	end
	return XContextControl.CreateRolloverWindow(self, gamepad, context, pos)
end

function XTechControl:GetRolloverTitle()
	local research = UIColony
	local tech_id = self.context.id
	if research:IsTechDiscovered(tech_id) then
		return T(3917, "<display_name> (<FieldDisplayName>)")
	else
		return T(3918, "Unknown Tech (<FieldDisplayName>)")
	end
end

function XTechControl:GetRolloverText()
	local research = UIColony
	local tech_id = self.context.id
	local discovered = research:IsTechDiscovered(tech_id)
	local researched = research:IsTechResearched(tech_id)

	if not discovered and not researched then
		return T(3919, "<FieldDescription><newline><newline>To unlock, research more technologies in this field or use the Explorer rover to analyze anomalies.")
	elseif researched and not research:IsTechRepeatable(tech_id) then
		return T(3920, "<description><newline><newline><em>Researched</em>")
	end
	local percent = (research.TechBoostPerTech[tech_id] or 0) + (research.TechBoostPerField[TechDef[tech_id].group] or 0)
	local percent_check = percent > 0
	return T{10980, "<description><newline><newline>Research cost<right><ResearchPoints(cost)><if(percent_check)><newline><left>Cost reduction<right><percent>%</if>", percent = percent, percent_check = percent_check }
end

local queue = T(12638, "<left><left_click> Queue for research<right><em>Ctrl+<left_click></em> Queue on top")
local dequeue = T(7775, "<right_click> Remove from research queue") 
local queue_dequeue = queue .. "<newline><center>" .. dequeue
local first_inqueue = T(8534, "<em>Ctrl+<left_click></em> Queue on top")
function XTechControl:GetRolloverHint()
	local research = UIColony
	local tech_id = self.context.id
	if research:IsTechResearchable(tech_id) then
		if not research:TechQueueIndex(tech_id) then
			return queue
		end
		if research:IsTechRepeatable(tech_id) then
			return queue_dequeue
		end
		return dequeue.."<newline><center>"..first_inqueue
	end
	return ""
end

local gamepad_queue = T(3925, "<left><ButtonA> Queue for research<right><RightTrigger><ButtonA> Queue on top")
local gamepad_dequeue = T(3924, "<ButtonX> Remove from research queue")
local gamepad_first_inqueue = T(8659, "<RightTrigger><ButtonA> Queue on top")
local gamepad_queue_dequeue = gamepad_queue .. "<newline><center>" .. gamepad_dequeue
local gamepad_dequeue_inqueue = gamepad_dequeue .. "<newline><center>" .. gamepad_first_inqueue

function XTechControl:GetRolloverHintGamepad()
	local research = UIColony
	local tech_id = self.context.id
	if research:IsTechResearchable(tech_id) then
		local index = research:TechQueueIndex(tech_id)
		if not index then
			return gamepad_queue
		end

		local hints = gamepad_prioritize

		if research:IsTechRepeatable(tech_id) then
			return gamepad_queue_dequeue
		else
			return gamepad_dequeue_inqueue
		end
	end
	return ""
end
