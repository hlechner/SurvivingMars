-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	group = "Infopanel Sections",
	id = "sectionWaterProduction",
	PlaceObj('XTemplateTemplate', {
		'__context_of_kind', "WaterProducer",
		'__condition', function (parent, context)
			if not context then return end
			return context:ShowUISectionLifeSupportProduction()
		end,
		'__template', "InfopanelSection",
		'RolloverText', T(502733614779, --[[XTemplate sectionWaterProduction RolloverText]] "<UISectionWaterProductionRollover>"),
		'Title', T(80, --[[XTemplate sectionWaterProduction Title]] "Production"),
		'Icon', "UI/Icons/Sections/Water_2.tga",
	}, {
		PlaceObj('XTemplateTemplate', {
			'__template', "InfopanelText",
			'Text', T(840359936837, --[[XTemplate sectionWaterProduction Text]] "<WaterProductionText>"),
		}),
		PlaceObj('XTemplateTemplate', {
			'__dlc', "armstrong",
			'__context_of_kind', "MoistureVaporator",
			'__condition', function (parent, context) return not g_NoTerraforming end,
			'__template', "InfopanelText",
			'Text', T(12022, --[[XTemplate sectionWaterProduction Text]] "Terraforming boost<right><modifier_percent('water_production', 'TP Boost Water')>"),
		}),
		PlaceObj('XTemplateTemplate', {
			'__condition', function (parent, context) return context:IsKindOf("ResourceProducer") and context.wasterock_producer end,
			'__template', "InfopanelText",
			'Text', T(474, --[[XTemplate sectionWaterProduction Text]] "Stored Waste Rock<right><wasterock(GetWasterockAmountStored,wasterock_max_storage)>"),
		}),
		}),
})

