GlobalVar("ConstructionCounter", 0)

DefineClass.ConstructionSite = {
	__parents = { "Building" },
	properties = {
		{ id = "BuildingClass", editor = "text", default = false, no_edit = true },
	},
	flags = { cfNoHeightSurfs = true, cofComponentCustomData = true, gofUnderConstruction = true, efSelectable = true, efWalkable = false},
	display_name = T(606, "Construction Site"),
	building_class = false,
	building_update_time = 5*1000,
	
	construction_resources = false,
	rebuild = false,
	construct_request = false,
	construction_started = false,
	
	on_complete_functor = false, --called after building is placed with both construction site and building alive
	building_class_proto = false, --class definition of the object being constructed.
	forced_entity = false, --force the entity of the construction site
	alternative_entity_t = false,
	construction_bbox = false, -- keeps a bbox needed for construction visualization
	use_demolished_state = false,
	
	supplied = false,
	prefab = false,
	dont_consume_prefab = false,
	
	construction_group = false, --a group of construction sites, only the construction group leader adds requests, all sites are completed together.
	can_complete_during_init = true,
	clean_cables_on_place = true, --when placing the building, will clean cables underneath it, for construction site -> building combos that do no share a shape.
	construction_costs_at_start = false, --for ui, since requests don't keep total and total may change due to modifiers.
	
	waste_rocks_underneath = false, --should be passed by construction controller.
	stockpiles_underneath = false,
	
	place_stockpile = true,
	resource_stockpile = false,
	resource_stockpile_spot = "Construction",
	
	fx_actor_base_class = "ConstructionSite",
	
	accumulate_dust = false,
	maintenance_resource_type = "no_maintenance", --doesn't require maintenance.
	accumulate_maintenance_points = false,
	
	auto_connect = false,
	UpdateAttachedSigns = empty_func,
	
	auto_construct_ts = false,
	combo_reqs = false,
	
	pin_progress_value = "ConstructedBuildPoints",
	pin_progress_max = "BuildPoints",
	
	labels_applied = false, --helper
	nanite_thread = false,
	last_nanite_tick = false, --for setworking spam
	
	dome_skin = false,
	SetSuspended = empty_func,
	is_locked_by_story_bit = false,
	
	use_control_construction_logic = true,
	
	orig_terrain1 = false,
	orig_terrain2 = false,
	construction_data = false,
	prefab_objects = false,
	
	snapped_to = false,
}

function ConstructionSite:GetFrameEntity()
	if IsKindOf(self.building_class_proto, "SpireBase") then
		return SpireBase.GetFrameEntity(self, self.building_class_proto)
	else
		return "none"
	end
end

local function nanite_class_filter(o)
	return not IsKindOfClasses(o, "SharedStorageBaseVisualOnly", "Unit", "SpaceElevator", "SupplyPod")
end

function ConstructionSite:CanWorkInTurnedOffDome()
	return true
end

function ConstructionSite:RestartNaniteThread()
	if IsValidThread(self.nanite_thread) then
		DeleteThread(self.nanite_thread)
	end
	self:StartNaniteThread()
end

function dbg_ResetAllNaniteThreads()
	MapForEach(true, "ConstructionSite", ConstructionSite.RestartNaniteThread)
end

SavegameFixups.ResetNaniteThreads = dbg_ResetAllNaniteThreads

function ConstructionSite:StopNaniteThread()
	if IsValidThread(self.nanite_thread) then
		DeleteThread(self.nanite_thread)
	end
	self.nanite_thread = nil
end

function ConstructionSite:StartNaniteThread()
	if not g_ConstructionNanitesResearched then return end
	
	self:AttachSign(false, "SignNoCommandCenter")
	
	if IsValidThread(self.nanite_thread) then return end
	if self.construction_group and self.construction_group[1] ~= self then return end --only group leader
	self:DestroyWasteRockUnderneath()
	self:MoveStockpilesUnderneathOutside()
	self:TestBlockerClearenceProgress()
	if not self:IsWaitingResources() then return end --off during blockers, on after blockers, off when resources are collected
	if not self.working then return end
	self.nanite_thread = CreateGameTimeThread(function(self, class_f)
		local stockpile = self.resource_stockpile
		while IsValid(self) and self:IsWaitingResources() do
			local required_resources = {}
			if not self.last_nanite_tick or GameTime() - self.last_nanite_tick >= g_Consts.ConstructionNanitesTimeDelta then
				for resource, request in pairs(self.construction_resources or empty_table) do
					if request:GetTargetAmount() > 0 then
						table.insert(required_resources, resource)
					end
				end
				if #required_resources <= 0 then return end
				local request = false
				local nanite_func = function(o)
					if class_f(o) then
						for i = 1, #required_resources do
							local r = required_resources[i]
							if type(o.resource) == "table" then
								local req = o.supply[r]
								if req and req:GetTargetAmount() >= const.ResourceScale then
									request = req
									return "break"
								end
							elseif o.resource == r then
								local req = o.supply_request
								if req and req:GetTargetAmount() >= const.ResourceScale then
									request = req
									return "break"
								end
							end
						end
					end
					return false
				end

				local realm = GetRealm(self)
				realm:MapForEach(self, "hex", 30, "ResourceStockpileBase", nanite_func)
				if request then
					local resource = request:GetResource()
					local my_req = self.construction_resources[resource]
					local amount = Min(const.ResourceScale, my_req:GetTargetAmount())
					amount = Min(amount, request:GetTargetAmount())
					
					my_req:AddAmount(-amount)
					request:AddAmount(-amount)
					local bld = request:GetBuilding()
					if bld:HasMember("DroneLoadResource") then
						bld:DroneLoadResource(nil, request, resource, amount, true)
					end
					
					if stockpile then
						if stockpile.initialized then
							stockpile:AddResource(amount, resource)
						else
							stockpile.init_with_amount = stockpile.init_with_amount or {}
							stockpile.init_with_amount[resource] = (stockpile.init_with_amount[resource] or 0) + amount
						end
					end
					
					if my_req:GetActualAmount() <= 0 then
						self:StartConstructionPhase()
					end
				end
			end
			self.last_nanite_tick = GameTime()
			Sleep(g_Consts.ConstructionNanitesTimeDelta)
		end
	end, self, nanite_class_filter)
end

--suffix added to bld labels so that construction sites end up in separate containers from constructed blds
g_ConstructionSiteLabelSuffix = "_Construction"

function ConstructionSite:SetCustomLabels(obj, add)
	--apply bld's custom labels, with the construction suffix
	local i = 1
	local class = self.building_class_proto
	while true do
		local lbl_id = "label"..i
		if not class:HasMember(lbl_id) then break end
		if class[lbl_id] ~= "" then
			local lbl_str = class[lbl_id] .. g_ConstructionSiteLabelSuffix
			if add then
				obj:AddToLabel(lbl_str, self)
			else
				obj:RemoveFromLabel(lbl_str, self)
			end
		end
		i = i + 1
	end
end

function ConstructionSite:AddToCityLabels()
	Building.AddToCityLabels(self) --add to whatever lbls we usually add ourselves to
	--also add construction suffix template class lbls
	local suffix = g_ConstructionSiteLabelSuffix
	local classdef = self.building_class_proto
	local template_name = IsKindOf(classdef, "ClassTemplate") and classdef.template_name or ""
	if template_name ~= "" then
		self.city:AddToLabel(template_name .. suffix, self)
		if classdef:HasMember("build_category") and classdef.build_category then
			self.city:AddToLabel(classdef.build_category .. suffix, self)
		end
	end
	if classdef.class ~= template_name then
		self.city:AddToLabel(classdef.class .. suffix, self)
	end
	self.labels_applied = true
end

function ConstructionSite:RemoveFromCityLabels()
	Building.RemoveFromCityLabels(self) --add to whatever lbls we usually add ourselves to

	local suffix = g_ConstructionSiteLabelSuffix
	local classdef = self.building_class_proto
	local template_name = IsKindOf(classdef, "ClassTemplate") and classdef.template_name or ""
	if template_name ~= "" then
		self.city:RemoveFromLabel(template_name .. suffix, self)
		if classdef:HasMember("build_category") and classdef.build_category then
			self.city:RemoveFromLabel(classdef.build_category .. suffix, self)
		end
	end
	if classdef.class ~= template_name then
		self.city:RemoveFromLabel(classdef.class .. suffix, self)
	end
	self.labels_applied = false
end


function GetCityLabelsForClassAndTemplate(template, class)
	--returns a map with all city labels that this building will add itself to in its lifetime
	--note, that the construction site will be in some of these and the building itself will be in others
	class = class or template.template_class ~= "" and ClassTemplates.Building[template.template_class] or g_Classes.Building
	local ret = {}
	if class.default_label then
		ret[class.default_label] = true
	end
	if template.id then
		ret[template.id] = true
		ret[template.id .. g_ConstructionSiteLabelSuffix] = true
	end
	if class.class ~= template.id then
		ret[class.class] = true
		ret[class.class .. g_ConstructionSiteLabelSuffix] = true
	end
	if template.build_category then
		ret[template.build_category] = true
		ret[template.build_category .. g_ConstructionSiteLabelSuffix] = true
	end
	
	if not IsKindOf(class, "Dome") and class.default_label == "Building" then
		ret["BuildingNoDomes"] = true
	end
	
	local i = 1
	while true do
		local lbl_id = "label"..i
		if not template:HasMember(lbl_id) then break end
		if template[lbl_id] ~= "" then
			ret[template[lbl_id]] = true
			ret[template[lbl_id] .. g_ConstructionSiteLabelSuffix] = true
		end
		i = i + 1
	end
	
	return ret
end

function GetModifierObject(template)
	--returns a fake modifier object that holds all modifiers of the template's potential labels
	--and can be used to modify costs appropriately
	--note, this gets all potential labels, hence it will get both construction site labels and bld labels, which means that any duplicate mods in those groups will get doubled.
	if type(template) == "string" then template = BuildingTemplates[template] end
	if not template then return end --some buildings don't have templates - such as cables and pipes
	local predicted_labels = GetCityLabelsForClassAndTemplate(template)
	local modifications = {}
	for lbl, _ in pairs(predicted_labels) do
		local modifiers = UICity.label_modifiers[lbl]
		if modifiers then
			for id, mod in pairs(modifiers) do
				--gather all modifiers that would potentially affect this building
				local prop = mod.prop
				local modification = modifications[prop]
				if not modification then
					modification = { amount = 0, percent = 100 }
					modifications[prop] = modification
				end
				modification.amount = (modification.amount or 0) + mod.amount
				modification.percent = (modification.percent or 100) + mod.percent
			end
		end
	end
	
	return Modifiable:new{modifications = modifications} --use this to modify cost values
end

function ConstructionSite:GetBroadcastLabel()
	local t = BuildingTemplates[self.building_class]
	if t then
		return t.id .. g_ConstructionSiteLabelSuffix
	end
	return Building.GetBroadcastLabel(self)
end

function ConstructionSite:OnSetWorking(working)
	self.auto_connect = working and self:IsBlockerClearenceComplete() or false
	
	if working then
		self:ConnectToCommandCenters()
	else
		if self.construction_resources then
			self:InterruptDrones(nil, function(drone) if drone.d_request and self.construction_resources[drone.d_request:GetResource()] == drone.d_request then return drone end end)
		end
		self:DisconnectFromCommandCenters()
	end
	
	if g_ConstructionNanitesResearched then
		if working then
			self:StartNaniteThread()
		else
			self:StopNaniteThread()
		end
	end
end

function ConstructionSite:ToggleWorking_Update(button)
	button:SetRolloverText(T(619, "Construction sites that are turned off are not serviced.<newline><newline>Current status: <em><UIWorkingStatus></em>"))
	Building.ToggleWorking_Update(self, button)
end

