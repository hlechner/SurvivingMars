DefineClass.DroneBase =
{
	__parents = { "Vehicle", "CityObject", "NightLightObject", "InfopanelObj", "InteractionController", "Shroudable" },
	flags = { gofPermanent = true, cofComponentSound = true },

	moving = false,
	fx_moving_target = false,

	work_spot_task = "Workdrone",
	work_spot_deposit = "Workdrone",
	work_spot_drone_recharge = "Rechargedrone",
	work_spot_drone_repair = "Repairdrone",

	properties = {
		{ category = "DroneBase", id = "name", name = T(1000037, "Name"), editor = "text", default = "" },
		{ category = "Movement", id = "move_speed", name = T(4454, "Move Speed"), editor = "number", default = 1000, modifiable = true },
	},

	dust = 0,
	dust_max = const.MaxMaintenance,
	accumulate_dust = true,
	dust_devils = false,

	start_player_controllable = false,
	override_ui_status = false,

	interaction_mode = false, --custom str, represents special interraction btn toggle.
	control_override = false,
	
	embark_target = false,
	embark_rocket_spot = false,	
	
	rotaty_spot = "Origin",
	rotaty_offset = point(0, 0, 12*guim),
}

function DroneBase:GameInit()
	self:SetIsNightLightPossible(true)
end

function DroneBase:Done()
	self.moving = false
	self:UpdateMoving()
end

function DroneBase:AttachedToRealm(map_id)
	local next_environment = ActiveMaps[map_id].Environment
	self:TransformToEnvironment(next_environment)

	self:SetIsNightLightPossible(not self:IsMalfunctioned())
	if self:IsNightLightPossible() then
		self:NightLightEnable(false)
	else
		self:NightLightDisable(false)
	end
end

function DroneBase:DetachFromRealm(map_id)
	self:SetIsNightLightPossible(false)
	self:DestroyAttaches("ParSystem")
end

function DroneBase:TransformToEnvironment(environment)
	local environment_fx_actor = self.environment_fx[environment] or self.environment_fx.base
	self.fx_actor_base_class = environment_fx_actor
	
	local environment_entity = self.environment_entity[environment] or self.environment_entity.base
	self:ChangeEntity(environment_entity)
end

function DroneBase:SetCommandUserInteraction(...)
	self:SetCommand(...)
end

function DroneBase:SetDisablingCommand(...)
	self:SetCommand(...)
end

function DroneBase:StartMoving()
	self.moving = true
	if not self.fx_moving_target then
		self:UpdateMoving()
	end
end

function DroneBase:StopMoving()
	self.moving = false
	if self.fx_moving_target then
		self:UpdateMoving()
	end
end

function DroneBase:UpdateMoving()
	local moving = self.moving
	if moving ~= not self.fx_moving_target then
		return
	end
	if moving then
		local fx_moving_target = IsUnitInDome(self) and "Dome" or "Outside"
		self.fx_moving_target = fx_moving_target
		PlayFX("Moving", "start", self, fx_moving_target)
	else
		local fx_moving_target = self.fx_moving_target
		self.fx_moving_target = false
		PlayFX("Moving", "end", self, fx_moving_target)
	end
end

function DroneBase:SetOutsideVisuals(outside)
	local fx_moving_target = self.fx_moving_target
	if fx_moving_target then
		self.fx_moving_target = false
		PlayFX("Moving", "end", self, fx_moving_target)
	end
end

function DroneBase:GetColdPenalty()
	local max_heat = const.MaxHeat
	local heat = GetHeatAt(self)
	return MulDivRound(100, max_heat - heat, max_heat)
end

function DroneBase:IsDead()
	return not IsValid(self) or self.command == "Dead"
end

function DroneBase:CanBeControlled()
	return not self.control_override and self.command ~= "Malfunction" and self.command ~= "Dead" and not self.disappeared and not self:IsShroudedInRubble()
end

function DroneBase:ToggleControlMode()
	local unit_ctrl_dlg = GetInGameInterfaceModeDlg()
	assert(unit_ctrl_dlg:IsKindOf("UnitDirectionModeDialog"))
	
	if not self:CanBeControlled()then
		return 
	end
	
	if terminal.IsKeyPressed(const.vkControl) then --ignore the button while ctrl is down
		--handles case where button is pressed but already in move/interact mode.
		return
	end

	if unit_ctrl_dlg.unit == self and not IsValid(unit_ctrl_dlg.interaction_obj) then
		local new_val = unit_ctrl_dlg.interaction_mode ~= "move" and "move" or false
		SetUnitControlInteractionMode(self, new_val)
		if unit_ctrl_dlg.interaction_mode == "move" then
			unit_ctrl_dlg:SetFocus(true)
		end
	end
	
	HintDisable("HintVehicleOrders")
	
	RebuildInfopanel(self)
end

