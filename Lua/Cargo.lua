if FirstLoad then
	local cargo_types = {
		Resource = "Resource",
		Drone = "Drone",
		Rover = "Rover",
		Colonist = "Colonist",
		Prefab = "Prefab",
		Unknown = "Unknown",
	}
	CargoType = setmetatable(cargo_types, immutable_meta)
end

function GetCargoType(class)
	if GetResourceInfo(class) then
		return CargoType.Resource
	elseif BuildingTemplates[class] then
		return CargoType.Prefab
	elseif table.find(GetSortedColonistSpecializationTable(), class) then
		return CargoType.Colonist
	else
		local def = g_Classes[class]
		if def then
			return class == "Drone" and CargoType.Drone or CargoType.Rover
		end
	end
	assert(false, "cannot determine cargo type")
	return CargoType.Unknown
end

function GetObjectCargoType(object)
	if IsKindOf(object, "Colonist") then
		return CargoType.Colonist
	elseif IsKindOf(object, "BaseRover") then
		return CargoType.Rover
	elseif IsKindOf(object, "Drone") then
		return CargoType.Drone
	else
		assert(false, "cannot determine object cargo type")
		return CargoType.Unknown
	end
end

function GetObjectCargoIDs(object)
	if IsKindOf(object, "Colonist") then
		local colonist = object
		local specializations = {}
		for _,specialization in ipairs(GetSortedColonistSpecializationTable()) do
			if colonist.traits[specialization] then
				table.insert(specializations, specialization)
			end
		end
		return #specializations > 0 and specializations or { "none" }
	else
		return { object.class }
	end
end

function GetTotalCargoPending(city, class)
	local remaining_func = CargoTransporter.GetCargoRemaining
	local total = 0
	for _,transporter in ipairs(city.labels.LanderRocketBase or empty_table) do
		local pending = remaining_func(transporter, class)
		total = total + pending
	end

	for _,transporter in ipairs(city.labels.Elevator or empty_table) do
		local pending = remaining_func(transporter, class)
		total = total + pending
	end
	return total
end

function GetTotalCargoAvailable(city, cargo_type, class)
	if cargo_type == CargoType.Resource then
		local resources = GetCityResourceOverview(city)
		return resources:GetAvailable(class) / const.ResourceScale
	elseif cargo_type == CargoType.Prefab then
		return city:GetPrefabs(class)
	elseif cargo_type == CargoType.Colonist then
		if class == "Tourist" then
			local tourists = 0
			local colonists = city.labels.Colonist or empty_table
			for _,colonist in pairs(colonists) do
				if colonist.traits.Tourist then
					tourists = tourists + 1
				end
			end
			return tourists
		else
			return #(city.labels[class] or empty_table)
		end
	else
		return #(city.labels[class] or empty_table)
	end
end

function GetTotalAvailableInColony(class) -- Deprecated
	local available = 0
	local cities_to_check = Cities
	local cargo_type = GetCargoType(class)
	for _,city in ipairs(cities_to_check) do
		available = available + GetTotalCargoAvailable(city, cargo_type, class)
	end
	return available
end

AvailabilityStatus = {
	None = 0,
	Restricted = 1,
	NotEnough = 2,
	Limited = 3,
	Ready = 4,
	Loaded = 5,
}

AvailabilityStatusDescription = {
	T(13941, "<red>Below minimum</red>"),
	T(13775, "<red>Not enough</red>"),
	T(13776, "<yellow>Limited</yellow>"),
	T(13777, "<green>Ready</green>"),
	T(13805, "<green>Loaded</green>"),
}

function GetHighestAvailabilityStatus(status, other_status)
	return Min(status, other_status)
end

function GetAvailabilityStatus(remaining, total_pending, available, restricted)
	local result = AvailabilityStatus.None
	if remaining == 0 then
		result = AvailabilityStatus.Loaded
	elseif (restricted and available > restricted) and remaining > restricted then
		result = AvailabilityStatus.Restricted
	elseif remaining > available then
		result = AvailabilityStatus.NotEnough
	elseif total_pending > available then
		result = AvailabilityStatus.Limited
	else
		result = AvailabilityStatus.Ready
	end
	return result
end

CargoPriority = {
    approve = 1,
    neutral = 0,
    disapprove = -1,
}
