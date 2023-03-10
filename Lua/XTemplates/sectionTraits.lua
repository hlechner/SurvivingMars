-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	group = "Infopanel Sections",
	id = "sectionTraits",
	PlaceObj('XTemplateGroup', {
		'__condition', function (parent, context) return IsKindOfClasses(context, "School", "Sanatorium") end,
	}, {
		PlaceObj('XTemplateForEach', {
			'array', function (parent, context) return nil, 1, context.max_traits end,
			'run_after', function (child, context, item, i, n)
				rawset(child, "n", n)
			end,
		}, {
			PlaceObj('XTemplateTemplate', {
				'__template', "InfopanelActiveSection",
				'RolloverText', T(257506711483, --[[XTemplate sectionTraits RolloverText]] "Select a trait that is affected by this building."),
				'RolloverHint', T(988789013053, --[[XTemplate sectionTraits RolloverHint]] "<left_click> Change<newline><em>Ctrl + <left_click> on trait</em> Select in all <display_name_pl>"),
				'RolloverHintGamepad', T(958322390788, --[[XTemplate sectionTraits RolloverHintGamepad]] "<ButtonA> Change<newline><em><ButtonX> on trait</em> Select in all <display_name_pl>"),
				'OnContextUpdate', function (self, context, ...)
					local trait_id = ResolveValue(context, "trait" .. self.n)
					if trait_id=="auto" then
						self:SetTitle(T{7421, "Trait: <trait_name>", trait_name = T(669, "Auto")})
						return
					end
					local trait = TraitPresets[trait_id]
					self:SetTitle(trait and T{7421, "Trait: <trait_name>", trait_name = trait.display_name} or T(7422, "Select a Trait"))
				end,
				'Icon', "UI/Icons/Sections/traits.tga",
			}, {
				PlaceObj('XTemplateFunc', {
					'name', "OnActivate(self, context)",
					'parent', function (parent, context) return parent.parent end,
					'func', function (self, context)
						OpenInfopanelItems(context, self, self.n)
					end,
				}),
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
				'__context_of_kind', "Sanatorium",
				'__template', "InfopanelText",
				'Margins', box(52, 0, 20, 4),
				'Text', T(745754891525, --[[XTemplate sectionTraits Text]] "Lifetime cured<right><life_time_trained>"),
			}),
			PlaceObj('XTemplateTemplate', {
				'__context_of_kind', "Sanatorium",
				'__template', "InfopanelText",
				'Margins', box(52, 0, 20, 4),
				'Text', T(13821, --[[XTemplate sectionTraits Text]] "Next cured in:"),
			}),
			PlaceObj('XTemplateTemplate', {
				'__context_of_kind', "School",
				'__template', "InfopanelText",
				'Margins', box(52, 0, 20, 4),
				'Text', T(186914304841, --[[XTemplate sectionTraits Text]] "Lifetime graduates<right><life_time_trained>"),
			}),
			PlaceObj('XTemplateTemplate', {
				'__context_of_kind', "School",
				'__template', "InfopanelText",
				'Margins', box(52, 0, 20, 4),
				'Text', T(13822, --[[XTemplate sectionTraits Text]] "Next graduate in:"),
			}),
			PlaceObj('XTemplateTemplate', {
				'__context_of_kind', "TrainingBuilding",
				'__template', "InfopanelProgress",
				'Margins', box(52, 0, 20, 4),
				'BindTo', "HighestUnitsTrainingProgress",
			}),
			}),
		}),
})

