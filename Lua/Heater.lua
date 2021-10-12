local max_heat = const.MaxHeat

DefineClass.BaseHeater =
{
	__parents = { "InitDone" },
	heat = 0,
	is_static = false,
	max_neighbors = 0,
}

function BaseHeater:GetHeatRange()
	return 0
end

function BaseHeater:Done()
	self:ApplyHeat(false)
	self.heat = 0
end

function BaseHeater:GetHeatCenter()
	return self:GetVisualPosXYZ()
end

function BaseHeater:GetHeatBorder()
end

function BaseHeater:OnSetWorking(working)
	self:ApplyHeat(working)
end

function BaseHeater:ApplyHeat(apply, map_id)
	local game_map = map_id and GetGameMapByID(map_id) or GetGameMap(self)
	local heat_grid = game_map.heat_grid
	if not heat_grid then
		return
	end

	local new_info, heat, center_x, center_y, radius, border, progress
	local info = heat_grid.heaters[self]
	if apply then
		if info and self.is_static then
			return
		end
		heat = self.heat
		center_x, center_y = self:GetHeatCenter()
		radius = self:GetHeatRange()
		border = self:GetHeatBorder()
		new_info = {-heat, center_x, center_y, radius, border}
		if info then
			if table.iequals(new_info, info) then
				return
			end
			self:ApplyHeat(false)
		end
	else
		if not info or self.is_static then
			return
		end
		heat, center_x, center_y, radius, border, progress = table.unpack(info)
	end
	heat_grid.heaters[self] = new_info
	if heat ~= 0 then
		local new_progress = heat_grid:ApplyHeatForm(self, heat, center_x, center_y, radius, border, progress)
		if new_info and new_progress then
			new_info[6] = new_progress
		end
		heat_grid:OnHeatGridChanged()
	end
end

function BaseHeater:ApplyForm(grid, heat, center_x, center_y, radius, border, map_width, map_height, map_border, grid_tile, progress)
	return Heat_AddCircle(grid, center_x, center_y, radius, heat, border, map_width, map_height, map_border, grid_tile, progress)
end

function OnMsg.ClassesPostprocess()
	local heaters = ClassDescendants("BaseHeater")
	local min_heat, max_heat = 0, 0
	for name, def in pairs(heaters) do
		assert(def.heat ~= 0)
		if def.heat > 0 then
			max_heat = max_heat + (1 + def.max_neighbors) * def.heat
		else
			min_heat = min_heat - (1 + def.max_neighbors) * def.heat
		end
	end
	assert(max_heat < (2<<15))
	assert(min_heat < (2<<15))
end

----

DefineClass.SubsurfaceHeater =
{
	__parents = { "BaseHeater", "RangeElConsumer", "LifeSupportConsumer", "OutsideBuildingWithShifts" },
	heat = 5*max_heat, -- compensate cold wave + cold area + 2 spheres
	properties =
	{
		-- prop only for UI purposes
		{id = "UIRange", name = T(643, "Range"), editor = "number", default = 5, min = 3, max = 15, no_edit = true, dont_save = true},
	},
	UIRange = 5,
	max_neighbors = 6,
}

function SubsurfaceHeater:GameInit()
	self:UpdateElectricityConsumption()
end

function SubsurfaceHeater:GetHeatRange()
	return 10 * self.UIRange * guim
end

function SubsurfaceHeater:GetHeatBorder()
	return const.SubsurfaceHeaterFrameRange
end

function SubsurfaceHeater:OnPostChangeRange()
	if self:CanWork() then
		self:ApplyHeat(true)
	end
	self:UpdateElectricityConsumption()
end
