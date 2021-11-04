DefineClass.AutoMode = {
	auto_mode_on = true,
}

function AutoMode:SetAutoMode(value)
	self.auto_mode_on = value
end

function AutoMode:IsAutoModeEnabled()
	return self.auto_mode_on
end

function AutoMode:ToggleAutoMode(broadcast)
	local next_value = not self:IsAutoModeEnabled()
	if broadcast then
		GetRealm(self):MapForEach("map", self.class, function(o)
			o:SetAutoMode(next_value)
		end)
	else
		self:SetAutoMode(next_value)	
	end
end

function AutoMode:ToggleAutoMode_Update(button)
	if self:IsAutoModeEnabled() then
		button:SetIcon("UI/Icons/IPButtons/automated_mode_on.tga")
	else
		button:SetIcon("UI/Icons/IPButtons/automated_mode_off.tga")
	end
end
