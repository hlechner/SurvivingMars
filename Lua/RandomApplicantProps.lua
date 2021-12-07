DefineClass.RandomApplicantProps = {
	__parents = { "PropertyObject" },
	properties = {
		{ category = "General", id = "Trait",  name = "Trait", editor = "dropdownlist", default = "", 
			items = function() 
				local traits = TraitsCombo(nil, nil, "no specialziations") 
				table.insert(traits, {value = "random_positive", text = "Random Positive"})
				table.insert(traits, {value = "random_negative", text = "Random Negative"})
				table.insert(traits, {value = "random_rare", text = "Random Rare"})
				table.insert(traits, {value = "random_common", text = "Random Common"})
				table.insert(traits, {value = "random", text = "Random"})
				return traits
			end},
		{ category = "General", id = "Specialization", editor = "dropdownlist", default = "any", 
			items = function() 
				local items = GetColonistSpecializationCombo("empty")()
				table.insert(items, 1, {value = "any", text = "Random Specialization"})
				return items
			end},
	},	
}