function DroneBase:ToggleControlMode_Update(button)
	button:SetIcon(self.interaction_mode ~= "move" and "UI/Icons/IPButtons/move.tga" or "UI/Icons/IPButtons/cancel.tga")
	button:SetEnabled(self:CanBeControlled())
	local to_mode = self.interaction_mode ~= "move"
	button:SetRolloverText(
		self:IsKindOf("RCTransport") and T(4463, "Give command to move or harvest resources.")
		or self:IsKindOf("RCRover") and T(4483, "Give command to move or repair Drones.")
		or T(4424, "Give command to move or interact with an object."))
	local shortcuts = GetShortcuts("actionMoveInteract")
	local hint = ""
	if shortcuts and (shortcuts[1] or shortcuts[2]) then
		hint = T(10927, " / <em><ShortcutName('actionMoveInteract', 'keyboard')></em>")
	end
	button:SetRolloverHint(to_mode and T{7401, "<left_click><hint> Select target mode<newline><UnitMoveControl()> on target to move or interact", hint = hint, self}
		or T(7510, "<left_click> on target to select it  <right_click> Cancel"))
	button:SetRolloverHintGamepad(to_mode and T(7511, "<ButtonA> Select target mode") or T(7512, "<ButtonA> Cancel"))
end

function DroneBase:SetControlMode(v)
	ResetUnitControlInteractionMode( v and "move" or false, self)
end

function DroneBase:Random(...)
	return CityObject.Random(self, ...)
end

function DroneBase:GetDustMax()
	return self.dust_max * (100 + g_Consts.DroneMaxDustBonus) / 100
end

function DroneBase:AddDust(dust)
	if not self.accumulate_dust or self:IsDead() or self:GetParent() then return end
	local dust_max = self:GetDustMax()
	self.dust = Max(Min(dust_max, self.dust + dust), 0)
	self:SetDustVisuals()
	if self.dust >= dust_max and self.command ~= "Malfunction" then
		self:SetDisablingCommand("Malfunction")
	end
end

function DroneBase:SetDustVisuals()
	local normalized_dust = MulDivRound(self.dust, 255, self.dust_max)
	self:SetDust(normalized_dust, const.DustMaterialExterior)
end

function DroneBase:Getdust() 
	return MulDivRound(self.dust, 100, self.dust_max) 
end

function DroneBase:UseBattery(amount)
end

function DroneBase:RegisterDustDevil(devil)
	self.dust_devils = self.dust_devils or {}
	if self.dust_devils[devil] then
		return
	end
	
	local modifier = self.dust_devils.modifier or ObjectModifier:new{target = self, prop = "move_speed"}
	self.dust_devils.modifier = modifier
	if modifier.percent > -devil.drone_speed_down then
		modifier:Change(0, -devil.drone_speed_down)
	end
	self.dust_devils[devil] = true
	self.dust_devils.count = (self.dust_devils.count or 0) + 1
	
	if SelectedObj == self then
		ReopenSelectionXInfopanel()
	end
end

function DroneBase:UnregisterDustDevil(devil)
	if not self.dust_devils or not self.dust_devils[devil] then
		return
	end
	
	self.dust_devils[devil] = nil
	self.dust_devils.count = self.dust_devils.count - 1
	if self.dust_devils.count > 0 then
		local max = 0
		for devil in pairs(self.dust_devils) do
			max = Max(max, devil.drone_speed_down)
		end
		self.dust_devils.modifier:Change(0, -max)
	else
		self.dust_devils.modifier:delete()
		self.dust_devils = false
	end
	RebuildInfopanel(self)
end

function DroneBase:GetDustDevilPenalty()
	return self.dust_devils and self.dust_devils.modifier.percent or 0
end

function DroneBase:RepairDrone(drone, power)
	self:PushDestructor(function(self)
		if drone.repair_drone == self then
			drone.repair_drone = false
		end
		self:StopFX()
	end)
	drone.repair_drone = self
	for _ = 1, 2 do
		if drone.command == "NoBattery" then
			self.override_ui_status = "RechargeDrone"
			self:PushDestructor(function(self)
				self.override_ui_status = nil
			end)
			if not self:GotoUnitSpot(drone, self.work_spot_drone_recharge) then
				self:PopAndCallDestructor()
				break
			end
			self:Face(drone, 200)
			self:StartFX("Recharge", self, drone)	-- actor/target is reversed to match recharge station
			self:PlayState("rechargeDroneStart")
			self:PlayState("rechargeDroneIdle", 8, const.eDontCrossfade)
			if IsValid(drone) and not drone:IsDead() then
				drone.battery = drone.battery + power
				drone:SetCommand("Fixed", "noBatteryFixed")
			end
			self:PlayState("rechargeDroneEnd", 1, const.eDontCrossfade)
			self:StopFX()
			self:UseBattery(power)
			self:PopAndCallDestructor()
		elseif drone.command == "Malfunction" or (drone.command == "Freeze" and drone:CanBeThawed()) then
			if not self:GotoUnitSpot(drone, self.work_spot_drone_repair) then
				break
			end
			self:Face(drone, 200)
			self:StartFX("Repair", drone)
			self:PlayState("repairDroneStart")
			self:PlayState("repairDroneIdle", g_Consts.DroneRepairAnimReps, const.eDontCrossfade)
			if IsValid(drone) and not drone:IsDead() then
				drone.dust = 0
				drone:GenerateDustMalfunctionThreshold()
				drone:SetCommand("Fixed", "breakDownFixed")
			end
			self:PlayState("repairDroneEnd", 1, const.eDontCrossfade)
			self:StopFX()
		end
		Sleep(1) -- let the drone decide if it is ok
	end
	self:PopAndCallDestructor()
