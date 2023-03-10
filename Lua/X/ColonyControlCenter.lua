function City:GetColonyStatsButtons()
	local resource_overview_obj = GetCityResourceOverview(self)
	local t = {
		{
			button_caption = T(547, "Colonists"),
			button_text = T(9640, "Show historical data for Colonists, unemployed and homeless."),
			on_icon = "UI/Icons/ColonyControlCenter/colonist_on.tga",
			off_icon = "UI/Icons/ColonyControlCenter/colonist_off.tga",
			{
				caption = function()
					return T{8959, "<graph_right>Colonists</graph_right> <em>(<colonists>)</em>",
						colonists = #(self.labels.Colonist or ""),
					}
				end,
				data = { self.ts_colonists, }
			},
			{
				caption = function()
					return T{8961, "<graph_left>Unemployed</graph_left> <em>(<unemployed>)</em> and <graph_right>Homeless</graph_right> <em>(<homeless>)</em>",
						unemployed = #(self.labels.Unemployed or ""),
						homeless = #(self.labels.Homeless or ""),
					}
				end,
				data = { self.ts_colonists_unemployed, self.ts_colonists_homeless, },
			},
			id = "colonists",
		},
		{
			button_caption = T(716941050141, "Transportation"),
			button_text = T(9641, "Show historical data for Drones and Shuttles."),
			on_icon = "UI/Icons/ColonyControlCenter/drones_on.tga",
			off_icon = "UI/Icons/ColonyControlCenter/drones_off.tga",
			{
				caption  = function()
					return T{8962, "<graph_right>Drones</graph_right> <em>(<drones>)</em>",
						drones = #(self.labels.Drone or ""),
					}
				end,
				data = { self.ts_drones, }
			},
			{
				caption = function()
					return T{8963, "<graph_right>Shuttles</graph_right> <em>(<shuttles>)</em>",
						shuttles = self:CountShuttles(),
					}
				end,
				data = { self.ts_shuttles, },
			},
			id = "transportation",
		},
		{
			button_caption = T(3980, "Buildings"),
			button_text = T(9642, "Show historical data for colony Buildings and completed constructions per Sol."),
			on_icon = "UI/Icons/ColonyControlCenter/buildings_on.tga",
			off_icon = "UI/Icons/ColonyControlCenter/buildings_off.tga",
			{
				caption = function()
					return T{8964, "<graph_right>Buildings</graph_right> <em>(<buildings>)</em>",
						buildings = self:CountBuildings(),
					}
				end,
				data = { self.ts_buildings, }
			},
			{
				caption = function()
					return T{8966, "<graph_right>Completed Constructions per Sol</graph_right> <em>(<constructions>)</em>",
						constructions = (self.constructions_completed_today or 0),
					}
				end,
				data = { self.ts_constructions_completed, },
			},
			id = "buildings",
		},
		{
			button_caption = T(79, "Power"),
			button_text = T(9643, "Show historical data for Power - stored Power, average production and demand per hour."),
			on_icon = "UI/Icons/ColonyControlCenter/power_on.tga",
			off_icon = "UI/Icons/ColonyControlCenter/power_off.tga",
			{
				caption = function()
					return T{8967, "<graph_right>Stored Power</graph_right> <em>(<power>)</em>",
						power = FormatResourceValueMaxResource(resource_overview_obj, resource_overview_obj:GetTotalStoredPower()),
					}
				end,
				data = { self.ts_resources_grid.electricity.stored, scale = const.ResourceScale, }
			},
			{
				caption = function()
					return T{11519, "<graph_left>Produced</graph_left> <em>(<produced>)</em> and <graph_right>Demanded</graph_right> <em>(<demand>)</em> Power (average per hour)",
						produced = FormatResourceValueMaxResource(resource_overview_obj, resource_overview_obj:GetTotalProducedPower()),
						demand = FormatResourceValueMaxResource(resource_overview_obj, resource_overview_obj:GetTotalRequiredPower())
					}
				end,
				data = { self.ts_resources_grid.electricity.production, self.ts_resources_grid.electricity.consumption, scale = const.ResourceScale}
			},
			id = "power",
		},
		{
			button_caption = T(682, "Oxygen"),
			button_text = T(9645, "Show historical data for Oxygen - stored Oxygen, average production and demand per hour."),
			on_icon = "UI/Icons/ColonyControlCenter/oxygen_on.tga",
			off_icon = "UI/Icons/ColonyControlCenter/oxygen_off.tga",
			{
				caption = function()
					return T{8971, "<graph_right>Stored Oxygen</graph_right> <em>(<air>)</em>",
						air = FormatResourceValueMaxResource(resource_overview_obj, resource_overview_obj:GetTotalStoredAir()),
					}
				end,
				data = { self.ts_resources_grid.air.stored, scale = const.ResourceScale, }
			},
			{
				caption = function()
					return T{11520, "<graph_left>Produced</graph_left> <em>(<produced>)</em> and <graph_right>Demanded</graph_right> <em>(<demand>)</em> Oxygen (average per hour)",
						produced = FormatResourceValueMaxResource(resource_overview_obj,resource_overview_obj:GetTotalProducedAir()),
						demand = FormatResourceValueMaxResource(resource_overview_obj,resource_overview_obj:GetTotalRequiredAir()),
					}
				end,
				data = { self.ts_resources_grid.air.production, self.ts_resources_grid.air.consumption, scale = const.ResourceScale}
			},
			id = "oxygen",
		},
		{
			button_caption = T(681, "Water"),
			button_text = T(9646, "Show historical data for Water - stored Water, average production and demand per hour."),
			on_icon = "UI/Icons/ColonyControlCenter/water_on.tga",
			off_icon = "UI/Icons/ColonyControlCenter/water_off.tga",
			{
				caption = function()
					return T{8973, "<graph_right>Stored Water</graph_right> <em>(<water>)</em>",
						water = FormatResourceValueMaxResource(resource_overview_obj, resource_overview_obj:GetTotalStoredWater()),
					}
				end,
				data = { self.ts_resources_grid.water.stored, scale = const.ResourceScale, }
			},
			{
				caption = function()
					return T{11521, "<graph_left>Produced</graph_left> <em>(<produced>)</em> and <graph_right>Demanded</graph_right> <em>(<demand>)</em> Water (average per hour)",
						produced = FormatResourceValueMaxResource(resource_overview_obj, resource_overview_obj:GetTotalProducedWater()),
						demand = FormatResourceValueMaxResource(resource_overview_obj, resource_overview_obj:GetTotalRequiredWater()),
					}
				end,
				data = { self.ts_resources_grid.water.production, self.ts_resources_grid.water.consumption, scale = const.ResourceScale}
			},
			id = "water",
		},
	}
	for i, id in ipairs(GetStockpileResourceList()) do
		local ts_resource = self.ts_resources[id]
		local resource_name = FormatResourceName(id)
		t[#t + 1] = {
			button_caption = T{9647, "<resource>", resource = resource_name},
			button_text = T{9648, "Show historical data for <resource> - stockpiled <resource>, production and consumption per Sol.", resource = resource_name},
			on_icon = "UI/Icons/ColonyControlCenter/" .. id:lower() .. "_on.tga",
			off_icon = "UI/Icons/ColonyControlCenter/" .. id:lower() .. "_off.tga",
			{
				caption = function()
					return T{8977, "<graph_right>Stockpiled <resource></graph_right> <em>(<amount>)</em>",
						resource = resource_name,
						amount = resource_overview_obj["GetAvailable" .. id](resource_overview_obj) / const.ResourceScale,
					}
				end,
				data = { ts_resource.stockpile, scale = const.ResourceScale}
			},
			{
				caption = function()
					return T{8979, "<graph_left>Produced</graph_left> <em>(<produced>)</em> and <graph_right>Consumed</graph_right> <em>(<consumed>)</em> (per Sol)",
						produced = resource_overview_obj["Get" .. id .. "ProducedYesterday"](resource_overview_obj) / const.ResourceScale,
						consumed = resource_overview_obj["Get" .. id .. "ConsumedByConsumptionYesterday"](resource_overview_obj) / const.ResourceScale,
					}
				end,
				data = { ts_resource.produced, ts_resource.consumed, scale = const.ResourceScale}
			},
			margin_right = (i % 4 == 0 and i ~= #GetStockpileResourceList() ) and 40 or nil,
			id = id,
		}
	end
	return t
end

function CommandCenterChooseLifeSupportGridBuilding(context)
	local water, air = context.water, context.air
	local combined_grid = { }
	combined_grid.consumers = table.union(water.consumers, air.consumers)
	combined_grid.producers = table.union(water.producers, air.producers)
	combined_grid.elements  = table.union(water.elements,  air.elements)
	return CommandCenterChooseGridBuilding(combined_grid)
end

function CommandCenterChooseGridBuilding(grid)
	--choose biggest consumer
	if #grid.consumers > 0 then
		local max_consumption, max_consumer = 0, false
		for i,consumer in ipairs(grid.consumers) do
			if max_consumption < consumer.consumption then
				max_consumption = consumer.consumption
				max_consumer = consumer
			end
		end		
		if max_consumer and max_consumer.building then
			return max_consumer.building
		end
	end
	
	--choose biggest producer
	if #grid.producers > 0 then
		local max_production, max_producer = 0, false
		for i,producer in ipairs(grid.producers) do
			if max_production < producer.production then
				max_production = producer.production
				max_producer = producer
			end
		end		
		if max_producer and max_producer.building then
			return max_producer.building
		end
	end
	
	--choose just the first element
	local first_element = grid.elements[1]
	return first_element and first_element.building
end

function FilterColonistByTrait(colonist, trait)
	if not trait then return end
	local trait_id = trait.id
	return not colonist.traits[trait_id]
end

function SortColonistTable(context, colonists)
	local age_groups = table.invert(const.ColonistAges)
	local specializations = table.invert(table.keys(const.ColonistSpecialization))
	local stat_sort = context.sort_type
	if not stat_sort then
		table.stable_sort(colonists, function(a,b)
			if a.age_trait ~= b.age_trait then
				return age_groups[a.age_trait] < age_groups[b.age_trait]
			elseif a.specialist ~= b.specialist then
				return specializations[a.specialist] < specializations[b.specialist]
			else
				return a.age < b.age
			end
		end)
	else
		table.stable_sort(colonists, function(a,b)
			local a_stat = stat_sort == "stat_morale" and a.traits["Renegade"] and 0 or a[stat_sort]
			local b_stat = stat_sort == "stat_morale" and b.traits["Renegade"] and 0 or b[stat_sort]
			if context.sort_ascending then
				return a_stat < b_stat
			else
				return a_stat > b_stat
			end
		end)
	end
	return colonists
end

function GetCommandCenterColonists(context)
	local colonists
	local container
	local effects_filter
	if context then
		container = context.dome and context.dome or UICity
		if context.problematic_colonists then
			colonists = GetDetrimentalStatusColonists(container)
		end
		effects_filter = {}
		if context.homeless then
			effects_filter["StatusEffect_Homeless"] = true
		end
		if context.unemployed then
			effects_filter["StatusEffect_Unemployed"] = true
		end
	end
	colonists = colonists or table.icopy(container.labels.Colonist) or empty_table
	local able = context.able_to_work
	local unable = context.unable_to_work
	local remove_unable_colonists = able ~= false and not unable
	local remove_able_colonists = unable and able == false
	for i = #colonists, 1, -1 do
		local colonist = colonists[i]
		local removed
		if FilterColonistByTrait(colonist, context["trait_Age Group"]) or
			FilterColonistByTrait(colonist, context["trait_Negative"]) or
			FilterColonistByTrait(colonist, context["trait_Specialization"]) or
			FilterColonistByTrait(colonist, context["trait_other"]) or
			FilterColonistByTrait(colonist, context["trait_Positive"]) or
			context["trait_interest"] and not table.find(GetInterests(colonist), context["trait_interest"].id)
		then
			table.remove(colonists, i)
			removed = true
		end
		if not removed and (remove_able_colonists or remove_unable_colonists) then
			local can_work = colonist:CanWork()
			if (can_work and remove_able_colonists) or
				(not can_work and remove_unable_colonists) then
				table.remove(colonists, i)
				removed = true
			end
		end
		if not removed then
			for effect, _ in pairs(effects_filter or empty_table) do
				if not colonist.status_effects[effect] then
					table.remove(colonists, i)
					break
				end
			end
		end
	end
	colonists = SortColonistTable(context, colonists)
	return colonists
end

function SpawnTraitsPopup(button, traits_group)
	local dlg = GetDialog(button)
	local popup = XTemplateSpawn("CommandCenterPopup", dlg)
	popup.context = button
	popup:SetAnchor(button.box)
	local list = popup.idContainer
	
	local entry = XTemplateSpawn("CommandCenterPopupItem", list)
	entry:SetText(T(11679, "No filter"))
	entry.OnPress = function(self, gamepad)
		dlg.context["trait_" .. traits_group] = nil
		dlg.idContent:RespawnContent()
		if popup.window_state ~= "destroying" then
			popup:Close()
		end
	end
	
	local traits
	if traits_group == "interest" then
		traits = { }
		for i=1,#ServiceInterestsList do
			local interest_id = ServiceInterestsList[i]
			if interest_id ~= "needFood" then
				table.insert(traits, { id = interest_id, display_name = Interests[interest_id].display_name })
			end
		end
		TSort(traits, "display_name")
	else
		traits = GetTSortedTraits(traits_group)
	end
	for i,trait in ipairs(traits) do
		local entry = XTemplateSpawn("CommandCenterPopupItem", list, trait)
		entry:SetText(trait.display_name)
		entry.OnPress = function(self, gamepad)
			dlg.context["trait_" .. traits_group] = self.context
			dlg.idContent:RespawnContent()
			if popup.window_state ~= "destroying" then
				popup:Close()
			end
		end
	end
	
	popup:Open()
end

function CommandCenterHidePopup(win)
	local dlg = GetDialog(win or "ColonyControlCenter")
	local popup = dlg:ResolveId("idPopup")
	if popup and popup.window_state ~= "destroying" then
		popup:Close()
	end
end

function Colonist:UICommandCenterStatUpdate(win, stat)
	local v = self:GetProperty(stat)
	local tv
	if stat == "Morale" and self.traits.Renegade or 
		stat == "Satisfaction" and not self.traits.Tourist then
		win.idLabel:SetVisible(false)
		win.idNoStat:SetVisible(true)
	else
		local low = g_Consts.LowStatLevel / const.Scale.Stat
		if v < low then
			tv = T{4194, "<red><value></red>", value = v}
		else
			tv = Untranslated(v)
		end
	end
	win.idLabel:SetText(tv)
end

function Colonist:GetUIOverviewInfo()
	local rows = {}
	rows[#rows + 1] = T(4358, "Age Group<right><Age>")
	rows[#rows + 1] = T(4359, "Specialization<right><Specialization>")
	rows[#rows + 1] = T(4360, "Residence<right><h SelectResidence InfopanelSelect><ResidenceDisplayName></h>")
	rows[#rows + 1] = T(213479829949, "<UIWorkplaceLine>")
	rows[#rows + 1] = self:GetUIInfo(true)
	rows[#rows + 1] = T(9722, "<center><em>Traits</em>")
	rows[#rows + 1] = self:GetUITraitsRollover()
	rows[#rows + 1] = T(9723, "<center><em>Interests</em>")
	rows[#rows + 1] = self:GetUIInterestsLine()
	local warning = self:GetUIWarning()
	if warning then
		rows[#rows + 1] = "<center>" .. T(47, "<red>Warning</red>")
		rows[#rows + 1] = warning
	end
	return table.concat(rows, "<newline><left>")
end

function GetCommandCenterPowerGrids(context)
	local result = { }
	local all_grids = UICity.electricity
	for i, grid in ipairs(all_grids) do
		--exclude grids containing only autonomous consumers and nothing else
		--also exclude empty grids (only cables)
		
		if #grid.storages > 0 or #grid.producers > 0 then
			table.insert(result, grid)
		elseif #grid.consumers > 0 then
			local only_autonomous = true
			for j,consumer in ipairs(grid.consumers) do
				--autonomous consumers have this flag set to 1
				if consumer.building.disable_electricity_consumption == 0 then
					only_autonomous = false
					break
				end
			end
			
			if not only_autonomous then
				table.insert(result, grid)
			end
		end
	end
	
	return result
end

function GetCommandCenterLifeSupportGrids(context)
	local result = { }
	local all_grids = UICity.water
	for i, grid in ipairs(all_grids) do
		--exclude grids containing only autonomous consumers and nothing else
		--also exclude empty grids (only cables)
		
		local entry = { water = grid, air = grid.air_grid }
		
		if (#entry.water.storages + #entry.air.storages) > 0 or (#entry.water.producers + #entry.air.producers) > 0 then
			table.insert(result, entry)
		elseif (#entry.water.consumers + #entry.air.consumers) > 0 then
			local only_autonomous = true
			for j,consumer in ipairs(entry.water.consumers) do
				--autonomous consumers have this flag set to 1
				if IsKindOf(consumer.building, "ElectricityConsumer") and consumer.building.disable_electricity_consumption == 0 then
					only_autonomous = false
					break
				end
			end
			for j,consumer in ipairs(entry.air.consumers) do
				--autonomous consumers have this flag set to 1
				if IsKindOf(consumer.building, "ElectricityConsumer") and consumer.building.disable_electricity_consumption == 0 then
					only_autonomous = false
					break
				end
			end
			
			if not only_autonomous then
				table.insert(result, entry)
			end
		end
	end
	
	return result
end

function IsCCBuildingTransportation(building)
	return IsKindOfClasses(building, "DroneControl", "ShuttleHub")
end

function IsCCBuildingStorage(building)
	return IsKindOfClasses(building, "ResourceStockpileBase", "WaterStorage", "AirStorage", "ElectricityStorage")
end

function IsCCBuildingOther(building)
	if IsKindOf(building, "GridTransfer") then return true end
	return building.build_category ~= "Decorations" and
		GetTopLevelBuildMenuCategory(building.build_category) ~= "Terraforming" and
		not IsCCBuildingTransportation(building) and
		not IsKindOfClasses(building, "ResourceStockpileBase", "WaterStorage", "AirStorage", "ElectricityStorage", "ElectricityProducer", "ResourceProducer", "WaterProducer", "AirProducer", "Service", "Residence", "Workshop", "DroneFactory")
end

local function IsCCBuilding(building)
	return not building.count_as_building and (not IsKindOfClasses(building, "UniversalStorageDepot", "WasteRockDumpSite") and (not IsDlcAvailable("armstrong") or not IsKindOf(building, "LandscapeLake")))
end

function FilterCommandCenterBuildings(buildings, context)
	local any_filter = context.decorations or
		context.other or
		context.power_producers ~= false or
		context.production_buildings ~= false or
		context.residential or
		context.services ~= false or
		context.storages or
		context.terraforming or
		context.transportation

	local IsCCBuildingTransportation = IsCCBuildingTransportation
	local IsCCBuildingStorage = IsCCBuildingStorage
	local IsCCBuildingOther = IsCCBuildingOther

	for i = #buildings, 1, -1 do
		local building = buildings[i]
		if IsCCBuilding(building) or IsKindOfClasses(building, "PassageRamp", "PassageGridElement", "Passage", "ConstructionSite") or
			context.inside_buildings == false and context.outside_buildings ~= false and building.parent_dome or
			context.outside_buildings == false and context.inside_buildings ~= false and not building.parent_dome or
			any_filter and not context.decorations and building.build_category == "Decorations" or
			any_filter and not context.storages and IsCCBuildingStorage(building) or
			any_filter and context.power_producers == false and IsKindOf(building, "ElectricityProducer") and not IsKindOf(building, "GridTransfer") or
			any_filter and context.production_buildings == false and IsKindOfClasses(building, "ResourceProducer", "WaterProducer", "AirProducer", "DroneFactory") and not IsKindOf(building, "GridTransfer") or
			any_filter and context.services == false and (IsKindOf(building, "Service") or IsKindOf(building, "Workshop")) and (building.build_category ~= "Decorations" or not context.decorations) or
			any_filter and not context.residential and IsKindOf(building, "Residence") or
			any_filter and not context.terraforming and IsDlcAvailable("armstrong") and GetTopLevelBuildMenuCategory(building.build_category) == "Terraforming" or
			any_filter and not context.transportation and IsCCBuildingTransportation(building) or
			any_filter and not context.other and IsCCBuildingOther(building) or
			building.destroyed or building.bulldozed
		then
			table.remove(buildings, i)
		end
	end
end

function GetCommandCenterBuildings(context)
	local buildings
	local dome = context.dome
	if dome then
		--get nearby buildings
		local query_hexrad = dome:GetOutsideWorkplacesDist() + 7
		local query_filter = function(bld, self)
				if not bld:IsKindOf("Building") then return false end
				local dome = IsObjInDome(bld)
				return (not dome or dome == self) and self:IsBuildingInWorkRange(bld) and bld.dome_label and true or false
		end
		local realm = GetRealm(dome)
		local objs = realm:MapGet(dome, "hex", query_hexrad, "DomeOutskirtBld", query_filter, dome)
		buildings = table.icopy(dome.labels.Building) or {}
		for _, obj in ipairs(objs) do
			table.insert_unique(buildings, obj)
		end
	else
		buildings = table.icopy(UICity.labels.Building) or empty_table
	end
		
	FilterCommandCenterBuildings(buildings, context)
	
	local build_categories = table.invert(table.map(BuildCategories, "id"))
	local subcategories = BuildMenuSubcategories
	table.stable_sort(buildings, function(a, b)
		if a.build_category ~= b.build_category then
			local cat_a = build_categories[GetTopLevelBuildMenuCategory(a.build_category)]
			local cat_b = build_categories[GetTopLevelBuildMenuCategory(b.build_category)]
			if cat_a == cat_b then
				local parent_cat = BuildCategories[cat_a].id
				if a.build_category == parent_cat then
					return true
				elseif b.build_category == parent_cat then
					return false
				else
					--both a and b are in subcategories
					return subcategories[a.build_category].build_pos < subcategories[b.build_category].build_pos
				end
			end
			return cat_a < cat_b
		elseif a.build_pos ~= b.build_pos then
			return a.build_pos < b.build_pos
		else
			return a.name < b.name
		end
	end)
	return buildings
end

function Building:GetUIProductionTexts(items, short)
	items = items or {}
	if self:IsKindOf("GridTransfer") then
		return items
	end
	if self:IsKindOf("AirProducer") or self:IsKindOf("WaterProducer") or IsKindOf(self, "ElectricityProducer") or IsKindOf(self, "Mine") or self:IsKindOf("ResourceProducer") and self:GetResourceProduced() and not self:IsKindOf("Farm") then
		if not short then items[#items + 1] = T(9649, "<center><em>Production</em>") end
		if self:IsKindOf("AirProducer") then
			if not short then
				items[#items + 1] = self:GetUISectionAirProductionRollover()
			else
				items[#items + 1] = T{9769, "<air(ProductionEstimate)>", self.air}
			end
		elseif self:IsKindOf("WaterProducer") then
			items[#items + 1] = self:GetWaterProductionText(short)
			if not short and self:IsKindOf("ResourceProducer") and self.wasterock_producer then
				items[#items + 1] = T(474, "Stored Waste Rock<right><wasterock(GetWasterockAmountStored,wasterock_max_storage)>")
			end
		elseif IsKindOf(self, "Mine") then
			items[#items + 1] = short and T(9724, "<resource(PredictedDailyProduction, GetResourceProduced)>") or T(472, "Production per Sol<right><resource(PredictedDailyProduction, GetResourceProduced)>")
			if not short then
				items[#items + 1] = T(473, "Stored <resource(exploitation_resource)><right><resource(GetAmountStored,max_storage,exploitation_resource)>")
				items[#items + 1] = T(474, "Stored Waste Rock<right><wasterock(GetWasterockAmountStored,wasterock_max_storage)>")
			end
		elseif self:IsKindOf("ResourceProducer") then
			for _, producer in ipairs(self.producers) do
				local resource_produced = producer:GetResourceProduced()
				local resource_name = GetResourceInfo(resource_produced).id
				if short then
					items[#items + 1] = T{9724, "<resource(PredictedDailyProduction, GetResourceProduced)>", 
					resource = resource_name, PredictedDailyProduction = producer:GetPredictedDailyProduction(), GetResourceProduced = resource_produced, producer}
				else
					items[#items + 1] = T{466, "Production per Sol (predicted)<right><resource(PredictedDailyProduction, GetResourceProduced)>", 
					resource = resource_name, PredictedDailyProduction = producer:GetPredictedDailyProduction(), GetResourceProduced = resource_produced, producer}
					items[#items + 1] = T{478, "Stored <resource(GetResourceProduced)><right><resource(GetAmountStored,max_storage,GetResourceProduced)>", 
						resource = resource_name, GetResourceProduced = resource_produced, GetAmountStored = producer:GetAmountStored(), max_storage = producer.max_storage, producer}
				end
			end
			if not short and self.wasterock_producer then
				items[#items + 1] = T(474, "Stored Waste Rock<right><wasterock(GetWasterockAmountStored,wasterock_max_storage)>")
			end
		elseif self:IsKindOf("ElectricityProducer") then
			items[#items + 1] = short and T(9725, "<power(UIPowerProduction)>") or T(437, "Power production<right><power(UIPowerProduction)>")
			if not short and self:IsKindOf("WindTurbine") then
				items[#items + 1] = T(438, "Elevation boost<right><ElevationBonus>%")
			end
		end
	elseif self:IsKindOf("Farm") and short then
		local index = self.current_crop
		local crop = self:GetCrop(index)
		if crop then
			local production = (self:CalcExpectedProduction(index) or crop.FoodOutput) / (crop.GrowthTime / const.DayDuration)
			local prod = production / 1000
			local frac = production / 100 % 10
			local warn = (production == 0 and TLookupTag("<red>") or TLookupTag("<em>")) or ""
			local icon = const.TagLookupTable["icon_" .. crop.ResourceType]
			items[#items + 1] = T{7414, "<warn><prod>.<frac><icon>", warn = warn, prod = prod, frac = frac, icon = icon}
		end
	end
	return items
end

function Building:GetOverviewInfo()
	local rows = {self.description .. T(316, "<newline>")}
	rows = self:GetUIProductionTexts(rows)
	local res = self:GetUIConsumptionTexts()
	if next(res) then
		rows[#rows + 1] = T(9650, "<center><em>Consumption</em>")
		if res.power then rows[#rows + 1] = res.power end
		if res.air then rows[#rows + 1] = res.air end
		if res.water then rows[#rows + 1] = res.water end
		if res.stored_water then rows[#rows + 1] = res.stored_water end
		if res.resource then rows[#rows + 1] = res.resource end
		if res.food then rows[#rows + 1] = res.food end
		if res.upgrade then rows[#rows + 1] = res.upgrade end
	end
	if self:IsKindOf("Service") then
		rows[#rows + 1] = T(9651, "<center><em>Visitors</em>")
		rows[#rows + 1] = T(708009583391, "Inside<right><count(visitors)>/<colonist(max_visitors)>")
		rows[#rows + 1] = T(529, "Today<right><colonist(visitors_per_day)>")
		rows[#rows + 1] = T(530, "Lifetime<right><colonist(visitors_lifetime)>")
		rows[#rows + 1] = T(531, "Service Comfort<right><Stat(EffectiveServiceComfort)>")
	end
	if self:IsKindOf("Residence") then
		rows[#rows + 1] = Untranslated("<center><em>") .. T(10405, "Other") .. TLookupTag("</em>")
		rows[#rows + 1] = T(702480492408, "Residents<right><UIResidentsCount> / <colonist(UICapacity)>")
		rows[#rows + 1] = T(424588493338, "Comfort of residents<right><em><Stat(service_comfort)></em>")
	end
	if self:IsKindOf("ElectricityStorage") then
		rows[#rows + 1] = T(9652, "<center><em>Power Storage</em>")
		rows[#rows + 1] = self.electricity:GetElectricityUIMode()
		rows[#rows + 1] = T(464, "Stored Power<right><power(StoredPower)>")
		rows[#rows + 1] = T(465, "Capacity<right><power(capacity)>")
		rows[#rows + 1] = T(7784, "Max output<right><power(max_electricity_discharge)>")
	end
	if self:IsKindOf("AirStorage") then
		rows[#rows + 1] = T(9653, "<center><em>Oxygen Storage</em>")
		rows[#rows + 1] = self.air:GetUIMode()
		rows[#rows + 1] = T(521, "Stored Oxygen<right><air(StoredAir)>")
		rows[#rows + 1] = T(522, "Capacity<right><air(air_capacity)>")
		rows[#rows + 1] = T(7783, "Max output<right><air(max_air_discharge)>")
	end
	if self:IsKindOf("WaterStorage") then
		rows[#rows + 1] = T(9654, "<center><em>Water Storage</em>")
		rows[#rows + 1] = self.water:GetUIMode()
		rows[#rows + 1] = T(523, "Stored Water<right><water(StoredWater)>")
		rows[#rows + 1] = T(111319356806, "Capacity<right><water(water_capacity)>")
		rows[#rows + 1] = T(7785, "Max output<right><water(max_water_discharge)>")
	end
	local power_grid = self:IsKindOfClasses("ElectricityProducer", "ElectricityStorage") and self.electricity and self.electricity.grid
	if power_grid then
		rows[#rows + 1] = T(9655, "<center><em>Power Grid</em>")
		rows[#rows + 1] = T{576, "Power production<right><power(current_production)>", current_production = power_grid.current_production, power_grid}
		rows[#rows + 1] = T{321, "Total demand<right><power(consumption)>", consumption = power_grid.consumption, power_grid}
		rows[#rows + 1] = T{322, "Stored Power<right><power(current_storage)>", current_storage = power_grid.current_storage, power_grid}
	end
	local water_grid = self:IsKindOfClasses("WaterProducer", "WaterStorage") and self.water and self.water.grid
		or self:IsKindOf("LifeSupportGridElement") and self.pillar and self.water and self.water.grid
	if water_grid then
		rows[#rows + 1] = T(9656, "<center><em>Water Grid</em>")
		rows[#rows + 1] = T{545, "Water production<right><water(current_production)>", current_production = water_grid.current_production, water_grid}
		rows[#rows + 1] = T{332, "Total demand<right><water(consumption)>", consumption = water_grid.consumption, water_grid}
		rows[#rows + 1] = T{333, "Stored Water<right><water(current_storage)>", current_storage = water_grid.current_storage, water_grid}
	end
	local air_grid = self:IsKindOfClasses("AirProducer", "AirStorage") and self.air and self.air.grid 
		or self:IsKindOf("LifeSupportGridElement") and self.pillar and self.water and self.water.grid and self.water.grid.air_grid
	if air_grid then
		rows[#rows + 1] = T(9657, "<center><em>Oxygen Grid</em>")
		rows[#rows + 1] = T{541, "Oxygen production<right><air(current_production)>", current_production = air_grid.current_production, air_grid}
		rows[#rows + 1] = T{327, "Total demand<right><air(consumption)>", consumption = air_grid.consumption, air_grid}
		rows[#rows + 1] = T{328, "Stored Oxygen<right><air(current_storage)>", current_storage = air_grid.current_storage, air_grid}
	end
	if self:IsKindOf("ShuttleHub") then
		rows[#rows + 1] = T(9658, "<center><em>Shuttles</em>")
		rows[#rows + 1] = T(766548374853, "Shuttles<right><count(shuttle_infos)>/<max_shuttles>")
		rows[#rows + 1] = T(398, "In flight<right><FlyingShuttles>")
		rows[#rows + 1] = T(8700, "Refueling<right><RefuelingShuttles>")
		rows[#rows + 1] = T(717110331584, "Idle<right><IdleShuttles>")
		rows[#rows + 1] = T(8701, "Global load <right><GlobalLoadText>")
	end
	if self:IsKindOf("DroneHub") then
		rows[#rows + 1] = T(9659, "<center><em>Drones</em>")
		rows[#rows + 1] = T(732959546527, "Drones<right><drone(DronesCount,MaxDronesCount)>")
		rows[#rows + 1] = T(935141416350, "<DronesStatusText>")
		if self.total_requested_drones > 0 then
			rows[#rows + 1] = T(8463, "<OrderedDronesCount>")
		end
	end
	if (IsKindOf(self, "UniversalStorageDepot") or IsKindOf(self, "MechanizedDepot")) and not self:IsKindOf("SupplyRocket") and not IsKindOf(self, "SpaceElevator") then
		if (self:DoesAcceptResource("Metals") or self:DoesAcceptResource("Concrete") or self:DoesAcceptResource("Food") or self:DoesAcceptResource("PreciousMetals") or self:DoesAcceptResource("PreciousMinerals")) then
			rows[#rows + 1] = T(9726, "<center><em>Basic Resources</em>")
			if self:DoesAcceptResource("Concrete") then
				rows[#rows + 1] = T(497, "<resource('Concrete' )><right><concrete(Stored_Concrete, MaxAmount_Concrete)>")
			end
			if self:DoesAcceptResource("Food") then
				rows[#rows + 1] = T(498, "<resource('Food' )><right><food(Stored_Food, MaxAmount_Food)>")
			end
			if self:DoesAcceptResource("PreciousMetals") then
				rows[#rows + 1] = T(499, "<resource('PreciousMetals' )><right><preciousmetals(Stored_PreciousMetals, MaxAmount_PreciousMetals)>")
			end
			if self:DoesAcceptResource("Metals") then
				rows[#rows + 1] = T(496, "<resource('Metals' )><right><metals(Stored_Metals, MaxAmount_Metals)>")
			end
			if self:DoesAcceptResource("PreciousMinerals") then
				rows[#rows + 1] = T(12774, "<resource('PreciousMinerals' )><right><preciousminerals(Stored_PreciousMinerals, MaxAmount_PreciousMinerals)>")
			end
		end
		if (self:DoesAcceptResource("Polymers") or self:DoesAcceptResource("Electronics") or self:DoesAcceptResource("MachineParts") or self:DoesAcceptResource("Fuel") or self:DoesAcceptResource("MysteryResource")) then
			rows[#rows + 1] = T(9727, "<center><em>Advanced Resources</em>")
			if self:DoesAcceptResource("Polymers") then
				rows[#rows + 1] = T(502, "<resource('Polymers' )><right><polymers(Stored_Polymers, MaxAmount_Polymers)>")
			end
			if self:DoesAcceptResource("Electronics") then
				rows[#rows + 1] = T(503, "<resource('Electronics' )><right><electronics(Stored_Electronics, MaxAmount_Electronics)>")
			end
			if self:DoesAcceptResource("MachineParts") then
				rows[#rows + 1] = T(504, "<resource('MachineParts' )><right><machineparts(Stored_MachineParts, MaxAmount_MachineParts)>")
			end
			if self:DoesAcceptResource("Fuel") then
				rows[#rows + 1] = T(505, "<resource('Fuel' )><right><fuel(Stored_Fuel, MaxAmount_Fuel)>")
			end
			if self:DoesAcceptResource("MysteryResource") then
				rows[#rows + 1] = T(8671, "<resource('MysteryResource' )><right><mysteryresource(Stored_MysteryResource, MaxAmount_MysteryResource)>")
			end
		end
		if UIColony:IsTechResearched("MartianVegetation") and self:DoesAcceptResource("Seeds") then
			rows[#rows + 1] = Untranslated("<center><em>") .. T(12476, "Terraforming") .. TLookupTag("</em>")
			rows[#rows + 1] = T(11843, "Seeds") .. Untranslated("<right><seeds(Stored_Seeds, MaxAmount_Seeds)>")
		end
	end
	return rows
end

function Building:GetUIOverviewInfo()
	local rows = self:GetOverviewInfo()
	local warning = self:GetUIWarning()
	if warning then
		rows[#rows + 1] = "<center>" .. T(47, "<red>Warning</red>")
		rows[#rows + 1] = warning
	end
	return #rows > 0 and table.concat(rows, "<newline><left>") or ""
end

function Building:GetUIConsumptionRow()
	local res = self:GetUIConsumptionTexts("short")
	local t = {}
	if res.power then t[#t + 1] = res.power end
	if res.air then t[#t + 1] = res.air end
	if res.water then t[#t + 1] = res.water end
	if res.stored_water then t[#t + 1] = res.stored_water end
	if res.resource then t[#t + 1] = res.resource end
	if res.upgrade then t[#t + 1] = res.upgrade end
	return table.concat(t, " ")
end

function Building:GetUIProductionRow()
	local res = self:GetUIProductionTexts(nil, "short")
	return table.concat(res, " ")
end

function Building:GetUIEffectsRow()
	if self:IsKindOf("Service") then
		return T(9728, "<count(visitors)>/<colonist(max_visitors)>")
	elseif self:IsKindOf("Residence") then
		return T(9729, "<UIResidentsCount>/<colonist(UICapacity)>")
	elseif self:IsKindOf("DroneControl") then
		return T(9730, "<drone(DronesCount,MaxDronesCount)>")
	elseif self:IsKindOf("ShuttleHub") then
		return T(9770, "<count(shuttle_infos)>/<max_shuttles>")
	elseif self:IsKindOf("Dome") then
		return T(9771, "<colonist(ColonistCount, LivingSpace)>")
	elseif (IsKindOf(self, "UniversalStorageDepot") or IsKindOf(self, "MechanizedDepot")) and not self:IsKindOf("SupplyRocket") and not IsKindOf(self, "SpaceElevator") then
		local sum = type(self.resource) == "table" and #self.resource > 1
		local stored, max = 0,0
		if (self:DoesAcceptResource("Metals") or self:DoesAcceptResource("Concrete") or self:DoesAcceptResource("Food") or self:DoesAcceptResource("PreciousMetals")or self:DoesAcceptResource("PreciousMinerals")) then
			if self:DoesAcceptResource("Concrete") then
				if sum then
					stored = stored + self:GetStored_Concrete()
					max = max + self:GetMaxAmount_Concrete()
				else
					return T(9731, "<concrete(Stored_Concrete, MaxAmount_Concrete)>")
				end
			end
			if self:DoesAcceptResource("Food") then
				if sum then
					stored = stored + self:GetStored_Food()
					max = max + self:GetMaxAmount_Food()
				else
					return T(9732, "<food(Stored_Food, MaxAmount_Food)>")
				end
			end
			if self:DoesAcceptResource("PreciousMetals") then
				if sum then
					stored = stored + self:GetStored_PreciousMetals()
					max = max + self:GetMaxAmount_PreciousMetals()
				else
					return T(9733, "<preciousmetals(Stored_PreciousMetals, MaxAmount_PreciousMetals)>")
				end
			end
			if self:DoesAcceptResource("Metals") then
				if sum then
					stored = stored + self:GetStored_Metals()
					max = max + self:GetMaxAmount_Metals()
				else
					return T(9734, "<metals(Stored_Metals, MaxAmount_Metals)>")
				end
			end
			if self:DoesAcceptResource("PreciousMinerals") then
				if sum then
					stored = stored + self:GetStored_PreciousMinerals()
					max = max + self:GetMaxAmount_PreciousMinerals()
				else
					return T(12775, "<preciousminerals(Stored_PreciousMinerals, MaxAmount_PreciousMinerals)>")
				end
			end
		end
		if (self:DoesAcceptResource("Polymers") or self:DoesAcceptResource("Electronics") or self:DoesAcceptResource("MachineParts") or self:DoesAcceptResource("Fuel") or self:DoesAcceptResource("MysteryResource")) then
			if self:DoesAcceptResource("Polymers") then
				if sum then
					stored = stored + self:GetStored_Polymers()
					max = max + self:GetMaxAmount_Polymers()
				else
					return T(9735, "<polymers(Stored_Polymers, MaxAmount_Polymers)>")
				end
			end
			if self:DoesAcceptResource("Electronics") then
				if sum then
					stored = stored + self:GetStored_Electronics()
					max = max + self:GetMaxAmount_Electronics()
				else
					return T(9736, "<electronics(Stored_Electronics, MaxAmount_Electronics)>")
				end
			end
			if self:DoesAcceptResource("MachineParts") then
				if sum then
					stored = stored + self:GetStored_MachineParts()
					max = max + self:GetMaxAmount_MachineParts()
				else
					return T(9737, "<machineparts(Stored_MachineParts, MaxAmount_MachineParts)>")
				end
			end
			if self:DoesAcceptResource("Fuel") then
				if sum then
					stored = stored + self:GetStored_Fuel()
					max = max + self:GetMaxAmount_Fuel()
				else
					return T(9738, "<fuel(Stored_Fuel, MaxAmount_Fuel)>")
				end
			end
			if self:DoesAcceptResource("MysteryResource") then
				if sum then
					stored = stored + self:GetStored_MysteryResource()
					max = max + self:GetMaxAmount_MysteryResource()
				else
					return T(9739, "<mysteryresource(Stored_MysteryResource, MaxAmount_MysteryResource)>")
				end
			end
		end
		if UIColony:IsTechResearched("MartianVegetation") and self:DoesAcceptResource("Seeds") then
			if sum then
				stored = stored + self:GetStored_Seeds()
				max = max + self:GetMaxAmount_Seeds()
			else
				return Untranslated("<seeds(Stored_Seeds, MaxAmount_Seeds)>")
			end
		end
		return T{9740, "<stored>/<max>", stored = FormatResourceValueMaxResource(empty_table,stored), max = FormatResourceValueMaxResource(empty_table, max), empty_table}
	elseif self:IsKindOf("ElectricityStorage") then
		return  T(9741, "<power(StoredPower, capacity)>")
	elseif self:IsKindOf("AirStorage") then
		return  T(9742, "<air(StoredAir, air_capacity)>")
	elseif self:IsKindOf("WaterStorage") then
		return  T(9743, "<water(StoredWater, water_capacity)>")
	elseif self:IsKindOf("WasteRockDumpSite") then
		return T(9744, "<wasterock(Stored_WasteRock, MaxAmount_WasteRock)>")
	elseif self:IsKindOf("Workplace") then
		local count, max = 0, 0
		if self.active_shift > 0 then --single shift building
			count = #self.workers[self.active_shift]
			max = self.max_workers
		else
			for i = 1, self.max_shifts do
				count = count + #self.workers[i]
			end
			max = self.max_shifts * self.max_workers
		end
		return T{9772, "<colonist(count, max)>", count = count, max = max, self}
	elseif self:IsKindOf("TrainingBuilding") then
		local count, max = 0, 0
		if self.active_shift > 0 then --single shift building
			count = #self.visitors[self.active_shift]
			max = self.max_visitors
		else
			for i = 1, self.max_shifts do
				count = count + #self.visitors[i]
			end
			max = self.max_shifts * self.max_visitors
		end
		return T{9772, "<colonist(count, max)>", count = count, max = max, self}
	end
	
	return ""
end

function GetCommandCenterDomesList()
	local communities = UICity.labels.Community or empty_table
	table.sort(communities, function(a,b)
		if a.build_category ~= "Domes" then --geoscape dome comes last
			return false
		elseif b.build_category ~= "Domes" then --geoscape dome comes last
			return true
		elseif a.build_pos ~= b.build_pos then
			return a.build_pos < b.build_pos
		else
			a.name = IsT(a.name) and _InternalTranslate(a.name) or a.name
			b.name = IsT(b.name) and _InternalTranslate(b.name) or b.name
			return a.name < b.name
		end
	end)
	return communities
end

function SpawnDomesPopup(button)
	local dlg = GetDialog(button)
	local popup = XTemplateSpawn("CommandCenterPopup", dlg)
	popup.context = button
	popup:SetAnchor(button.box)
	local list = popup.idContainer
	
	local entry = XTemplateSpawn("CommandCenterPopupItem", list)
	entry:SetText(T(596159635934, "Entire Colony"))
	entry.OnPress = function(self, gamepad)
		dlg.context.dome = nil
		button:OnContextUpdate(dlg.context)
		dlg.idContent:RespawnContent()
		if popup.window_state ~= "destroying" then
			popup:Close()
		end
	end
	
	local domes = GetCommandCenterDomesList()
	for i,dome in ipairs(domes) do
		local entry = XTemplateSpawn("CommandCenterPopupItem", list, dome)
		entry:SetText(T(7305, "<DisplayName>"))
		entry.OnPress = function(self, gamepad)
			dlg.context.dome = self.context
			button:OnContextUpdate(dlg.context)
			dlg.idContent:RespawnContent()
			if popup.window_state ~= "destroying" then
				popup:Close()
			end
		end
	end
	
	popup:Open()
end

function GetCommandCenterNextDome(cur_dome, dir)
	local domes = GetCommandCenterDomesList()
	local idx = cur_dome and table.find(domes, cur_dome)
	local next_dome = idx and domes[idx + dir] or domes[dir == 1 and 1 or #domes]
	if next_dome then
		return next_dome
	end
end

function SelectCommandCenterNextDome(host, dir)
	local context = host.context or {}
	local dome = context.dome
	dome = GetCommandCenterNextDome(dome, dir)
	while dome and not dome:GetUIInteractionState() do
		dome = GetCommandCenterNextDome(dome, dir)		
	end
	context.dome = dome
	host.context = context
	local list = host.idList
	local is_focused = list:IsFocused(true)
	if is_focused then
		list:SetFocus(false, true)
	end
	list:OnContextUpdate()
	list:ScrollTo(0,0)
	host.idButtons:OnContextUpdate(context)
	if is_focused then
		list:SetFocus()
		list:SetSelection(1)
	end
end

function GetDomeFilterRolloverText(win)
	local mode = GetDialogMode(win)
	if mode == "colonists" then
		return GetColonistsFilterRollover(win.context, T(9660, "Filter by Dome."))
	elseif mode == "buildings" then
		return GetBuildingsFilterRollover(win.context, T(9660, "Filter by Dome."))
	end
end

local function add_separator(text, ...)
	local t = {...}
	if not text then return text end
	local count = 0
	for _, val in ipairs(t) do
		if val then
			count = count + 1
		end
	end
	if count > 1 then
		text = text .. ", "
	elseif count == 1 then
		text = text .. T(9661, " or ")
	end
	return text
end

function GetTransportationFilterRollover(context, description)
	local rows = {}
	if context.drone_hubs ~= false then table.insert(rows, T(5048, "Drone Hubs")) end
	if context.drone_assemblers    then table.insert(rows, T(5046, "Drone Assemblers")) end
	if context.rovers ~= false     then table.insert(rows, T(951182332337, "RC Rovers")) end
	if context.shuttle_hubs        then table.insert(rows, T(5260, "Shuttle Hubs")) end
	if context.rockets             then table.insert(rows, T(296967872321, "Rockets")) end
	
	local res
	if #rows > 0 then
		res = T(9667, "<center><em>Active Filters</em>") .. "<newline><left>- " .. table.concat(rows, "<newline>- ")
	end
	
	if description then
		return table.concat({description, res}, "<newline><newline>")
	else
		return res
	end
end

function GetColonistsFilterRollover(context, description)
	local rows = {}
	local dome_name = context.dome and (T(9773, "Dome: ") .. context.dome:GetDisplayName()) or T(596159635934, "Entire Colony")
	
	rows[#rows + 1] = context["trait_Age Group"]      and context["trait_Age Group"].display_name or nil
	rows[#rows + 1] = context["trait_Negative"]       and context["trait_Negative"].display_name or nil
	rows[#rows + 1] = context["trait_Specialization"] and context["trait_Specialization"].display_name or nil
	rows[#rows + 1] = context["trait_other"]          and context["trait_other"].display_name or nil
	rows[#rows + 1] = context["trait_Positive"]       and context["trait_Positive"].display_name or nil
	
	if (context.able_to_work ~= false) ~= (context.unable_to_work ~= false) then
		rows[#rows + 1] = (context.able_to_work ~= false) and T(9673, "Able to Work") or nil
		rows[#rows + 1] = (context.unable_to_work ~= false) and T(731124482973, "Unable to Work") or nil
	end
	if context.homeless then
		rows[#rows + 1] = T(9665, "Homeless colonists")
	end
	if context.unemployed then
		rows[#rows + 1] = T(9666, "Unemployed colonists")
	end
	if context.problematic_colonists then
		rows[#rows + 1] = T(7934, "Problematic colonists")
	end
	
	local res = T(9667, "<center><em>Active Filters</em>") .. "<newline><left>- " .. dome_name
	if #rows > 0 then
		res = res .. "<newline>- " .. table.concat(rows, "<newline>- ")
	end
	if description then
		return table.concat({description, res}, "<newline><newline>")
	else
		return res
	end
end

function GetBuildingsFilterRollover(context, description)
	local rows = {}
	local dome_name = not not context.dome and (T(9773, "Dome: ") .. context.dome:GetDisplayName()) or T(9774, "In the entire Colony")
	local inside_buildings = context.inside_buildings ~= false and T(367336674138, "Inside Buildings")
	local outside_buildings = context.outside_buildings ~= false and T(885971788025, "Outside Buildings")
	if inside_buildings then
		if outside_buildings then
			inside_buildings = inside_buildings .. T(9661, " or ")
		end
	end
	if inside_buildings or outside_buildings then
		rows[#rows + 1] = T{9668, "<inside_buildings><outside_buildings>", 
			inside_buildings = inside_buildings or "", outside_buildings = outside_buildings or ""}
	end
	local decorations = not not context.decorations and T(435618535856, "Decorations")
	local storages = not not context.storages and T(82, "Storages")
	local power_producers = context.power_producers ~= false and T(416682488997, "Power Producers")
	local production_buildings = context.production_buildings ~= false and T(932771917833, "Production Buildings")
	local services = context.services ~= false and T(133797343482, "Services")
	local residential = not not context.residential and T(316855249043, "Residential Buildings")
	local terraforming = not not context.terraforming and T(12095, "Terraforming Buildings")
	local transportation = not not context.transportation and T(716941050141, "Transportation")
	local other = not not context.other and T(814424953825, "Other Buildings")
	decorations =          add_separator(decorations, storages, power_producers, production_buildings, services, residential, terraforming, transportation, other)
	storages =             add_separator(             storages, power_producers, production_buildings, services, residential, terraforming, transportation, other)
	power_producers =      add_separator(                       power_producers, production_buildings, services, residential, terraforming, transportation, other)
	production_buildings = add_separator(                                        production_buildings, services, residential, terraforming, transportation, other)
	services =             add_separator(                                                              services, residential, terraforming, transportation, other)
	residential =          add_separator(                                                                        residential, terraforming, transportation, other)
	terraforming =         add_separator(                                                                                     terraforming, transportation, other)
	transportation =       add_separator(                                                                                                   transportation, other)
	if decorations or storages or power_producers or production_buildings or services or residential or terraforming or transportation or other then
		rows[#rows + 1] = T{12187, "<decorations><storages><power_producers><production_buildings><services><residential><terraforming><transportation><other>", 
			decorations = decorations or "",
			storages = storages or "",
			power_producers = power_producers or "",
			production_buildings = production_buildings or "",
			services = services or "",
			residential = residential or "",
			terraforming = terraforming or "",
			transportation = transportation or "",
			other = other or "",}
	end
	
	local res = T(9667, "<center><em>Active Filters</em>") .. "<newline><left>- " .. dome_name
	if #rows > 0 then
		res = res .. "<newline>- " .. table.concat(rows, "<newline>- ")
	end
	
	if description then
		return table.concat({description, res}, "<newline><newline>")
	else
		return res
	end
end

function Dome:GetOverviewInfo()
	local rows = {self.description .. "<newline>"}
	rows[#rows + 1] = self:GetUISectionCitizensRollover()
	local connected_domes = self:GetConnectedDomes()
	if next(connected_domes) then
		rows[#rows + 1] = T(9670, "<center><em>Connected Domes</em>")
		for dome, val in pairs(connected_domes) do
			rows[#rows + 1] = dome:GetDisplayName()
		end
	end
	return rows
end

function Community:UICommandCenterStatUpdate(win, stat)
	local stat_scale = const.Scale.Stat
	local v = GetAverageStat(self.labels.Colonist, stat) / stat_scale
	local tv
	local low = g_Consts.LowStatLevel / stat_scale
	if v < low then
		tv = Untranslated(string.format("<red>%d</red>", v))
	else
		tv = Untranslated(v)
	end
	win.idLabel:SetText(v)
end

function Community:UIHasDomePolicies()
	return false
end

function Dome:UIHasDomePolicies()
	return true
end

function Community:UIGetLinkedDomes()
	return ""
end

function Dome:UIGetLinkedDomes()
	return tostring(#table.keys(self:GetConnectedDomes()))
end

function Community:UICommandCenterGetJobsHomes()
	local homes = self:GetFreeLivingSpace()
	return 0, homes
end

function Dome:UICommandCenterGetJobsHomes()
	local jobs = GetFreeWorkplacesAround(self)
	if jobs <= 0 then
		jobs = self.labels.Unemployed and #self.labels.Unemployed or 0
		jobs = jobs > 0 and -jobs or jobs
	end
	local homes = self:GetFreeLivingSpace()
	if homes <= 0 then
		homes = self.labels.Homeless and #self.labels.Homeless or 0
		homes = homes > 0 and -homes or homes
	end
	return jobs, homes
end

function ToggleColonistsTraitsInterests(dialog)
	local context = dialog.context
	local interests = context.interests
	local traits = not interests
	dialog.idTraitsTitle:SetVisible(not traits)
	dialog.idInterestsTitle:SetVisible(traits)
	local list = dialog.idList
	for _, item in ipairs(list) do
		if #item > 0 then
			local child = item[1] -- item is an XVirtualContent control so we get its child
			child.idTraits:SetVisible(not traits)
			child.idInterests:SetVisible(traits)
		end
	end
	context.interests = traits
end

function ToggleBuildingsShiftsEffects(dialog)
	local context = dialog.context
	local shifts = context.shifts
	local effects = not shifts
	dialog.idEffectsTitles:SetVisible(not effects)
	dialog.idShiftsTitles:SetVisible(effects)
	local list = dialog.idList
	for _, item in ipairs(list) do
		if #item > 0 then
			local child = item[1] -- item is an XVirtualContent control so we get its child
			child.idEffects:SetVisible(not effects)
			child.idShifts:SetVisible(effects)
		end
	end
	context.shifts = effects
end

function ToggleCommandCenterFilter(button, name, valid_nil)
	local dlg = GetDialog(button)
	local context = dlg.context
	local value = valid_nil and context[name] ~= false or context[name]
	context[name] = not value
	local list = button:ResolveId("idList")
	list:OnContextUpdate()
	list:ScrollTo(0,0) -- reset page scroll when changing filters
	button:ResolveId("idButtons"):OnContextUpdate(context)
	XUpdateRolloverWindow(button)
end

function SetColonistsSorting(button, sort_type)
	local dlg = GetDialog(button)
	local context = dlg.context
	if sort_type ~= context.sort_type then
		context.sort_type = sort_type
		context.sort_ascending = false
	else
		context.sort_ascending = not context.sort_ascending
	end
	local list = button:ResolveId("idList")
	list:OnContextUpdate()
	list:ScrollTo(0,0) -- reset page scroll when changing filters
	button:ResolveId("idButtons"):OnContextUpdate(context)
	XUpdateRolloverWindow(button)
end

function GetCommandCenterActiveTransportFilters(context)
	local filters = {}
	filters.drone_hubs = context.drone_hubs or nil
	filters.drone_assemblers = context.drone_assemblers or nil
	filters.shuttle_hubs = context.shuttle_hubs or nil
	filters.rockets = context.rockets or nil
	filters.rovers = context.rovers or nil
	return filters
end

function GetCommandCenterTransportsList(context)
	local labels = UICity.labels
	local list = {}

	local active_filters = GetCommandCenterActiveTransportFilters(context)
	local no_filters = table.count(active_filters) == 0
	
	local drone_hubs =    (no_filters or active_filters.drone_hubs)       and labels.DroneHub     or empty_table
	local assemblers =    (no_filters or active_filters.drone_assemblers) and labels.DroneFactory or empty_table
	local rockets =       (no_filters or active_filters.rockets)          and labels.AllRockets   or empty_table
	local rc_rovers =     (no_filters or active_filters.rovers)           and labels.Rover        or empty_table
	local shuttle_hubs =  (no_filters or active_filters.shuttle_hubs)     and labels.ShuttleHub   or empty_table
	
	local sort_func = function(a,b) return a.name < b.name end
	if #(drone_hubs or "") > 0 then
		local h = {}
		for _, hub in ipairs(drone_hubs) do
			if not hub.destroyed and not hub.bulldozed then
				h[#h + 1] = hub
			end
		end
		table.stable_sort(h, sort_func)
		table.iappend(list, h)
	end
	if #(assemblers or "") > 0 then
		local a = {}
		for _, assembler in ipairs(assemblers) do
			if not assembler.destroyed and not assembler.bulldozed then
				a[#a + 1] = assembler
			end
		end
		table.stable_sort(a, sort_func)
		table.iappend(list, a)
	end
	if #(shuttle_hubs or "") > 0 then
		local s = {}
		for _, shuttle_hub in ipairs(shuttle_hubs) do
			if not shuttle_hub.destroyed and not shuttle_hub.bulldozed then
				s[#s + 1] = shuttle_hub
			end
		end
		table.stable_sort(s, sort_func)
		table.iappend(list, s)
	end
	if #(rockets or "") > 0 then
		local r = {}
		for _, rocket in ipairs(rockets) do
			if rocket.landed then
				r[#r + 1] = rocket
			end
		end
		table.stable_sort(r, sort_func)
		table.iappend(list, r)
	end
	
	if #(rc_rovers or empty_table) > 0 then
		local r = {}
		for _, rover in ipairs(rc_rovers) do
			if not rover.destroyed then
				r[#r + 1] = rover
			end
		end
		table.stable_sort(r, sort_func)
		table.iappend(list, r)
	end
	
	return list
end

function GetCommandCenterTransportInfo(self)
	local rows = {self.description}
	if IsKindOf(self, "ShuttleHub") then
		rows[#rows + 1] = self:GetUIRolloverText(true)
	end
	if IsKindOf(self, "DroneControl") then
		rows[#rows + 1] = T(316, "<newline>")
		rows[#rows + 1] = T(9659, "<center><em>Drones</em>")
		if IsKindOf(self, "SupplyRocket") then
			rows[#rows + 1] = T(963695586350, "Drones<right><drone(DronesCount)>")
		elseif IsKindOf(self, "RCRover") then
			rows[#rows + 1] = T(4491, "Drones<right><count(drones)>/<MaxDrones>")
		else
			rows[#rows + 1] = T(732959546527, "Drones<right><drone(DronesCount,MaxDronesCount)>")
		end
		rows[#rows + 1] = self:GetDronesStatusText()
	end
	if IsKindOf(self, "RCTransport") then
		rows[#rows + 1] = T(9805, "<newline><center><em>Resources carried</em>")
		if self:HasMember("GetStored_Concrete") then
			rows[#rows + 1] = T(343032565187, "Concrete<right><concrete(Stored_Concrete)>")
		end
		if self:HasMember("GetStored_Metals") then
			rows[#rows + 1] = T(455677282700, "Metals<right><metals(Stored_Metals)>")
		end
		if self:HasMember("GetStored_Food") then
			rows[#rows + 1] = T(788345915802, "Food<right><food(Stored_Food)>")
		end
		if self:HasMember("GetStored_PreciousMetals") then
			rows[#rows + 1] = T(925417865592, "Rare Metals<right><preciousmetals(Stored_PreciousMetals)>")
		end
		if self:HasMember("GetStored_PreciousMinerals") then
			rows[#rows + 1] = T(12776, "Exotic Minerals<right><preciousminerals(Stored_PreciousMinerals)>")
		end
		if self:HasMember("GetStored_Polymers") then
			rows[#rows + 1] = T(157677153453, "Polymers<right><polymers(Stored_Polymers)>")
		end
		if self:HasMember("GetStored_Electronics") then
			rows[#rows + 1] = T(624861249564, "Electronics<right><electronics(Stored_Electronics)>")
		end
		if self:HasMember("GetStored_MachineParts") then
			rows[#rows + 1] = T(407728864620, "Machine Parts<right><machineparts(Stored_MachineParts)>")
		end
		if self:HasMember("GetStored_Fuel") then
			rows[#rows + 1] = T(317815331128, "Fuel<right><fuel(Stored_Fuel)>")
		end
		if UIColony:IsTechResearched("MartianVegetation") and self:HasMember("GetStored_Seeds") then
			rows[#rows + 1] = T(12002, "Seeds<right><seeds(Stored_Seeds)>")
		end
	end
	if IsKindOf(self, "DroneFactory") then
		rows[#rows + 1] = T(9806, "<newline><center><em>Construction</em>")
		rows[#rows + 1] = T(410, "<UIConstructionStatus>")
		rows[#rows + 1] = T(8646, "Available Drone Prefabs<right><drone(available_drone_prefabs)>")
		rows[#rows + 1] = T(8539, "Scheduled Drone Prefabs<right><drone(drones_in_construction)>")
		if UIColony:IsTechResearched("ThePositronicBrain") then
			rows[#rows + 1] = T(6742, "Scheduled Biorobots<right><colonist(androids_in_construction)>")
		end
		rows[#rows + 1] = T(693516738839, "Required <resource(ConstructResource)><right><resource(ConstructResourceAmount, ConstructResourceTotal, ConstructResource)>")
	end
	local warning = self:GetUIWarning()
	if warning then
		rows[#rows + 1] = "<center>" .. T(47, "<red>Warning</red>")
		rows[#rows + 1] = warning
	end
	return #rows > 0 and table.concat(rows, "<newline><left>") or ""
end

GlobalVar("g_CommandCenterSavedContext", false)
GlobalVar("g_CommandCenterSavedMode", false)

if FirstLoad then
	g_CommandCenterOpen = false
end

function OnMsg.ChangeMap()
	g_CommandCenterOpen = false
end

function GetCommandCenterDialog()
	return GetDialog("ColonyControlCenter")
end

function OpenCommandCenter(context, mode)
	g_CommandCenterOpen = true
	local ui = GetInGameInterface()
	if ui.mode ~= "selection" and ui.mode ~= "overview" then
		ui:SetMode("selection") -- make sure there is no other dialog mode open
	end
	local dlg = OpenDialog("ColonyControlCenter", nil, context or g_CommandCenterSavedContext or {})
	mode = mode or g_CommandCenterSavedMode
	if mode and mode ~= "" then
		dlg:SetMode(mode)
	end
	local mode_dlg = GetInGameInterfaceModeDlg()
	mode_dlg:SetParent(dlg)
	return dlg
end

function CloseCommandCenter()
	CloseDialog("ColonyControlCenter")
	Msg("CommandCenterClosed")
end

function OnMsg.MessageBoxPreOpen()
	return CloseCommandCenter()
end

function OnMsg.SelectionAdded(obj)
	return CloseCommandCenter()
end

function OnMsg.SelectionRemoved(obj)
	return CloseCommandCenter()
end

function UpdateUICommandCenterWarning(win)
	CreateRealTimeThread(function(win)
		Sleep(50)
		if win.window_state == "destroying" then return end
		local context = win.context
		local warning = not not context:GetUIWarning()
		win.idRollover:SetImage(warning and "UI/Common/Hex_2_shine_2.tga" or "UI/Common/Hex_2_shine.tga")
		win.idWarningShine:SetVisible(warning)
		win.idWarning:SetVisible(warning)
	end, win)
end

function UpdateUICommandCenterRow(self, context, row_type)
	if row_type == "building" then
		local shifts = GetDialog(self).context.shifts
		self.idEffects:SetVisible(not shifts)
		self.idShifts:SetVisible(shifts)
		local consumption = context:GetUIConsumptionRow()
		local has_consumption = consumption ~= ""
		self.idConsumption:SetText(consumption)
		self.idConsumption:SetVisible(has_consumption)
		self.idNoConsumption:SetVisible(not has_consumption)
		local production = context:GetUIProductionRow()
		local has_production = production ~= ""
		self.idProduction:SetText(production)
		self.idProduction:SetVisible(has_production)
		self.idNoProduction:SetVisible(not has_production)
		local effects = context:GetUIEffectsRow()
		local has_effects = effects ~= ""
		self.idBuildingEffects:SetText(effects)
		self.idBuildingEffects:SetVisible(has_effects)
		self.idNoBuildingEffects:SetVisible(not has_effects)
	elseif row_type == "colonist" then
		self.idSpecialization:SetImage(context.pin_specialization_icon)
		local interests = GetDialog(self).context.interests
		self.idTraits:SetVisible(not interests)
		self.idInterests:SetVisible(interests)
	elseif row_type == "dome" then
		self.idLinked:SetText(context:UIGetLinkedDomes())
		local jobs, homes = context:UICommandCenterGetJobsHomes()
		self.idJobs:SetText(tostring(jobs))
		self.idHomes:SetText(tostring(homes))
	elseif row_type == "transportation" then
		self:SetRolloverText(GetCommandCenterTransportInfo(context))
		if IsKindOf(context, "DroneControl") then
			local lap_time = context:CalcLapTime()
			local image
			if lap_time >= const.DroneLoadLowThreshold then
				image = "UI/Icons/ColonyControlCenter/warning_low.tga"
				if lap_time >= const.DroneLoadMediumThreshold then
					image = "UI/Icons/ColonyControlCenter/warning_high.tga"
				end
				self.idLoad:SetImage(image)
			end
			self.idLoad:SetVisible(not not image)
			self.idDroneCount:SetText(tostring(#context.drones) .. "/" .. tostring(context:GetMaxDrones()) .. " <image UI/Icons/ColonyControlCenter/drone.tga 1400>")
		elseif IsKindOf(context, "DroneFactory") then
			local drone_count = (context.drones_in_construction or 0)
			local text = tostring(drone_count) .. " <image UI/Icons/ColonyControlCenter/drone.tga 1400>"
			if UIColony:IsTechResearched("ThePositronicBrain") then
				local android_count = (context.androids_in_construction or 0)
				text = text .. " " .. tostring(android_count) .. " <image UI/Icons/ColonyControlCenter/android.tga 1400>"
			end
			self.idQueuedPrefabs:SetText(text)
		elseif IsKindOf(context, "ShuttleHub") then
			local shuttles_load = context:GetGlobalLoad()
			local image
			if shuttles_load > 1 then
				image = "UI/Icons/ColonyControlCenter/warning_low.tga"
				if shuttles_load > 2 then
					image = "UI/Icons/ColonyControlCenter/warning_high.tga"
				end
				self.idLoad:SetImage(image)
			end
			self.idLoad:SetVisible(not not image)
			self.idShuttleCount:SetText(tostring(#context.shuttle_infos) .. "/" .. tostring(context.max_shuttles) .. " <image UI/Icons/ColonyControlCenter/shuttle.tga 1400>")
		end
	end
	self.idButtonIcon:SetImage(context:GetPinIcon())
	UpdateUICommandCenterWarning(self)
end

function CCC_ButtonListOnShortcut(self, shortcut, source)
	local rel = XShortcutToRelation[shortcut]
	if rel == "up" or rel == "down" then
		local focus = self.desktop:GetKeyboardFocus()
		local idx = table.find(self, focus)
		if idx then
			local dir = rel=="up" and -1 or 1
			local child = idx and self[idx + dir] or self[dir == 1 and 1 or #self]
			local scroll_area = GetParentOfKind(self, "XScrollArea")
			scroll_area:ScrollIntoView(child)
			child:SetFocus()
			return "break"
		end
	end
	return XContextWindow.OnShortcut(self, shortcut, source)
end