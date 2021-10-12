DefineClass.FadingDecal = {
	__parents = { "Object", },
	decal_name = "",
	delay = 0,
	decal_fade_time = 1000,
	fading_decal_thread = false,
}

function FadingDecal:GameInit()
	self.fading_decal_thread = CreateGameTimeThread(function()
		Sleep(self.delay)
		if not IsValid(self) then
			return
		end
		local pos = self:GetPos()
		GetRealm(self):MapDelete(pos, 20*guim, self.decal_name)
		local decal = PlaceObjectIn(self.decal_name, self:GetMapID())
		decal:SetPos(pos)
		self:Attach(decal)
		decal:SetOpacity(100)
		local fade_time = self.decal_fade_time
		
		for opacity = 100, 0, -5 do
			Sleep(fade_time / 20)
			if not IsValid(decal) then return end
			decal:SetOpacity(opacity)
			local bbox = ObjectHierarchyBBox(decal)
			GetTerrain(self):InvalidateType(bbox)
		end
		if not IsValid(decal) then return end
		local bbox = ObjectHierarchyBBox(decal)
		GetTerrain(self):InvalidateType(bbox)
		DoneObject(decal)
		DoneObject(self)
	end)
end

function FadingDecal:Done()
	if CurrentThread() ~= self.fading_decal_thread and IsValidThread(self.fading_decal_thread) then
		DeleteThread(self.fading_decal_thread)
		self.fading_decal_thread = false
	end
end
