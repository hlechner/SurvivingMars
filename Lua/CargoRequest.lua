function GetCargoColonistSpecializationItems()
	local items = {}
	for id, entry in pairs(const.ColonistSpecialization) do
		items[#items+1] = {id = id, sort_key = entry.sort_key, name = entry.display_name_plural}
	end
	table.sortby_field(items, "sort_key")
	return items
end

DefineClass.CargoItem = {
	__parents = { "InitDone" },

	type = CargoType.Unknown,
	id = false,
	name = false,
}

function CargoItem:__tostring()
	return self.id and self.id
end

DefineClass.CargoRequestItem = {
	__parents = { "CargoItem" },

	submenu = false,
	destination_requested = 0,
	destination_available = 0,
	origin_requested = 0,
	origin_available = 0,
	predicted_request = 0,
}

DefineClass.CargoRequest = {
	__parents = { "InitDone" },

	submenu_rollovers = {
		prefabs = {
			title = T(1110, "Prefab Buildings"),
			descr = T(1111, "Prefabricated parts needed for the construction of certain buildings on Mars."),
			hint =  T(1112, "<left_click> Browse Prefab Buildings"),
			gamepad_hint = T(1113, "<ButtonA> Browse Prefab Buildings"),
		},
		vehicles = {
			title = T(13676, "RC Vehicles"),
			descr = T(13677, "Remote Controlled vehicles that have been designed to perform various tasks."),
			hint =  T(13678, "<left_click> Browse RC Vehicles"),
			gamepad_hint = T(13679, "<ButtonA> Browse RC Vehicles"),
		},
		colonists = {
			title = T(547, "Colonists"),
			descr = T(13680, "Inhabitants of the Mars colony. Specialized in a variety of fields."),
			hint =  T(13681, "<left_click> Browse Colonists"),
			gamepad_hint = T(13682, "<ButtonA> Browse Colonists"),
		}
	},

	transporter = false,
	cargo_items = false,
	cargo_type_items = false,
	cargo_type_totals = false,
	top_level_items = false,

	cargo_weight_limit = 0,
	passenger_limit = 0,

	destination_weight_requested = 0,
	auto_mode = false,
}

function CargoRequest:IsTwoWayRequest()
	return false
end

function CargoRequest:HasAutoMode()
	return self.has_auto_mode
end

function CargoRequest:GetAutoMode()
	return self.auto_mode
end

function CargoRequest:SetAutoMode(mode)
	if self.auto_mode ~= mode then
		self.auto_mode = mode
		self:ClearRequests(true)
		self:RetrieveRequests(self.auto_mode)
		ObjModified(self)
	end
end

function CargoRequest:GetCargoWeightCapacityLimit()
	return self.cargo_weight_limit
end

function CargoRequest:GetCargoWeightCapacityRequested()
	return self.destination_weight_requested
end

function CargoRequest:GetPassengersRequested()
	local colonists = self.cargo_type_totals[CargoType.Colonist]
	return colonists and colonists.destination_requested or 0
end

function CargoRequest:GetPassengersLimit()
	return self.passenger_limit
end

function CargoRequest:GetTransportableCargo(transporter)
	local cargo_items = {}
	local cargo_type_items = {}

	if transporter:CanTransportCargoType(CargoType.Prefab) then
		cargo_type_items[CargoType.Prefab] = {}
		local prefab_items = cargo_type_items[CargoType.Prefab]

		local prefabs = transporter:GetTransportablePrefabs()
		table.sort(prefabs, PresetSortLessCb)
		for _, prefab in ipairs(prefabs) do
			local cargo_item = CargoRequestItem:new{ type=CargoType.Prefab, id=prefab.id, name=prefab.name }
			cargo_items[prefab.id] = cargo_item
			prefab_items[#prefab_items+1] = cargo_item
		end
	end

	if transporter:CanTransportCargoType(CargoType.Colonist) then
		cargo_type_items[CargoType.Colonist] = {}
		local colonists_items = cargo_type_items[CargoType.Colonist]

		local colonists = GetCargoColonistSpecializationItems()
		for _, colonist in ipairs(colonists) do
			local cargo_item = CargoRequestItem:new{ type=CargoType.Colonist, id=colonist.id, name=colonist.name }
			cargo_items[colonist.id] = cargo_item
			colonists_items[#colonists_items+1] = cargo_item
		end
	end

	if transporter:CanTransportCargoType(CargoType.Rover) then
		cargo_type_items[CargoType.Rover] = {}
		local rover_items = cargo_type_items[CargoType.Rover]

		local vehicles = transporter:GetTransportableVehicles()
		table.sort(vehicles, PresetSortLessCb)

		for _, vehicle in ipairs(vehicles) do
			local cargo_item = CargoRequestItem:new{ type=CargoType.Rover, id=vehicle.id, name=vehicle.name }
			cargo_items[vehicle.id] = cargo_item
			rover_items[#rover_items+1] = cargo_item
		end
	end

	if transporter:CanTransportCargoType(CargoType.Drone) then
		local drone_item = CargoRequestItem:new{ type=CargoType.Drone, id="Drone", name=T(517, "Drones") }
		cargo_items[drone_item.id] = drone_item
		cargo_type_items[CargoType.Drone] = { drone_item }
	end

	if transporter:CanTransportCargoType(CargoType.Resource) then
		cargo_type_items[CargoType.Resource] = {}
		local resource_items = cargo_type_items[CargoType.Resource]

		for k, item in ipairs(ResupplyItemDefinitions) do
			if (not item.filter or item.filter()) and IsResupplyItemAvailable(item.id) then
				local id = item.id
				local cargo_type = GetCargoType(id)
				if cargo_type == CargoType.Resource then
					local cargo_item = CargoRequestItem:new{ type=cargo_type, id=item.id, name=item.name }
					cargo_items[item.id] = cargo_item
					resource_items[#resource_items+1] = cargo_item
				end
			end
		end
	end

	return cargo_items, cargo_type_items
end

function CargoRequest:Init()
	assert(self.transporter)

	local transporter = self.transporter
	self.cargo_weight_limit = transporter:GetCargoWeightCapacity()
	self.passenger_limit = transporter:GetPassengerCapacity()

	self.has_auto_mode = transporter:HasAutoMode()
	self.auto_mode = transporter:IsAutoModeEnabled()

	self.cargo_items, self.cargo_type_items = self:GetTransportableCargo(transporter)
	
	self.cargo_type_totals = {}
	local cargo_type_totals = self.cargo_type_totals
	cargo_type_totals[CargoType.Prefab] = CargoRequestItem:new{type=CargoType.Prefab, id = "prefabs", name=T(1109, "Prefab Buildings"), submenu = true,}
	cargo_type_totals[CargoType.Colonist] = CargoRequestItem:new{type=CargoType.Colonist, id = "colonists", name=T(547, "Colonists"), submenu = true,}
	cargo_type_totals[CargoType.Rover] = CargoRequestItem:new{type=CargoType.Rover, id = "vehicles", name=T(13676, "RC Vehicles"), submenu = true,}
	cargo_type_totals[CargoType.Drone] = self.cargo_items["Drone"]
	cargo_type_totals[CargoType.Resource] = CargoRequestItem:new{type=CargoType.Resource, id = "Resource", name=T(692, "Resources")}

	self:RetrieveCargoInfo()
	self:RetrieveRequests(self:GetAutoMode())

	self:InitTopLevelItems()
end

function CargoRequest:InitTopLevelItems()
	self.top_level_items = {}

	local top_level_items = self.top_level_items
	local cargo_type_items = self.cargo_type_items
	local cargo_type_totals = self.cargo_type_totals

	if cargo_type_items[CargoType.Prefab] then
		top_level_items[#top_level_items+1] = cargo_type_totals[CargoType.Prefab]
	end

	if cargo_type_items[CargoType.Colonist] then
		top_level_items[#top_level_items+1] = cargo_type_totals[CargoType.Colonist]
	end

	if cargo_type_items[CargoType.Rover] then
		top_level_items[#top_level_items+1] = cargo_type_totals[CargoType.Rover]
	end

	if cargo_type_items[CargoType.Drone] then
		top_level_items[#top_level_items+1] = cargo_type_totals[CargoType.Drone]
	end

	if cargo_type_items[CargoType.Resource] then
		local resources = cargo_type_items[CargoType.Resource]
		for _, resource in ipairs(resources) do
			top_level_items[#top_level_items+1] = resource
		end
	end
end

function CargoRequest:RetrieveRequests(is_automode)
	local destination_requests = self.transporter.cargo or empty_table
	for id, request in pairs(destination_requests) do
		self:SetDestinationRequest(id, request.requested, true)
	end
end

function CargoRequest:RetrieveCargoInfo()
	local origin_map_id = self.transporter:GetCargoOriginMapID()
	local origin_city = Cities[origin_map_id]

	local destination_map_id = self.transporter:GetCargoDestinationMapID()
	local destination_city = Cities[destination_map_id]

	for cargo_type, cargo_items in pairs(self.cargo_type_items) do
		local destination_total = 0
		local origin_total = 0
		for _, cargo_item in pairs(cargo_items) do
			local origin_available = origin_city and GetTotalCargoAvailable(origin_city, cargo_item.type, cargo_item.id) or 0
			local destination_available = destination_city and GetTotalCargoAvailable(destination_city, cargo_item.type, cargo_item.id) or 0
			origin_total = origin_total + origin_available
			destination_total = destination_total + destination_available
			cargo_item.origin_available = origin_available
			cargo_item.destination_available = destination_available
		end

		local type_total = self.cargo_type_totals[cargo_type]
		if type_total then
			type_total.origin_available = origin_total
			type_total.destination_available = destination_total
		end
	end
end

function CargoRequest:ClearRequests(silent)
	for id, item in pairs(self.cargo_items) do
		item.destination_requested = 0
		item.origin_requested = 0
		item.predicted_request = 0
	end
	for id, item in pairs(self.cargo_type_totals) do
		item.destination_requested = 0
		item.origin_requested = 0
		item.predicted_request = 0
	end
	self.destination_weight_requested = 0
	if not silent then
		ObjModified(self)
	end
end

function CargoRequest:GetDestinationRequest(id, fallback)
	local cargo_item = self.cargo_items[id]
	return cargo_item and cargo_item.destination_requested or (fallback or 0)
end

function CargoRequest:SetDestinationRequest(id, amount, silent)
	local cargo_item = self.cargo_items[id]
	-- assert(cargo_item)
	if not cargo_item then return end
	local delta = amount - cargo_item.destination_requested
	if delta ~= 0 then
		cargo_item.destination_requested = amount
		local cargo_type_totals = self.cargo_type_totals[cargo_item.type]
		if cargo_item ~= cargo_type_totals then
			cargo_type_totals.destination_requested = cargo_type_totals.destination_requested + delta
		end

		if cargo_item.type ~= CargoType.Colonist and self.cargo_weight_limit > 0 then
			local supply_item = GetResupplyItem(id)
			local item_weight = GetResupplyItemWeight(supply_item)
			local delta_weight = item_weight * delta
			self.destination_weight_requested = self.destination_weight_requested + delta_weight
		end

		if not silent then
			ObjModified(self)
		end

		return true
	end

	return false
end

function CargoRequest:GetDestinationRequests(cargo_type)
	local items = self.cargo_type_items[cargo_type] or empty_table
	local total = #items
	local counted = {}
	for _, item in ipairs(items) do
		counted[item.destination_requested] = (counted[item.destination_requested] or 0) + 1
	end
	return counted, total
end

function CargoRequest:SetDestinationRequestsWithAmount(cargo_type, with_amount, amount, silent)
	if with_amount == amount then return false end

	local items = self.cargo_type_items[cargo_type] or empty_table
	local changed = false
	for _, item in ipairs(items) do
		if not with_amount or item.destination_requested == with_amount then
			changed = self:SetDestinationRequest(item.id, amount, true) or changed
		end
	end
	if changed and not silent then
		ObjModified(self)
	end
	return changed
end

function CargoRequest:SetOriginRequest(id, amount, silent)
	local cargo_item = self.cargo_items[id]
	-- assert(cargo_item)
	if not cargo_item then return end
	local delta = amount - cargo_item.origin_requested
	if delta ~= 0 then
		cargo_item.origin_requested = amount
		local cargo_type_totals = self.cargo_type_totals[cargo_item.type]
		if cargo_item ~= cargo_type_totals then
			cargo_type_totals.origin_requested = cargo_type_totals.origin_requested + delta
		end

		if not silent then
			ObjModified(self)
		end
	end
end

function CargoRequest:GetCargoTopLevelItems()
	return self.top_level_items
end

function CargoRequest:GetCargoTypeItems(cargo_type)
	return self.cargo_type_items[cargo_type] or empty_table
end

function CargoRequest:GetDestinationCargoList()
	local cargo = {}
	for id, item in pairs(self.cargo_items) do
		if item.destination_requested ~= 0 then
			cargo[id] = { type=item.type, class=id, amount=item.destination_requested }
		end
	end
	return cargo
end

function CargoRequest:GetOriginCargoList()
	local cargo = {}
	for id, item in pairs(self.cargo_items) do
		if item.origin_requested ~= 0 then
			cargo[id] = { type=item.type, class=id, amount=item.origin_requested }
		end
	end
	return cargo
end

function CargoRequest:Cancel()
end

function CargoRequest:Apply()
	self.transporter:SetAutoMode(self:GetAutoMode())
	self.transporter:UISetCargoRequest(self)
end

function CargoRequest:CanDestinationRequest(item)
	if item.type ~= CargoType.Colonist and self.cargo_weight_limit > 0 then
		local supply_item = GetResupplyItem(item.id)
		local item_weight = GetResupplyItemWeight(supply_item)
		local predicted_weight = self.destination_weight_requested + item_weight
		return predicted_weight <= self.cargo_weight_limit
	elseif item.type == CargoType.Colonist and self.passenger_limit > 0 then
		local passengers_requested = self:GetPassengersRequested()
		return passengers_requested < self.passenger_limit
	end
	return true
end

function CargoRequest:CanOriginRequest(item)
	return true
end

function CargoRequest:GetDestinationRequestRemaining(item)
	if self:GetAutoMode() then
		return Max(0, item.destination_requested - item.destination_available)
	else
		return item.destination_requested
	end
end

function CargoRequest:GetOriginRequestRemaining(item)
	if self:GetAutoMode() then
		return Max(0, item.origin_requested - item.origin_available)
	else
		return item.origin_requested
	end
end

function CargoRequest:GetDestinationTransferable(item)
	return item.destination_available
end

function CargoRequest:GetOriginTransferable(item)
	return item.origin_available
end

function CargoRequest:GetDestinationRequestStatus(item)
	local status = AvailabilityStatus.Loaded
	if item.destination_requested > 0 then
		local origin_map_id = self.transporter:GetCargoOriginMapID()
		local origin_city = Cities[origin_map_id]
		local origin_total_pending = GetTotalCargoPending(origin_city, item.id)
		local origin_transferable = self:GetOriginTransferable(item)
		local destination_remaining = self:GetDestinationRequestRemaining(item)
		status = GetAvailabilityStatus(destination_remaining, origin_total_pending, item.origin_available, origin_transferable)
	end
	return status
end

function CargoRequest:GetOriginRequestStatus(item)
	local status = AvailabilityStatus.Loaded
	if item.origin_requested > 0 then
		local destination_map_id = self.transporter:GetCargoDestinationMapID()
		local destination_city = Cities[destination_map_id]
		local destination_total_pending = GetTotalCargoPending(destination_city, item.id)
		local destination_transferable = self:GetDestinationTransferable(item)
		local origin_remaining = self:GetOriginRequestRemaining(item)
		status = GetAvailabilityStatus(origin_remaining, destination_total_pending, item.destination_available, destination_transferable)
	end
	return status
end

function CargoRequest:GetRollover(id)
	if self.prop_meta.submenu then
		return self.submenu_rollovers[id]
	end

	custom_pack_multiplier = custom_pack_multiplier or 1
	local item = GetResupplyItem(id)
	if not item then
		assert(false, "No such cargo item!")
		return
	end
	local display_name, description = item.name, item.description
	if not display_name or display_name == "" then
		display_name, description = ResolveDisplayName(id)
	end
	description = (description and description ~= "" and description .. "<newline><newline>") or ""
	local icon = item.icon and Untranslated("<image "..item.icon.." 2000><newline><newline>") or ""
	description = icon..description .. T{1114, "Weight: <value> kg<newline>Cost: <funding(cost)>", value = GetResupplyItemWeight(item), cost = GetResupplyItemPrice(item)}
	return {
		title = display_name,
		descr = description,
		gamepad_hint = T(7580, "<DPadLeft> Change value <DPadRight>"),
	}
end