end

function DroneBase:OnModifiableValueChanged(prop, old_val, new_val)
	if prop == "move_speed" then
		self:SetMoveSpeed(new_val)
	end
end

function DroneBase:GetDisplayName()
	return self.name~="" and self.name or self.display_name
end

function DroneBase:GetShapePoints()
	return GetEntityOutlineShape(nil) --will get the fallback shape 1 hex.
end

function DroneBase:OnUnitControlActiveChanged(new_val)
end

function DroneBase:SetInteractionMode(mode)
	if self.interaction_mode == mode then
		SetUnitControlInteractionMode(self, false)
	else
		SetUnitControlInteractionMode(self, mode)
		local unit_ctrl_dlg = GetInGameInterfaceModeDlg()
		unit_ctrl_dlg:SetFocus(true)
	end
end

function DroneBase:IsMalfunctioned()
	return self.command == "Malfunction"
end

function DroneBase:SetMalfunction()
	self:SetCommand("Malfunction")
end

function DroneBase:Malfunction()
	self:SetIsNightLightPossible(false)
end

function DroneBase:Repair()
	self:SetIsNightLightPossible(true)
end

--ui hyperlinks use this to center on obj
function DroneBase:GetLogicalPos()
	return self:GetVisualPos()
end

function DroneBase:UseTunnel(tunnel)
	self:Unsiege()
	self:ExitHolder(tunnel)

	local pos = select(2, tunnel:GetEntrance(self, "tunnel_entrance"))
	if not pos or not self:Goto_NoDestlock(pos) or not IsValid(tunnel) then
		return
	end

	--the rest is non interruptable from outside
	self:PushDestructor(function(self)
		SetUnitControlInteraction(false, self)
	end)
	tunnel:TraverseTunnel(self)
	self:PopDestructor()
	SetUnitControlInteraction(false, self)

	-- get out from the tunnel exit
	local pos = tunnel:GetExitPosition(self)
	self:Goto(pos)
end

function DroneBase:UseElevator(elevator)
	self:PushDestructor(function(self)
		local pos = elevator:GetExitPosition(self)
		self:Goto(pos)
	end)
	
	Unit.UseElevator(self, elevator)
	self:PopDestructor()
end

function DroneBase:GotoAndEmbark(rocket)
	self:PushDestructor(function(self)
		self.control_override = nil
		self.embark_target = nil
	end, self)
	self.control_override = true
	self.embark_target = rocket
	self:SetCommandCenter(false, "do not orphan!")
	self:DropCarriedResource()
	
	local entrance = rocket.waypoint_chains and rocket.waypoint_chains.rocket_entrance[1]
	if entrance then
		local speed = self:GetSpeed()
		local count = #entrance
		local first_pt = count

		local p1 = entrance[count]
		local p2 = entrance[count - 1]
		local p = self:GetPos()
		if p ~= p1 and p ~= p2 then
			local init_at = count
			if IsCloser2D(p, p2, p1:Dist2D(p2)) then
				init_at = init_at - 1
			end
			self:Goto(entrance[init_at]) --use goto to reach first pt
		end
		if not IsValid(rocket) or not rocket:IsValidPos() or not rocket:IsBoardingAllowed() then 
			self:PopAndCallDestructor() -- control_override
			return 
		end
		
		table.insert(rocket.boarding, self)
		self:PushDestructor(function(self)
			table.remove_value(rocket.boarding, self)
			table.insert_unique(rocket.expedition.drones, self)
		end)
		
		for i = count - 1, 1, -1 do
			local p1 = entrance[i + 1]
			local p2 = entrance[i]
			local p3 = self:GetPos()
			if p2 ~= p3 then
				self:Face(p2)
				rocket:OnWaypointStartGoto(self, p1, p2)
				local t = p3:Dist(p2) * 1000 / speed
				self:SetPos(p2, t)
				Sleep(t)
				if not IsValid(rocket) or not rocket:IsValidPos() or not self:IsValidPos() then return end
			end
		end
		
		self:PopAndCallDestructor()
	else -- fallback, no entrance found
		self:Goto(rocket:GetPos())
	end	

	if not IsValid(rocket) then return end

	self:SetHolder(rocket)
	self:SetCommand("Disappear", "keep in holder")
end

function DroneBase:GetCursor()
	return self:CanBeControlled() and const.DefaultRoverCursor or const.DefaultMouseCursor
end