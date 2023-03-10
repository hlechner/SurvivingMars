-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	group = "CCC",
	id = "CommandCenterCategories",
	PlaceObj('XTemplateTemplate', {
		'__template', "NewOverlayDlg",
		'MinWidth', 550,
		'HostInParent', true,
	}, {
		PlaceObj('XTemplateCode', {
			'run', function (self, parent, context)
				local dlg = GetDialog(parent)
				if dlg then
					dlg.OnShortcut = function(dlg, shortcut, source)
						if shortcut == "RightShoulder" and rawget(dlg, "idStats") then
							if not dlg.idStats:IsFocused(true) then
								local list = dlg.idList.idScrollArea
								rawset(dlg, "last_list_focus", list.focused_item)
								dlg.idStats:SetSelection(1)
								return "break"
							end
						elseif shortcut == "LeftShoulder" and rawget(dlg, "idList") then
							if not dlg.idList:IsFocused(true) then
								dlg.idList:SetFocus()
								local list = dlg.idList.idScrollArea
								list:SetSelection(rawget(dlg, "last_list_focus") or 1)
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
			'Title', T(431862968979, --[[XTemplate CommandCenterCategories Title]] "COMMAND CENTER"),
		}),
		PlaceObj('XTemplateWindow', {
			'__context', function (parent, context) return PGColonyNameObjectCreate() end,
			'__class', "XText",
			'Id', "idColonyName",
			'Margins', box(64, -100, 0, 0),
			'HAlign', "left",
			'MaxHeight', 50,
			'MouseCursor', "UI/Cursors/Rollover.tga",
			'TextStyle', "PGLandingPosDetails",
			'ContextUpdateOnOpen', true,
			'Translate', true,
			'Text', T(13791, --[[XTemplate CommandCenterCategories Text]] "<ColonyName>"),
		}, {
			PlaceObj('XTemplateFunc', {
				'name', "OnHyperLink(self, hyperlink, argument, hyperlink_box, pos, button)",
				'func', function (self, hyperlink, argument, hyperlink_box, pos, button)
					local host = GetDialog(self)
					self.context:RenameColony(host)
				end,
			}),
			}),
		PlaceObj('XTemplateWindow', {
			'__class', "XContentTemplateList",
			'Id', "idList",
			'Margins', box(98, 20, 0, 0),
			'BorderWidth', 0,
			'Dock', "left",
			'LayoutMethod', "Box",
			'Clip', false,
			'Background', RGBA(0, 0, 0, 0),
			'FocusedBackground', RGBA(0, 0, 0, 0),
			'ShowPartialItems', false,
		}, {
			PlaceObj('XTemplateTemplate', {
				'__template', "ScrollbarNew",
				'Id', "idScroll",
				'ZOrder', 0,
				'Target', "idScrollArea",
			}),
			PlaceObj('XTemplateWindow', {
				'__context', function (parent, context) return GetCityResourceOverview(UICity) end,
				'__class', "XList",
				'Id', "idScrollArea",
				'BorderWidth', 0,
				'LayoutVSpacing', -8,
				'Background', RGBA(255, 255, 255, 0),
				'FocusedBackground', RGBA(255, 255, 255, 0),
				'VScroll', "idScroll",
			}, {
				PlaceObj('XTemplateForEach', {
					'comment', "categories",
					'array', function (parent, context) return Presets.ColonyControlCenterCategory.Default end,
					'condition', function (parent, context, item, i) return item.filter() end,
					'__context', function (parent, context, item, i, n) return item end,
					'run_after', function (child, context, item, i, n)
						child.idRollover:SetImage("UI/CommonNew/ccc_categories_big.tga")
						child.idRollover:SetMargins(box(-40,-11,0,-11))
					end,
				}, {
					PlaceObj('XTemplateTemplate', {
						'__template', "MenuEntrySmall",
						'Padding', box(35, 12, 0, 12),
						'HAlign', "left",
						'OnPress', function (self, gamepad)
							SetDialogMode(self, self.context.id, self.context)
						end,
						'TextStyle', "ListItem3",
						'Text', T(583679719179, --[[XTemplate CommandCenterCategories Text]] "<display_name>"),
					}),
					}),
				}),
			}),
		PlaceObj('XTemplateWindow', {
			'comment', "resource info",
			'Margins', box(30, 0, 0, 0),
		}, {
			PlaceObj('XTemplateTemplate', {
				'__template', "ScrollbarNew",
				'Id', "idScroll",
				'ZOrder', 0,
				'Target', "idStats",
			}),
			PlaceObj('XTemplateWindow', {
				'__context', function (parent, context) return GetCityResourceOverview(UICity) end,
				'__class', "XList",
				'Id', "idStats",
				'BorderWidth', 0,
				'Padding', box(0, 0, 0, 0),
				'MaxWidth', 1405,
				'LayoutMethod', "HWrap",
				'LayoutHSpacing', -4,
				'LayoutVSpacing', 6,
				'UniformColumnWidth', true,
				'UniformRowHeight', true,
				'Background', RGBA(0, 0, 0, 0),
				'FocusedBackground', RGBA(0, 0, 0, 0),
				'VScroll', "idScroll",
				'LeftThumbScroll', false,
				'GamepadInitialSelection', false,
			}, {
				PlaceObj('XTemplateTemplate', {
					'__template', "CommandCenterStatsBox",
					'Id', "idGeneral",
					'Padding', box(42, 12, 42, 32),
					'HandleKeyboard', false,
					'HandleMouse', false,
					'Title', T(784131592927, --[[XTemplate CommandCenterCategories Title]] "GENERAL"),
				}, {
					PlaceObj('XTemplateTemplate', {
						'comment', "funding",
						'__template', "CommandCenterStatsRow",
						'Name', T(799726720261, --[[XTemplate CommandCenterCategories Name]] "Funding"),
						'Value', T(724590769700, --[[XTemplate CommandCenterCategories Value]] "<funding(Funding)>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "available rockets",
						'__template', "CommandCenterStatsRow",
						'Name', T(434472115528, --[[XTemplate CommandCenterCategories Name]] "Available Rockets"),
						'Value', T(631332357625, --[[XTemplate CommandCenterCategories Value]] "<AvailableRockets>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "available pods",
						'__template', "CommandCenterStatsRow",
						'Name', T(602355606532, --[[XTemplate CommandCenterCategories Name]] "Available Supply Pods"),
						'Value', T(226146906598, --[[XTemplate CommandCenterCategories Value]] "<AvailablePods>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "research per sol",
						'__template', "CommandCenterStatsRow",
						'Name', T(192510649062, --[[XTemplate CommandCenterCategories Name]] "Research per Sol"),
						'Value', T(981138236987, --[[XTemplate CommandCenterCategories Value]] "<research(EstimatedRP)>"),
					}),
					PlaceObj('XTemplateFunc', {
						'name', "OnSetFocus",
						'func', function (self, ...)
							local dlg = GetDialog(self)
							dlg.idStats:ScrollIntoView(self)
							return XToggleButton.OnSetFocus(self,...)
						end,
					}),
					PlaceObj('XTemplateFunc', {
						'name', "SetSelected(self, selected)",
						'func', function (self, selected)
							self:SetFocus(selected)
						end,
					}),
					}),
				PlaceObj('XTemplateTemplate', {
					'__template', "CommandCenterStatsBox",
					'Id', "idGridResources",
					'Padding', box(42, 12, 42, 32),
					'HandleKeyboard', false,
					'HandleMouse', false,
					'Title', T(380120250163, --[[XTemplate CommandCenterCategories Title]] "GRID RESOURCES"),
				}, {
					PlaceObj('XTemplateTemplate', {
						'comment', "power",
						'__template', "CommandCenterStatsRow",
						'Name', T(828786133480, --[[XTemplate CommandCenterCategories Name]] "Power"),
						'Value', T(881442954094, --[[XTemplate CommandCenterCategories Value]] "<power(TotalStoredPower)>"),
					}, {
						PlaceObj('XTemplateWindow', {
							'comment', "delta",
							'__class', "XText",
							'Dock', "right",
							'MinWidth', 100,
							'MaxWidth', 100,
							'TextStyle', "CCCStatsValue",
							'ContextUpdateOnOpen', true,
							'OnContextUpdate', function (self, context, ...)
								local delta = context:GetPowerNumber()
								if delta < 0 then
									self:SetText(T(11620, "<red><resource(PowerNumber)></red>"))
								elseif delta > 0 then
									self:SetText(T(11621, "+<resource(PowerNumber)>"))
								else
									self:SetText(T(577741044359, "<resource(PowerNumber)>")) --zero
								end
							end,
							'Translate', true,
							'Text', T(577741044359, --[[XTemplate CommandCenterCategories Text]] "<resource(PowerNumber)>"),
							'TextHAlign', "right",
						}),
						}),
					PlaceObj('XTemplateTemplate', {
						'comment', "oxygen",
						'__template', "CommandCenterStatsRow",
						'Name', T(407391407041, --[[XTemplate CommandCenterCategories Name]] "Oxygen"),
						'Value', T(474477027302, --[[XTemplate CommandCenterCategories Value]] "<air(TotalStoredAir)>"),
					}, {
						PlaceObj('XTemplateWindow', {
							'comment', "delta",
							'__class', "XText",
							'Dock', "right",
							'MinWidth', 100,
							'MaxWidth', 100,
							'TextStyle', "CCCStatsValue",
							'ContextUpdateOnOpen', true,
							'OnContextUpdate', function (self, context, ...)
								local delta = context:GetAirNumber()
								if delta < 0 then
									self:SetText(T(11622, "<red><resource(AirNumber)></red>"))
								elseif delta > 0 then
									self:SetText(T(11623, "+<resource(AirNumber)>"))
								else
									self:SetText(T(126480315436, "<resource(AirNumber)>")) --zero
								end
							end,
							'Translate', true,
							'Text', T(126480315436, --[[XTemplate CommandCenterCategories Text]] "<resource(AirNumber)>"),
							'TextHAlign', "right",
						}),
						}),
					PlaceObj('XTemplateTemplate', {
						'comment', "water",
						'__template', "CommandCenterStatsRow",
						'Name', T(664501538579, --[[XTemplate CommandCenterCategories Name]] "Water"),
						'Value', T(102228902597, --[[XTemplate CommandCenterCategories Value]] "<water(TotalStoredWater)>"),
					}, {
						PlaceObj('XTemplateWindow', {
							'comment', "delta",
							'__class', "XText",
							'Dock', "right",
							'MinWidth', 100,
							'MaxWidth', 100,
							'TextStyle', "CCCStatsValue",
							'ContextUpdateOnOpen', true,
							'OnContextUpdate', function (self, context, ...)
								local delta = context:GetWaterNumber()
								if delta < 0 then
									self:SetText(T(11624, "<red><resource(WaterNumber)></red>"))
								elseif delta > 0 then
									self:SetText(T(11625, "+<resource(WaterNumber)>"))
								else
									self:SetText(T(673482905848, "<resource(WaterNumber)>")) --zero
								end
							end,
							'Translate', true,
							'Text', T(673482905848, --[[XTemplate CommandCenterCategories Text]] "<resource(WaterNumber)>"),
							'TextHAlign', "right",
						}),
						}),
					PlaceObj('XTemplateFunc', {
						'name', "OnSetFocus",
						'func', function (self, ...)
							local dlg = GetDialog(self)
							dlg.idStats:ScrollIntoView(self)
							return XToggleButton.OnSetFocus(self,...)
						end,
					}),
					PlaceObj('XTemplateFunc', {
						'name', "SetSelected(self, selected)",
						'func', function (self, selected)
							self:SetFocus(selected)
						end,
					}),
					}),
				PlaceObj('XTemplateTemplate', {
					'__template', "CommandCenterStatsBox",
					'Id', "idBuildings",
					'Margins', box(0, -12, 0, 0),
					'Padding', box(42, 12, 42, 32),
					'HandleKeyboard', false,
					'HandleMouse', false,
					'Title', T(748828817759, --[[XTemplate CommandCenterCategories Title]] "BUILDINGS"),
				}, {
					PlaceObj('XTemplateTemplate', {
						'comment', "total",
						'__template', "CommandCenterStatsRow",
						'Name', T(392865833841, --[[XTemplate CommandCenterCategories Name]] "Total Buildings"),
						'Value', T(875372934535, --[[XTemplate CommandCenterCategories Value]] "<BuildingsCount>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "domes",
						'__template', "CommandCenterStatsRow",
						'Name', T(257603859990, --[[XTemplate CommandCenterCategories Name]] "Domes"),
						'Value', T(364672378569, --[[XTemplate CommandCenterCategories Value]] "<DomesCount>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "power producers",
						'__template', "CommandCenterStatsRow",
						'Name', T(493891577302, --[[XTemplate CommandCenterCategories Name]] "Power Producers"),
						'Value', T(651515305382, --[[XTemplate CommandCenterCategories Value]] "<PowerProducersCount>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "production",
						'__template', "CommandCenterStatsRow",
						'Name', T(867622188086, --[[XTemplate CommandCenterCategories Name]] "Production"),
						'Value', T(320260921198, --[[XTemplate CommandCenterCategories Value]] "<ProductionBuildingsCount>"),
					}),
					PlaceObj('XTemplateFunc', {
						'name', "OnSetFocus",
						'func', function (self, ...)
							local dlg = GetDialog(self)
							dlg.idStats:ScrollIntoView(self)
							return XToggleButton.OnSetFocus(self,...)
						end,
					}),
					PlaceObj('XTemplateFunc', {
						'name', "SetSelected(self, selected)",
						'func', function (self, selected)
							self:SetFocus(selected)
						end,
					}),
					}),
				PlaceObj('XTemplateTemplate', {
					'__template', "CommandCenterStatsBox",
					'Id', "idBasicResources",
					'Margins', box(0, -12, 0, 0),
					'Padding', box(42, 12, 42, 32),
					'HandleKeyboard', false,
					'HandleMouse', false,
					'Title', T(733241404556, --[[XTemplate CommandCenterCategories Title]] "BASIC RESOURCES"),
				}, {
					PlaceObj('XTemplateTemplate', {
						'comment', "metals",
						'__template', "CommandCenterStatsRow",
						'Name', T(713516352322, --[[XTemplate CommandCenterCategories Name]] "Metals"),
						'Value', T(813997644883, --[[XTemplate CommandCenterCategories Value]] "<metals(AvailableMetals)>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "concrete",
						'__template', "CommandCenterStatsRow",
						'Name', T(664110305028, --[[XTemplate CommandCenterCategories Name]] "Concrete"),
						'Value', T(814411638574, --[[XTemplate CommandCenterCategories Value]] "<concrete(AvailableConcrete)>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "food",
						'__template', "CommandCenterStatsRow",
						'Name', T(281038741589, --[[XTemplate CommandCenterCategories Name]] "Food"),
						'Value', T(313049198339, --[[XTemplate CommandCenterCategories Value]] "<food(AvailableFood)>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "rare metals",
						'__template', "CommandCenterStatsRow",
						'Name', T(933465905918, --[[XTemplate CommandCenterCategories Name]] "Rare Metals"),
						'Value', T(649593042933, --[[XTemplate CommandCenterCategories Value]] "<preciousmetals(AvailablePreciousMetals)>"),
					}),
					PlaceObj('XTemplateFunc', {
						'name', "OnSetFocus",
						'func', function (self, ...)
							local dlg = GetDialog(self)
							dlg.idStats:ScrollIntoView(self)
							return XToggleButton.OnSetFocus(self,...)
						end,
					}),
					PlaceObj('XTemplateFunc', {
						'name', "SetSelected(self, selected)",
						'func', function (self, selected)
							self:SetFocus(selected)
						end,
					}),
					}),
				PlaceObj('XTemplateTemplate', {
					'__template', "CommandCenterStatsBox",
					'Id', "idAdvancedResources",
					'Margins', box(0, -12, 0, 0),
					'Padding', box(42, 12, 42, 32),
					'HandleKeyboard', false,
					'HandleMouse', false,
					'Title', T(252946080460, --[[XTemplate CommandCenterCategories Title]] "ADVANCED RESOURCES"),
				}, {
					PlaceObj('XTemplateTemplate', {
						'comment', "polymers",
						'__template', "CommandCenterStatsRow",
						'Name', T(153085345860, --[[XTemplate CommandCenterCategories Name]] "Polymers"),
						'Value', T(190719877337, --[[XTemplate CommandCenterCategories Value]] "<polymers(AvailablePolymers)>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "machine parts",
						'__template', "CommandCenterStatsRow",
						'Name', T(950147653122, --[[XTemplate CommandCenterCategories Name]] "Machine Parts"),
						'Value', T(762617745142, --[[XTemplate CommandCenterCategories Value]] "<machineparts(AvailableMachineParts)>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "fuel",
						'__template', "CommandCenterStatsRow",
						'Name', T(600161614581, --[[XTemplate CommandCenterCategories Name]] "Fuel"),
						'Value', T(826228979160, --[[XTemplate CommandCenterCategories Value]] "<fuel(AvailableFuel)>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "electronics",
						'__template', "CommandCenterStatsRow",
						'Name', T(710449628491, --[[XTemplate CommandCenterCategories Name]] "Electronics"),
						'Value', T(404473173475, --[[XTemplate CommandCenterCategories Value]] "<electronics(AvailableElectronics)>"),
					}),
					PlaceObj('XTemplateFunc', {
						'name', "OnSetFocus",
						'func', function (self, ...)
							local dlg = GetDialog(self)
							dlg.idStats:ScrollIntoView(self)
							return XToggleButton.OnSetFocus(self,...)
						end,
					}),
					PlaceObj('XTemplateFunc', {
						'name', "SetSelected(self, selected)",
						'func', function (self, selected)
							self:SetFocus(selected)
						end,
					}),
					}),
				PlaceObj('XTemplateTemplate', {
					'__dlc', "armstrong",
					'__condition', function (parent, context) return not g_NoTerraforming end,
					'__template', "CommandCenterStatsBox",
					'Id', "idTerraforming",
					'Margins', box(0, -12, 0, 0),
					'Padding', box(42, 12, 42, 32),
					'HandleKeyboard', false,
					'HandleMouse', false,
					'Title', T(849526618919, --[[XTemplate CommandCenterCategories Title]] "TERRAFORMING PROGRESS"),
				}, {
					PlaceObj('XTemplateTemplate', {
						'comment', "atmosphere",
						'__dlc', "armstrong",
						'__template', "CommandCenterStatsRow",
						'Name', T(516490202538, --[[XTemplate CommandCenterCategories Name]] "Atmosphere"),
						'Value', T(972097632831, --[[XTemplate CommandCenterCategories Value]] "<Atmosphere>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "temperature",
						'__template', "CommandCenterStatsRow",
						'Name', T(618229231873, --[[XTemplate CommandCenterCategories Name]] "Temperature"),
						'Value', T(138871236663, --[[XTemplate CommandCenterCategories Value]] "<Temperature>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "water",
						'__template', "CommandCenterStatsRow",
						'Name', T(969321325521, --[[XTemplate CommandCenterCategories Name]] "Water"),
						'Value', T(999182219498, --[[XTemplate CommandCenterCategories Value]] "<Water>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "vegetation",
						'__template', "CommandCenterStatsRow",
						'Name', T(370878295349, --[[XTemplate CommandCenterCategories Name]] "Vegetation"),
						'Value', T(735974971764, --[[XTemplate CommandCenterCategories Value]] "<Vegetation>"),
					}),
					PlaceObj('XTemplateFunc', {
						'name', "OnSetFocus",
						'func', function (self, ...)
							local dlg = GetDialog(self)
							dlg.idStats:ScrollIntoView(self)
							return XToggleButton.OnSetFocus(self,...)
						end,
					}),
					PlaceObj('XTemplateFunc', {
						'name', "SetSelected(self, selected)",
						'func', function (self, selected)
							self:SetFocus(selected)
						end,
					}),
					}),
				PlaceObj('XTemplateTemplate', {
					'__template', "CommandCenterStatsBox",
					'Id', "idOtherResources",
					'Margins', box(0, -12, 0, 0),
					'Padding', box(42, 12, 42, 32),
					'HandleKeyboard', false,
					'HandleMouse', false,
					'Title', T(804810025952, --[[XTemplate CommandCenterCategories Title]] "OTHER RESOURCES"),
				}, {
					PlaceObj('XTemplateTemplate', {
						'comment', "seeds",
						'__dlc', "armstrong",
						'__condition', function (parent, context) return UIColony:IsTechResearched("MartianVegetation") end,
						'__template', "CommandCenterStatsRow",
						'Name', T(971221728791, --[[XTemplate CommandCenterCategories Name]] "Seeds"),
						'Value', T(935626806595, --[[XTemplate CommandCenterCategories Value]] "<seeds(AvailableSeeds)>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "exotic minerals",
						'__dlc', "picard",
						'__template', "CommandCenterStatsRow",
						'Name', T(12779, --[[XTemplate CommandCenterCategories Name]] "Exotic Minerals"),
						'Value', T(12780, --[[XTemplate CommandCenterCategories Value]] "<preciousminerals(AvailablePreciousMinerals)>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "waste rock",
						'__template', "CommandCenterStatsRow",
						'Name', T(197579162861, --[[XTemplate CommandCenterCategories Name]] "Waste Rock"),
						'Value', T(690528976873, --[[XTemplate CommandCenterCategories Value]] "<wasterock(AvailableWasteRock)>"),
					}),
					PlaceObj('XTemplateFunc', {
						'name', "OnSetFocus",
						'func', function (self, ...)
							local dlg = GetDialog(self)
							dlg.idStats:ScrollIntoView(self)
							return XToggleButton.OnSetFocus(self,...)
						end,
					}),
					PlaceObj('XTemplateFunc', {
						'name', "SetSelected(self, selected)",
						'func', function (self, selected)
							self:SetFocus(selected)
						end,
					}),
					}),
				PlaceObj('XTemplateTemplate', {
					'__template', "CommandCenterStatsBox",
					'Id', "idColonists",
					'Margins', box(0, -12, 0, 0),
					'Padding', box(42, 12, 42, 32),
					'HandleKeyboard', false,
					'HandleMouse', false,
					'Title', T(885202472049, --[[XTemplate CommandCenterCategories Title]] "COLONISTS"),
				}, {
					PlaceObj('XTemplateTemplate', {
						'comment', "population",
						'__template', "CommandCenterStatsRow",
						'Name', T(259581680578, --[[XTemplate CommandCenterCategories Name]] "Total Population"),
						'Value', T(239457667632, --[[XTemplate CommandCenterCategories Value]] "<ColonistCount>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "homeless",
						'__template', "CommandCenterStatsRow",
						'Name', T(999475003786, --[[XTemplate CommandCenterCategories Name]] "Homeless"),
						'Value', T(721463728266, --[[XTemplate CommandCenterCategories Value]] "<HomelessColonists>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "unemployed",
						'__template', "CommandCenterStatsRow",
						'Name', T(156613984420, --[[XTemplate CommandCenterCategories Name]] "Unemployed"),
						'Value', T(481786352063, --[[XTemplate CommandCenterCategories Value]] "<UnemployedColonists>"),
					}),
					PlaceObj('XTemplateTemplate', {
						'comment', "problematic",
						'__template', "CommandCenterStatsRow",
						'Name', T(730955511769, --[[XTemplate CommandCenterCategories Name]] "Problematic"),
						'Value', T(149395259777, --[[XTemplate CommandCenterCategories Value]] "<DetrimentalColonistsCount>"),
					}),
					PlaceObj('XTemplateFunc', {
						'name', "OnSetFocus",
						'func', function (self, ...)
							local dlg = GetDialog(self)
							dlg.idStats:ScrollIntoView(self)
							return XToggleButton.OnSetFocus(self,...)
						end,
					}),
					PlaceObj('XTemplateFunc', {
						'name', "SetSelected(self, selected)",
						'func', function (self, selected)
							self:SetFocus(selected)
						end,
					}),
					}),
				}),
			}),
		PlaceObj('XTemplateAction', {
			'ActionId', "close",
			'ActionName', T(4523, --[[XTemplate CommandCenterCategories ActionName]] "CLOSE"),
			'ActionToolbar', "ActionBar",
			'ActionShortcut', "Escape",
			'ActionGamepad', "ButtonB",
			'OnAction', function (self, host, source)
				CloseCommandCenter()
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "rename",
			'ActionSortKey', "2",
			'ActionName', T(13792, --[[XTemplate CommandCenterCategories ActionName]] "RENAME COLONY"),
			'ActionToolbar', "ActionBar",
			'ActionGamepad', "RightThumbClick",
			'OnAction', function (self, host, source)
				g_ColonyNameObj:RenameColony(host.idContent.idOverlayDlg)
			end,
		}),
		}),
})

