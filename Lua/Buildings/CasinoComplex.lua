DefineClass.CasinoComplex = {
	__parents = { "ElectricityConsumer", "ServiceWorkplace" },
}
function CasinoComplex:Service(unit, duration)
	if unit.traits.Gambler then
		if self:Random(100) < 50 then
			local trait = TraitPresets.Gambler
			unit:ChangeSanity(-trait.param * const.Scale.Stat, trait.id)
		end
	end
	ServiceWorkplace.Service(self, unit, duration)
end

function SavegameFixups.UpdateCasinoComplexTemplateName()
	local template_name = "CasinoComplex"
	MapsForEach("map", template_name, function(bld)
		bld.encyclopedia_id = template_name
		bld.fx_actor_class = template_name
		bld.template_name = template_name
	end)
end