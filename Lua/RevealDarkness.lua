
DefineClass.BuildingRevealDarkness = {
	__parents = { "Object" },
	properties = {
		{ template = true, category = "Reveal", name = Untranslated("Reveal Range"), id = "reveal_range", editor = "number", default = 145 },
	}
}

function BuildingRevealDarkness:CanReveal()
	return false
end

DefineClass.UnitRevealDarkness = {
	__parents = { "Object" },
	properties = {
		{ template = true, category = "Reveal", name = Untranslated("Reveal Range"), id = "reveal_range", editor = "number", default = 75 },
	},
	revealer_obj = false,
}

function UnitRevealDarkness:CanReveal()
	return false
end