DefineClass.ColdSensitive = {
	__parents = { "BaseBuilding"},

	properties = {
		{ template = true, name = T(664, "Penalty Heat"),         id = "penalty_heat",            category = "Cold", editor = "number", default = const.DefaultPanaltyHeat, min = 0, max = const.MaxHeat, slider = true, help = "Heat at which the cold penalty is applied" },
		{ template = true, name = T(665, "Penalty Percent"),      id = "penalty_pct",             category = "Cold", editor = "number", default = const.DefaultPanaltyPct,  min = 0, max = 300, slider = true, help = "Cold penalty percents" },
		{ template = true, name = T(666, "Freeze Time"),          id = "freeze_time",             category = "Cold", editor = "number", default = const.DefaultFreezeTime,  scale = const.HourDuration, help = "Freeze time if under the freeze heat" },
		{ template = true, name = T(8526, "Defrost Time"),        id = "defrost_time",            category = "Cold", editor = "number", default = const.DefaultDefrostTime, scale = const.HourDuration, help = "Defrost time if above the freeze heat" },
		{ template = true, name = T(667, "Freeze Heat"),          id = "freeze_heat",             category = "Cold", editor = "number", default = const.DefaultFreezeHeat,  min = 0, max = const.MaxHeat, slider = true, help = "Below that heat the building begins to freeze" },
	},
	
	is_electricity_consumer = false, --el consumer child flips this
	cold_mod = false,
	
	freeze_progress = 0,
}

function ColdSensitive:SetFrozen(frozen)
	frozen = frozen or false
	if self.frozen == frozen then
		return
	end
	if frozen then
		self.frozen = true
		self.city:AddToLabel("Frozen", self)
		self:UpdateWorking(false)
	else
		self.frozen = false
		self.city:RemoveFromLabel("Frozen", self)
		self:UpdateWorking()
	end
	self:AttachSign(frozen, "SignNotWorking")
	self:OnFrozenStateChanged()
	RebuildInfopanel(self)
end

function ColdSensitive:OnFrozenStateChanged()
end

function ColdSensitive:GetColdPenalty()
	local penalty = IsGameRuleActive("WinterIsComing") and HasColdWave(self:GetMapID()) and 2*self.penalty_pct or self.penalty_pct
	return IsValid(self) and not IsObjInDome(self) and GetHeatAt(self) < self.penalty_heat and penalty or 0
end

function ColdSensitive:IsFreezing()
	return IsValid(self) and not IsObjInDome(self) and GetHeatAt(self) < self.freeze_heat
end

function ColdSensitive:BuildingUpdate(delta)
	local old_progress = self.freeze_progress
	local new_progress
	if self:IsFreezing() then
		new_progress = Min(old_progress + delta, self.freeze_time)
	elseif self.defrost_time > 0 then
		new_progress = Max(old_progress - MulDivRound(delta, self.freeze_time, self.defrost_time), 0)
	else
		new_progress = 0
	end
	if old_progress ~= new_progress then
		self.freeze_progress = new_progress
		if not self.frozen and new_progress == self.freeze_time then
			self:SetFrozen(true)
		elseif self.frozen and new_progress == 0 then
			self:SetFrozen(false)
			self:SetMalfunction()
		end
	end
end

function ColdSensitive:GetFreezeProgress()
	return MulDivRound(100, self.freeze_progress, self.freeze_time)
end

function ColdSensitive:GetFreezeStatus()
	if self.frozen then
		return self:IsFreezing() and T(8527, "Frozen") or T(8528, "Desfrosting")
	else
		return self:IsFreezing() and T(3875, "Freezing") or ""
	end
end

function ColdSensitive:CheatUnfreeze()
	self:SetFrozen(false)
end
