DefineClass.Deposit = {
	__parents = { "EditorObject", "PinnableObject", "InfopanelObj" },
	flags = { efMarker = true },
	
	encyclopedia_id = false,
	resource = false, --"Metals", "Concrete", "Polymers" --something from Resources global table preferably.
	
	properties = {
		{ category = "Debug", name = "Marker", id = "DepositMarker", editor = "object", default = false, developer = true, read_only = true, dont_save = true},
	},
	display_name = "",
	display_icon = "",
	description = T(634, "<resource(resource)> Deposit"),
	
	pin_summary1 = "",
	pin_on_start = false,
	
	radius_max = 0,
	quality_mul = 100,
	
	city_label = false,
	max_amount = 0,
	
	marker = false,
}

function Deposit:GetDisplayName()
	return T{self.display_name, self}
end

function Deposit:AddToCitiesLabel()
	if self.city_label then
		GetCity(self):AddToLabel(self.city_label, self)
	end
end

function Deposit:RemoveFromCitiesLabel()
	if self.city_label then
		GetCity(self):RemoveFromLabel(self.city_label, self)
	end
end

function Deposit:Done()
	self:RemoveFromCitiesLabel()
	if SelectedObj == self then
		SelectObj(false)
	end
end

function Deposit:Init()
	self.encyclopedia_id = self.resource
end

function Deposit:GameInit()
	self:AdjustVisuals()
	self:AddToCitiesLabel()
end

function Deposit:GetDescription()
	return T{self.description, self}
end

function Deposit:GetResourceName()
	return self.resource and GetResourceInfo(self.resource) and GetResourceInfo(self.resource).display_name or ""
end

function Deposit:GetDepositMarker()
	local marker = self.marker
	if not marker then
		local realm = GetRealm(self)
		marker = realm:MapGet("map", "DepositMarker", function(marker, deposit) return marker.placed_obj == deposit end, self)[1]
	end
	return marker
end

function Deposit:IsExplorationBlocked()
end

function Deposit:IsDepleted()
end

function Deposit:CheatRefill()
end

function Deposit:CheatEmpty()
end

function Deposit:GetQualityMultiplier()
	return 100
end

function Deposit:IsExploitableBy(exploiter)
	return IsValid(exploiter) and exploiter.exploitation_resource == self.resource and not self:IsDepleted()
end

function Deposit:GetDepth()
	return 0
end

function Deposit:GetAmount()
	return 0
end

function Deposit:DoesHaveSupplyRequestForResource(resource)
	return self.resource == resource
end

local UnbuildableZ = buildUnbuildableZ()

local function CalcDepositZ(object)
	local q, r = WorldToHex(object)
	local game_map = GetGameMap(object)
	local z = game_map.realm:HexMaxHeight(q, r)
	local bz = game_map.buildable:GetZ(q, r)
	if bz ~= UnbuildableZ then
		z = Max(z, bz) 
	end
	return z - 30
end

GlobalVar( "g_CurrentDepositScale", const.SignsOverviewCameraScaleDown )
GlobalVar( "g_CurrentDepositOpacity", const.SignsOverviewCameraOpacityDown )

function Deposit:AdjustVisuals()
	self:SetScale(g_CurrentDepositScale)
	self:SetOpacity(g_CurrentDepositOpacity)
	self:SetZ(CalcDepositZ(self))
end

function SavegameFixups.Deposit_AdjustVisuals()
	MapForEach("map", "Deposit", function(obj)
		obj:AdjustVisuals()
	end)
end

----

GlobalVar("g_ResourceIconsTurnedOff", false)
GlobalVar("g_ResourceIconsVisible", true)
GlobalVar("ShowResourceIconReasons",  {})

function SetResourceIconsVisible(visible)
	if visible and not g_SignsVisible then return end
	if not visible and not g_ResourceIconsTurnedOff then return end
	local action = visible and "SetEnumFlags" or "ClearEnumFlags"
	
	local realm = GetActiveRealm()
	if realm then
		local deposits = realm:MapGet("map", "TerrainDeposit", "SubsurfaceDeposit")
		deposits = table.ifilter(deposits, function(index, obj) return obj.revealed end)
		for _,deposit in ipairs(deposits) do
			if visible then
				deposit:SetEnumFlags(const.efVisible)
			else
				deposit:ClearEnumFlags(const.efVisible)
			end
		end
	end
	g_ResourceIconsVisible = visible
end

function ShowResourceIcons(reason)
	reason = reason or false
	if next(ShowResourceIconReasons) == nil then
		SetResourceIconsVisible(true)
	end
	ShowResourceIconReasons[reason] = true
end

function HideResourceIcons(reason)
	reason = reason or false
	ShowResourceIconReasons[reason] = nil
	if next(ShowResourceIconReasons) == nil then
		SetResourceIconsVisible(false)
	end
end

function ToggleResourceIcons()
	g_ResourceIconsTurnedOff = not g_ResourceIconsTurnedOff
	SetResourceIconsVisible(not g_ResourceIconsTurnedOff)
end

----

function SavegameFixups.FixMarkerEnumFlag()
	local IsKindOf = IsKindOf
	local GetEnumFlags = CObject.GetEnumFlags
	local SetEnumFlags = CObject.SetEnumFlags
	local efMarker = const.efMarker
	MapForEach(function(obj)
		if GetEnumFlags(obj, efMarker) == 0 and IsKindOfClasses(obj, "Deposit", "TerrainWaterObject") then
			SetEnumFlags(obj, efMarker)
		end
	end)
end