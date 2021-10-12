DefineClass.ForestSight = {
	__parents = { "SafariSight" },
	sight_name = T(12719, "Forest"),
	sight_category = "Additional Buildings",
	sight_satisfaction = 3,
}

function ForestSight:GetVisibleSize()
	--	ForestSight is currently not instanced in an actual position
	-- So doesn't have a radius
	return 0
end

function CanSeeForest(realm, observation_pt, sight_range)
	if not IsDlcAvailable("armstrong") then
		return false
	end

	local trees = realm:MapGet(observation_pt, "hex", sight_range, "VegetationTree")
	local trees_in_forest = 10
	return #trees > trees_in_forest
end