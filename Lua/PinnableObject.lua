--[[@@@
@class PinnableObject
class overview...
--]]

DefineClass.PinnableCollection = {
	__parents = { "InitDone" },
	pins = {},
}

function PinnableCollection:Init()
	self.pins = {}
end

function PinnableCollection:OnLoad()
	for i=1,#self.pins do
		self.pins[i].is_pinned = true
	end
end

function PinnableCollection:UnpinAll(force)
	for i=#self.pins,1,-1 do
		local obj = self.pins[i]
		if force or obj:CanBeUnpinned() then 
			obj:TogglePin(force)
		end
	end
end

local function AddPinnedObjs(objects_to_add, list, used)
	local IsKindOf = IsKindOf
	for i,obj in ipairs(objects_to_add or empty_table) do
		if IsKindOf(obj, "PinnableObject") and obj:IsPinned() and not used[obj] then
			list[#list + 1] = obj
			used[obj] = true
		end
	end
end

function SortPins(map_id)
	local used, new_order = {}, {}
	local labels = Cities[map_id].labels or empty_table	
	local pinned_objects = GameMaps[map_id].pinnables.pins
	
	if #pinned_objects > 1 then
		--supply rockets
		AddPinnedObjs(labels.SupplyRocket, new_order, used)
		--rovers
		AddPinnedObjs(labels.Rover, new_order, used)
		--domes
		AddPinnedObjs(labels.Dome, new_order, used)
		--drones
		AddPinnedObjs(labels.Drone, new_order, used)
		--orbital probes (only the first in the label is pinned)
		local probes = labels.OrbitalProbe or empty_table
		if IsKindOf(probes[1], "PinnableObject") and probes[1]:IsPinned() then
			new_order[#new_order + 1] = probes[1]
			used[probes[1]] = true
		end
		--buildings
		AddPinnedObjs(labels.Building, new_order, used)
		--colonists
		AddPinnedObjs(labels.Colonist, new_order, used)
		--everything else
		AddPinnedObjs(pinned_objects, new_order, used)
		
		GameMaps[map_id].pinnables.pins = new_order
	end
end

function UnpinAll(force)
	for _, game_map in pairs(GameMaps) do
		game_map.pinnables:UnpinAll(force)
	end
end

local Map_Loading = false

function OnMsg.ChangeMap()
	Map_Loading = true
end

function OnMsg.ChangeMapDone()
	Map_Loading = false
end

DefineClass.PinnableObject = {
	__parents = { "Object" },
	
	properties = {
		{ template = true, name = T(3459, "Pin Rollover Context"), id = "pin_rollover_context", category = "Pin",  editor = "text", default = "", },
		{ template = true, name = T(765, "Pin Rollover"), id = "pin_rollover", category = "Pin",  editor = "text", default = "", translate = true, },
		{ template = true, name = T(3460, "Pin Rollover Hint"), id = "pin_rollover_hint", category = "Pin",  editor = "text", default = T(7604, "<left_click> Select"), translate = true, },
		{ template = true, name = T(3461, "Pin Rollover Hint Xbox"), id = "pin_rollover_hint_xbox", category = "Pin",  editor = "text", default = T(7605, "<ButtonA> View"), translate = true, },
		{ template = true, name = T(9622, "Pin Summary 2"), id = "pin_summary2", category = "Pin",  editor = "text", default = "", translate = true, },
		{ template = true, name = T(3462, "Pin Summary 1"), id = "pin_summary1", category = "Pin",  editor = "text", default = "", translate = true, },
		{ template = true, name = T(3465, "Pin Progress Value"), id = "pin_progress_value", category = "Pin",  editor = "text", default = "", },
		{ template = true, name = T(3466, "Pin Progress Max"), id = "pin_progress_max", category = "Pin",  editor = "text", default = "", },
		{ template = true, name = T(3467, "Pin on Start"), id = "pin_on_start", category = "Pin",  editor = "bool", default = false, },
		{ template = true, name = T(3468, "Blink"), id = "pin_blink", category = "Pin",  editor = "bool", default = false, },
		{ template = true, name = T(3469, "Obvious Blink"), id = "pin_obvious_blink", category = "Pin",  editor = "bool", default = false, },
	},
	
	is_pinned = false,
	repin = false,
	show_pin_toggle = true,
}

function PinnableObject:GameInit()	
	if self.pin_on_start then
		if Map_Loading or self:AutoPinAvailable() then 
			self:TogglePin()
		end
	end 
end

function PinnableObject:DetachFromRealm(map_id)
	local is_pinned = self:IsPinned()
	if is_pinned then
		self:TogglePin(true)
		self.repin = true
	end
end

function PinnableObject:AttachedToRealm(map_id)
	if self.repin then
		self.repin = false
		self:TogglePin(true)
	end
end

function PinnableObject:AutoPinAvailable()
	local options = AccountStorage.Options
	local pin_it = false

	local pins = GameMaps[self:GetMapID()].pinnables.pins
	if #pins > AccountStorage.Options.AutoPinMaxNum then
		return pin_it
	end
	
	if ( self:IsKindOf("Dome") and options.AutoPinDomes ) or
		( self:IsKindOf("DroneHub") and options.AutoPinDroneHubs ) or 
		( self:IsKindOf("BaseRover") and options.AutoPinRovers ) then  
			pin_it = true
	elseif self:IsKindOf("Colonist") then
		local colonist_traits = self.traits
		if colonist_traits.Founder and options.AutoPinFounders then
			pin_it = true
		end
		if options.AutoPinRareColonists then
			for trait_id, _ in pairs(self.traits) do
				if g_RareTraits[trait_id] then
					pin_it = true
					break
				end	
			end
		end
	end
	return pin_it
end

function PinnableObject:Done()
	if self:IsPinned() then
		self:TogglePin()
	end
end

function PinnableObject:GetPinProgress()
	local context = self.pin_rollover_context ~= "" and self:HasMember(self.pin_rollover_context) and self[self.pin_rollover_context] or self
	local max = context:GetProperty(self.pin_progress_max) or 100
	local progress = context:GetProperty(self.pin_progress_value) or 0
	return MulDivRound(progress, 100, max)
end

function PinnableObject:GetPinIcon()
	return self.display_icon
end

function PinnableObject:GetTitle()
	return self:GetDisplayName()
end

function PinnableObject:GetPinSummary()
	if self.pin_summary2 ~= "" then
		return T(9623, "<pin_summary1><newline><pin_summary2>")
	else
		return self.pin_summary1
  end
end

function PinnableObject:TogglePin(force, map_id)
	map_id = map_id or self:GetMapID()
	local pins_dlg = GetDialog("PinsDlg")
	local can_update_visual_pins = pins_dlg and pins_dlg.map_id == map_id and map_id == ActiveMapID
	local pins = GameMaps[map_id].pinnables.pins
	if self:IsPinned() then
		if self:CanBeUnpinned() or force then
			self.is_pinned = false
			table.remove_entry(pins, self)
			if can_update_visual_pins then
				pins_dlg:Unpin(self)
			end
		end
	else
		assert(IsValid(self), "Pinning an invalid object")
		self.is_pinned = true
		table.insert_unique(pins, self)
		if can_update_visual_pins then
			pins_dlg:Pin(self)
			SortPinnedObjs()
		end
	end
end

function PinnableObject:IsPinned()
	return self.is_pinned
end

function PinnableObject:CanBeUnpinned()
	return true
end

function PinnableObject:OnPinClicked(gamepad)
	-- return true to disable the standard select/view funcionality of the pin dialog
end

