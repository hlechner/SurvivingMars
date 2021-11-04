-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	group = "InGame",
	id = "FilterTable",
	PlaceObj('XTemplateWindow', {
		'Dock', "top",
	}, {
		PlaceObj('XTemplateWindow', {
			'__class', "XFrame",
			'Margins', box(-80, 0, -300, 0),
			'Dock', "box",
			'Image', "UI/CommonNew/pg_action_bar.tga",
			'FrameBox', box(42, 0, 341, 0),
			'TileFrame', true,
			'SqueezeY', false,
			'FlipX', true,
		}),
		PlaceObj('XTemplateWindow', {
			'__class', "XLabel",
			'Id', "idTitle",
			'Padding', box(22, 0, 0, 0),
			'HAlign', "left",
			'VAlign', "center",
			'TextStyle', "MediumHeader",
			'Translate', true,
		}),
		}),
	PlaceObj('XTemplateWindow', {
		'Margins', box(0, 0, 0, 60),
	}, {
		PlaceObj('XTemplateWindow', {
			'__class', "XContentTemplateList",
			'Id', "idList",
			'BorderWidth', 0,
			'LayoutVSpacing', 10,
			'UniformRowHeight', true,
			'Clip', false,
			'Background', RGBA(0, 0, 0, 0),
			'FocusedBackground', RGBA(0, 0, 0, 0),
			'VScroll', "idScroll",
			'ShowPartialItems', false,
			'MouseScroll', true,
			'OnContextUpdate', function (self, context, ...)
				XContentTemplateList.OnContextUpdate(self, context, ...)
				if self.focused_item then
					self.focused_item =  Min(self.focused_item, #self)
					self:DeleteThread("select")
					self:CreateThread("select", function()
						self:SetSelection(self.focused_item)
					end)
				end
			end,
			'RespawnOnContext', false,
		}, {
			PlaceObj('XTemplateMode', {
				'mode', "categories",
			}, {
				PlaceObj('XTemplateCode', {
					'run', function (self, parent, context)
						parent:ResolveId("idTitle"):SetText(T(1117, "CATEGORIES"))
					end,
				}),
				PlaceObj('XTemplateForEach', {
					'comment', "category",
					'array', function (parent, context) return context:GetProperties() end,
					'item_in_context', "prop_meta",
					'run_after', function (child, context, item, i, n)
						local rollover = context:GetCategoryRollover(item)
						if rollover then
							child:SetRolloverTitle(rollover.title)
							child:SetRolloverText(rollover.descr)
							child:SetRolloverHint(rollover.hint)
							child:SetRolloverHintGamepad(rollover.gamepad_hint)
							child:SetId(item.id)
						end
					end,
				}, {
					PlaceObj('XTemplateTemplate', {
						'__template', "PropFilter",
						'RolloverTemplate', "Rollover",
					}, {
						PlaceObj('XTemplateWindow', {
							'__class', "XImage",
							'Id', "idRollover",
							'ZOrder', 0,
							'Margins', box(-60, 0, -60, -6),
							'Dock', "box",
							'Visible', false,
							'Image', "UI/Common/bm_buildings_pad.tga",
							'ImageFit', "stretch",
						}),
						}),
					}),
				}),
			PlaceObj('XTemplateMode', {
				'mode', "items",
			}, {
				PlaceObj('XTemplateCode', {
					'run', function (self, parent, context)
						parent:ResolveId("idTitle"):SetText(GetDialogModeParam(parent).name)
					end,
				}),
				PlaceObj('XTemplateForEach', {
					'comment', "item",
					'array', function (parent, context) return GetDialogModeParam(parent).items(context) end,
					'item_in_context', "prop_meta",
					'run_after', function (child, context, item, i, n)
						local rollover = item.rollover
						if rollover then
							child:SetRolloverTitle(rollover.title)
							child:SetRolloverText(rollover.descr)
							child:SetRolloverHint(rollover.hint)
							child:SetRolloverHintGamepad(rollover.gamepad_hint)
							child:SetId(item.value)
						end
					end,
				}, {
					PlaceObj('XTemplateTemplate', {
						'__template', "PropFilter",
						'RolloverTemplate', "Rollover",
					}, {
						PlaceObj('XTemplateWindow', {
							'__class', "XImage",
							'Id', "idRollover",
							'ZOrder', 0,
							'Margins', box(-60, 0, -60, -6),
							'Dock', "box",
							'Visible', false,
							'Image', "UI/Common/bm_buildings_pad.tga",
							'ImageFit', "stretch",
						}),
						}),
					}),
				}),
			}),
		PlaceObj('XTemplateTemplate', {
			'__template', "Scrollbar",
			'Id', "idScroll",
			'Margins', box(0, 0, 0, 40),
			'Target', "idList",
		}),
		}),
})

