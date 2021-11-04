if FirstLoad then
	g_InfobarContextObj = false
end

DefineClass.Infobar = {
	__parents = { "XDialog" },
	navigation_button = false,
	
	last_width = false,
	last_height = false,
}

function CreateInfobarContextObject()
	if not g_InfobarContextObj then
		g_InfobarContextObj = InfobarObj:new()
	end
	return g_InfobarContextObj
end

function Infobar:Open(...)
	XDialog.Open(self, ...)
	
	self.idGamepadHint:SetImage(GetPlatformSpecificImagePath(self.navigation_button or "DPadUp"))
	local ctrlSeeds = self.idPad:ResolveId("idSeedsResources")
	if ctrlSeeds then
		ctrlSeeds:SetVisible(UIColony:IsTechResearched("MartianVegetation"))
	end
	self:RecalculateMargins()
	
	self:CreateThread("UpdateThread", self.UpdateThreadFunc, self)
	self:UpdateGamepadHint()
end

function Infobar:Close(...)
	XDialog.Close(self, ...)
	self:UpdateHintDlgMargins()
end

function Infobar:UpdateHintDlgMargins()
	local dlg = GetDialog("OnScreenHintDlg")
	if dlg then
		CreateGameTimeThread(dlg.RecalculateMargins, dlg)
	end
end

function Infobar:UpdateContext()
	ObjModified(g_InfobarContextObj)
end

function Infobar:UpdateThreadFunc()
	--triggers UI update every 1 second
	while self.window_state ~= "destroying" do
		self:UpdateContext()
		Sleep(1000)
	end
end

function Infobar:RecalculateMargins()
	self:SetMargins(GetSafeMargins())
end

function Infobar:OnLayoutComplete()
	if self.last_width ~= self.measure_width then
		local hint = self:ResolveId("idGamepadHint")
		if hint and hint:GetVisible() then
			local x, y = self.content_box:minxyz()
			local width, height = self.content_box:sizexyz()
			hint:SetLayoutSpace(x, y, width, height)
		end
		self.last_width = self.measure_width
	end
	if self.last_height ~= self.measure_height then
		self:UpdateHintDlgMargins()
		self.last_height = self.measure_height
	end
end

function OnMsg.SystemSize(pt)
	local dlg = GetDialog("Infobar")
	if dlg then
		dlg:RecalculateMargins()
	end
end

function Infobar:DockInPopupNotification(popup, dock)
	if dock then
		self:SetDock("none")
		self:SetParent(popup)
		self:EnumFocusChildren(function(child, x, y)
			assert(not rawget(child, "GetRolloverHint") and not rawget(child, "GetRolloverHintGamepad"))
			child.GetRolloverHint = function() return T(816190283569, --[[XTemplate Infobar RolloverHintGamepad]] "<DPad> Navigate <DPadDown> Close") end
			child.GetRolloverHintGamepad = child.GetRolloverHint
			rawset(child, "oldOnPress", rawget(child, "OnPress"))
			rawset(child, "OnPress", nil)
			child:SetFocusOrder(child.FocusOrder + point(-1, -1))
		end)
	else
		self:SetDock(false)
		self:SetParent(GetInGameInterface())
		self:EnumFocusChildren(function(child, x, y)
			child.GetRolloverHint = nil
			child.GetRolloverHintGamepad = nil
			rawset(child, "OnPress", rawget(child, "oldOnPress"))
			rawset(child, "oldOnPress", nil)
			child:SetFocusOrder(child.FocusOrder - point(-1, -1))
		end)
	end
	self:UpdateGamepadHint()
end

function UpdateInfobarVisibility(force)
	local igi = GetInGameInterface()
	if not igi then
		return
	end
	
	local visible = force or AccountStorage.Options.InfobarEnabled
	if visible then
		OpenDialog("Infobar", igi)
	else
		CloseDialog("Infobar")
	end
	
	local dlg = GetDialog("OnScreenHintDlg")
	if dlg then
		dlg:RecalculateMargins()
	end
end

function Infobar:OnSetFocus()
	self:UpdateGamepadHint()
	LockHRXboxLeftThumb("infobar")
	XDialog.OnSetFocus(self)
end

function Infobar:OnKillFocus()
	if self.window_state ~= "destroying" then
		self:UpdateGamepadHint()
		UnlockHRXboxLeftThumb("infobar")
		XDialog.OnKillFocus(self)
		UpdateInfobarVisibility()
	end
end

function Infobar:SetGamepadHintVisible(visible)
	if visible then
		self.last_width = false --reset width so that it can be shown correctly
	end
	local hint = self:ResolveId("idGamepadHint")
	if hint then
		hint:SetVisible(visible)
	end
end

