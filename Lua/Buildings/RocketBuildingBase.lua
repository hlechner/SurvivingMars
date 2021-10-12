DefineClass.RocketBuildingBase = { __parents = { "BaseRoverBuilding", "RocketLandingSite" }, rover_class = false }

function GetMachineType(class)
	return "Rocket"
end

function RocketBuildingBase:GameInit()
	CreateGameTimeThread(function()
		g_UITotalRockets = g_UITotalRockets + 1
		local rocket_class = self:GetConstructionRocketEntity()
		local map_id = self:GetMapID()
		local rocket = PlaceBuildingIn(rocket_class, map_id, {name = GenerateMachineName(GetMachineType(rocket_class))})
		rocket:SetPos(self:GetSpotPos(self:GetSpotBeginIndex("Rocket")))
		rocket:SetAngle(self:GetAngle())
		rocket:SetCommand("Unload")
		rocket.landing_site = PlaceBuildingIn("RocketLandingSite", map_id)
		local pos = self:GetPos()
		rocket.landing_site:SetPos(pos)
		rocket.landing_site:SetAngle(self:GetAngle())
		DeleteRocketConstruction(pos, map_id)
		DoneObject(self)
	end)
end

function DeleteRocketConstruction(pos, map_id)
	local q, r = WorldToHex(pos)
	local object_hex_grid = GetGameMapByID(map_id).object_hex_grid
	local blds = object_hex_grid:GetObjects(q, r, nil, nil, function(o)
		return IsKindOf(o, "LandingPad") or IsKindOf(o, "TradePad")
	end)
	for _, bld in ipairs(blds) do
		bld.rocket_construction = nil
	end
end

function RocketBuildingBase:GetConstructionRocketEntity()
	if self.construction_rocket_class then
		return self.construction_rocket_class
	end
	return GetMissionSponsor().rocket_class or "SupplyRocket"
end

function OnMsg.ConstructionSiteRemoved(construction_site)
	if construction_site and IsKindOf(construction_site.building_class_proto, "RocketBuildingBase") then
		local pos = construction_site:GetPos()
		DeleteRocketConstruction(pos, construction_site:GetMapID())
	end
end