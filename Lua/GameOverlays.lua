local OverlayColors = {
	electricity = {
		0,
		RGBA(12 , 94 , 248, 80 ),
		RGBA(12 , 13 , 248, 120),
		RGBA(255, 23 , 255, 120),
		RGBA(253, 11 , 13 , 120),
		RGBA(255, 244, 11 , 120),
		RGBA(26 , 203, 9  , 120),
		RGBA(10 , 203, 192, 180),
		RGBA(240, 240, 240, 80 ),
	},
	water = {
		0,
		RGBA(12 , 94 , 248, 80 ),
		RGBA(12 , 13 , 248, 120),
		RGBA(255, 23 , 255, 120),
		RGBA(253, 11 , 13 , 120),
		RGBA(255, 244, 11 , 120),
		RGBA(26 , 203, 9  , 120),
		RGBA(10 , 203, 192, 180),
		RGBA(240, 240, 240, 80 ),
	},
}

GlobalVar("OverlaySupplyPallettes", false)

function OnMsg.NewGame()
	OverlaySupplyPallettes = {
		electricity = false,
		water = false,
		custom = false,
	}
end

function GetGridOverlayIndex(grid)
	return grid.overlay_id
end

function Lua_BuildOverlaySupplyGrid()
	local game_map = ActiveGameMap
	local supply_connection_grid = game_map.supply_connection_grid
	local supply_overlay_grid = game_map.supply_overlay_grid
	BuildOverlaySupplyGrid(supply_overlay_grid, supply_connection_grid.electricity, supply_connection_grid.water)
end

