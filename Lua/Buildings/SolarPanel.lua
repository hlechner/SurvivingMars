DefineClass.SolarPanelBase = {
	__parents = { "Object" },
	artificial_sun = false,
	panel_obj = false,
	counter_atmosphere_modifier = false,
}

function SolarPanelBase:GameInit()
	local sun = self.city.labels.ArtificialSun and self.city.labels.ArtificialSun[1] or nil
	if sun and TestSunPanelRange(sun, self) then
		self.artificial_sun = sun
	end
	self:UpdateProduction()
end

function SolarPanelBase:UpdateCounterAtmosphereModifier()
	local atm_modifier = self:FindModifier("TP Boost Atmosphere", "electricity_production")
	local ca_modifier = self.counter_atmosphere_modifier
	if not atm_modifier or not self:IsAffectedByArtificialSun() then
		if ca_modifier and (ca_modifier.amount ~= 0 or ca_modifier.percent ~= 0) then
			ca_modifier:Change(0, 0)
		end
		return false
	end
	if not ca_modifier then
		self.counter_atmosphere_modifier = ObjectModifier:new{
			target = self,
			prop = "electricity_production", 
			amount = -atm_modifier.amount,
			percent = -atm_modifier.percent,
		}
	else
		ca_modifier:Change(-atm_modifier.amount, -atm_modifier.percent)
	end
end

function SolarPanelBase:GetTPBoostAtmosphere()
	local percent = 0
	local atm_modifier = self:FindModifier("TP Boost Atmosphere", "electricity_production")
	if atm_modifier then
		percent = percent + atm_modifier.percent
	end
	if self.counter_atmosphere_modifier then
		percent = percent + self.counter_atmosphere_modifier.percent
	end
	return percent
end

function SolarPanelBase:UpdateProduction()
	local new_base_production = self:CanBeOpened() and self:GetClassValue("electricity_production") or 0
	self:UpdateCounterAtmosphereModifier()
	if self.base_electricity_production ~= new_base_production then
		self:SetBase("electricity_production", new_base_production)
		RebuildInfopanel(self)
	end
end

function SolarPanelBase:IsAffectedByArtificialSun()
	return self.artificial_sun and self.artificial_sun.work_state == "produce"
end

function SolarPanelBase:CanBeOpened()
	return SunAboveHorizon or self:IsAffectedByArtificialSun()
end

function SolarPanelBase:SetArtificialSun(sun)
	self.artificial_sun = sun
	self:UpdateProduction()
end

function SolarPanelBase:IsOpened()
	return true
end

----

DefineClass.SolarPanelBuilding = {
	__parents = { "SolarPanelBase", "ElectricityProducer" },
	
	upgrade1_icon = "UI/Icons/Upgrades/Improved_Photovoltaics_01.tga",
}

function SolarPanelBuilding:Init()
	self.city:AddToLabel("SolarPanelBuilding", self)
end

function SolarPanelBuilding:Done()
	self.city:RemoveFromLabel("SolarPanelBuilding", self)
end

function SolarPanelBuilding:GameInit()
	self:OnChangeState()
end

function SolarPanelBuilding:OnSetWorking(working)
	self:UpdateProduction()
	ElectricityProducer.OnSetWorking(self, working)
end

function SolarPanelBuilding:BuildingUpdate(dt, day, hour)
	self:UpdateProduction(hour)
end

function SolarPanelBuilding:SetDustVisualsPerc(perc)
	if not self.show_dust_visuals then return end
	BuildingVisualDustComponent.SetDustVisualsPerc(self, perc)
	if IsValid(self.panel_obj) then
		BuildingVisualDustComponent.SetDustVisualsPerc(self.panel_obj, perc)
	end
end

function SolarPanelBuilding:SetDustVisuals(dust)
	if not self.show_dust_visuals then return end
	if self:GetGameFlags(const.gofUnderConstruction) ~= 0 then return end
	BuildingVisualDustComponent.SetDustVisuals(self, dust)
	if IsValid(self.panel_obj) then
		BuildingVisualDustComponent.SetDustVisuals(self.panel_obj, dust)
	end
end

function SolarPanelBuilding:OnChangeState()
	self.accumulate_dust = self:IsOpened() and not IsObjInDome(self)
	if g_DustRepulsion then
		local percent = self:IsOpened() and 0 or -(100 + g_DustRepulsion)
		self:SetModifier("maintenance_build_up_per_hr", "DustRepulsion", 0, percent)
	end
	self.accumulate_maintenance_points = self:IsOpened() or not not g_DustRepulsion
end

----

DefineClass.SolarPanel = {
	__parents = { "SolarPanelBuilding" },
	building_update_time = const.HourDuration,
	open_close_thread = false,
	interaction_state = false,
}

