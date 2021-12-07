DefineClass.Asteroids = {
}

function Asteroids:Init()
end

DefineClass.Colony = {
	__parents = { "UpgradeUnlocks", "Discoveries", "MiniMysteries", "Mysteries", "Challenges", "Research", "Asteroids" },

	day = 1, -- start the game at sol 1
	hour = 6, -- start the game at 6am so the solar panels are immediatelly working
	minute = 0,
	
	city_labels = false,
	funds = false,
	planetary_anomalies = false,
	construction_cost = false,
	compound_effects = false,
	deposit_depth_exploitation_research_bonus = 0,
	
	map_seed = false,
	surface_map_id = false,
	underground_map_id = false,
	underground_map_unlocked = false,
	underground_map_revealed = false,
}

function Colony.new(class, obj)
	local colony = setmetatable(obj or {}, class)
	colony.funds = Funding:new()
	colony.city_labels = LabelContainer:new()
	colony.planetary_anomalies = PlanetaryAnomalies:new()
	colony.construction_cost = ConstructionCost:new()
	colony.compound_effects = {}
	Asteroids.Init(colony)
	Discoveries.Init(colony)
	return colony
end

function Colony:Init()
	local gen = GetRandomMapGenerator()
	self.map_seed = gen and gen.Seed or AsyncRand()

	UpgradeUnlocks.Init(self)

	-- call early mod effects init
	for _, effects in ipairs(ModGlobalEffects) do
		effects:EffectsInit(self)
	end

	local sponsor = GetMissionSponsor()
	sponsor:EffectsInit(self)
	GetCommanderProfile():EffectsInit(self)
	local rules = GetActiveGameRules()
	for _, rule_id in ipairs(rules) do
		local rule = GameRulesMap[rule_id]
		assert(rule)
		if rule then
			rule:EffectsInit(self)
		end
	end

	self:SelectMystery() -- should be before research - research items depend on the current mystery
	self:InitResearch()

	self.city_labels:AddToLabel("Consts", g_Consts)

	local init_funding = GetSponsorModifiedFunding(sponsor.funding, empty_table)
	self.funds:ChangeFunding(init_funding*1000000 - g_CargoCost, "Sponsor")

	--lock mystery resource depot from the build menu
	LockBuilding("StorageMysteryResource")
	LockBuilding("MechanizedDepotMysteryResource")
	LockBuilding("TradePad")

	self.surface_map_id = ActiveMapID

	CreateGameTimeThread(function(self)
		self:GameInitResearch()
		self.tech_will_be_granted = {}
		GetCommanderProfile():EffectsGatherTech(self.tech_will_be_granted)
		self:InitMysteries()
		self.tech_will_be_granted = false

		self:CheckAvailableTech()
	end, self)
end

GlobalVar("SessionRandom", false)
function OnMsg.NewGame()
	g_SessionSeed = g_SessionSeed or AsyncRand()
	g_InitialSessionSeed = g_SessionSeed
	SessionRandom = GameRandom:new(nil, g_SessionSeed)
end

GlobalVar("UIColony", false)
function OnMsg.NewGame()
	if not ActiveMapData.GameLogic then return end
	UIColony = Colony:new()
	UIColony:Init()
end

function OnMsg.PostNewGame()
	if UIColony then
		UIColony:LoadMapStoredTechs()
	end
end
function OnMsg.SaveMap()
	if UIColony then
		UIColony:SaveMapStoredTechs()
	end
end

function SavegameFixups.AddColony()
	SessionRandom = GameRandom:new()
	SessionRandom:CopyMove(UICity)
	
	UIColony = Colony:new()
	UIColony.surface_map_id = ActiveMapID

	local gen = GetRandomMapGenerator()
	UIColony.map_seed = gen and gen.Seed or AsyncRand()

	UICity.colony = UIColony

	UpgradeUnlocks.CopyMove(UIColony, UICity)
	Mysteries.CopyMove(UIColony, UICity)
	Mysteries.FixMystery(UIColony)
	Research.CopyMove(UIColony, UICity)
	Challenges.CopyMove(UIColony, UICity)

	UIColony.funds:CopyMove(UICity)
	UIColony.planetary_anomalies:CopyMove(UICity)
	UIColony.construction_cost:CopyMove(UICity)
	UIColony.city_labels = LabelContainer:new()
	UIColony.city_labels:Copy(UICity)
	-- Limited save game compatibility for label modifiers.
	-- Transfer all to colony and forward updates from city to colony.
	UICity.label_modifiers = {}

	CopyMoveClassFields(UICity, UIColony,
	{
		"compound_effects",
		"deposit_depth_exploitation_research_bonus",
	})

	Research.ForwardCalls(UICity, UIColony)
	Funding.ForwardCalls(UICity, UIColony.funds)
