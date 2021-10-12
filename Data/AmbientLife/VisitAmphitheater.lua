-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('AmbientLife', {
	group = "Visit",
	id = "VisitAmphitheater",
	param1 = "unit",
	param2 = "bld",
	PlaceObj('XPrgDefineSlot', {
		'groups', "A",
		'spot_type', "Visitbench",
		'attach', "DecorInt_04",
		'goto_spot', "Pathfind",
		'flags_missing', 1,
		'usable_night', false,
	}),
	PlaceObj('XPrgDefineSlot', {
		'groups', "A",
		'spot_type', "Visitchair1",
		'goto_spot', "Pathfind",
		'flags_missing', 1,
	}),
	PlaceObj('XPrgDefineSlot', {
		'groups', "A",
		'spot_type', "Visitchair2",
		'goto_spot', "Pathfind",
		'flags_missing', 1,
	}),
	PlaceObj('XPrgDefineSlot', {
		'groups', "A",
		'spot_type', "Workshop",
		'goto_spot', "Pathfind",
		'flags_missing', 1,
		'usable_by_child', false,
	}),
	PlaceObj('XPrgVisitSlot', {
		'unit', "unit",
		'bld', "bld",
		'group', "A",
		'group_fallback', "Holder",
	}),
})

