local PlanetCameras = 
{
	["PlanetNone"] = { point(0, 3398, 30000), point(-700, 0, 29900) },
	["PlanetMars"] = { point(0, 3398, 30000), point(-700, 0, 29900) },
	["PlanetEarth"] = { point(-334, 2536, 30126), point(-472, 2056, 30114) },
	["PlanetEarthCloseup"] = { point(-571, 1545, 30400),point(-683, 1060, 30353) },
}
local planet_mars_longitude_offset = -90 * 60
local planet_mars_rotation_speed = 50
local planet_earth_rotation_speed = 250
local planet_earth_close_rotation_speed = 250

GlobalVar("PlanetScene", false)
GlobalVar("PlanetCamera", false)
GlobalVar("PlanetThread", false)
GlobalVar("PlanetStack", false)

function SetPlanetCamera(planet, state)
	state = state or "open"
	planet = planet or false
	if planet then
		PlanetStack = PlanetStack or {}
		table.remove_value(PlanetStack, planet)
		if state == "open" then
			table.insert(PlanetStack, planet)
		end
		planet = PlanetStack[#PlanetStack] or false
	end
	if not planet then
		PlanetStack = false
	end
	local old_planet = PlanetScene or false
	if planet == old_planet then
		return
	end
	PlanetScene = planet
	PlacePlanet(planet)
	return CreateRealTimeThread(function()
		if IsValidThread(CameraTransitionThread) then
			WaitMsg("CameraTransitionEnd")
		end
		while IsValidThread(PlanetThread) do
			WaitMsg(PlanetThread)
		end
		PlanetThread = CurrentThread()
		CancelRenderingSkipFrames(40)
		if old_planet then
			WaitNextFrame(1)
			table.restore(hr, "PlanetCamera")
			WaitNextFrame(2)
			RecreateRenderObjects()
			if PlanetCamera then
				SetCamera(unpack_params(PlanetCamera))
			end
			SetLightmodelOverride(1, false)
			SetPostProcPredicate("space_mist", false)
			WaitNextFrame(1)
		end
		if planet then
			PlanetCamera = { GetCamera() }
			WaitNextFrame(1)
			SetPostProcPredicate("space_mist", true)
			SetLightmodelOverride(1, planet)
			WaitNextFrame(2)
			table.change(hr, "PlanetCamera", { 
				RenderTerrain = 0,
				RenderBuildGrid = 0,
				RenderOverlayGrid = 0,
				RenderMirage = 0,
				RenderIce = 0,
				RenderPlanetView = PlanetObj and 1 or 0,
				FarZ = 700000,
				NearZ = 100,
			})
			cameraMax.Activate(1)
			cameraMax.SetCamera(unpack_params(PlanetCameras[planet]))
			camera.SetAutoFovX(1, 0, 70*60, 16, 9, 170*60, 7, 1)
			WaitNextFrame(1)
			DestroyAllRenderObjs()
		end
		WaitNextFrame(2)
		ResumeRendering()
		if next(s_CameraLockReasons) == nil then
			engineUnlockCamera(1)
		end
		Msg(CurrentThread())
		Msg("PlanetCameraSet")
	end)
end

function WaitPlanetCamera(planet, state)
	local thread = SetPlanetCamera(planet, state)
	if thread then
		WaitMsg(thread)
	end
end

function ClosePlanetCamera(planet)
	SetPlanetCamera(planet, "close")
end

GlobalVar("PlanetObj", false)
GlobalVar("PlanetRotationObj", false)
GlobalVar("PlanetRocket", false)

--- Armstrong DLC stub.
function GetTerraformParamPct(name)
	return 0
end

local RocketOffsets = {
	ZeusRocket = point(0, -20*guic, 0),
}

GlobalVar("PlanetMaxWaterLevel", false)

function SetMaxWaterLevelAndRefresh(level)
	PlanetMaxWaterLevel = level
	hr.PlanetWater = MulDivRound(PlanetMaxWaterLevel, GetTerraformParamPct("Water"), 1000)
end

local function CleanupPlanet()
	if IsValid(PlanetObj) then
		DoneObject(PlanetObj)
	end
	PlanetObj = false

	if IsValid(PlanetRotationObj) then
		DoneObject(PlanetRotationObj)
	end
	PlanetRotationObj = false
	
	if IsValid(PlanetRocket) then
		PlayFX("Thrusters", "end", PlanetRocket)
		DoneObject(PlanetRocket)
	end
	PlanetRocket = false
end

function PlacePlanetRocket(rocket_class)
	local template = BuildingTemplates[rocket_class]
	assert(template, print_format("Invalid rocket class", rocket_class))
	local rocket_entity = GetMissionSponsor():GetDefaultRocketSkin() or (template and template.entity) or "Rocket"
	local clsdef = g_Classes[template.template_class]
	assert(IsValidEntity(rocket_entity))
	local rocket_obj = PlaceObject("Rocket")
	rocket_obj:ClearEnumFlags(const.efCollision + const.efApplyToGrids)
	rocket_obj:ChangeEntity(rocket_entity)
	g_CurrentCCS = UICity and g_CurrentCCS or ColonyColorSchemes[GetMissionSponsor().colony_color_scheme or "default"]
	local palette = GetAdjustedRocketPalette(rocket_obj.entity or "Rocket", clsdef.rocket_palette, GetCurrentColonyColorScheme())
	SetObjectPaletteRecursive(rocket_obj, DecodePalette(palette))
	rocket_obj:SetState("inSpace")
	rocket_obj:DestroyAttaches()
	AutoAttachObjectsToShapeshifter(rocket_obj)
	rocket_obj:SetScale(1)
	rocket_obj:SetGameFlags(const.gofAlwaysRenderable + const.gofRealTimeAnim)
	rocket_obj:SetAxis(point(973, 1217, 3787))
	rocket_obj:SetAngle(-2863)
	rocket_obj:SetPos(point(-563, 1399, 30368) + (RocketOffsets[rocket_entity] or point30))
	local light = PlaceObject("PointLight")
	light:SetAttenuationRadius(10938)
	light:SetIntensity(5)
	light:SetColor(RGB(200,203, 225))
	rocket_obj:Attach(light)
	light:SetAttachOffset(point(0,40000, 0))
	PlayFX("Thrusters", "start", rocket_obj)
	return rocket_obj
end

function PlacePlanet(scene)
	CleanupPlanet()
	if not scene then
		return
	end

	MapDelete("map","PlanetDummy", "Rocket")

	local planets = {
		["PlanetNone"] = false,
		["PlanetMars"] = "PlanetMars",
		["PlanetEarth"] = "PlanetEarth",
		["PlanetEarthCloseup"] = "PlanetEarth",
	}

	local class = planets[scene]
	if not class then return end

	local rotation_obj = PlaceObject("PlanetDummy")
	local planet_obj = PlaceObject(class)
	local rocket_obj = false
	rotation_obj:SetPos(0, 0, 300*guim)
	if class == "PlanetMars" then
		rotation_obj:SetState("idle")
		rotation_obj:SetAnimSpeed(1, planet_mars_rotation_speed)
		rotation_obj:SetGameFlags(const.gofBoneTransform)
		local idx = 1
		for _, value in ipairs(MarsScreenLandingSpots or {}) do
			if value.add_hr_info_onplace then
				hr["PlanetColony"..idx.."Longitude"] = value.longitude
				hr["PlanetColony"..idx.."Latitude"] = value.latitude
				idx = idx + 1
			end
		end
		if not PlanetMaxWaterLevel then
			local lower_bound = 300
			PlanetMaxWaterLevel = lower_bound + AsyncRand(1000 - lower_bound)
		end
		SetMaxWaterLevelAndRefresh(PlanetMaxWaterLevel)
		hr.PlanetVegetation = GetTerraformParamPct("Vegetation")
		hr.PlanetAtmosphere = GetTerraformParamPct("Atmosphere")
		hr.PlanetTemperature = GetTerraformParamPct("Temperature")

		-- TODO: Make an actual atmoshpere entity and update the material(blending mode, transparency)
		local atmosphere = PlaceObject("PlanetClouds")
		rotation_obj:Attach(atmosphere, rotation_obj:GetSpotBeginIndex("Planet"))
		atmosphere:SetScale(101)
		atmosphere:SetOpacity(GetTerraformParamPct("Atmosphere"))
	elseif class == "PlanetEarth" then
		rotation_obj:SetState("idleSlow")
		rotation_obj:SetAxis(point(-1361, 1113, 3700))
		rotation_obj:SetAngle(5018)
		if scene == "PlanetEarthCloseup" then
			rocket_obj = PlacePlanetRocket(GetRocketClass())
			rotation_obj:SetAnimSpeed(1, planet_earth_close_rotation_speed)
		else
			rotation_obj:SetAnimSpeed(1, planet_earth_rotation_speed)
		end
	else
		assert(false, "Unknown planet class")
	end
	rotation_obj:SetGameFlags(const.gofAlwaysRenderable + const.gofRealTimeAnim)
	rotation_obj:Attach(planet_obj, rotation_obj:GetSpotBeginIndex("Planet"))
	planet_obj:SetHeat(255)
	PlanetObj = planet_obj
	PlanetRotationObj = rotation_obj
	PlanetRocket = rocket_obj
end

function RoundCoordToFullDegrees(coord)
	local remainder = coord % 60
	remainder = remainder >= 30 and remainder - 60 or remainder
	return coord - remainder
end

function GetPlanetSceneLongtitudeOffset()
	return planet_mars_longitude_offset
end

function GetPlanetSceneLongtitude(long)
	local long_temp = long - planet_mars_longitude_offset
	return long_temp >= 0 and long_temp or long_temp + 360 * 60
end

function PlanetGetClickCoords(click_pos)
	if not click_pos then 
		return false
	end
	local duration = GetAnimDuration(PlanetRotationObj:GetEntity(), EntityStates["idle"])
	local planet_angle = 360*60 - MulDivRound(PlanetRotationObj:GetAnimPhase(1), 360 * 60, duration)
	local planet_pos, planet_radius = PlanetObj:GetBSphere()
	local ok, lat_org, long_org = ScreenToPlanet(click_pos, planet_pos, planet_radius)
	if not ok then
		return false
	end
	-- planet_rot is 0..360, planet_offset is -90, 
	-- lat -> -70 .. +70 (dep on click and fov) as we rotate the planet
	local lat = lat_org
	local long = long_org
	long = planet_angle + planet_mars_longitude_offset + long
	if long < 0 then
		long = 360 *60 + long
	end	
	if long > 180*60 then
		long = long - 360 * 60
	end
	lat = lat - 90*60
	
	--restrict coordinates to full degrees
	lat = RoundCoordToFullDegrees(lat)
	long = RoundCoordToFullDegrees(long)
	
	lat = Clamp(lat, -70*60, 70*60)
	
	-- longitude is -180*60..180*60 W/E
	-- latitude  is -90*60..90*60 N/S
	return lat, long, lat_org, long_org
end
