DefineClass.FilterObject = {
    filter = false,
	categories = false,
}

FilterState = {
	Musthave = 1000000,
	Positive = 1,
	Neutral = 0,
	Negative = -1000,
}

function FilterObject:UpdateFilterForAttribute(attribute, state, cat_id, elements)
    local filter = self.filter
	local category = self.categories[cat_id]
	if attribute == "all" then

        --see the how filters are distributed in the category
		local musthave = category.__musthave == category.count
		local mix_musthave = not musthave and (category.__musthave or 0) >= 1

		local positive = category.__positive == category.count
		local mix_positive = not positive and (category.__positive or 0) >= 1

		local negative = category.__negative == category.count
		local mix_negative = not negative and (category.__negative or 0) >= 1

        local current_state = nil
		local clear_filters = false

        --see if we have to clear the filters instead of setting new value
		if (musthave or mix_musthave) and state == TraitFilterState.Musthave then
			current_state = mix_musthave and TraitFilterState.Musthave or nil
			clear_filters = true
		elseif (positive or mix_positive) and state == TraitFilterState.Positive then
			current_state = mix_positive and TraitFilterState.Positive or nil
			clear_filters = true
		elseif (negative or mix_negative) and state == TraitFilterState.Negative then
			current_state = mix_negative and TraitFilterState.Negative or nil
			clear_filters = true
        end

        --loop to clean or set
        for _, value in sorted_pairs(elements) do
            if value.group == cat_id then
                if clear_filters then
                	self:ClearFilter(value.id, state)
                else
                	self:SetFilter(value.id, state)
                end
            end
        end

	elseif filter[attribute] == state then
		self:ClearFilter(attribute, state)
	else
		self:SetFilter(attribute, state)
	end
end

function FilterObject:SetFilter(value, state, current_state)
    self.filter[value] = state
end

function FilterObject:ClearFilter(value, state)
	if self.filter[value] == state then
		self.filter[value] = nil
	end
end

function FilterObject:GetPropFilterDisplayName(prop_meta)
	
end

function FilterObject:UpdateImages(ctrl, prop_meta)
	local filter = self.filter
	local categories = self.categories
	local musthave, positive, negative, mix_musthave, mix_positive, mix_negative
	local cat_id = prop_meta.cat_id or prop_meta.id
	local all = prop_meta.value == "all" or prop_meta.submenu
	if all then
		musthave = categories[cat_id].__musthave == categories[cat_id].count
		mix_musthave = not musthave and (categories[cat_id].__musthave or 0) >= 1

		positive = categories[cat_id].__positive == categories[cat_id].count
		mix_positive = not positive and (categories[cat_id].__positive or 0) >= 1

		negative = categories[cat_id].__negative == categories[cat_id].count
		mix_negative = not negative and (categories[cat_id].__negative or 0) >= 1
	else
		musthave = filter[prop_meta.value] == TraitFilterState.Musthave
		positive = filter[prop_meta.value] == TraitFilterState.Positive
		negative = filter[prop_meta.value] == TraitFilterState.Negative
	end

	ctrl.idMusthave:SetImage(mix_musthave and "UI/Icons/traits_random_musthave.tga" or musthave and "UI/Icons/traits_musthave.tga" or "UI/Icons/traits_musthave_disabled.tga")
	ctrl.idPositive:SetImage(mix_positive and "UI/Icons/traits_random_approve.tga" or positive and "UI/Icons/traits_approve.tga" or "UI/Icons/traits_approve_disable.tga")
	ctrl.idNegative:SetImage(mix_negative and "UI/Icons/traits_random_disapprove.tga" or negative and "UI/Icons/traits_disapprove.tga" or "UI/Icons/traits_disapprove_disable.tga")
end

function FilterObjectAttributes(filter, obj_attributes)
	local match = 0
	for attrib, value in pairs(filter or empty_table) do
		if obj_attributes[attrib] then
			match = match + (not value and 0 or value)
		end
	end
	return match
end