-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	group = "Shortcuts",
	id = "GameCheatShortcuts",
	PlaceObj('XTemplateAction', {
		'ActionMode', "Game",
	}, {
		PlaceObj('XTemplateAction', {
			'ActionId', "Cheats",
			'ActionTranslate', false,
			'ActionName', "Cheats",
			'ActionMenubar', "DevMenu",
			'OnActionEffect', "popup",
			'__condition', function (parent, context) return Platform.editor end,
			'replace_matching_id', true,
		}, {
			PlaceObj('XTemplateAction', {
				'ActionId', "Cheats.Map Exploration",
				'ActionTranslate', false,
				'ActionName', "Map Exploration ...",
				'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
				'OnActionEffect', "popup",
				'replace_matching_id', true,
			}, {
				PlaceObj('XTemplateAction', {
					'comment', "Reveal all Deposits (all)",
					'RolloverText', "Reveal all Deposits (all)",
					'ActionId', "MapExplorationScan",
					'ActionTranslate', false,
					'ActionName', "Scan Map",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatMapExplore("scanned")
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Reveal all deposits level 1 and above",
					'RolloverText', "Reveal all deposits level 1 and above",
					'ActionId', "MapExplorationDeepScan",
					'ActionTranslate', false,
					'ActionName', "Deep Scan Map",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatMapExplore("deep scanned")
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Scan queued sectors",
					'RolloverText', "Scan queued sectors",
					'ActionId', "MapExplorationScanQueued",
					'ActionTranslate', false,
					'ActionName', "Scan Queued",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatMapExplore("scan queued")
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Spawn Special Projects",
					'RolloverText', "Spawn one special project of each type",
					'ActionId', "CheatSpawnSpecialProjects",
					'ActionTranslate', false,
					'ActionName', "Spawn Special Projects",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatSpawnSpecialProjects()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Spawn Planetary Anomalies",
					'ActionId', "CheatSpawnPlanetaryAnomalies",
					'ActionTranslate', false,
					'ActionName', "Spawn Planetary Anomalies",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatSpawnPlanetaryAnomalies()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Batch Spawn Planetary Anomalies with at least 1 Breakthrough",
					'ActionId', "CheatBatchSpawnPlanetaryAnomalies",
					'ActionTranslate', false,
					'ActionName', "Spawn Planetary Anomalies (batch)",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
							CheatBatchSpawnPlanetaryAnomalies()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Scan Revealed Anomalies",
					'RolloverText', "Scan all revealed anomalies.",
					'ActionId', "G_ScanAllAnomalies",
					'ActionTranslate', false,
					'ActionName', "Scan Revealed Anomalies",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
							ScanAllAnomalies()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Reveal Underground Darkness Toggle",
					'RolloverText', "Reveal Underground Darkness Toggle",
					'ActionId', "RevealUndergroundDarknessToggle",
					'ActionTranslate', false,
					'ActionName', "Reveal Underground Darkness Toggle",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if CheatsEnabled() and UIColony then
							UIColony:RevealUndergroundDarkness(UIColony.underground_map_revealed)
						end
					end,
					'__condition', function (parent, context) return IsDlcAccessible("picard") end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Unlock Underground",
					'RolloverText', "Unlock Underground",
					'ActionId', "UnlockUnderground",
					'ActionTranslate', false,
					'ActionName', "Unlock Underground",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if CheatsEnabled() and UIColony then
							UIColony:UnlockUnderground()
						end
					end,
					'__condition', function (parent, context) return IsDlcAccessible("picard") end,
					'replace_matching_id', true,
				}),
				}),
			PlaceObj('XTemplateAction', {
				'ActionId', "Cheats.Terraforming",
				'ActionTranslate', false,
				'ActionName', "Terraforming ...",
				'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
				'OnActionEffect', "popup",
				'replace_matching_id', true,
			}, {
				PlaceObj('XTemplateAction', {
					'ActionId', "TP_Atmosphere",
					'ActionSortKey', "10",
					'ActionTranslate', false,
					'ActionName', "TP Atmosphere +10%",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatChangeTerraformingParamPct("Atmosphere", 10)
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "TP_Water",
					'ActionSortKey', "20",
					'ActionTranslate', false,
					'ActionName', "TP Water +10%",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatChangeTerraformingParamPct("Water", 10)
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "TP_Temperature",
					'ActionSortKey', "30",
					'ActionTranslate', false,
					'ActionName', "TP Temperature +10%",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatChangeTerraformingParamPct("Temperature", 10)
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "TP_Vegetation",
					'ActionSortKey', "40",
					'ActionTranslate', false,
					'ActionName', "TP Vegetation +10%",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatChangeTerraformingParamPct("Vegetation", 10)
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "TP_IncreaseAll",
					'ActionSortKey', "50",
					'ActionTranslate', false,
					'ActionName', "Increase all Terraforming Parameters by 10%",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						for param in pairs(Terraforming) do
							CheatChangeTerraformingParamPct(param, 10)
						end
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "TP_DecreaseAll",
					'ActionSortKey', "60",
					'ActionTranslate', false,
					'ActionName', "Decrease all Terraforming Parameters by 10%",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						for param in pairs(Terraforming) do
							CheatChangeTerraformingParamPct(param, -10)
						end
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "TP_MaxAll",
					'ActionSortKey', "61",
					'ActionTranslate', false,
					'ActionName', "Max All Terraforming Parameters",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						for param in pairs(Terraforming) do
							CheatSetTerraformingParamPct(param, 100)
						end
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "TP_ResetAll",
					'ActionSortKey', "62",
					'ActionTranslate', false,
					'ActionName', "Reset All Terraforming Parameters",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						for param in pairs(Terraforming) do
							CheatSetTerraformingParamPct(param, 0)
						end
					end,
					'replace_matching_id', true,
				}),
				}),
			PlaceObj('XTemplateAction', {
				'ActionId', "Cheats.Vegetation",
				'ActionTranslate', false,
				'ActionName', "Vegetation ...",
				'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
				'OnActionEffect', "popup",
				'replace_matching_id', true,
			}, {
				PlaceObj('XTemplateAction', {
					'ActionId', "VG_SpeedDefault",
					'ActionSortKey', "10",
					'ActionTranslate', false,
					'ActionName', "Default Growth Speed",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatSetVegGrowthModifier(100)
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "VG_SpeedFast",
					'ActionSortKey', "20",
					'ActionTranslate', false,
					'ActionName', "Fast Growth Speed",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatSetVegGrowthModifier(500)
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "VG_SpeedVeryFast",
					'ActionSortKey', "30",
					'ActionTranslate', false,
					'ActionName', "Very Fast Growth Speed",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatSetVegGrowthModifier(1000)
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "VG_NoWither",
					'ActionSortKey', "40",
					'ActionTranslate', false,
					'ActionName', "Toggle Ignore Requirements",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatToggleNoWither()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "VG_ForceWither",
					'ActionSortKey', "50",
					'ActionTranslate', false,
					'ActionName', "Toggle Force Wither",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatToggleForceWither()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "VG_Unlock",
					'ActionSortKey', "60",
					'ActionTranslate', false,
					'ActionName', "Unlock All Vegetation Plants",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatUnlockAllVegetationPlants()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "Soil_TargetIncrease",
					'ActionSortKey', "70",
					'ActionTranslate', false,
					'ActionName', "Increase Soil Quality by 25%",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatChangeSoilQuality(25)
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "Soil_TargetDecrease",
					'ActionSortKey', "80",
					'ActionTranslate', false,
					'ActionName', "Decrease Soil Quality by 25%",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatChangeSoilQuality(-25)
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "Soil_ToggleOverlay",
					'ActionSortKey', "90",
					'ActionTranslate', false,
					'ActionName', "Toggle Soil Overlay",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatToggleSoilTransparentOverlay()
					end,
					'replace_matching_id', true,
				}),
				}),
			PlaceObj('XTemplateAction', {
				'ActionId', "Cheats.Change Map",
				'ActionTranslate', false,
				'ActionName', "Change Map ...",
				'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
				'OnActionEffect', "popup",
				'replace_matching_id', true,
			}, {
				PlaceObj('XTemplateAction', {
					'ActionId', "ChangeMapEmpty",
					'ActionTranslate', false,
					'ActionName', "Empty Map",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatChangeMap("POCMap_Alt_00")
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "ChangeMapPocMapAlt1",
					'ActionTranslate', false,
					'ActionName', "Phase 1",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatChangeMap("POCMap_Alt_01")
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "ChangeMapPocMapAlt2",
					'ActionTranslate', false,
					'ActionName', "Phase 2 (Early)",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatChangeMap("POCMap_Alt_02")
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "ChangeMapPocMapAlt3",
					'ActionTranslate', false,
					'ActionName', "Phase 2 (Late)",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatChangeMap("POCMap_Alt_03")
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "ChangeMapPocMapAlt4",
					'ActionTranslate', false,
					'ActionName', "Phase 3",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatChangeMap("POCMap_Alt_04")
					end,
					'replace_matching_id', true,
				}),
				}),
			PlaceObj('XTemplateAction', {
				'ActionId', "Cheats.Trigger Disaster",
				'ActionTranslate', false,
				'ActionName', "Trigger Disaster ...",
				'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
				'OnActionEffect', "popup",
				'replace_matching_id', true,
			}, {
				PlaceObj('XTemplateAction', {
					'ActionId', "Cheats.Trigger Disaster Dust Devil",
					'ActionSortKey', "1",
					'ActionTranslate', false,
					'ActionName', "Dust Devil...",
					'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
					'OnActionEffect', "popup",
					'replace_matching_id', true,
				}, {
					PlaceObj('XTemplateForEach', {
						'comment', "dust devil",
						'array', function (parent, context) return DataInstanceCombo("MapSettings_DustDevils")() end,
						'run_after', function (child, context, item, i, n)
							child.ActionId = "TriggerDisaster" .. item
							child.ActionName = item
							child.ActionSortKey = tostring(i)
							child.OnAction = function()
								if not CheatsEnabled() then return end
								CheatDustDevil(false, item)
							end
						end,
					}, {
						PlaceObj('XTemplateAction', {
							'ActionTranslate', false,
							'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						}),
						}),
					PlaceObj('XTemplateAction', {
						'comment', "Dust Devil",
						'RolloverText', "Dust Devil",
						'ActionId', "TriggerDisasterDustDevil",
						'ActionSortKey', "0",
						'ActionTranslate', false,
						'ActionName', "Default Dust Devil",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							if not CheatsEnabled() then return end
							CheatDustDevil()
						end,
						'replace_matching_id', true,
					}),
					}),
				PlaceObj('XTemplateAction', {
					'ActionId', "Cheats.Trigger Disaster Dust Devil Major",
					'ActionSortKey', "2",
					'ActionTranslate', false,
					'ActionName', "Dust Devil Major...",
					'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
					'OnActionEffect', "popup",
					'replace_matching_id', true,
				}, {
					PlaceObj('XTemplateForEach', {
						'comment', "major dust devil",
						'array', function (parent, context) return DataInstanceCombo("MapSettings_DustDevils")() end,
						'run_after', function (child, context, item, i, n)
							child.ActionId = "TriggerDisaster" .. item .. "Major"
							child.ActionName = "Major " .. item
							child.ActionSortKey = tostring(i)
							child.OnAction = function()
								if not CheatsEnabled() then return end
								CheatDustDevil("major", item)
							end
						end,
					}, {
						PlaceObj('XTemplateAction', {
							'ActionTranslate', false,
							'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						}),
						}),
					PlaceObj('XTemplateAction', {
						'comment', "Dust Devil",
						'RolloverText', "Major Dust Devil",
						'ActionId', "TriggerDisasterDustDevilMajor",
						'ActionSortKey', "0",
						'ActionTranslate', false,
						'ActionName', "Default Major Dust Devil",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							if not CheatsEnabled() then return end
							CheatDustDevil("major")
						end,
						'replace_matching_id', true,
					}),
					}),
				PlaceObj('XTemplateAction', {
					'ActionId', "Cheats.Trigger Disaster Dust Storm",
					'ActionSortKey', "3",
					'ActionTranslate', false,
					'ActionName', "Dust Storm...",
					'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
					'OnActionEffect', "popup",
					'replace_matching_id', true,
				}, {
					PlaceObj('XTemplateForEach', {
						'comment', "dust storm",
						'array', function (parent, context) return DataInstanceCombo("MapSettings_DustStorm")() end,
						'run_after', function (child, context, item, i, n)
							child.ActionId = "TriggerDisaster" .. item
							child.ActionName = item
							child.ActionSortKey = tostring(i)
							child.OnAction = function()
								if not CheatsEnabled() then return end
								CheatDustStorm("normal", item)
							end
						end,
					}, {
						PlaceObj('XTemplateAction', {
							'ActionTranslate', false,
							'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						}),
						}),
					PlaceObj('XTemplateAction', {
						'comment', "Dust Storm",
						'RolloverText', "Dust Storm",
						'ActionId', "TriggerDisasterDustStormNormal",
						'ActionSortKey', "0",
						'ActionTranslate', false,
						'ActionName', "Default Dust Storm",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							if not CheatsEnabled() then return end
							CheatDustStorm("normal")
						end,
						'replace_matching_id', true,
					}),
					}),
				PlaceObj('XTemplateAction', {
					'ActionId', "Cheats.Trigger Disaster Dust Storm Great",
					'ActionSortKey', "4",
					'ActionTranslate', false,
					'ActionName', "Dust Storm Great...",
					'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
					'OnActionEffect', "popup",
					'replace_matching_id', true,
				}, {
					PlaceObj('XTemplateForEach', {
						'comment', "great dust storm",
						'array', function (parent, context) return DataInstanceCombo("MapSettings_DustStorm")() end,
						'run_after', function (child, context, item, i, n)
							child.ActionId = "TriggerDisaster" .. item .. "Great"
							child.ActionName = "Great " .. item
							child.ActionSortKey = tostring(i)
							child.OnAction = function()
								if not CheatsEnabled() then return end
								CheatDustStorm("great", item)
							end
						end,
					}, {
						PlaceObj('XTemplateAction', {
							'ActionTranslate', false,
							'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						}),
						}),
					PlaceObj('XTemplateAction', {
						'comment', "Dust Storm",
						'RolloverText', "Dust Storm",
						'ActionId', "TriggerDisasterDustStormGreat",
						'ActionSortKey', "0",
						'ActionTranslate', false,
						'ActionName', "Default Great Dust Storm",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							if not CheatsEnabled() then return end
							CheatDustStorm("great")
						end,
						'replace_matching_id', true,
					}),
					}),
				PlaceObj('XTemplateAction', {
					'ActionId', "Cheats.Trigger Disaster Dust Storm Electrostatic",
					'ActionSortKey', "5",
					'ActionTranslate', false,
					'ActionName', "Dust Storm Electrostatic...",
					'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
					'OnActionEffect', "popup",
					'replace_matching_id', true,
				}, {
					PlaceObj('XTemplateForEach', {
						'comment', "electrostatic dust storm",
						'array', function (parent, context) return DataInstanceCombo("MapSettings_DustStorm")() end,
						'run_after', function (child, context, item, i, n)
							child.ActionId = "TriggerDisaster" .. item .. "Electrostatic"
							child.ActionName = "Electrostatic " .. item
							child.ActionSortKey = tostring(i)
							child.OnAction = function()
								if not CheatsEnabled() then return end
								CheatDustStorm("electrostatic", item)
							end
						end,
					}, {
						PlaceObj('XTemplateAction', {
							'ActionTranslate', false,
							'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						}),
						}),
					PlaceObj('XTemplateAction', {
						'comment', "Dust Storm",
						'RolloverText', "Dust Storm",
						'ActionId', "TriggerDisasterDustStormElectrostatic",
						'ActionSortKey', "0",
						'ActionTranslate', false,
						'ActionName', "Default Electrostatic Dust Storm",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							if not CheatsEnabled() then return end
							CheatDustStorm("electrostatic")
						end,
						'replace_matching_id', true,
					}),
					}),
				PlaceObj('XTemplateAction', {
					'ActionId', "Cheats.Trigger Disaster Cold Wave",
					'ActionSortKey', "6",
					'ActionTranslate', false,
					'ActionName', "Cold Wave...",
					'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
					'OnActionEffect', "popup",
					'replace_matching_id', true,
				}, {
					PlaceObj('XTemplateForEach', {
						'comment', "cold wave",
						'array', function (parent, context) return DataInstanceCombo("MapSettings_ColdWave")() end,
						'run_after', function (child, context, item, i, n)
							child.ActionId = "TriggerDisaster" .. item
							child.ActionName = item
							child.ActionSortKey = tostring(i)
							child.OnAction = function()
								if not CheatsEnabled() then return end
								CheatColdWave(item)
							end
						end,
					}, {
						PlaceObj('XTemplateAction', {
							'ActionTranslate', false,
							'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						}),
						}),
					PlaceObj('XTemplateAction', {
						'comment', "Cold Wave",
						'RolloverText', "Cold Wave",
						'ActionId', "TriggerDisasterColdWave",
						'ActionSortKey', "0",
						'ActionTranslate', false,
						'ActionName', "Default Cold Wave",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							if not CheatsEnabled() then return end
							CheatColdWave()
						end,
						'replace_matching_id', true,
					}),
					}),
				PlaceObj('XTemplateAction', {
					'ActionId', "Cheats.Trigger Disaster Meteor",
					'ActionSortKey', "7",
					'ActionTranslate', false,
					'ActionName', "Meteor...",
					'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
					'OnActionEffect', "popup",
					'replace_matching_id', true,
				}, {
					PlaceObj('XTemplateForEach', {
						'comment', "meteor",
						'array', function (parent, context) return DataInstanceCombo("MapSettings_Meteor")() end,
						'run_after', function (child, context, item, i, n)
							child.ActionId = "TriggerDisaster" .. item
							child.ActionName = item
							child.ActionSortKey = tostring(i)
							child.OnAction = function()
								if not CheatsEnabled() then return end
								CheatMeteors("single", item)
							end
						end,
					}, {
						PlaceObj('XTemplateAction', {
							'ActionTranslate', false,
							'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						}),
						}),
					PlaceObj('XTemplateAction', {
						'comment', "Meteors",
						'RolloverText', "Meteors",
						'ActionId', "TriggerDisasterMeteorsSingle",
						'ActionSortKey', "0",
						'ActionTranslate', false,
						'ActionName', "Default Meteors Single",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							if not CheatsEnabled() then return end
							CheatMeteors("single")
						end,
						'replace_matching_id', true,
					}),
					}),
				PlaceObj('XTemplateAction', {
					'ActionId', "Cheats.Trigger Disaster Meteor Multi Spawn",
					'ActionSortKey', "8",
					'ActionTranslate', false,
					'ActionName', "Meteor Multi Spawn...",
					'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
					'OnActionEffect', "popup",
					'replace_matching_id', true,
				}, {
					PlaceObj('XTemplateForEach', {
						'comment', "multi spawn meteor",
						'array', function (parent, context) return DataInstanceCombo("MapSettings_Meteor")() end,
						'run_after', function (child, context, item, i, n)
							child.ActionId = "TriggerDisaster" .. item .. "MultiSpawn"
							child.ActionName = "Multi Spawn " .. item
							child.ActionSortKey = tostring(i)
							child.OnAction = function()
								if not CheatsEnabled() then return end
								CheatMeteors("multispawn", item)
							end
						end,
					}, {
						PlaceObj('XTemplateAction', {
							'ActionTranslate', false,
							'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						}),
						}),
					PlaceObj('XTemplateAction', {
						'comment', "Meteors",
						'RolloverText', "Meteors",
						'ActionId', "TriggerDisasterMeteorsMultiSpawn",
						'ActionSortKey', "0",
						'ActionTranslate', false,
						'ActionName', "Default Meteors Multi Spawn",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							if not CheatsEnabled() then return end
							CheatMeteors("multispawn")
						end,
						'replace_matching_id', true,
					}),
					}),
				PlaceObj('XTemplateAction', {
					'ActionId', "Cheats.Trigger Disaster Meteor Storm",
					'ActionSortKey', "9",
					'ActionTranslate', false,
					'ActionName', "Meteor Storm...",
					'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
					'OnActionEffect', "popup",
					'replace_matching_id', true,
				}, {
					PlaceObj('XTemplateForEach', {
						'comment', "meteor storm",
						'array', function (parent, context) return DataInstanceCombo("MapSettings_Meteor")() end,
						'run_after', function (child, context, item, i, n)
							child.ActionId = "TriggerDisaster" .. item .. "Storm"
							child.ActionName = "Storm " .. item
							child.ActionSortKey = tostring(i)
							child.OnAction = function()
								if not CheatsEnabled() then return end
								CheatMeteors("storm", item)
							end
						end,
					}, {
						PlaceObj('XTemplateAction', {
							'ActionTranslate', false,
							'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						}),
						}),
					PlaceObj('XTemplateAction', {
						'comment', "Meteors",
						'RolloverText', "Meteors",
						'ActionId', "TriggerDisasterMeteorsStorm",
						'ActionSortKey', "0",
						'ActionTranslate', false,
						'ActionName', "Default Meteors Storm",
						'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						'OnAction', function (self, host, source)
							if not CheatsEnabled() then return end
							CheatMeteors("storm")
						end,
						'replace_matching_id', true,
					}),
					}),
				PlaceObj('XTemplateAction', {
					'ActionId', "Cheats.Trigger Disaster Toxic Rains",
					'ActionSortKey', "10",
					'ActionName', T(558613651480, --[[XTemplate GameCheatShortcuts ActionName]] "Toxic Rains"),
					'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
					'OnActionEffect', "popup",
					'__condition', function (parent, context) return IsDlcAvailable("armstrong") end,
					'replace_matching_id', true,
				}, {
					PlaceObj('XTemplateForEach', {
						'comment', "toxic rains",
						'array', function (parent, context) return DataInstanceCombo("MapSettings_RainsDisaster")() end,
						'condition', function (parent, context, item, i) return DataInstances.MapSettings_RainsDisaster[item].type == "toxic" end,
						'run_after', function (child, context, item, i, n)
							child.ActionId = "TriggerDisaster" .. item .. "ToxicRain"
							child.ActionName = "Rain " .. item
							child.ActionSortKey = tostring(i)
							child.OnAction = function()
								if not CheatsEnabled() then return end
								CheatRainsDisaster(item)
							end
						end,
					}, {
						PlaceObj('XTemplateAction', {
							'ActionTranslate', false,
							'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						}),
						}),
					}),
				PlaceObj('XTemplateAction', {
					'ActionId', "Cheats.Trigger Disaster Water Rains",
					'ActionSortKey', "10",
					'ActionName', T(435194581681, --[[XTemplate GameCheatShortcuts ActionName]] "Water Rains"),
					'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
					'OnActionEffect', "popup",
					'__condition', function (parent, context) return IsDlcAvailable("armstrong") end,
					'replace_matching_id', true,
				}, {
					PlaceObj('XTemplateForEach', {
						'comment', "water rains",
						'array', function (parent, context) return DataInstanceCombo("MapSettings_RainsDisaster")() end,
						'condition', function (parent, context, item, i) return DataInstances.MapSettings_RainsDisaster[item].type == "normal" end,
						'run_after', function (child, context, item, i, n)
							child.ActionId = "TriggerDisaster" .. item .. "WaterRain"
							child.ActionName = "Rain " .. item
							child.ActionSortKey = tostring(i)
							child.OnAction = function()
								if not CheatsEnabled() then return end
								CheatRainsDisaster(item)
							end
						end,
					}, {
						PlaceObj('XTemplateAction', {
							'ActionTranslate', false,
							'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						}),
						}),
					}),
				PlaceObj('XTemplateAction', {
					'ActionId', "Cheats.Trigger Disaster Marsquakes",
					'ActionSortKey', "10",
					'ActionName', T(866254995932, --[[XTemplate GameCheatShortcuts ActionName]] "Marsquakes"),
					'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
					'OnActionEffect', "popup",
					'__condition', function (parent, context) return IsDlcAvailable("armstrong") end,
					'replace_matching_id', true,
				}, {
					PlaceObj('XTemplateForEach', {
						'comment', "marsquake",
						'array', function (parent, context) return DataInstanceCombo("MapSettings_Marsquake")() end,
						'run_after', function (child, context, item, i, n)
							child.ActionId = "TriggerDisaster" .. item .. "Marsquake"
							child.ActionName = "Marsquake " .. item
							child.ActionSortKey = tostring(i)
							child.OnAction = function()
								if not CheatsEnabled() then return end
								CheatTriggerMarsquake(item)
							end
						end,
					}, {
						PlaceObj('XTemplateAction', {
							'ActionTranslate', false,
							'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						}),
						}),
					}),
				PlaceObj('XTemplateAction', {
					'ActionId', "Cheats.Trigger Disaster Underground Marsquakes",
					'ActionSortKey', "10",
					'ActionName', T(13683, --[[XTemplate GameCheatShortcuts ActionName]] "Underground Marsquakes"),
					'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
					'OnActionEffect', "popup",
					'__condition', function (parent, context) return IsDlcAccessible("picard") end,
					'replace_matching_id', true,
				}, {
					PlaceObj('XTemplateForEach', {
						'comment', "underground marsquake",
						'array', function (parent, context) return DataInstanceCombo("MapSettings_UndergroundMarsquake")() end,
						'run_after', function (child, context, item, i, n)
							child.ActionId = "TriggerDisaster" .. item .. "UndergroundMarsquake"
							child.ActionName = "UndergroundMarsquake " .. item
							child.ActionSortKey = tostring(i)
							child.OnAction = function()
								if not CheatsEnabled() then return end
								CheatTriggerUndergroundMarsquake()
							end
						end,
					}, {
						PlaceObj('XTemplateAction', {
							'ActionTranslate', false,
							'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						}),
						}),
					PlaceObj('XTemplateForEach', {
						'comment', "underground cave in",
						'array', function (parent, context) return DataInstanceCombo("MapSettings_UndergroundMarsquake")() end,
						'run_after', function (child, context, item, i, n)
							child.ActionId = "TriggerDisaster" .. item .. "UndergroundCaveIn"
							child.ActionName = "UndergroundCaveIn " .. item
							child.ActionSortKey = tostring(i)
							child.OnAction = function()
								if not CheatsEnabled() then return end
								local pos = GetCursorWorldPos()
								CheatTriggerUndergroundCaveIn(pos)
							end
						end,
					}, {
						PlaceObj('XTemplateAction', {
							'ActionTranslate', false,
							'ActionIcon', "CommonAssets/UI/Menu/default.tga",
						}),
						}),
					}),
				PlaceObj('XTemplateAction', {
					'comment', "Stop Disaster",
					'RolloverText', "Stop Disaster",
					'ActionId', "TriggerDisasterStop",
					'ActionSortKey', "0",
					'ActionTranslate', false,
					'ActionName', "Stop Disaster",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatStopDisaster()
					end,
					'replace_matching_id', true,
				}),
				}),
			PlaceObj('XTemplateAction', {
				'ActionId', "Cheats.Research",
				'ActionTranslate', false,
				'ActionName', "Research ...",
				'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
				'OnActionEffect', "popup",
				'replace_matching_id', true,
			}, {
				PlaceObj('XTemplateAction', {
					'comment', "Finish current research instantly",
					'RolloverText', "Finish current research instantly",
					'ActionId', "G_ResearchCurrent",
					'ActionTranslate', false,
					'ActionName', "Research current tech",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatResearchCurrent()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Research all techs instantly",
					'RolloverText', "Research all techs instantly",
					'ActionId', "G_ResearchAll",
					'ActionTranslate', false,
					'ActionName', "Research all",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatResearchAll()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Unlock all techs instantly",
					'RolloverText', "Unlock all techs instantly",
					'ActionId', "G_UnlockАllТech",
					'ActionTranslate', false,
					'ActionName', "Unlock all Tech",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatUnlockAllTech()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Unlock all breakthroughs on this map",
					'RolloverText', "Unlock all breakthroughs on this map",
					'ActionId', "UnlockBreakthroughs",
					'ActionTranslate', false,
					'ActionName', "Unlock map Breakthroughs",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatUnlockBreakthroughs()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Unlock all breakthroughs",
					'RolloverText', "Unlock all breakthroughs",
					'ActionId', "UnlockAllBreakthroughs",
					'ActionTranslate', false,
					'ActionName', "Unlock all Breakthroughs",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatUnlockAllBreakthroughs()
					end,
					'replace_matching_id', true,
				}),
				}),
			PlaceObj('XTemplateAction', {
				'ActionId', "Cheats.Workplaces",
				'ActionTranslate', false,
				'ActionName', "Workplaces ...",
				'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
				'OnActionEffect', "popup",
				'replace_matching_id', true,
			}, {
				PlaceObj('XTemplateAction', {
					'comment', "Clear Forced Workplaces",
					'RolloverText', "Clear Forced Workplaces",
					'ActionId', "G_CheatClearForcedWorkplaces",
					'ActionTranslate', false,
					'ActionName', "Clear Forced Workplaces",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatClearForcedWorkplaces()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Toggle All Shifts",
					'RolloverText', "Toggle All Shifts",
					'ActionId', "G_ToggleAllShifts",
					'ActionTranslate', false,
					'ActionName', "Toggle All Shifts",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatToggleAllShifts()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Update All Workplaces",
					'RolloverText', "Update All Workplaces",
					'ActionId', "G_CheatUpdateAllWorkplaces",
					'ActionTranslate', false,
					'ActionName', "Update All Workplaces",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatUpdateAllWorkplaces()
					end,
					'replace_matching_id', true,
				}),
				}),
			PlaceObj('XTemplateAction', {
				'ActionId', "Cheats.StoryBits",
				'ActionTranslate', false,
				'ActionName', "Story Bits ...",
				'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
				'OnActionEffect', "popup",
				'replace_matching_id', true,
			}, {
				PlaceObj('XTemplateAction', {
					'comment', "Clear Category Cooldowns",
					'RolloverText', "Clear StoryBit Category Cooldowns",
					'ActionId', "G_CheatClearSBCategoryCooldowns",
					'ActionTranslate', false,
					'ActionName', "Clear Category Cooldowns",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						StoryBitCategoryState.ClearCooldowns()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Interrupt StoryBit Supression Times",
					'RolloverText', "Interrupt StoryBit Supression Times",
					'ActionId', "G_InterruptStoryBitSupressionTimes",
					'ActionTranslate', false,
					'ActionName', "Interrupt StoryBit Supression Times",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
										InterruptStoryBitSupressionTimes()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Clear Category Cooldowns",
					'RolloverText', "Clear StoryBit Category Cooldowns",
					'ActionId', "G_CheatClearSBCategoryCooldowns",
					'ActionTranslate', false,
					'ActionName', "Clear Category Cooldowns",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						StoryBitCategoryState.ClearCooldowns()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Toggle StoryBit Testing",
					'RolloverText', "Toggle StoryBit Testing",
					'ActionId', "G_ToggleStorybitTesting",
					'ActionTranslate', false,
					'ActionName', "Toggle Testing",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'ActionToggle', true,
					'ActionToggled', function (self, host)
						return g_StoryBitTesting
					end,
					'ActionToggledIcon', "CommonAssets/UI/Menu/checked.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						ToggleStoryBitTesting()
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Delete StoryBit Testing Backlog",
					'RolloverText', "Toggle StoryBit Testing",
					'ActionId', "G_DeleteStoryBitTestingBacklog",
					'ActionTranslate', false,
					'ActionName', "Delete Testing Backlog",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						DeleteStoryBitTestingBacklog()
					end,
					'replace_matching_id', true,
				}),
				}),
			PlaceObj('XTemplateAction', {
				'ActionId', "Cheats.Start Mystery",
				'ActionTranslate', false,
				'ActionName', "Start Mystery ...",
				'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
				'OnActionEffect', "popup",
				'replace_matching_id', true,
			}, {
				PlaceObj('XTemplateAction', {
					'ActionId', "StartMysteryAIUprisingMystery",
					'ActionTranslate', false,
					'ActionName', "Artificial Intelligence (Normal) - Mystery 5",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatStartMystery(self.ActionId:sub(#"StartMystery"+1))		
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "StartMysteryUnitedEarthMystery",
					'ActionTranslate', false,
					'ActionName', "Beyond Earth (Easy) - Mystery 9",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatStartMystery(self.ActionId:sub(#"StartMystery"+1))
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "StartMysteryDreamMystery",
					'ActionTranslate', false,
					'ActionName', "Inner Light (Easy) - Mystery 4",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatStartMystery(self.ActionId:sub(#"StartMystery"+1))		
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "StartMysteryMarsgateMystery",
					'ActionTranslate', false,
					'ActionName', "Marsgate (Hard) - Mystery 6",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatStartMystery(self.ActionId:sub(#"StartMystery"+1))		
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "StartMysteryMetatronMystery",
					'ActionTranslate', false,
					'ActionName', "Metatron (Hard) - Mystery 12",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatStartMystery(self.ActionId:sub(#"StartMystery"+1))		
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "StartMysteryCrystalsMystery",
					'ActionTranslate', false,
					'ActionName', "Philosopher's Stone (Easy) - Mystery 10",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatStartMystery(self.ActionId:sub(#"StartMystery"+1))		
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "StartMysteryMirrorSphereMystery",
					'ActionTranslate', false,
					'ActionName', "Spheres (Normal) - Mystery 3",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatStartMystery(self.ActionId:sub(#"StartMystery"+1))		
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "StartMysteryLightsMystery",
					'ActionTranslate', false,
					'ActionName', "St. Elmo's Fire (Normal) - Mystery 11",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatStartMystery(self.ActionId:sub(#"StartMystery"+1))
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "StartMysteryDiggersMystery",
					'ActionTranslate', false,
					'ActionName', "The Dredgers (Normal) - Mystery 2",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatStartMystery(self.ActionId:sub(#"StartMystery"+1))		
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "StartMysteryWorldWar3",
					'ActionTranslate', false,
					'ActionName', "The Last War (Hard) - Mystery 7",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatStartMystery(self.ActionId:sub(#"StartMystery"+1))		
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "StartMysteryBlackCubeMystery",
					'ActionTranslate', false,
					'ActionName', "The Power of Three (Easy) - Mystery 1",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatStartMystery(self.ActionId:sub(#"StartMystery"+1))		
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'ActionId', "StartMysteryTheMarsBug",
					'ActionTranslate', false,
					'ActionName', "Wildfire (Hard) - Mystery 8",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						CheatStartMystery(self.ActionId:sub(#"StartMystery"+1))		
					end,
					'replace_matching_id', true,
				}),
				}),
			PlaceObj('XTemplateAction', {
				'ActionId', "Cheats.Spawn Colonist",
				'ActionTranslate', false,
				'ActionName', "Spawn Colonist ...",
				'ActionIcon', "CommonAssets/UI/Menu/folder.tga",
				'OnActionEffect', "popup",
				'replace_matching_id', true,
			}, {
				PlaceObj('XTemplateAction', {
					'comment', "Spawn 1 Colonist",
					'RolloverText', "Spawn 1 Colonist",
					'ActionId', "SpawnColonist1",
					'ActionTranslate', false,
					'ActionName', "Spawn 1 Colonist",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatSpawnNColonists(1)
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Spawn 10 Colonist",
					'RolloverText', "Spawn 10 Colonist",
					'ActionId', "SpawnColonist10",
					'ActionTranslate', false,
					'ActionName', "Spawn 10 Colonist",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatSpawnNColonists(10)
					end,
					'replace_matching_id', true,
				}),
				PlaceObj('XTemplateAction', {
					'comment', "Spawn 100 Colonist",
					'RolloverText', "Spawn 100 Colonist",
					'ActionId', "SpawnColonist100",
					'ActionTranslate', false,
					'ActionName', "Spawn 100 Colonist",
					'ActionIcon', "CommonAssets/UI/Menu/default.tga",
					'OnAction', function (self, host, source)
						if not CheatsEnabled() then return end
						CheatSpawnNColonists(100)
					end,
					'replace_matching_id', true,
				}),
				}),
			PlaceObj('XTemplateAction', {
				'comment', "Open Pregame Menu",
				'RolloverText', "Open Pregame Menu",
				'ActionId', "G_OpenPregameMenu",
				'ActionTranslate', false,
				'ActionName', "New Game",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source)
					CreateRealTimeThread(OpenPreGameMainMenu)
				end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'comment', "Enable/disable the cheats in the infopanels",
				'RolloverText', "Enable/disable the cheats in the infopanels",
				'ActionId', "G_ToggleInfopanelCheats",
				'ActionTranslate', false,
				'ActionName', "Toggle Infopanel Cheats",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source)
					CheatToggleInfopanelCheats()
				end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'comment', "Unlock all buildings for construction",
				'RolloverText', "Unlock all buildings for construction",
				'ActionId', "G_UnlockAllBuildings",
				'ActionTranslate', false,
				'ActionName', "Unlock all buildings",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source)
					if not CheatsEnabled() then return end
					CheatUnlockAllBuildings()
				end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "UnlockAdditionalBuildings",
			}),
			PlaceObj('XTemplateAction', {
				'comment', "Unpin All Pinned Objects",
				'RolloverText', "Unpin All Pinned Objects",
				'ActionId', "G_UnpinAll",
				'ActionTranslate', false,
				'ActionName', "Unpin All Pinned Objects",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source)
					if not CheatsEnabled() then return end
						UnpinAll("force")
				end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'comment', "Toggle Rocket Instant Travel",
				'RolloverText', "Toggle Rocket Instant Travel",
				'ActionId', "G_ToggleRocketInstantTravel",
				'ActionTranslate', false,
				'ActionName', "Toggle Rocket Instant Travel",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source)
					if not CheatsEnabled() then return end
						dbg_ToggleRocketInstantTravel()
				end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'comment', "Unlock, Research, Explore",
				'RolloverText', "Unlock all buildings, research all techs, explore the map.",
				'ActionId', "G_MultiCheat",
				'ActionTranslate', false,
				'ActionName', "Unlock, Research, Explore",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source)
					if not CheatsEnabled() then return end
						MultiCheat()
				end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'comment', "Complete all wires and pipes instantly",
				'RolloverText', "Complete all wires and pipes instantly",
				'ActionId', "G_CompleteWiresPipes",
				'ActionTranslate', false,
				'ActionName', "Complete wires\\pipes",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source)  end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'comment', "Complete all constructions instantly (Alt-B)",
				'RolloverText', "Complete all constructions instantly (Alt-B)",
				'ActionId', "G_CompleteConstructions",
				'ActionTranslate', false,
				'ActionName', "Complete constructions",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'ActionShortcut', "Alt-B",
				'OnAction', function (self, host, source)
					if not CheatsEnabled() then return end
					CheatCompleteAllConstructions()
				end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'ActionId', "G_ModsEditor",
				'ActionTranslate', false,
				'ActionName', "Mod editor",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source)
					if not CheatsEnabled() then return end
					ModEditorOpen()
				end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'ActionId', "G_AddFunding",
				'ActionTranslate', false,
				'ActionName', "Add funding $500000000",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source)
					if not CheatsEnabled() then return end
					CheatAddFunding()
				end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'ActionId', "G_ToggleOnScreenHints",
				'ActionTranslate', false,
				'ActionName', "Toggle on-screen hints",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source)
					if not CheatsEnabled() then return end
					SetHintNotificationsEnabled(not HintsEnabled)
					UpdateOnScreenHintDlg()
				end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'ActionId', "G_ResetOnScreenHints",
				'ActionTranslate', false,
				'ActionName', "Reset on-screen hints",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'OnAction', function (self, host, source)
					if not CheatsEnabled() then return end
					g_ShownOnScreenHints = {}
					UpdateOnScreenHintDlg()
				end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'comment', " (Ctrl-U)",
				'RolloverText', " (Ctrl-U)",
				'ActionId', "G_ToggleSigns",
				'ActionTranslate', false,
				'ActionName', "Toggle Signs",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'ActionShortcut', "Ctrl-U",
				'OnAction', function (self, host, source)
					if not CheatsEnabled() then return end
					ToggleSigns()
				end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'comment', " (Ctrl-Alt-I)",
				'RolloverText', " (Ctrl-Alt-I)",
				'ActionId', "G_ToggleInGameInterface",
				'ActionTranslate', false,
				'ActionName', "Toggle InGame Interface",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'ActionShortcut', "Ctrl-Alt-I",
				'OnAction', function (self, host, source)
					hr.RenderUIL = hr.RenderUIL == 0 and 1 or 0
				end,
				'replace_matching_id', true,
			}),
			PlaceObj('XTemplateAction', {
				'comment', " (Shift-C)",
				'RolloverText', " (Shift-C)",
				'ActionId', "FreeCamera",
				'ActionTranslate', false,
				'ActionName', "Toggle Free Camera",
				'ActionIcon', "CommonAssets/UI/Menu/default.tga",
				'ActionShortcut', "Shift-C",
				'OnAction', function (self, host, source)
					if not ActiveMapData.GameLogic then return end
					if cameraFly.IsActive() then
						SetMouseDeltaMode(false)
						cameraRTS.Activate(1)
					else
						print("Camera Fly")
						cameraFly.Activate(1)
						SetMouseDeltaMode(true)
					end
				end,
				'replace_matching_id', true,
			}),
			}),
		}),
})

