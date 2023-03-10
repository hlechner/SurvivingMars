DefineClass.DepositMarker = {
	__parents = { "EditorMarker" },
	entity = "Hex1_Placeholder",
	resource = "",
	properties = {
		{ category = "Debug", name = T(8927, "Deposit"),      id = "Deposit",     editor = "object", default = false, developer = true, read_only = true, dont_save = true},
		{ category = "Debug", name = T(635, "Feature"), id = "dbg_feature", editor = "object", default = false, developer = true},
		{ category = "Debug", name = T(636, "Cluster"), id = "dbg_cluster", editor = "number", default = -1, developer = true},
		{ category = "Debug", name = T(637, "Prefab"),  id = "dbg_prefab",  editor = "text", default = "", developer = true},
	},
	is_placed = false,
	placed_obj = false, -- can still be false if is_placed = true, means the placement was obstructed and the deposit is lost
	depth_layer = 0,
	new_pos_if_obstruct = true,
}

function DepositMarker:Init()
	self:SetScale(110)
	local city = GetCity(self)
	if city then
		city:AddToLabel(self.class, self)
	end
end

function DepositMarker:Done()
	local city = GetCity(self)
	if city then
		city:RemoveFromLabel(self.class, self)
	end
end

function DepositMarker:GetDeposit()
	return self.placed_obj
end

function DepositMarker:GetObstructionRadius()
	return const.DepositObstructMaxRadius
end

function DepositMarker:EditorGetText()
	return self.class .. " " .. self.resource
end

function DepositMarker:GetDepthClass()
	return "surface"
end

function FindUnobstructedDepositPos(marker, dont_move_if_obstruct)
	local city = GetCity(marker)
	assert(city.MapArea)
	assert(not marker.is_placed)
	
	-- don't spawn deposits on top of other deposits
	local function IsBlockedByDeposit(marker, realm, pos_x, pos_y)
		local block_range = IsKindOf(marker, "SurfaceDepositMarker") and 1 or 2
		return realm:MapCount(point(pos_x, pos_y), const.HexSize * block_range, "Deposit") > 0
	end

	-- check for buildings on the required position, don't place surface deposits if buildings are in the way
	local orig_x, orig_y = marker:GetVisualPosXYZ()
	local mx, my = orig_x, orig_y
	local radius = marker:GetObstructionRadius()
	local IsDepositObstructed = IsDepositObstructed	
	local map_id = marker:GetMapID()
	local game_map = GameMaps[map_id]
	local object_hex_grid = game_map.object_hex_grid
	local realm = game_map.realm
	local obstructed = IsDepositObstructed(object_hex_grid, mx, my, radius) or IsBlockedByDeposit(marker, realm, mx, my)
	local unobstructed = false
	if obstructed and marker.new_pos_if_obstruct and not dont_move_if_obstruct then
		local GetMapSectorXY = GetMapSectorXY
		local sector = GetMapSectorXY(city, mx, my)
		local sx, sy
		local buildable_grid = game_map.buildable
		
		local f_continue = function(qi, ri)
			local xi, yi = HexToWorld(qi, ri)
			if IsDepositObstructed(object_hex_grid, xi, yi, radius) or IsBlockedByDeposit(marker, realm, xi, yi) then
				return true -- would continue searching in that directon
			end
			
			if GetMapSectorXY(city, xi, yi) ~= sector then
				if not sx then
					sx, sy = xi, yi
				end
				return "wrong" -- would stop searching in that directon
			end
		end
		
		local max_depth = GetMapSectorTile(map_id) / const.GridSpacing
		local x, y = FindBuildableAround(object_hex_grid, buildable_grid, mx, my, f_continue, max_depth, "wrong")
		
		if x then
			obstructed = false
			unobstructed = true
			mx, my = x, y
		else
			mx, my = sx, sy
		end
	end
	
	if not mx or not my then
		mx, my = orig_x, orig_y
	end

	return mx, my, unobstructed, obstructed
end

function DepositMarker:PlaceDeposit(dont_move_if_obstruct)
	local city = GetCity(self)
	assert(city.MapArea)
	if not self.is_placed then
		local ix, iy = self:GetVisualPosXYZ()
		local initial_sector = GetMapSectorXY(city, ix, iy)
		local x, y, unobstructed, obstructed = FindUnobstructedDepositPos(self, dont_move_if_obstruct)
		local sector = GetMapSectorXY(city, x, y)
		if obstructed then
			if sector ~= initial_sector then
				StoreErrorSource(self, "Failed to find a new place in the same sector!")
			else
				StoreErrorSource(self, "Failed to find a new place on the map!")
			end
		elseif unobstructed then
			self:SetPos(x, y, const.InvalidZ)
			print("Obstructed", self.class, "moved to", x, y)
		end

		self.placed_obj = not obstructed and self:SpawnDeposit()
		self.is_placed = true
		if sector then
			sector:RegisterDeposit(self) -- for deposits which got spawned later by means other than exploration
		end
		if IsValid(self.placed_obj) then
			self.placed_obj.marker = self
			self.placed_obj:SetPos(x, y, const.InvalidZ)
			if IsKindOf(self.placed_obj, "SubsurfaceDeposit") then
				local map_id = self:GetMapID()
				local map_data = ActiveMaps[map_id]
				self.placed_obj:SetAngle(map_data and (map_data.OverviewOrientation * 60) or 0)
			else
				self.placed_obj:SetAngle(self:GetAngle())
			end
		end
	end
	return self.placed_obj
end

function DepositMarker:SpawnDeposit() -- override this for the actual code which spawns the deposit
end

function DepositMarker:GetEstimatedAmount()
	return 0
end
