DefineClass.Workforce = {
	__parents = { "Object", "LabelContainer" },
	properties = {
		{ template = true, id = "WorkRange", name = T(12390, "Work Range (hexes)"), editor = "number", default = 0},
	},
}

function Workforce:GameInit()
	self.city:AddToLabel("Workforce", self)
	self:AddOutskirtBuildings()
end

function Workforce:Init()
	self:InitEmptyLabel("Workplace")
end

function Workforce:Done()
	self.city:RemoveFromLabel("Workforce", self)
end

function SavegameFixups.AddWorkforcesToLabel()
	MapForEach("map", "Workforce", function(bld)
		bld.city:AddToLabel("Workforce", bld)
	end)
end

function Workforce:GetOutsideWorkplacesDist()
	local range = self.WorkRange
	return range + g_Consts.DefaultOutsideWorkplacesRadius
end

function Workforce:GetSelectionRadiusScale()
	return self:GetOutsideWorkplacesDist()
end

function Workforce:ChooseTraining(colonist)
	local training_centers = self.labels.TrainingBuilding or empty_table
	local workplace, shift = ChooseTraining(colonist, training_centers)
	return workplace, shift
end

function Workforce:ChooseWorkplace(colonist)
	local workplace, shift, worker_to_kick
	local workplaces = self.labels.Workplace or empty_table
	workplace, shift, worker_to_kick = ChooseWorkplace(colonist, workplaces, true)
	return workplace, shift, worker_to_kick
end

function Workforce:HasFreeWorkplacesAround(colonist)
	for _, b in ipairs(self.labels.Workplace or empty_table) do
		if not b.destroyed and b.ui_working and b:CanWorkHere(colonist) and b:HasFreeWorkSlots() then
			return true
		end
	end
	return false
end

function Workforce:IsBuildingInWorkRange(bld, range)
	range = range or self:GetOutsideWorkplacesDist()
	local distance = HexAxialDistance(self:GetPos(), bld:GetPos())
	return distance <= range
end

function Workforce:AddOutskirtBuildings()
	local realm = GetRealm(self)
	realm:MapForEach(self, "hex", self:GetOutsideWorkplacesDist() + 7, "DomeOutskirtBld", function(bld, self)
		if self:IsBuildingInWorkRange(bld) then
			bld:AddToDomeLabels(self)
		end
	end, self)
end
