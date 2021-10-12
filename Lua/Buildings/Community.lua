BirthPolicy = {
	Forbidden = 0,
	Enabled = 1,
	Limited = 2,
	MAX = 3,
}

DefineClass.Community = {
	__parents = { "Workforce" },

	accept_colonists = true,
	overpopulated = false, -- set when homeless are added and the amount of homeless goes over a specific limit

	traits_filter = false,

	free_spaces = false,

	birth_policy = BirthPolicy.Enabled,
	next_birth_check_time = 0,
	birth_progress = 0,
	daily_birth_progress = 0,
	fertile_male = 0,
	fertile_female = 0,
	born_children = 0,
}

function Community:Init()
	Workforce.Init(self)

	self:InitEmptyLabel("Colonist")

	self.birth_progress = g_Consts.BirthThreshold / 2
	self.traits_filter = {}
end

function Community:GameInit()
	self.city:AddToLabel("Community", self)
end

function Community:Done()
	self.city:RemoveFromLabel("Community", self)
end

function SavegameFixups.AddCommunitiesToLabel()
	MapForEach("map", "Community", function(bld)
		bld.city:AddToLabel("Community", bld)
	end)
end

function Community:GetAverageHealth() return GetAverageStat(self.labels.Colonist, "Health") end
function Community:GetAverageSanity() return GetAverageStat(self.labels.Colonist, "Sanity") end
function Community:GetAverageComfort() return GetAverageStat(self.labels.Colonist, "Comfort") end
function Community:GetAverageMorale() return GetAverageStat(self.labels.Colonist, "Morale") end
function Community:GetAverageSatisfaction() return GetAverageStat(self.labels.Colonist, "Satisfaction") end

function Community:GetMoraleBonus()
	return 0
end

function Community:GetDamageDecrease()
	return 0
end

function Community:CyclePolicy(policy_member, broadcast, max)
	if not self:GetUIInteractionState() then 
		return
	end	
	
	local state = self[policy_member] + 1
	if state >= max then
		state = 0
	end
	self:SetPolicyState(policy_member, broadcast, state)
end

function Community:TogglePolicy(policy_member, broadcast)
	if not self:GetUIInteractionState() then 
		return
	end	
	local state = not self[policy_member]
	self:SetPolicyState(policy_member, broadcast, state)
end

function Community:SetPolicyState(policy_member, broadcast, state)
	if broadcast then
		local list = self.city.labels.Community or empty_table
		for _, community in ipairs(list) do
			if community[policy_member] ~= state and self:GetUIInteractionState() then
				PlayFX("DomeAcceptColonistsChanged", "start", community)
				community[policy_member] = state
				ObjModified(community)
			end
		end
	else
		PlayFX("DomeAcceptColonistsChanged", "start", self)
		self[policy_member] = state
		ObjModified(self)
	end
end

function Community:ToggleAcceptColonists(broadcast)
	self:TogglePolicy("accept_colonists", broadcast)
end

function Community:CycleBirthPolicy(broadcast)
	self:CyclePolicy("birth_policy", broadcast, BirthPolicy.MAX)
end

local daily_birth_checks = 6
function Community:BuildingUpdate()
	local now = GameTime()
	
	if now > self.next_birth_check_time then
		self:CalcBirth()
		self.next_birth_check_time = self.next_birth_check_time + const.DayDuration / daily_birth_checks
	end
end

local stat_scale = const.Scale.Stat
local birth_comfort_cap = 150*stat_scale

local function CheckFertility(c, min_comfort_birth) 
	local traits = c.traits
	if
		c.stat_comfort > min_comfort_birth
		and not c:IsDying() 
		and not traits.Child
		and not traits.Android
		and (not traits.Senior or g_SeniorsCanWork)
		and not traits.OtherGender
	then
		return true
	end
end

local function CalcFertility(c)
	local comfort = c.stat_comfort
	return comfort + Min(birth_comfort_cap, c.birth_comfort_modifier), comfort
end

function Community:OnColonistSpawned(colonist)
end

function Community:OnColonistRested(colonist)
end