end

function SavegameFixups.AddColony2()
	UIColony.day = UICity.day
	UIColony.hour = UICity.hour
	UIColony.minute = UICity.minute
end

function SavegameFixups.AddColonyDev3()
	UIColony.underground_map_revealed = false
	if UIColony.underground_map_id == ActiveMapID then
		UpdateRevealDarkness(UIColony.underground_map_id)
	end
end

function Colony:DailyUpdate(day)
	self.planetary_anomalies:UpdatePlanetaryAnomalies(day)

	self.funds:UpdateFunding()
end

function Colony:HourlyUpdate(hour)
	self:HourlyResearch(hour)
end

function OnMsg.NewMinute(minute)
	if UIColony then
		UIColony.minute = minute
		MainCity.minute = minute
	end
end

function OnMsg.NewHour(hour)
	if UIColony then
		UIColony.hour = hour
		MainCity.hour = hour
		UIColony:HourlyUpdate(hour)
	end
end

function OnMsg.NewDay(day)
	if UIColony then
		UIColony.day = day
		MainCity.day = day
		UIColony:DailyUpdate(day)
	end
end

function TimeToDayHour(time)
	time = time / const.HourDuration + Colony.hour -- time is in sol hours now
	return Colony.day + time / const.HoursPerDay, time
end

function GetTimeOfDay()
	if UIColony then
		return UIColony.hour, UIColony.minute
	end
	return 0, 0
end

function Colony:CreateSessionRand(...)
	return CreateRand(false, g_SessionSeed, ...)
end

function Colony:CreateMapRand(...)
	return CreateRand(true, self.map_seed, ...)
end

function Colony:CreateResearchRand(...)
	if IsGameRuleActive("ChaosTheory") then
		return AsyncRand
	elseif IsGameRuleActive("TechVariety") then
		return self:CreateSessionRand(...)
	else
		return self:CreateMapRand(...)
	end
end

function Colony:GrantTechFromProperties(source)
	for i=1, 5 do
		local tech_name = source["tech"..i]
		if tech_name and tech_name ~= "" then
			self:SetTechResearched(tech_name)
		end
	end
end

