--doesnt have requests, only visual pile of cubes
DefineClass.SharedStorageBaseVisualOnly = {
	__parents = { "ResourceStockpileBase" },
		properties = {
		{ template = true, name = T(696, "Max Shared Storage"),  category = "Storage Space", id = "max_shared_storage",  editor = "number", default = 120000, scale = const.ResourceScale },
		{ id = "storable_resources", editor = "prop table", no_edit = true },
		{ id = "StoredAmount", editor = false },
		
		{ id = "stockpiled_amount", editor = "number", default = false, no_edit = true },
	},
	storable_resources = false, --array of resources that can be stored in this depo -> {"r1", "r2"}
	has_demand_request = false,
	visual_cubes = false, --helper, to distinguish cube resource types
	auto_transportation_states = false,
	has_supply_request = false,
	
	cube_placement_angle = 0,
	
	dome_label = false,
}

function SharedStorageBaseVisualOnly:Init()
	self.placement_offset = point30
end

function SavegameFixups.InitMissingCarriedResourcesForRovers()
	MapForEach("map", "RCTransport", function(self)
		local storable_resources = self.storable_resources
		local resource_requests = self.resource_requests
		local disconnected = false
		local disconnected_from_start = #self.command_centers <= 0
		for i = 1, #storable_resources do
			local resource_name = storable_resources[i]
			
			if not self.visual_cubes[resource_name] then
				if not disconnected and not disconnected_from_start then
					self:DisconnectFromCommandCenters()
					disconnected = true
				end
				self.stockpiled_amount[resource_name] = 0
				self.visual_cubes[resource_name] = {}
				
				self["GetStored_"..resource_name] = function(self)
					return self.stockpiled_amount[resource_name]
				end
				
				self["GetMaxAmount_"..resource_name] = self.MaxSharedStorageGetter
				
				resource_requests[resource_name] = self:AddSupplyRequest(resource_name, 0, const.rfCannotMatchWithStorage)
			end
		end
		
		if disconnected and not disconnected_from_start then
			self:ConnectToCommandCenters()
		end
	end)
end

function SharedStorageBaseVisualOnly:CreateResourceRequests() 
	--no reqs, drones cannot interact with us.
	--init stuff.
	self.visual_cubes = { }
	self.stockpiled_amount = self.stockpiled_amount or {}
	local storable_resources = self.storable_resources
	
	for i = 1, #storable_resources do
		local resource_name = storable_resources[i]
		
		self.stockpiled_amount[resource_name] = 0
		self.visual_cubes[resource_name] = {}
		
		self["GetStored_"..resource_name]=  function(self)
			return self.stockpiled_amount[resource_name]
		end
		
		self["GetMaxAmount_"..resource_name] = self.MaxSharedStorageGetter
	end
end

function SharedStorageBaseVisualOnly:RoverLoadResource(amount, resource, request)
	self:AddResource(amount, resource, true)
end

function SharedStorageBaseVisualOnly:AddResource(amount, resource)
	local remaining_space = self:GetEmptyStorage()
	amount = Clamp(amount, -(self.max_shared_storage - remaining_space), remaining_space)
	
	
	self.stockpiled_amount[resource] = (self.stockpiled_amount[resource] or 0) + amount
	self:SetCount(self.stockpiled_amount[resource], resource)
end

function SharedStorageBaseVisualOnly:GetEmptyStorage(resource)
	return self.max_shared_storage - self:GetStoredAmount()
end

function SharedStorageBaseVisualOnly:SetResourceAutoTransportationState(resource, state)
	self.auto_transportation_states[resource] = state
end

function SharedStorageBaseVisualOnly:GetStoredAmount(resource)
	if not self.stockpiled_amount then
		return 0
	elseif resource then
		return self.stockpiled_amount[resource]
	else
		local total = 0
		for k, v in pairs(self.stockpiled_amount) do
			total = total + v
		end
		
		return total
	end
