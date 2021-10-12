DefineClass.ConstructionCost = {
	__parents = { "InitDone" },
	--Construction cost modifiers (per building, per stage, per resource, in percent)
	--These are filled only when there is a change
	construction_cost_mods_percent = false,
	construction_cost_mods_amount = false,
}

function ConstructionCost:Init()
	self.construction_cost_mods_percent = {}
	self.construction_cost_mods_amount = {}
end

function ConstructionCost:CopyMove(other)
	CopyMoveClassFields(other, self,
	{
		"construction_cost_mods_percent",
		"construction_cost_mods_amount"
	})
end

---- Construction cost modifications
GlobalVar("g_StoryBitConstructionCostModifications", {}) --[building_name] = {[resource] = {[amount] = number, [percent] = number}
local function GetStoryBitConstructionCostModsFor(building_name, resource)
	local data = g_StoryBitConstructionCostModifications
	data[building_name] = data[building_name] or {}
	data = data[building_name]
	data[resource] = data[resource] or {}
	return data[resource]
end

function ConstructionCost:ModifyConstructionCost(action, building, resource, percent, amount, id)
	--extract the building name
	local building_name = building
	if type(building) == "table" then
		if IsKindOf(building, "BuildingTemplate") then
			building_name = building.name
		elseif IsValid(building) then
			building_name = building.class
		end
	end
	
	--Cost modifiers are first indexed by building (the object, see above)
	local all_costs_percent = self.construction_cost_mods_percent
	local building_costs_percent = all_costs_percent[building_name] or {}
	all_costs_percent[building_name] = building_costs_percent
	
	local all_costs_amount = self.construction_cost_mods_amount
	local building_costs_amount = all_costs_amount[building_name] or {}
	all_costs_amount[building_name] = building_costs_amount
	
	--finally by the resource for that stage
	if not building_costs_percent[resource] then
		building_costs_percent[resource] = 100
	end
	
	if not building_costs_amount[resource] then
		building_costs_amount[resource] = 0
	end
	
	if id == "StoryBit" then
		if action == "add" or action == "remove" then
			local data = GetStoryBitConstructionCostModsFor(building_name, resource)
			data.amount = (data.amount or 0) + amount * (action == "remove" and -1 or 1)
			data.percent = (data.percent or 0) + percent * (action == "remove" and -1 or 1)
		end
	end
	
	if action == "add" then
		building_costs_percent[resource] = building_costs_percent[resource] + (percent or 0)
		building_costs_amount[resource] = building_costs_amount[resource] + (amount or 0)
	elseif action == "remove" then
		building_costs_percent[resource] = building_costs_percent[resource] - (percent or 0)
		building_costs_amount[resource] = building_costs_amount[resource] - (amount or 0)
	elseif action == "reset" then
		if id == "StoryBit" then
			local data = GetStoryBitConstructionCostModsFor(building_name, resource)
			building_costs_percent[resource] = building_costs_percent[resource] - (data.percent or 0)
			building_costs_amount[resource] = building_costs_amount[resource] - (data.amount or 0)
		else
			building_costs_percent[resource] = 100
			building_costs_amount[resource] = 0
		end
	else
		error("Incorrect cost modification action")
	end

	Msg("ConstructionCostChanged", building_name, resource)
end

function ConstructionCost:GetConstructionCost(building, resource, modifier_obj)
	if building == "" then return 0 end
	
	--extract the building name
	local building_name = building
	if type(building) == "table" then
		if IsKindOf(building, "BuildingTemplate") then
			building_name = building.id
		elseif building:HasMember("class") then
			building_name = building.class
		end
	end
	
	--base value
	local cost_prop_prefix = "construction_cost_"
	local prop_id = cost_prop_prefix..resource
	local value = building[prop_id]
	
	if building:IsKindOf("Passage") then
		local costs = building.elements and #building.elements > 0 and building.elements[#building.elements].construction_cost_at_completion
		if costs and costs[resource] then
			value = costs[resource]
		end
	end
	
	if modifier_obj then --apply lbl modifiers
		value = modifier_obj:ModifyValue(value, prop_id)
	end
	
	--apply global cost modifier
	value = g_Consts:ModifyValue(value, resource.."_cost_modifier")
	
	--apply dome-only cost modifier
	if IsKindOf(g_Classes[building.template_class], "Dome") then
		value = g_Consts:ModifyValue(value, resource.."_dome_cost_modifier")
	end
	
	--apply building-stage-resource modifier
	local building_costs_percent = self.construction_cost_mods_percent[building_name] or empty_table
	local percent_modifier = building_costs_percent[resource] or 100
	local building_costs_amount = self.construction_cost_mods_amount[building_name] or empty_table
	local amount_modifier = building_costs_amount[resource] or 0
	
	local mod = {
		percent = percent_modifier,
		amount = amount_modifier,
	}
	Msg("ModifyConstructionCost", building_name, resource, mod)
	
	return MulDivRound(value, mod.percent, 100) + mod.amount
end
