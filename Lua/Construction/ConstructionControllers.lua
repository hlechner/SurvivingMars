ConstructionModeController = {}

DefineClass.ConstructionControllers = {
	city = false,
	construction_controllers = false
}

function ConstructionControllers:InitConstructionControllers(city)
	self.city = city
	self.construction_controllers = {}
end

function ConstructionControllers:DoneConstructionControllers()
	self.city = false
	self.construction_controllers = false
end

function ConstructionControllers:GetConstructionController(class_name)
	local instance = self.construction_controllers[class_name]
	if not instance then
		local class = g_Classes[class_name]
		assert(class)
		instance = class and class:new({city = self.city}) or nil
	 	self.construction_controllers[class_name] = instance
	end
	return instance
end

function GetConstructionController(mode)
	mode = mode or InGameInterfaceMode

	local controller = ConstructionModeController[mode]
	if controller then
		local city_construction = GetCityConstructionControllers()
		return city_construction:GetConstructionController(controller)
	end
end

function ConstructionControllers:ApplyFixup()
	local controllers = self.construction_controllers
	local city = self.city
	controllers["ConstructionController"] = CityConstruction[city]
	controllers["GridConstructionController"] = CityGridConstruction[city]
	controllers["GridSwitchConstructionController"] = CityGridSwitchConstruction[city]
	controllers["TunnelConstructionController"] = CityTunnelConstruction[city]
	controllers["LayoutConstructionController"] = CityLayoutConstruction[city]
	controllers["LevelPrefabController"] = CityLevelPrefabConstruction[city]
	controllers["OpenCityConstructionController"] = OpenCityConstruction[city]

	controllers["LandscapeTerraceController"] = CityLandscapeTerrace[city]
	controllers["LandscapeRampController"] = CityLandscapeRamp[city]
	controllers["LandscapeTextureController"] = CityLandscapeTexture[city]
	controllers["LandscapeClearWasteRockController"] = CityLandscapeClearWasteRock[city]

	for _, controller in pairs(controllers) do
		controller.city = city
	end

	-- Deprecated and safe to nil
	CityGridConstruction[city] = nil
	CityGridSwitchConstruction[city] = nil
	CityLevelPrefabConstruction[city] = nil

	CityLandscapeTerrace[city] = nil
	CityLandscapeRamp[city] = nil
	CityLandscapeTexture[city] = nil
	CityLandscapeClearWasteRock[city] = nil
end

ConstructionModeController["construction"] = "ConstructionController"
ConstructionModeController["electricity_grid"] = "GridConstructionController"
ConstructionModeController["life_support_grid"] = "GridConstructionController"
ConstructionModeController["passage_grid"] = "GridConstructionController"
ConstructionModeController["passage_ramp"] = "GridSwitchConstructionController"
ConstructionModeController["electricity_switch"] = "CityGridSwitchConstruction"
ConstructionModeController["lifesupport_switch"] = "CityGridSwitchConstruction"
ConstructionModeController["tunnel_construction"] = "TunnelConstructionController"
ConstructionModeController["layout"] = "LayoutConstructionController"
ConstructionModeController["level_prefab"] = "LevelPrefabController"

ConstructionModeController["landscape_terrace"] = "LandscapeTerraceController"
ConstructionModeController["landscape_ramp"] = "LandscapeRampController"
ConstructionModeController["landscape_texture"] = "LandscapeTextureController"
ConstructionModeController["landscape_clearwasterock"] = "LandscapeClearWasteRockController"

GlobalVar("CityConstruction", {})
GlobalVar("CityGridConstruction", {})
GlobalVar("CityGridSwitchConstruction", {})
GlobalVar("CityTunnelConstruction", {})
GlobalVar("CityLayoutConstruction", {})
GlobalVar("CityLevelPrefabConstruction", {})
GlobalVar("OpenCityConstruction", {})

GlobalVar("CityLandscapeTerrace", {})
GlobalVar("CityLandscapeRamp", {})
GlobalVar("CityLandscapeTexture", {})
GlobalVar("CityLandscapeClearWasteRock", {})

function GetDefaultConstructionController(city)
	local city_construction = GetCityConstructionControllers(city or UICity)
	return city_construction:GetConstructionController("ConstructionController")
end

function GetGridConstructionController(city)
	local city_construction = GetCityConstructionControllers(city or UICity)
	return city_construction:GetConstructionController("GridConstructionController")
end

function GetGridSwitchConstructionController(city)
	local city_construction = GetCityConstructionControllers(city or UICity)
	return city_construction:GetConstructionController("GridSwitchConstructionController")
end

function GetTunnelConstructionController(city)
	local city_construction = GetCityConstructionControllers(city or UICity)
	return city_construction:GetConstructionController("TunnelConstructionController")
end

function GetLayoutConstructionController(city)
	local city_construction = GetCityConstructionControllers(city or UICity)
	return city_construction:GetConstructionController("LayoutConstructionController")
end

function GetLevelPrefabConstructionController(city)
	local city_construction = GetCityConstructionControllers(city or UICity)
	return city_construction:GetConstructionController("LevelPrefabController")
end

function GetOpenCityConstructionController()
	local city_construction = GetCityConstructionControllers(UICity)
	return city_construction:GetConstructionController("OpenCityConstructionController")
end

function GetLandscapeTerraceController(city)
	local city_construction = GetCityConstructionControllers(city or UICity)
	return city_construction:GetConstructionController("LandscapeTerraceController")
end

function GetLandscapeRampController(city)
	local city_construction = GetCityConstructionControllers(city or UICity)
	return city_construction:GetConstructionController("LandscapeRampController")
end

function GetLandscapeTextureController(city)
	local city_construction = GetCityConstructionControllers(city or UICity)
	return city_construction:GetConstructionController("LandscapeTextureController")
end

function GetLandscapeClearWasteRockController(city)
	local city_construction = GetCityConstructionControllers(city or UICity)
	return city_construction:GetConstructionController("LandscapeClearWasteRockController")
end
