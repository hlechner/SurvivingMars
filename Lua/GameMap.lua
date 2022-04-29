-- Holder instance for all map specific data structures

DefineClass.GameMap = {
	map_id = false,
	hex_width = -1,
	hex_height = -1,

	buildable = false,
	heat_grid = false,
	landscape_grid = false,
	lr_manager = false,
	object_hex_grid = false,
	pinnables = false,
	realm = false,
	supply_connection_grid = false,
	terrain = false,
}

function GameMap.new(class, map_id, map_width, map_height, map_data)
	assert(map_width ~= 0 and map_height ~= 0)
	local hex_width = ((map_width or 0) + const.GridSpacing - 1) / const.GridSpacing
	local hex_height = ((map_height or 0) + const.GridVerticalSpacing - 1) / const.GridVerticalSpacing
	assert(hex_width ~= 0 and hex_height ~= 0)
	-- compatibility
	HexMapWidth = hex_width
	HexMapHeight = hex_height
	
	local self = setmetatable({}, class)
	self.map_id = map_id
	self.hex_width = hex_width
	self.hex_height = hex_height

	self.realm = GetRealmByID(map_id)
	self.terrain = GetTerrainByID(map_id)

	self.buildable = BuildableGrid:new()
	self.buildable:Build(self.realm, hex_width, hex_height, map_data)
	self.heat_grid = HeatGrid:new(map_width, map_height)
	self.landscape_grid = NewGrid(hex_width, hex_height, 32, 0)
	self.lr_manager = LRManager:new()
	self.object_hex_grid = ObjectHexGrid:new()
	self.object_hex_grid:Build(hex_width, hex_height)
	self.pinnables = PinnableCollection:new()
	self.supply_connection_grid = SupplyConnectionGrid:new()
	self.supply_connection_grid:Build(hex_width, hex_height)
	self.supply_overlay_grid = NewGrid(hex_width, hex_height, 8, 0)
	
	return self
end

function GameMap:RefreshBuildableGrid()	
	local map_data = ActiveMaps[self.map_id]
	self.buildable:Build(self.realm, self.hex_width, self.hex_height, map_data)
end

GlobalVar("GameMaps", {})
GlobalVar("ActiveGameMap", false) -- Temporary variable to access the active game map data.

GlobalVar("HexMapWidth", false)
GlobalVar("HexMapHeight", false)

GlobalVar("SupplyGridConnections", false) -- Deprecated
GlobalVar("OverlaySupplyGrid", false) -- Deprecated

local function AddNewGameMap(map_id, hex_width, hex_height, map_data)
	GameMaps = GameMaps or {}
		
	local map_width, map_height = GetTerrainByID(map_id):GetMapSize()
	local game_map = GameMap:new(map_id, map_width, map_height, map_data)
	GameMaps[map_id] = game_map
	return game_map
end

function OnMsg.PreNewMap(map_id)
	local map_width, map_height = GetTerrainByID(map_id):GetMapSize()
	local map_data = ActiveMaps[map_id]
	AddNewGameMap(map_id, map_width, map_height, map_data)
	if table.count(GameMaps) == 1 then
		ActiveGameMap = GameMaps[map_id]
	end
end

function OnMsg.NewMapLoaded(map_id)
	local game_map = GameMaps[map_id]
	game_map.heat_grid:InitHeat()
end

function OnMsg.SwitchMap(map_id)
	ActiveGameMap = GameMaps[map_id]
	Landscape_SetGrid(ActiveGameMap.landscape_grid)
	UpdateRenderLandscape()
end

function OnMsg.SwitchMap(map_id, previous_map_id)
	local previous_game_map = GameMaps[previous_map_id]
	local game_map = GameMaps[map_id]
	if previous_game_map then
		previous_game_map.heat_grid:SetInvisible()
	end
	game_map.heat_grid:SetVisible()
end

function OnMsg.MapUnload(map_id)
	if GameMaps then
		if GameMaps[map_id] == ActiveGameMap then
			ActiveGameMap = false
		end
		GameMaps[map_id] = nil
	end
end

GlobalVar("MapSwitchCallbacks", {})
GlobalVar("MapSwitchCallbackRockets", {})

function QueueMapSwitchCallback(map_id, callback)
	MapSwitchCallbacks = MapSwitchCallbacks or {}
	MapSwitchCallbacks[map_id] = MapSwitchCallbacks[map_id] or {}
	local callbacks = MapSwitchCallbacks[map_id]
	table.insert(callbacks, callback)
