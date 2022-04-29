local UIL = UIL

if Platform.linux then
	local ui_images = {}

	function UIL_RequestImage(image)
		table.insert_unique(ui_images, image)
		UIL.RequestImage(image)
	end

	function OnMsg.SystemActivate()
		hr.TR_ForceReload = 1
		for _,image in ipairs(ui_images) do
			UIL.ReloadImage(image)
		end
	end
end
