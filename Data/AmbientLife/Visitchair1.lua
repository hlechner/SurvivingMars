-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('AmbientLife', {
	group = "VisitSpot",
	id = "Visitchair1",
	param1 = "unit",
	param2 = "bld",
	param3 = "obj",
	param4 = "spot",
	param5 = "slot_data",
	param6 = "slot",
	param7 = "slotname",
	PlaceObj('XPrgPlayAnim', {
		'obj', "unit",
		'anim', "sitChair1Start",
	}),
	PlaceObj('XPrgHasVisitTime', {
		'form', "while-do",
	}, {
		PlaceObj('XPrgPlayAnim', {
			'obj', "unit",
			'anim', "sitChair1Idle",
			'blending', false,
		}),
		}),
	PlaceObj('XPrgPlayAnim', {
		'obj', "unit",
		'anim', "sitChair1End",
		'blending_next', false,
	}),
	PlaceObj('XPrgRotateObj', {
		'obj', "unit",
		'angle', 10800,
	}),
	PlaceObj('XPrgPlayAnim', {
		'obj', "unit",
		'anim', "idle",
		'loops', "0",
		'time', "0",
		'blending', false,
	}),
})

