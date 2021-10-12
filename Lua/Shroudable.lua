DefineClass.Shroudable = {
	shrouding_rubble = false,
}

function Shroudable:IsShroudedInRubble()
	local rubble = self.shrouding_rubble or empty_table
	return #rubble > 0
end