function RebuildOverlaySupplyPalettes()
	OverlaySupplyPallettes.electricity = {}
	local e = OverlaySupplyPallettes.electricity
	local ce = OverlayColors.electricity
	OverlaySupplyPallettes.water = {}
	local w = OverlaySupplyPallettes.water
	local cw = OverlayColors.water
	--[[
	OverlaySupplyPallettes.all = {}
	local a = OverlaySupplyPallettes.all

	local function MixRGBA(col_1, col_2)
		local r1, g1, b1, a1 = GetRGBA(col_1)
		local r2, g2, b2, a2 = GetRGBA(col_2)
		return RGBA((r1 + r2) / 2,
					  (g1 + g2) / 2,
					  (b1 + b2) / 2,
					  (a1 + a2) / 2)
	end
	]]
	for i = 1, 256 do
		e[i] = ce[band(i - 1, 15) % #ce + 1]
		w[i] = cw[shift(i - 1, -4) % #cw + 1]
		--a[i] = MixRGBA(e[i], w[i])
	end
end

function GetOverlaySupplyGridValAtTerrainCursor()
	local p = GetTerrainCursor()
	local q, r = WorldToHex(p:x(), p:y())
	local supply_overlay_grid = ActiveGameMap.supply_overlay_grid
	return supply_overlay_grid:get(q+r/2, r)
end

show_overlay = false
local overlay_grid_dirty = false

function GetOverlayPalette()
	return show_overlay == "water" and OverlaySupplyPallettes.water or show_overlay == "custom_supply" and OverlaySupplyPallettes.custom or
			show_overlay == "electricity" and OverlaySupplyPallettes.electricity or empty_table
end

function GetOverlayGrid()
	local supply_overlay_grid = ActiveGameMap.supply_overlay_grid
	return (show_overlay == "water" or show_overlay == "custom_supply" or show_overlay == "electricity") and supply_overlay_grid
end

function GetOverlayTransform()
	return 0, 1
end

function GetOverlayBorder()
	return RGBA(255, 255, 255, 255)
end

function RefreshSupplyGridOverlay_Exec()
	if show_overlay then
		if overlay_grid_dirty then
			local grid = GetOverlayGrid()
			local border = GetOverlayBorder()
			if type(overlay_grid_dirty) == "boolean" or overlay_grid_dirty == grid then
				local offset, scale = GetOverlayTransform()
				SetOverlayGrid(GetOverlayPalette(), grid, border, offset, scale)
			end
		end
		if hr.RenderOverlayGrid == 0 then
			hr.RenderOverlayGrid = 1
		end
	elseif hr.RenderOverlayGrid == 1 then
		hr.RenderOverlayGrid = 0
	end
	
	overlay_grid_dirty = false
end

function RefreshSupplyGridOverlay(grid)
	overlay_grid_dirty = not overlay_grid_dirty and grid or true
	DelayedCall(0, RefreshSupplyGridOverlay_Exec)
end

function ShowWaterOverlay()
	show_overlay = "water"
	local supply_overlay_grid = ActiveGameMap.supply_overlay_grid
	RefreshSupplyGridOverlay(supply_overlay_grid)
end

function HideOverlay()
	show_overlay = false
	DelayedCall(0, RefreshSupplyGridOverlay_Exec)
end

HideAllSupplyOverlays = HideOverlay

function ShowElectricityOverlay()
	show_overlay = "electricity"
	local supply_overlay_grid = ActiveGameMap.supply_overlay_grid
	RefreshSupplyGridOverlay(supply_overlay_grid)
end

function CycleElectricityOverlay()
	local realm = GetRealmByID(ActiveMapID)
	local electricity_grids = GetCommandCenterPowerGrids()
	CycleGrids(electricity_grids)
	ShowElectricityOverlay()
end

local last_sel_obj = false
local last_seen_grid = 0
function CycleGrids(grids)
	local idx = last_seen_grid + 1
	if idx > #grids then
		idx = 1
	end
	last_seen_grid = idx
	
	local grid = grids[idx]
	if grid then
		local root = CommandCenterChooseGridBuilding(grid)
		ViewAndSelectObject(root)
		last_sel_obj = root
	end
end

function CycleWaterOverlay()
	local lifesupport_grids = GetCommandCenterLifeSupportGrids()
	local water_grids = table.map(lifesupport_grids, "water")
	CycleGrids(water_grids)
	ShowWaterOverlay()
end

function OnMsg.OverlaySupplyGridChanged()
	local supply_overlay_grid = ActiveGameMap.supply_overlay_grid
	RefreshSupplyGridOverlay(supply_overlay_grid)
end

function OnMsg.SwitchMap()
	RebuildOverlaySupplyPalettes()
	HideAllSupplyOverlays()
end

local function ClearLastSelObj()
	last_sel_obj = false
end
function OnMsg.SelectionChange()
	if hr.RenderOverlayGrid then
		if SelectedObj and SelectedObj ~= last_sel_obj then
			last_sel_obj = SelectedObj
			HideAllSupplyOverlays()
		elseif not SelectedObj then
			DelayedCall(1000, ClearLastSelObj)
		end
	end
end

function AssignOverlayIDsToAllGrids()
	local c = UICity.electricity
	for i = 1, #c do
		c[i]:AssignOverlayID()
	end
	c = UICity.water
	for i = 1, #c do
		c[i]:AssignOverlayID()
	end
end

function SavegameFixups.BuildOverlayGridsFromScratch()
	RebuildOverlaySupplyPalettes()
	AssignOverlayIDsToAllGrids()
	Lua_BuildOverlaySupplyGrid()
end

local last_custom_grid = false
function ShowOverlayForSupplyGrid(supply_type, overlay_id, color)
	local arg_hash = xxhash64(supply_type, overlay_id, color)
	if last_custom_grid ~= arg_hash then
		OverlaySupplyPallettes.custom = {}
		local c = OverlaySupplyPallettes.custom
		for i = 1, 256 do
			c[i] = 0
		end
		
		overlay_id = supply_type == "water" and shift(overlay_id, 4) or overlay_id
		local sft = supply_type == "water" and 0 or 4
		for i = 0, 8 do
			c[bor(overlay_id, shift(i, sft)) + 1] = color
		end
		
		last_custom_grid = arg_hash
	end
	
	show_overlay = "custom_supply"
	local supply_overlay_grid = ActiveGameMap.supply_overlay_grid
	RefreshSupplyGridOverlay(supply_overlay_grid)
end