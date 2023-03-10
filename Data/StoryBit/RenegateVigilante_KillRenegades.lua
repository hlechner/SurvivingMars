-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('StoryBit', {
	ActivationEffects = {},
	Effects = {
		PlaceObj('ForEachExecuteEffects', {
			'Label', "Colonist",
			'Filters', {
				PlaceObj('HasTrait', {
					'Trait', "Renegade",
				}),
			},
			'RandomCount', 3,
			'Effects', {
				PlaceObj('KillColonist', nil),
			},
		}),
	},
	Enables = {
		"RenegateVigilante_KillRenegades",
	},
	MainMapExclusive = false,
	NotificationText = T(11384, --[[StoryBit RenegateVigilante_KillRenegades NotificationText]] "The vigilante strikes again"),
	Prerequisites = {
		PlaceObj('CheckObjectCount', {
			'Label', "Colonist",
			'Filters', {
				PlaceObj('HasTrait', {
					'Trait', "Renegade",
				}),
			},
			'Condition', ">=",
			'Amount', 3,
		}),
	},
	ScriptDone = true,
	SelectObject = false,
	SuppressTime = 600000,
	TextReadyForValidation = true,
	TextsDone = true,
	group = "Renegades",
	id = "RenegateVigilante_KillRenegades",
	qa_info = PlaceObj('PresetQAInfo', {
		data = {
			{
				action = "Modified",
				time = 1552918144,
				user = "Lina",
			},
			{
				action = "Modified",
				time = 1637250330,
			},
		},
	}),
})

