-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	group = "Infopanel Sections",
	id = "ipBuilding",
	PlaceObj('XTemplateTemplate', {
		'__context_of_kind', "Building",
		'__template', "Infopanel",
	}, {
		PlaceObj('XTemplateGroup', {
			'__condition', function (parent, context) return not context.destroyed end,
		}, {
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionUpgrades",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionServiceArea",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionDome",
			}),
			PlaceObj('XTemplateTemplate', {
				'__condition', function (parent, context) return IsDlcAccessible("picard") end,
				'__template', "sectionMicroGHabitat",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionStorageWarning",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionCrop",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionVegetationPlant",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionPasture",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionCustom",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionConstructionSite",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionVisitors",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionTraits",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionResidence",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionResourceProducer",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionMine",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionStorage",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionResearchProject",
			}),
			PlaceObj('XTemplateTemplate', {
				'__condition', function (parent, context) return IsDlcAccessible("picard") end,
				'__template', "sectionReconCenter",
			}),
			PlaceObj('XTemplateTemplate', {
				'__condition', function (parent, context) return IsDlcAvailable("gagarin") end,
				'__template', "sectionGameDevProgress",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionPowerProduction",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionWindTurbineBoost",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionWaterProduction",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionAirProduction",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionWorkshifts",
			}),
			PlaceObj('XTemplateTemplate', {
				'__condition', function (parent, context) return IsDlcAccessible("picard") end,
				'__template', "sectionBottomlessPitResearchCenter",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionPowerStorage",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionWaterStorage",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionAirStorage",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionPowerGrid",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionWaterGrid",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionTerraforming",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionTerraformingMFG",
				'IgnoreMissing', true,
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionAirGrid",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionConsumption",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionMaintenance",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionCold",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionSupplyProducerAttention",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionWarning",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionSensorTower",
			}),
			PlaceObj('XTemplateTemplate', {
				'comment', "priority",
				'__context', function (parent, context) return context:HasMember("construction_group") and context.construction_group and context.construction_group[1] or context end,
				'__condition', function (parent, context) return context.prio_button end,
				'__template', "InfopanelButton",
				'RolloverText', T(370449987367, --[[XTemplate ipBuilding RolloverText]] "Priority affects how often this building is serviced by Drones as well as its share of Power and life support. Notifications are not shown for buildings with low priority.<newline><newline>Current priority: <em><UIPriority></em>"),
				'RolloverTitle', T(369, --[[XTemplate ipBuilding RolloverTitle]] "Change Priority"),
				'RolloverHintGamepad', T(7659, --[[XTemplate ipBuilding RolloverHintGamepad]] "<ButtonA> Change priority<newline><ButtonX> Change priority of all <display_name_pl>"),
				'Id', "idPriority",
				'OnContextUpdate', function (self, context, ...)
					if context.priority == 1 then
						self:SetIcon("UI/Icons/IPButtons/normal_priority.tga")
					elseif context.priority == 2 then
						self:SetIcon("UI/Icons/IPButtons/high_priority.tga")
					else
						self:SetIcon("UI/Icons/IPButtons/urgent_priority.tga")
					end
					local shortcuts = GetShortcuts("actionPriority")
					local binding = ""
					if shortcuts and (shortcuts[1] or shortcuts[2]) then
						binding = T(10950, "<newline><center><em><ShortcutName('actionPriority', 'keyboard')></em> Increase Priority")
					end
					self:SetRolloverHint(T{10951, "<left><left_click> Increase priority<right><right_click> Decrease priority<binding><newline><center><em>Ctrl + <left_click></em> Change priority of all <display_name_pl>", binding = binding})
				end,
				'OnPress', function (self, gamepad)
					PlayFX("UIChangePriority")
					self.context:TogglePriority(1, not gamepad and IsMassUIModifierPressed())
					ObjModified(self.context)
				end,
				'AltPress', true,
				'OnAltPress', function (self, gamepad)
					if gamepad then
						self.context:TogglePriority(1, true)
					else
						self.context:TogglePriority(-1, IsMassUIModifierPressed())
					end
					ObjModified(self.context)
				end,
				'Translate', true,
			}),
			PlaceObj('XTemplateTemplate', {
				'comment', "on/off",
				'__condition', function (parent, context) return context.on_off_button and not (IsKindOf(context, "ConstructionSite") and context.building_class == "BlackCubeMonolith") end,
				'__template', "InfopanelButton",
				'RolloverText', T(382329017655, --[[XTemplate ipBuilding RolloverText]] "Buildings that are turned off do not function and never consume Power or resources.<newline><newline>Current status: <em><UIWorkingStatus></em>"),
				'RolloverDisabledText', T(10553, --[[XTemplate ipBuilding RolloverDisabledText]] "This building is currently disabled."),
				'RolloverTitle', T(627191661712, --[[XTemplate ipBuilding RolloverTitle]] "Turn On/Off"),
				'RolloverHint', T(238148642034, --[[XTemplate ipBuilding RolloverHint]] "<left_click> Activate <newline><em>Ctrl + <left_click></em> Activate for all <display_name_pl>"),
				'RolloverHintGamepad', T(919224409562, --[[XTemplate ipBuilding RolloverHintGamepad]] "<ButtonA> Activate <newline><ButtonX> Activate for all <display_name_pl>"),
				'OnPressParam', "ToggleWorking",
				'OnPress', function (self, gamepad)
					self.context:ToggleWorking(not gamepad and IsMassUIModifierPressed())
				end,
				'AltPress', true,
				'OnAltPress', function (self, gamepad)
					if gamepad then
						self.context:ToggleWorking(true)
					end
				end,
			}),
			PlaceObj('XTemplateTemplate', {
				'comment', "tourist restrictions",
				'__context_of_kind', "Hotel",
				'__condition', function (parent, context) return true end,
				'__template', "InfopanelButton",
				'RolloverText', T(178777171911, --[[XTemplate ipBuilding RolloverText]] "Buildings that only accept Tourists won't allow other Colonists to take residence.<newline><newline>Accepting: <em><UITouristOnlyStatus></em>"),
				'RolloverDisabledText', T(818564269263, --[[XTemplate ipBuilding RolloverDisabledText]] "This building is currently accepting any resident."),
				'RolloverTitle', T(129927784288, --[[XTemplate ipBuilding RolloverTitle]] "Tourist Restrictions On/Off"),
				'RolloverHint', T(238148642034, --[[XTemplate ipBuilding RolloverHint]] "<left_click> Activate <newline><em>Ctrl + <left_click></em> Activate for all <display_name_pl>"),
				'RolloverHintGamepad', T(919224409562, --[[XTemplate ipBuilding RolloverHintGamepad]] "<ButtonA> Activate <newline><ButtonX> Activate for all <display_name_pl>"),
				'OnPressParam', "ToggleTouristOnly",
				'OnPress', function (self, gamepad)
					self.context:ToggleTouristOnly(not gamepad and IsMassUIModifierPressed())
				end,
				'AltPress', true,
				'OnAltPress', function (self, gamepad)
					if gamepad then
						self.context:ToggleTouristOnly(true)
					end
				end,
				'Icon', "UI/Icons/IPButtons/colonists_all.tga",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "customDomeButtons",
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "sectionWorkplace",
			}),
			PlaceObj('XTemplateTemplate', {
				'comment', "tunnel",
				'__condition', function (parent, context) return IsKindOf(context, "Tunnel") end,
				'__template', "InfopanelButton",
				'RolloverText', T(8629, --[[XTemplate ipBuilding RolloverText]] "Move the camera to the other side of the tunnel."),
				'RolloverTitle', T(8630, --[[XTemplate ipBuilding RolloverTitle]] "View Exit"),
				'RolloverHint', T(8631, --[[XTemplate ipBuilding RolloverHint]] "<left_click> View"),
				'RolloverHintGamepad', T(7605, --[[XTemplate ipBuilding RolloverHintGamepad]] "<ButtonA> View"),
				'OnPress', function (self, gamepad)
					ViewAndSelectObject(self.context.linked_obj)
				end,
				'Icon', "UI/Icons/IPButtons/tunnel.tga",
			}),
			PlaceObj('XTemplateTemplate', {
				'comment', "toggle lrt",
				'__condition', function (parent, context) return IsKindOfClasses(context, "StorageDepot", "MechanizedDepot") and not IsKindOf(context, "RocketBase") end,
				'__template', "InfopanelButton",
				'RolloverText', T(11233, --[[XTemplate ipBuilding RolloverText]] "Storages with forbidden Shuttle Access are never serviced by Shuttles.<newline><newline>Current status: <em><on_off(user_include_in_lrt)></em>"),
				'RolloverTitle', T(11254, --[[XTemplate ipBuilding RolloverTitle]] "Shuttle Access"),
				'RolloverHint', T(11255, --[[XTemplate ipBuilding RolloverHint]] "<left_click> Toggle <newline><em>Ctrl + <left_click></em> Toggle for all <display_name_pl>"),
				'RolloverHintGamepad', T(454042608125, --[[XTemplate ipBuilding RolloverHintGamepad]] "<ButtonA> Toggle <newline><ButtonX> Toggle for all <display_name_pl>"),
				'Id', "ToggleLRTServiceButton",
				'FoldWhenHidden', true,
				'OnPressParam', "ToggleLRTService",
				'OnPress', function (self, gamepad)
					self.context:ToggleLRTService(not gamepad and IsMassUIModifierPressed())
				end,
				'AltPress', true,
				'OnAltPress', function (self, gamepad)
					if gamepad then
						self.context:ToggleLRTService(true)
					end
				end,
				'Icon', "UI/Icons/IPButtons/rebuild.tga",
			}),
			PlaceObj('XTemplateTemplate', {
				'comment', "salvage",
				'__context_of_kind', "Demolishable",
				'__condition', function (parent, context) return context:ShouldShowDemolishButton() end,
				'__template', "InfopanelButton",
				'RolloverTitle', T(3973, --[[XTemplate ipBuilding RolloverTitle]] "Salvage"),
				'RolloverHintGamepad', T(7657, --[[XTemplate ipBuilding RolloverHintGamepad]] "<ButtonY> Activate"),
				'Id', "idSalvage",
				'OnContextUpdate', function (self, context, ...)
					local refund = context:GetRefundResources() or empty_table
					local rollover = T(7822, "Destroy this building.")
					if IsKindOf(context, "LandscapeConstructionSiteBase") then
						self:SetRolloverTitle(T(12171, "Cancel Landscaping"))
						rollover = T(12172, "Cancel this landscaping project. The terrain will remain in its current state")
					end
					if #refund > 0 then
						rollover = rollover .. "<newline><newline>" .. T(7823, "<UIRefundRes> will be refunded upon salvage.")
					end
					self:SetRolloverText(rollover)
					context:ToggleDemolish_Update(self)
				end,
				'OnPressParam', "ToggleDemolish",
				'Icon', "UI/Icons/IPButtons/salvage_1.tga",
			}, {
				PlaceObj('XTemplateFunc', {
					'name', "OnXButtonDown(self, button)",
					'func', function (self, button)
						if button == "ButtonY" then
							return self:OnButtonDown(false)
						elseif button == "ButtonX" then
							return self:OnButtonDown(true)
						end
						return (button == "ButtonA") and "break"
					end,
				}),
				PlaceObj('XTemplateFunc', {
					'name', "OnXButtonUp(self, button)",
					'func', function (self, button)
						if button == "ButtonY" then
							return self:OnButtonUp(false)
						elseif button == "ButtonX" then
							return self:OnButtonUp(true)
						end
						return (button == "ButtonA") and "break"
					end,
				}),
				}),
			PlaceObj('XTemplateTemplate', {
				'comment', "refab",
				'__dlc', "picard",
				'__context_of_kind', "Building",
				'__condition', function (parent, context) return context:CanRefab() end,
				'__template', "InfopanelButton",
				'RolloverText', T(608358975996, --[[XTemplate ipBuilding RolloverText]] "Convert this building into a Prefab that you can rebuild elsewhere. All upgrades on the building will be lost.<newline><newline>Drone Hubs also take back 6 nearby Drones."),
				'RolloverTitle', T(578067230743, --[[XTemplate ipBuilding RolloverTitle]] "Refab"),
				'RolloverHintGamepad', T(7657, --[[XTemplate ipBuilding RolloverHintGamepad]] "<ButtonY> Activate"),
				'OnPressParam', "ToggleRefab",
				'Icon', "UI/Icons/IPButtons/refab.tga",
			}, {
				PlaceObj('XTemplateFunc', {
					'name', "OnXButtonDown(self, button)",
					'func', function (self, button)
						if button == "ButtonY" then
							return self:OnButtonDown(false)
						elseif button == "ButtonX" then
							return self:OnButtonDown(true)
						end
						return (button == "ButtonA") and "break"
					end,
				}),
				PlaceObj('XTemplateFunc', {
					'name', "OnXButtonUp(self, button)",
					'func', function (self, button)
						if button == "ButtonY" then
							return self:OnButtonUp(false)
						elseif button == "ButtonX" then
							return self:OnButtonUp(true)
						end
						return (button == "ButtonA") and "break"
					end,
				}),
				}),
			}),
		PlaceObj('XTemplateGroup', nil, {
			PlaceObj('XTemplateTemplate', {
				'comment', "rebuild",
				'__template', "InfopanelButton",
				'RolloverText', T(593, --[[XTemplate ipBuilding RolloverText]] "Rebuild this building."),
				'RolloverTitle', T(592, --[[XTemplate ipBuilding RolloverTitle]] "Rebuild"),
				'RolloverHint', T(238148642034, --[[XTemplate ipBuilding RolloverHint]] "<left_click> Activate <newline><em>Ctrl + <left_click></em> Activate for all <display_name_pl>"),
				'RolloverHintGamepad', T(919224409562, --[[XTemplate ipBuilding RolloverHintGamepad]] "<ButtonA> Activate <newline><ButtonX> Activate for all <display_name_pl>"),
				'FoldWhenHidden', true,
				'OnContextUpdate', function (self, context, ...)
					self:SetEnabled((not g_Tutorial or g_Tutorial.EnableRebuild) and not context.bulldozed)
					self:SetVisible(context.destroyed and not context.demolishing)
					XTextButton.OnContextUpdate(self, context, ...)
				end,
				'OnPressParam', "DestroyedRebuild",
				'OnPress', function (self, gamepad)
					self.context:DestroyedRebuild(not gamepad and IsMassUIModifierPressed())
				end,
				'AltPress', true,
				'OnAltPress', function (self, gamepad)
					if gamepad then
						self.context:DestroyedRebuild(true)
					end
				end,
				'Icon', "UI/Icons/IPButtons/rebuild.tga",
			}),
			PlaceObj('XTemplateTemplate', {
				'comment', "clear",
				'__template', "InfopanelButton",
				'RolloverText', T(595, --[[XTemplate ipBuilding RolloverText]] "Remove the remains of this building."),
				'RolloverDisabledText', T(596, --[[XTemplate ipBuilding RolloverDisabledText]] "You need the Decommission Protocol (Engineering) Tech to remove these building remains."),
				'RolloverTitle', T(594, --[[XTemplate ipBuilding RolloverTitle]] "Clear"),
				'Id', "idDecommission",
				'FoldWhenHidden', true,
				'OnContextUpdate', function (self, context, ...)
					self:SetEnabled(UIColony:IsTechResearched("DecommissionProtocol") or false)
					self:SetVisible(context.destroyed and not context.demolishing)
					local hint = T(238148642034, "<left_click> Activate <newline><em>Ctrl + <left_click></em> Activate for all <display_name_pl>")
					local hint_gamepad = T(919224409562, "<ButtonA> Activate <newline><ButtonX> Activate for all <display_name_pl>")
					if context.bulldozed then
						hint = TLookupTag("<left_click>") .. " " .. T(3687, "Cancel")
						hint_gamepad = TLookupTag("<ButtonA>") .. " " .. T(3687, "Cancel")
					end
					self:SetRolloverHint(hint)
					self:SetRolloverHintGamepad(hint_gamepad)
					XTextButton.OnContextUpdate(self, context, ...)
					self:SetIcon(context.bulldozed and "UI/Icons/IPButtons/cancel.tga" or "UI/Icons/IPButtons/demolition.tga")
				end,
				'OnPress', function (self, gamepad)
					if self.context.bulldozed then
						self.context:CancelDestroyedClear(not gamepad and IsMassUIModifierPressed())
					else
						self.context:DestroyedClear(not gamepad and IsMassUIModifierPressed())
					end
				end,
				'AltPress', true,
				'OnAltPress', function (self, gamepad)
					if gamepad then
						if self.context.bulldozed then
							self.context:CancelDestroyedClear(true)
						else
							self.context:DestroyedClear(true)
						end
					end
				end,
				'Icon', "UI/Icons/IPButtons/demolition.tga",
			}),
			}),
		PlaceObj('XTemplateTemplate', {
			'__template', "sectionCheats",
		}),
		}),
})

