DefineClass.Shroudable = {
	__parents = {
		"InitDone",
	},
	shrouding_rubble = false,
}

function Shroudable:Done()
	for _,rubble in ipairs(self.shrouding_rubble or empty_table) do
		table.remove_entry(rubble.shrouded_objects, self)
	end
end

function Shroudable:IsShroudedInRubble()
	local rubble = self.shrouding_rubble or empty_table
	return #rubble > 0
end