function Infobar:UpdateGamepadHint()
	if not GetUIStyleGamepad() then
		self:SetGamepadHintVisible(false)
		return
	end
	
	local focus = GetDialog(self.desktop:GetKeyboardFocus())
	if IsKindOfClasses(focus, "SelectionModeDialog", "OverviewModeDialog", "InGameInterface") then
		self:SetGamepadHintVisible(true)
	elseif IsKindOf(focus, "PopupNotification") then
		self:SetGamepadHintVisible(focus.idList:IsFocused(true) and focus.idList:GetSelection()[1] == 1)
	else
		self:SetGamepadHintVisible(false)
	end
end

function OnMsg.GamepadUIStyleChanged()
	local infobar = GetDialog("Infobar")
	if infobar then infobar:UpdateGamepadHint() end
end

function OnMsg.TechResearched(tech_id, research, first_time)
	if tech_id == "MartianVegetation" then
		local infobar = GetDialog("Infobar")
		if infobar then
			local ctrlSeeds = infobar.idPad:ResolveId("idSeedsResources")
			if ctrlSeeds then
				ctrlSeeds:SetVisible(true)
			end
		end
	end
end

function Infobar:OnShortcut(shortcut, ...)
	if shortcut == "DPadDown" then
		self:SetFocus(false, true)
		return "break"
	elseif XShortcutToRelation[shortcut] then -- fix changing the gamespeed using DPad while navigating the infobar
		XDialog.OnShortcut(self, shortcut, ...)
		return "break"
	else
		return XDialog.OnShortcut(self, shortcut, ...)
	end
end

function OnMsg.CityStart(igi)
	CreateGameTimeThread(UpdateInfobarVisibility)
end

function OnMsg.SafeAreaMarginsChanged()
	local infobar = GetDialog("Infobar")
	if infobar then
		infobar:RecalculateMargins()
	end
end

--UI text getters

DefineClass.InfobarObj = {
	__parents = { "PropertyObject" },
}

function InfobarObj:FmtFunding(n, colorized)
	return self:FmtRes(n, colorized)

	--note: temporarily commented out
	--formatting funding in the infobar happens in a specific manner:
	--0,1,2...,999, 1k,2k,3k,...,999k, 1M,2M,3M,...,999M, 1B,2B,3B,...
	--local abs_n = abs(n)
	--if abs_n >= 1000000000 then --billion (B)
	--	return T{9775, "<n>B", n = T{tostring(n / 1000000000)}}
	--elseif abs_n >= 1000000 then --million (M)
	--	return T{9776, "<n>M", n = T{tostring(n / 1000000)}}
	--elseif abs_n >= 1000 then --thousand (k)
	--	return T{9777, "<n>k", n = T{tostring(n / 1000)}}
	--else -- 0-999
	--	return T{9778, "<n>", n = T{tostring(n)}}
	--end
end

function InfobarObj:FmtRes(n, colorized)
	--formatting resource in the infobar happens in a specific manner:
	--0,1,2...,999, 1k,1.9k,2k,...,999k, 1M,1.9M,2M,...,999M, 1B,1.9B,2B,...
	local tnum
	local abs_n, sign_n = abs(n), (n < 0) and -1 or 1
	if abs_n >= 1000000000 then --billion (B)
		local div = 1000000000
		local value, rem = (abs_n / div) * sign_n, (abs_n % div) / (div / 10)
		if rem > 0 then
			tnum = T{9807, --[[Infobar number formatting (billion)]] "<n>.<rem>B", n = T{tostring(value)}, rem = T{tostring(rem)}}
		else
			tnum = T{9775, --[[Infobar number formatting (billion)]] "<n>B", n = T{tostring(value)}}
		end
	elseif abs_n >= 1000000 then --million (M)
		local div = 1000000
		local value, rem = (abs_n / div) * sign_n, (abs_n % div) / (div / 10)
		if rem > 0 then
			tnum = T{9808, --[[Infobar number formatting (million)]] "<n>.<rem>M", n = T{tostring(value)}, rem = T{tostring(rem)}}
		else
			tnum = T{9776, --[[Infobar number formatting (million)]] "<n>M", n = T{tostring(value)}}
		end
	elseif abs_n >= 1000 then --thousand (k)
		local div = 1000
		local value, rem = (abs_n / div) * sign_n, (abs_n % div) / (div / 10)
		if rem > 0 then
			tnum = T{9809, --[[Infobar number formatting (thousand)]] "<n>.<rem>k", n = T{tostring(value)}, rem = T{tostring(rem)}}
		else
			tnum = T{9777, --[[Infobar number formatting (thousand)]] "<n>k", n = T{tostring(value)}}
		end
	else -- 0-999
		tnum = T{9778, --[[Infobar number formatting]] "<n>", n = T{tostring(n)}}
	end
	
	if colorized then
		if n >= 0 then
			return T{9779, "<green><tnum></green>", tnum = tnum}
		elseif n < 0 then
			return T{9780, "<red><tnum></red>", tnum = tnum}
		end
	else
		return tnum
	end
