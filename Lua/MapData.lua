function OnMsg.DataLoaded()
	local class_names = ClassDescendantsList("MapSettings")
	for i = 1, #class_names do
		local class = class_names[i]
		local entry = table.find_value(MapDataPreset.properties, "id", class)
		if entry then
			entry.items = function() return DataInstanceCombo(class, "{name}", "disabled") end
		end
	end
end


--[[
function OnMsg.DataLoaded()
	local class_names = ClassDescendantsList("MapSettings")
	if #class_names == 0 then
		return
	end
	
	local meta = getmetatable(MapDataClass.properties)
	setmetatable(MapDataClass.properties, {})
	for i = 1, #class_names do
		local class = class_names[i]
		table.iappend(MapDataClass.properties, {
			{ category = "Game", id = class, editor = "dropdownlist", default = "default", items = function() return DataInstanceCombo(class, "{name}") end, },
		})
	end
	setmetatable(MapDataClass.properties, meta)
end
--]]

MapDataPreset.MinimapActiveArea = box(0,0,-1,-1)
MapDataPreset.MinimapSize = point(0, 0)

local oldSaveMapData = MapDataPreset.SaveMapData
function MapDataPreset:SaveMapData(folder)
	if not folder then
		-- precalc minimap size bounding box
		local minimap_image = self.IsRandomMap and "memoryscreenshot/minimap.tga" or (GetMapPath() .. "minimap.tga")
		self.MinimapActiveArea = GetTextureBoundingBox(minimap_image, 100)
		self.MinimapSize = point(UIL.MeasureImage(minimap_image))
	end
	oldSaveMapData(self, folder)
end

local orig_MapDataPresetOnEditorSetProperty = MapDataPreset.OnEditorSetProperty

function MapDataPreset:OnEditorSetProperty(prop_id, old_value, ged)
	if prop_id == "playable_height_range" or prop_id == "visible_height_range" then
		local width = self.Width * guim
		local height = self.Height * guim
		local x = width / 2
		local y = height / 2
		local prop = self[prop_id]
		
		DbgClearVectors()
		
		if prop then
			local z_low = prop.from * guim
			local z_high = prop.to * guim
			
			local terrain = GetActiveTerrain()
			local tavg, tmin, tmax = terrain:GetAreaHeight()
			local low_opacity = z_low < tmin and 30 or 128
			local high_opacity = z_high > tmax and 30 or 128
			
			local width_half = (width / 2) - self.PassBorder
			local height_half = (height / 2) - self.PassBorder

			DbgDrawPlane(point(x, y, z_low), width_half, height_half, RGBA(255, 100, 100, low_opacity))
			DbgDrawPlane(point(x, y, z_high), width_half, height_half, RGBA(100, 255, 100, high_opacity))
		end

		if prop_id == "playable_height_range" then
			local passable_min = prop and prop.from * guim or min_int
			local passable_max = prop and prop.to * guim or max_int
			local terrain = GetActiveTerrain()
			terrain:SetPassableHeight(passable_min, passable_max)
			terrain:RebuildPassability()
		end
	else
		orig_MapDataPresetOnEditorSetProperty(self, prop_id, old_value, ged)
	end
end
