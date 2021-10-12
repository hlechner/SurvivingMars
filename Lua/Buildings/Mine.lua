DefineClass.Mine = {
	__parents = { "ResourceProducer", "Building", "BuildingDepositExploiterComponent", "ElectricityConsumer" },

	last_serviced_time = 0, --(TODO: is still needed?) moment the mine was last serviced by a working drone, or turned on	
	building_update_time = const.HourDuration,
	exploitation_resource = false,
}

function Mine:IsIdle()
	return self.ui_working and not self:CanExploit() and not self.city.colony:IsTechResearched("NanoRefinement")
end

function Mine:SetUIWorking(working)
	Building.SetUIWorking(self, working)
	BuildingDepositExploiterComponent.UpdateIdleExtractorNotification(self)
end

function Mine:DroneLoadResource(drone, request, resource, amount) --propagated from stockpile.
	if not self.working then --if we have stopped due to being full
		self:UpdateWorking()
	end
end

function Mine:OnChangeActiveDeposit()
	BuildingDepositExploiterComponent.OnChangeActiveDeposit(self)
	self:UpdateWorking()
end

function Mine:OnDepositDepleted(deposit)
	BuildingDepositExploiterComponent.OnDepositDepleted(self, deposit)
	if not self:CanExploit() and not self.city.colony:IsTechResearched("NanoRefinement") then
		self:UpdateWorking(false)
	end
end

function Mine:GetHourPredictedProduction() -- per one hour
	if self.working then
		local deposit_multiplier = self:GetCurrentDepositQualityMultiplier()
		local amount_produced = MulDivRound(self.production_per_day1, deposit_multiplier, const.HoursPerDay*100)
		if self:HasMember("performance") then
			amount_produced = MulDivRound(amount_produced, self.performance, 100)
		end
		return amount_produced
	end
	
	return 0
end

function Mine:OnDepositsLoaded()
	self:UpdateConsumption()
	self:UpdateWorking()
end

function Mine:GatherConstructionStatuses(statuses)
	BuildingDepositExploiterComponent.GatherConstructionStatuses(self, statuses)
	if #self.nearby_deposits > 0 then
		local status = table.copy(ConstructionStatus.DepositInfo)
		local amount, grade
		for i = 1, #self.nearby_deposits do
			if self.nearby_deposits[i].resource == self.exploitation_resource then
				amount = (amount or 0) + self.nearby_deposits[i].amount
				grade = Max(grade or 1, table.find(DepositGradesTable, self.nearby_deposits[i].grade) or 1)
			end
		end
		if amount and grade then
			grade = DepositGradesTable[grade] -- index to name
			grade = DepositGradeToDisplayName[grade] -- name to display name
			status.text = T{status.text, {resource = FormatResource(empty_table, amount, self.exploitation_resource), grade = grade, col = ConstructionStatusColors.info.color_tag}}
			statuses[#statuses + 1] = status
		end
	end
end

function Mine:GetResourceProducedIcon(idx)
	return "UI/Icons/Sections/" .. Resources[self.exploitation_resource].name .. "_2.tga"
end

function Mine:GetUISectionMineRollover()
	local lines = {
		T{466, "Production per Sol (predicted)<right><resource(PredictedDailyProduction, GetResourceProduced)>", self},
		T{468, "Lifetime production<right><resource(LifetimeProduction,exploitation_resource)>", self},
	}
	AvailableDeposits(self, lines)
	lines[#lines + 1] = T(469, "<newline><center><em>Storage</em>")
	lines[#lines + 1] = T{470, "<resource(exploitation_resource)><right><resource(GetAmountStored,max_storage,exploitation_resource)>", self}
	lines[#lines + 1] = T{471, "Waste Rock<right><wasterock(GetWasterockAmountStored,wasterock_max_storage)>", self}

	return table.concat(lines, "<newline><left>")
end

function Mine:CheatFill()
	ResourceProducer.CheatFill(self)
end

function Mine:CheatEmpty()
	ResourceProducer.CheatEmpty(self)
end

function OnMsg.GatherFXActors(list)
	list[#list + 1] = "Mine"
end
