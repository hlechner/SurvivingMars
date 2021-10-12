DefineClass.MiniMysteries = {
	mini_mystery = false,
	has_mini_mystery = false,
	previous_mini_mysteries = false,
}

function MiniMysteries:StartMiniMystery(mini_mystery_name, map_id, mini_mystery)
	CreateGameTimeThread(function()
		local seq_list = DataInstances.Scenario[mini_mystery_name]
		self.mini_mystery = mini_mystery
		RunSequenceList(seq_list, map_id)
		self.has_mini_mystery = false
		self.mini_mystery = false
		table.insert(self.previous_mini_mysteries, mini_mystery_name)
	end)
end

function MiniMysteries:FilterPresets(presets, force_mini_mystery)
	if not self.previous_mini_mysteries then self.previous_mini_mysteries = {} end
	
	local PresetFilter = function(_,preset)
		local available_sequences = #table.subtraction(preset.sequences, self.previous_mini_mysteries) > 0
		
		if force_mini_mystery and not self.has_mini_mystery then
			return available_sequences
		end
		
		return not (self.has_mini_mystery and available_sequences)
	end
	
	return table.ifilter(presets, PresetFilter)
end

function MiniMysteries:GetNumColonists()
	if self.mini_mystery.city.labels.Colonist ~= nil then
		return #(self.mini_mystery.city.labels.Colonist or empty_table)
	end
	return 0
end

function OnMsg.NewMapLoaded(map_id)
	local map_data = ActiveMaps[map_id]
	if UIColony and map_data:HasMember("mini_mystery_name") and map_data.mini_mystery_name then
		UIColony:StartMiniMystery(map_data.mini_mystery_name, map_id, { city = Cities[map_id] })
	end
end
