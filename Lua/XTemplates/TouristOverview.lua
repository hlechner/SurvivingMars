-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	group = "InGame",
	id = "TouristOverview",
	PlaceObj('XTemplateWindow', {
		'__context', function (parent, context) return context or {} end,
		'__class', "XDialog",
	}, {
		PlaceObj('XTemplateFunc', {
			'name', "Close",
			'func', function (self, ...)
				local mode_dlg = GetInGameInterfaceModeDlg()
				mode_dlg:SetParent(GetInGameInterface())
				XDialog.Close(self, ...)
			end,
		}),
		PlaceObj('XTemplateLayer', {
			'__condition', function (parent, context) return GameState.gameplay end,
			'layer', "ScreenBlur",
			'layer_id', "idBlur",
		}),
		PlaceObj('XTemplateLayer', {
			'layer', "XPauseLayer",
		}),
		PlaceObj('XTemplateLayer', {
			'layer', "XHideInfopanelLayer",
		}),
		PlaceObj('XTemplateTemplate', {
			'__context', function (parent, context) return context or {} end,
			'__template', "NewOverlayDlg",
			'MinWidth', 500,
			'InitialMode', "colonists",
			'InternalModes', "colonists, domes, traits",
		}, {
			PlaceObj('XTemplateCode', {
				'run', function (self, parent, context)
					local dlg = GetDialog(parent)
					if dlg then
						dlg.OnShortcut = function(dlg, shortcut, source)
							if shortcut == "RightShoulder" and rawget(dlg, "idList") then
								if not dlg.idList:IsFocused(true) then
									dlg.idList:SetFocus()
									dlg.idList:SetSelection(rawget(dlg, "last_list_focus") or 1)
									return "break"
								end
							elseif shortcut == "LeftShoulder" and rawget(dlg, "idButtons") then
								if not dlg.idButtons:IsFocused(true) then
									rawset(dlg, "last_list_focus", dlg.idList.focused_item)
									dlg.idButtons[1]:SetFocus()
									return "break"
								end
							end
							return XDialog.OnShortcut(dlg, shortcut, source)
						end
					end
				end,
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "CommandCenterTitle",
				'Title', T(345255658639, --[[XTemplate TouristOverview Title]] "TOURISTS in <rocket_name>"),
			}),
			PlaceObj('XTemplateWindow', {
				'__context', function (parent, context) return context or {} end,
				'__class', "XContentTemplate",
				'Id', "idContent",
				'IdNode', false,
				'GridStretchX', false,
				'GridStretchY', false,
			}, {
				PlaceObj('XTemplateMode', {
					'mode', "colonists",
				}, {
					PlaceObj('XTemplateTemplate', {
						'__template', "ScrollbarNew",
						'Id', "idButtonsScroll",
						'ZOrder', 0,
						'Margins', box(87, 0, 0, 0),
						'Target', "idButtonsScrollArea",
					}),
					PlaceObj('XTemplateWindow', {
						'__class', "XScrollArea",
						'Id', "idButtonsScrollArea",
						'IdNode', false,
						'Dock', "left",
						'VScroll', "idButtonsScroll",
					}, {
						PlaceObj('XTemplateWindow', {
							'__class', "XContextWindow",
							'Id', "idButtons",
							'Margins', box(12, 0, 0, 0),
							'LayoutMethod', "VList",
							'OnContextUpdate', function (self, context, ...)
								for _, child in ipairs(self) do
									child:OnContextUpdate(context, ...)
								end
								XContextWindow.OnContextUpdate(self, context, ...)
							end,
						}, {
							PlaceObj('XTemplateFunc', {
								'name', "OnShortcut(self, shortcut, source)",
								'func', function (self, shortcut, source)
									return CCC_ButtonListOnShortcut(self, shortcut, source)
								end,
							}),
							PlaceObj('XTemplateTemplate', {
								'__template', "CommandCenterButton",
								'RolloverTitle', T(12783, --[[XTemplate TouristOverview RolloverTitle]] "Age Group"),
								'Id', "idAge",
								'Margins', box(-12, 40, 0, -14),
								'OnContextUpdate', function (self, context, ...)
									XTextButton.OnContextUpdate(self, context, ...)
									self:SetRolloverText(GetColonistsFilterRollover(context, T(9672, "Filter by Age Group.")))
									local hint_gamepad = T(507431830973, "<ButtonA> Set filter") .. " " .. T(9802, "<RB> Inspect")
									self:SetRolloverHintGamepad(hint_gamepad)
								end,
								'OnPress', function (self, gamepad)
									SpawnTraitsPopup(self, "Age Group")
								end,
								'Image', "UI/CommonNew/ccc_categories_small.tga",
							}, {
								PlaceObj('XTemplateWindow', {
									'__class', "XText",
									'Id', "idText",
									'Margins', box(15, 0, 0, 0),
									'VAlign', "center",
									'TextStyle', "CCCFilterItem",
									'ContextUpdateOnOpen', true,
									'OnContextUpdate', function (self, context, ...)
										local trait = self.context["trait_Age Group"]
										local trait_name = trait and trait.display_name or T(11679, "No filter")
										self:SetText(T{11608, "AGE GROUP: <em><trait></em>", trait = trait_name})
									end,
									'Translate', true,
								}),
								}),
							PlaceObj('XTemplateTemplate', {
								'__template', "CommandCenterButton",
								'RolloverTitle', T(12784, --[[XTemplate TouristOverview RolloverTitle]] "Specialization"),
								'Id', "idSpec",
								'Margins', box(-12, 0, 0, -14),
								'OnContextUpdate', function (self, context, ...)
									XTextButton.OnContextUpdate(self, context, ...)
									self:SetRolloverText(GetColonistsFilterRollover(context, T(11610, "Filter by Specialization.")))
									local hint_gamepad = T(507431830973, "<ButtonA> Set filter") .. " " .. T(9802, "<RB> Inspect")
									self:SetRolloverHintGamepad(hint_gamepad)
								end,
								'OnPress', function (self, gamepad)
									SpawnTraitsPopup(self, "Specialization")
								end,
								'Image', "UI/CommonNew/ccc_categories_small.tga",
							}, {
								PlaceObj('XTemplateWindow', {
									'__class', "XText",
									'Id', "idText",
									'Margins', box(15, 0, 0, 0),
									'VAlign', "center",
									'TextStyle', "CCCFilterItem",
									'ContextUpdateOnOpen', true,
									'OnContextUpdate', function (self, context, ...)
										local trait = self.context.trait_Specialization
										local trait_name = trait and trait.display_name or T(11679, "No filter")
										self:SetText(T{11611, "SPECIALIZATION: <em><trait></em>", trait = trait_name})
									end,
									'Translate', true,
								}),
								}),
							PlaceObj('XTemplateTemplate', {
								'__template', "CommandCenterButton",
								'RolloverTitle', T(12785, --[[XTemplate TouristOverview RolloverTitle]] "Interest"),
								'Id', "idInterest",
								'Margins', box(-12, 0, 0, -14),
								'OnContextUpdate', function (self, context, ...)
									XTextButton.OnContextUpdate(self, context, ...)
									self:SetRolloverText(GetColonistsFilterRollover(context, T(11834, "Filter by Interest.")))
									local hint_gamepad = T(507431830973, "<ButtonA> Set filter") .. " " .. T(9802, "<RB> Inspect")
									self:SetRolloverHintGamepad(hint_gamepad)
								end,
								'OnPress', function (self, gamepad)
									SpawnTraitsPopup(self, "interest")
								end,
								'Image', "UI/CommonNew/ccc_categories_small.tga",
							}, {
								PlaceObj('XTemplateWindow', {
									'__class', "XText",
									'Id', "idText",
									'Margins', box(15, 0, 0, 0),
									'VAlign', "center",
									'TextStyle', "CCCFilterItem",
									'ContextUpdateOnOpen', true,
									'OnContextUpdate', function (self, context, ...)
										local interest = self.context.trait_interest
										local interest_name = interest and interest.display_name or T(11679, "No filter")
										self:SetText(T{11835, "INTEREST: <em><interest></em>", interest = interest_name})
									end,
									'Translate', true,
								}),
								}),
							PlaceObj('XTemplateTemplate', {
								'__template', "CommandCenterButton",
								'RolloverTitle', T(12786, --[[XTemplate TouristOverview RolloverTitle]] "Perks"),
								'Id', "idPerk",
								'Margins', box(-12, 0, 0, -14),
								'OnContextUpdate', function (self, context, ...)
									XTextButton.OnContextUpdate(self, context, ...)
									self:SetRolloverText(GetColonistsFilterRollover(context, T(11613, "Filter by Perks.")))
									local hint_gamepad = T(507431830973, "<ButtonA> Set filter") .. " " .. T(9802, "<RB> Inspect")
									self:SetRolloverHintGamepad(hint_gamepad)
								end,
								'OnPress', function (self, gamepad)
									SpawnTraitsPopup(self, "Positive")
								end,
								'Image', "UI/CommonNew/ccc_categories_small.tga",
							}, {
								PlaceObj('XTemplateWindow', {
									'__class', "XText",
									'Id', "idText",
									'Margins', box(15, 0, 0, 0),
									'VAlign', "center",
									'TextStyle', "CCCFilterItem",
									'ContextUpdateOnOpen', true,
									'OnContextUpdate', function (self, context, ...)
										local trait = self.context.trait_Positive
										local trait_name = trait and trait.display_name or T(11679, "No filter")
										self:SetText(T{11614, "PERK: <em><trait></em>", trait = trait_name})
									end,
									'Translate', true,
								}),
								}),
							PlaceObj('XTemplateTemplate', {
								'__template', "CommandCenterButton",
								'RolloverTitle', T(12787, --[[XTemplate TouristOverview RolloverTitle]] "Quirk"),
								'Id', "idQuirk",
								'Margins', box(-12, 0, 0, -14),
								'OnContextUpdate', function (self, context, ...)
									XTextButton.OnContextUpdate(self, context, ...)
									self:SetRolloverText(GetColonistsFilterRollover(context, T(11616, "Filter by Quirk.")))
									local hint_gamepad = T(507431830973, "<ButtonA> Set filter") .. " " .. T(9802, "<RB> Inspect")
									self:SetRolloverHintGamepad(hint_gamepad)
								end,
								'OnPress', function (self, gamepad)
									SpawnTraitsPopup(self, "other")
								end,
								'Image', "UI/CommonNew/ccc_categories_small.tga",
							}, {
								PlaceObj('XTemplateWindow', {
									'__class', "XText",
									'Id', "idText",
									'Margins', box(15, 0, 0, 0),
									'VAlign', "center",
									'TextStyle', "CCCFilterItem",
									'ContextUpdateOnOpen', true,
									'OnContextUpdate', function (self, context, ...)
										local trait = self.context.trait_other
										local trait_name = trait and trait.display_name or T(11679, "No filter")
										self:SetText(T{11617, "QUIRK: <em><trait></em>", trait = trait_name})
									end,
									'Translate', true,
								}),
								}),
							PlaceObj('XTemplateTemplate', {
								'__template', "CommandCenterButton",
								'RolloverText', T(12788, --[[XTemplate TouristOverview RolloverText]] "Filter by Flaw"),
								'RolloverTitle', T(12789, --[[XTemplate TouristOverview RolloverTitle]] "Flaw"),
								'Id', "idFlaw",
								'Margins', box(-12, 0, 0, -14),
								'OnContextUpdate', function (self, context, ...)
									XTextButton.OnContextUpdate(self, context, ...)
									self:SetRolloverText(GetColonistsFilterRollover(context, T(11618, "Filter by Flaw.")))
									local hint_gamepad = T(507431830973, "<ButtonA> Set filter") .. " " .. T(9802, "<RB> Inspect")
									self:SetRolloverHintGamepad(hint_gamepad)
								end,
								'OnPress', function (self, gamepad)
									SpawnTraitsPopup(self, "Negative")
								end,
								'Image', "UI/CommonNew/ccc_categories_small.tga",
							}, {
								PlaceObj('XTemplateWindow', {
									'__class', "XText",
									'Id', "idText",
									'Margins', box(15, 0, 0, 0),
									'VAlign', "center",
									'TextStyle', "CCCFilterItem",
									'ContextUpdateOnOpen', true,
									'OnContextUpdate', function (self, context, ...)
										local trait = self.context.trait_Negative
										local trait_name = trait and trait.display_name or T(11679, "No filter")
										self:SetText(T{11619, "FLAW: <em><trait></em>", trait = trait_name})
									end,
									'Translate', true,
								}),
								}),
							PlaceObj('XTemplateCode', {
								'run', function (self, parent, context)
									if GetUIStyleGamepad() then
										local first = parent[1]
										CreateRealTimeThread(function(first)
											if first.window_state ~= "destroying" then
												first:SetFocus()
											end
										end, first)
									end
								end,
							}),
							}),
						}),
					}),
				PlaceObj('XTemplateWindow', {
					'__class', "XSizeConstrainedWindow",
					'HAlign', "left",
				}, {
					PlaceObj('XTemplateTemplate', {
						'__template', "ScrollbarNew",
						'Id', "idScroll",
						'Target', "idList",
					}),
					PlaceObj('XTemplateMode', {
						'mode', "colonists",
					}, {
						PlaceObj('XTemplateAction', {
							'ActionId', "close",
							'ActionName', T(208066612611, --[[XTemplate TouristOverview ActionName]] "CLOSE"),
							'ActionToolbar', "ActionBar",
							'ActionShortcut', "Escape",
							'ActionGamepad', "ButtonB",
							'OnActionEffect', "close",
							'OnAction', function (self, host, source)
								HolidayRating:CloseTouristOverview()
							end,
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "interests",
							'ActionName', T(12790, --[[XTemplate TouristOverview ActionName]] "INTERESTS"),
							'ActionToolbar', "ActionBar",
							'ActionGamepad', "ButtonY",
							'ActionState', function (self, host)
								return host.context.interests and "hidden"
							end,
							'OnAction', function (self, host, source)
								ToggleColonistsTraitsInterests(host)
								host:UpdateActionViews(host.idActionBar)
							end,
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "traits",
							'ActionName', T(12791, --[[XTemplate TouristOverview ActionName]] "TRAITS"),
							'ActionToolbar', "ActionBar",
							'ActionGamepad', "ButtonY",
							'ActionState', function (self, host)
								return not host.context.interests and "hidden"
							end,
							'OnAction', function (self, host, source)
								ToggleColonistsTraitsInterests(host)
								host:UpdateActionViews(host.idActionBar)
							end,
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "reset",
							'ActionName', T(12792, --[[XTemplate TouristOverview ActionName]] "RESET FILTERS"),
							'ActionToolbar', "ActionBar",
							'ActionGamepad', "ButtonX",
							'OnAction', function (self, host, source)
								host.context.dome = nil
								host.context.able_to_work = nil
								host.context.unable_to_work = nil
								host.context.homeless = nil
								host.context.unemployed = nil
								host.context.problematic_colonists = nil
								host.context["trait_Age Group"] = nil
								host.context["trait_Negative"] = nil
								host.context["trait_Specialization"] = nil
								host.context["trait_other"] = nil
								host.context["trait_Positive"] = nil
								host.context.sort_type = nil
								host.context.sort_ascending = nil
								host:ResolveId("idContent"):RespawnContent()
							end,
						}),
						PlaceObj('XTemplateWindow', {
							'comment', "column titles",
							'Margins', box(83, 0, 0, 15),
							'Dock', "top",
							'LayoutMethod', "HList",
						}, {
							PlaceObj('XTemplateWindow', {
								'comment', "name",
								'__class', "XText",
								'Padding', box(0, 0, 0, 0),
								'MinWidth', 200,
								'MaxWidth', 200,
								'HandleMouse', false,
								'TextStyle', "OverviewItemSection",
								'Translate', true,
								'Text', T(974775805233, --[[XTemplate TouristOverview Text]] "Tourists"),
								'TextVAlign', "center",
							}),
							PlaceObj('XTemplateWindow', {
								'comment', "holiday rating",
								'__class', "XText",
								'Id', "idHolidayRating",
								'Margins', box(3, 0, 0, 0),
								'MinWidth', 120,
								'MaxWidth', 200,
								'HandleMouse', false,
								'MouseCursor', "UI/Cursors/Rollover.tga",
								'TextStyle', "OverviewItemSection",
								'Translate', true,
								'Text', T(771121148729, --[[XTemplate TouristOverview Text]] "Holiday Rating"),
							}),
							PlaceObj('XTemplateWindow', {
								'comment', "stats: health",
								'__class', "XTextButton",
								'Margins', box(29, 0, 0, 0),
								'MinWidth', 36,
								'MinHeight', 31,
								'MaxWidth', 36,
								'MaxHeight', 31,
								'MouseCursor', "UI/Cursors/Rollover.tga",
								'OnPress', function (self, gamepad)
									SetColonistsSorting(self, "stat_health")
								end,
								'Image', "UI/Icons/Sections/health.tga",
							}),
							PlaceObj('XTemplateWindow', {
								'comment', "stats: stress",
								'__class', "XTextButton",
								'Margins', box(24, 0, 0, 0),
								'MinWidth', 36,
								'MinHeight', 31,
								'MaxWidth', 36,
								'MaxHeight', 31,
								'MouseCursor', "UI/Cursors/Rollover.tga",
								'OnPress', function (self, gamepad)
									SetColonistsSorting(self, "stat_sanity")
								end,
								'Image', "UI/Icons/Sections/stress.tga",
							}),
							PlaceObj('XTemplateWindow', {
								'comment', "stats: comfort",
								'__class', "XTextButton",
								'Margins', box(24, 0, 0, 0),
								'MinWidth', 36,
								'MinHeight', 31,
								'MaxWidth', 36,
								'MaxHeight', 31,
								'MouseCursor', "UI/Cursors/Rollover.tga",
								'OnPress', function (self, gamepad)
									SetColonistsSorting(self, "stat_comfort")
								end,
								'Image', "UI/Icons/Sections/comfort.tga",
							}),
							PlaceObj('XTemplateWindow', {
								'comment', "stats: morale",
								'__class', "XTextButton",
								'Margins', box(24, 0, 0, 0),
								'MinWidth', 36,
								'MinHeight', 31,
								'MaxWidth', 36,
								'MaxHeight', 31,
								'MouseCursor', "UI/Cursors/Rollover.tga",
								'OnPress', function (self, gamepad)
									SetColonistsSorting(self, "stat_morale")
								end,
								'Image', "UI/Icons/Sections/morale.tga",
							}),
							PlaceObj('XTemplateWindow', {
								'comment', "stats: satisfaction",
								'__class', "XTextButton",
								'Margins', box(24, 0, 0, 0),
								'MinWidth', 36,
								'MinHeight', 31,
								'MaxWidth', 36,
								'MaxHeight', 31,
								'MouseCursor', "UI/Cursors/Rollover.tga",
								'OnPress', function (self, gamepad)
									SetColonistsSorting(self, "stat_satisfaction")
								end,
								'Image', "UI/Icons/Sections/satisfaction.tga",
							}),
							PlaceObj('XTemplateWindow', {
								'comment', "traits",
								'__class', "XText",
								'Id', "idTraitsTitle",
								'Margins', box(40, 0, 0, 0),
								'Padding', box(0, 0, 0, 0),
								'HAlign', "left",
								'VAlign', "top",
								'MinWidth', 370,
								'MaxWidth', 370,
								'GridStretchX', false,
								'LayoutMethod', "HList",
								'FoldWhenHidden', true,
								'HandleMouse', false,
								'TextStyle', "OverviewItemSection",
								'ContextUpdateOnOpen', true,
								'OnContextUpdate', function (self, context, ...)
									self:SetVisible(not context.interests)
									XText.OnContextUpdate(self, context, ...)
								end,
								'Translate', true,
								'Text', T(12793, --[[XTemplate TouristOverview Text]] "Traits"),
								'TextVAlign', "center",
							}),
							PlaceObj('XTemplateWindow', {
								'comment', "interests",
								'__class', "XText",
								'Id', "idInterestsTitle",
								'Margins', box(40, 0, 0, 0),
								'Padding', box(0, 0, 0, 0),
								'HAlign', "left",
								'VAlign', "top",
								'MinWidth', 370,
								'MaxWidth', 370,
								'GridStretchX', false,
								'FoldWhenHidden', true,
								'HandleMouse', false,
								'TextStyle', "OverviewItemSection",
								'ContextUpdateOnOpen', true,
								'OnContextUpdate', function (self, context, ...)
									self:SetVisible(context.interests)
									XText.OnContextUpdate(self, context, ...)
								end,
								'Translate', true,
								'Text', T(12794, --[[XTemplate TouristOverview Text]] "Interests"),
								'TextVAlign', "center",
							}),
							}),
						PlaceObj('XTemplateWindow', {
							'__class', "XContentTemplateList",
							'Id', "idList",
							'Margins', box(4, 0, 0, 0),
							'BorderWidth', 0,
							'Padding', box(0, 0, 0, 0),
							'MinWidth', 1200,
							'MaxWidth', 1200,
							'UniformRowHeight', true,
							'Clip', false,
							'Background', RGBA(0, 0, 0, 0),
							'FocusedBackground', RGBA(0, 0, 0, 0),
							'VScroll', "idScroll",
							'ShowPartialItems', false,
							'MouseScroll', true,
							'GamepadInitialSelection', false,
							'OnContextUpdate', function (self, context, ...)
								XContentTemplateList.OnContextUpdate(self, context, ...)
								self:ResolveId("idNoResults"):SetVisible(#self == 0)
							end,
							'RespawnOnDialogMode', false,
						}, {
							PlaceObj('XTemplateMode', {
								'mode', "colonists",
							}, {
								PlaceObj('XTemplateForEach', {
									'comment', "tourists",
									'array', function (parent, context) local colonists = GetRocketPassengers(context); parent:ResolveId("idTitle"):SetTitle(T{12795, "<white><count></white> TOURISTS in <rocket_name>", count = #colonists, rocket_name = Untranslated(context.rocket_name)}) return colonists end,
									'__context', function (parent, context, item, i, n) return item end,
									'run_before', function (parent, context, item, i, n)
										NewXVirtualContent(parent, context, "TouristOverviewRow", 1013, 46)
									end,
								}),
								}),
							}),
						PlaceObj('XTemplateWindow', {
							'__class', "XText",
							'Id', "idNoResults",
							'Dock', "box",
							'HAlign', "center",
							'VAlign', "center",
							'Visible', false,
							'HandleMouse', false,
							'TextStyle', "InGameTitle",
							'Translate', true,
							'Text', T(12796, --[[XTemplate TouristOverview Text]] "No objects matching current filters."),
						}),
						PlaceObj('XTemplateCode', {
							'run', function (self, parent, context)
								local list = parent:ResolveId("idList")
								parent:ResolveId("idNoResults"):SetVisible(#list == 0)
							end,
						}),
						}),
					PlaceObj('XTemplateMode', {
						'mode', "traits",
					}, {
						PlaceObj('XTemplateWindow', {
							'__class', "XContentTemplateList",
							'Id', "idList",
							'BorderWidth', 0,
							'Padding', box(0, 0, 0, 0),
							'LayoutVSpacing', 16,
							'UniformRowHeight', true,
							'Clip', false,
							'Background', RGBA(0, 0, 0, 0),
							'FocusedBackground', RGBA(0, 0, 0, 0),
							'VScroll', "idScroll",
							'ShowPartialItems', false,
							'MouseScroll', true,
						}, {
							PlaceObj('XTemplateTemplate', {
								'__template', "MenuEntrySmall",
								'OnPress', function (self, gamepad)
									local dlg = GetDialog(self)
									dlg.context["trait_" .. dlg.mode_param.trait_group] = nil
									SetBackDialogMode(self)
								end,
								'Text', T(12797, --[[XTemplate TouristOverview Text]] "All Traits"),
							}),
							PlaceObj('XTemplateForEach', {
								'comment', "traits",
								'array', function (parent, context) local dlg = GetDialog(parent); return GetTSortedTraits(dlg.mode_param and dlg.mode_param.trait_group) end,
								'__context', function (parent, context, item, i, n) return item end,
								'run_after', function (child, context, item, i, n)
									child:SetRolloverTitle(item.display_name)
									child:SetRolloverText(item.description)
								end,
							}, {
								PlaceObj('XTemplateTemplate', {
									'__template', "MenuEntrySmall",
									'RolloverTemplate', "Rollover",
									'RolloverAnchor', "left",
									'OnPress', function (self, gamepad)
										local dlg = GetDialog(self)
										dlg.context["trait_" .. dlg.mode_param.trait_group] = self.context
										SetBackDialogMode(self)
									end,
									'Text', T(12798, --[[XTemplate TouristOverview Text]] "<display_name>"),
								}),
								}),
							}),
						PlaceObj('XTemplateCode', {
							'run', function (self, parent, context)
								parent:ResolveId("idScroll"):SetMargins(box(99,0,0,0))
							end,
						}),
						}),
					}),
				}),
			}),
		}),
})

