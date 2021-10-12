DefineClass.BaseRoverBuilding = {
	__parents = { "Building" },
	
	rover_class = false,
	unlock_tech = false,
	hide = true,
	check_supply = false,
	shape_entity = false,
}

function BaseRoverBuilding:GameInit()
	if self.rover_class then
		CreateGameTimeThread(function()
			local rover = PlaceObjectIn(self.rover_class, self:GetMapID())
			local spot = self:GetSpotBeginIndex("Rover")
			local pos, angle = self:GetSpotLoc(spot)
			rover:SetPos(pos)
			rover:SetAngle(angle)
			rover:TransformToEnvironment(GetEnvironment(self))
			DoneObject(self)
		end)
	end
end

DefineClass.RCRoverBuilding = { __parents = { "BaseRoverBuilding" }, rover_class = "RCRover" }
DefineClass.RCTransportBuilding = { __parents = { "BaseRoverBuilding" }, rover_class = "RCTransport" }
DefineClass.RCExplorerBuilding = { __parents = { "BaseRoverBuilding" }, rover_class = "ExplorerRover" }
DefineClass.RCSafariBuilding = { __parents = { "BaseRoverBuilding" }, rover_class = "RCSafari" }
DefineClass.SupplyRocketBuilding = { __parents = { "RocketBuildingBase" }, construction_rocket_class = false }

function OnMsg.DataLoaded()
	ClassDescendants("BaseRoverBuilding", function(classname, class)
		if class.unlock_tech then
			local requirements = BuildingTechRequirements[classname] or {}
			BuildingTechRequirements[classname] = requirements
			requirements[#requirements + 1] = { tech = class.unlock_tech, hide = class.hide, check_supply = class.check_supply }
		end
	end)
end