end

function InfobarObj:GetFundingText()
	local funding = GetCityResourceOverview(UICity):GetFunding()
	
	return T{9781, "$<funding>",
		funding = self:FmtFunding(funding),
	}
end

function InfobarObj:GetFundingRollover()
	return GetCityResourceOverview(UICity):GetFundingRollover()
end

function InfobarObj:GetResearchText()
	local estimate = GetCityResourceOverview(UICity):GetEstimatedRP()
	local progress = GetCityResourceOverview(UICity):GetResearchProgress()
	
	return T{9782, "<estimate><icon_Research_orig>  <progress><image UI/Icons/res_theoretical_research.tga>",
		estimate = self:FmtRes(estimate),
		progress = progress,
	}
end

function InfobarObj:GetResearchRollover()
	local rollover_items = GetCityResourceOverview(UICity):GetResearchRolloverItems()
	local research_text = T(5621, "No Active Research")
	local research_eta_text = ""
	if UIColony and UIColony:GetResearchInfo() then
		research_text = T{12475, "Researching <em><name></em> (<percent(progress)>)",
			name = function()
				local current_research = UIColony:GetResearchInfo()
				return current_research and TechDef[current_research].display_name or T(6761, "None")
			end,
			progress = function()
				local _, points, max_points = UIColony:GetResearchInfo()
				return max_points and MulDivRound(100, points, max_points) or 0
			end,
		}
		research_eta_text = T{13813, "Estimated remaining time: <timeH(researchETA)>",
			researchETA = function()
				local estimated_RP = GetCityResourceOverview(UICity):GetEstimatedRP()
				local time = 0
				if estimated_RP > 0 then
					local _, points, max_points = UIColony:GetResearchInfo()
					time = MulDivRound(const.HoursPerDay, (max_points - points), estimated_RP)
				end
				return time
			end,
		} 
	end
	table.insert(rollover_items, research_text)
	table.insert(rollover_items, research_eta_text)
	return table.concat(rollover_items, "<newline><left>")
end

function InfobarObj:GetGridResourcesText()
	local resource_overview = GetCityResourceOverview(UICity)
	local power = resource_overview:GetPowerNumber() / const.ResourceScale
	local air = resource_overview:GetAirNumber() / const.ResourceScale
	local water = resource_overview:GetWaterNumber() / const.ResourceScale

	return T{9783, "<power><icon_Power_orig>  <air><icon_Air_orig>  <water><icon_Water_orig>",
		power = self:FmtRes(power, "colorized"),
		air = self:FmtRes(air, "colorized"),
		water = self:FmtRes(water, "colorized"),
	}
end

function InfobarObj:GetElectricityText()
	local power = GetCityResourceOverview(UICity):GetPowerNumber() / const.ResourceScale
	return T{11680, "<power><icon_Power_orig>", power = self:FmtRes(power, "colorized"),}
end

function InfobarObj:GetLifesupportText()
	local resource_overview = GetCityResourceOverview(UICity)
	local air = resource_overview:GetAirNumber() / const.ResourceScale
	local water = resource_overview:GetWaterNumber() / const.ResourceScale

	return T{11681, "<air><icon_Air_orig>  <water><icon_Water_orig>", 
				air = self:FmtRes(air, "colorized"),
				water = self:FmtRes(water, "colorized"),}
end

function InfobarObj:GetElectricityGridRollover()
	return GetCityResourceOverview(UICity):GetElectricityGridRollover()
end

function InfobarObj:GetLifesupportGridRollover()
	return GetCityResourceOverview(UICity):GetLifesupportGridRollover()
end

function InfobarObj:GetGridResourcesRollover()
	return GetCityResourceOverview(UICity):GetGridRollover()
end

local function StockpileHasResource(obj, resource)
	if type(obj.stockpiled_amount) == "table" then
		return (obj.stockpiled_amount[resource] or 0) > 0
	elseif obj.resource == resource then
		return (obj.stockpiled_amount or 0) > 0
	end
end

