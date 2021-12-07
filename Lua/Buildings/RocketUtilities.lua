RocketTypeNames = {
	Passenger = T(1116, "Passenger Rocket"),
	Cargo = T(1115, "Cargo Rocket"),
	Trade = T(8029, "Trade Rocket"),
	Refugee = T(8123, "Refugee Rocket"),
	ForeignAid = T(11194, "Foreign Aid Rocket"),
	Lander = T(13616, "Asteroid Lander"),
	Fallback = T(1685, "Rocket"),
}

DefineClass.FXRocket = {
	__parents = { "SpawnFXObject" },
	entity = "Rocket",
}

function SavegameFixups.UnstuckStuckMaintenanceRockets()
	MapGet("map", "SupplyRocket", function(o)
				if o.command == "WaitMaintenance" and not o.auto_connect then
					--rem any connections
					o:ForceInterruptIncomingDrones()
					o:DisconnectFromCommandCenters()
					--reconnect proper
					CreateGameTimeThread(function(o)
						table.insert_unique(g_LandedRocketsInNeedOfFuel, o)
						o:StartDroneControl()
						o:OpenDoor()
					end, o)
				end
			end)
end

function SavegameFixups.RocketWaitLaunchOrder()
	CreateGameTimeThread(function()
		local list = UICity.labels.AllRockets or empty_table
		for _, rocket in ipairs(list) do
			if IsValid(rocket) and rocket.command == "WaitLaunchOrder" then
				rocket:SetCommand("WaitLaunchOrder")
			end
		end
	end)
end

function SavegameFixups.RemoveRocketsFromDomeStockpileLabels()
	MapForEach(true, "Dome", function(obj)
		local cont = obj.labels.ResourceStockpile
		for i = #(cont or ""), 1, -1 do
			if IsKindOf(cont[i], "SupplyRocket") then
				table.remove(cont, i)
			end
		end
	end)
end

function SavegameFixups.DropBrokenDrones()
	MapForEach("map", "SupplyRocket", function(obj)
		obj:DropBrokenDrones(obj.drones_exiting)
		obj:DropBrokenDrones(obj.drones_entering)
	end )
end

SavegameFixups.DropBrokenDronesAgain = SavegameFixups.DropBrokenDrones

-- msg / status updates

local function UpdateFlightPermissions(map_id)
	local city = Cities[map_id] or MainCity
	local rockets = city.labels.AllRockets or empty_table
	for _, rocket in ipairs(rockets) do		
		if rocket.command == "WaitInOrbit" then -- update status/trigger land for rockets in orbit
			rocket:UpdateStatus(rocket:IsFlightPermitted() and (rocket.landing_disabled and "landing disabled" or "in orbit") or "suspended in orbit")
			if rocket:IsLandAutomated() then
				rocket:SetCommand("LandOnMars", rocket.landing_site)
			end
		elseif rocket.waiting_resources then
			Wakeup(rocket.command_thread)
		end
	end
end

OnMsg.DustStorm = UpdateFlightPermissions
OnMsg.DustStormEnded = UpdateFlightPermissions

function OnMsg.ConstValueChanged(prop, old_value, new_value)
	if prop == "SupplyMissionsEnabled" then
		UpdateFlightPermissions()
	end		
end

function OnMsg.GatherLabels(labels)
	labels.AllRockets = true
end

function GetConstructionRocketEntity(rocket_class)
	local cls_str = rocket_class or GetRocketClass()
	local t = BuildingTemplates[cls_str]
	if t then
		return t.entity
	end
	local cls = g_Classes[cls_str]
	return cls:GetEntity()
end

function GetConstructionRocketPalette(rocket_class)
	local t = BuildingTemplates[rocket_class]
	local class_name = t and t.template_class or rocket_class
	local class = g_Classes[class_name]
	return class.rocket_palette
end

