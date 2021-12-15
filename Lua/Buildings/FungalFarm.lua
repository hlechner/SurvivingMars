DefineClass.FungalFarm = {
	__parents = { "ResourceProducer", "ElectricityConsumer", "LifeSupportConsumer" ,"Workplace"},
	
	resource_produced1 = "Food",
	stockpile_spots1 = {"Resourcepile"},
}

function FungalFarm.OnCalcProduction_Food(producer, amount_to_produce)
	return MulDivRound(producer.parent.performance, amount_to_produce, 100)
end

function FungalFarm.Produce_Food(producer, amount_produced)
	amount_produced = SingleResourceProducer.Produce(producer, amount_produced)
	if producer.resource_produced == "Food" then
		local farm = producer.parent
		Msg("FoodProduced", farm, amount_produced)
	end
	return amount_produced
end

function FungalFarm:GameInit()
	self:TransformToEnvironment(GetEnvironment(self))
end

local underground_fungal_farm_production = 14 * const.ResourceScale
local function GetProductionIn(environment)
	return environment == "Surface" and BuildingTemplates.FungalFarm.production_per_day1 or underground_fungal_farm_production
end

function FungalFarm:TransformToEnvironment(environment)
	local production = GetProductionIn(environment)
	self:SetBase("production_per_day1", production)
end

function SavegameFixups.ImprovedUndergroundFungalFarms2()
	MapsForEach("map", "FungalFarm", function(farm)
		local production = GetProductionIn(GetEnvironment(farm))
		-- Some FungalFarms do not produce the correct amount
		-- But their production_per_day1 is set correctly,
		-- so we set it twice to make sure it is set correctly
		farm:SetBase("production_per_day1", production - 1)
		farm:SetBase("production_per_day1", production)
	end)
end

function FungalFarm:GetBuildMenuProductionText(production_props)
	local amount = GetProductionIn(ActiveMapData.Environment)
	return T(3967, "Base production: ") .. FormatResource(empty_table, amount, "Food")
end