function Community:SpawnChild(dreamer_chance)
	local colonist = GenerateColonistData(self.city, "Child", "martianborn")
	colonist.dome = self
	if IsDreamMystery() then
		assert(self.labels.Colonist)
		local rand = self:Random(100)
		if rand < dreamer_chance then
			if self.city.colony.mystery.state == "ended" then
				colonist.traits["DreamerPosMystery"] = true
			else
				colonist.traits["Dreamer"] = true
			end
		end
	end
	Colonist:new(colonist, self:GetMapID())
	self:OnColonistSpawned(colonist)
	self.born_children = self.born_children + 1
	g_TotalChildrenBornWithMating = g_TotalChildrenBornWithMating + 1
	Msg("ColonistBorn", colonist, "born")
	return colonist
end

function Community:GetMinComfortBirth()
	return g_Consts.MinComfortBirth
end

function Community:GetBirthRatePenalty()
	return 0
end

function Community:CalcBirth()
	if self.birth_policy == BirthPolicy.Forbidden or self.birth_policy == BirthPolicy.Limited and self:GetFreeLivingSpace(true) == 0 then
		return
	end
	
	local min_comfort_birth = self:GetMinComfortBirth()

	local males = self.labels.Male or empty_table
	local females = self.labels.Female or empty_table

	-- find couples	
	local num_male_fertile = 0
	local fertile_male = {}
	for _, colonist in ipairs(males) do
		if CheckFertility(colonist, min_comfort_birth) then
			fertile_male[#fertile_male + 1] = colonist
		end
	end
	
	local num_female_fertile = 0
	local fertile_female = {}
	for _, colonist in ipairs(females) do
		if CheckFertility(colonist, min_comfort_birth) then
			fertile_female[#fertile_female + 1] = colonist
		end
	end
	
	self.fertile_male = #fertile_male
	self.fertile_female = #fertile_female
	
	local couples_count = Min(#fertile_male, #fertile_female)
	
	if couples_count == 0 then 
		self.daily_birth_progress = 0
		RebuildInfopanel(self)
		return false 
	end
	
	if #fertile_male < #fertile_female then
		table.sortby_field_descending(fertile_female, "stat_comfort")
	else
		table.sortby_field_descending(fertile_male, "stat_comfort")
	end
	
	local total_fertility, dreamers = 0, 0
	local function add_group(group)
		for i = 1, couples_count do
			local colonist = group[i]
			local fertility, comfort = CalcFertility(colonist)
			total_fertility = total_fertility + fertility
			local traits = colonist.traits
			if traits.Dreamer or traits.DreamerPostMystery then
				dreamers = dreamers + 1
			end
		end
	end
	add_group(fertile_male)
	add_group(fertile_female)
	
	local avg_fertility = total_fertility / (2*couples_count)
	local birth_progress = Max(0, couples_count * (avg_fertility - 30*stat_scale)) -- daily
	birth_progress = MulDivRound(birth_progress, 100 - self:GetBirthRatePenalty(), 100)
	
	self.daily_birth_progress = birth_progress
	self.birth_progress = self.birth_progress + birth_progress / daily_birth_checks
	
	while self.birth_progress >= g_Consts.BirthThreshold do
		self.birth_progress = self.birth_progress - g_Consts.BirthThreshold 
		CreateGameTimeThread(function(self)
			Sleep(1000+self:Random(self.building_update_time-1000))
			if not IsValid(self) then
				return
			end
			self:SpawnChild(dreamers * 100 / (2*couples_count))
		end, self)
	end
	RebuildInfopanel(self)
end

function Community:CheatSpawnChild()
	self:SpawnChild(10)
end

function Community:GetBirthTextLines()
	return {
		T(559, "<newline><center><em>Births</em>"),
		T{7701, "Birth Threshold<right><resource(MinComfortBirth, Comfort)> Comfort", self},
		T{560, "Males who want children<right><colonist(fertile_male)>", self},
		T{561, "Females who want children<right><colonist(fertile_female)>", self},
		T{562, "Children born<right><colonist(born_children)>", self},
	}
end

function Community:GetBirthStatusText()
	local status = false
	if self.daily_birth_progress <= 0 then
		status = T(563, "<red>No children will be born. The average Comfort of all fertile couples is too low.</red>")
	elseif self.birth_policy ~= BirthPolicy.Forbidden then
		status = T(13598, "<green>Children will be born. The inhabitants are comfortable enough.</green>")
	else
		status = T(8738, "<green>Children will be born if births are allowed.</green>")
	end
end

function Community:GetBirthDomeStatusText()
	if self:GetFreeLivingSpace(true) > 0 then
		return T(13740, "Current status: <em>Births are allowed (Free living space available)</em>")
	else
		return T(13758, "Current status: <em>Births are forbidden (Dome is full)</em>")
	end
end

function Community:GetBirthText()
	local texts = self:GetBirthTextLines()
	local status = self:GetBirthStatusText()
	if status then
		texts[#texts + 1] = status
	end
	return table.concat(texts, "<newline><left>")
end

GlobalVar("DomeTraitsCameraParams", false)

function Community:OpenFilterTraits(category)
	local camera = DomeTraitsCameraParams or {GetCamera()}
	DomeTraitsCameraParams = false
	CloseDialog("DomeTraits")
	local dlg = OpenDialog("DomeTraits", nil, {category = category, dome = self, filter = self.traits_filter, colonists = self.labels.Colonist})
	if category and type(category) == "string" then
		local prop_meta = table.find_value(dlg.context:GetProperties(), "id", category)
		if prop_meta then
			SetDialogMode(dlg, "items", prop_meta)
		end
	end
	self.accept_colonists = true
	DomeTraitsCameraParams = camera
end

function Community:ResetFreeSpace()
	self.free_spaces = nil
end

function Community:RefreshFreeLivingSpaces()
	self.free_spaces = empty_table
end

function Community:GetFreeLivingSpace(count_all)
	if not self.free_spaces then
		self:RefreshFreeLivingSpaces()
	end

	if count_all then
		return self.free_spaces.inclusive
	else
		return self.free_spaces.exclusive
	end
end

function Community:HasFreeLivingSpaceFor(traits)
	if not self.free_spaces then
		self:RefreshFreeLivingSpaces()
	end

	if self.free_spaces.exclusive > 0 then
		return true
	elseif self.free_spaces.inclusive > 0 then
		for trait, space in pairs(self.free_spaces.traits) do
			if traits[trait] and space > 0 then
				return true
			end
		end
	end
	return false
end

function Community:CanVisit()
	return not self.destroyed and not self.demolishing
end

function Community:ApplyTraitsFilter()
	local traits_filter = self.traits_filter
	for _, colonist in ipairs(self.labels.Colonist) do
		-- Assume other communities could score higher
		if TraitFilterColonist(traits_filter, colonist.traits) <= 0 then
			colonist:InterruptCommand()
		end
	end
end

function Community:GetScoreFor(traits)
	-- life support is leading as previously this was exluding communities.
	local score = 0
	if self:HasLifeSupport() then
		score = 100
	end

	score = score + TraitFilterColonist(self.traits_filter, traits)
	return score
end

function Community:HasLifeSupport()
	return self:HasWater() and (GetAtmosphereBreathable(self:GetMapID()) or (self:HasPower() and self:HasAir()))
end

function Community:CheckConditionsAll()
	local t = GameTime()
	for _, colonist in ipairs(self.labels.Colonist or empty_table) do
		if not colonist.outside_start then
			self:CheckConditions(colonist, t)
		end
	end
end

function Community:CheckConditions(colonist, t)
	local map_id = self:GetMapID()
	colonist:Affect("StatusEffect_Dehydrated", not self:HasWater(), t)	
	colonist:Affect("StatusEffect_Suffocating", not GetAtmosphereBreathable(map_id) and not self:HasAir(), t)
	colonist:Affect("StatusEffect_Freezing", not GetAtmosphereBreathable(map_id) and not self:HasPower(), t)
end

function Community:GetRandomPos()
	return InvalidPos()
end

function Community:RandPlaceColonist(colonist)
	colonist:SetPos(self:GetPos())
end

function Community:GetService(need, colonist, starving)
	return false
end

function Community:ChooseResidence(colonist)
	return false
end

function Community:GetMoraleModifiers()
	local morale_modifiers = {}
	return morale_modifiers
end

function SavegameFixups.SetBirthPolicy()
	for _,community in ipairs(UIColony.city_labels.labels.Community or empty_table) do
		local value = rawget(community, "allow_birth")
		if value == false then
			community.birth_policy = BirthPolicy.Forbidden
		elseif value == true then
			community.birth_policy = BirthPolicy.Enabled
		end
	end
end

function SavegameFixups.ExtendedTraitsFilter()
	for _,community in ipairs(UIColony.city_labels.labels.Community or empty_table) do
		for key,value in pairs(community.traits_filter) do
			community.traits_filter[key] = value and TraitFilterState.Positive or TraitFilterState.Negative
		end
	end	
end