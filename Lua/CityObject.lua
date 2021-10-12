DefineClass.CityObject = {
	__parents = { "Object", "Modifiable" },
	city = false,
}

function CityObject:Init()
	local map_id = self:GetMapID()
	if not self.city then
		self.city = Cities[map_id] or UICity
	end
	assert(self.city.map_id == map_id)
end

function CityObject:Random(...)
	local city = self.city
	if not city then
		return AsyncRand(...)
	end
	return city:Random(...)
end

function CityObject:ChangeObjectModifier(modifier_table)
	local modifier = self:FindModifier(modifier_table.id, modifier_table.prop)
	local amount, percent = modifier_table.amount or 0, modifier_table.percent or 0
	if modifier then
		if amount~=0 or percent~=0 then
			modifier:Change(amount, percent, modifier_table.display_text)
		else
			modifier:delete()
		end
	elseif amount~=0 or percent~=0 then
		modifier_table.target = self
		ObjectModifier:new(modifier_table)
	end
end

function CityObject:RemoveObjectModifier(prop, id)
	local modifier = self:FindModifier(id, prop)
	if modifier then
		modifier:delete()
	end
end

function CityObject:AttachedToRealm(map_id)
	self.city = Cities[map_id]
	assert(self.city)
end

function City:GetMapID()
	return self.map_id
end