end

function AddMapSwitchCallbackRocket(rocket, map_id)
	MapSwitchCallbackRockets = MapSwitchCallbackRockets or {}
	MapSwitchCallbackRockets[map_id] = MapSwitchCallbackRockets[map_id] or {}
	table.insert(MapSwitchCallbackRockets[map_id], rocket)
end

function OnMsg.SwitchMap(map_id)
	local callbacks = MapSwitchCallbacks and MapSwitchCallbacks[map_id] or false
	if callbacks then
		for _,callback in ipairs(callbacks) do 
			callback(map_id)
		end
	end
	MapSwitchCallbacks[map_id] = nil
	MapSwitchCallbackRockets[map_id] = nil
end

function OnMsg.MapUnload(map_id)
	MapSwitchCallbacks = MapSwitchCallbacks or {}
	MapSwitchCallbacks[map_id] = nil
	
	MapSwitchCallbackRockets = MapSwitchCallbackRockets or {}
	DoneObjects(MapSwitchCallbackRockets)
	MapSwitchCallbackRockets[map_id] = nil
end

----

GlobalVar("g_BuildableZ", false) -- Deprecated
GlobalVar("g_PinnedObjs", false) -- Deprecated
GlobalVar("ObjectGrid", false) -- Deprecated

function SavegameFixups.A001_GameMaps(metadata, lua_revision)
	if lua_revision > 1001648 then return end

	local map_id = ActiveMapID
	local terrain = GetTerrainByID(map_id)
	local map_width, map_height = terrain:GetMapSize()
	local map_data = ActiveMaps[map_id]
	local game_map = AddNewGameMap(map_id, map_width, map_height, map_data)
	ActiveGameMap = game_map

	game_map.buildable = BuildableGrid:new { }
	game_map.buildable.z_grid = g_BuildableZ
	g_BuildableZ = false

	if game_map.buildable.z_grid and game_map.buildable.z_grid:bits() ~= 16 then
		local new_grid = BuildableGrid:new()
		new_grid.z_grid:copy(game_map.buildable.z_grid)
		game_map.buildable = new_grid
	end

	game_map.pinnables.pins = table.copy(g_PinnedObjs or empty_table)
	g_PinnedObjs = false

	game_map.object_hex_grid = ObjectHexGrid:new {}
	game_map.object_hex_grid.grid = ObjectGrid
	-- ObjectGrid = false

	game_map.hex_width = HexMapWidth
	game_map.hex_height = HexMapHeight

	game_map.supply_connection_grid = SupplyConnectionGrid:new()
	game_map.supply_connection_grid.electricity = SupplyGridConnections.electricity
	game_map.supply_connection_grid.water = SupplyGridConnections.water
	SupplyGridConnections = false

	game_map.supply_overlay_grid = OverlaySupplyGrid
	OverlaySupplyGrid = false

	game_map.heat_grid:MoveLegacy()

	game_map.terrain = terrain

	game_map.landscape_grid = LandscapeGrid
	LandscapeGrid = false

	game_map.realm = GetRealmByID(map_id)
	
	game_map.lr_manager = LRManagerInstance
end

-- Object grid accessors
function GetGameMap(object)
	local map_id = object:GetMapID()
	return GameMaps[map_id]
end

function GetGameMapByID(map_id)
	return GameMaps[map_id]
end

function GetBuildableGrid(object)
	local map_id = object:GetMapID()
	return GameMaps[map_id].buildable
end

function GetObjectHexGrid(object)
	local map_id = object:GetMapID()
	return GameMaps[map_id].object_hex_grid
end

function GetLandscapeGrid(object)
	local map_id = object:GetMapID()
	return GameMaps[map_id].landscape_grid
end

function GetSupplyConnectionGrid(object)
	local map_id = object:GetMapID()
	return GameMaps[map_id].supply_connection_grid
end

function GetTerrain(object)
	local map_id = object:GetMapID()
	return GameMaps[map_id].terrain
end

function GetRealm(object)
	local map_id = object:GetMapID()
	return GameMaps[map_id].realm
end

function GetLRManager(object)
	local map_id = object:GetMapID()
	return GameMaps[map_id].lr_manager
end

-- Active grid accessors
function GetActiveObjectHexGrid()
	return ActiveGameMap.object_hex_grid
end

function GetActiveLandscapeGrid()
	return ActiveGameMap.landscape_grid
end
