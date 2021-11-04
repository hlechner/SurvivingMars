-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	group = "InGame",
	id = "DomeTraits",
	PlaceObj('XTemplateWindow', {
		'__context', function (parent, context) return TraitsObjectCreateAndLoad(context) end,
		'__class', "XDialog",
		'InitialMode', "categories",
		'InternalModes', "categories,items",
	}, {
		PlaceObj('XTemplateFunc', {
			'name', "Open",
			'func', function (self, ...)
				ViewAndSelectDome(self.context.dome)
				self.context:SetDialog(self)
				XDialog.Open(self, ...)
			end,
		}),
		PlaceObj('XTemplateFunc', {
			'name', "Close",
			'func', function (self, ...)
				if DomeTraitsCameraParams then
					SetCamera(table.unpack(DomeTraitsCameraParams))
					DomeTraitsCameraParams = false
				end
				XDialog.Close(self, ...)
			end,
		}),
		PlaceObj('XTemplateWindow', {
			'HAlign', "right",
		}, {
			PlaceObj('XTemplateLayer', {
				'layer', "XHideInGameInterfaceLayer",
			}),
			PlaceObj('XTemplateLayer', {
				'layer', "XPauseLayer",
			}),
			PlaceObj('XTemplateLayer', {
				'layer', "XCameraLockLayer",
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XFrame",
				'Id', "idFrame",
				'IdNode', false,
				'Padding', box(80, 30, 80, 50),
				'HAlign', "right",
				'MinWidth', 550,
				'LayoutMethod', "VList",
				'HandleMouse', true,
				'Image', "UI/Common/menu_pad_1.tga",
				'FrameBox', box(86, 0, 0, 0),
				'TileFrame', true,
			}, {
				PlaceObj('XTemplateFunc', {
					'name', "Open",
					'func', function (self, ...)
						XFrame.Open(self, ...)
						local pad = self:GetPadding()
						local margin = GetSafeMargins(pad)
						self:SetPadding(box(pad:minx(), margin:miny(), margin:maxx(), margin:maxy()))
					end,
				}),
				PlaceObj('XTemplateWindow', {
					'__class', "XText",
					'Dock', "top",
					'HAlign', "right",
					'TextStyle', "DomeName",
					'Translate', true,
					'Text', T(347194033198, --[[XTemplate DomeTraits Text]] "<DomeName>"),
					'WordWrap', false,
					'Shorten', true,
					'TextHAlign', "right",
				}),
				PlaceObj('XTemplateWindow', {
					'__class', "XText",
					'Dock', "top",
					'HAlign', "right",
					'TextStyle', "PGLandingPosDetails",
					'Translate', true,
					'Text', T(837650465667, --[[XTemplate DomeTraits Text]] "<DomeSubtitle>"),
					'TextHAlign', "right",
				}),
				PlaceObj('XTemplateTemplate', {
					'__template', "FilterTable",
				}),
				}),
			PlaceObj('XTemplateWindow', {
				'Id', "idActionBar",
				'Margins', box(0, 0, 115, 25),
				'VAlign', "bottom",
			}, {
				PlaceObj('XTemplateFunc', {
					'name', "Open",
					'func', function (self, ...)
						XWindow.Open(self, ...)
						self:SetMargins(GetSafeMargins(self:GetMargins()))
					end,
				}),
				PlaceObj('XTemplateWindow', {
					'__class', "XFrame",
					'Margins', box(-115, 0, -341, 0),
					'VAlign', "bottom",
					'Image', "UI/CommonNew/pg_action_bar.tga",
					'FrameBox', box(42, 0, 341, 0),
					'TileFrame', true,
					'SqueezeY', false,
					'FlipX', true,
				}),
				PlaceObj('XTemplateWindow', {
					'__class', "XToolBar",
					'Id', "idToolbar",
					'HAlign', "right",
					'VAlign', "center",
					'LayoutHSpacing', 60,
					'Background', RGBA(0, 0, 0, 0),
					'Toolbar', "ActionBar",
					'Show', "text",
					'ButtonTemplate', "InGameMenuEntry",
				}),
				}),
			PlaceObj('XTemplateAction', {
				'ActionId', "prev",
				'ActionName', T(5446, --[[XTemplate DomeTraits ActionName]] "PREVIOUS DOME"),
				'ActionToolbar', "ActionBar",
				'ActionGamepad', "LeftTrigger",
				'OnAction', function (self, host, source)
					host:CreateThread("close_dialog", function()
						local prop_meta = GetDialogModeParam(host)
						local category = prop_meta and prop_meta.id or nil
						host.context:WaitAskToApplyTraitsFilter()
						CycleFilterTraits(host.context, -1, category)
					end)
				end,
				'__condition', function (parent, context) return UICity and #(UICity.labels.Community or "") > 1 end,
			}),
			PlaceObj('XTemplateAction', {
				'ActionId', "next",
				'ActionName', T(5445, --[[XTemplate DomeTraits ActionName]] "NEXT DOME"),
				'ActionToolbar', "ActionBar",
				'ActionGamepad', "RightTrigger",
				'OnAction', function (self, host, source)
					host:CreateThread("close_dialog", function()
						local prop_meta = GetDialogModeParam(host)
						local category = prop_meta and prop_meta.id or nil
						host.context:WaitAskToApplyTraitsFilter()
						CycleFilterTraits(host.context, 1, category)
					end)
				end,
				'__condition', function (parent, context) return UICity and #(UICity.labels.Community or "") > 1 end,
			}),
			PlaceObj('XTemplateAction', {
				'ActionId', "clear",
				'ActionName', T(5448, --[[XTemplate DomeTraits ActionName]] "CLEAR"),
				'ActionToolbar', "ActionBar",
				'ActionGamepad', "ButtonY",
				'ActionState', function (self, host)
					local prop_meta = GetDialogModeParam(host)
					local category = prop_meta and prop_meta.id or nil
					if not host.context:CanClearFilter(category) then
						return "disabled"
					end
				end,
				'OnAction', function (self, host, source)
					local prop_meta = GetDialogModeParam(host)
					host.context:ClearTraits(prop_meta)
				end,
			}),
			PlaceObj('XTemplateAction', {
				'ActionId', "apply",
				'ActionName', T(5447, --[[XTemplate DomeTraits ActionName]] "APPLY"),
				'ActionToolbar', "ActionBar",
				'ActionGamepad', "ButtonA",
				'ActionState', function (self, host)
					local prop_meta = GetDialogModeParam(host)
					local category = prop_meta and prop_meta.id or nil
					if not host.context:CanApplyFilter(category) then
						return "disabled"
					end
				end,
				'OnAction', function (self, host, source)
					local param = GetDialogModeParam(host)
					host.context:ApplyDomeFilter(param and param.id)
				end,
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XContentTemplate",
				'RespawnOnContext', false,
			}, {
				PlaceObj('XTemplateMode', {
					'mode', "categories",
				}, {
					PlaceObj('XTemplateAction', {
						'ActionId', "close",
						'ActionName', T(4523, --[[XTemplate DomeTraits ActionName]] "CLOSE"),
						'ActionToolbar', "ActionBar",
						'ActionShortcut', "Escape",
						'ActionGamepad', "ButtonB",
						'OnAction', function (self, host, source)
							host:CreateThread("close_dialog", function()
								host.context:WaitAskToApplyTraitsFilter()
								host:Close()
							end)
						end,
					}),
					}),
				PlaceObj('XTemplateMode', {
					'mode', "items",
				}, {
					PlaceObj('XTemplateAction', {
						'ActionId', "back",
						'ActionName', T(4254, --[[XTemplate DomeTraits ActionName]] "BACK"),
						'ActionToolbar', "ActionBar",
						'ActionShortcut', "Escape",
						'ActionGamepad', "ButtonB",
						'OnActionEffect', "back",
					}),
					}),
				}),
			}),
		}),
})

