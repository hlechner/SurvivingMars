-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('StoryBit', {
	ActivationEffects = {
		PlaceObj('ForEachExecuteEffects', {
			'Label', "Colonist",
			'Filters', {
				PlaceObj('HasTrait', {
					'Trait', "Martianborn",
				}),
			},
			'Effects', {
				PlaceObj('ModifyColonistStat', {
					'Stat', "Comfort",
					'Amount', "<comfort_gain>",
				}),
			},
		}),
	},
	Effects = {},
	Enables = {
		"ChildrenOfTomorrow_TheAdvent1_Repeatable",
	},
	MainMapExclusive = false,
	NotificationText = "",
	Prerequisites = {},
	ScriptDone = true,
	SuppressTime = 7200000,
	TextReadyForValidation = true,
	TextsDone = true,
	group = "Breakthroughs",
	id = "ChildrenOfTomorrow_TheAdvent1_Repeatable",
	qa_info = PlaceObj('PresetQAInfo', {
		data = {
			{
				action = "Modified",
				time = 1637247374,
			},
		},
	}),
	PlaceObj('StoryBitParamNumber', {
		'Name', "comfort_gain",
		'Value', 30,
	}),
})

