-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	group = "Shortcuts",
	id = "GameShortcuts",
	PlaceObj('XTemplateAction', {
		'__condition', function (parent, context) return Platform.developer end,
	}, {
		PlaceObj('XTemplateAction', {
			'ActionId', "Editors",
			'ActionTranslate', false,
			'ActionName', "Editors",
			'ActionMenubar', "DevMenu",
			'OnActionEffect', "popup",
			'replace_matching_id', true,
		}, {
			PlaceObj('XTemplateAction', {
				'ActionId', "Editors.Random Map",
				'ActionTranslate', false,
				'ActionName', "Random Map ...",
				'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
				'OnActionEffect', "popup",
				'replace_matching_id', true,
			}, {
				PlaceObj('XTemplateAction', {
					'ActionId', "Editors.Random Map.Debug",
					'ActionTranslate', false,
					'ActionName', "Debug ...",
					'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
					'OnActionEffect', "popup",
					'replace_matching_id', true,
				}, {
					PlaceObj('XTemplateAction', {
						'ActionId', "PrefabDbgClear",
						'ActionTranslate', false,
						'ActionName', "Draw Clear",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							DbgClearVectors()
							DbgClearTexts()
							hr.TerrainDebugDraw = 0
							dbg_grid = false
						end,
						'replace_matching_id', true,
					}),
					PlaceObj('XTemplateAction', {
						'comment', " (Ctrl-B)",
						'RolloverText', " (Ctrl-B)",
						'ActionId', "DbgToggleBuildableGrid",
						'ActionTranslate', false,
						'ActionName', "Toggle Buildable Grid",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'ActionShortcut', "Ctrl-B",
						'OnAction', function (self, host, source)
							DbgToggleBuildableGrid()
						end,
						'replace_matching_id', true,
					}),
					PlaceObj('XTemplateAction', {
						'ActionId', "PrefabDbgDrawMinCircles",
						'ActionTranslate', false,
						'ActionName', "Draw Min Circles",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							PrefabDbgDrawCircle("RadiusMin")
						end,
						'replace_matching_id', true,
					}),
					PlaceObj('XTemplateAction', {
						'ActionId', "PrefabDbgDrawMaxCircles",
						'ActionTranslate', false,
						'ActionName', "Draw Max Circles",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							PrefabDbgDrawCircle("RadiusMax")
						end,
						'replace_matching_id', true,
					}),
					PlaceObj('XTemplateAction', {
						'ActionId', "PrefabDbgDrawDecorCircles",
						'ActionTranslate', false,
						'ActionName', "Draw Decor Circles",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							PrefabDbgDrawDecorCircles()
						end,
						'replace_matching_id', true,
					}),
					PlaceObj('XTemplateAction', {
						'ActionId', "PrefabDbgDrawPos",
						'ActionTranslate', false,
						'ActionName', "Draw Prefab Pos",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							PrefabDbgDrawPos()
						end,
						'replace_matching_id', true,
					}),
					PlaceObj('XTemplateAction', {
						'ActionId', "PrefabEditorDrawClusters",
						'ActionTranslate', false,
						'ActionName', "Draw Resource Clusters",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							PrefabDbgDrawResourceClusters()
						end,
						'replace_matching_id', true,
					}),
					PlaceObj('XTemplateAction', {
						'ActionId', "PrefabDbgDrawFeatures",
						'ActionTranslate', false,
						'ActionName', "Draw Features",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							PrefabDbgDrawFeatures()
						end,
						'replace_matching_id', true,
					}),
					PlaceObj('XTemplateAction', {
						'ActionId', "PrefabEditorObjectsToggle",
						'ActionTranslate', false,
						'ActionName', "Editor Objects Toggle",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							PrefabEditorObjectsToggle()
						end,
						'replace_matching_id', true,
					}),
					PlaceObj('XTemplateAction', {
						'ActionId', "PrefabDbgActionCompareObjects",
						'ActionTranslate', false,
						'ActionName', "Compare Objects",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							PrefabDbgActionCompareObjects()
						end,
						'replace_matching_id', true,
					}),
					PlaceObj('XTemplateAction', {
						'ActionId', "PrefabDbgActionFindSelected",
						'ActionTranslate', false,
						'ActionName', "Find Selected",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							PrefabDbgActionFindSelected()
						end,
						'replace_matching_id', true,
					}),
					}),
				PlaceObj('XTemplateAction', {
					'ActionId', "CurrentPreset",
					'ActionTranslate', false,
					'ActionName', "Current Preset",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						local gen = GetRandomMapGenerator() or GetRandomMapGeneratorHolder()
						if gen then
							PropEditorOpen(gen)
						end
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "PrefabFeatures",
					'ActionTranslate', false,
					'ActionName', "Feature Editor",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						OpenFeatureEditor()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "ResaveAllBlankMaps",
					'ActionTranslate', false,
					'ActionName', "Resave All Blank Maps",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source) return ResaveAllBlankMaps() end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "ResaveAllPrefabs",
					'ActionTranslate', false,
					'ActionName', "Resave All Prefabs",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source) ResaveAllPrefabs() end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateForEach', {
					'comment', "Resave Prefabs Versions",
					'array', function (parent, context) return PrefabVersions() end,
					'run_after', function (child, context, item, i, n)
						child.ActionId = "ResavePrefabsVersion" .. i
						child.ActionName = "Resave Prefabs Version " .. item
						child.OnAction = function() ResaveAllPrefabs(item) end
					end,
				}, {
					PlaceObj('XTemplateAction', {
						'ActionTranslate', false,
					}),
					}),
				}),
			PlaceObj('XTemplateAction', {
				'comment', " (Ctrl-Alt-M)",
				'RolloverText', " (Ctrl-Alt-M)",
				'ActionId', "MapSettingsEditor",
				'ActionTranslate', false,
				'ActionName', "Map Settings",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'ActionShortcut', "Ctrl-Alt-M",
				'OnAction', function (self, host, source)
					local _, window_id = PropEditor_GetFirstWindow("MapSettingsEditor")
					if not window_id then
						local class_names = ClassDescendantsList("MapSettings")
						local classes = {}
						for i = 1, #class_names do
							local class = g_Classes[class_names[i]]
							local data = DataInstances[class.class]
							local obj = table.icopy(data)
							obj.name = class.class
							classes[i] = obj
						end
						PropEditorOpen(MapSettingsEditor:new(classes)) 
					else
						PropEditorActivateWindow(window_id)
					end
				end,
				'replace_matching_id', true,
			}),
			}),
		}),
	PlaceObj('XTemplateAction', {
		'ActionId', "Debug",
		'ActionTranslate', false,
		'ActionName', "Debug",
		'ActionMenubar', "DevMenu",
		'OnActionEffect', "popup",
		'__condition', function (parent, context) return Platform.developer end,
		'replace_matching_id', true,
	}, {
		PlaceObj('XTemplateAction', {
			'comment', "Toggle Hex Build Grid Visibility (Ctrl-F3)",
			'RolloverText', "Toggle Hex Build Grid Visibility (Ctrl-F3)",
			'ActionId', "DE_HexBuildGridToggle",
			'ActionTranslate', false,
			'ActionName', "Toggle Hex Build Grid Visibility",
			'ActionIcon', "CommonAssets/UI/Menu/default.tga",
			'ActionShortcut', "Ctrl-F3",
			'OnAction', function (self, host, source)
				debug_build_grid()
			end,
			'replace_matching_id', true,
		}),
		PlaceObj('XTemplateAction', {
			'comment', "Toggle Terrain Deposit Grid (Ctrl-F4)",
			'RolloverText', "Toggle Terrain Deposit Grid (Ctrl-F4)",
			'ActionId', "DE_ToggleTerrainDepositGrid",
			'ActionTranslate', false,
			'ActionName', "Toggle Terrain Deposit Grid",
			'ActionIcon', "CommonAssets/UI/Menu/default.tga",
			'ActionShortcut', "Ctrl-F4",
			'OnAction', function (self, host, source) ToggleTerrainDepositGrid() end,
			'replace_matching_id', true,
		}),
		PlaceObj('XTemplateAction', {
			'comment', "Toggle Planet Mars Colors",
			'ActionId', "DE_TogglePlanetMarsColors",
			'ActionTranslate', false,
			'ActionName', "Toggle Planet Mars Colors",
			'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
			'OnActionEffect', "popup",
			'replace_matching_id', true,
		}, {
			PlaceObj('XTemplateAction', {
				'comment', "Clear",
				'RolloverText', "Clear Planet Mars Colors",
				'ActionId', "DE_TogglePlanetMarsColorsClear",
				'ActionSortKey', "0",
				'ActionTranslate', false,
				'ActionName', "Clear",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source) DbgShowPlanetColors() end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'comment', "Prefab",
				'RolloverText', "Show Planet Mars Colors - Prefab",
				'ActionId', "DE_TogglePlanetMarsColorsMapName",
				'ActionSortKey', "1",
				'ActionTranslate', false,
				'ActionName', "Prefab Name",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source) DbgShowPlanetColors(DbgPlanetColorsCallbackName) end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'comment', "Topography",
				'RolloverText', "Show Planet Mars Colors - Topography",
				'ActionId', "DE_TogglePlanetMarsColorsMapTopography",
				'ActionSortKey', "2",
				'ActionTranslate', false,
				'ActionName', "Map Topography",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source) DbgShowPlanetColors(DbgPlanetColorsCallbackTopography) end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'comment', "Difficulty",
				'RolloverText', "Show Planet Mars Colors - Difficulty",
				'ActionId', "DE_TogglePlanetMarsColorsMapDifficulty",
				'ActionSortKey', "3",
				'ActionTranslate', false,
				'ActionName', "Game Difficulty",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source) DbgShowPlanetColors(DbgPlanetColorsCallbackDifficulty) end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'comment', "Altitude",
				'RolloverText', "Show Planet Mars Colors - Altitude",
				'ActionId', "DE_TogglePlanetMarsColorsMapChallenge",
				'ActionSortKey', "3",
				'ActionTranslate', false,
				'ActionName', "Overlay Altitude",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source) DbgShowPlanetColors(DbgPlanetColorsCallbackAltitude) end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'comment', "Style",
				'RolloverText', "Show Planet Mars Colors - Style",
				'ActionId', "DE_TogglePlanetMarsColorsMapStyle",
				'ActionSortKey', "4",
				'ActionTranslate', false,
				'ActionName', "Dominant Style",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source)
					DbgShowPlanetColors(DbgPlanetColorsCallbackStyle)
				end,
				'replace_matching_id', true,
			}),
			}),
		PlaceObj('XTemplateAction', {
			'comment', "Test Freeze Map",
			'ActionId', "DE_TestFreezeMap",
			'ActionTranslate', false,
			'ActionName', "Test Freeze Map",
			'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
			'OnActionEffect', "popup",
			'replace_matching_id', true,
		}, {
			PlaceObj('XTemplateAction', {
				'comment', "Ice",
				'RolloverText', "Freeze Entire Map",
				'ActionId', "DE_FreezeEntireMap",
				'ActionSortKey', "5",
				'ActionTranslate', false,
				'ActionName', "Freeze Map",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source) FreezeEntireMap() end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'comment', "Ice",
				'RolloverText', "Unfreeze Entire Map",
				'ActionId', "DE_UnfreezeEntireMap",
				'ActionSortKey', "6",
				'ActionTranslate', false,
				'ActionName', "Unfreeze Map",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source) UnfreezeEntireMap() end,
				'replace_matching_id', true,
			}),
			}),
		}),
	PlaceObj('XTemplateAction', {
		'comment', "Debug place buildings",
		'ActionId', "Buildings",
		'ActionTranslate', false,
		'ActionName', "Buildings",
		'ActionMenubar', "DevMenu",
		'OnActionEffect', "popup",
		'__condition', function (parent, context) return Platform.developer and Platform.editor end,
		'replace_matching_id', true,
	}, {
		PlaceObj('XTemplateAction', {
			'comment', "Demolish (Delete)",
			'RolloverText', "Demolish (Delete)",
			'ActionId', "Demolish",
			'ActionMode', "Game",
			'ActionTranslate', false,
			'ActionName', "Demolish",
			'ActionIcon', "CommonAssets/UI/Menu/default.tga",
			'ActionShortcut', "Delete",
			'OnAction', function (self, host, source)
				if GetInGameInterface() and not g_Tutorial then
					GetInGameInterface():SetMode("demolish")
				end
			end,
			'replace_matching_id', true,
		}),
		PlaceObj('XTemplateAction', {
			'comment', "Power Cables",
			'RolloverText', "Power Cables",
			'ActionId', "Electricity Grid",
			'ActionMode', "Game",
			'ActionTranslate', false,
			'ActionName', "Electricity Grid",
			'ActionIcon', "CommonAssets/UI/Menu/default.tga",
			'OnAction', function (self, host, source)
				if GetInGameInterface() then
					GetInGameInterface():SetMode("electricity_grid")
				end
			end,
			'replace_matching_id', true,
		}),
		PlaceObj('XTemplateAction', {
			'comment', "Pipes",
			'RolloverText', "Pipes",
			'ActionId', "LifeSupport Grid",
			'ActionMode', "Game",
			'ActionTranslate', false,
			'ActionName', "LifeSupport Grid",
			'ActionIcon', "CommonAssets/UI/Menu/default.tga",
			'OnAction', function (self, host, source)
				if GetInGameInterface() then
					GetInGameInterface():SetMode("life_support_grid")
				end
			end,
			'replace_matching_id', true,
		}),
		PlaceObj('XTemplateForEach', {
			'comment', "Folders",
			'array', function (parent, context) return SortedBuildingTemplates end,
			'condition', function (parent, context, item, i) return i % 20 == 1 end,
			'run_before', function (parent, context, item, i, n)
				context.building_start_index = i
			end,
			'run_after', function (child, context, item, i, n)
				child.ActionId = "BuildFolder" .. i
				child.ActionName = item .. ", ..."
			end,
		}, {
			PlaceObj('XTemplateAction', {
				'ActionTranslate', false,
				'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
				'OnActionEffect', "popup",
			}, {
				PlaceObj('XTemplateForEach', {
					'comment', "Buildings in folder",
					'array', function (parent, context) return SortedBuildingTemplates end,
					'condition', function (parent, context, item, i) return i >= context.building_start_index and i < context.building_start_index + 20 end,
					'run_after', function (child, context, item, i, n)
						child.ActionId = "Build" .. item
						child.ActionName = "Place ".. item
						child.ActionMenubar = "BuildFolder" .. context.building_start_index
						child.OnAction = function()
							if IsEditorActive() then
								g_EditorModeDlg = OpenDialog("ConstructionModeDialog", GetEditorInterface(), { template = item })
							elseif GetInGameInterface() then
								GetInGameInterface():SetMode("construction", { template = item })
							end	
						end
					end,
				}, {
					PlaceObj('XTemplateAction', {
						'ActionTranslate', false,
					}),
					}),
				}),
			}),
		}),
	PlaceObj('XTemplateAction', {
		'ActionMode', "Game",
	}, {
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPOCMapAlt0",
			'ActionName', T(727272233433, --[[XTemplate GameShortcuts ActionName]] "Open Empty Map"),
			'ActionShortcut', "Alt-0",
			'OnAction', function (self, host, source)
				CheatChangeMap("POCMap_Alt_00")
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPOCMapAlt1",
			'ActionName', T(4521, --[[XTemplate GameShortcuts ActionName]] "Open POC Map 1"),
			'ActionShortcut', "Alt-1",
			'OnAction', function (self, host, source)
				CheatChangeMap("POCMap_Alt_01")
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPOCMapAlt2",
			'ActionName', T(722962309661, --[[XTemplate GameShortcuts ActionName]] "Open POC Map 2"),
			'ActionShortcut', "Alt-2",
			'OnAction', function (self, host, source)
				CheatChangeMap("POCMap_Alt_02")
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPOCMapAlt3",
			'ActionName', T(753123816124, --[[XTemplate GameShortcuts ActionName]] "Open POC Map 3"),
			'ActionShortcut', "Alt-3",
			'OnAction', function (self, host, source)
				CheatChangeMap("POCMap_Alt_03")
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPOCMapAlt4",
			'ActionName', T(4522, --[[XTemplate GameShortcuts ActionName]] "Open POC Map 4"),
			'ActionShortcut', "Alt-4",
			'OnAction', function (self, host, source)
				CheatChangeMap("POCMap_Alt_04")
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPOCMapAlt5",
			'ActionName', T(6974, --[[XTemplate GameShortcuts ActionName]] "Open POC Map LateGame"),
			'ActionShortcut', "Alt-5",
			'OnAction', function (self, host, source)
				CheatChangeMap("POCMap_LateGame")
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionInGameMainMenu",
			'ActionName', T(152768500780, --[[XTemplate GameShortcuts ActionName]] "Toggle In Game Main Menu"),
			'ActionShortcut', "Escape",
			'ActionGamepad', "Start",
			'OnAction', function (self, host, source)
				local igi = GetInGameInterface()
				local dlg = GetHUD()
				local modal = terminal.desktop:GetModalWindow()
				if igi and dlg and dlg.window_state ~= "destroying" and igi:GetVisible() and (not modal or modal == terminal.desktop) then
					dlg.idMenu:Press()
				else
					CloseIngameMainMenu()
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPanUp",
			'ActionMode', "ForwardToC",
			'ActionName', T(964722863858, --[[XTemplate GameShortcuts ActionName]] "Pan Up"),
			'ActionShortcut', "W",
			'ActionShortcut2', "Up",
			'ActionBindable', true,
			'ActionMouseBindable', false,
			'ActionBindSingleKey', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPanDown",
			'ActionMode', "ForwardToC",
			'ActionName', T(981867141540, --[[XTemplate GameShortcuts ActionName]] "Pan Down"),
			'ActionShortcut', "S",
			'ActionShortcut2', "Down",
			'ActionBindable', true,
			'ActionMouseBindable', false,
			'ActionBindSingleKey', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPanLeft",
			'ActionMode', "ForwardToC",
			'ActionName', T(199913045993, --[[XTemplate GameShortcuts ActionName]] "Pan Left"),
			'ActionShortcut', "A",
			'ActionShortcut2', "Left",
			'ActionBindable', true,
			'ActionMouseBindable', false,
			'ActionBindSingleKey', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPanRight",
			'ActionMode', "ForwardToC",
			'ActionName', T(644017017186, --[[XTemplate GameShortcuts ActionName]] "Pan Right"),
			'ActionShortcut', "D",
			'ActionShortcut2', "Right",
			'ActionBindable', true,
			'ActionMouseBindable', false,
			'ActionBindSingleKey', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionRotLeft",
			'ActionMode', "ForwardToC",
			'ActionName', T(741646947499, --[[XTemplate GameShortcuts ActionName]] "Rotate Camera Left"),
			'ActionShortcut', "Q",
			'ActionBindable', true,
			'ActionMouseBindable', false,
			'ActionBindSingleKey', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionRotRight",
			'ActionMode', "ForwardToC",
			'ActionName', T(892715092566, --[[XTemplate GameShortcuts ActionName]] "Rotate Camera Right"),
			'ActionShortcut', "E",
			'ActionBindable', true,
			'ActionMouseBindable', false,
			'ActionBindSingleKey', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionRotUp",
			'ActionMode', "ForwardToC",
			'ActionName', T(384814720970, --[[XTemplate GameShortcuts ActionName]] "Rotate Camera Up"),
			'ActionShortcut', "F",
			'ActionBindable', true,
			'ActionMouseBindable', false,
			'ActionBindSingleKey', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionRotDown",
			'ActionMode', "ForwardToC",
			'ActionName', T(240317934981, --[[XTemplate GameShortcuts ActionName]] "Rotate Camera Down"),
			'ActionShortcut', "G",
			'ActionBindable', true,
			'ActionMouseBindable', false,
			'ActionBindSingleKey', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionZoomIn",
			'ActionMode', "ForwardToC",
			'ActionName', T(279635353384, --[[XTemplate GameShortcuts ActionName]] "Zoom In"),
			'ActionShortcut', ".",
			'ActionBindable', true,
			'ActionBindSingleKey', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionZoomOut",
			'ActionMode', "ForwardToC",
			'ActionName', T(305580647526, --[[XTemplate GameShortcuts ActionName]] "Zoom Out"),
			'ActionShortcut', ",",
			'ActionBindable', true,
			'ActionBindSingleKey', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionOrbitCamera",
			'ActionMode', "ForwardToC",
			'ActionName', T(969312516259, --[[XTemplate GameShortcuts ActionName]] "Orbit Camera"),
			'ActionShortcut', "Alt",
			'ActionBindable', true,
			'ActionMouseBindable', false,
			'ActionBindSingleKey', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPauseGame",
			'ActionName', T(200927746859, --[[XTemplate GameShortcuts ActionName]] "Pause Game"),
			'ActionShortcut', "Space",
			'ActionShortcut2', "Pause",
			'ActionGamepad', "DPadDown",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if dlg and dlg:GetVisible() then
					if PauseReasons.Debug then Resume("Debug") else TogglePause() end
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionSpeedUp",
			'ActionName', T(933108950407, --[[XTemplate GameShortcuts ActionName]] "Speed Up"),
			'ActionShortcut', "+",
			'ActionShortcut2', "Numpad +",
			'ActionGamepad', "DPadRight",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				if Platform.developer then
					local factor = GetTimeFactor() * 12 / 10
					SetTimeFactor(Clamp(factor, 0, 100000), "sync")
					local current_factor = GetTimeFactor()
					if factor > 0 and factor == current_factor then
						PlayFX("GameSpeedUp", "start")
					end
				elseif GetHUD() then
					ChangeGameSpeedState(1)
				end
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionSpeedDown",
			'ActionName', T(450845916933, --[[XTemplate GameShortcuts ActionName]] "Speed Down"),
			'ActionShortcut', "-",
			'ActionShortcut2', "Numpad -",
			'ActionGamepad', "DPadLeft",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				if Platform.developer then
					local current_factor = GetTimeFactor()
					local new_factor = current_factor * 10 / 12
					if new_factor < current_factor then
						if new_factor == 0 then
							PlayFX("GamePause", "start")
							Msg("MarsPause")
						else
							PlayFX("GameSpeedDown", "start")
						end
					end
					SetTimeFactor(Clamp(new_factor, 0, 100000), "sync")
				elseif GetHUD() then
					ChangeGameSpeedState(-1)
				end
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionToggleHighSpeed",
			'ActionName', T(852738262115, --[[XTemplate GameShortcuts ActionName]] "Toggle High Speed"),
			'ActionShortcut', "Numpad *",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				if UIColony then
					if GetTimeFactor() ~= const.DefaultTimeFactor then
						UIColony:SetGameSpeed(1)
					else
						UIColony:SetGameSpeed(CheatsEnabled() and 10 or 5)
					end
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionRotBuildingLeft",
			'ActionName', T(312752058553, --[[XTemplate GameShortcuts ActionName]] "Rotate Building Left"),
			'ActionShortcut', "R",
			'ActionShortcut2', "Shift-R",
			'ActionGamepad', "LeftShoulder",
			'ActionBindable', true,
			'ActionMouseBindable', false,
			'OnAction', function (self, host, source)
				local obj = GetConstructionController()
				if obj then
					obj:Rotate(-1)
				end
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionRotBuildingRight",
			'ActionName', T(694856081085, --[[XTemplate GameShortcuts ActionName]] "Rotate Building Right"),
			'ActionShortcut', "T",
			'ActionShortcut2', "Shift-T",
			'ActionGamepad', "RightShoulder",
			'ActionBindable', true,
			'ActionMouseBindable', false,
			'OnAction', function (self, host, source)
				local obj = GetConstructionController()
				if obj then
					obj:Rotate(1)
				end
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionOpenBuildMenu",
			'ActionName', T(383281603855, --[[XTemplate GameShortcuts ActionName]] "Build Menu"),
			'ActionShortcut', "B",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				local igi = GetInGameInterface()
				local dlg = GetHUD()
				if igi and dlg and igi:GetVisible() and dlg:GetVisible() and igi.mode == "selection" then
					ToggleXBuildMenu(true, "close")
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionMapOverview",
			'ActionName', T(786525376837, --[[XTemplate GameShortcuts ActionName]] "Map Overview"),
			'ActionShortcut', "M",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				if not g_PhotoMode and ActiveMapData and ActiveMapData.IsAllowedToEnterOverview then
					local igi = GetInGameInterface()
					local dlg = GetHUD()
					if igi and igi:GetVisible() and dlg and dlg:GetVisible() and dlg.window_state ~= "destroying" then
						dlg.idOverview:Press()
					end
					if Platform.developer and not igi then
						ToggleOffGameOverview()
					end
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionToggleResourceIcons",
			'ActionName', T(600243851394, --[[XTemplate GameShortcuts ActionName]] "Toggle Resource Icons"),
			'ActionShortcut', "I",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				ToggleResourceIcons()
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionDeployProbe",
			'ActionName', T(559972871255, --[[XTemplate GameShortcuts ActionName]] "Deploy Orbital Probe"),
			'ActionShortcut', "X",
			'ActionGamepad', "ButtonX",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				DeployOrbitalProbe()
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionResetCamera",
			'ActionName', T(864744602325, --[[XTemplate GameShortcuts ActionName]] "Reset Camera"),
			'ActionShortcut', "Home",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				ResetRTSCamera()
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionRadio",
			'ActionName', T(796804896133, --[[XTemplate GameShortcuts ActionName]] "Radio"),
			'ActionShortcut', "Y",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				local igi = GetInGameInterface()
				local dlg = GetHUD()
				if igi and dlg and dlg:GetVisible() and dlg.window_state ~= "destroying" and igi:GetVisible() and igi.mode_dialog:IsKindOf("UnitDirectionModeDialog") then
					dlg.idRadio:Press()
				else
					CloseDialog("RadioStationDlg")
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionResupplyScreen",
			'ActionName', T(970807214544, --[[XTemplate GameShortcuts ActionName]] "Resupply Screen"),
			'ActionShortcut', "Tab",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				local igi = GetInGameInterface()
				local dlg = GetHUD()
				if igi and dlg and dlg:GetVisible() and dlg.window_state ~= "destroying" and igi:GetVisible() and igi.mode_dialog:IsKindOf("UnitDirectionModeDialog") then
					dlg.idResupply:Press()
				else
					CloseDialog("Resupply")
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionResearchScreen",
			'ActionName', T(771055429123, --[[XTemplate GameShortcuts ActionName]] "Research Screen"),
			'ActionShortcut', "H",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				local igi = GetInGameInterface()
				local dlg = GetHUD()
				if igi and dlg and dlg:GetVisible() and dlg.window_state ~= "destroying" and igi:GetVisible() and igi.mode_dialog:IsKindOf("UnitDirectionModeDialog") then
					dlg.idResearch:Press()
				else
					CloseResearchDialog()
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionMissionProfile",
			'ActionName', T(10092, --[[XTemplate GameShortcuts ActionName]] "Mission Profile"),
			'ActionShortcut', "O",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				local igi = GetInGameInterface()
				local dlg = GetHUD()
				if igi and dlg and dlg:GetVisible() and dlg.window_state ~= "destroying" and igi:GetVisible() and igi.mode_dialog:IsKindOf("UnitDirectionModeDialog") then
					dlg.idGoals:Press()
				else
					CloseDialog("MissionProfileDlg")
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPlanetaryView",
			'ActionName', T(805731420530, --[[XTemplate GameShortcuts ActionName]] "Planetary View"),
			'ActionShortcut', "P",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				local igi = GetInGameInterface()
				local dlg = GetHUD()
				if igi and dlg and dlg:GetVisible() and dlg.window_state ~= "destroying" and igi:GetVisible() and igi.mode_dialog:IsKindOf("UnitDirectionModeDialog") then
					dlg.idPlanetaryView:Press()
				else
					ClosePlanetaryView()
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionColonyControlCenter",
			'ActionName', T(137542936955, --[[XTemplate GameShortcuts ActionName]] "Command Center"),
			'ActionShortcut', "Z",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				local igi = GetInGameInterface()
				local dlg = GetHUD()
				if igi and dlg and dlg:GetVisible() and dlg.window_state ~= "destroying" and igi:GetVisible() and igi.mode_dialog:IsKindOf("UnitDirectionModeDialog") then
					dlg.idColonyControlCenter:Press()
				else
					CloseCommandCenter()
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionMilestonesScreen",
			'ActionName', T(973748367669, --[[XTemplate GameShortcuts ActionName]] "Milestones"),
			'ActionShortcut', "L",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				local igi = GetInGameInterface()
				local dlg = GetHUD()
				if igi and dlg and dlg:GetVisible() and dlg.window_state ~= "destroying" and igi:GetVisible() and igi.mode_dialog:IsKindOf("UnitDirectionModeDialog") then
					dlg.idMilestones:Press()
				else
					 CloseDialog("Milestones")
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionAchievementsScreen",
			'ActionName', T(697482021580, --[[XTemplate GameShortcuts ActionName]] "Achievements"),
			'ActionShortcut', ";",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				if not GameState.gameplay then return end
				local igi = GetInGameInterface()
				local dlg = GetDialog("Achievements")
				local hud = GetHUD()
				if igi and hud and hud:GetVisible() and igi:GetVisible() and igi.mode_dialog:IsKindOf("UnitDirectionModeDialog") then
					OpenDialog("Achievements")
				else
					CloseDialog("Achievements")
				end
			end,
			'IgnoreRepeated', true,
			'__condition', function (parent, context) return not Platform.steam and not Platform.console and not Platform.windows_store end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionNextDome",
			'ActionName', T(7695, --[[XTemplate GameShortcuts ActionName]] "Next Dome"),
			'ActionShortcut', "Pageup",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				NextDome()
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPreviousDome",
			'ActionName', T(411744294712, --[[XTemplate GameShortcuts ActionName]] "Previous Dome"),
			'ActionShortcut', "Pagedown",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				PreviousDome()
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionNextRover",
			'ActionName', T(7696, --[[XTemplate GameShortcuts ActionName]] "Next Rover"),
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				NextRover()
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPreviousRover",
			'ActionName', T(749913145697, --[[XTemplate GameShortcuts ActionName]] "Previous Rover"),
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				PreviousRover()
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionNextBuilding",
			'ActionName', T(447211684750, --[[XTemplate GameShortcuts ActionName]] "Next Building"),
			'ActionShortcut', "\\",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				SelectNextBuildingOfSameType(1)
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPreviousBuilding",
			'ActionName', T(961951175823, --[[XTemplate GameShortcuts ActionName]] "Previous Building"),
			'ActionShortcut', "'",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				SelectNextBuildingOfSameType(-1)
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionToggleDemolish",
			'ActionName', T(936607973592, --[[XTemplate GameShortcuts ActionName]] "Salvage Selected"),
			'ActionToolbar', "SelectedObj",
			'ActionShortcut', "Delete",
			'ActionBindable', true,
			'ActionState', function (self, host)
				return SelectedObj and IsKindOfClasses(SelectedObj, "Demolishable", "LifeSupportGridElement", "ElectricityGridElement") or "disabled"
			end,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				FocusInfopanel = false
				if SelectedObj and IsKindOf(SelectedObj, "Demolishable") and not (g_Tutorial and IsKindOf(SelectedObj, "ConstructionSite")) then
					SelectedObj:ToggleDemolish()
					if SelectedObj then
						RebuildInfopanel(SelectedObj)
					end
				elseif SelectedObj and IsKindOfClasses(SelectedObj, "LifeSupportGridElement", "ElectricityGridElement") then
					SelectedObj:Demolish()
					SelectObj(false)
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionFollowCamera",
			'ActionName', T(10117, --[[XTemplate GameShortcuts ActionName]] "Follow Camera"),
			'ActionToolbar', "SelectedObj",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				local igi = GetInGameInterface()
				local dlg = GetHUD()
				if igi and dlg and dlg:GetVisible() and igi:GetVisible() and igi.mode == "selection" then
					local obj = SelectedObj
					if obj and IsKindOf(obj, "CameraFollowObject") then
						Camera3pFollow(obj)
					end
				end
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionTogglePin",
			'ActionName', T(646525548286, --[[XTemplate GameShortcuts ActionName]] "Pin/Unpin Selected"),
			'ActionToolbar', "SelectedObj",
			'ActionBindable', true,
			'ActionState', function (self, host)
				return SelectedObj and IsKindOf(SelectedObj, "PinnableObject") or "disabled"
			end,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				FocusInfopanel = false
				if SelectedObj and IsKindOf(SelectedObj, "PinnableObject") then
					SelectedObj:TogglePin()
					RebuildInfopanel(SelectedObj)
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionClearAllPins",
			'ActionName', T(463783151661, --[[XTemplate GameShortcuts ActionName]] "Clear Pins"),
			'ActionShortcut', "Alt-P",
			'ActionBindable', true,
			'ActionToggled', function (self, host)  end,
			'ActionState', function (self, host)  end,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				UnpinAll()
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionRenameSelected",
			'ActionName', T(337463951534, --[[XTemplate GameShortcuts ActionName]] "Rename Selected"),
			'ActionToolbar', "SelectedObj",
			'ActionBindable', true,
			'ActionState', function (self, host)
				return SelectedObj and IsKindOf(SelectedObj, "Renamable") or "disabled"
			end,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
					FocusInfopanel = false
				if SelectedObj and IsKindOf(SelectedObj, "Renamable") and SelectedObj.rename_allowed
					and (not SelectedObj:IsKindOf("BaseBuilding") or SelectedObj:GetUIInteractionState()) 
				then
					SelectedObj:ShowRenameUI(source == "gamepad")
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionMoveInteract",
			'ActionName', T(765178809736, --[[XTemplate GameShortcuts ActionName]] "Move / Interact with target"),
			'ActionToolbar', "SelectedObj",
			'ActionGamepad', "RightTrigger-ButtonA",
			'ActionBindable', true,
			'ActionState', function (self, host)
				return SelectedObj and IsKindOf(SelectedObj, "DroneBase") or "disabled"
			end,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				FocusInfopanel = false
				if not SelectedObj or not IsKindOf(SelectedObj, "DroneBase") then return end
				local igi = GetInGameInterface()
				if igi and igi:GetVisible() then
					SelectedObj:ToggleControlMode()
					if source == "gamepad" then
						ActivateControlModeDlgAction()
					end
					RebuildInfopanel(SelectedObj)
				end
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionForceLaunch",
			'ActionName', T(439134274593, --[[XTemplate GameShortcuts ActionName]] "Launch"),
			'ActionToolbar', "SelectedObj",
			'ActionGamepad', "RightTrigger-ButtonX",
			'ActionState', function (self, host)
				return SelectedObj and IsKindOf(SelectedObj, "SupplyRocket") or "disabled"
			end,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				if SelectedObj and IsKindOf(SelectedObj, "SupplyRocket") then
					SelectedObj:UILaunch()
				end
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionLoadResources",
			'ActionName', T(903069926510, --[[XTemplate GameShortcuts ActionName]] "Load resources"),
			'ActionToolbar', "SelectedObj",
			'ActionGamepad', "RightTrigger-ButtonX",
			'ActionBindable', true,
			'ActionState', function (self, host)
				return SelectedObj and IsKindOf(SelectedObj, "RCTransport") or "disabled"
			end,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				FocusInfopanel = false
				if not SelectedObj or not IsKindOf(SelectedObj, "RCTransport") then return end
				local igi = GetInGameInterface()
				if igi and igi:GetVisible() then
					SelectedObj:LoadResource()
					if source == "gamepad" then
						ActivateControlModeDlgAction()
					end
					RebuildInfopanel(SelectedObj)
				end
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionUnloadResources",
			'ActionName', T(231672184710, --[[XTemplate GameShortcuts ActionName]] "Unload resources"),
			'ActionToolbar', "SelectedObj",
			'ActionGamepad', "RightTrigger-ButtonY",
			'ActionBindable', true,
			'ActionState', function (self, host)
				return SelectedObj and IsKindOf(SelectedObj, "RCTransport") or "disabled"
			end,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				FocusInfopanel = false
				if not SelectedObj or not IsKindOf(SelectedObj, "RCTransport") then return end
				local igi = GetInGameInterface()
				if igi and igi:GetVisible() then
					SelectedObj:UnloadResource()
					if source == "gamepad" then
						ActivateControlModeDlgAction()
					end
					RebuildInfopanel(SelectedObj)
				end
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionReassignDrone",
			'ActionName', T(715125537239, --[[XTemplate GameShortcuts ActionName]] "Reassign"),
			'ActionToolbar', "SelectedObj",
			'ActionGamepad', "RightTrigger-ButtonY",
			'ActionBindable', true,
			'ActionState', function (self, host)
				return SelectedObj and IsKindOf(SelectedObj, "Drone") or "disabled"
			end,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				FocusInfopanel = false
				if not SelectedObj or not IsKindOf(SelectedObj, "Drone") then return end
				local igi = GetInGameInterface()
				if igi and igi:GetVisible() then
					SelectedObj:ToggleReassignInteractionMode()
					if source == "gamepad" then
						ActivateControlModeDlgAction()
					end
					RebuildInfopanel(SelectedObj)
				end
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionAssignToBuilding",
			'ActionName', T(8761, --[[XTemplate GameShortcuts ActionName]] "Assign To Building"),
			'ActionToolbar', "SelectedObj",
			'ActionGamepad', "RightTrigger-ButtonA",
			'ActionBindable', true,
			'ActionState', function (self, host)
				return IsKindOf(SelectedObj, "Colonist") or "disabled"
			end,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				FocusInfopanel = false
				if not IsKindOf(SelectedObj, "Colonist") or SelectedObj.traits.Renegade then return end
				local igi = GetInGameInterface()
				if igi and igi:GetVisible() then
					SelectedObj:ToggleInteraction()
					if source == "gamepad" then
						ActivateControlModeDlgAction()
					end
					RebuildInfopanel(SelectedObj)
				end
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPriority",
			'ActionName', T(949156525062, --[[XTemplate GameShortcuts ActionName]] "Change priority"),
			'ActionToolbar', "SelectedObj",
			'ActionGamepad', "RightTrigger-ButtonA",
			'ActionBindable', true,
			'ActionState', function (self, host)
				return IsKindOf(SelectedObj, "Building") and SelectedObj.prio_button or "disabled"
			end,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				FocusInfopanel = false
				if not IsKindOf(SelectedObj, "Building") or not SelectedObj.prio_button or not SelectedObj:GetUIInteractionState()  then return end
				SelectedObj:TogglePriority(1)
				RebuildInfopanel(SelectedObj)
			end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionOnOff",
			'ActionName', T(643321767698, --[[XTemplate GameShortcuts ActionName]] "Turn on/off"),
			'ActionToolbar', "SelectedObj",
			'ActionGamepad', "RightTrigger-ButtonY",
			'ActionBindable', true,
			'ActionState', function (self, host)
				if IsKindOf(SelectedObj, "Building") and SelectedObj.on_off_button and SelectedObj:GetUIInteractionState() then
						if not (IsKindOf(SelectedObj, "ConstructionSite") and SelectedObj.building_class == "BlackCubeMonolith") then
							return SelectedObj.on_off_button
						end			
					end
					return "disabled"
			end,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				FocusInfopanel = false
				if not IsKindOf(SelectedObj, "Building") or not SelectedObj.on_off_button or (IsKindOf(SelectedObj, "ConstructionSite") and SelectedObj.building_class== "BlackCubeMonolith") or not SelectedObj:GetUIInteractionState() then return end
				SelectedObj:ToggleWorking()
				RebuildInfopanel(SelectedObj)
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionDomeFilter",
			'ActionName', T(204031300524, --[[XTemplate GameShortcuts ActionName]] "Filter colonists by traits"),
			'ActionToolbar', "SelectedObj",
			'ActionGamepad', "RightTrigger-ButtonX",
			'ActionBindable', true,
			'ActionState', function (self, host)
				return IsKindOf(SelectedObj, "Dome") or "disabled"
			end,
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				FocusInfopanel = false
				if not IsKindOf(SelectedObj, "Dome") or not SelectedObj:GetUIInteractionState() then return end
				SelectedObj:OpenFilterTraits()
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionLastNotification",
			'ActionName', T(748588275043, --[[XTemplate GameShortcuts ActionName]] "Last Notification"),
			'ActionShortcut', "Backspace",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				local igi = GetInGameInterface()
				if not igi or not igi:GetVisible() then return end
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				local dlg = GetDialog("OnScreenNotificationsDlg")
				local notifications = dlg and dlg.idNotifications
				if dlg and #notifications > 0 then
					notifications[#notifications].idButton:Press()
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionLastConstructed",
			'ActionName', T(614477738289, --[[XTemplate GameShortcuts ActionName]] "Last Constructed Building"),
			'ActionShortcut', "End",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				local igi = GetInGameInterface()
				if not igi or not igi:GetVisible() then return end
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				local bld = UICity and UICity.LastConstructedBuilding
				if bld then
					if IsValid(bld) then
						ViewAndSelectObject(bld)
					end
				end
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPlaceCable",
			'ActionName', T(881, --[[XTemplate GameShortcuts ActionName]] "Power Cables"),
			'ActionShortcut', "C",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				if g_Tutorial and g_Tutorial.BuildMenuWhitelist and not g_Tutorial.BuildMenuWhitelist.PowerCables then return end
				local igi = GetInGameInterface()
				if not igi or not igi:GetVisible() then return end
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				local require_construction = not(g_Consts and g_Consts.InstantCables ~= 0)
				igi:SetMode("electricity_grid", {grid_elements_require_construction = require_construction})
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionPlacePipes",
			'ActionName', T(882, --[[XTemplate GameShortcuts ActionName]] "Pipes"),
			'ActionShortcut', "V",
			'ActionBindable', true,
			'OnAction', function (self, host, source)
				if g_Tutorial and g_Tutorial.BuildMenuWhitelist and not g_Tutorial.BuildMenuWhitelist.Pipes then return end
				local igi = GetInGameInterface()
				if not igi or not igi:GetVisible() then return end
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				local require_construction = not(g_Consts and g_Consts.InstantPipes ~= 0)
				igi:SetMode("life_support_grid", {grid_elements_require_construction = require_construction})
			end,
			'IgnoreRepeated', true,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "actionToggleFullscreen",
			'ActionShortcut', "Alt-Enter",
			'OnAction', function (self, host, source)
				ToggleFullscreen()
			end,
		}),
		PlaceObj('XTemplateAction', {
			'comment', "Show Last Hint (F1)",
			'ActionId', "ShowHints",
			'ActionTranslate', false,
			'ActionIcon', "CommonAssets/UI/Menu/default.tga",
			'ActionShortcut', "F1",
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				ShowLastHint()
			end,
			'replace_matching_id', true,
		}),
		PlaceObj('XTemplateAction', {
			'comment', "Toggles selected rover control mode. (-Ctrl)",
			'ActionId', "RoverControlModeStop",
			'ActionTranslate', false,
			'ActionIcon', "CommonAssets/UI/Menu/default.tga",
			'ActionShortcut', "-Ctrl",
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				if IsValid(SelectedObj) and IsKindOfClasses(SelectedObj, "DroneBase") and not GetDialog("ResourceItems") then
					SelectedObj:SetControlMode(false)
					return "break"
				end
			end,
			'replace_matching_id', true,
		}),
		PlaceObj('XTemplateAction', {
			'comment', "Toggles selected rover control mode. (Ctrl)",
			'ActionId', "RoverControlMode",
			'ActionTranslate', false,
			'ActionIcon', "CommonAssets/UI/Menu/default.tga",
			'ActionShortcut', "Ctrl",
			'OnAction', function (self, host, source)
				local dlg = GetHUD()
				if not dlg or not dlg:GetVisible() then return end
				if IsValid(SelectedObj) and IsKindOfClasses(SelectedObj, "DroneBase") and not GetDialog("ResourceItems") then
					SelectedObj:SetControlMode(true)
					return "break"
				end
			end,
			'replace_matching_id', true,
		}),
		PlaceObj('XTemplateForEach', {
			'comment', "buildings",
			'array', function (parent, context) local t = table.values(BuildingTemplates or empty_table) TSort(t, "display_name") return t end,
			'condition', function (parent, context, item, i) return item.key_bindable and item.build_category ~= "Hidden" end,
			'run_after', function (child, context, item, i, n)
				child.OnActionParam = item.id
				child.ActionName = item.display_name
				child.ActionId = "actionBuild" .. item.id
				child.ActionShortcut = item.build_shortcut1
				child.ActionShortcut2 = item.build_shortcut2
				child.ActionGamepad = item.build_shortcut_gamepad
				child:BindShortcuts()
			end,
		}, {
			PlaceObj('XTemplateAction', {
				'ActionBindable', true,
				'OnAction', function (self, host, source)
					local igi = GetInGameInterface()
					if not igi or not igi:GetVisible() then return end
					local dlg = GetHUD()
					if not dlg or not dlg:GetVisible() then return end
					local id = self.OnActionParam
					if id == "Passage" then
						if not g_Tutorial or not g_Tutorial.BuildMenuWhitelist or g_Tutorial.BuildMenuWhitelist.Passage then
							GetInGameInterface():SetMode("passage_grid", {grid_elements_require_construction = g_Consts.InstantPassages == 0})
						end
						return
					elseif id == "PassageRamp" then
						if not g_Tutorial or not g_Tutorial.BuildMenuWhitelist or g_Tutorial.BuildMenuWhitelist.PassageRamp then
							GetInGameInterface():SetMode("passage_ramp")
						end
						return
					end
					local bld_template = BuildingTemplates[id]
					local show, prefabs, can_build, action = UIGetBuildingPrerequisites(bld_template.build_category, bld_template, true)
					if show then
						local items
						local subcategory = BuildMenuSubcategories[bld_template.build_category]
						if subcategory and subcategory.allow_template_variants then
							local variants = UIItemMenu(bld_template.build_category, true)
							for i = #variants, 1, -1 do
								if not variants[i].enabled then
									table.remove(variants,i)
								end
							end
							items = table.values(variants, false, "name")
						end
						action(nil, {enabled = can_build, name = bld_template.id, construction_mode = bld_template.construction_mode, template_variants = items})
						CloseXBuildMenu()
					end
				end,
				'IgnoreRepeated', true,
			}),
			}),
		}),
	PlaceObj('XTemplateAction', {
		'comment', "Write upsampled screenshot (-Ctrl-PrtScr)",
		'ActionId', "DE_ToggleScreenshotInterface",
		'ActionTranslate', false,
		'ActionIcon', "CommonAssets/UI/Menu/default.tga",
		'ActionShortcut', "-Ctrl-PrtScr",
		'OnAction', function (self, host, source)
			CreateRealTimeThread(function()
				hr.InterfaceInScreenshot = 0
				WaitNextFrame(3)
				LockCamera("Screenshot")
				MovieWriteScreenshot(GenerateScreenshotFilename("aa", "AppData/"), 0, 32, false)
				UnlockCamera("Screenshot")
			end)
		end,
		'replace_matching_id', true,
	}),
	PlaceObj('XTemplateAction', {
		'comment', "Write upsampled screenshot (-PrtScr)",
		'ActionId', "UpsampledScreenshot",
		'ActionTranslate', false,
		'ActionIcon', "CommonAssets/UI/Menu/default.tga",
		'ActionShortcut', "-PrtScr",
		'OnAction', function (self, host, source)
			CreateRealTimeThread(function()
				table.change(hr, "print_screen", {
					InterfaceInScreenshot = 1,
				})
				WaitNextFrame(3)
				LockCamera("Screenshot")
				MovieWriteScreenshot(GenerateScreenshotFilename("aa", "AppData/"), 0, 32, false)
				UnlockCamera("Screenshot")
				table.restore(hr, "print_screen")
			end)
		end,
		'replace_matching_id', true,
	}),
})

