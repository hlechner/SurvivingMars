-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	group = "Infopanel Sections",
	id = "sectionDome",
	PlaceObj('XTemplateGroup', {
		'__context_of_kind', "Dome",
	}, {
		PlaceObj('XTemplateTemplate', {
			'comment', "filter traits",
			'__template', "InfopanelButton",
			'RolloverText', T(363, --[[XTemplate sectionDome RolloverText]] "Filter Colonists in the Dome by desired or undesired traits. Colonists that do not match the filter will try to resettle in another Dome. If a Quarantine was set for the Dome, this action will remove it."),
			'RolloverTitle', T(362, --[[XTemplate sectionDome RolloverTitle]] "Filter by Traits"),
			'OnContextUpdate', function (self, context, ...)
				local shortcuts = GetShortcuts("actionDomeFilter")
				local hint = ""
				if shortcuts and (shortcuts[1] or shortcuts[2]) then
					hint = T(10952, " / <em><ShortcutName('actionDomeFilter', 'keyboard')></em>")
				end
				self:SetRolloverHint(T{10947, "<left_click><hint> Activate", hint = hint})
			end,
			'OnPressParam', "OpenFilterTraits",
			'Icon', "UI/Icons/IPButtons/colonists_accept.tga",
		}),
		PlaceObj('XTemplateTemplate', {
			'__template', "InfopanelActiveSection",
			'OnContextUpdate', function (self, context, ...)
				local dome = ResolvePropObj(context)
				local birth_policy = dome.birth_policy
				if birth_policy == BirthPolicy.Enabled then
					self:SetIcon("UI/Icons/Sections/birth_on.tga")
					self:SetTitle(T(8726, "Births are allowed"))
				elseif birth_policy == BirthPolicy.Forbidden then
					self:SetIcon("UI/Icons/Sections/birth_off.tga")
					self:SetTitle( T(8727, "Births are forbidden"))
				else
					self:SetIcon("UI/Icons/Sections/birth_limit.tga")
					self:SetTitle( T(13754, "Births are forbidden when full"))
				end
				rawset(self, "ProcessToggle", function(self, context, broadcast)
					local building = ResolvePropObj(context)
					building:CycleBirthPolicy(broadcast)
					RebuildInfopanel(building)
				end)
				self.OnActivate = function (self, context, gamepad)
					self:ProcessToggle(context, not gamepad and IsMassUIModifierPressed())
				end
				self.OnAltActivate = function(self, context, gamepad)
					if gamepad then
						self:ProcessToggle(context, true)
					end
				end
				-- rollover
				self:SetRolloverTitle(T(8728, "Birth Control Policy"))
				local texts = {}
				if birth_policy == BirthPolicy.Enabled then	
					texts[#texts+1] = T(8729, "Set the birth policy for this Dome. Colonists at high comfort will have children if births are allowed.<newline><newline>Current status: <em>Births are allowed</em>")
					self:SetRolloverHint(T(8730, "<left_click> Forbid births in this Dome when it is full<newline><em>Ctrl + <left_click></em> Forbid births in all Domes when they are full"))
					self:SetRolloverHintGamepad(T(8731, "<ButtonA> Forbid births in this Dome when it is full<newline><ButtonX> Forbid births in all Domes when they are full"))
				elseif birth_policy == BirthPolicy.Forbidden then
					texts[#texts+1] = T(8732, "Set the birth policy for this Dome. Colonists at high comfort will have children if births are allowed.<newline><newline>Current status: <em>Births are forbidden</em>")
					self:SetRolloverHint(T(8733, "<left_click> Allow births in this Dome<newline><em>Ctrl + <left_click></em> Allow births in all Domes"))
					self:SetRolloverHintGamepad(T(8734, "<ButtonA> Allow births in this Dome <newline><ButtonX> Allow births in all Domes"))
				else
					texts[#texts+1] = T(13763, "Set the birth policy for this Dome. Colonists at high comfort will have children if births are allowed.<newline><newline><BirthDomeStatusText>")
					self:SetRolloverHint(T(13764, "<left_click> Forbid births in this Dome<newline><em>Ctrl + <left_click></em> Forbid births in all Domes"))
					self:SetRolloverHintGamepad(T(13767, "<ButtonA> Forbid births in this Dome <newline><ButtonX> Forbid births in all Domes"))
				end
				texts[#texts + 1]  = dome:GetBirthText()	
				self:SetRolloverText(table.concat(texts, "<newline><left>"))
			end,
		}),
		PlaceObj('XTemplateTemplate', {
			'__template', "InfopanelActiveSection",
			'OnContextUpdate', function (self, context, ...)
				local dome = ResolvePropObj(context)
					local accept = dome.allow_work_in_connected
					if accept then
						self:SetIcon("UI/Icons/Sections/work_in_connected_domes_on.tga")
						self:SetTitle(dome:GetUIWorkInConnectedText())
					else
						self:SetIcon("UI/Icons/Sections/work_in_connected_domes_off.tga")
						self:SetTitle( dome:GetUIWorkInConnectedText())
					end
					rawset(self, "ProcessToggle", function(self, context, broadcast)
						local building = ResolvePropObj(context)
						building:ToggleWorkInConnected(broadcast)
						RebuildInfopanel(building)
					end)
					self.OnActivate = function (self, context, gamepad)
						self:ProcessToggle(context, not gamepad and IsMassUIModifierPressed())
					end
					self.OnAltActivate = function(self, context, gamepad)
						if gamepad then
							self:ProcessToggle(context, true)
						end
					end
					-- rollover
					self:SetRolloverTitle(dome:GetUIWorkInConnectedText())
					self:SetRolloverText(T(8888, "Allow or forbid working in connected Domes.<newline><newline>Current status: <em><UIWorkInConnected></em>"))
					if dome.allow_work_in_connected then
						self:SetRolloverHint(T(8889, "<left_click> Forbid for this Dome<newline><em>Ctrl + <left_click></em> Forbid for all Domes"))
						self:SetRolloverHintGamepad(T(8890, "<ButtonA> Forbid for this Dome<newline><ButtonX> Forbid for all Domes"))
					else
						self:SetRolloverHint(T(8891, "<left_click> Allow for this Dome<newline><em>Ctrl + <left_click></em> Allow for all Domes"))
						self:SetRolloverHintGamepad(T(8892, "<ButtonA> Allow for this Dome<newline><ButtonX> Allow for all Domes"))
					end
			end,
		}),
		PlaceObj('XTemplateTemplate', {
			'__template', "InfopanelActiveSection",
			'OnContextUpdate', function (self, context, ...)
				local dome = ResolvePropObj(context)
					local accept = dome.allow_service_in_connected
					if accept then
						self:SetIcon("UI/Icons/Sections/service_in_connected_domes_on.tga")
						self:SetTitle(dome:GetUIServiceInConnectedText())
					else
						self:SetIcon("UI/Icons/Sections/service_in_connected_domes_off.tga")
						self:SetTitle(dome:GetUIServiceInConnectedText())
					end
					rawset(self, "ProcessToggle", function(self, context, broadcast)
						local building = ResolvePropObj(context)
						building:ToggleServiceInConnected(broadcast)
						RebuildInfopanel(building)
					end)
					self.OnActivate = function (self, context, gamepad)
						self:ProcessToggle(context, not gamepad and IsMassUIModifierPressed())
					end
					self.OnAltActivate = function(self, context, gamepad)
						if gamepad then
							self:ProcessToggle(context, true)
						end
					end
					-- rollover
					self:SetRolloverTitle(dome:GetUIServiceInConnectedText())
					self:SetRolloverText(T(8896, "Allow or forbid using service buildings in connected Domes.<newline><newline>Current status: <em><UIServiceInConnected></em>"))
					if dome.allow_service_in_connected then
						self:SetRolloverHint(T(8889, "<left_click> Forbid for this Dome<newline><em>Ctrl + <left_click></em> Forbid for all Domes"))
						self:SetRolloverHintGamepad(T(8890, "<ButtonA> Forbid for this Dome<newline><ButtonX> Forbid for all Domes"))
					else
						self:SetRolloverHint(T(8891, "<left_click> Allow for this Dome<newline><em>Ctrl + <left_click></em> Allow for all Domes"))
						self:SetRolloverHintGamepad(T(8892, "<ButtonA> Allow for this Dome<newline><ButtonX> Allow for all Domes"))
					end
			end,
		}),
		PlaceObj('XTemplateTemplate', {
			'__template', "InfopanelActiveSection",
			'OnContextUpdate', function (self, context, ...)
				local dome = ResolvePropObj(context)
					local accept = dome.accept_colonists
					local overpopulated = dome.overpopulated
					if accept then
						self:SetIcon(overpopulated 
										and "UI/Icons/Sections/Overpopulated.tga" 
										or "UI/Icons/Sections/accept_colonists_on.tga")
						self:SetTitle(overpopulated and T(10460, "Overpopulated Dome") or T(8735, "Accepts Colonists"))
					else
						self:SetIcon("UI/Icons/Sections/accept_colonists_off.tga")
						self:SetTitle( T(8736, "Quarantined"))
					end
					rawset(self, "ProcessToggle", function(self, context, broadcast)
						local building = ResolvePropObj(context)
						building:ToggleAcceptColonists(broadcast)
						RebuildInfopanel(building)
					end)
					self.OnActivate = function (self, context, gamepad)
						self:ProcessToggle(context, not gamepad and IsMassUIModifierPressed())
					end
					self.OnAltActivate = function(self, context, gamepad)
						if gamepad then
							self:ProcessToggle(context, true)
						end
					end
					-- rollover
					self:SetRolloverTitle(T(364, --[[XTemplate sectionDome RolloverTitle]] "Immigration Policy"))
					if accept then
						self:SetRolloverText(T(7660, "Set the Immigration policy for this Dome. Colonists are not allowed to enter or leave quarantined Domes.<newline><newline>Current status: <em>Accepts new Colonists</em>"))
						self:SetRolloverHint(T(7661, "<left_click> Quarantine this Dome<newline><em>Ctrl + <left_click></em> Quarantine all Domes"))
						self:SetRolloverHintGamepad(T(7662, "<ButtonA> Quarantine this Dome<newline><ButtonX> Quarantine all Domes"))
					else
						self:SetRolloverText(T(365, "Set the Immigration policy for this Dome. Colonists are not allowed to enter or leave quarantined Domes.<newline><newline>Current status: <em>Quarantined</em>"))
						self:SetRolloverHint(T(7663, "<left_click> Accept Colonists in this Dome<newline><em>Ctrl + <left_click></em> Accept Colonists in all Domes"))
						self:SetRolloverHintGamepad(T(7664, "<ButtonA> Accept Colonists in this Dome<newline><ButtonX> Accept Colonists in all Domes"))
					end
					if overpopulated then
						if accept then
							self:SetRolloverText(T(10452, "Set the Immigration policy for this Dome. Colonists are not allowed to enter or leave quarantined Domes.<newline><newline>Current status: <em>Overpopulated dome</em>"))
						else
							self:SetRolloverHint(T(7663, "<left_click> Accept Colonists in this Dome<newline><em>Ctrl + <left_click></em> Accept Colonists in all Domes"))
							self:SetRolloverHintGamepad(T(7664, "<ButtonA> Accept Colonists in this Dome<newline><ButtonX> Accept Colonists in all Domes"))
						end
					end
			end,
		}),
		PlaceObj('XTemplateTemplate', {
			'__template', "InfopanelSection",
			'RolloverText', T(121681643085, --[[XTemplate sectionDome RolloverText]] "<UISectionCitizensRollover>"),
			'Title', T(371953345486, --[[XTemplate sectionDome Title]] "Colonists<right><ColonistCount> / <colonist(LivingSpace)>"),
			'Icon', "UI/Icons/Sections/colonist.tga",
			'TitleHAlign', "stretch",
		}, {
			PlaceObj('XTemplateTemplate', {
				'__template', "InfopanelText",
				'FoldWhenHidden', true,
				'Text', T(201464169022, --[[XTemplate sectionDome Text]] "<EmploymentMessage>"),
			}),
			PlaceObj('XTemplateTemplate', {
				'__template', "InfopanelText",
				'Text', T(613137333871, --[[XTemplate sectionDome Text]] "<ResidenceMessage>"),
			}),
			}),
		PlaceObj('XTemplateTemplate', {
			'__template', "InfopanelSection",
			'RolloverText', T(244389183434, --[[XTemplate sectionDome RolloverText]] "The average <em>Health</em> of all Colonists living in this Dome."),
			'RolloverTitle', T(455859065748, --[[XTemplate sectionDome RolloverTitle]] "Average Health <Stat(AverageHealth)>"),
			'Icon', "UI/Icons/Sections/health.tga",
		}, {
			PlaceObj('XTemplateTemplate', {
				'__template', "InfopanelStat",
				'BindTo', "AverageHealth",
			}),
			}),
		PlaceObj('XTemplateTemplate', {
			'__template', "InfopanelSection",
			'RolloverText', T(607491882958, --[[XTemplate sectionDome RolloverText]] "The average <em>Sanity</em> of all Colonists living in this Dome."),
			'RolloverTitle', T(942703008133, --[[XTemplate sectionDome RolloverTitle]] "Average Sanity <Stat(AverageSanity)>"),
			'Icon', "UI/Icons/Sections/stress.tga",
		}, {
			PlaceObj('XTemplateTemplate', {
				'__template', "InfopanelStat",
				'BindTo', "AverageSanity",
			}),
			}),
		PlaceObj('XTemplateTemplate', {
			'__template', "InfopanelSection",
			'RolloverText', T(327454642679, --[[XTemplate sectionDome RolloverText]] "<ComfortRollover>"),
			'RolloverTitle', T(577070564514, --[[XTemplate sectionDome RolloverTitle]] "Average Comfort <Stat(AverageComfort)>"),
			'Icon', "UI/Icons/Sections/comfort.tga",
		}, {
			PlaceObj('XTemplateTemplate', {
				'__template', "InfopanelStat",
				'BindTo', "AverageComfort",
			}),
			}),
		PlaceObj('XTemplateTemplate', {
			'__template', "InfopanelSection",
			'RolloverText', T(856271865233, --[[XTemplate sectionDome RolloverText]] "The average <em>Morale</em> of all Colonists living in this Dome."),
			'RolloverTitle', T(765210150801, --[[XTemplate sectionDome RolloverTitle]] "Average Morale <Stat(AverageMorale)>"),
			'Icon', "UI/Icons/Sections/morale.tga",
		}, {
			PlaceObj('XTemplateTemplate', {
				'__template', "InfopanelStat",
				'BindTo', "AverageMorale",
			}),
			}),
		PlaceObj('XTemplateTemplate', {
			'__template', "InfopanelSection",
			'RolloverText', T(237838216252, --[[XTemplate sectionDome RolloverText]] "The average <em>Satisfaction</em> of all Tourists in this Dome."),
			'RolloverTitle', T(404306177597, --[[XTemplate sectionDome RolloverTitle]] "Average Satisfaction <Stat(AverageSatisfaction)>"),
			'Icon', "UI/Icons/Sections/satisfaction.tga",
		}, {
			PlaceObj('XTemplateTemplate', {
				'__template', "InfopanelStat",
				'BindTo', "AverageSatisfaction",
			}),
			}),
		}),
})