function Colony:ChangeGlobalConsts()
	-- directly modify global consts (from sponsor
	local sponsor = GetMissionSponsor()
	for _, mod_const in ipairs(directlyModifiableConsts) do
		local mod_id = mod_const.local_id
		local global_const = mod_const.global_id
		if sponsor:HasMember(mod_id) then
			SetGlobalConst(global_const, sponsor[mod_id])
		end
	end
	
	-- modify global consts with labels (from commander)
	local commander = GetCommanderProfile()
	for _, mod_const in ipairs(modifiableConsts) do
		local mod_id = mod_const.local_id
		local global_const = mod_const.global_id
		local lower_bound = g_Consts[global_const] < g_Consts["base_"..global_const] and - g_Consts[global_const] or - g_Consts["base_"..global_const]
		local mod_amount = commander[mod_id] > lower_bound and commander[mod_id] or lower_bound
		if commander:HasMember(mod_id) then
			local scale = ModifiablePropScale[global_const]
			if not scale then
				assert(false, print_format("Trying to modify a non-modifiable property", "Consts", "-", global_const))
				return
			end
			local tech_mod = {Label = "Const", Amount = mod_amount, Prop = global_const}
			self.city_labels:SetLabelModifier("Consts", tech_mod, Modifier:new{
				prop = global_const,
				amount = mod_amount,
				percent = 0,
				id = commander:HasMember("GetIdentifier") and commander:GetIdentifier() or commander.id,
			})
		end
	end
end

function SetGlobalConst(global_const, amount)
	local scale = ModifiablePropScale[global_const]
	if not scale then
		assert(false, print_format("Trying to modify a non-modifiable property", "Consts", "-", global_const))
		return
	end
	g_Consts[global_const] = amount
end

function Colony:ApplyModificationsFromProperties()
	local sponsor = GetMissionSponsor()
	self:GrantTechFromProperties(sponsor)
	
	local commander = GetCommanderProfile()
	self:GrantTechFromProperties(commander)
end

function Colony:InitMissionBonuses()
	local sponsor = GetMissionSponsor()
	--Initial cargo capacity (funding is set in City:Init)
	g_Consts:SetBase("CargoCapacity", sponsor.cargo)
	self:ChangeGlobalConsts()
	
	CreateGameTimeThread( function()
		while true do
			local period = Max(const.HourDuration, g_Consts.SponsorFundingInterval or const.DayDuration)
			local amount = g_Consts.SponsorFundingPerInterval * 1000000
			Sleep(period)
			if amount > 0 then
				amount = self.funds:ChangeFunding( amount, "Sponsor" )
				AddOnScreenNotification( "PeriodicFunding", nil, { sponsor = sponsor.display_name or "", number = amount } )
			end
		end
	end )
end

GlobalVar("SponsorGoalProgress", {}) -- goal_id, target, progress, state, GetTargetText, GetProgressText

function AreAllSponsorGoalsCompleted()
	for _, goal_res in ipairs(SponsorGoalProgress) do
		local state = goal_res.state
		if not state or state == "fail" then
			return false
		end
	end
	return true
end

local function MissionGoalUpdate(sponsor, goal, i)
	local progress = SponsorGoalProgress[i]
	local param1 = sponsor:GetProperty(string.format("goal_%d_param_1", i))
	local param2 = sponsor:GetProperty(string.format("goal_%d_param_2", i))
	local param3 = sponsor:GetProperty(string.format("goal_%d_param_3", i))
	local res = goal:Completed(progress, param1, param2, param3, i)

	progress.state = res and GameTime() or "fail"
	if res then
		progress.progress = progress.target
		param1 = ConvertParam(param1)
		param2 = ConvertParam(param2, type(param1)=="number" and param1>0)
		param3 = ConvertParam(param3, type(param2)=="number" and param2>0)
		local context = {param1 = param1, param2 = param2, param3 = param3}
		local reward = sponsor:GetProperty("reward_effect_"..i)
		reward:Execute(MainMapID)
		AddOnScreenNotification("GoalCompleted", OpenMissionProfileDlg, {reward_description = T{reward.Description, reward}, context = context, rollover_title = T(4773, "<em>Goal:</em> "), rollover_text = goal.description})
		Msg("GoalComplete", goal)
		if AreAllSponsorGoalsCompleted() then
			Msg("MissionEvaluationDone")
		end
		return 
	end
end

function SetupMissionGoals()
	local sponsor = GetMissionSponsor()
	for i = 1, g_Consts.SponsorGoalsCount do
		local id = sponsor:GetProperty("sponsor_goal_"..i)
		if id then
			SponsorGoalProgress[i] = {goal_id = id, state = false, GetTargetText = function(self) return self.target or "" end, GetProgressText = function(self) return self.progress or "" end}
			local goal = Presets.SponsorGoals.Default[id]
			CreateGameTimeThread(MissionGoalUpdate, sponsor, goal, i)
		end
	end
end

GlobalVar("g_InitialRocketCargo", false)
GlobalVar("g_InitialCargoCost", 0)
GlobalVar("g_InitialCargoWeight", 0)
GlobalVar("g_InitialSessionSeed", false)

function Colony:GameStart(city)
	if g_RocketCargo then
		g_InitialRocketCargo = table.copy(g_RocketCargo, "deep")
		g_InitialCargoCost = g_CargoCost
		g_InitialCargoWeight = g_CargoWeight
		city:AddResupplyItems(g_RocketCargo)
		ResetCargo()
	else
		ApplyResupplyPreset(city, "Start_medium")
	end

	local sponsor = GetMissionSponsor()

	CreateGameTimeThread(function(city, colony)
		if not g_Tutorial or g_Tutorial.EnableRockets then
			city:CreateSupplyShips()
			local cargo = city.queued_resupply
			city.queued_resupply = {}
			Sleep(1) -- wait for rocket GameInits
			assert(city.labels.SupplyRocket and #city.labels.SupplyRocket > 0)
			cargo.rocket_name = g_CurrentMapParams.rocket_name
			MarkNameAsUsed("Rocket",g_CurrentMapParams.rocket_name_base) 
			city:OrderLanding(cargo, 0, true)
		else
			-- cleanup saved rockets
			local rockets = city.labels.SupplyRocket or empty_table
			
			for i = #rockets, 1, -1 do
				if rockets[i]:GetPos() == InvalidPos() then
					DoneObject(rockets[i])
				end
			end
		end

		sponsor:game_apply(city)
		GetCommanderProfile():game_apply(city)

		-- apply mod effects
		for _, effects in ipairs(ModGlobalEffects) do
			effects:EffectsApply(colony)
		end
		GetMissionSponsor():EffectsApply(colony)
		GetCommanderProfile():EffectsApply(colony)
		local rules = GetActiveGameRules()
		for _, rule_id in ipairs(rules) do
			local rule = GameRulesMap[rule_id]
			if rule then
				rule:EffectsApply(colony)
			end
		end
		InitApplicantPool()
		colony:ApplyModificationsFromProperties()
	end, city, self)
	
	--mission related
	self:InitMissionBonuses()
	
	if not g_Tutorial and ActiveMapID ~= "Mod" then
		SetupMissionGoals()
		self:StartChallenge()
	end
end

function OnMsg.CityStart(city)
	UIColony:GameStart(city)
end

function OnMsg.LoadGame()
	local rules = GetActiveGameRules()
	for _, rule_id in ipairs(rules) do
		local rule = GameRulesMap[rule_id]
		if rule then
			rule:EffectsLoad(UIColony)
		end
	end
end

function Colony:ForEachLabelObject(label, func, ...)
	self.city_labels:ForEachLabelObject(label, func, ...)
end

function Colony:GetCityLabels(label)
	return self.city_labels.labels[label] or empty_table
end

function Colony:GetActiveColonyMaps()
	return empty_table
end

function Colony:IsActiveColonyMap(map_id)
	return true
end

function Colony:IncrementDepositDepthExploitationLevel(amount)
	self.deposit_depth_exploitation_research_bonus = self.deposit_depth_exploitation_research_bonus + amount
end

function Colony:GetMaxSubsurfaceExploitationLayer()
	return 1 + self.deposit_depth_exploitation_research_bonus
end

function Colony:CountBuildings(label)
	local total = 0
	for _, city in ipairs(Cities) do
		total = total + city:CountBuildings(label)
	end
	return total
end

function Colony:GetWorkshopWorkersPercent()
	local colonists = self:GetCityLabels("Colonist") or empty_table
	local workshops = self:GetCityLabels("Workshop") or empty_table
	if #colonists==0 or #workshops==0 then 
		return 0 
	end
	local workers= 0
	for _, workshop in ipairs(workshops) do
		if workshop.working then
			for i=1, workshop.max_shifts do
				workers = workers + #workshop.workers[i]				
			end
		end
	end
	if workers==0 then 
		return 0 
	end
	local col_count = 0
	for _, colonist in ipairs(colonists) do
		if colonist:CanWork() then
			col_count = col_count + 1
		end
	end
	if col_count==0 then 
		return 0 
	end
	return MulDivRound(workers, 100, col_count)
end

function OnMsg.TechResearched(tech_id, research, first_time)
	if not first_time then
		return
	end
	local sponsor = GetMissionSponsor()
	if not research:IsTechDiscoverable(tech_id) then
		UIColony.funds:ChangeFunding( sponsor.funding_per_breakthrough*1000000, "Sponsor" )
		local now = GameTime()
		for i=1,sponsor.applicants_per_breakthrough do
			GenerateApplicant(now, MainCity)
		end
	else
		UIColony.funds:ChangeFunding( sponsor.funding_per_tech*1000000, "Sponsor"  )
	end
end

-------------- speed buttons
local last_speed = 1
function Colony:SetGameSpeed(factor)
	local current_factor = GetTimeFactor() / const.DefaultTimeFactor
	if factor and factor < current_factor  then
		PlayFX(factor == 0 and "GamePause" or "GameSpeedDown", "start")
	elseif not factor or (factor and factor > current_factor) then
		if current_factor == 0 then
			PlayFX("GamePause", "end")
		else
			PlayFX("GameSpeedUp", "start")
		end
	end
	factor = factor or last_speed
	if factor ~= current_factor then
		if factor == 0 then
			Msg("MarsPause")
		elseif current_factor == 0 and factor > current_factor then
			Msg("MarsResume")
		end
	end
	if factor > 0 then last_speed = factor end
	MainCity:Gossip("GameSpeed", factor)
	SetTimeFactor(const.DefaultTimeFactor * factor, true)
	HUDUpdateTimeButtons()
	
	HintDisable("HintGameSpeed")
end

function Colony:GetMapDisplayName(map_id)
	return T(1233, "Mars")
end

function GetMapDisplayName(map_id)
	return UIColony:GetMapDisplayName(map_id)
end
