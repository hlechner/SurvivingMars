-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

local _slots = {
	{
		flags_missing = 1,
		goto_spot = "LeadToSpot",
		groups = {
			["A"] = true,
		},
		spots = {
			"Playground",
		},
	},
	{
		flags_missing = 1,
		goto_spot = "LeadToSpot",
		groups = {
			["A"] = true,
		},
		spots = {
			"Playtablet",
		},
	},
}
PrgAmbientLife["VisitNursery"] = function(unit, bld)
	local spot, obj, desc, slot, slotname, pos, __placed

	unit:PushDestructor(function(unit)
		if IsValid(__placed) then
			DoneObject(__placed)
		end
	end)

	spot, obj, desc, slot, slotname = PrgGetObjRandomSpotFromGroup(bld, nil, "A", _slots, unit)
	pos = spot and obj:GetSpotLocPos(spot)
	if spot then
		if slotname == "Playtablet" then
			__placed = PlaceObjectIn("Tablet", unit:GetMapID(), nil, const.cofComponentAttach)
			NetTempObject(__placed)
			unit:Attach(__placed, unit:GetRandomSpot("Tablet"))
		end
		PrgVisitSlot(unit, bld, obj, spot, desc, slot, slotname)
		if unit.visit_restart then unit:PopAndCallDestructor() return end
	else
		PrgVisitHolder(unit, bld)
		if unit.visit_restart then unit:PopAndCallDestructor() return end
	end
	PrgLeadToExit(unit, bld)
	if unit.visit_restart then unit:PopAndCallDestructor() return end

	unit:PopAndCallDestructor()
end
