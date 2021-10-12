-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	group = "Infopanel Sections",
	id = "customMartianUniversity",
	PlaceObj('XTemplateTemplate', {
		'__context_of_kind', "MartianUniversity",
		'__template', "InfopanelActiveSection",
		'RolloverText', T(7977, --[[XTemplate customMartianUniversity RolloverText]] "<TrainedRollover>"),
		'RolloverTitle', T(240, --[[XTemplate customMartianUniversity RolloverTitle]] "Specialization"),
		'RolloverHint', T(703125928773, --[[XTemplate customMartianUniversity RolloverHint]] "<left_click> Select specialization<newline><em>Ctrl + <left_click> on specialization</em> Select in all Universities"),
		'RolloverHintGamepad', T(896744390747, --[[XTemplate customMartianUniversity RolloverHintGamepad]] "<ButtonA> Select specialization<newline><em><ButtonX> on specialization</em> Select in all Universities"),
		'UniformRowHeight', true,
		'Title', T(440284296071, --[[XTemplate customMartianUniversity Title]] "Training<right><Specialization>"),
		'Icon', "UI/Icons/Sections/traits.tga",
		'TitleHAlign', "stretch",
	}, {
		PlaceObj('XTemplateFunc', {
			'name', "OnActivate(self, context)",
			'parent', function (parent, context) return parent.parent end,
			'func', function (self, context)
				OpenInfopanelItems(context, self)
			end,
		}),
		}),
	PlaceObj('XTemplateWindow', {
		'__class', "XFrame",
		'IdNode', false,
		'Margins', box(17, -12, 0, -13),
		'Padding', box(0, 22, 0, 22),
		'LayoutMethod', "VList",
		'Image', "UI/CommonNew/ip_header.tga",
		'FrameBox', box(12, 12, 0, 12),
	}, {
		PlaceObj('XTemplateTemplate', {
			'__template', "InfopanelText",
			'Margins', box(52, 0, 20, 4),
			'Text', T(509074303312, --[[XTemplate customMartianUniversity Text]] "Lifetime graduates<right><life_time_trained>"),
		}),
		PlaceObj('XTemplateTemplate', {
			'__template', "InfopanelText",
			'Margins', box(52, 0, 20, 4),
			'Text', T(13820, --[[XTemplate customMartianUniversity Text]] "Next graduate in:"),
		}),
		PlaceObj('XTemplateTemplate', {
			'__template', "InfopanelProgress",
			'Margins', box(52, 0, 20, 4),
			'BindTo', "HighestUnitsTrainingProgress",
		}),
		}),
	PlaceObj('XTemplateTemplate', {
		'__context_of_kind', "MartianUniversity",
		'__template', "InfopanelSection",
		'Title', T(508811339853, --[[XTemplate customMartianUniversity Title]] "Needed specializations"),
	}, {
		PlaceObj('XTemplateTemplate', {
			'__template', "InfopanelText",
			'Text', T(806240447341, --[[XTemplate customMartianUniversity Text]] "<NeededSpecializations>"),
		}),
		}),
})

