-----------------------------------------------------------------------------------------------------------------
local dbg_prints = false
GlobalObj("LRManagerInstance", "LRManager")
GlobalVar("StorableResources", false)
GlobalVar("StorableResourcesForSession", false)

function BuildStorableResourcesArray()
	if StorableResources then return end
	
	--deduce the kind of resources storage depots can store
	StorableResources = {}
	local descendants = ClassDescendantsList("StorageDepot")
	local template_depots = table.filter(BuildingTemplates, function(id, o)
			local c = ClassTemplates.Building[id]
			if c and IsKindOf(c, "StorageDepot") and not c.exclude_from_lr_transportation then 
				return o
			end
		end)
	for _, t in pairs(template_depots) do
		table.insert(descendants, t.id)
	end
	local resources = {}
	for i = 1, #descendants do
		local class_def = BuildingTemplates[descendants[i]] or g_Classes[descendants[i]]
		if not class_def.exclude_from_lr_transportation then
			if class_def:HasMember("storable_resources") and class_def.storable_resources then --shared storage
				for i = 1, #(class_def.storable_resources or empty_table) do
					resources[class_def.storable_resources[i]] = true
				end
			else
				for _, resource_name in ipairs(AllResourcesList) do
					local max_name = "max_amount_"..resource_name
					if class_def:HasMember(max_name) then --single resource storages
						resources[resource_name] = true
					end
				end
			end
		end
	end
	
	local transportable_resources = CargoShuttle.storable_resources
	for r_f, _ in pairs(resources) do
		if table.find(transportable_resources, r_f) then
			table.insert(StorableResources, r_f)
		end
	end
	
	table.sort(StorableResources, function(a, b) return a < b end)
	StorableResourcesForSession = table.copy(StorableResources)
	if dbg_prints then
		print("resource storage tbl built:")
		for i = 1, #StorableResources do
			print(StorableResources[i])
		end
	end
end

DefineClass.ColonistTransportTask = {
	__parents = { "InitDone" },
	
	state = "new", --new, almost_ready_for_pickup, ready_for_pickup, transporting, done
	source_dome = false,
	dest_dome = false,
	colonist = false,
	shuttle = false,
	source_landing_site = false, --{pos, landing id, spot id}
	dest_pos = false, -- safe pos to place the colonist in case of errors
}

function ColonistTransportTask:CanExecute()
	return not self.shuttle
		and IsValid(self.colonist) and self.colonist:CanChangeCommand()-- not diying and not leaving
		and (self.state == "ready_for_pickup" or self.state == "almost_ready_for_pickup")
		and self.source_dome:IsLandingSpotFree(self.source_landing_site[2])
		and self.dest_dome.has_free_landing_slots
end

function ColonistTransportTask:Cleanup()
	local lr_manager = GetLRManager(self.colonist)
	lr_manager:RemoveColonistTransportRequest(self)
	local shuttle = self.shuttle
	if shuttle and shuttle.transport_task == self then
		Wakeup(shuttle.command_thread)
	end
	local colonist = self.colonist
	if colonist and colonist.transport_task == self then
		colonist.transport_task = false
	end
	DoneObject(self)
end

function CreateColonistTransportTask(colo, source_dome, dest_dome)
	assert(colo.transport_task == false)
	local ref_pos = colo:IsValidPos() and colo:GetPos() or colo.holder and colo.holder:GetPos()
	if ref_pos == InvalidPos() then
		return --cant create transport req, we don't know where colo is
	end
	local landing_slot, landing_idx = source_dome:GetNearestLandingSlot(ref_pos)
	if not landing_slot then
		assert(false, "No landing spot found!")
		return
	end
	local req = ColonistTransportTask:new{
		colonist = colo,
		source_dome = source_dome,
		dest_dome = dest_dome,
		source_landing_site = table.pack(landing_slot.pos, landing_idx),
	}
	colo.transport_task = req
	local lr_manager = GetLRManager(colo)
	lr_manager:AddColonistTransportRequest(req)
	return req
end