function GetMarsAnomalyScenarios()
	return { "MarsAnomalies", "GenericAnomalies" }
end

function GroupMarsAnomalies()
	local target = "Anomalies"
	DataInstances.Scenario[target] = nil

	PlaceObj('Scenario', {
		'name', target,
		'singleton', false,
	})

	local sources = GetMarsAnomalyScenarios()
	local target_seq_list = DataInstances.Scenario[target]
	for _, source in pairs(sources) do
		local source_seq_list = DataInstances.Scenario[source] or {}
		target_seq_list = table.iappend(target_seq_list, source_seq_list)
		source_seq_list = nil
	end
end

OnMsg.DataLoaded = GroupMarsAnomalies
