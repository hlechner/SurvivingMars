local RUBBLE_CLASS = "RubbleBase"

DefineClass.RubbleClearer = {
}

function RubbleClearer:CanInteractWithObject(obj, interaction_mode)
	if IsKindOf(obj, RUBBLE_CLASS) and obj:CanBeCleared() then
		return true, T{13735, "<UnitMoveControl('ButtonA', interaction_mode)>: Clear Cave-In", self} 
	end
	return false
end

function RubbleClearer:InteractWithObject(obj, interaction_mode)
	if IsKindOf(obj, RUBBLE_CLASS) and obj:CanBeCleared() then
		SetUnitControlInteractionMode(self, false)
		GetCommandFunc(self)(self, "ClearRubble", obj)
	end
end

function RubbleClearer:ClearRubble(rubble)
	rubble:DroneApproach(self, "ClearRubble")
	
	rubble:RequestClear()
	
	local resource = rubble.clear_request:GetResource()
	local amount = DroneResourceUnits[resource]
	
	if IsKindOf(self, "Drone") then
		rubble:DroneWork(self, rubble.clear_request, resource, amount)
	else
		rubble:RoverWork(self, rubble.clear_request, resource, amount)
	end
end