local supply_element_name_to_grid_name = {
	electricity = "ElectricityGrid",
	water = "WaterGrid",
}

DefineClass.SupplyGridSwitch = {
	__parents = { "SyncObject", "PinnableObject", "InfopanelObj" ,"Renamable"},
	
	switched_state = false, -- current switch state
	switch_state = false, -- state to be switched (used when rebuilding)
	is_switch = false,
	construction_connections = -1,
	conn = -1,
	supply_element = "electricity",
	
	display_name = false,
	description = false,
	
	on_state = false,
	off_state = false,
	switch_anim = false,
	open_close_thread = false,
	encyclopedia_id = false,
	
	pin_rollover = T(7383, "<description>"),
	skin_before_switch = false,
	
	switch_cs = false,
	rename_allowed = true,
	name = "",
}

function SupplyGridSwitch:GameInit()
	if self.is_switch then
		if not IsKindOf(self, "ConstructionSite") then --i.e. built.
			self.is_switch = false
			self:MakeSwitch() --init properly
			
			if self.switch_state == "on" and not self.switched_state or self.switch_state == "off" and self.switched_state then
				self:Switch()
			end
		end		
	end
end

function SupplyGridSwitch:Done()
	if IsValid(self.switch_cs) then
		DoneObject(self.switch_cs)
	end
end

function SupplyGridSwitch:CanMakeSwitch()
	return not self.is_switch and self.auto_connect == false and not self.chain
end

function SupplyGridSwitch:MakeNotSwitch(constr_site)
	if self.switched_state then
		self:Switch()
	end
	
	self.is_switch = false
	self.conn = 0
	self.rename_allowed = false
	self.name=""
	self:UpdateVisuals()
	
	if SelectedObj == self then
		SelectObj(false)
	end	
	if self:IsPinned() then
		self:TogglePin()
	end

	self.display_name = nil
	self.description = nil
	self.encyclopedia_id = nil
end


function SupplyGridSwitch:MakeSwitch(constr_site)
	if self.is_switch then return end
	if not self:CanMakeSwitch(constr_site) then return end
	local is_cable = IsKindOf(self, "ElectricityGridElement")
	self.is_switch = true
	self.conn = 0
	self.rename_allowed = true
	self.fx_actor_class = is_cable and "CableSwitch" or "PipeValve"
	self:UpdateVisuals()
	if self.on_state and self:HasState(self.on_state) then
		self:SetState(self.on_state)
	end
	self:SetEnumFlags(const.efSelectable)
	if self.switch_cs then
		self.switch_cs = false
	end
	
	local bld_template = BuildingTemplates[is_cable and "ElectricitySwitch" or "LifesupportSwitch"]
	self.display_name = bld_template.display_name
	self.description = bld_template.description
	self.encyclopedia_id = bld_template.encyclopedia_id
end

function SupplyGridSwitch:GetDisplayName()
	return self.is_switch and self.name~="" and Untranslated(self.name) or self.display_name
end

local BroadcastSwitchesFilter = function(obj, current_state) 
	return obj.is_switch and obj.switched_state == current_state
end

function SupplyGridSwitch:Switch(broadcast)
	if not self.is_switch then return end
	local switches = {}
	local current_state = self.switched_state
	if broadcast then
		switches = GetRealm(self):MapGet( "map", self.class, BroadcastSwitchesFilter, current_state )
	else
		switches[1] = self
	end

	local supply_connection_grid = GetSupplyConnectionGrid(self)
	for i = 1, #switches do		
		local grid_class_def = g_Classes[supply_element_name_to_grid_name[switches[i].supply_element]]
		local skin_name = switches[i]:GetGridSkinName()
		switches[i].skin_before_switch = skin_name
		switches[i].construction_connections = HexGridGet(supply_connection_grid[switches[i].supply_element], switches[i]) --force same conns on reconnect
		switches[i]:SupplyGridDisconnectElement(switches[i][switches[i].supply_element], grid_class_def, true)
		switches[i].switched_state = not switches[i].switched_state
		switches[i]:SupplyGridConnectElement(switches[i][switches[i].supply_element], grid_class_def, skin_name)
		switches[i].skin_before_switch = nil
		
		if switches[i].supply_element == "electricity" then
			PlayFX("CableSwitched", switches[i].switched_state and "off" or "on", switches[i])
		elseif switches[i].supply_element == "water" then
			PlayFX("PipeSwitched", switches[i].switched_state and "off" or "on", switches[i])
		end
		
		switches[i]:UpdateAnim()
	end
end

function SupplyGridSwitch:UpdateAnim()
	if not self.switch_anim or not self:HasState(self.switch_anim) then
		--there is no anim, don't make threads
		local new_state = self.switched_state and self.off_state or self.on_state
		if new_state and self:HasState(new_state) then
			self:SetState(new_state)
		end
	else
		DeleteThread(self.open_close_thread)
		self.open_close_thread = CreateGameTimeThread(function()
			local anim = self:GetStateText()
			if anim == self.switch_anim then
				Sleep(self:TimeToAnimEnd())
				if not IsValid(self) then return end
			end
			local state = self.switched_state --false we are going to on state, true we are going to off state
			local final_anim = state and self.off_state or self.on_state
			local transition_anim_flags = state and 0 or const.eReverse
			local skip_anim = anim == self.switch_anim and 
								band(self:GetAnimFlags(1), const.eReverse) == transition_anim_flags or false
			
			if not skip_anim then
				self:SetAnim(1, self.switch_anim, transition_anim_flags)
				Sleep(self:TimeToAnimEnd())
				if not IsValid(self) then return end
			end
			
			if final_anim and self:HasState(final_anim) then
				self:SetState(final_anim)
			end
		end)
	end
end

DefineClass.SupplyGridSwitchBuilding = { --placeholder for build menu
	__parents = {"Building"},
	rename_allowed = true,
}
