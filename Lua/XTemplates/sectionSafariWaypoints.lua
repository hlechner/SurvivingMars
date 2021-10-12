-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	group = "Infopanel Sections",
	id = "sectionSafariWaypoints",
	PlaceObj('XTemplateTemplate', {
		'__template', "InfopanelSection",
		'RolloverText', T(142125981715, --[[XTemplate sectionSafariWaypoints RolloverText]] "View and adjust the RC Safari's waypoints. The RC Safari has a maximum of 10 waypoints. Moving the RC Safari manually removes the currently set waypoints."),
		'Title', T(401282745585, --[[XTemplate sectionSafariWaypoints Title]] "Waypoints<right><count(safari_route)>/10"),
	}, {
		PlaceObj('XTemplateTemplate', {
			'__template', "InfopanelText",
			'Text', T(440373028715, --[[XTemplate sectionSafariWaypoints Text]] "Expected satisfaction reward: <last_awarded_satisfaction>/25"),
		}),
		PlaceObj('XTemplateWindow', {
			'__class', "XContextControl",
			'GridY', 5,
			'LayoutMethod', "Grid",
			'LayoutHSpacing', 2,
			'UniformRowHeight', true,
			'BorderColor', RGBA(32, 32, 32, 0),
			'Background', RGBA(255, 255, 255, 0),
		}, {
			PlaceObj('XTemplateForEach', {
				'comment', "waypoint",
				'array', function (parent, context) return context.safari_route end,
				'run_after', function (child, context, item, i, n)
					child:SetText(Untranslated("Waypoint #"..tostring(i)))
					child.waypoint_index = i
					child.GridY = ((i-1)%5)+1
					child.GridX = DivCeil(i,5)
					
					local realm = GetRealm(context)
					local waypoint = context.safari_route[i]
					local sights = GetVisibleSights(realm, waypoint, context.sight_range)
					
					local lines = {}
					for _,sight in  ipairs(sights) do
						table.insert(lines, sight:GetName())
					end
					local string = table.concat(lines, "\n")
					if #lines == 0 then
						string = T(12808, "No sights visible")
					end
					child:SetRolloverText(string)
				end,
			}, {
				PlaceObj('XTemplateWindow', {
					'__class', "XTextButton",
					'RolloverTemplate', "Rollover",
					'RolloverAnchor', "left",
					'RolloverTitle', T(899882583669, --[[XTemplate sectionSafariWaypoints RolloverTitle]] "Visible sights"),
					'RolloverHintGamepad', T(615719208241, --[[XTemplate sectionSafariWaypoints RolloverHintGamepad]] "View waypoint <ButtonA> Insert new waypoint <ButtonX>"),
					'Padding', box(20, 1, 2, 1),
					'HAlign', "left",
					'VAlign', "top",
					'MouseCursor', "UI/Cursors/Rollover.tga",
					'RelativeFocusOrder', "next-in-line",
					'OnPress', function (self, gamepad)
						local safari = ResolvePropObj(self.context)
						local broadcast = not gamepad and IsMassUIModifierPressed()
						if broadcast then
							print("Insert Waypoint")
							safari:InsertWaypointAfter(self.waypoint_index)
							ObjModified(safari)
						else
							print("Move Camera to waypoint")
							local pos = safari.safari_route[self.waypoint_index]
							ViewObjectMars(pos)
						end
						XCreateRolloverWindow(self, gamepad, true)
					end,
					'AltPress', true,
					'OnAltPress', function (self, gamepad)
						local safari = ResolvePropObj(self.context)
						if gamepad then
							safari:MoveWaypoint(self.waypoint_index)
						else
							safari:MoveWaypoint(self.waypoint_index)
						end
						
						ObjModified(safari)
						XCreateRolloverWindow(self, gamepad, true)
					end,
					'Image', "UI/CommonNew/ccc_categories_small1.tga",
					'ImageScale', point(800, 700),
					'FrameBox', box(35, 30, 30, 30),
					'Rows', 2,
					'Columns', 2,
					'TextStyle', "RolloverTextStyleHighlight",
					'Translate', true,
					'ColumnsUse', "abaaa",
				}),
				}),
			}),
		}),
})

