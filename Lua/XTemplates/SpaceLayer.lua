-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	__is_kind_of = "XCameraLockLayer",
	group = "Layers",
	id = "SpaceLayer",
	PlaceObj('XTemplateWindow', {
		'__class', "XCameraLockLayer",
	}, {
		PlaceObj('XTemplateFunc', {
			'name', "Open",
			'func', function (self, ...)
				XCameraLockLayer.Open(self, ...)
				SetPlanetCamera("PlanetNone")
			end,
		}),
		PlaceObj('XTemplateFunc', {
			'name', "Close",
			'func', function (self, ...)
				ClosePlanetCamera("PlanetNone")
				XLayer.Close(self, ...)
			end,
		}),
		}),
})

