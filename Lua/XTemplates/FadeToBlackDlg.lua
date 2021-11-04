-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	__is_kind_of = "XDialog",
	group = "InGame",
	id = "FadeToBlackDlg",
	PlaceObj('XTemplateWindow', {
		'__context', function (parent, context) return context end,
		'__class', "XDialog",
		'HandleMouse', true,
	}, {
		PlaceObj('XTemplateFunc', {
			'name', "OnDelete",
			'func', function (self, ...)
				local window = self.desktop.idFade
				if window.window_state ~= "destroying" then
					window:delete()
				end
			end,
		}),
		PlaceObj('XTemplateWindow', {
			'__parent', function (parent, context) return terminal.desktop end,
			'Id', "idFade",
			'ZOrder', 100000000,
			'Dock', "box",
			'Visible', false,
			'Background', RGBA(0, 0, 0, 255),
			'FadeInTime', 450,
			'FadeOutTime', 450,
		}),
		}),
})