function SolarPanel:GameInit()
	self.panel_obj = self:GetAttach(self:GetEntity() .. "Top")
	self.panel_obj:Detach()
	self.panel_obj:SetAngle(self:GetAngle())
	self.panel_obj.base = self
end

function SolarPanel:UpdateProduction()
	self:SetInteractionState(self:CanBeOpened() and self.working)
	SolarPanelBase.UpdateProduction(self)
end

function SolarPanel:Done()
	if IsValidThread(self.open_close_thread) then
		DeleteThread(self.open_close_thread)
	end
	
	if IsValid(self.panel_obj) then
		DoneObject(self.panel_obj)
	end
end

function SolarPanel:Destroy()
	Building.Destroy(self)
	self.panel_obj:SetColorModifier(self.demolish_color)
	if self.panel_obj:GetStateText() ~= "idle" then
		CreateGameTimeThread(function()
			if not IsValid(self) or not IsValid(self.panel_obj) then return end
			Sleep(self.panel_obj:TimeToAnimEnd())
			self.panel_obj:SetAnim(1, "idle")
		end)
	end
end

function SolarPanel:RebuildStart()
	self:ClearEnumFlags(const.efVisible)
	self.panel_obj:ClearEnumFlags(const.efVisible)
end

function SolarPanel:RebuildCancel()
	self:SetEnumFlags(const.efVisible)
	self.panel_obj:SetEnumFlags(const.efVisible)
end

function SolarPanel:IsOpened()
	return self.interaction_state
end

function SolarPanel:SetInteractionState(state)
	if state == self.interaction_state then return end
	self.interaction_state = state
	self:OnChangeState()
	DeleteThread(self.open_close_thread)
	self.open_close_thread = CreateGameTimeThread(function()
		local anim_state = state and "opening" or "closing"
		local panel_obj = self.panel_obj
		if panel_obj:GetStateText() ~= "idle" then
			Sleep(panel_obj:TimeToAnimEnd())
		end
		if panel_obj:GetStateText() == anim_state then
			return
		end
		panel_obj:SetAnim(1, anim_state)
		if not state then
			panel_obj:SetAngle(self:GetAngle(), 5*const.MinuteDuration)
		end
	end)
end

function SolarPanel:OrientToSun(sun_azi, time)
	return self.panel_obj:SetAngle(sun_azi, time or const.MinuteDuration)
end

function SolarPanel:SetPalette(...)
	SolarPanelBuilding.SetPalette(self, ...)
	SetObjectPaletteRecursive(self.panel_obj, ...)
end

function OnMsg.SunChange()
	UIColony:ForEachLabelObject("SolarPanelBase", "UpdateProduction")
end

function SunToSolarPanelAngle(sun_azi)
	return sun_azi - 30*60 < 0 and 390*60 - sun_azi or sun_azi - 30*60
end

function SolarPanelsOrientToSun(anim_time)
	local idle_state = EntityStates["idleOpened"]
	local opening_state = EntityStates["opening"]
	local azi = SunToSolarPanelAngle(GetSunPos())
	for _, panel in ipairs(UIColony.city_labels.labels.SolarPanel or empty_table) do
		local panel_obj = panel.panel_obj
		if panel:IsOpened() then
			local panel_state = panel_obj:GetState()
			if panel_state == idle_state then
				if panel:IsAffectedByArtificialSun() then
					local angle = CalcOrientation(panel:GetPos(), panel.artificial_sun:GetPos())
					panel:OrientToSun(angle+140*60, anim_time)
				else
					panel:OrientToSun(azi, anim_time)
				end
				panel:UpdateCounterAtmosphereModifier()
			elseif panel_state == opening_state and panel_obj:TimeToAnimEnd() < 2 then
				panel_obj:SetAnim(1, "idleOpened")
			end
		end
	end
end

GlobalGameTimeThread("SolarPanelOrientation", function()
	local update_interval = 3*const.MinuteDuration
	while true do
		Sleep(update_interval)
		SolarPanelsOrientToSun(update_interval)
	end
end)

GlobalVar("g_DustRepulsion", false)

function OnMsg.TechResearched(tech_id, research)
	if tech_id == "DustRepulsion" then
		g_DustRepulsion = TechDef.DustRepulsion.param1
	end
end

function SolarPanel:BroadcastVerify(other)
	-- make sure broadcasts affect buildings of the same template only
	return other.template_name == self.template_name
end

DefineClass.SolarPanelTop = {
	__parents = { "BuildingVisualDustComponent" },
	base = false,
}

function SolarPanelTop:SelectionPropagate()
	return self.base
end

DefineClass("SolarPanelBigTop", "SolarPanelTop")

function OnMsg.TerraformParamChanged(name, value, old_value)
	if name ~= "Atmosphere" then return end
	for _, panel in ipairs(MainCity.labels.SolarPanel or {}) do
		panel:UpdateCounterAtmosphereModifier()
	end
end