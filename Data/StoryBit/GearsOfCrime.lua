-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('StoryBit', {
	ActivationEffects = {},
	Category = "Tick_FounderStageDone",
	Effects = {
		PlaceObj('ForEachExecuteEffects', {
			'Label', "FactoryBuildings",
			'Filters', {},
			'Effects', {
				PlaceObj('Malfunction', nil),
			},
		}),
	},
	Enabled = true,
	Image = "UI/Messages/Events/04_interrogation.tga",
	MainMapExclusive = false,
	Prerequisites = {
		PlaceObj('CheckObjectCount', {
			'Label', "Colonist",
			'Filters', {
				PlaceObj('HasTrait', {
					'Trait', "engineer",
				}),
				PlaceObj('HasTrait', {
					'Trait', "Renegade",
				}),
			},
			'Condition', ">=",
			'Amount', 1,
		}),
		PlaceObj('CheckObjectCount', {
			'Label', "Building",
			'Filters', {
				PlaceObj('IsBuildingClass', {
					'Template', {
						"ElectronicsFactory",
						"ElectronicsFactory_Small",
						"MachinePartsFactory",
						"MachinePartsFactory_Small",
						"PolymerPlant",
					},
				}),
			},
			'Condition', ">",
			'Amount', 0,
		}),
		PlaceObj('IsMapEnvironment', {
			'Negate', true,
			'SelectedMapEnvironment', "Asteroid",
		}),
	},
	ScriptDone = true,
	Text = T(279719620496, --[[StoryBit GearsOfCrime Text]] "A short investigation into the matter has revealed that a Renegade Engineer has actively been sabotaging repair parts used in the maintenance of these factories.\n\nCiting the bad conditions and contempt they feel for the leadership of the colony as reasons for their behavior, they thought that sabotaging the mission would somehow advance their cause."),
	TextReadyForValidation = true,
	TextsDone = true,
	Title = T(616417254122, --[[StoryBit GearsOfCrime Title]] "Renegades: Gears of Crime"),
	VoicedText = T(441775588556, --[[voice:narrator]] "Our factories have began eating up a lot of electricity."),
	group = "Renegades",
	id = "GearsOfCrime",
	qa_info = PlaceObj('PresetQAInfo', {
		data = {
			{
				action = "Modified",
				time = 1625147585,
			},
		},
	}),
	PlaceObj('StoryBitReply', {
		'Text', T(428264166418, --[[StoryBit GearsOfCrime Text]] "Great stuff..."),
		'OutcomeText', "custom",
		'CustomOutcomeText', T(735009949626, --[[StoryBit GearsOfCrime CustomOutcomeText]] "All Factories closed for repairs after sabotage."),
	}),
})

