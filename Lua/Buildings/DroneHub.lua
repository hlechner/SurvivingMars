DefineClass.DroneHub = {
	__parents = { "TaskRequester", "DroneControl", "ElectricityConsumer" },
	properties = {
		{ id = "service_area_min", name = "Min service area range", editor = "number", default = const.CommandCenterMinRadius, no_edit = true, modifiable = true, scale = 1, },
		{ id = "service_area_max", name = "Max service area range", editor = "number", default = const.CommandCenterDefaultRadius, no_edit = true, modifiable = true, scale = 1, },
	},
	
	building_update_time = 10000,
	work_radius = const.CommandCenterDefaultRadius,
	
	charging_stations = false,
	auto_connect_requesters_at_start = true,
	accept_requester_connects = true,
	
	play_working_anim_on_this_attach = "DroneHubAntenna",
	
	total_requested_drones = 0,
}

function DroneHub:Init()
	self.charging_stations = {}
end

function DroneHub:InitAttaches()
	AttachedRechargeStations.Init(self)
	
	local c = self:GetAttaches("CableHardLeft")
	local cm1, cm2, cm3, cm4 = GetCablesPalette()
	for i = 1, #(c or "") do
		c[i]:SetColorizationMaterial4(cm1, cm2, cm3, cm4)
	end
end

function DroneHub:OnSkinChanged(skin, palette)
	Building.OnSkinChanged(self, skin, palette)
	self:InitAttaches()
end

function DroneHub:GameInit()
	self:InitAttaches()
	self:GatherOrphanedDrones()
	self.work_radius = self.service_area_max
	self.UIWorkRadius = self.service_area_max
end

function DroneHub:Done()
	for _, station in ipairs(self.charging_stations) do
		DoneObject(station)
	end
end

function DroneHub:OnRefabricate()
	-- Destroy drones when refabbing
	local num_drones = self.starting_drones
	local found_drones = {}
	
	-- Prefer own drones
	while #found_drones < num_drones and #(self.drones or empty_table) > 0 do
		local drone = ExpeditionPickDroneFrom(self, found_drones)
		if not drone then
			break
		end
		table.insert(found_drones, drone)
	end
	-- Look in other command centers
	ExpeditionPickDrones(found_drones, num_drones, self.city)
	
	for _, drone in ipairs(found_drones) do
		drone:DespawnNow()
	end
	
	Building.OnRefabricate(self)
end

function DroneHub:OnSetWorking(working)
	if working then
		self:GatherOrphanedDrones()
		self:SetWaitingDronesIdle()
	end
	
	ElectricityConsumer.OnSetWorking(self, working)
	self:NotifyWorkingChanged(self.connected_task_requesters)
	
	AttachedRechargeStations.SetWorking(self.charging_stations, working)
end

function DroneHub:GetMaxDrones()
	return g_Consts.CommandCenterMaxDrones
end

function DroneHub:SpawnDrone()
	if #self.drones >= self:GetMaxDrones() then
		return false
	end
	local drone = self.city:CreateDrone()
	drone:SetHolder(self)
	drone:SetCommandCenter(self)
	return true
end

function DroneHub:GetSelectionRadiusScale()
	if not IsValid(self) and GetDefaultConstructionController().template_obj == self then
		return const.CommandCenterDefaultRadius + (UIColony:IsTechResearched("SignalBoosters") and const.SignalBoostersBuff or 0)
	else
		return self.work_radius
	end
end

function DroneHub:ShowUISectionConsumption()
	if self.city.colony:IsTechResearched("AutonomousHubs") then
		return false
	end	
	return Building.ShowUISectionConsumption(self)
end

function OnMsg.GatherFXActors(list)
	list[#list + 1] = "DroneHub"
end

function DroneHub:GetFreeConstructionSlotsForDrones()
	return self:GetMaxDrones() - self:GetDronesCount()
end

function DroneHub:GetUISectionDroneHubRollover()
	return table.concat({
		T{293, "Low Battery<right><drone(DischargedDronesCount)>", self},
		T{294, "Broken<right><drone(BrokenDronesCount)>", self},
		T{295, "Idle<right><drone(IdleDronesCount)>", self},
	}, "<newline><left>")
end

function DroneHub:ShouldShowAvailableDronePrefabInfo()
	return true
end

DroneHub.GetConstructDroneCost = DroneFactory.GetConstructDroneCost
DroneHub.GetConstructResource = DroneFactory.GetConstructResource

function DroneHub:GetDronesStatusText()
	if not self.working then
		return T(647, "<red>Not working. Drones won't receive further instructions.</red>")
	else
		return DroneControl.GetDronesStatusText(self)
	end
end

function DroneHub:GetFactoryNearby()
	if #(self.city.labels.DroneFactory or "") > 0 then
		local realm = GetRealm(self)
		local f = realm:MapFindNearest(self, self, g_Consts.DroneHubOrderDroneRange, "DroneFactory", function(o) return o.destroyed == false end)
		return f
	end
	
	return false
end

function DroneHub:OrderDroneConstructionAtClosestFactory()
	local f = self:GetFactoryNearby()
	
	if f then
		f:ConstructDrone(1, self)
		self.total_requested_drones = self.total_requested_drones + 1
		RebuildInfopanel(self)
	end
end

function DroneHub:OnDroneRemovedFromQueue()
	self.total_requested_drones = self.total_requested_drones - 1
	RebuildInfopanel(self)
end

function DroneHub:GetOrderedDronesCount()
	return T{8492, "Drones ordered: <num>", num = self.total_requested_drones}
end

function BulkObjModifiedInCityLabels(...)
	local lbls = table.pack(...)
	local city_labels = UICity.labels
	for i = 1, #lbls do
		local container = city_labels[lbls[i]] or empty_table
		for _, obj in ipairs(container) do
			ObjModified(obj)
		end
	end
end

function OnMsg.DepositsSpawned()
	if UICity then
		local arr = UICity.labels.DroneHub --template name label
		
		for i = 1, #(arr or empty_table) do
			if arr[i].are_requesters_connected then
				arr[i]:ReconnectTaskRequesters()
			else
				arr[i]:ConnectTaskRequesters()
			end
		end
	end
end

function DroneHub:CheatSpawnDrone()
	self:SpawnDrone()
end
