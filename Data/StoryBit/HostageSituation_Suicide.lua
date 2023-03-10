-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('StoryBit', {
	ActivationEffects = {},
	Effects = {
		PlaceObj('ForceSuicide', nil),
	},
	MainMapExclusive = false,
	Prerequisites = {},
	ScriptDone = true,
	Text = T(302241594445, --[[StoryBit HostageSituation_Suicide Text]] "When <DisplayName> received a message confirming the payment, they took an improvised gun out of their pocket and committed suicide.\n\nWhy they did this and to whom the money was transferred may never be known."),
	TextReadyForValidation = true,
	TextsDone = true,
	VoicedText = T(426523429304, --[[voice:narrator]] "You wired the money, prepared the Rover and then something strange happened."),
	group = "Renegades",
	id = "HostageSituation_Suicide",
	qa_info = PlaceObj('PresetQAInfo', {
		data = {
			{
				action = "Modified",
				time = 1637250330,
			},
		},
	}),
	PlaceObj('StoryBitParamFunding', {
		'Name', "money",
		'Value', 550000000,
	}),
})

