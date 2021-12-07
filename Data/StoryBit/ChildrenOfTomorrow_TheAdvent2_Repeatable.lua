-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('StoryBit', {
	ActivationEffects = {},
	Effects = {
		PlaceObj('ForEachExecuteEffects', {
			'Label', "Colonist",
			'Filters', {
				PlaceObj('HasTrait', {
					'Trait', "Martianborn",
				}),
			},
			'Effects', {
				PlaceObj('ModifyObject', {
					'Prop', "base_morale",
					'Amount', "<morale_up>",
					'Sols', "<morale_up_sols>",
				}),
			},
		}),
	},
	Enables = {
		"ChildrenOfTomorrow_TheAdvent2_Repeatable",
	},
	MainMapExclusive = false,
	NotificationText = "",
	Prerequisites = {},
	ScriptDone = true,
	SuppressTime = 7200000,
	TextReadyForValidation = true,
	TextsDone = true,
	group = "Breakthroughs",
	id = "ChildrenOfTomorrow_TheAdvent2_Repeatable",
	qa_info = PlaceObj('PresetQAInfo', {
		data = {
			{
				action = "Modified",
				time = 1637247374,
			},
		},
	}),
	PlaceObj('StoryBitParamNumber', {
		'Name', "morale_up",
		'Value', 10,
	}),
	PlaceObj('StoryBitParamSols', {
		'Name', "morale_up_sols",
		'Value', 3600000,
	}),
})