function ConstructionSite:GetBuildingClass()
	return self.building_class
end

function ConstructionSite:SetBuildingClass(building_class)
	self.building_class = building_class
	local class = ClassTemplates.Building[building_class] or g_Classes[building_class]
	ConstructionCounter = ConstructionCounter + 1
	self.counter = ConstructionCounter
	self.building_class_proto = class
	self.shape = class.shape
	self.display_name = class.display_name
	self.display_name_pl = class.display_name_pl
	self.is_tall = class.is_tall
	self.rename_allowed = class.rename_allowed
	if class:HasMember("can_demolish") then --no member, stay default, which is true
		self.can_demolish = class.can_demolish
	end
	if class:HasMember("use_shape_selection") then
		self.use_shape_selection = class.use_shape_selection
	end
	self:SetConstructionSiteEntity()
end

function ConstructionSite:HasMember(member)
	if member == "GetSelectionRadiusScale" then
		return self.building_class_proto:HasMember("GetSelectionRadiusScale")
	else
		return Building.HasMember(self, member)
	end
end

function ConstructionSite:GetSelectionRadiusScale()
	return self.building_class_proto:GetSelectionRadiusScale()
end

function ConstructionSite:ApplyToGrids()
	Building.ApplyToGrids(self)
	local interior = GetEntityInteriorShape(self:GetEntity())
	if interior and next(interior) then --apply to build grid, so user cant place buildings over the dome construction
		local object_hex_grid = GetObjectHexGrid(self)
		HexGridShapeAddObject(object_hex_grid.grid, self, interior)
	end
end

function ConstructionSite:RemoveFromGrids()
	Building.RemoveFromGrids(self)
	local interior = GetEntityInteriorShape(self:GetEntity())
	if interior and next(interior) then
		local object_hex_grid = GetObjectHexGrid(self)
		HexGridShapeRemoveObject(object_hex_grid.grid, self, interior)
	end
end

