DefineClass.Shroudable = {
	__parents = {
		"Object",
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

function Shroudable:ClearOwnRubble()
	local rubble_table = table.copy(self.shrouding_rubble or empty_table)
	for _, rubble in ipairs(rubble_table) do
		rubble:OnClear()
	end
	self.shrouding_rubble = {}
end

function SavegameFixups.ClearRubbleTables()
	MapsForEach("map", "Shroudable", function(o)
		local rubble_table = o.shrouding_rubble or empty_table
		for i = #rubble_table, 1, -1  do
			local rubble = rubble_table[i]
			if not IsValid(rubble) then 
				table.remove(rubble_table, i)
			end
		end
		if IsKindOf(o, "Building") then
			o:UpdateWorking()
		end
	end)
end