GlobalVar("g_InitialRocketCargo", false)
GlobalVar("g_InitialCargoCost", 0)
GlobalVar("g_InitialCargoWeight", 0)
GlobalVar("g_InitialSessionSeed", false)

function ResetCargo()
	g_RocketCargo = false
	g_CargoCost = 0
	g_CargoWeight = 0
	g_CargoMode = false
end

if FirstLoad then
	ResetCargo()
end

DefineClass.RocketPayloadObject = {
	__parents = { "PropertyObject" },
	properties = {
		{ id = "prefabs", category = "Payload", name = T(1109, "Prefab Buildings"), editor = "payload", default = 0, submenu = true, },
		{ id = "colonists", category = "Payload", name = T(547, "Colonists"), editor = "payload", default = 0, submenu = true, },
		{ id = "vehicles", category = "Payload", name = T(13676, "RC Vehicles"), editor = "payload", default = 0, submenu = true, }
	},
	
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
	}
}

function RocketPayload_GetMeta(id)
	assert(#(ResupplyItemDefinitions or "") > 0)
	assert(type(id) == "string")
	return table.find_value(ResupplyItemDefinitions, "id", id)
end

function RocketPayload_GetCargo(id)
	return table.find_value(g_RocketCargo, "class", id)
end

function RocketPayload_GetAmount(id)
	local cargo = RocketPayload_GetCargo(id)
	return cargo and cargo.amount or 0
end

function RocketPayloadObject:GetProperties()
	local props = table.icopy(self.properties)
	table.iappend(props, ResupplyItemDefinitions)
	return props
end

function RocketPayloadObject:IsLocked(item_id)
	local def = RocketPayload_GetMeta(item_id)
	return def and def.locked
end

GlobalVar("g_ImportLocks", {})

--[[@@@
	Locks an item from the list of available imports. Once locked an item will no longer be visible in the resupply interface until unlocked.

	@function void Gameplay@LockImport(string item, string lock_id)
	@param string item - The name of the item to be locked.
	@param string lock_id - Lock id of the lock. For an item to be unlocked all unique locks must be removed.
	@result void
]]

function LockImport(item, lock_id)
	local locks = g_ImportLocks[item] or {}
	g_ImportLocks[item] = locks
	locks[lock_id] = true
end

--[[@@@
	Removes a lock or all locks from an import item. Unlocked item will appear normally in the resupply interface.

	@function void Gameplay@UnlockImport(string item[, string lock_id])
	@param string crop_name - The name of the item to be unlocked.
	@param string lock_id - Optional. Lock id of the lock. For an item to be unlocked all unique locks must be removed. If omitted all locks for the given item will be removed.
	@result void
]]
function UnlockImport(item, lock_id)
	if not lock_id then
		g_ImportLocks[item or false] = nil
	else
		local locks = g_ImportLocks[item or false]
		if locks then
			locks[lock_id] = nil
			if next(locks) == nil then
				g_ImportLocks[item or false] = nil
			end
		end
	end
end

function RocketPayloadObject:IsBlacklisted(prop_meta)
	local city = MainCity
	if prop_meta.id == "OrbitalProbe" and GameState.gameplay then
		local _, fully_scanned = UnexploredSectorsExist(city)
		return fully_scanned
	end
	
	if prop_meta.id == "Food" and IsGameRuleActive("Hunger") then
		return true
	end

	local blacklist_classes = city and city.launch_mode == "elevator" and {"Vehicle"}
	return blacklist_classes and IsKindOfClasses(g_Classes[prop_meta.id], blacklist_classes)
end

function RocketPayloadObject:IsImportLocked(prop_meta)
	return g_ImportLocks[prop_meta.id] and next(g_ImportLocks[prop_meta.id]) ~= nil
end

function RocketPayloadObject:IsBlacklistedSubmenu(prop_meta)
	return prop_meta.submenu and prop_meta.id == "vehicles" or prop_meta.id == "colonists"
end

function RocketPayloadObject:IsHidden(prop_meta)
	if prop_meta.submenu then return false end
	local def = RocketPayload_GetMeta(prop_meta.id)
	return def and def.hidden
end

function RocketPayload_CalcCargoWeightCost()
	g_CargoCost = 0
	g_CargoWeight = 0
	for k, item in ipairs(ResupplyItemDefinitions) do
		g_CargoCost = g_CargoCost + RocketPayload_GetTotalItemPrice(item)
		g_CargoWeight = g_CargoWeight + RocketPayload_GetTotalItemWeight(item)
	end
end

function RocketPayloadObject:SetItem(item_id, amount)
	local cargo = RocketPayload_GetCargo(item_id)
	cargo.amount = amount
	ObjModified(self)
end

function RocketPayloadObject:AddItem(item_id, ignore_funds, custom_pack_multiplier)
	custom_pack_multiplier = custom_pack_multiplier or 1
	local item = RocketPayload_GetMeta(item_id)
	if self:CanLoad(item, ignore_funds, custom_pack_multiplier) then
		local cargo = RocketPayload_GetCargo(item_id)
		if cargo then
			cargo.amount = cargo.amount + (item.pack * custom_pack_multiplier)
			ObjModified(self)
		end
	end
end

function RocketPayloadObject:RemoveItem(item_id, custom_pack_multiplier)
	custom_pack_multiplier = custom_pack_multiplier or 1
	local item = RocketPayload_GetMeta(item_id)
	if self:CanUnload(item) then
		local cargo = RocketPayload_GetCargo(item_id)
		if cargo then
			cargo.amount = Max(0, cargo.amount - (item.pack * custom_pack_multiplier))
			ObjModified(self)
		end
	end
end

function RocketPayloadObject:ClearItems()
	for k, item in ipairs(ResupplyItemDefinitions) do
		local cargo = RocketPayload_GetCargo(item.id)
		if cargo then
			cargo.amount = 0
		end
	end
	ObjModified(self)
end

function RocketPayloadObject:ClearCargoPriorities()
	for _,item in ipairs(ResupplyItemDefinitions) do
		self.object:SetCargoPriority(item.id, CargoPriority.Neutral)
	end
	for _,trait in sorted_pairs(TraitPresets) do
		self.object:SetCargoPriority(trait.id, CargoPriority.Neutral)
	end
	ObjModified(self)
end

function LaunchModeCargoExceeded(item)
end

function RocketPayloadObject:SetPayloadPriority(item_id, priority)
	self.object:SetCargoPriority(item_id, priority)
	self.object:CalculateOptimalPayload()
	ObjModified(self)
end

function RocketPayloadObject:GetPayloadPriority(item_id)
	return self.object:GetCargoPriority(item_id)
end

function RocketPayloadObject:GetCargoPriorities(items)
	local approved = 0
	local disapproved = 0
	for _,item in ipairs(items) do
		local prio = self:GetPayloadPriority(item.id)
		if prio == CargoPriority.disapprove then
			disapproved = disapproved + 1
		elseif prio == CargoPriority.approve then
			approved = approved + 1
		end
	end
	return approved, disapproved
end

function RocketPayloadObject:CanLoad(item, ignore_funds, custom_pack_multiplier)
	if LaunchModeCargoExceeded(item) then
		return false
	end
	if not item then return false end
	
	local cargo = RocketPayload_GetCargo(item.id)
	local loaded_amount = cargo and cargo.amount or 0
	local amount = custom_pack_multiplier or 1
	local enough_funds = ignore_funds or self:GetFunding() >= (RocketPayload_GetItemPrice(item) * amount)
	return loaded_amount < item.max and enough_funds and self:GetRemainingCapacity() >= (RocketPayload_GetItemWeight(item) * amount)
end

function RocketPayloadObject:CanUnload(item)
	return item and RocketPayload_GetAmount(item.id) > 0
end

function RocketPayloadObject:GetUsedCapacity()
	assert(g_RocketCargo)
	return g_CargoWeight
end

function RocketPayloadObject:GetTotalCapacity()
	assert(g_RocketCargo)
	if self.object and self.object:HasMember("GetCapacity") then
		return self.object:GetCapacity()
	else
		local city = MainCity
		local cargo = city and city:GetCargoCapacity() or GetMissionSponsor().cargo
		return cargo
	end
end

function RocketPayloadObject:GetRemainingCapacity()
	local remaining_capacity = self:GetTotalCapacity() - self:GetUsedCapacity()
	assert(remaining_capacity >= 0)
	return remaining_capacity
end

function RocketPayloadObject:GetFunding()
	assert(g_RocketCargo)
	local funding = UIColony and UIColony.funds:GetFunding() or GetSponsorModifiedFunding()*1000000
	return funding - g_CargoCost
end

function RocketPayloadObject:GetAvailableRockets()
	return g_UIAvailableRockets
end

function RocketPayloadObject:GetTotalRockets()
	return g_UITotalRockets
end

function RocketPayloadObject:GetRocketName()
	local name = g_RenameRocketObj:GetRocketHyperlink()
	return GetCargoSumTitle(name)
end

function RocketPayloadObject:RenameRocket(host)
	g_RenameRocketObj:RenameRocket(host, function() ObjModified(self) end)
end

function RocketPayloadObject:PassengerRocketDisabledRolloverTitle()
	if IsGameRuleActive("TheLastArk") then
		return T(972855831022, "The Last Ark")
	elseif not AreNewColonistsAccepted() then
		return T(10446, "Colonization Temporarily Suspended")
	else
		return T(1116, "Passenger Rocket")
	end
end

function RocketPayloadObject:PassengerRocketDisabledRolloverText()
	if IsGameRuleActive("TheLastArk") then
		return T(10447, "Can call a Passenger Rocket only once.")
	elseif not AreNewColonistsAccepted() then
		return T{8537, "<SponsorDisplayName> has to make sure the Colony is sustainable before allowing more Colonists to come to Mars. Make sure the Founders are supplied with Water, Oxygen, and Food for 10 Sols after they arrive on Mars.", SponsorDisplayName = GetMissionSponsor().display_name or ""}
	else
		return T(8538, "Rockets unavailable.")
	end
end

function RocketPayloadObject:GetPrefabsTitle()
	local name = T(4068, "PREFABS")
	return GetCargoSumTitle(name)
end

function RocketPayloadObject:GetRocketTypeTitle()
	local name = T(4067, "SELECT ROCKET")
	return GetCargoSumTitle(name)
end

function RocketPayloadObject:SetProperty(id, value)
	local cargo = RocketPayload_GetCargo(id)
	if cargo then
		cargo.amount = value
		return
	end
	return PropertyObject.SetProperty(self, id, value)
end

function RocketPayloadObject:GetProperty(id)
	local cargo = RocketPayload_GetCargo(id)
	if cargo then
		return cargo.amount
	end
	return PropertyObject.GetProperty(self, id)
end

function RocketPayloadObject:GetAmount(item)
	local amount = 0
	if item.submenu then
		if item.id == "prefabs" then
			amount = RocketPayload_GetPrefabsCount()
		elseif item.id == "vehicles" then
			amount = RocketPayload_GetVehiclesCount()
		elseif item.id == "colonists" then
			amount = self.traits_object:GetTotalApprovedSpecialists()
		end
	else
		amount = RocketPayload_GetAmount(item.id)
	end
	return amount
end

function RocketPayloadObject:GetDifficultyBonus()
	if g_TitleObj then
		return g_TitleObj:GetDifficultyBonus()
	end
	return ""
end

function RocketPayload_GetPrefabsCount()
	local prefab_count = 0
	for k, item in ipairs(ResupplyItemDefinitions) do
		if (not item.locked or item.group == "Refab") and BuildingTemplates[item.id] then
			prefab_count = prefab_count + RocketPayload_GetAmount(item.id)
		end
	end
	return prefab_count
end

function RocketPayload_GetVehiclesCount()
	local vehicle_count = 0
	for k, item in ipairs(ResupplyItemDefinitions) do
		if not item.locked and IsKindOf(g_Classes[item.id], "BaseRover") then
			vehicle_count = vehicle_count + RocketPayload_GetAmount(item.id)
		end
	end
	return vehicle_count
end

function RocketPayloadObject:GetPrice(item)
	local money
	if not item then
		money = RocketPayload_GetPrefabsPrice()
	else
		money = RocketPayload_GetTotalItemPrice(item)
	end
	return T{4075, "<funding(money)>", money = money}
end

function RocketPayloadObject:GetNumAvailablePods(label)
	local n = 0
	for _, pod in ipairs(MainCity.labels[label] or empty_table) do
		if pod:IsAvailable() then
			n = n + 1
		end
	end
	return n
end

function RocketPayloadObject:GetAvailableSupplyPods()
	return self:GetNumAvailablePods("SupplyPod")
end

function RocketPayloadObject:GetTotalSupplyPods()
	return table.count(MainCity.labels.SupplyPod or {})
end

function RocketPayloadObject:GetAvailablePassengerPods()
	return self:GetNumAvailablePods("PassengerPod")
end

function RefundPods(label)
	local list = MainCity.labels[label] or empty_table
	for i = #list, 1, -1 do
		if list[i].refund > 0 then
			DoneObject(list[i])
		end
	end
end

function RefundPassenger()
end

function RefundSupply()
	RefundPods("SupplyPod")
end

function RocketPayload_GetTotalItemPrice(item)
	return (RocketPayload_GetAmount(item.id) / item.pack) * RocketPayload_GetItemPrice(item)
end

function RocketPayload_GetItemPrice(item)
	local price = item.price
	local city = MainCity
	if city and city.launch_mode == "elevator" and #(city.labels.SpaceElevator or empty_table) > 0 then
		local price_mod = city.labels.SpaceElevator[1].price_mod
		price = MulDivRound(item.price, price_mod, 100)
	end
	
	local sponsor = GetMissionSponsor()
	if sponsor.WeightCostModifierGroup == item.group then
		price = MulDivRound(price, sponsor.CostModifierPercent, 100)
	end
	
	return price
end

function RocketPayload_GetTotalItemWeight(item)
	return (RocketPayload_GetAmount(item.id) / item.pack) * RocketPayload_GetItemWeight(item)
end

function RocketPayload_GetItemWeight(item)
	local weight = item.kg
	
	local sponsor = GetMissionSponsor()
	if sponsor.WeightCostModifierGroup == item.group then
		weight = MulDivRound(weight, sponsor.WeightModifierPercent, 100)
	end
	
	return weight
end

function RocketPayload_GetPrefabsPrice()
	local money = 0
	for k, item in ipairs(ResupplyItemDefinitions) do
		if BuildingTemplates[item.id] then
			money = money + RocketPayload_GetTotalItemPrice(item)
		end
	end
	return money
end

function RocketPayloadObject:GetRollover(id, custom_pack_multiplier)
	if self.prop_meta.submenu then
		return self.submenu_rollovers[id]
	end
	
	custom_pack_multiplier = custom_pack_multiplier or 1
	local item = RocketPayload_GetMeta(id)
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
	description = icon..description .. T{1114, "Weight: <value> kg<newline>Cost: <funding(cost)>", value = RocketPayload_GetItemWeight(item) * custom_pack_multiplier, cost = RocketPayload_GetItemPrice(item) * custom_pack_multiplier}
	return {
		title = display_name,
		descr = description,
		gamepad_hint = T(7580, "<DPadLeft> Change value <DPadRight>"),
	}
end

function RocketPayloadObject:GetPodItemText()
	local pod_class = GetMissionSponsor().pod_class
	local template = pod_class and BuildingTemplates[pod_class]
	local name = template and template.display_name or T(824938247285, "Supply Pod")
	
	if self:GetNumAvailablePods("SupplyPod") > 0 then
		return T(11439, "<new_in('gagarin')>") .. name
	end
	return T(11439, "<new_in('gagarin')>") .. T{10860, "<name> ($<cost> M)", name = name, cost = GetMissionSponsor().pod_price / (1000*1000)}
end

function RocketPayloadObjectCreate(context)
	g_RocketCargo = GetMissionInitialLoadout()
	RocketPayload_CalcCargoWeightCost()
	
	local traits_object = TraitsObjectCreateAndLoad()
	return RocketPayloadObject:new({object = context, traits_object = traits_object})
end

function RocketPayloadObjectCreateAndSetRequested(context)
	local payload = RocketPayloadObjectCreate(context)
	context:SetPayload(payload)
	RocketPayload_CalcCargoWeightCost()
	local has_requested_passengers = table.find_if(payload.traits_object.approved_per_trait or empty_table, function(v) return v > 0 end)
	if not has_requested_passengers and g_CargoWeight == 0 then
		context:SetDefaultPayload(payload)
		RocketPayload_CalcCargoWeightCost()
	end
	return payload
end

function RocketPayloadObjectCreateAndLoad(pregame)
	InitRocketRenameObject(pregame, true)
	if pregame then
		RocketPayload_Init()
	else
		g_RocketCargo = false
		g_CargoMode = false
	end
	if not g_RocketCargo then
		g_RocketCargo = GetMissionInitialLoadout(pregame)
		RocketPayload_CalcCargoWeightCost()
	end
	return RocketPayloadObject:new({object = false})
end

function ClearRocketCargo()
	g_RocketCargo = GetMissionInitialLoadout()
	RocketPayload_CalcCargoWeightCost()	
end
