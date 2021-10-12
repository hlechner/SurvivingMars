DefineClass.Refabable = {
	__parents = { "Object" },

	properties = {
		{ template = true, category = "Refab", name = T(13655, "Can refab?"), id = "can_refab", editor = "bool", default = true, help = "Specify if the object can be converted to a prefab.", no_edit = function() return not IsDlcAvailable("picard") end },
	},

	refab_work_request = false,
}

function Refabable:CanRefab()
	return self.can_refab
end

function Refabable:OnSetRefabbing(is_refabbing)
end
