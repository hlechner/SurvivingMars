DefineClass.RubbleBase = {
}

DefineClass.RubbleClearer = {
}

function RubbleClearer:CanInteractWithObject(obj, interaction_mode)
	if IsKindOf(obj, "RubbleBase") and obj:CanBeCleared() then
		return true, T{13735, "<UnitMoveControl('ButtonA', interaction_mode)>: Clear Rubble", self} 
	end
	return false
end

function RubbleClearer:InteractWithObject(obj, interaction_mode)
	if IsKindOf(obj, "RubbleBase") and obj:CanBeCleared() then
		SetUnitControlInteractionMode(self, false)
		GetCommandFunc(self)(self, "ClearRubble", obj)
	end
end

function RubbleClearer:ClearRubble(rubble)
	if not IsValid(rubble) then return end

	local reached_rubble = rubble:DroneApproach(self, "ClearRubble")
	if not reached_rubble then return end
	
	if not IsValid(rubble) then return end
	rubble:RequestClear()
	
	local resource = rubble.clear_request:GetResource()
	local amount = DroneResourceUnits[resource]
	
	if IsKindOf(self, "Drone") then
		rubble:DroneWork(self, rubble.clear_request, resource, amount)
	else
		rubble:RoverWork(self, rubble.clear_request, resource, amount)
	end
end