function GetConstructableRocketPalette(rocket_class)
	local cls_str = rocket_class or GetRocketClass()
	local palette = GetConstructionRocketPalette(cls_str)
	return GetAdjustedRocketPalette(GetConstructionRocketEntity(cls_str), palette, GetCurrentColonyColorScheme())
end

function GetAdjustedRocketPalette(rocket_entity, palette, ccs)
	ccs = ccs or GetCurrentColonyColorScheme()
	if (rocket_entity == "Rocket") and ccs.id == "default" then
		return {palette[2], palette[1], palette[3], palette[4]}
	end
	return palette
end

function SavegameFixups.RocketsAndSupplyPodsPins()
	CreateGameTimeThread(function()
		local list = UICity.labels.AllRockets
		if not list then return end
		for _, rocket in ipairs(list) do
			if IsValid(rocket) then
				rocket:SetPinned(rocket:ShouldBePinned())
			end
		end
	end)
end

function PrepareApplicantsForTravel(city, host, capacity)
	capacity = capacity or g_Consts.MaxColonistsPerRocket
	local free = GetAvailableResidences(city)
	local applicants = {}
	local approved = host.context.approved_applicants
	for _, applicant in ipairs(approved or empty_table) do
		applicants[#applicants + 1] = applicant
	end
	
	local filtered_applicants_count = Min(capacity, #applicants)
	local passengers_count = filtered_applicants_count
	if passengers_count <= 0 then
		local popup_id = "LaunchIssue_NoPassengers"
		if host.context:GetMatchingColonistsCount() <= 0 then popup_id = "LaunchIssue_NoMatchingApplicants" end
		local params = {
			choice1 = T(717, "Launch anyway"), 
			choice2 = T(718, "Abort"),
		}
		local res = WaitPopupNotification(popup_id, params, false, host)
		if res == 2 then
			return false
		end	
	end
	if free < filtered_applicants_count then
		local params = {
			number1 = filtered_applicants_count,
			number2 = free,
			choice1 = T(717, "Launch anyway"), 
			choice2 = (free > 0) and T{719, "Launch with <em><number></em> passengers", number = free} or T(718, "Abort"),
		}
		if free > 0 then
			params.choice3 = T(718, "Abort")
		end
		local res = WaitPopupNotification("LaunchIssue_Housing", params, false, host)
			
		if not res or (free <= 0 and res == 2) or res == 3 then
			return false
		elseif res == 2 then
			passengers_count = free
		end			
	end
	
--		cargo[1].amount = passengers_count
		--cargo[2].amount = MulDivRound(passengers_count, g_Consts.FoodPerRocketPassenger, const.ResourceScale)
		-- remove applicants from the pool
	local applicants_data = {}
	for i = 1, passengers_count do
		local idx = table.remove_entry(g_ApplicantPool,applicants[i])
		assert(idx)-- can not find applicant in applicants pool
		applicants_data[i] = applicants[i][1]
	end
	--cargo[1].applicants_data = applicants_data	
	return passengers_count, applicants_data
end

GlobalVar("g_LandedRocketsInNeedOfFuel", {})

function SavegameFixups.FixRocketsWaitingOnDisembarkedColonists()
	MapForEach("map", "SupplyRocket", function(o)
		if not IsKindOf(o, "RocketExpedition") and o.command == "Unload" then
			o:CheckDisembarkationTable()
		end
	end)
end

local rocket_on_gnd_cmd = {
	LandOnMars = true,
	Unload = true,
	Refuel = true,
	WaitLaunchOrder = true,
	Countdown = true,
	Takeoff = true,
	ExpeditionRefuelAndLoad = true,
}

DefineClass.RocketLandingSite = {
	__parents = { "Building" },
	
	disable_selection = true,
	default_label = false,
	landing_pad = false,
	SetSuspended = empty_func,
	snap_target_type = "LandingPad",
}

function RocketLandingSite:GameInit()
	local site_pos = self:GetPos()
	local q, r = WorldToHex(site_pos)
	local blds = GetObjectHexGrid(self):GetObjects(q, r)
	for _, bld in ipairs(blds) do
		if IsKindOf(bld, "LandingPad") or IsKindOf(bld, "TradePad") then
			self.landing_pad = bld
			break
		end
	end
end

function RocketLandingSite:SelectionPropagate()
	local rocket = GetLandingRocket(self)

	if rocket and rocket_on_gnd_cmd[rocket.command] then
		if IsValid(self.landing_pad) then
			return self.landing_pad
		end
		return rocket
	else
		if rocket and rocket.auto_export or not IsValid(self.landing_pad) then
			return rocket
		end
		return self.landing_pad
	end
end

function GetLandingRocket(site)
	local rockets = UICity.labels.AllRockets or ""
	for i = 1, #rockets do
		if rockets[i].landing_site == site and rockets[i]:GetEnumFlags(const.efSelectable) ~= 0 then
			return rockets[i]
		end
	end
end

function OnMsg.GatherSelectedObjectsOnHexGrid(q, r, objects)
	local site = GetActiveObjectHexGrid():GetObject(q, r, "RocketLandingSite")
	local rocket = site and GetLandingRocket(site)
	if rocket then
		table.insert_unique(objects, rocket)
	end
end

DefineClass.LandingPad = {
	__parents = { "Building" },
	rocket_construction = false,
	SetSuspended = empty_func,
}

function LandingPad:GameInit()
	local obj = self:GetAttach("DecRocketLandingPlatform")
	obj:SetAttachOffset(point(0, 0, 1000))
end

function LandingPad:SnappedObjectPlaced(building)
	if IsKindOf(building, "ConstructionSite") then
		self.rocket_construction = building
	end
end

function LandingPad:InitConstruction(site)
	site:DestroyAttaches("DecRocketLandingPlatform")
	AttachToObject(site, "DecRocketLandingPlatformBuild", "Pad")
end

function LandingPad:OnDemolish()
	Building.OnDemolish(self)
	RemovePadFromLandingSite(self)
end

function LandingPad:CanSnapTo()
	return not self:HasRocket()
end

function LandingPad:HasRocket()
	if self.rocket_construction then
		return self.rocket_construction
	end
	local rockets = UICity.labels.AllRockets or empty_table
	for _, rocket in ipairs(rockets) do
		if rocket.landing_site and rocket.landing_site.landing_pad == self and (rocket_on_gnd_cmd[rocket.command] or rocket:IsLandAutomated()) then
			return true, rocket
		end
	end
	return false
end

function LandingPad:CanDemolish()
	if self:HasRocket() then
		return false
	end
	
	return Building.CanDemolish(self)
end

function LandingPad:IsAvailable()
	return not self:HasRocket()
end

function LandingPad:CanRefab()
	return self:IsAvailable() and Building.CanRefab(self)
end

function LandingPad:SelectionPropagate()
	local _, rocket = self:HasRocket()
	if rocket and not rocket_on_gnd_cmd[rocket.command] and rocket.auto_export then
		return rocket
	end
	return self
end

function RocketsComboItems()
	local items = {}
	for id, item in pairs(BuildingTemplates) do
		local class = g_Classes[item.template_class]
		if IsKindOf(class, "RocketBase") and item.sponsor_selectable and not IsKindOf(class, "SupplyPod") then
			items[#items + 1] = { value = id, text = item.display_name }
		end
	end
	return items
end

function PodsComboItems()
	local items = { {value = false, text = ""} }
	for id, item in pairs(BuildingTemplates) do
		local class = g_Classes[item.template_class]
		if IsKindOf(class, "SupplyPod") and item.sponsor_selectable then
			items[#items + 1] = { value = id, text = item.display_name }
		end
	end
	return items
end

function GetRocketClass()
	return GetMissionSponsor().rocket_class or "SupplyRocket"
end

function GetRocketPassengers(context)
	local colonists = table.icopy(context.colonists) or empty_table
	for i = #colonists, 1, -1 do
		local colonist = colonists[i]
		if FilterColonistByTrait(colonist, context["trait_Age Group"]) or
			FilterColonistByTrait(colonist, context["trait_Negative"]) or
			FilterColonistByTrait(colonist, context["trait_Specialization"]) or
			FilterColonistByTrait(colonist, context["trait_other"]) or
			FilterColonistByTrait(colonist, context["trait_Positive"]) or
			context["trait_interest"] and not table.find(GetInterests(colonist), context["trait_interest"].id)
		then
			table.remove(colonists, i)
		end
	end
	colonists = SortColonistTable(context, colonists)
	return colonists
end

--Hint about sending another rocket from earth at sol 9
GlobalVar("SuggestedResupplyMissionPopupThread", false)

-- minus one, because we start at sol 1
local SuggestedResupplyMissionPopupDelay = const.DayDuration*(9 - 1) - const.HourDuration*3

local function CheckSuggestedResupplyMissionPopupConditions()
	local city = UICity
	
	--check if there's enough funding
	if UIColony.funds.funding < 500000000 then --$500m
		return false
	end

	return true
end

local function StartSuggestedResupplyMissionPopupThread(delay)
	if not g_Tutorial then
		SuggestedResupplyMissionPopupThread = CreateGameTimeThread(function(delay)
			Sleep(delay or SuggestedResupplyMissionPopupDelay)
			while true do
				if CheckSuggestedResupplyMissionPopupConditions() then
					local gamepad = GetUIStyleGamepad()
					ShowPopupNotification("SuggestedResupplyMission", { gamepad = gamepad, kbmouse = not gamepad })
					return
				else
					Sleep(const.DayDuration)
				end
			end
		end, delay)
	end
end

function RemovePadFromLandingSite(pad)
	local rockets = UICity.labels.AllRockets or empty_table
	for _, rocket in ipairs(rockets) do
		if rocket.landing_site and rocket.landing_site.landing_pad == pad then
			rocket.landing_site.landing_pad = nil
		end
	end
end

function OnMsg.LoadGame()
	if not SuggestedResupplyMissionPopupThread then
		local day = const.DayDuration
		local delay = SuggestedResupplyMissionPopupDelay - GameTime()
		if delay > 0 then
			StartSuggestedResupplyMissionPopupThread(delay)
		end
	end
end

function OnMsg.CityStart()
	StartSuggestedResupplyMissionPopupThread()
end

function OnMsg.RocketLaunchFromEarth(rocket)
	if rocket.flight_time > 0 and IsValidThread(SuggestedResupplyMissionPopupThread) then
		DeleteThread(SuggestedResupplyMissionPopupThread)
		RemoveOnScreenNotification("popupSuggestedResupplyMission")
	end
end

DefineClass.RocketCargoItem = {
	__parents = { "PropertyObject" },
	properties = {
		{ id = "cargo", name = T(11220, "Cargo"), editor = "dropdownlist", items = PresetsCombo("Cargo"), default = "" },
		{ id = "amount", name = T(1000100, "Amount"), editor = "number", default = 0, min = 0 },
	},
}

DefineStoryBitTrigger("RocketLaunchedEvent", "RocketLaunchedEvent")
function OnMsg.RocketLaunched(rocket)
	Msg("RocketLaunchedEvent", rocket)
end

----

function dbg_ToggleRocketInstantTravel()
	config.RocketInstantTravel = not config.RocketInstantTravel
	if config.RocketInstantTravel then
		Msg("RocketInstantTravel")
	end
	print("Rocket Instant Travel:", config.RocketInstantTravel)
end

if Platform.developer then

local function FixRockets()
	if not string.match(GetMap(), "Maps/POCMap_") then return end
	local rockets = MainCity.labels.AllRockets or {}
	for _, rocket in ipairs(rockets) do
		local state = rocket:GetState()
		rocket:SetState("idle")
		rocket:SetState(state)
	end
end

OnMsg.GameTimeStart = FixRockets
OnMsg.LoadGame = FixRockets

end
