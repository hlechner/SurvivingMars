DefineClass.Holder = {
	__parents = {"WaypointsObj" },
	units = false,
}

function Holder:Done()
	self:KickUnitsFromHolder()
end

function Holder:KickUnitsFromHolder()
	local units = self.units
	self.units = nil
	if units then
		local cur_thread = CurrentThread()
		for i = 1, #units do
			local unit = units[i]
			assert(IsValid(unit), "(Shielded) Something went wrong. Units should not be invalid")
			assert(unit.command_thread ~= cur_thread or IsKindOf(self, "Elevator"), "Probable destructor interuption")
			if IsValid(unit) then
				unit:KickFromBuilding(self)
			end
		end
	end
end

function Holder:OnEnterHolder(unit)
	local units = self.units
	if units then
		units[#units + 1] = unit
	else
		self.units = { unit }
	end
end

function Holder:OnExitHolder(unit)
	table.remove_entry(self.units, unit)
	if unit == CameraFollowObjWaiting then
		Camera3pFollow(unit)
	end
end

function Holder:GetExitPosition(unit)
	if not unit:IsValidPos() then return end
	
	local max_da = 60*60
	local angle = max_da - unit:Random(2*max_da)
	local dist = unit:Random(5*guim, MulDivRound(20*guim, abs(cos(angle)), 4096))
	local target_pos = RotateRadius(dist, unit:GetAngle() + angle, unit:GetPos())
	if GetTerrain(unit):LinePassable(unit:GetPos(), target_pos) then
		return target_pos
	else
		return unit:GetPos() -- find a destlockable point nearby
	end
end