end

function SharedStorageBaseVisualOnly:MaxSharedStorageGetter()
	return self.max_shared_storage
end

function SharedStorageBaseVisualOnly:ReInitBoxSpots()
	if self:HasSpot("Box") then
		self.cube_attach_spot_idx = self:GetSpotBeginIndex("Box")
	elseif self:HasSpot("Box1") then
		self.cube_attach_spot_idx = self:GetSpotBeginIndex("Box1")
	end
	
	self.placement_offset = point30
end

function SharedStorageBaseVisualOnly:OnResourceCubePlaced(cube, resource)
	--callback
end

function SharedStorageBaseVisualOnly:SetCount(new_count, resource)
	new_count = new_count/const.ResourceScale --+ (new_count%const.ResourceScale==0 and 0 or 1)
	new_count = Max(new_count, 0)
	if not resource then return end
	
	self:ReInitBoxSpots()
	self.visual_cubes[resource] = self.visual_cubes[resource] or {}
	local total_cubes_of_type = #self.visual_cubes[resource]
	if total_cubes_of_type == new_count then return end
	local inc = new_count - total_cubes_of_type
	local step = new_count > total_cubes_of_type and 1 or -1
	
	local map_id = self:GetMapID()
	for i = total_cubes_of_type, new_count + step * -1, step do
		if step < 0 then
			--decreasing count
			local the_cube_in_question = self.visual_cubes[resource][i]
			local idx = table.find(self.placed_cubes, the_cube_in_question)
			self.placed_cubes[idx] = false
			self.visual_cubes[resource][i] = nil
			DoneObject(the_cube_in_question)
			self:RearrangeCubes(idx)
		else
			--increasing count
			local the_cube_in_question = PlaceObjectIn(self.cube_class, map_id, {
				resource = resource,
			})
			self:Attach(the_cube_in_question, self.cube_attach_spot_idx)
			local idx = table.find(self.placed_cubes, false) or #self.placed_cubes + 1
			the_cube_in_question:SetAttachOffset(self:GetCubePosRelative(idx - 1))
			--total_cubes = total_cubes + 1
			assert(not self.placed_cubes[idx])
			self.placed_cubes[idx] = the_cube_in_question
			self.visual_cubes[resource][i + 1] = the_cube_in_question
			self:OnResourceCubePlaced(the_cube_in_question, resource)
		end
	end
	
	self.count = self.count + inc
end


function SharedStorageBaseVisualOnly:GetCubePosRelative(idx)
	return Rotate(ResourceStockpileBase.GetCubePosRelative(self, idx), self.cube_placement_angle)
end

function SharedStorageBaseVisualOnly:RearrangeCubes(removed_cube_idx)
	--rearrange cubes that might be above the removed one.
	local max = Max(self:GetMax(), #self.placed_cubes)
	local step = self.max_x * self.max_y
	local next_cube_idx = removed_cube_idx + step
	while next_cube_idx <= max do
		local next_cube = self.placed_cubes[next_cube_idx]
		if not next_cube then
			break
		else
			next_cube:SetAttachOffset(self:GetCubePosRelative(removed_cube_idx - 1))
			self.placed_cubes[removed_cube_idx] = next_cube
			self.placed_cubes[next_cube_idx] = false
			
			removed_cube_idx = removed_cube_idx + step
			next_cube_idx = next_cube_idx + step
		end
	end
end

function SharedStorageBaseVisualOnly:DoesAcceptResource(resource)
	return table.find(self.storable_resources, resource)
end

SharedStorageBaseVisualOnly.AddDepotResource = SharedStorageBaseVisualOnly.AddResource
SharedStorageBaseVisualOnly.AddResourceAmount = SharedStorageBaseVisualOnly.AddResource
SharedStorageBaseVisualOnly.SetResourceAmount = false --not impl.
SharedStorageBaseVisualOnly.SetCountFromRequest = false --not impl.
