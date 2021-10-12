DefineClass.DomeOutskirtBld = {
	__parents = { "CityObject" },
	dome_label = false,
}

function DomeOutskirtBld:GameInit()
	self:AddToDomeLabels()
end

function DomeOutskirtBld:Done()
	self:RemoveFromDomeLabels()
end
	
function DomeOutskirtBld:AddToDomeLabels(dome)
	local label = self.dome_label
	if not label then
		return
	end

	dome = dome or IsObjInDome(self)
	local city = dome and dome.city or self.city
	assert(city == self.city)

	if dome then
		dome:AddToLabel(label, self)
		return
	end

	for _, workforce in ipairs(city.labels.Workforce or empty_table) do
		if workforce:IsBuildingInWorkRange(self) then
			workforce:AddToLabel(label, self)
		end
	end
end

function DomeOutskirtBld:RemoveFromDomeLabels(dome)
	local label = self.dome_label
	if not label then
		return
	end

	dome = dome or IsObjInDome(self)
	local city = dome and dome.city or self.city
	assert(city == self.city)

	if dome then
		dome:RemoveFromLabel(label, self)
		return
	end

	for _, workforce in ipairs(city.labels.Workforce or empty_table) do
		if workforce:IsBuildingInWorkRange(self) then
			workforce:RemoveFromLabel(label, self)
		end
	end
end

function SavegameFixups.FixOutsideDomeBldCity()	
	MapsForEach("map", "DomeOutskirtBld", function(bld)
		bld.city = GetCity(bld)
	end)
end
