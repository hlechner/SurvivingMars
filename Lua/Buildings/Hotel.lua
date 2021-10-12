DefineClass.Hotel = {
	__parents = { "LivingBase", "WaypointsObj"},
	flags = { efWalkable = true },
}

function Hotel:SetTouristOnly(restricted)
	local is_restricted = self.exclusive_trait == "Tourist"
	if restricted ~= is_restricted then
		if restricted then
			self.exclusive_trait = "Tourist"
		else
			self.exclusive_trait = false
		end

		if restricted then
			for i = #self.colonists, 1, -1 do
				local colonist = self.colonists[i]
				if IsValid(colonist) then
					colonist:UpdateResidence()
				end
			end	
		else
			self:CheckHomeForHomeless()
		end
	end
end

function Hotel:ToggleTouristOnly(broadcast)
	if not self.suspended then
		RebuildInfopanel(self)
		self:SetTouristOnly(self.exclusive_trait ~= "Tourist")
		if broadcast then
			BroadcastAction(self, "SetTouristOnly", self.exclusive_trait == "Tourist")
		end
	end
end

function Hotel:ToggleTouristOnly_Update(button)
	local tourists_only = self.exclusive_trait == "Tourist"
	if tourists_only then
		button:SetIcon("UI/Icons/IPButtons/tourist.tga")
	else
		button:SetIcon("UI/Icons/IPButtons/colonists_all.tga")
	end
end

function Hotel:GetUITouristOnlyStatus()
	if self.exclusive_trait == "Tourist" then
		return T(12702, "Tourists Only")
	else
		return T(12703, "Any Colonist")
	end
end
