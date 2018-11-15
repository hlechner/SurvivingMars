-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	group = "Default",
	id = "MarsRenameControl",
	PlaceObj('XTemplateWindow', {
		'__class', "XDialog",
		'Padding', box(0, -100, 0, 0),
		'HAlign', "center",
		'VAlign', "center",
	}, {
		PlaceObj('XTemplateLayer', {
			'layer', "XSuppressInputLayer",
		}),
		PlaceObj('XTemplateWindow', {
			'__class', "XFrame",
			'Margins', box(-30, 0, -30, 0),
			'Dock', "box",
			'VAlign', "top",
			'Image', "UI/CommonNew/rename.tga",
			'FrameBox', box(100, 0, 100, 0),
			'SqueezeX', false,
			'SqueezeY', false,
		}),
		PlaceObj('XTemplateWindow', {
			'__class', "XText",
			'Id', "idRenameTitle",
			'Padding', box(0, 25, 0, 0),
			'Dock', "top",
			'HAlign', "center",
			'TextStyle', "RenameTitle",
			'Translate', true,
		}),
		PlaceObj('XTemplateTemplate', {
			'__template', "MarsEdit",
			'Margins', box(0, 10, 0, 0),
			'Padding', box(48, 0, 48, 0),
			'HAlign', "stretch",
			'VAlign', "center",
		}),
		PlaceObj('XTemplateWindow', {
			'__class', "XToolBar",
			'Id', "idToolbar",
			'IdNode', false,
			'Dock', "top",
			'HAlign', "center",
			'LayoutHSpacing', 60,
			'Background', RGBA(0, 0, 0, 0),
			'Toolbar', "RenameActionBar",
			'Show', "text",
			'ButtonTemplate', "MenuEntry",
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "ok",
			'ActionName', T{6895, --[[XTemplate MarsRenameControl ActionName]] "OK"},
			'ActionToolbar', "RenameActionBar",
			'ActionShortcut', "Enter",
			'ActionGamepad', "ButtonA",
			'OnActionEffect', "close",
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "rename",
			'ActionName', T{10120, --[[XTemplate MarsRenameControl ActionName]] "RENAME"},
			'ActionToolbar', "RenameActionBar",
			'ActionGamepad', "ButtonY",
			'__condition', function (parent, context) return Platform.console and context and context.console_show end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "rename",
			'ActionName', T{11465, --[[XTemplate MarsRenameControl ActionName]] "VIRTUAL KEYBOARD"},
			'ActionToolbar', "RenameActionBar",
			'ActionGamepad', "ButtonY",
			'__condition', function (parent, context) return Platform.steam and GetUIStyleGamepad() and context and context.console_show end,
		}),
		PlaceObj('XTemplateAction', {
			'ActionId', "cancel",
			'ActionName', T{5450, --[[XTemplate MarsRenameControl ActionName]] "CANCEL"},
			'ActionToolbar', "RenameActionBar",
			'ActionShortcut', "Escape",
			'ActionGamepad', "ButtonB",
			'OnActionEffect', "close",
		}),
		}),
})

