GlobalVar("g_ApplicantPool",{})
GlobalVar("g_ApplicantPoolFilter",{})
GlobalVar("g_LastGeneratedApplicantTime", false)

local drop_out_time = 1000*const.HourDuration
const.BuyApplicantsCount = 50


function GenerateApplicant(time, city)
	local colonist = GenerateColonistData(city, nil, nil, {no_specialization = IsGameRuleActive("Amateurs") or nil})
	local rand = Random(1, 100)
	if rand<=5 then
		MakeTourist(colonist)
	end	
	table.insert(g_ApplicantPool, 1, {colonist, time or GameTime()})
	return colonist
end

function GenerateApplicants(number, trait, specialization)
	assert(number)
	trait = trait ~= "" and trait or "random"
	specialization = specialization ~= "" and specialization or "any"
	local now = GameTime()
	for i=1,number do
		local colonist = GenerateApplicant(now)
		local to_add = trait
		if trait == "random_positive" then
			to_add = GetRandomTrait(colonist.traits, {}, {}, "Positive", "base")
		elseif trait == "random_negative" then
			to_add =  GetRandomTrait(colonist.traits, {}, {}, "Negative", "base")
		elseif trait == "random_rare" then
			to_add =  GetRandomTrait(colonist.traits, {}, {}, "Rare", "base")
		elseif trait == "random_common" then
			to_add =  GetRandomTrait(colonist.traits, {}, {}, "Common", "base")
		elseif trait == "random" then
			to_add = GenerateTraits(colonist, false, 1)
		else
			to_add = trait
		end
		if type(to_add) == "table" then
			for trait in pairs(to_add) do
				colonist.traits[trait] = true
			end
		elseif to_add then
			colonist.traits[to_add] = true
		end
		if specialization ~= "any" then
			colonist.traits[specialization] = true
			colonist.specialist = specialization
		end
	end
end

function MakeTourist(applicant)
	applicant.traits["Tourist"] = true
	applicant.traits["Safari"] = true
end

local function InitApplicantPoolFilter()
	ForEachPreset(TraitPreset, function(trait, group_list)
		if trait.initial_filter then
			g_ApplicantPoolFilter[trait.id] = TraitFilterState.Negative
		end
		if trait.initial_filter_up then
			g_ApplicantPoolFilter[trait.id] = TraitFilterState.Positive
		end	
	end)
end

function SavegameFixups.ResetApplicantPool()
	InitApplicantPoolFilter()
end

function SavegameFixups.FixupApplicantPool()
	for k,v in pairs(g_ApplicantPoolFilter) do
		if v == true then
			 g_ApplicantPoolFilter[k] = TraitFilterState.Positive
		elseif v == false then
			 g_ApplicantPoolFilter[k] = TraitFilterState.Negative
		end
	end
end

function InitApplicantPool()
	g_LastGeneratedApplicantTime = 0
	local pool_size = g_Consts.ApplicantsPoolStartingSize
	if IsGameRuleActive("MoreApplicants") then
		pool_size = pool_size + 500
	end
	for i=1,pool_size do
		GenerateApplicant(-Random(0, drop_out_time/2))
	end
	if IsGameRuleActive("MoreTourists") then
		for i=1,20 do
			local applicant = GenerateApplicant(-Random(0, drop_out_time/2))
			MakeTourist(applicant)
		end
	end
	
	InitApplicantPoolFilter()
end

function ClearApplicantPool()
	g_ApplicantPool = {}
end

function OnMsg.NewHour(hour)
	if not g_LastGeneratedApplicantTime then return end
	local now = GameTime()
	if hour == 3 then
		-- drop old applicants
		local drop_threshold = now - drop_out_time
		for i = #g_ApplicantPool, 1, -1 do
			local applicant, application_time = unpack_params(g_ApplicantPool[i])
			if application_time and application_time - drop_threshold < 0 then
				table.remove(g_ApplicantPool, i)
				if not applicant.traits.Tourist then
					GenerateApplicant(now)
				end
			end
		end
	end
	if (g_Consts.ApplicantSuspendGenerate or 0) > 0 then
		return
	end
	-- generate new one
	if now - g_LastGeneratedApplicantTime >= g_Consts.ApplicantGenerationInterval then
		local non_tourists = 0
		for _, data in ipairs(g_ApplicantPool) do
			local applicant = data[1]
			if not applicant.traits.Tourist then
				non_tourists = non_tourists + 1
			end
		end
		local pool_size = g_Consts.ApplicantsPoolStartingSize
		if IsGameRuleActive("MoreApplicants") then
			pool_size = pool_size + 500
		end
		if non_tourists < pool_size then
			GenerateApplicant(now)
			g_LastGeneratedApplicantTime = now
		end
	end
end


