local map_border = const.HeatGridBorder
local grid_tile = const.HeatGridTileSize
local max_heat = const.MaxHeat
local heat_step_percent = 1
local heat_step_min = 1
local Heat_Get = Heat_Get

DefineClass.HeatGrid = {
	__parents = {},
	map_width = -1,
	map_height = -1,
	grid = false,
	grid_target = false,
	heat_changed = false,
	heaters = {},
	visible = false,
	lerp_grid_thread = false,
}

function HeatGrid.new(class, width, height)
	assert(width ~= 0 and height ~= 0)

	local self = setmetatable({}, class)
	self.map_width = width
	self.map_height = height
	width = width - 2 * map_border
	height = height - 2 * map_border
	assert(width ~= 0 and height ~= 0)
	local grid_width = width / grid_tile + ((width % grid_tile) == 0 and 0 or 1)
	local grid_height = height / grid_tile + ((height % grid_tile) == 0 and 0 or 1)

	self.grid = NewGrid(grid_width, grid_height, 8, max_heat)
	self.grid_target = NewGrid(grid_width, grid_height, 16, const.HeatZeroTarget + max_heat)
	self.heat_changed = false
	self.heaters = {}
	self.visible = false
	return self
end

function HeatGrid:delete(...)
	if self.visible then
		ClearHeatGrid()
	end
end

GlobalVar("s_Heaters", {})
GlobalVar("g_HeatGrid", false)
GlobalVar("s_HeatGridTarget", false)
GlobalVar("HeatChanged", false)
PersistableGlobals.s_HeatGridTarget = nil -- don't save this, we can rebuild it

function HeatGrid:MoveLegacy()
	self.grid = g_HeatGrid
	self.heat_changed = HeatChanged
	self.heaters = s_Heaters
	if g_HeatGrid then
		self:SetVisible()
	end

	self:FixHeatValues()
	self:ApplyHeaters(true)
	Msg("ApplyHeaters", self.grid_target)
	self:ApplyHeaters(false)

	g_HeatGrid = false
	s_Heaters = false
	s_HeatGridTarget = false
	HeatChanged = false
end

function HeatGrid:GetHeatAtXY(x, y)
	return Heat_Get(x, y, self.grid, map_border, grid_tile)
end

function HeatGrid:GetHeatAt(obj)
	return Heat_Get(obj, self.grid, map_border, grid_tile)
end

function HeatGrid:GetAverageHeatIn(area)
	return Heat_Average(area, self.grid, self.map_width, self.map_height, map_border, grid_tile)
end

function HeatGrid:GetAverageHeatShape(shape, obj)
	return Heat_AverageInShape(shape, obj, self.grid, map_border, grid_tile)
end

function HeatGrid:ApplyHeatForm(heater, heat, center_x, center_y, radius, border, progress)
	radius = radius or 0
	border = border or 0
	progress = progress or -1
	return heater:ApplyForm(self.grid_target, heat, center_x, center_y, radius - border / 2, border, self.map_width, self.map_height, map_border, grid_tile, progress)
end

function HeatGrid:ApplyHeaters(static)
	for heater, info in pairs(self.heaters) do
		if static and heater.is_static or not static and not heater.is_static then
			local heat, center_x, center_y, radius, border = table.unpack(info)
			local progress = self:ApplyHeatForm(heater, -heat, center_x, center_y, radius, border)
			info[6] = progress
		end
	end
end

function HeatGrid:FixHeatValues()
	for heater, info in pairs(self.heaters) do
		assert(heater.heat == GetClassValue(heater, "heat"))
		info[1] = -heater.heat
	end
end

function HeatGrid:InitHeat()
	AsyncLerpHeatGrid(self.grid, self.grid_target, 100)
	if self.visible then
		hr.TR_UpdateHeatGrid = 1
	end
end

function HeatGrid:SetVisible()
	self.visible = true
	SetHeatGrid(self.grid, map_border)
	hr.TR_UpdateHeatGrid = 1
end

function HeatGrid:SetInvisible()
	self.visible = false
	ClearHeatGrid()
end

function HeatGrid:WaitLerpFinish()
	while self.grid and self.grid_target do
		local game_speed = IsPaused() and 0 or GetTimeFactor()
		if game_speed == 0 then
			WaitMsg("MarsResume", 200)
		else
			local err, changed = AsyncLerpHeatGrid(self.grid, self.grid_target, heat_step_percent, heat_step_min)
			if err or not changed then
				if err then
					print("LerpHeatGrid error: ", err)
				end
				self.changed = false
				break
			end
			if self.visible then
				hr.TR_UpdateHeatGrid = 1
			end
			Sleep(200 * (1000 / game_speed))
		end
	end
	if self.visible then
		SetIceStrength(0, "LerpHeatGrid")
	end
end

function HeatGrid:OnHeatGridChanged()
	self.changed = true
	if IsValidThread(self.lerp_grid_thread) then
		return
	end
	if self.visible then
		SetIceStrength(GetSceneParam("IceStrength"), "LerpHeatGrid")
	end
	self.lerp_grid_thread = CreateMapRealTimeThread(function() self:WaitLerpFinish() end)
end

function GetHeatAt(obj)
	local game_map = GetGameMap(obj)
	local heat_grid = game_map.heat_grid
	return heat_grid:GetHeatAt(obj)
end

function GetAverageHeatShape(shape, obj)
	local game_map = GetGameMap(obj)
	local heat_grid = game_map.heat_grid
	return heat_grid:GetAverageHeatShape(shape, obj)
end

function FreezeEntireMap()
	local game_map = ActiveGameMap
	if game_map then
		local heat_grid = game_map.heat_grid
		hr.RenderIce = 1
		SetIceStrength(100, "debug", nil, 0, 0)
		Heat_SetAmbient(heat_grid.grid, 100)
		hr.TR_UpdateHeatGrid = 1
	end
end

function UnfreezeEntireMap()
	hr.RenderIce = 0
	SetIceStrength(0, "debug")
end

function OnMsg.ChangeMap()
	ClearHeatGrid()
end
