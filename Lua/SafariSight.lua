DefineClass.SafariSight = {
	__parents = { "Object" },
	properties = {
		{ template = true, category = "Safari", id = "sight_name", name = T(12751, "sight_name"), editor = "text", default = "", translate = true, },
		{ template = true, category = "Safari", id = "sight_category", name = T(12752, "sight_category"), editor = "text", default = "" },
		{ template = true, category = "Safari", id = "sight_satisfaction", name = T(12753, "sight_satisfaction"), editor = "number", default = 0 },
		{ template = true, category = "Safari", id = "sight_visible_size", name = T(12895, "sight_visible_size"), editor = "number", default = 0 },
	},
}

function SafariSight:GetSightSatisfaction()
	return self.sight_satisfaction
end

function SafariSight:GetVisibleSize()
	if self.sight_visible_size > 0 then
		return self.sight_visible_size
	end
	
	local center, radius = self:GetBSphere()
	return radius
end

function SafariSight:GetName()
	if self.sight_name ~= "" then
		return self.sight_name
	end
	
	if self["display_name"] then
		return self.display_name
	end
	
	return Untranslated("Safari sight does not have a name configured")
end

local satisfaction_award_multiplier = {
	1,
	0.75,
	0.5,
	0.25,
	0
}

function SafariSight:AwardSatisfaction(safari)
	if not safari.awarded_satisfaction then safari.awarded_satisfaction = {} end
	if not safari.awarded_satisfaction.total then safari.awarded_satisfaction.total = 0 end
	if not safari.seen_sights then safari.seen_sights = {} end
	
	if table.find(safari.seen_sights, self) then return end
	
	if not safari.awarded_satisfaction[self.sight_category] then safari.awarded_satisfaction[self.sight_category] = {} end
	
	local multiplier_index = Min(#safari.awarded_satisfaction[self.sight_category] + 1, 4)
	local multiplier = satisfaction_award_multiplier[multiplier_index]
	
	local previously_awarded_satisfaction = safari.awarded_satisfaction.total or 0
	local satisfaction_room = 25 - previously_awarded_satisfaction
	local satisfaction_to_award = Min(multiplier * self:GetSightSatisfaction(), satisfaction_room)
	
	if satisfaction_to_award then
		safari.awarded_satisfaction.total = previously_awarded_satisfaction + satisfaction_to_award
		table.insert(safari.awarded_satisfaction[self.sight_category], satisfaction_to_award)
		table.insert(safari.seen_sights, self)
		for _, visitor in ipairs(safari.visitors) do
			visitor:ChangeSatisfaction(satisfaction_to_award * const.Scale.Stat, "safari")
		end
	end
end

function SafariSight:IsActive()
	return self.sight_category ~= ""
end

local forest_sight = nil
function GetVisibleSights(realm, observation_pt, sight_range)
	local function filter_function(_, sight)
		if not sight:IsActive() then return false end

		local distance = observation_pt:Dist(sight:GetPos())
		local radius = sight:GetVisibleSize()
		return distance - radius < sight_range * const.HexHeight
	end
	
	-- Extend the query range to get all the objects whose center is outside the sight range but whose bounds are inside
	local query_range = sight_range * 3
	local queried_sights = realm:MapGet(observation_pt, "hex", query_range, "SafariSight")
	local filtered_sights = table.ifilter(queried_sights, filter_function)
	
	if CanSeeForest(realm, observation_pt, sight_range) then
		-- Keep one forest sight instance for all forests
		if not forest_sight then forest_sight = ForestSight:new() end
		table.insert(filtered_sights, forest_sight)
	end
	
	return filtered_sights
end

function ObserveSights(safari)
	local realm = GetRealm(safari)
	local sights = GetVisibleSights(realm, safari:GetPos(), safari.sight_range)
	for _,sight in pairs(sights) do
		sight:AwardSatisfaction(safari)
	end
end