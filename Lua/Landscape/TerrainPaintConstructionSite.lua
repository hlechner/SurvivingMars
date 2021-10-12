DefineClass.TerrainPaintConstructionSite = {
	__parents = { "LandscapeConstructionSiteBase" },
	
	work_request = false,
	work_required = false,
	last_progress_marked = 0,
}

local work_per_hex_for_terrain_painting = 1000
function TerrainPaintConstructionSite:GatherConstructionResources()
	if self.work_request then return end
	local landscape = Landscapes[self.mark]
	if not landscape then
		assert(false)
		return 
	end
	
	local passed = {}
	LandscapeForEachObstructor(self.mark, function(obj)
		if not passed[obj] then
			if obj:GetEnumFlags(const.efRemoveUnderConstruction + const.efBakedTerrainDecal + const.efBakedTerrainDecalLarge) ~= 0 then
				DoneObject(obj)
			end
			passed[obj] = true
		end
	end)
	
	self.work_required = landscape.hexes * work_per_hex_for_terrain_painting
	self.work_request = self:AddWorkRequest("construct", 0, 0, self:GetMaxDrones())

	self.construction_resources = {}
	self.construct_request = self.work_request
	
	self.state = "init_done"
	self:UpdateState()
end

function TerrainPaintConstructionSite:TryGoToNextState()
	if self.state == "work" then
		if self.work_request:GetActualAmount() <= 0 then
			self.state = "work_done"
			self:UpdateState()
		end
	end
end

function TerrainPaintConstructionSite:UpdateState()
	if self.state == "init_done" then
		if self.work_required > 0 then
			self.state = "work"
			self.work_request:AddAmount(self.work_required)
		else
			self.state = "work_done"
		end
	end
	if self.state == "work_done" then
		self.state = "complete"
		CreateGameTimeThread(self.Complete, self)
	end
end

function TerrainPaintConstructionSite:GetTotalLandscapeProgress()
	local total = self.work_required
	local progress = 0
	if self.state == "work" then
		progress = self.work_required - self.work_request:GetActualAmount()
	elseif self.state == "work_done" or self.state == "complete" then
		progress = total
	end
	
	return MulDivTrunc(progress, 100, total)
end

function TerrainPaintConstructionSite:GetResourceProgress()
	local lines = {}
	
	if self.state == "work" then
		lines[#lines+1] = T{12395, "<em>Changing terrain</em><right><percent>%", percent = self:GetTotalLandscapeProgress()}
	end
	
	return table.concat(lines, "<newline><left>")
end	

function TerrainPaintConstructionSite:UpdateLSProgress()
	local p = self:GetTotalLandscapeProgress()
	if p > self.last_progress_marked then
		LandscapeChangeTerrain(self.mark, p)
		self.last_progress_marked = p
		self:TryGoToNextState()
	end
end

function TerrainPaintConstructionSite:BuildingUpdate(delta, day, hour)
	if self.state == "work" and UIColony:IsTechResearched("LandscapingNanites") then
		local current_time = GameTime()
		if not self.auto_construct_ts_ls then self.auto_construct_ts_ls = current_time end 
		if current_time - self.auto_construct_ts_ls >= construction_site_auto_construct_tick then
			self.auto_construct_ts_ls = current_time
			
			local req = self.work_request
			local a = req:GetActualAmount()
			local dec = Min(construction_site_auto_construct_amount, a)
			a = a - dec
			req:SetAmount(a)
			self:UpdateLSProgress(dec, req)
			RebuildInfopanel(self)
		end
	end
end

function TerrainPaintConstructionSite:GetDroneWorkAmount(drone, request, resource, amount)
	return amount
end

function TerrainPaintConstructionSite:RoverLoadResource(amount, resource, request)
	self:AddResource(amount, resource, true)
end

function TerrainPaintConstructionSite:AddResource(amount, resource)
	if resource == "construct" then
		self.work_request:AddAmount(amount * (const.ResourceScale / DroneResourceUnits.construct))
		self:UpdateLSProgress(amount)
		return
	end
end

function TerrainPaintConstructionSite:Getdescription() 
	return T{12470, "<em>Landscaping project.</em> Drones will gradually change the underlying surface towards the desired texture.", self}
end