local function CycleObjects(list)
	if not list or not next(list) then
		return
	end

	--find the next object to select (or use the first one)
	local idx = SelectedObj and table.find(list, SelectedObj) or 0
	local idx = (idx % #list) + 1
	local next_obj = list[idx]
	
	ViewAndSelectObject(next_obj)
	XDestroyRolloverWindow()
end

local IsKindOf = IsKindOf
local query_filter = function(obj, resource)
		return (IsKindOf(obj, "ResourceStockpileBase") and StockpileHasResource(obj, resource)) or
		       (IsKindOf(obj, "Drone") and obj.resource == resource) or
		       (IsKindOf(obj, "CargoShuttle") and obj.carried_resource_type == resource) or
		       (IsKindOf(obj, "ResourceProducer") and obj.producers[resource] and obj.producers[resource].total_stockpiled > 0)
end

function InfobarObj:CycleResources(resource)
	--gather all objects
	local realm = GetActiveRealm()
	local all_objs = realm:MapGet(true, "ResourceStockpileBase", "CargoShuttle", "DroneBase", "Building", query_filter, resource)
	if not all_objs or not next(all_objs) then
		return
	end
	
	--this fixed the issue when one object is a child of another
	--later SelectionPropagate() returns the same obj and cycling stucks
	local unique_objs = { }
	for i,obj in ipairs(all_objs) do
		obj = SelectionPropagate(obj)
		if not unique_objs[obj] then
			table.insert(unique_objs, obj)
			unique_objs[obj] = #unique_objs
		end
	end
	
	CycleObjects(unique_objs)
end

function InfobarObj:CycleDroneControl()
	local list = UICity.labels["DroneControl"] or empty_table
	local count = #list
	if count == 0 then return end
	local controllers = {}
	for i = count, 1, -1 do
		local obj = list[i]
		if obj:IsValidPos() then
			controllers[#controllers + 1] = obj
		end
	end
	
	CycleObjects(controllers)
end

function InfobarObj:CycleOverstayingTourists()
	local objs = g_OverstayingTourists[ActiveMapID]
	if not objs or #objs == 0 then return end
	CycleObjects(objs)
end

function InfobarObj:CycleColonists()
	local objs = UICity.labels.Colonist
	if not objs or #objs == 0 then return end
	CycleObjects(objs)
end

function InfobarObj:GetScannedResourcesText()
	return T(13671, "<icon_ScannedResources_orig>")
end

function InfobarObj:GetScannedResourcesRollover()
	return GetCityResourceOverview(UICity):GetScannedResourcesRollover()
end

function InfobarObj:GetMetalsText()
	local metals = GetCityResourceOverview(UICity):GetAvailableMetals() / const.ResourceScale
	return T{10096, "<metals><icon_Metals_orig>", metals = self:FmtRes(metals)}
end

function InfobarObj:GetConcreteText()
	local concrete = GetCityResourceOverview(UICity):GetAvailableConcrete() / const.ResourceScale
	return T{10097, "<concrete><icon_Concrete_orig>", concrete = self:FmtRes(concrete)}
end

function InfobarObj:GetFoodText()
	local food = GetCityResourceOverview(UICity):GetAvailableFood() / const.ResourceScale
	return T{10098, "<food><icon_Food_orig>", food = self:FmtRes(food)}
end

function InfobarObj:GetPreciousMetalsText()
	local precious_metals = GetCityResourceOverview(UICity):GetAvailablePreciousMetals() / const.ResourceScale
	return T{10099, "<precious_metals><icon_PreciousMetals_orig>", precious_metals = self:FmtRes(precious_metals)}
end

function InfobarObj:GetPreciousMineralsText()
	local precious_minerals = GetCityResourceOverview(UICity):GetAvailablePreciousMinerals() / const.ResourceScale
	return T{12777, "<precious_minerals><icon_PreciousMinerals_orig>", precious_minerals = self:FmtRes(precious_minerals)}
end

function InfobarObj:AppendResourceToRollover(rollover, restype, reslookup)
	local colony_maps = UIColony:GetActiveColonyMaps()
	
	if #colony_maps == 1 then
		return
	end

	table.insert(rollover, T(13672, "<newline><center><em>Other maps</em>"))
	
	local overall_res = GetResourceOverviewTotal()

	reslookup = reslookup or restype
	local total_amount = overall_res.non_roundable[reslookup] and overall_res.resources_total[reslookup] or overall_res.resources_total[reslookup] or 0
	local colonist_message = T{13825, "Total living across maps<right><resource(amount, type)>", amount = total_amount, type = restype }
	local tourist_message = T{13826, "Total staying across maps<right><resource(amount, type)>", amount = total_amount, type = restype }
	local resource_message = T{13673, "Total stored across maps<right><resource(amount, type)>", amount = total_amount, type = restype }
	local message = restype == ("Colonist" and colonist_message) or (restype == "Tourist" and tourist_message) or resource_message
	table.insert(rollover, message)

	for _,map_id in pairs(colony_maps) do
		if UICity.map_id ~= map_id then
			local map_name = T(UIColony:GetMapDisplayName(map_id))
			local amount = 0
			if Cities[map_id] then
				local res = GetCityResourceOverview(Cities[map_id])
				amount = overall_res.non_roundable[reslookup] and res.data[reslookup] or res.data[reslookup] or 0
			end
			table.insert(rollover, T{13674, "<map_name><right><resource(amount, type)>", map_name = map_name, amount = amount, type = restype })
		end
	end
end

function InfobarObj:ShouldShowDiscoveredDeposits(city)
	return false
end

function InfobarObj:GetMetalsRollover()
	local resource_overview = GetCityResourceOverview(UICity)

	local rollover = {
		resource_overview:GetBasicResourcesHeading(),
		T(316, "<newline>"),
		T{3636, "Metals production<right><metals(MetalsProducedYesterday)>", resource_overview},
		T{3637, "From surface deposits<right><metals(MetalsGatheredYesterday)>", resource_overview},
		T(316, "<newline>"),
		T{3638, "Metals consumption<right><metals(MetalsConsumedByConsumptionYesterday)>", resource_overview},
		T{3639, "Metals maintenance<right><metals(MetalsConsumedByMaintenanceYesterday)>", resource_overview},
		T{10081, "In construction sites<right><metals(MetalsInConstructionSitesActual, MetalsInConstructionSitesTotal)>", resource_overview},
		T{10526, "Upgrade construction<right><metals(MetalsUpgradeConstructionActual, MetalsUpgradeConstructionTotal)>", resource_overview},
	}
	
	if self:ShouldShowDiscoveredDeposits(UICity) then
		local discovered_deposits = UICity:GatherDiscoveredDeposits()
		local discovered_metals = discovered_deposits.Metals[1].amount or 0
		local discovered_subsurface_metals = discovered_deposits.Metals[2].amount or 0
	
		rollover[#rollover + 1] = T(316, "<newline>")
		rollover[#rollover + 1] = T{13814, "Discovered Metals<right><metals(number)>", number = discovered_metals}
		rollover[#rollover + 1] = T{13815, "Discovered Underground Metals<right><metalsDeep(number)>", number = discovered_subsurface_metals}
	end
	
	self:AppendResourceToRollover(rollover, "Metals")
	return table.concat(rollover, "<newline><left>")
end

function InfobarObj:GetConcreteRollover()
	local resource_overview = GetCityResourceOverview(UICity)

	local rollover = {
		resource_overview:GetBasicResourcesHeading(),
		T(316, "<newline>"),
		T{3640, "Concrete production<right><concrete(ConcreteProducedYesterday)>", resource_overview},
		T(316, "<newline>"),
		T{3641, "Concrete consumption<right><concrete(ConcreteConsumedByConsumptionYesterday)>", resource_overview},
		T{3642, "Concrete maintenance<right><concrete(ConcreteConsumedByMaintenanceYesterday)>", resource_overview},
		T{10082, "In construction sites<right><concrete(ConcreteInConstructionSitesActual, ConcreteInConstructionSitesTotal)>", resource_overview},
		T{10527, "Upgrade construction<right><concrete(ConcreteUpgradeConstructionActual, ConcreteUpgradeConstructionTotal)>", resource_overview},
	}
	
	if self:ShouldShowDiscoveredDeposits(UICity) then
		local discovered_deposits = UICity:GatherDiscoveredDeposits()
		local discovered_concrete = discovered_deposits.Concrete.amount or 0
	
		rollover[#rollover + 1] = T(316, "<newline>")
		rollover[#rollover + 1] = T{13816, "Discovered Concrete<right><concrete(number)>", number = discovered_concrete}
	end
	
	self:AppendResourceToRollover(rollover, "Concrete")
	return table.concat(rollover, "<newline><left>")
end

function InfobarObj:GetFoodRollover()
	local resource_overview = GetCityResourceOverview(UICity)
	local rollover = {
		resource_overview:GetBasicResourcesHeading(),
		T(316, "<newline>"),
		T{3643, "Food production<right><food(FoodProducedYesterday)>", resource_overview},
		T{3644, "Food consumption<right><food(FoodConsumedByConsumptionYesterday)>", resource_overview},
		T{9767, "Stored in service buildings<right><food(FoodStoredInServiceBuildings)>", resource_overview},
	}
	self:AppendResourceToRollover(rollover, "Food")
	return table.concat(rollover, "<newline><left>")
end

function InfobarObj:GetRareMetalsRollover()
	local resource_overview = GetCityResourceOverview(UICity)

	local rollover = {
		resource_overview:GetBasicResourcesHeading(),
		T(316, "<newline>"),
		T{3646, "Rare Metals production<right><preciousmetals(PreciousMetalsProducedYesterday)>", resource_overview},
		T(316, "<newline>"),
		T{3647, "Rare Metals consumption<right><preciousmetals(PreciousMetalsConsumedByConsumptionYesterday)>", resource_overview},
		T{3648, "Rare Metals maintenance<right><preciousmetals(PreciousMetalsConsumedByMaintenanceYesterday)>", resource_overview},		
		T{10528, "Upgrade construction<right><preciousmetals(PreciousMetalsUpgradeConstructionActual, PreciousMetalsUpgradeConstructionTotal)>", resource_overview},
		T(316, "<newline>"),
		T{3649, "<LastRareMetalsExportStr>", resource_overview},
	}
	
	if self:ShouldShowDiscoveredDeposits(UICity) then
		local discovered_deposits = UICity:GatherDiscoveredDeposits()
		local discovered_rare_metals = discovered_deposits.PreciousMetals.amount or 0
	
		rollover[#rollover + 1] = T(316, "<newline>")
		rollover[#rollover + 1] = T{13817, "Discovered Rare Metals<right><preciousmetals(number)>", number = discovered_rare_metals}
	end
	
	self:AppendResourceToRollover(rollover, "PreciousMetals")
	return table.concat(rollover, "<newline><left>")
end

function InfobarObj:GetPolymersText()
	local polymers = GetCityResourceOverview(UICity):GetAvailablePolymers() / const.ResourceScale
	return T{10100, "<polymers><icon_Polymers_orig>", polymers = self:FmtRes(polymers)}
end

function InfobarObj:GetElectronicsText()
	local electronics = GetCityResourceOverview(UICity):GetAvailableElectronics() / const.ResourceScale
	return T{10101, "<electronics><icon_Electronics_orig>", electronics = self:FmtRes(electronics)}
end

function InfobarObj:GetMachinePartsText()
	local machine_parts = GetCityResourceOverview(UICity):GetAvailableMachineParts() / const.ResourceScale
	return T{10102, "<machine_parts><icon_MachineParts_orig>", machine_parts = self:FmtRes(machine_parts)}
end

function InfobarObj:GetFuelText()
	local resource_overview = GetCityResourceOverview(UICity)
	local fuel = resource_overview:GetAvailableFuel() / const.ResourceScale
	return T{10103, "<fuel><icon_Fuel_orig>", fuel = self:FmtRes(fuel)}
end

function InfobarObj:GetPolymersRollover()
	local resource_overview = GetCityResourceOverview(UICity)

	local rollover = {
		resource_overview:GetAdvancedResourcesHeading(),
		T(316, "<newline>"),
		T{3655, "Polymers production<right><polymers(PolymersProducedYesterday)>", resource_overview},
		T{3656, "From surface deposits<right><polymers(PolymersGatheredYesterday)>", resource_overview},
		T(316, "<newline>"),
		T{3657, "Polymers consumption<right><polymers(PolymersConsumedByConsumptionYesterday)>", resource_overview},
		T{3658, "Polymers maintenance<right><polymers(PolymersConsumedByMaintenanceYesterday)>", resource_overview},
		T{10083, "In construction sites<right><polymers(PolymersInConstructionSitesActual, PolymersInConstructionSitesTotal)>", resource_overview},
		T{10529, "Upgrade construction<right><polymers(PolymersUpgradeConstructionActual, PolymersUpgradeConstructionTotal)>", resource_overview},
	}

	if self:ShouldShowDiscoveredDeposits(UICity) then
		local discovered_deposits = UICity:GatherDiscoveredDeposits()
		local discovered_polymers = discovered_deposits.Polymers.amount or 0

		rollover[#rollover + 1] = T(316, "<newline>")
		rollover[#rollover + 1] = T{13818, "Discovered Polymers<right><polymers(number)>", number = discovered_polymers}
	end

	self:AppendResourceToRollover(rollover, "Polymers")
	return table.concat(rollover, "<newline><left>")
end

function InfobarObj:GetElectronicsRollover()
	local resource_overview = GetCityResourceOverview(UICity)
	local rollover = {
		resource_overview:GetAdvancedResourcesHeading(),
		T(316, "<newline>"),
		T{3659, "Electronics production<right><electronics(ElectronicsProducedYesterday)>", resource_overview},
		T{3660, "Electronics consumption<right><electronics(ElectronicsConsumedByConsumptionYesterday)>", resource_overview},
		T{3661, "Electronics maintenance<right><electronics(ElectronicsConsumedByMaintenanceYesterday)>", resource_overview},
		T{10084, "In construction sites<right><electronics(ElectronicsInConstructionSitesActual, ElectronicsInConstructionSitesTotal)>", resource_overview},
		T{10530, "Upgrade construction<right><electronics(ElectronicsUpgradeConstructionActual, ElectronicsUpgradeConstructionTotal)>", resource_overview},
	}
	self:AppendResourceToRollover(rollover, "Electronics")
	return table.concat(rollover, "<newline><left>")
end

function InfobarObj:GetMachinePartsRollover()
	local resource_overview = GetCityResourceOverview(UICity)
	local rollover = {
		resource_overview:GetAdvancedResourcesHeading(),
		T(316, "<newline>"),
		T{3662, "Machine Parts production<right><machineparts(MachinePartsProducedYesterday)>", resource_overview},
		T{3663, "Machine Parts consumption<right><machineparts(MachinePartsConsumedByConsumptionYesterday)>", resource_overview},
		T{3664, "Machine Parts maintenance<right><machineparts(MachinePartsConsumedByMaintenanceYesterday)>", resource_overview},
		T{10085, "In construction sites<right><machineparts(MachinePartsInConstructionSitesActual, MachinePartsInConstructionSitesTotal)>", resource_overview},
		T{10531, "Upgrade construction<right><machineparts(MachinePartsUpgradeConstructionActual, MachinePartsUpgradeConstructionTotal)>", resource_overview},
	}
	self:AppendResourceToRollover(rollover, "MachineParts")
	return table.concat(rollover, "<newline><left>")
end

function InfobarObj:GetFuelRollover()
	local resource_overview = GetCityResourceOverview(UICity)
	local rollover = {
		resource_overview:GetAdvancedResourcesHeading(),
		T(316, "<newline>"),
		T{3665, "Fuel production<right><fuel(FuelProducedYesterday)>", resource_overview},
		T{3666, "Fuel consumption<right><fuel(FuelConsumedByConsumptionYesterday)>", resource_overview},
		T{3667, "Fuel maintenance<right><fuel(FuelConsumedByMaintenanceYesterday)>", resource_overview},
		T{3668, "Refueling of Rockets<right><fuel(RocketRefuelFuelYesterday)>", resource_overview},
	}
	self:AppendResourceToRollover(rollover, "Fuel")
	return table.concat(rollover, "<newline><left>")
end

function InfobarObj:CycleLabel(label)
	CycleObjects(UICity.labels[label])
end

function InfobarObj:GetSeedsText()
	local seeds = GetCityResourceOverview(UICity):GetAvailableSeeds() / const.ResourceScale
	return T{12096, "<seeds><icon_Seeds_orig>", seeds = self:FmtRes(seeds)}
end

function InfobarObj:GetSeedsRollover()
	return GetCityResourceOverview(UICity):GetSeedsRollover()
end

function InfobarObj:GetPrefabText()
	local prefabs_count = UICity:GetTotalPrefabs()
	return T{13675, "<prefabs><icon_Prefab_orig>", prefabs = self:FmtRes(prefabs_count)}
end

function InfobarObj:GetPrefabRollover()
	return GetCityResourceOverview(UICity):GetPrefabRollover()
end

function InfobarObj:GetWasteRockText()
	local waste_rock = GetCityResourceOverview(UICity):GetAvailableWasteRock() / const.ResourceScale
	return T{12299, "<waste_rock><icon_WasteRock_orig>", waste_rock = self:FmtRes(waste_rock)}
end

function InfobarObj:GetWasteRockRollover()
	local resource_overview = GetCityResourceOverview(UICity)
	local rollover = {
		resource_overview:GetOtherResourcesHeading(),
		T(316, "<newline>"),
		T{12294, "Waste Rock production<right><wasterock(WasteRockProducedYesterday)>", resource_overview},
		T{12295, "Waste Rock consumption<right><wasterock(WasteRockConsumedByConsumptionYesterday)>", resource_overview},
	}
	self:AppendResourceToRollover(rollover, "WasteRock")
	return table.concat(rollover, "<newline><left>")
end

function InfobarObj:CycleFreeHomes()
	local list = { }
	for _, home in ipairs(UICity.labels.Residence or empty_table) do
		if not home.destroyed and not home.children_only and home:GetFreeSpace() > 0 then
			table.insert(list, home)
		end
	end
	
	CycleObjects(list)
end

function InfobarObj:CycleFreeWorkplaces()
	local list = { }
	for _,workplace in ipairs(UICity.labels.Workplace or empty_table) do
		if not workplace.destroyed and not workplace.demolishing then
			if workplace.ui_working and workplace:GetFreeWorkSlots() > 0 then
				table.insert(list, workplace)
			end
		end
	end
	
	CycleObjects(list)
end

function InfobarObj:GetTotalDrones()
	local total_drones = #(UICity.labels.Drone or empty_table)
	return T{11183, "<total_drones><icon_Drone_orig>", total_drones = self:FmtRes(total_drones)}
end

function InfobarObj:GetTotalColonists()
	local total_coloinsts = GetCityResourceOverview(UICity):GetColonistCount()
	return T{11184, "<total_coloinsts><icon_Colonist_orig>", total_coloinsts = self:FmtRes(total_coloinsts)}
end

function InfobarObj:GetTotalTourists()
	local total_tourists = GetCityResourceOverview(UICity):GetTouristCount()
	return T{12778, "<total_tourists><icon_Tourist_orig>", total_tourists = self:FmtRes(total_tourists)}
end

function InfobarObj:GetFreeHomes()
	local resource_overview = GetCityResourceOverview(UICity)
	local free_homes = resource_overview:GetFreeLivingSpace()
	local homeless = resource_overview:GetHomelessColonists()
	return T{10422, "<free_homes><icon_Home_orig>", free_homes = self:FmtRes(free_homes)}..Untranslated(" ")..T{10423, "<homeless><icon_Homeless_orig>", homeless = self:FmtRes(homeless)}
end

function InfobarObj:GetHomeless()
	local homeless = GetCityResourceOverview(UICity):GetHomelessColonists()
	return T{10423, "<homeless><icon_Homeless_orig>", homeless = self:FmtRes(homeless)}
end

function InfobarObj:GetFreeWork()
	local free_work = GetCityResourceOverview(UICity):GetFreeWorkplaces()
	local unemployed = GetCityResourceOverview(UICity):GetUnemployedColonists()
	return T{10424, "<free_work><icon_Work_orig>", free_work = self:FmtRes(free_work)}..Untranslated(" ").. T{10425, "<unemployed><icon_Unemployed_orig>", unemployed = self:FmtRes(unemployed)}
end

function InfobarObj:GetUnemployed()
	local unemployed = GetCityResourceOverview(UICity):GetUnemployedColonists()
	return T{10425, "<unemployed><icon_Unemployed_orig>", unemployed = self:FmtRes(unemployed)}
end

function InfobarObj:GetColonistCount()
	return GetCityResourceOverview(UICity):GetColonistCount()
end

function InfobarObj:GetColonistsRollover()
	local resource_overview = GetCityResourceOverview(UICity)
	local data = resource_overview.data
	if not rawget(data, "children") then
		resource_overview:GatherPerDomeInfo()
		resource_overview:ProcessDomelessColonists()
	end
	local city_labels = resource_overview.city.labels	
	local rollover = {
		T{553, "<newline><center><em>Age Groups</em>", newline = ""},
		T{554, "Children<right><colonist(number)>",    number = data.children },
		T{555, "Youth<right><colonist(number)>",       number = data.youths },
		T{556, "Adults<right><colonist(number)>",      number = data.adults },
		T{557, "Middle Aged<right><colonist(number)>", number = data.middleageds },
		T{558, "Senior<right><colonist(number)>",      number = data.seniors },		
		T(9768, "<newline><center><em>Origin</em>"),
		T{8035, "Martianborn<right><colonist(number)>", number = data.martianborn},
		T{8036, "Earthborn<right><colonist(number)>",   number = data.earthborn},
	}
	self:AppendResourceToRollover(rollover, "Colonist", "colonists")
	return table.concat(rollover, "<newline><left>")
end

function InfobarObj:GetTouristCount()
	return GetCityResourceOverview(UICity):GetTouristCount()
end

function InfobarObj:GetTouristsRollover()
	local resource_overview = GetCityResourceOverview(UICity)
	local tourists = resource_overview:GetAllTourists()
	local active_tourists = {}
	local departing_tourists = {}
	local overstaying_tourists = {}
	for _, tourist in ipairs(tourists) do
		if tourist.sols <= g_Consts.TouristSolsOnMarsMin then
			table.insert(active_tourists, tourist)
		elseif tourist.sols <= g_Consts.TouristSolsOnMarsMax then
			table.insert(departing_tourists, tourist)
		else
			table.insert(overstaying_tourists, tourist)
		end
	end
	
	local rollover = {
		T{12744, "Enjoying their holiday (sol 1-5)<right><tourist(number)>",    number = #active_tourists },
		T{12745, "Looking to go home (sol 6-10)<right><tourist(number)>",       number = #departing_tourists },
		T{12746, "Desperate to leave (sol 10+)<right><tourist(number)>",        number = #overstaying_tourists },
	}
	self:AppendResourceToRollover(rollover, "Tourist", "tourists")
	return table.concat(rollover, "<newline><left>")
end

function InfobarObj:GetDronesCount()
	return GetCityResourceOverview(UICity):GetDronesCount()
end

function InfobarObj:GetDronesRollover()
	local resource_overview = GetCityResourceOverview(UICity)

	local destroyed_drones = 0
	for _, obj in pairs(g_DestroyedVehicles[UICity.map_id] or empty_table) do
		if IsKindOf(obj, "Drone") then
			destroyed_drones = destroyed_drones + 1
		end
	end
	
	local rollover = 
	{
		T{11697, "Drone controllers<right><number>", number = #(UICity.labels.DroneControl or empty_table)},
		T{11830, "Drone prefabs<right><prefab(number)>", number = UICity.drone_prefabs},
		T{13819, "Damaged drones<right><drone(number)>", number =  #(g_BrokenDrones[UICity.map_id] or empty_table)},
		T{11831, "Destroyed drones<right><drone(number)>", number =  destroyed_drones},
	}
	self:AppendResourceToRollover(rollover, "Drone", "drones")
	return table.concat(rollover, "<newline><left>")
end

function InfobarObj:GetFreeHomesRollover()
	return GetCityResourceOverview(UICity):GetHomesRollover()
end	

function InfobarObj:GetJobsRollover()
	return GetCityResourceOverview(UICity):GetJobsRollover()
end