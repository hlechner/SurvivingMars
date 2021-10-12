-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	__is_kind_of = "XLayer",
	group = "Layers",
	id = "ScreenBlur",
	PlaceObj('XTemplateWindow', {
		'__class', "XLayer",
		'ZOrder', 0,
	}, {
		PlaceObj('XTemplateFunc', {
			'name', "Open",
			'func', function (self, ...)
				XLayer.Open(self, ...)
				table.change(hr, "BackgroundBlur", {
					EnablePostProcScreenBlur = 96,
					EnablePostProcVignette = 1,
				})
				SetSceneParam(1, "Vignette", 160, 0, 0)
				SetSceneParam(1, "VignetteColor", RGB(0,0,0), 0, 0)
				HideExploration_Queue(UICity)
			end,
		}),
		PlaceObj('XTemplateFunc', {
			'name', "Close",
			'func', function (self, ...)
				XLayer.Close(self, ...)
				table.restore(hr, "BackgroundBlur")
				local current_lm = GetCurrentLightModel(1)
				SetSceneParam(1, "Vignette", current_lm.vignette, 0, 0)
				SetSceneParam(1, "VignetteColor", current_lm.vignette_color, 0, 0)
				ShowExploration_Queue(UICity, true)
			end,
		}),
		PlaceObj('XTemplateWindow', {
			'__class', "XImage",
			'Id', "idImage",
			'Dock', "box",
			'Image', "UI/CommonNew/menu_background.tga",
			'ImageFit', "stretch",
			'ImageColor', RGBA(255, 255, 255, 96),
		}),
		}),
})

