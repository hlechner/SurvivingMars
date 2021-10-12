DefineClass.InteractionController = {
	start_player_controllable = false,
}

function InteractionController:OnInteractionModeChanged(old, new)
	self.interaction_mode = new
	ObjModified(self)
end

function InteractionController:ResolveObjAt(pos, interaction_mode)
end

function InteractionController:SetInteractionState(val)
	SetUnitControlInteractionMode(self, val)
	if val then
		SetUnitControlFocus(true, self)
	end
end

function InteractionController:GetCursor()
	return self.interaction_mode and const.DefaultInteractionCursor or const.DefaultMouseCursor
end