-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('StoryBit', {
	ActivationEffects = {},
	Effects = {
		PlaceObj('RewardPrefab', {
			'Amount', 1,
			'Prefab', "TriboelectricScrubber",
		}),
		PlaceObj('RewardTechBoost', {
			'Field', "Physics",
			'Research', "TriboelectricScrubbing",
			'Amount', 10,
		}),
	},
	MainMapExclusive = false,
	Prerequisites = {},
	ScriptDone = true,
	SuppressTime = 3600000,
	Text = T(857899493605, --[[StoryBit Prototype_Scrubber_Success Text]] "<effect>Triboelectric Scrubber prefab has been added. Insights gained from the project have resulted in a <tech_boost>% progress towards the Triboelectric Scrubbing technology."),
	TextReadyForValidation = true,
	TextsDone = true,
	VoicedText = T(846305562522, --[[voice:narrator]] "Our Scientists have succeeded in building the prototype Triboelectric Scrubber."),
	group = "Buildings",
	id = "Prototype_Scrubber_Success",
	qa_info = PlaceObj('PresetQAInfo', {
		data = {
			{
				action = "Modified",
				time = 1637247374,
			},
		},
	}),
	PlaceObj('StoryBitParamPercent', {
		'Name', "tech_boost",
		'Value', 10,
	}),
})