function ConstructionSite:AppendWasteRockObstructors(arr)
	if arr and #arr > 0 then
		if not self.stockpiles_underneath then
			--initialize in "waiting to clear state"
			self:ClearHierarchyEnumFlags(const.efApplyToGrids)
			local construction_group = self.construction_group
			local construction1 = construction_group and construction_group[1]
			if construction1 and construction1.auto_connect then
				construction1:DisconnectFromCommandCenters() --if we are addding to an existing group, it may already be connected.
				construction1:SetAutoConnect(false) --mark leader so it doesn't connect with empty requests
			end
		end
		
		self.waste_rocks_underneath = self.waste_rocks_underneath or {}
		self.stockpiles_underneath = self.stockpiles_underneath or {}

		local waste_rocks_underneath = self.waste_rocks_underneath
		for i = 1, #arr do
			local stock = arr[i]
			if not stock:GetParent() --waste rock used by artists as a part of a bld
				and not rawget(stock, "not_wasterock") then --waste rock used by lvl designers as part of bld
				stock:Activate(self.priority, self) --send out work requests
				waste_rocks_underneath[#waste_rocks_underneath + 1] = stock
			end
		end
	end
end

function ConstructionSite:AppendStockpilesUnderneath(arr)
	if arr and #arr > 0 then
		local needs_init = not self.stockpiles_underneath
		
		local construction_resources
		if self.construction_group and self.construction_group[1] ~= self then
			self.construction_group[1]:GatherConstructionResources()
			construction_resources = self.construction_group[1].construction_resources
		else
			self:GatherConstructionResources() --init building cost.
			construction_resources = self.construction_resources
		end
		
		self.stockpiles_underneath = self.stockpiles_underneath or {}
		
		for i = 1, #arr do
			local stock = arr[i]
			if stock:GetStoredAmount() <= 0 then
				if IsValid(stock) then
					DoneObject(stock)
				end
			else
				for r_n, d_req in pairs(construction_resources) do
					if d_req:GetActualAmount() > 0 and stock.resource == r_n then
						local a = Min(d_req:GetActualAmount(), stock:GetStoredAmount(r_n))
						stock:AddResource(-a, r_n)
						d_req:AddAmount(-a)
						break
					end
				end
				
				if IsValid(stock) then --if we took all resources from the stockpile, it's dead.
					stock:InitUnderConstruction(self)
					self.stockpiles_underneath[#self.stockpiles_underneath + 1] = stock
				end
			end
		end
		
		needs_init = needs_init and #self.stockpiles_underneath > 0
		
		if needs_init then
			--initialize in "waiting to clear state"
			self:ClearHierarchyEnumFlags(const.efApplyToGrids)
			if self.construction_group and self.construction_group[1].auto_connect then
				self.construction_group[1]:DisconnectFromCommandCenters() --if we are addding to an existing group, it may already be connected.
				self.construction_group[1]:SetAutoConnect(false) --mark leader so it doesn't connect with empty requests
			end
		elseif self:GetEnumFlags(const.efApplyToGrids) == 0 and self:IsBlockerClearenceComplete() then
			--we were created with no block pass due to stockpiles, but we consumed them all.
			self:SetHierarchyEnumFlags(const.efApplyToGrids)
		end
	end
end

function ConstructionSite:SetHierarchyEnumFlags(flags)
	Object.SetHierarchyEnumFlags(self, flags)
	if self.prefab_objects then
		local t = self.prefab_objects
		for i = 1, #t do
			t[i]:SetHierarchyEnumFlags(flags)
		end
	end
end

function ConstructionSite:ClearHierarchyEnumFlags(flags)
	Object.ClearHierarchyEnumFlags(self, flags)
	if self.prefab_objects then
		local t = self.prefab_objects
		for i = 1, #t do
			t[i]:ClearHierarchyEnumFlags(flags)
		end
	end
end

function ConstructionSite:CleanupWasteRockObstructors()
	if not self:IsBlockerClearenceComplete() then
		local construction_group = self.construction_group
		local waste_rocks_underneath = self.waste_rocks_underneath
		if waste_rocks_underneath then
			local selected = selected_construction_site and
				(self == selected_construction_site or table.find(construction_group, selected_construction_site))
			for i = 1, #waste_rocks_underneath do
				local o = waste_rocks_underneath[i]
				if IsValid(o) then
					o:Deactivate(self)
					if selected then
						o:ClearGameFlags(const.gofWhiteColored)
					end
				end
			end
		end
		local stockpiles_underneath = self.stockpiles_underneath
		if stockpiles_underneath then
			for i = 1, #stockpiles_underneath do
				local o = stockpiles_underneath[i]
				local parent_construction = o.parent_construction
				table.remove_entry(parent_construction, self)
				if #parent_construction <= 0 then
					o.parent_construction = false
				end
				o:OnConstructionCanceled()
			end
		end
		self.waste_rocks_underneath = false
		self.stockpiles_underneath = false
	end
end

if FirstLoad then
	ws_clearence_test_callers_list = false
	selected_construction_site = false
end

local function DelayedBlockerClearenceTest()
	for k, v in pairs(ws_clearence_test_callers_list or empty_table) do
		if IsValid(k) then
			k:TestBlockerClearenceProgress()
		end
	end
	
	ws_clearence_test_callers_list = false
end

function ConstructionSite:OnWasteRockObstructorCleared(obstr, stock)
	table.remove_entry(self.waste_rocks_underneath, obstr)
	if stock then
		self.stockpiles_underneath[#self.stockpiles_underneath + 1] = stock
	end
	
	ws_clearence_test_callers_list = ws_clearence_test_callers_list or {}
	ws_clearence_test_callers_list[self] = true
	DelayedCall(0, DelayedBlockerClearenceTest)
end

function ConstructionSite:OnBlockingStockpileCleared(obstr)
	table.remove_entry(self.stockpiles_underneath, obstr)
	ws_clearence_test_callers_list = ws_clearence_test_callers_list or {}
	ws_clearence_test_callers_list[self] = true
	DelayedCall(0, DelayedBlockerClearenceTest)
end

function ConstructionSite:TintWasteRockObstructors(set)
	if self.construction_group then
		self.construction_group[1]:TintWasteRockObstructors(set)
	else
		local c = #(self.waste_rocks_underneath or "")
		if c > 0 then
			if set then
				for i = 1, c do
					local ws = self.waste_rocks_underneath[i]
					ws:SetGameFlags(const.gofWhiteColored)
				end
			else
				for i = 1, c do
					local ws = self.waste_rocks_underneath[i]
					ws:ClearGameFlags(const.gofWhiteColored)
				end
			end
		end
	end
end

function OnMsg.SelectionChange()
	if IsValid(selected_construction_site) then
		selected_construction_site:TintWasteRockObstructors(false)
	end
	
	selected_construction_site = IsKindOf(SelectedObj, "ConstructionSite") and SelectedObj or false
	
	if selected_construction_site then
		selected_construction_site:TintWasteRockObstructors(true)
	end
end

function OnMsg.SelectionAdded(obj)
	if IsKindOf(obj, "ConstructionSite") then
		PlayFX("Select", "start", obj, obj.building_class)
	end
end

function OnMsg.SelectionRemoved(obj)
	if IsKindOf(obj, "ConstructionSite") then
		PlayFX("Select", "end", obj, obj.building_class)
	end
end

function ConstructionSite:TestBlockerClearenceProgress()
	local obj = self.construction_group and self.construction_group[1] or self
	if obj:IsBlockerClearenceComplete() then
		obj:OnBlockerClearenceComplete()
	end
end

function ConstructionSite:UpdateNotWorkingBuildingsNotification()
end

function ConstructionSite:IsBlockerClearenceComplete(ignore_group)
	if not ignore_group and self.construction_group and self.construction_group[1] ~= self then
		return self.construction_group[1]:IsBlockerClearenceComplete()
	end
	
	local stockpiles_underneath = self.stockpiles_underneath
	if stockpiles_underneath and #stockpiles_underneath > 0 then
		return false
	end
	local waste_rocks_underneath = self.waste_rocks_underneath
	if waste_rocks_underneath and #waste_rocks_underneath > 0 then
		return false
	end
	return true
end

function ConstructionSite:IsBlockerClearenceCompleteUIOnly()
	local construction_group = self.construction_group
	local construction1 = construction_group and construction_group[1]
	if construction1 and construction1 ~= self then
		return construction1:IsBlockerClearenceComplete()
	end
	return self:IsBlockerClearenceComplete()
end

function ConstructionSite:PickEntity()
	if self.forced_entity then
		return self.forced_entity
	end
	local class = self.building_class_proto
	if self.dome_skin and self.dome_skin.construction_entity then
		return self.dome_skin.construction_entity
	end
	if class.construction_entity then 
		return class.construction_entity 
	end
	if self.alternative_entity_t then
		if self.alternative_entity_t.palette then
			return self.alternative_entity_t.entity, DecodePalette(self.alternative_entity_t.palette)
		else
			return self.alternative_entity_t.entity
		end
	end
	return class.entity
end

function ConstructionSite:SetConstructionSiteEntity()
	local entity, cm1, cm2, cm3, cm4 = self:PickEntity()
	self:ChangeEntity(entity)
	AttachDoors(self, entity)
	if IsKindOf(self.building_class_proto, "RocketBuildingBase") then
		if self:HasSpot("Rocket") then
			local rocket_class = self.building_class_proto.construction_rocket_class
			local e = GetConstructionRocketEntity(rocket_class)
			local a = PlaceObjectIn("Shapeshifter", self:GetMapID())
			a:ChangeEntity(e)
			self:Attach(a, self:GetSpotBeginIndex("Rocket"))
			cm1, cm2, cm3, cm4 = DecodePalette(GetConstructableRocketPalette(rocket_class))
		end
	end
	if not cm1 then
		cm1, cm2, cm3, cm4 = GetBuildingColors(GetCurrentColonyColorScheme(), self.building_class_proto)
	end
	if cm1 then
		CreateGameTimeThread(Building.SetPalette, self, cm1, cm2, cm3, cm4)
	end
end

function ConstructionSite:GatherConstructionResources()
	if self.construction_group and self.construction_group[1] ~= self then return end --only main guy from the group distributes requests
	if self.construction_resources then return end --already created.

	self.construction_resources = {}
	self.construction_costs_at_start = {}

	if not self.supplied and not IsGameRuleActive("FreeConstruction") then -- Buildings don't require resources to be constructed with Free Construction rule
		local mod_o = self.labels_applied and self or GetModifierObject(self.building_class) or self

		for _, resource in ipairs(ConstructionResourceList) do
			local amount = self:GetConstructionCost(resource, mod_o)
			if amount > 0 then
				if self.rebuild then
					local modifier = g_Consts.rebuild_cost_modifier
					amount = MulDivRound(amount, modifier, 100)
				end
				self.construction_resources[resource] = self:AddDemandRequest(resource, amount, const.rfConstruction)
				self.construction_costs_at_start[resource] = amount
			end
		end
	end
	if self.prefab and not self.dont_consume_prefab then
		assert(self.city:GetPrefabs(self.building_class) > 0)
		self.city:AddPrefabs(self.building_class, -1)
	end
	local drones_requested = Clamp(self:GetConstructionCost("build_points") / 1000, 1, 10)
	self.construct_request = self:AddWorkRequest("construct", 0, 0, drones_requested)
end

function ConstructionSite:RefreshConstructionResources()
	if not self.supplied and not IsGameRuleActive("FreeConstruction") then -- Buildings don't require resources to be constructed with Free Construction rule
		local mod_o = self.labels_applied and self or GetModifierObject(self.building_class) or self
		for _, resource in ipairs(ConstructionResourceList) do
			local construction_resource = self.construction_resources[resource]
			if construction_resource then
				local cost = self:GetConstructionCost(resource, mod_o)
				local old_cost = self.construction_costs_at_start[resource]
				if cost ~= old_cost then
					local remaining = construction_resource:GetActualAmount()
					local delta = cost - old_cost
					local new_amount = Max(0, remaining + delta)
					if new_amount ~= old_cost then
						construction_resource:SetAmount(new_amount)
						self.construction_costs_at_start[resource] = cost
					end
				end
			end
		end
	end
end

function ConstructionSite:CreateResourceRequests()
	self:GatherConstructionResources()
end

function ConstructionSite:GetWorkNotPossibleReason()
	return self:IsHalted() and "Halted"
end

function ConstructionSite:GameInit()
	local class = self.building_class_proto

	local construction_state = class.construction_state
	if construction_state ~= "idle" then
		self:SetState(construction_state)
		local a = self:GetAttaches()
		if a then
			for i = 1, #a do
				local attach = a[i]
				if attach:HasState(construction_state) then
					attach:SetState(construction_state)
				end
			end
		end
		self.construction_bbox = false
	end
	
	class:InitConstruction(self)
	
	if self:IsBlockerClearenceComplete() then
		self:Initialize()
	end
	if IsValid(self) then
		CreateGameTimeThread(self.UpdateConstructionVisualization, self) --WaypointsObj:GameInit will attach doors to us after our GameInit, so delay this call.
	end
	
	--setup animated indicators
	local class = self.building_class_proto
	if IsKindOf(class, "StorageWithIndicators") then
		StorageWithIndicators.ResetIndicatorAnimations(self, class.indicator_class)
	end
	if IsKindOf(self.building_class_proto, "SpireBase") then
		SpireBase.UpdateFrame(self)
	end
	self:UpdateHexRanges(GetConstructionController() and IsPlacingMultipleConstructions())
end

function ConstructionSite:OnBlockerClearenceComplete()
	self:SetHierarchyEnumFlags(const.efApplyToGrids)
	if self.ui_working then --i.e. we are turned on
		self.auto_connect = true
		self:ConnectToCommandCenters()
	end
	self:Initialize()
	RebuildInfopanel(self)
end

if FirstLoad then
	queued_objs_for_vis_recalc = false
end

local function RecalcConstructionVisualisation()
	for k, v in pairs(queued_objs_for_vis_recalc or empty_table) do
		if IsValid(k) then
			k.construction_bbox = false
			k:UpdateConstructionVisualization()
		end
	end
	
	queued_objs_for_vis_recalc = {}
end

function ConstructionSite:QueueConstructionVisualizationRecalc()
	queued_objs_for_vis_recalc = queued_objs_for_vis_recalc or {}
	queued_objs_for_vis_recalc[self] = true
	DelayedCall(0, RecalcConstructionVisualisation)
end

function PrepareForConstruction(obj, exclude)
	if obj:GetClassFlags(const.cfConstructible) ~= 0
	and obj:GetEnumFlags(const.efVisible) ~= 0
	and (not exclude or not exclude[obj]) then
		obj:AddCustomData()
		obj:SetAnimSpeed(1, 0)
		obj:SetGameFlags(const.gofUnderConstruction)
	end
	obj:ForEachAttach(PrepareForConstruction, exclude)
end

function GetConstructionBBox(obj, surfaces, precise)
	return ObjectHierarchyBBox(obj, const.efVisible, const.cfConstructible, const.gofUnderConstruction, false, surfaces, precise)
end

local UnbuildableZ = buildUnbuildableZ()
function ConstructionSite:ComputeConstructionBBox()
	local game_map = GetGameMap(self)
	local terrain = game_map.terrain
	local buildable = game_map.buildable

	local function GetTerrainHeight(pos)
		local q, r = WorldToHex(pos)
		local buildable_z = buildable:GetZ(q, r)
		return buildable_z ~= UnbuildableZ and buildable_z or terrain:GetHeight(pos)
	end

	local function ClampToBuildableZ(bbox, pos, pad_z)
		local x1,y1,z1 = bbox:minxyz()
		local x2,y2,z2 = bbox:maxxyz()
		if pad_z then
			--cables dont flatten so buildable z is irrelevant
			z1 = z1 - pad_z
		else
			z1 = Max(GetTerrainHeight(pos), z1)
		end
		z2 = Max(z2, z1 + 1)
		return box(x1, y1, z1, x2, y2, z2)
	end

	local grp = self.construction_group
	if grp then
		if self.per_object_bbox then
			local bbox = {}
			self.construction_bbox = bbox
			for i = 2, #grp do
				local o = grp[i]
				PrepareForConstruction(o)
				bbox[i] = GetConstructionBBox(o)
				o.construction_bbox = ClampToBuildableZ(bbox[i], o:GetPos())
			end
		else
			local bbox
			local p
			for i = 2, #grp do
				local o = grp[i]
				if not o.entity or o.entity == "InvisibleObject" then
					self.construction_bbox = box()
					return 
				end
				PrepareForConstruction(o)
				local b = GetConstructionBBox(o)
				bbox = Extend(bbox or box(), b)
				local his_p = o:GetPos()
				p = not p and his_p or GetTerrainHeight(p) < GetTerrainHeight(his_p) and p or his_p
			end
			
			if not bbox:IsValid() or bbox:sizex() == 0 then
				self.construction_bbox = box()
				return
			end
			
			if self.building_class == "LifeSupportGridElement" and grp[2].chain then
				local d = grp[2].chain.delta
				local p = d < 0 and bbox:min() or bbox:max()
				p = p:SetZ(p:z() + d)
				bbox = Extend(bbox, p)
			end
			
			self.construction_bbox = ClampToBuildableZ(bbox, p, self.building_class == "ElectricityGridElement" and max_z_delta_for_cable_placement)
		end
	else
		PrepareForConstruction(self)
		local surfaces = band(-1, bnot(1)) --no collision
		local bbox = GetConstructionBBox(self, surfaces)
		self.construction_bbox = ClampToBuildableZ(bbox, self:GetPos())
		if self.prefab_objects then
			local pos = self:GetPos()
			surfaces = 1 --collision only
			for i = 1, #self.prefab_objects do
				local o = self.prefab_objects[i]
				PrepareForConstruction(o)
				bbox = GetConstructionBBox(o, surfaces, true)
				self.construction_bbox = ClampToBuildableZ(Extend(self.construction_bbox, bbox), pos)
			end
		end
	end
end

local StageGatherResources = 0
local StageConstructing    = 1

function ConstructionSite:UpdateConstructionVisualization()
	if not IsValid(self) then return end
	if self.construction_group and self.construction_group[1] ~= self then
		return
	end
	
	if not self.prefab_objects and IsKindOf(self.building_class_proto, "LevelPrefabBuilding") then
		assert(not self.construction_group) --not supported
		local flags_to_clear = self:GetEnumFlags(const.efApplyToGrids) == 0 and const.efApplyToGrids or 0
		self.prefab_objects = LevelPrefabBuilding_InstantiatePrefab(self, false, flags_to_clear, function(o)
			rawset(o, "not_wasterock", true)
		end)
	end
	
	if not self.construction_bbox then
		self:ComputeConstructionBBox()
	end

	local stage = StageConstructing
	local progress = 0
	if self.construction_resources then
		if not self:IsBlockerClearenceComplete() then
			stage = StageGatherResources
		else
			for resource, request in pairs(self.construction_resources) do
				if request:GetActualAmount() > 0 then
					stage = StageGatherResources
					break
				end
			end
		end

		progress = self:GetConstructionBuildPointsProgress()
	else
		stage = StageGatherResources
	end

	local construction_group = self.construction_group
	if construction_group then
		local construction_bbox = self.construction_bbox
		local per_object_bbox = self.per_object_bbox
		for i = 2, #construction_group do
			local c_s = construction_group[i]
			if IsValid(c_s) then
				if per_object_bbox then
					c_s:SetConstruction(progress, stage, construction_bbox[i])
				else
					c_s:SetConstruction(progress, stage, construction_bbox)
				end
			end
		end
	else
		self:SetConstruction(progress, stage, self.construction_bbox)
		for i = 1, #(self.prefab_objects or "") do
			local o = self.prefab_objects[i]
			o:SetConstruction(progress, stage, self.construction_bbox)
		end
	end
end

function ConstructionSite:Initialize()
	if self.supplied or not self:IsWaitingResources() and not self.construction_started and (not self.construction_group or self == self.construction_group[1]) then
		self:StartConstructionPhase()
	end
	
	self:ScatterUnitsUnderneath()
	
	if self.can_complete_during_init and not self:IsWaitingResources() and self:IsConstructed() then
		self:Complete()
		return
	end
	
	if self.place_stockpile and self:IsWaitingResources() then
		self:CreateResourceStockpile()
	end
	
	if not self.construction_group or self == self.construction_group[1] then
		self:CSInterruptDrones(self.priority)
	end
end

function ConstructionSite:CreateResourceStockpile()
	if self.resource_stockpile then return end
	assert(self.construction_resources and self.place_stockpile) --demand requests have been created.
	--figure out the possible resources
	local storable_resources = {}
	for r_n, d_req in pairs(self.construction_resources) do
		table.insert(storable_resources, r_n)
	end
	
	local stock = PlaceObjectIn("SharedStorageBaseVisualOnly", self:GetMapID(), {
		storable_resources = storable_resources,
		count_in_resource_overview = false
	}, const.cofComponentAttach)
	self:Attach(stock, self:GetSpotBeginIndex(self:GetState(), self:HasSpot(self.resource_stockpile_spot) and self.resource_stockpile_spot or "Origin"))
	self.resource_stockpile = stock
	
	self:Notify("BootVisualStockpileAmounts")
end

function ConstructionSite:BootVisualStockpileAmounts()
	local stock = self.resource_stockpile
	if stock then
		local costs_at_start = self.construction_costs_at_start
		local supplied = self.supplied
		for resource, request in pairs(self.construction_resources) do
			local amount = costs_at_start[resource]
			local amount_to_stock = (amount - (supplied and 0 or request:GetActualAmount())) - (stock.stockpiled_amount and stock.stockpiled_amount[resource] or 0)
			stock:AddResource(amount_to_stock, resource)
		end
	end
end

function ConstructionSite:DestroyResourceStockpile()
	if IsValid(self.resource_stockpile) then
		DoneObject(self.resource_stockpile)
		self.resource_stockpile = false
	end
end

function ConstructionSite:Gossip(gossip, ...)	
	if not netAllowGossip then return end
	NetGossip("Construction", self.building_class, self.handle, gossip, GameTime(), ...)
end

function ConstructionSite:GossipName()
	if netAllowGossip then
		return "Construction " .. (self.building_class or self.class)
	end
end

function ConstructionSite:GetConstructionCost(resource, mod_o)
	local class = self.building_class_proto
	local dome = IsObjInDome(self)
	local mod = (dome and resource ~= "build_points") and self.in_dome_construction_modifier or 100
	local ret = 0
	
	if resource == "build_points" then
		ret = class.instant_build and 0 or class[resource]
	else
		ret = UIColony.construction_cost:GetConstructionCost(class, resource, mod_o)
	end
	
	return MulDivRound(ret, mod, 100)
end

function ConstructionSite:AddCommandCenter(center)
	assert(center)
	if self:IsBlockerClearenceComplete() then
		if self.construction_group and self.construction_group[1] ~= self then
			local ldr = self.construction_group[1]
			if TaskRequester.AddCommandCenter(ldr, center) then
				center:AddConstruction(ldr)
				return true
			end
		elseif TaskRequester.AddCommandCenter(self, center) then
			center:AddConstruction(self)
			return true
		end
	end
end

function ConstructionSite:RemoveCommandCenter(center)
	if TaskRequester.RemoveCommandCenter(self, center) then
		center:RemoveConstruction(self)
	end
end

function ConstructionSite:SetPriority(priority)
	if self.construction_group and self ~= self.construction_group[1] then
		self.priority = priority
		return self.construction_group[1]:SetPriority(priority)
	end
	if self.priority == priority then return end
	for _, center in ipairs(self.command_centers) do
		center:RemoveConstruction(self)
	end
	
	if not self:IsBlockerClearenceComplete() then
		for i = 1, #(self.waste_rocks_underneath or empty_table) do
			--use highest available per stock
			local the_rock = self.waste_rocks_underneath[i]
			local rock_prio = priority
			for j = 1, #the_rock.parent_construction do
				local c = the_rock.parent_construction[j]
				if c ~= self then
					rock_prio = c.priority > rock_prio and c.priority or rock_prio
				end
			end
			the_rock:SetPriority(rock_prio)
		end
		for i = 1, #(self.stockpiles_underneath or empty_table) do
			--use highest available priority per stock
			local the_stock = self.stockpiles_underneath[i]
			local stock_prio = priority
			for j = 1, #the_stock.parent_construction do
				local c = the_stock.parent_construction[j]
				if c ~= self then
					stock_prio = c.priority > stock_prio and c.priority or stock_prio
				end
			end
			the_stock:SetPriority(stock_prio)
		end
	else
		self:CSInterruptDrones(priority) --should be before SetPriority so that self.priority ~= priority
	end
	
	for i = 2, #(self.construction_group or "") do
		o = self.construction_group[i]
		o.priority = priority
	end
	
	Building.SetPriority(self, priority)
	for _, center in ipairs(self.command_centers) do
		center:AddConstruction(self)
	end
end

function ConstructionSite:CSInterruptDrones(priority)
	if priority >= self.priority then -- equality means initialize
		CreateGameTimeThread(function(self, priority)
			for resource, request in pairs(self.construction_resources) do
				local amount = request:GetTargetAmount()
				if amount > 0 then
					self:InterruptDrones(
						function(cc) --command center filter
							if amount > 0 and cc.under_construction and cc.under_construction[resource] == request then	--this is only here because DroneHub:UpdateConstructions is delayed in a thread
								return cc
							end
						end,
						function(drone) --drone filter
							local d_req = drone.d_request
							
							if drone.resource == resource and IsCloser2D(self, drone, 120*guim) 
								and d_req and d_req ~= request and drone.command == "Deliver" and drone.amount <= request:GetTargetAmount() then --if drone is carrying more resources then the request requires, it won't be able to assign anyway so don't interrupt it.
								
								local bld = d_req:GetBuilding()
								local his_prio = bld and bld.priority or 0
								
								if his_prio < priority or
									((not IsKindOf(bld, "ShuttleHub") or not bld.shuttle_construction_resource_requests or bld.shuttle_construction_resource_requests[d_req:GetResource()] ~= d_req) --don't interrupt shuttle construction
									and (not IsKindOf(bld, "DroneHub") or not bld.drone_construction_request or bld.drone_construction_request ~= d_req)) --don't interrupt dronehub drone construction
									and (not IsKindOf(bld, "RequiresMaintenance") or not bld.maintenance_resource_request or bld.maintenance_resource_request ~= d_req) --maintenance requests
									and (not IsKindOf(bld, "HasConsumption") or not bld.consumption_resource_request or bld.consumption_resource_request ~= d_req) --consumption requests.
									and not d_req:IsAnyFlagSet(const.rfUpgrade) then --upgrade construction resources request.
									
									return drone
								end
							end
						end,
						function(drone) --on drone reset callback
							amount = amount - drone.amount
							if amount <= 0 then return "break" end
						end
					)
				end
			end
		end, self, priority)
	else
		CreateGameTimeThread(function(self)
			local under_construction
			
			self:InterruptDrones(
				function(cc) --command center filter
					under_construction = cc.under_construction
					return cc
				end,
				function(drone) --drone filter
					local request = drone.d_request
					if request and request:GetBuilding() == self and under_construction[request:GetResource()] ~= request then
						return drone
					end
				end
			)
		end, self)
	end
end

function ConstructionSite:IsSupplied()
	if self.construction_group and self ~= self.construction_group[1] then
		return self.construction_group[1]:IsSupplied()
	end

	for resource, request in pairs(self.construction_resources) do
		if request:GetTargetAmount() > 0 then
			return false
		end
	end
	return true
end

function ConstructionSite:IsWaitingResources()
	if not self:IsBlockerClearenceComplete() then
		return false
	end
	if self.construction_group and self ~= self.construction_group[1] then
		return self.construction_group[1]:IsWaitingResources()
	end
	
	for resource, request in pairs(self.construction_resources or empty_table) do
		if request:GetActualAmount() > 0 then
			return true
		end
	end
end

function ConstructionSite:GetEmptyStorage(resource)
	local request = resource == "construct" and self.construct_request or (self.construction_resources or empty_table)[resource]
	return request and request:GetActualAmount() or 0
end

function ConstructionSite:IsConstructed()
	if self.construction_group and self ~= self.construction_group[1] then
		return self.construction_group[1]:IsConstructed()
	end
	return self.construction_started and self.construct_request:GetActualAmount() <= 0
end

function ConstructionSite:DroneCanApproach(drone, resource, is_closest)
	if self.construction_group and not is_closest then
		local ldr = self.construction_group[1]
		if ldr.use_group_goto then
			return drone:CanReachBuildingsSpot({table.unpack(self.construction_group, 2)}, drone.work_spot_task)
		else
			local closest_obj = FindNearestObject(ldr.drop_offs or self.construction_group, drone:GetPos():SetInvalidZ(), function(obj)
				return obj ~= self.construction_group[1]
			end)
			assert(closest_obj, "leaked constr grp leader?")
			return closest_obj and closest_obj:DroneCanApproach(drone, resource, true) or false
		end
	end
	
	local class = self.building_class_proto
	if class:HasMember("DroneCanApproach") then
		return class.DroneCanApproach(self, drone, resource)
	else
		--Fallback to default approach, specifically for classes that do not implement this, like GridElements.
		return TaskRequester.DroneCanApproach(self, drone, resource)
	end
end

function ConstructionSite:DroneApproach(drone, resource, is_closest)
	if self.construction_group and not is_closest then
		local ldr = self.construction_group[1]
		if ldr.use_group_goto then
			return drone:GotoBuildingsSpot({table.unpack(self.construction_group, 2)}, drone.work_spot_task)
		else
			local closest_obj = FindNearestObject(ldr.drop_offs or self.construction_group, drone:GetPos():SetInvalidZ(), function(obj)
				return obj ~= self.construction_group[1]
			end)
			assert(closest_obj, "leaked constr grp leader?")
			return closest_obj and closest_obj:DroneApproach(drone, resource, true) or false
		end
	end
	
	local class = self.building_class_proto
	if class:HasMember("DroneApproach") then
		return class.DroneApproach(self, drone, resource)
	else
		--Fallback to default approach, specifically for classes that do not implement this, like GridElements.
		return TaskRequester.DroneApproach(self, drone, resource)
	end
end

function ConstructionSite:DroneWork(drone, request, resource, amount)
	drone:PushDestructor(function(drone)
		local self = drone.target
		if IsValid(self) and not self:IsWaitingResources() and self:IsConstructed() then
			self:Complete()
		end
	end)
	drone:ContinuousTask(request, amount, g_Consts.DroneConstructBatteryUse, "constructStart", "constructIdle", "constructEnd", "Construct",
		function(drone)
			drone.target:UpdateConstructionVisualization()
		end, IsKindOf(self.building_class_proto, "RocketBuildingBase"))
	drone:PopAndCallDestructor()
end

construction_site_auto_construct_tick = ConstructionSite.building_update_time
construction_site_auto_construct_amount = 167

function ConstructionSite:BuildingUpdate(delta, day, hour)
	if self.construction_group and self.construction_group[1] ~= self then return end
	
	if self.construction_started and g_ConstructionNanitesResearched then
		local current_time = GameTime()
		if not self.auto_construct_ts then self.auto_construct_ts = current_time end 
		if current_time - self.auto_construct_ts >= construction_site_auto_construct_tick then
			self.auto_construct_ts = current_time
			local a = self.construct_request:GetActualAmount()
			a = Max(a - construction_site_auto_construct_amount, 0)
			self.construct_request:SetAmount(a)
			self:UpdateConstructionVisualization()
			RebuildInfopanel(self)
			if not self:IsWaitingResources() and self:IsConstructed() then
				CreateGameTimeThread(self.Complete, self)
			end
		end
	end
end

function ConstructionSite:DroneUnloadResource(drone, request, resource, amount)
	assert(not self.construction_group or self == self.construction_group[1])
	if self.resource_stockpile then
		self.resource_stockpile:AddResource(amount, resource)
	end
	if request:GetActualAmount() <= 0 and self:StartConstructionPhase() then
		drone:SetCommand("Work", self.construct_request, "construct", Min(DroneResourceUnits.construct, self.construct_request:GetActualAmount()))
	end
end

function ConstructionSite:RoverLoadResource(amount, resource, request)
	self:AddResource(amount, resource, true)
end

function ConstructionSite:AddResource(amount, resource)
	if resource == "construct" then
		self.construct_request:AddAmount(amount)
		self:UpdateConstructionVisualization()
		return
	end
	if self.resource_stockpile then
		self.resource_stockpile:AddResource(amount, resource)
	end
	self.construction_resources[resource]:AddAmount(-amount)
end

function ConstructionSite:RoverWork(rover, request, resource, amount, total_amount, interaction_type)
	if resource == "construct" then
		rover:PushDestructor(function(rover)
			if IsValid(self) and not self:IsWaitingResources() and self:IsConstructed() then
				self:Complete()
			end
		end)
		rover:ContinuousTask(request, amount, "constructStart", "constructIdle", "constructEnd", "Construct", nil, nil, nil, nil, total_amount)
		rover:PopAndCallDestructor()
	elseif self.construction_resources[resource] == request then
		rover:ContinuousTask(request, amount, "gatherStart", "gatherIdle", "gatherEnd", interaction_type ~= "load" and "Unload" or "Load", "step", g_Consts.RCRoverTransferResourceWorkTime, "add resource")
	end
end
--
function ConstructionSite:StartConstructionPhase()
	if not self:IsWaitingResources() then
		if not self.construction_started then
			self:DestroyResourceStockpile()
			self:Gossip("construct")
			self.construct_request:AddAmount(self:GetConstructionCost("build_points"))
			self:UpdateConstructionVisualization()
			self.construction_started = true
			for _, center in ipairs(self.command_centers) do
				center:UpdateConstructions()
			end
			
			RebuildInfopanel(self)
		end	
		return true
	end
end

--use when quick building, so that no weird state objects remain
function ConstructionSite:DestroyWasteObjsUnderneath()
	self:DestroyWasteRockUnderneath()
	self:DestroyStockpilesUnderneath()
end

function ConstructionSite:DestroyWasteRockUnderneath()
	local waste_rocks_underneath = self.waste_rocks_underneath
	if waste_rocks_underneath then
		for i = #waste_rocks_underneath, 1, -1 do
			local o = waste_rocks_underneath[i]
			table.remove_entry(o.parent_construction, self) --remove so destructor doesn't call us, because we'll be dead
			table.remove_value(waste_rocks_underneath, o)
			DoneObject(o)
		end
	end
end

function ConstructionSite:DestroyStockpilesUnderneath()
	local stockpiles_underneath = self.stockpiles_underneath
	if stockpiles_underneath then
		for i = #stockpiles_underneath, 1, -1 do
			DoneObject(stockpiles_underneath[i]) --stock destructor cleans itself from this array.
		end
	end
end

function ConstructionSite:MoveStockpilesUnderneathOutside(interval)
	local stockpiles_underneath = self.stockpiles_underneath
	if stockpiles_underneath then
		local game_map = GetGameMap(self)
		for i = #stockpiles_underneath, 1, -1 do
			local stockpile = stockpiles_underneath[i]
			if stockpile then
				local q, r = WorldToHex(self:GetPos())
				local result
				result, q, r = TryFindStockpileDumpSpotIn(game_map, q, r, self:GetAngle(), GetEntityPeripheralHexShape(self:GetEntity()))
				if result then
					if interval then
						Sleep(interval)
					end
					local x, y = HexToWorld(q, r)
					if IsValid(stockpile) then
						stockpile:SetPos(point(x, y))
						self:OnBlockingStockpileCleared(stockpile)
						for _, p_c in ipairs(stockpile.parent_construction or empty_table) do
							if p_c ~= self then
								p_c:OnBlockingStockpileCleared()
							end
						end
						stockpile.parent_construction = false
						stockpile:OnConstructionCanceled()
					end
				end
			end
		end
	end
end

function QuickBuildWarning()
	DebugPrint("\n!!! Quick Build !!!\n")
end

function ConstructionSite:OnQuickBuild()
	self:DestroyWasteObjsUnderneath()
	DelayedCall(0, QuickBuildWarning)
end

function SavegameFixups.FixConstructionSiteAltEntities()
	MapForEach("map", "ConstructionSite", function(o)
		if not o.alternative_entity_t and IsKindOf(o.building_class_proto, "Dome") then
			o.alternative_entity_t = {entity = o.dome_skin and o.dome_skin[1] or
											o.building_class_proto.entity}
		end
	end)
end

function ConstructionSite:Complete(quick_build) --quick_build - cheat build
	if not IsValid(self) then return end -- happens when the user spams quick build and manages to complete the same site twice.

	assert(not self.construction_group or self ~= self.construction_group[1])
	local class = self.building_class_proto
	
	--black cube counting
	if self.construction_costs_at_start and self.construction_costs_at_start.BlackCube then
		local mystery = self.city.colony.mystery
		if mystery and mystery.class == "BlackCubeMystery" then
			mystery.used_cubes = mystery.used_cubes + self.construction_costs_at_start.BlackCube / const.ResourceScale
		end
	end

	local realm = GetRealm(self)
	realm:SuspendPassEdits("ConstructionSite.Complete")
	SuspendTerrainInvalidations("ConstructionSite.Complete")

	if quick_build then
		self:OnQuickBuild()
	end
	
	local instance = {
		city = self.city,
		init_with_skin = self.dome_skin,
		name = self.name,
		orig_terrain1 = self.orig_terrain1 or nil,
		orig_terrain2 = self.orig_terrain2 or nil,
		construction_data = next(self.construction_data or empty_table) and self.construction_data or nil,
	}
	local params = {
		alternative_entity_t = {entity = self.alternative_entity_t and self.alternative_entity_t.entity
			or self:GetEntity(), 
			palette = self.alternative_entity_t and self.alternative_entity_t.palette or {self:GetColorizationMaterial4()} },
	}

	local bld = PlaceBuildingIn(self.building_class, self:GetMapID(), instance, params)
	bld:SetAngle(self:GetAngle())
	bld:SetPos(self:GetPos())
	local dome = IsObjInDome(self)
	if dome then
		DeleteUnattachedRoads(bld, dome)
	end
	
	if self.on_complete_functor then
		self.on_complete_functor(self, bld)
	end
		
	local reselect = SelectedObj == self
	
	if IsValid(self.rebuild) then
		DoneObject(self.rebuild)
		self.rebuild = nil
	end
	self:MarkSpentResources(bld)
	if IsKindOf(bld, "PinnableObject") and self:IsPinned() then
		bld:TogglePin()
	end
	local multiselect_range_att = self:GetAttaches("RangeHexMultiSelectRadius")
	if multiselect_range_att and #multiselect_range_att > 0 and bld:HasMember(RangeHexRadius.bind_to) then
		ShowBuildingHexes(bld, bld == SelectedObj and "RangeHexMovableRadius" or "RangeHexMultiSelectRadius", RangeHexRadius.bind_to)
	end

	if self.clean_cables_on_place then
		--should be before apply grids
		self.city:SetCableCascadeDeletion(false, "ConstructionSite")
		local found_any_cables = self:DestroyCablesUnderneath(bld)
		
		local interior = GetEntityInteriorShape(bld:GetEntity())
		if interior and next(interior) then
			local object_hex_grid = GetObjectHexGrid(self)
			for _, cable in ipairs(HexGridShapeGetObjectList(object_hex_grid.grid, bld, interior, "ElectricityGridElement")) do
				DoneObject(cable)
				found_any_cables = true
			end
		end
		
		if found_any_cables then
			--the first clean happens based on the same shape, so the only way this could happen if the user constructs cables during construction
			print("Construction site shape does not correspond to completed building shape!")
		end
		self.city:SetCableCascadeDeletion(true, "ConstructionSite")
	end

	DoneObject(self)

	-- ApplyToGrids is done in GridObject:GameInit()
	-- this is speculative application to mark the spot so no other buildings can occupy it before GameInit is called (from a thread)
	bld:ApplyToGrids()
	if reselect then
		CreateGameTimeThread(function(bld)
			if GetInGameInterfaceMode() == "selection" then
				SelectObj(bld)
			end
		end, bld)
	end

	--cheats
	if quick_build and bld:HasMember("QuickBuildSetup") then
		bld:Notify("QuickBuildSetup")
	end

	Msg("ConstructionComplete", bld, dome)

	realm:ResumePassEdits("ConstructionSite.Complete")
	ResumeTerrainInvalidations("ConstructionSite.Complete")

	return bld
end

function ConstructionSite:DestroyCablesUnderneath(building)
	local found_any_cables = false
	local object_hex_grid = GetObjectHexGrid(self)
	for _, cable in ipairs(HexGridShapeGetObjectList(object_hex_grid.grid, building, building:GetShapePoints(), "ElectricityGridElement")) do
		DoneObject(cable)
		found_any_cables = true
	end
	return found_any_cables
end

function ConstructionSite:MarkSpentResources(bld)
	if self.construction_group and self.construction_group[1] ~= self then return end --ldr should mark
	local t = {}
	assert(self.construction_costs_at_start)
	for r_n, amount in pairs(self.construction_costs_at_start or empty_table) do
		t[r_n] = amount
	end
	if next(t) then
		bld.construction_cost_at_completion = t
	end
end

function ConstructionSite:ReturnResources()
	if self.construction_group and self.construction_group[1] ~= self then return end

	for _, resource in ipairs(ConstructionResourceList) do
		local amount = self.construction_costs_at_start and self.construction_costs_at_start[resource] or 0
		if amount > 0 then
			self:PlaceReturnStockpile(resource, amount - (self.supplied and 0 or self.construction_resources[resource]:GetActualAmount()))
		end
	end
	
	if self.prefab then
		self.city:AddPrefabs(self.building_class, 1)
	end
end

function ConstructionSite:Cancel()
	if not IsValid(self) then return end
	if not self.can_cancel then return end

	local realm = GetRealm(self)
	SuspendTerrainInvalidations("construction_site")
	realm:SuspendPassEdits("ConstructionSite.Cancel")
	if IsValid(self.rebuild) then
		self.rebuild:RebuildCancel()
	end

	local ws_block_obj = self.construction_group and self.construction_group[1] or self
	local ws_block = ws_block_obj:IsBlockerClearenceComplete()
	local grp = self.construction_group
	
	self:RestoreTerrain(self.building_class_proto)

	if not ws_block then
		if grp then --we are cancelling the entire group
			local g_count = #grp
			for i = g_count, 2, -1 do
				local o = grp[i]
				o:CleanupWasteRockObstructors()
				o.construction_group = false --suppress destructors because of cable cascade deletion
				o.UpdateVisuals =  empty_func
			end
			for i = g_count, 2, -1 do
				local o = grp[i]
				if IsValid(o) then --still can be invalid due to cable cascade deletion
					DoneObject(o)
				end
			end
			grp[1]:ReturnResources()
			assert(grp[1]:CanDelete())
			DoneObject(grp[1])
			ResumeTerrainInvalidations("construction_site")
			realm:ResumePassEdits("ConstructionSite.Cancel")
			return
		else
			self:CleanupWasteRockObstructors()
			self:ReturnResources()
		end
	else
		if grp then
			for i = #grp, 1, -1 do
				grp[i].UpdateVisuals =  empty_func
			end
			for i = #grp, 1, -1 do
				local o = grp[i]
				if IsValid(o) then
					DoneObject(o)
				end
			end
			self.construction_group = false
			ResumeTerrainInvalidations("construction_site")
			realm:ResumePassEdits("ConstructionSite.Cancel")
			return
		end

		self:ReturnResources()

		if SelectedObj == self then
			SelectObj()
		end
	end
	DoneObject(self)
	ResumeTerrainInvalidations("construction_site")
	realm:ResumePassEdits("ConstructionSite.Cancel")
end

function ConstructionSite:ToggleDemolish()
	self:Cancel()
end

local function exit_impassable_filter(obj)
	return obj.command ~= "Embark"
end

function ConstructionSite:GetUnitsUnderneath(test) --if test == true, will break on first unit
	local realm = GetRealm(self)
	return HexGetUnits(realm, self, self:GetEntity(), self:GetVisualPos(),
							self:GetAngle(), test, exit_impassable_filter)
end

function ConstructionSite:ScatterUnitsUnderneath()
	local units_underneath = self:GetUnitsUnderneath()
	for i = 1, #units_underneath do
		local u = units_underneath[i]
		if not u:IsKindOf("RCConstructorBase") or u.command ~= "Construct" or u.construction_clearing ~= self then
			if u:IsDead() then --gracefull delete drone
				if IsValid(u) then --not deleted
					if u.command == "DespawnAtHub" then --moving, stop moving and die
						u:SetCommand("DieNow")
					else
						DoneObject(u) --safe to del
					end
				end
			else			
				u:SetCommand("ExitImpassable")
			end
		end
	end

end

function ConstructionSite:ChangeConstructionGroup(new_group)
	local old_grp = self.construction_group
	if not old_grp then return end
	if old_grp[1] == self then return end --leaders cant switch
	
	table.remove_entry(old_grp, self)
	table.insert(new_group, self)
	self.construction_group = new_group
end

function ConstructionSite:Done()
	if not self:IsBlockerClearenceComplete() then
		self:CleanupWasteRockObstructors()
	end
	if self.construction_group then
		if not IsKindOf(self, "ConstructionGroupLeader") then
			table.remove_entry(self.construction_group, self)
			if self.construction_group[1]:CanDelete() then --only leader or leader of elements from different groups.
				self.construction_group[1]:ReturnResources()
				DoneObject(self.construction_group[1])
			end
		end
		self.construction_group = false --don't keep refs
	end
	local object_hex_grid = GetObjectHexGrid(self)
	local dome = GetDomeAtPoint(object_hex_grid, self)
	if dome then
		UpdateCoveredGrass(self, dome, "clear")
	end
	
	if self.prefab_objects then
		for i = 1, #self.prefab_objects do
			local o = self.prefab_objects[i]
			DoneObject(o)
		end
	end

	self:StopNaniteThread()
	
	self:RemoveFromCityLabels()
	Msg("ConstructionSiteRemoved", self)
end

function ConstructionSite:SetUIWorking(working)
	if self.construction_group and self.construction_group[1] ~= self then
		--propagate to group leader
		self.construction_group[1]:SetUIWorking(working)
	else
		Building.SetUIWorking(self, working)
	end
end

function ConstructionSite:Getdescription() 
	return T{607, "<em>Construction site</em>. This building will be constructed by Drones when all necessary resources have been brought.", self}
end

function ConstructionSite:GetIPDescription() 
	return self:Getdescription()
end

function ConstructionSite:UpdateNoCCSign()
	if g_ConstructionNanitesResearched then return end
	if self.construction_group and self ~= self.construction_group[1] then 
		return self.construction_group[1]:UpdateNoCCSign()
	end
	
	Building.UpdateNoCCSign(self)
end

function ConstructionSite:GetConstructionGroupLeader()
	return self.construction_group and self.construction_group[1] or self
end

function ConstructionSite:IsHalted()
	return self.is_locked_by_story_bit
end

function ConstructionSite:SetHalted(val)
	if self.is_locked_by_story_bit ~= val then
		self.is_locked_by_story_bit = val
		self:AttachSign(val, "SignHalted")
		self:UpdateWorking()
	end
end

function ConstructionSite:GetUIWarning()
	if self:IsHalted() then
		return NotWorkingWarning.Halted
	elseif self.exceptional_circumstances then
		return NotWorkingWarning["ExceptionalCircumstancesDisabled"]
	elseif self.ui_working and self:IsOutsideCommandRange() then
		return NotWorkingWarning["NoCommandCenter"]
	end
end

function ConstructionSite:ShouldShowNoCCSign()
	local r = Building.ShouldShowNoCCSign(self)
	if r then
		return not self:IsHalted() and not self.exceptional_circumstances
	end
	return r
end

function ConstructionSetState(construction, state)
	--state is Disable, Enable, Destroy, Complete
	assert(IsValid(construction))
	local ret = construction
	state = state or "Destroy"
	if state == "Disable" or state == "Lock" then
		construction:SetHalted(true)
	elseif state == "Enable" or state == "Unlock" then
		construction:SetHalted(false)
	elseif state == "Destroy" then
		DoneObject(construction)
	elseif state == "Complete" then
		ret = construction:Complete()
	else
		assert(false, "Unrecognized state!")
	end
	
	return ret
end

----

DefineClass.ConstructionSiteWithHeightSurfaces = {
	__parents = { "ConstructionSite" },
	flags = { cfNoHeightSurfs = false },
}

--These hints will be disabled when a building of this class is placed
HintDisabledByConstructionPlaced = {
	RegolithExtractor = "HintSuggestConcreteExtractor",
	WaterExtractor = {"HintUndergroundWater", "HintWaterProduction"},
	MoistureVaporator = "HintWaterProduction",
	MOXIE = "HintAirProduction",
	SensorTower = "HintSuggestSensorTower",
	DroneHub = "HintSuggestDroneHub",
	LivingQuarters = "HintSuggestLivingQuarters",
	ResearchLab = "HintSuggestResearchLab",
	HydroponicFarm = "HintSuggestHydroponicFarm",
	Farm = "HintSuggestHydroponicFarm",
	FungalFarm = "HintSuggestHydroponicFarm",
	FuelFactory = "HintRefuelingTheRocket",
	Infirmary = "HintHealthcare",
	MedicalCenter = "HintHealthcare",
}

--These hints will be disabled when a building of this category is placed
HintDisabledByConstructionPlacedFromCategory = {
	["Domes"] = "HintDomes",
	["Decorations"] = "HintDecorations",
}

local function DisableMultipleHints(ids)
	if type(ids) == "table" then
		for i=1,#ids do
			HintDisable(ids[i])
		end
	else
		HintDisable(ids)
	end
end

function RemoveUnderConstruction(obj)
	local realm = GetRealm(obj)
	if IsValidEntity(obj:GetEntity()) then
		-- enum all removable objects in a large enough radius, use the farthest point of the bounding box including surfaces
		local bb = obj:GetEntitySurfacesBBox()
		local pts = { bb:min(), point(bb:maxx(), bb:miny()), point(bb:minx(), bb:maxy()), bb:max() }

		local dist = 0
		for i = 1, #pts do
			dist = Max(dist, pts[i]:Len2D())
		end

		local object_hex_grid = GetObjectHexGrid(obj)

		realm:MapForEach(
			obj,
			dist + GetEntityMaxSurfacesRadius(),
			const.efRemoveUnderConstruction,
			function(o)
				local o_pos = o:GetPos()
				local q, r = WorldToHex(o_pos)
				local rad = o:GetRadius()
				local remove
				if not IsCloser2D(o, obj, dist + rad) then
					return
				end
				-- check if the object and the building share at least one hex
				local hexes = {}
				if rad < const.HexSize then
					hexes[1] = point(0, 0)
				else
					hexes = GetEntityPeripheralHexShape(o:GetEntity())
				end
				for i = 1, #hexes do
					object_hex_grid:GetObjects(q + hexes[i]:x(), r + hexes[i]:y(), nil, nil, function(o2) 
						if o2 == obj then
							remove = true
							return "break"
						end
						return false
					end)
					if remove then break end
				end
				if remove then
					DoneObject(o)
				end
			end)
	else
		local rad = obj:GetRadius()
		rad = rad == 0 and const.HexSize or rad
		realm:MapDelete( obj, rad, const.efRemoveUnderConstruction)
	end
end

function GetConstructionSiteClass(class_name, building_proto_class)
	local construction_site_class = ((class_name == "ElectricitySwitch" or class_name == "LifesupportSwitch") and "GridSwitchConstructionSite") or
		(class_name == "LifeSupportGridElement" and "PipeConstructionSite") or
		(class_name == "ElectricityGridElement" and "CableConstructionSite") or
		(class_name == "PassageGridElement" and "PassageConstructionSite") or
		(IsKindOf(building_proto_class, "OpenCity") and "OpenCityConstructionSite") or
		(building_proto_class.construction_site_applies_height_surfaces and "ConstructionSiteWithHeightSurfaces" or "ConstructionSite")
	return construction_site_class
end

function PlaceConstructionSite(city, class_name, pos, angle, params, no_block_pass, no_flatten)
	SuspendTerrainInvalidations("PlaceConstructionSite")
	
	Msg("ConstructionSitePlace", class_name, pos, angle, params, no_block_pass, no_flatten)
	
	params = params or {}
	local building_proto_class = ClassTemplates.Building[class_name] or g_Classes[class_name]
	local construction_site_class = GetConstructionSiteClass(class_name, building_proto_class)
	local site = PlaceObjectIn(construction_site_class, city.map_id, params)
	site:SetBuildingClass(class_name)
	AutoAttachObjectsToShapeshifter(site)
	
	if no_block_pass then
		site:ClearHierarchyEnumFlags(const.efApplyToGrids)
	end
	
	site.can_cancel = building_proto_class.can_cancel
	site.can_user_change_prio = building_proto_class.can_user_change_prio

	local realm = GetRealm(city)
	realm:SuspendPassEdits("PlaceConstructionSite")
	site:SetPos(AdjustBuildPos(city, pos))
	site:SetAngle(angle)
	local object_hex_grid = GetObjectHexGrid(city)
	local dome = GetDomeAtPoint(object_hex_grid, pos)
	if dome then
		DeleteUnattachedRoads(site, dome)
		UpdateCoveredGrass(site, dome, "build")
	elseif not no_flatten then
		FlattenTerrainInBuildShape(building_proto_class:GetFlattenShape(site), site)
	end
	site:ApplyToGrids() -- twofold purpose, both restrict building over our site and help clean up removables

	RemoveUnderConstruction(site)
	realm:ResumePassEdits("PlaceConstructionSite")
	ResumeTerrainInvalidations("PlaceConstructionSite")

	if building_proto_class:HasMember("build_category") then
		local hint_category = HintDisabledByConstructionPlacedFromCategory[building_proto_class.build_category]
		if hint_category then
			DisableMultipleHints(hint_category)
		end
	end
	
	local hint_building = HintDisabledByConstructionPlaced[class_name]
	if hint_building then
		DisableMultipleHints(hint_building)
	end
	
	if IsKindOf(building_proto_class, "Service") and not IsKindOf(building_proto_class, "MedicalBuilding") then
		HintDisable("HintComfortStatAndServices")
	end
	
	PlayFXAroundBuilding(site, "Place")
	
	Msg("ConstructionSitePlaced", site, class_name, pos, angle, params, no_block_pass, no_flatten)
	if params.prefab then
		Msg("ConstructionPrefabPlaced", site)
	end
	return site
end

-----------------------------------------------------------------------------------------------------------
DefineClass.PipeConstructionSite = {
	__parents = {"ConstructionSite", "LifeSupportGridElement"},
	flags = { gofPermanent = true },
	entity = false,
	default_label = false,
	is_construction_complete = false, --else canceled.
	time_required_for_demolish = 3000,
	disable_selection = false,
	can_complete_during_init = false,
	place_stockpile = false,
	connect_dir_cached = false, --supplygridconnect clears connect_dir, so keep 1 reserve cpy
	--resolve diamond inh
	display_icon = LifeSupportGridElement.display_icon,
	is_tall = LifeSupportGridElement.is_tall,
	GetDisplayName = BreakableSupplyGridElement.GetDisplayName,
	display_name = LifeSupportGridElement.display_name,
	display_name_pl = LifeSupportGridElement.display_name_pl,
	ApplyToGrids = LifeSupportGridElement.ApplyToGrids,
	RemoveFromGrids = LifeSupportGridElement.RemoveFromGrids,
	description = LifeSupportGridElement.description,
	PickEntity = empty_func,
	SetConstructionSiteEntity = empty_func,
	MoveInside = empty_func,
	AddDust = DustGridElement.AddDust,
	priority = 2,
	DroneUnloadResource = ConstructionSite.DroneUnloadResource,
	DroneWork = ConstructionSite.DroneWork,
	CreateResourceRequests = ConstructionSite.CreateResourceRequests,
	GetPriorityForRequest = RequiresMaintenance.GetPriorityForRequest,
	Repair = RequiresMaintenance.Repair,
	encyclopedia_id = false,
	Getdescription = ConstructionSite.Getdescription,
	UpdateAttachedSigns = empty_func,
	GetInfopanelTemplate = Building.GetInfopanelTemplate,
	GetFlattenShape = LifeSupportGridElement.GetInfopanelTemplate,
	
	--pipe skins, no skin changing of construction site pipes by users, but it can change internally.
	ChangeSkin = LifeSupportGridElement.ChangeSkin,
	GetSkins = LifeSupportGridElement.GetSkins,
	
	sign_spot = "Origin",
	sign_offset = point(0, 0, 12*guim),
	rename_allowed = false,
}

function PipeConstructionSite:Init()
	self.connect_dir_cached = self.connect_dir
end

function PipeConstructionSite:Complete(quick_build, current, total)
	if not IsValid(self) then return end
	
	if quick_build then
		self:OnQuickBuild()
	end
	
	self.is_construction_complete = true
	local bld = LifeSupportGridElement:new({
		city = self.city, 
		connect_dir = self.connect_dir_cached,
		pillar = self.pillar, 
		chain = self.chain,
		construction_grid_skin = self:GetGridSkinName(),
		is_switch = self.is_switch,
		switch_state = self.switch_state,
	}, self:GetMapID())
	bld:SetAngle(self:GetAngle())
	bld:SetPos(self:GetPos())
	
	if bld:CanMakePillar(self) then
		--everything is a pillar until proven pipe.
		--basically it's easier to demote a pillar then to promote a pipe later on.
		bld:MakePillar(self.pillar or true, self)
	else
		if not self.connect_dir_cached then
			--deduce dir from con
			local conn = self.construction_connections
			
			local dir = 0
			for i = 0, 5 do
				if testbit(conn, i) then
					dir = i
					break
				end
			end
			self.connect_dir_cached = dir
		end
		bld:MakePipe(self.connect_dir_cached)
	end
	
	if self.chain then
		bld:SetChainParams(self.chain.delta, self.chain.index, self.chain.length)
	end

	local reselect = SelectedObj == self
	bld.construction_connections = self.construction_connections
	DoneObject(self)
	bld:ApplyToGrids()
	if reselect then
		CreateGameTimeThread(SelectObj)
	end
end

function PipeConstructionSite:UpdateVisuals()
	LifeSupportGridElement.UpdateVisuals(self)
	
	if self.construction_group then
		self.construction_group[1]:QueueConstructionVisualizationRecalc()
	else
		self:QueueConstructionVisualizationRecalc()
	end
end

function PipeConstructionSite:CanMakeSwitch()
	return false
end
-----------------------------------------------------------------------------------------------------------
DefineClass.CableConstructionSite = {
	__parents = {"ConstructionSite", "ElectricityGridElement"},
	flags = { gofPermanent = true },
	entity = false,
	default_label = false,
	is_construction_complete = false,
	time_required_for_demolish = 3000,
	disable_selection = false,
	can_complete_during_init = false,
	place_stockpile = false,
	--resolve diamond inh
	display_icon = ElectricityGridElement.display_icon,
	description = ElectricityGridElement.description,
	is_tall = ElectricityGridElement.is_tall,
	GetDisplayName = BreakableSupplyGridElement.GetDisplayName,
	display_name = ElectricityGridElement.display_name,
	display_name_pl = ElectricityGridElement.display_name_pl,
	PickEntity = empty_func,
	SetConstructionSiteEntity = empty_func,
	MoveInside = empty_func,
	SetDust = empty_func,
	SetHeat = empty_func,
	--ConnectToCommandCenters = empty_func,
	AddDust = DustGridElement.AddDust,
	priority = 2,
	DroneUnloadResource = ConstructionSite.DroneUnloadResource,
	DroneWork = ConstructionSite.DroneWork,
	CreateResourceRequests = ConstructionSite.CreateResourceRequests,
	GetPriorityForRequest = RequiresMaintenance.GetPriorityForRequest,
	Repair = RequiresMaintenance.Repair,
	encyclopedia_id = false,
	Getdescription = ConstructionSite.Getdescription,
	UpdateAttachedSigns = empty_func,
	GetInfopanelTemplate = Building.GetInfopanelTemplate,
	GetFlattenShape = ElectricityGridElement.GetInfopanelTemplate,
	
	sign_spot = "Origin",
	rename_allowed = false,
}

function CableConstructionSite:Complete(quick_build, current, total)
	if not IsValid(self) then return end
	
	if quick_build then
		self:OnQuickBuild()
	end
	
	self.is_construction_complete = true
	local bld = ElectricityGridElement:new({
		city = self.city,
		construction_connections = self.construction_connections,
		pillar = self.pillar,
		chain = self.chain,
		is_switch = self.is_switch,
		switch_state = self.switch_state,
	}, self:GetMapID())
	bld:SetAngle(self:GetAngle())
	bld:SetPos(self:GetPos())
	if self.chain then
		bld:SetChainParams(self.chain.delta, self.chain.index, self.chain.length)
	end
	
	local reselect = SelectedObj == self
	DoneObject(self)
	bld:ApplyToGrids()
	if reselect then
		CreateGameTimeThread(SelectObj)
	end
end

function CableConstructionSite:UpdateVisuals()
	ElectricityGridElement.UpdateVisuals(self)
	
	if self.construction_group then
		self.construction_group[1]:QueueConstructionVisualizationRecalc()
	else
		self:QueueConstructionVisualizationRecalc()
	end
end

function CableConstructionSite:ToggleDemolish()
	ConstructionSite.ToggleDemolish(self)
	if IsValid(self) then
		if self.demolishing then
			self:SetColorModifier(RGB(0, 0, 0)) --sets color during demolish
		else
			self:SetColorModifier(RGB(100, 100, 100)) --clears color
		end
	end
end

function CableConstructionSite:CanMakeSwitch()
	return false
end


-----------------------------------------------------------------------------------------------------------
--construction group leader
-----------------------------------------------------------------------------------------------------------
DefineClass.ConstructionGroupLeader = {
	__parents = { "ConstructionSite" },
	entity = "Hex1_Placeholder",
	default_label = false,
	place_stockpile = false,
	drop_offs = false,
	per_object_bbox = false,
	use_group_goto = true,
	
	construction_cost_multiplier = 100, --groups cost exactly as much as 1 element, use this to change that
	
	flags = { efVisible = false, efApplyToGrids = false, efCollision = false, },
	
	ApplyToGrids = empty_func,
	RemoveFromGrids = empty_func,
}

function ConstructionGroupLeader:DestroyWasteRockUnderneath()
	local cg = self.construction_group
	for i = 2, #cg do
		local arr = ConstructionSite.DestroyWasteRockUnderneath(cg[i])
	end
end

function ConstructionGroupLeader:MoveStockpilesUnderneathOutside(interval)
	local cg = self.construction_group
	for i = 2, #cg do
		local arr = ConstructionSite.MoveStockpilesUnderneathOutside(cg[i], interval)
	end
end

function ConstructionGroupLeader:DestroyStockpilesUnderneath()
	local cg = self.construction_group
	for i = 2, #cg do
		local arr = ConstructionSite.DestroyStockpilesUnderneath(cg[i])
	end
end

function ConstructionGroupLeader:UpdateSignsVisibility(...)
	--use one of our controlled construnctions because we are invisible
	local obj = (self.construction_group or empty_table)[2]
	if obj then
		obj.signs = self.signs
		BaseBuilding.UpdateSignsVisibility(obj, ...)
	end
end

function ConstructionGroupLeader:GetConstructionCost(resource, mod_o)
	return MulDivRound(self.construction_cost_multiplier, ConstructionSite.GetConstructionCost(self, resource, mod_o), 100)
end

function ConstructionGroupLeader:TintWasteRockObstructors(set)
	local grp = self.construction_group
	for i = 2, #grp do
		local arr = grp[i].waste_rocks_underneath
		local c = arr and #arr or 0
		if c > 0 then
			if set then
				for j = 1, c do
					local ws = arr[j]
					ws:SetGameFlags(const.gofWhiteColored)
				end
			else
				for j = 1, c do
					local ws = arr[j]
					ws:ClearGameFlags(const.gofWhiteColored)
				end
			end
		end
	end
end

function ConstructionGroupLeader:SetAutoConnect(set)
	local grp = self.construction_group
	for i = 1, #(grp or "") do
		grp[i].auto_connect = set
	end
end

function ConstructionGroupLeader:SetUIWorking(working)
	local grp = self.construction_group
	for i = 2, #(grp or "") do
		grp[i].ui_working = working
	end
	Building.SetUIWorking(self, working)
end

function ConstructionGroupLeader:OnSetWorking(working)
	ConstructionSite.OnSetWorking(self, working)
	self:SetAutoConnect(self.auto_connect)
end

function ConstructionGroupLeader:ConnectToCommandCenters()
	TaskRequester.ConnectToCommandCenters(self)
	local grp = self.construction_group
	for i = 2, #(grp or "") do
		grp[i]:ConnectToCommandCenters()
	end
end

function SavegameFixups.FixStuckConstructions()
	MapForEach("map", "ConstructionGroupLeader", function(o)
		if not o.construction_started and not o:IsWaitingResources() then
			o:OnBlockerClearenceComplete()
		end
	end)
end

function ConstructionGroupLeader:OnBlockerClearenceComplete()
	if IsValid(self) and self:IsBlockerClearenceComplete() then
		--we get notification from each member, so check if there is still waste rock underneath the group
		--also we'll get multiple callbacks from each member, so check if we actually need to do anything.
		if self.instant_build then
			--instant power cbles should be non-instant power cables if there is waste rock underneath and only then!
			--i.e. we should 100% pass from here
			self:Complete()
		elseif not self.auto_connect
				or (self.supplied or not self:IsWaitingResources() and not self.construction_started) then --auto connect may have flipped before callback fired
			if not self.construction_resources then --late adds to the group may cause it to disconnect, in which case requests are already built
				self:GatherConstructionResources()
			end
			if not self.auto_connect and self.ui_working then
				self:SetAutoConnect(true)
				self:ConnectToCommandCenters()
			end
			self:Initialize()
			RebuildInfopanel(self)
		end
	end
end

function ConstructionGroupLeader:dbg_GetCCAndTaskRequestCount()
	return string.format("CC count: %d, TR count: %d", #self.command_centers, #self.task_requests)
end

function ConstructionGroupLeader:IsBlockerClearenceComplete()
	local construction_group = self.construction_group
	for i = 2, #(construction_group or "") do
		if IsValid(construction_group[i]) and not construction_group[i]:IsBlockerClearenceComplete(true) then
			return false
		end
	end
	return true
end

function ConstructionGroupLeader:TestBlockerClearenceProgress()
	if self:IsBlockerClearenceComplete() then
		local construction_group = self.construction_group
		for i = 2, #(construction_group or "") do
			construction_group[i]:OnBlockerClearenceComplete()
		end
		self:OnBlockerClearenceComplete()
	end
end

function dbg_CleanLeaders()
	MapForEach(true, "ConstructionGroupLeader", function(o) 
		if o:CanDelete() and IsValid(o) then 
			DoneObject(o) 
		end 
	end)
	
	MapForEach(true, "DroneControl", function(o)
		for i = #o.constructions, 1, -1 do
			if not IsValid(o.constructions[i]) then
				o:RemoveConstruction(o.constructions[i])
			end
		end
	end)
end

function ConstructionGroupLeader:Complete(quick_build)
	if not IsValid(self) then return end -- happens when the user spams quick build and manages to complete the same site twice.

	local realm = GetRealm(self)
	realm:SuspendPassEdits("ConstructionGroupLeader.Complete")
	local construction_group = self.construction_group
	if construction_group then
		local c = #construction_group
		for i = 2, c do
			local construction = construction_group[i]
			if IsValid(construction) then --a member may be completed by another construction group
				--pipe/cable specific, lock connections before build, because they are going to get changed by destructors.
				if construction:HasMember("conn") then
					construction.construction_connections = construction.conn
				end
				assert(construction.construction_group ~= false, "Duplicate elements in constr grp.")
				if construction.construction_group[1] == self then --only supress destructors if we are its original construction group leader.
					construction.construction_group = false --suppress destructor
					construction.MarkSpentResources = empty_func --suppress mark function
				end
				
				if construction.demolishing then
					--cancel demolish for completed objects,
					construction:ToggleDemolish()
				end
			end
		end

		local last_completed
		for i = 2, c do
			local construction = construction_group[i]
			if IsValid(construction) then --a member may be completed by another construction group
				last_completed = construction:Complete(quick_build, i, c) or last_completed
			end
		end

		if last_completed then
			self:MarkSpentResources(last_completed) --mark spent resources in 1 building so refunds would be correct
		end
		self.drop_offs = nil
	end
	DoneObject(self)
	realm:ResumePassEdits("ConstructionGroupLeader.Complete")
end

function ConstructionGroupLeader:CanDelete()
	if not IsValid(self) then return false end --already deleted.
	local construction_group = self.construction_group
	if not construction_group or #construction_group == 1 then return true end
	local diff_leader_count = 0
	for i = 2, #construction_group do
		local construction = construction_group[i]
		local grp = construction.construction_group
		if not grp or grp[1] ~= self then --the element has a different leader than us
			diff_leader_count = diff_leader_count + 1
		end
	end

	return diff_leader_count == #self.construction_group - 1
end

function ConstructionGroupLeader:SetConstructionSiteEntity()
end

function ConstructionGroupLeader:PickEntity()
	return false
end

local debug_constr_grp_leaders = false
if Platform.developer and debug_constr_grp_leaders then
	GlobalVar("all_construction_group_leaders", {})
	
	function ConstructionGroupLeader:Done()
		table.remove_entry(all_construction_group_leaders, self)
		print("leader removed, total leaders:", #all_construction_group_leaders)
	end
	
	function CreateConstructionGroup(input_building_class, pos, map_id, prio, instabuild, per_object_bbox, use_group_goto, params)
		local construction_group = {}
		local group_params = {
			construction_group = construction_group, 
			priority = prio or 2, 
			instant_build = instabuild or false,
			per_object_bbox = per_object_bbox,
			use_group_goto = use_group_goto
		}
		group_params = table.union(group_params, params)
		local obj = PlaceObjectIn("ConstructionGroupLeader", map_id, group_params)
		obj:SetBuildingClass(input_building_class)
		obj:SetPos(pos)
		all_construction_group_leaders[#all_construction_group_leaders + 1] = obj
		print("leader added, total leaders:", #all_construction_group_leaders)
		construction_group[1] = obj
		return construction_group
	end
else
	function CreateConstructionGroup(input_building_class, pos, map_id, prio, instabuild, per_object_bbox, use_group_goto, params)
		local construction_group = {}
		local group_params = {
			construction_group = construction_group, 
			priority = prio or 2, 
			instant_build = instabuild or false,
			per_object_bbox = per_object_bbox,
			use_group_goto = use_group_goto
		}
		if params then
			group_params = table.union(group_params, params)
		end
		local obj = PlaceObjectIn("ConstructionGroupLeader", map_id, group_params)
		obj:SetBuildingClass(input_building_class)
		obj:SetPos(pos)
		construction_group[1] = obj
		return construction_group
	end
end
-------------------------switch construction site-----------------------------------------------------------
------------------------------------------------------------------------------------------------------------
DefineClass.GridSwitchConstructionSite = {
	__parents = { "ConstructionSite" },
	entity = false,
	default_label = false,
	is_construction_complete = false, --else canceled.
	disable_selection = false,
	can_complete_during_init = false,
	
	obj_to_turn_into_switch = false,
	
	flags = { gofSpecialOrientMode = true },
	orient_mode = "terrain",
	
	sign_spot = "Origin",
	sign_offset = point(0, 0, 15*guim),
	rename_allowed = false,
}

local function steal_attaches(self, o, supply_resource)
	if g_Classes[o.class].UpdateVisuals(o, supply_resource) then
		self:DestroyAttaches()
		
		o:ForEachAttach(function(attach)
			local a = attach:GetAttachAngle()
			self:Attach(attach)
			attach:SetAttachAngle(a)
		end)
		
		self:UpdateConstructionVisualization()
	end
end

function SavegameFixups.RestoreSwitchUpdateVisualsFunction()
	MapForEach("map", "ElectricityGridElement", "LifeSupportGridElement", function(o)
					if o.is_switch then
						o.UpdateVisuals = nil
					end
				end)
end

function GridSwitchConstructionSite:GameInit()
	if IsValid(self.obj_to_turn_into_switch) then
		local o = self.obj_to_turn_into_switch
		if IsKindOf(o, "ElectricityGridElement") then
			self.sign_offset = point30
		else
			assert(o:CanMakePillar(self))
		end
		o.switch_cs = self
		o.force_hub = true
		o:ClearEnumFlags(const.efVisible)
		o.UpdateVisuals = function(o, supply_resource)
			steal_attaches(self, o, supply_resource)
		end
		o.conn = nil --force update visuals to not early out
		o:UpdateVisuals()
	end
end

function GridSwitchConstructionSite:RestoreObjToTurnIntoSwitch()
	if IsValid(self.obj_to_turn_into_switch) and self.obj_to_turn_into_switch.force_hub then
		local o = self.obj_to_turn_into_switch
		o.UpdateVisuals = nil
		o.force_hub = nil
		o.switch_cs = nil
		o:SetEnumFlags(const.efVisible)
		o.last_visual_pillar = min_int --force update visuals to not early out
		o:DestroyAttaches()
		if IsKindOf(o, "LifeSupportGridElement") and not o.is_switch and not o.pillar then
			local count, first, second = o:GetNumberOfConnections()
			o:SetAngle(first * 60 * 60)
		end
		o.conn = nil
		o:UpdateVisuals()
	end
end

function GridSwitchConstructionSite:Done()
	self:RestoreObjToTurnIntoSwitch()
end

function GridSwitchConstructionSite:Complete(quick_build, current, total)
	if not IsValid(self) then 
		self:RestoreObjToTurnIntoSwitch()
		return 
	end
	if not IsValid(self.obj_to_turn_into_switch) then
		--cable/pipe got destroyed
		DoneObject(self)
		return
	end
	
	if quick_build then
		self:OnQuickBuild()
	end
	
	local reselect = SelectedObj == self
	self.is_construction_complete = true
	self.obj_to_turn_into_switch:MakeSwitch(self)
	self.obj_to_turn_into_switch.name = self.name or ""
	self:RestoreObjToTurnIntoSwitch()
	
	if self:IsPinned() and not self.obj_to_turn_into_switch:IsPinned() then
		self.obj_to_turn_into_switch:TogglePin()
	end
	
	DoneObject(self)
	
	if reselect then
		CreateGameTimeThread(SelectObj, self.obj_to_turn_into_switch)
	end
end
----------- Infopanel
function ConstructionSite:GetBuildPoints()
	local class = self.building_class_proto
	return class.build_points/100
end

function ConstructionSite:GetConstructedBuildPoints()
	if self.construction_group and self ~= self.construction_group[1] then
		return self.construction_group[1]:GetConstructedBuildPoints()
	end
	if self:IsWaitingResources() then return 0 end	
	local bp = self:GetBuildPoints()
	return bp - self.construct_request:GetActualAmount()/100
end

function ConstructionSite:GetConstructionBuildPointsProgress()
	if self.construction_group and self ~= self.construction_group[1] then
		return self.construction_group[1]:GetConstructionBuildPointsProgress()
	end
	if self:IsWaitingResources() or not self.construct_request then return 0 end
	if not self:IsBlockerClearenceComplete() then return 0 end
	local b_p = self:GetConstructionCost("build_points")
	return b_p == 0 and 100 or 100 - MulDivRound(self.construct_request:GetActualAmount(), 100, b_p)
end

function ConstructionSite:GetResourceProgress()
	local grp = self.construction_group
	if grp and self ~= grp[1] then
		return grp[1]:GetResourceProgress()
	end
	local class = self.building_class_proto
	local items = {}
	local resources = self.construction_resources
	if resources then
		for _,res in ipairs(ConstructionResourceList) do
			local req = resources[res]
			if req then
				local res_amount = (self.construction_costs_at_start[res] or 0)
				items[#items+1] = T{618, "<left><resource><right><resource(remaining,total,res)>",
					resource = GetResourceInfo(res).display_name or "",
					remaining = res_amount - req:GetActualAmount(),
					total = res_amount,
					res = res}
			end
		end
	end
	return table.concat(items, "\n")
end		

-- provide stub for all missing classes
function UnpersistedMissingClass:GetDisplayName()
	return T(77, "Unknown")
end

function ConstructionSite:GetDisplayName()
	local class = self.building_class_proto
	return self.name~="" and Untranslated(self.name) or class:GetDisplayName()
end

function ConstructionSite:Getui_description()
	local class = self.building_class_proto
	return class.description
end

function ConstructionSite:GetPinIcon()
	local data = self.building_class_proto
	return data and data.display_icon or PinnableObject.GetPinIcon(self)
end

function ConstructionSite:GetIPStatus()
	if not self:IsBlockerClearenceCompleteUIOnly() then
		local ret = T(627, "The construction site is being cleared.")
		if not self.construction_group or not self.construction_group[1].instant_build then
			ret = ret .. 
					"<newline>" ..
					self:GetResourceProgress()
		end
		return ret
	elseif self:IsWaitingResources() then
		return self:GetResourceProgress()
	end
	return ""
end

function ConstructionSite:IsOutsideCommandRange(ignore_cg)
	local construction_group = self.construction_group
	if not ignore_cg and construction_group then
		local i = 1
		local c = #construction_group
		while i <= c do
			if construction_group[i]:IsOutsideCommandRange(true) then
				i = i + 1
			else
				return false
			end
		end
		return true
	end

	if #self.command_centers == 0 then
		for _, stock in ipairs(self.stockpiles_underneath or empty_table) do
			for _, cc in ipairs(stock.command_centers) do
				if cc.working then return false end
			end
		end
		
		for _, rock in ipairs(self.waste_rocks_underneath or empty_table) do
			for _, cc in ipairs(rock.command_centers) do
				if cc.working then return false end
			end
		end
		
		if #(self.city.labels.AncientArtifactInterface or "") > 0 then
			return false
		end
		
		return true
	else
		return Building.IsOutsideCommandRange(self)
	end
end

function ConstructionSite:SnappedTo(building)
	self.snapped_to = building
end

function OnMsg.GatherFXActors(list)
	list[#list + 1] = "ConstructionSite"
end

DefineClass.WireFramedPrettification = {
	__parents = { "Shapeshifter" },
	flags = { cofComponentCustomData = true },
	construction_stage = 1,
	GetSelectionRadiusScale = false,
}

function WireFramedPrettification:GameInit()
	self:ChangeEntity(self.entity)
	PrepareForConstruction(self)
	local bb = box(0, 0, min_int, 1, 1, max_int)
	self:SetConstruction(0, self.construction_stage, bb)
end

function WireFramedPrettification:UpdateConstructionShaderParams()
	local bb = box(0, 0, min_int, 1, 1, max_int)
	self:SetConstruction(0, self.construction_stage, bb)
end

GlobalVar("g_ConstructionNanitesResearched", false)
function OnNanitesResearched()
	g_ConstructionNanitesResearched = true
	MapsForEach(true, "ConstructionSite", function(o) o:StartNaniteThread() end)
end
function OnMsg.TechResearched(tech_id, research, first_time)
	if tech_id == "ConstructionNanites" then
		OnNanitesResearched()
	end
end

function OnMsg.ConstructionCostChanged(building, resource)
	local refresh_cost = function(object)
		if object.building_class == building then
			object:RefreshConstructionResources()
		end
	end
	MapsForEach(true, "ConstructionSite", refresh_cost)
end
