HolidayRating = {
	rewards = {
		{money = 2000000, fixed_applicants = 0, bonus_applicants = 1, bonus_chance = 40, star_rating = 1},
		{money = 7000000, fixed_applicants = 0, bonus_applicants = 1, bonus_chance = 80, star_rating = 2},
		{money = 13000000, fixed_applicants = 1, bonus_applicants = 1, bonus_chance = 25, star_rating = 3},
		{money = 22000000, fixed_applicants = 1, bonus_applicants = 1, bonus_chance = 50, star_rating = 3.5},
		{money = 30000000, fixed_applicants = 1, bonus_applicants = 1, bonus_chance = 75, star_rating = 4},
		{money = 35000000, fixed_applicants = 2, bonus_applicants = 0, bonus_chance = 0, star_rating = 4.5},
		{money = 38000000, fixed_applicants = 2, bonus_applicants = 1, bonus_chance = 50, star_rating = 5}
	}
}

function HolidayRating:ApplyRewards(colonists)
	local total_money_reward = 0
	local total_applicant_reward = 0
	
	for i=1, #colonists or empty_table do
		if colonists[i].traits.Tourist then
			local rating = self:GetRating(colonists[i])
			total_money_reward = total_money_reward + self:RewardMoney(rating, colonists[i])
			total_applicant_reward = total_applicant_reward + self:RewardApplicants(rating, colonists[i])
			self:RewardResearch(colonists[i])
		end
	end
	return total_money_reward, total_applicant_reward
end

function HolidayRating:GetRating(tourist)
	local satisfaction = tourist:GetSatisfaction()
	local rating = 1
	if satisfaction < 5 then rating = 1				-- 1 stars	(0-5)
	elseif satisfaction < 20 then rating = 2			-- 2 stars	(6-20)
	elseif satisfaction < 40 then rating = 3			-- 3 stars	(21-40)
	elseif satisfaction < 60 then rating = 4			-- 3.5 stars	(41-60)
	elseif satisfaction < 80 then rating = 5			-- 4 stars	(61-80)
	elseif satisfaction < 100 then rating = 6			-- 4.5 stars	(81-99)
	elseif satisfaction >= 100 then rating = 7 end	-- 5 stars	(100)

	return self:GetCappedRating(tourist, rating)
end

function HolidayRating:GetCappedRating(tourist, rating)
	local capped_rating = rating
	if tourist.traits.Renegade and rating > g_Consts.HolidayRenegadeCapRating then
		capped_rating = g_Consts.HolidayRenegadeCapRating
	end
	if (self:IsBelowCapThreshold(tourist:GetHealth()) or self:IsBelowCapThreshold(tourist:GetSanity()) or self:IsBelowCapThreshold(tourist:GetComfort())) and rating > g_Consts.HolidayStatCapRating then
		capped_rating = g_Consts.HolidayStatCapRating
	end
	return capped_rating
end

function HolidayRating:IsBelowCapThreshold(value)
	return value < g_Consts.HolidayCapThreshold
end

function HolidayRating:RewardMoney(rating, tourist)
	if not tourist.traits.Celebrity then
		local tourist_money_reward = MulDivRound(self.rewards[rating].money, g_Consts.TouristFundingMultiplier, 100)
		UIColony.funds:ChangeFunding(tourist_money_reward, "Tourist")
		return tourist_money_reward
	else
		local celebrity_money_reward = MulDivRound(self.rewards[rating].money * g_Consts.HolidayCelebrityMultiplier, g_Consts.TouristFundingMultiplier, 100)
		UIColony.funds:ChangeFunding(celebrity_money_reward, "Celebrity")
		return celebrity_money_reward
	end
end

function HolidayRating:RewardApplicants(rating, tourist)
	local applicants = 0
	applicants = self.rewards[rating].fixed_applicants
	if Random(0,100) > self.rewards[rating].bonus_chance then
		applicants = applicants + self.rewards[rating].bonus_applicants
	end
	
	if tourist.traits.Saint then
		applicants = applicants * g_Consts.HolidaySaintMultiplier
	end
	
	for i=1,applicants do
		local applicant = GenerateApplicant(false, tourist.city)
		MakeTourist(applicant)
	end
	
	return applicants
end

function HolidayRating:RewardResearch(tourist)
	if tourist.traits.Genius then
		tourist.city.colony:AddResearchPoints(g_Consts.HolidayGeniusResearchPoints)
	end
end

function HolidayRating:OpenTouristOverview(context)
	OpenDialog("TouristOverview", nil, context)
end

function HolidayRating:CloseTouristOverview()
	CloseDialog("TouristOverview")
	Msg("TouristOverviewClosed")
end

function UpdateUIHolidayRating(self, context)
	local rating = HolidayRating:GetRating(context)
	local star_rating = HolidayRating.rewards[rating].star_rating
	
	local empty_star = "UI/Icons/Sections/rating_star_empty.tga"
	local half_star = "UI/Icons/Sections/rating_star_half.tga"
	local full_star = "UI/Icons/Sections/rating_star_full.tga"
	local gold_star = "UI/Icons/Sections/rating_star_gold.tga"
	
	for i=1, #self do
		local star = self[i]
		star:SetImage(empty_star)
		if star_rating == 5 then
			star:SetImage(gold_star)
		elseif star_rating >= i then
			star:SetImage(full_star)
		elseif star_rating >= i - 0.5 then
			star:SetImage(half_star)
		end
	end
end
