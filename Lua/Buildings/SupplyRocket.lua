DefineClass.SupplyRocket = {
	__parents = { "RocketBase" },
}

-- backward compatibility
--[[
	Some rocket states used to happen in game-time threads which aren't saved anywhere and can be potentially saved.
	The following functions are used to hook onto these running threads and phase the rocket to a proper command.
--]]

-- potentially called from a created GameTime thread within LandOnSite
function SupplyRocket:UnloadCargo()
	self:SetCommand("Unload")
	Halt()
end

-- potentially called from a created GameTime thread within LandOnSite or BuildingUpdate
function SupplyRocket:Launch()
	self:SetCommand("Takeoff")
	Halt()
end

-- potentially called from within Launch (see above), in that case it's an automated return to Mars
function SupplyRocket:OrderLanding()
	self:SetCommand("FlyToMars")
	Halt()
end

-- potentially called at the very start of the created GameTime thread within LandOnSite
function SupplyRocket:Land()
	if IsValid(self.landing_site) then
		self:SetCommand("LandOnMars", self.landing_site)
	else
		self:SetCommand("WaitInOrbit")
	end
	Halt()
end

-- end backward compatibility

function SupplyRocket:UnloadCargoObjects(cargo, out)
	RocketBase.UnloadCargoObjects(self, cargo, out)
	self.cargo = nil
end

function SupplyRocket:CheatGenerateDepartures()
	self:GenerateDepartures(true, true)
end

function SupplyRocket:GenerateDepartures(count_earthsick, count_tourists)
	if not self.can_fly_colonists then -- for compatibility
		return
	end
	assert(self:IsValidPos())
	local domes = self.city.labels.Dome or ""
	
	if not self.departures then self.departures = {} end
	if not self.boarding then self.boarding = {} end
	if not self.boarded then self.boarded = {} end
	
	local earthsick = {}
	local tourists = {}
	
	local colonists = UIColony.city_labels.labels.Colonist or {}
	for _, colonist in ipairs(colonists) do
		if colonist:CanChangeCommand() and (count_earthsick and colonist.status_effects.StatusEffect_Earthsick or (count_tourists and colonist:IsTouristReadyToGoHome())) then
			local is_viable_rocket = colonist:GetMapID() ~= self:GetMapID() or IsInWalkingDist(self, colonist, const.ColonistMaxDepartureRocketDist)
			if is_viable_rocket then
				if colonist.traits.Tourist then
					tourists[#tourists + 1] = colonist
				else
					earthsick[#earthsick + 1] = colonist
				end
				colonist:SetCommand("LeavingMars", self)
			end
		end
	end
	
	if count_earthsick and #earthsick > 0 then
		AddOnScreenNotification("LeavingMars", false, {colonists_count = #earthsick}, earthsick, self:GetMapID())
	end
	if count_tourists and #tourists > 0 then
		AddOnScreenNotification("LeavingMarsTourists", false, {tourists_count = #tourists}, tourists, self:GetMapID())
	end
end

function SupplyRocket:UIOpenTouristOverview()
	local reward_info = self:GetTourismRewardInfo()
	HolidayRating:OpenTouristOverview(reward_info)
end

function SupplyRocket:ToggleAutoExport()
	self.auto_export = not self.auto_export
	self:AttachSign(self.auto_export, "SignTradeRocket")
	if not self.auto_export then -- can be disabled at any time
		if self.reserved_site then
			assert(IsValid(self.landing_site))
			DoneObject(self.landing_site)
			self.landing_site = nil
		end
		self.reserved_site = nil
	else -- can only be enabled when rocket is landed and has valid landing site
		assert(IsValid(self.landing_site))
		self.landing_site.disable_selection = false
		if self.waiting_resources then
			Wakeup(self.command_thread)
		end
	end
	if not self.auto_export and IsValid(self.site_particle) and self.status ~= "landing" then
		StopParticles(self.site_particle)
		if SelectedObj == self then
			SelectObj(false)
		end
	end
	ObjModified(self)
end

function SupplyRocket:ToggleAllowExport(broadcast)
	
	local allow = not self.allow_export
	
	if broadcast then
		local list = self.city.labels.SupplyRocket or empty_table
		for _, rocket in ipairs(list) do
			if rocket.allow_export ~= allow then
				rocket:ToggleAllowExport()
			end
		end
		return
	end
	
	self.allow_export = not self.allow_export
	
	if not self.allow_export and self.auto_export then
		self:ToggleAutoExport()
	end
	
	if self.command == "Refuel" or self.command == "WaitLaunchOrder" then
		if self.allow_export then
			-- cancel any remaining supply requests, interrupt drones, carry remaining supply to the new demand request
			self:InterruptDrones(nil, function(drone)
												if (drone.target == self) or 
													(drone.d_request and drone.d_request:GetBuilding() == self) or
													(drone.s_request and drone.s_request:GetBuilding() == self) then
													return drone
												end
											end)
			self:DisconnectFromCommandCenters()		
			
			-- create export request, transfer the remaining unload amount, close the unload request
			local stored = self.unload_request and self.unload_request:GetActualAmount() or 0
			
			local unit_count = 1 + (self.max_export_storage / (const.ResourceScale * 10)) --1 per 10
			self.export_requests = { self:AddDemandRequest("PreciousMetals", self.max_export_storage - stored, 0, unit_count) }
			if self.unload_request then
				table.remove_entry(self.task_requests, self.unload_request)
				self.unload_request = nil
			end
			
			self:ConnectToCommandCenters()
		else
			-- cancel demand request, interrupt drones, create supply request for the already stocked amount
			if self.export_requests and #self.export_requests > 0 then
				assert(#self.export_requests == 1)
				self:InterruptDrones(nil, function(drone)
													if (drone.target == self) or 
														(drone.d_request and drone.d_request:GetBuilding() == self) or
														(drone.s_request and drone.s_request:GetBuilding() == self) then
														return drone
													end
												end)
				
				self:DisconnectFromCommandCenters()
				-- create unload request, transfer the amount delivered, close the export request
				local amount = self:GetStoredExportResourceAmount()
				local unit_count = 1 + (self.max_export_storage / (const.ResourceScale * 10)) --1 per 10
				self.unload_request = self:AddSupplyRequest("PreciousMetals", amount, const.rfPostInQueue, unit_count)
				table.remove_entry(self.task_requests, self.export_requests[1])
				self.export_requests = nil
							
				self:ConnectToCommandCenters()
			end
		end
	end
	
	ObjModified(self)
end

function SupplyRocket:GetUIExportStatus()
	if self.allow_export then
		return T(286, "Gathering exports<right><preciousmetals(StoredExportResourceAmount, max_export_storage)>")
	elseif self:GetStoredExportResourceAmount() > 0 then
		return T(11470, "Unloading <right><preciousmetals(StoredExportResourceAmount, max_export_storage)>")
	end
end

function SupplyRocket:GetNumBoardedTourists()
	local count = 0
	for _, colonist in ipairs(self.boarded or empty_table) do
		if colonist.traits.Tourist then
			count = count + 1
		end
	end
	return count
end

function SupplyRocket:WaitingRefurbish()
	WaitWakeup()
end