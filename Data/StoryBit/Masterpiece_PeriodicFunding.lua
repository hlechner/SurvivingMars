-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('StoryBit', {
	ActivationEffects = {
		PlaceObj('RewardFunding', {
			'Amount', "<funds>",
		}),
	},
	Effects = {},
	Enables = {
		"Masterpiece_PeriodicFunding",
	},
	MainMapExclusive = false,
	NotificationText = T(11042, --[[StoryBit Masterpiece_PeriodicFunding NotificationText]] "Received <funds> from art sales"),
	Prerequisites = {},
	ScriptDone = true,
	SuppressTime = 3600000,
	TextReadyForValidation = true,
	TextsDone = true,
	group = "Buildings",
	id = "Masterpiece_PeriodicFunding",
	qa_info = PlaceObj('PresetQAInfo', {
		data = {
			{
				action = "Modified",
				time = 1637247374,
			},
		},
	}),
	PlaceObj('StoryBitParamFunding', {
		'Name', "funds",
		'Value', 250000000,
	}),
})

