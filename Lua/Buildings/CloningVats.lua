DefineClass.CloningVats = {
	__parents = { "ElectricityConsumer", "Workplace" },
	properties = {
		{  template = true, modifiable = true, id = "cloning_speed", name = T(14311, "Cloning speed"), default = 20, editor = "number", },
	},
	progress = false,
}

function CloningVats:Init()
	self.progress = 0
end

function CloningVats:BuildingUpdate(dt, ...)
	if self.working then
		local points = MulDivRound(self.performance,self.cloning_speed, 100)
		self.progress = self.progress + points
		if self.progress >= 1000 then
			local colonist_table = GenerateColonistData(self.city, "Child", "martianborn")
			colonist_table.dome = self.parent_dome
			colonist_table.traits["Clone"] = true
			if UIColony.mystery and UIColony.mystery:IsKindOf("DreamMystery") then
				colonist_table.traits["Dreamer"] = true
			end
			local colonist = Colonist:new(colonist_table, self:GetMapID())
			colonist:SetOutside(false)
			self:OnEnterUnit(colonist)
			Msg("ColonistBorn", colonist, "cloned")
			self.progress = 0
			self.parent_dome.clones_created = self.parent_dome.clones_created + 1
		end
	end	
end

function CloningVats:GetCloningProgress()
	return MulDivRound(self.progress,100, 1000)
end