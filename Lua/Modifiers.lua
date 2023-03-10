InitDoneMethods[#InitDoneMethods + 1] = "OnModifiableValueChanged"

DefineClass.Modifiable = {
	__parents = { "InitDone" },
	
	-- Each modifiable property has modifiable = true in its property definition
	-- Such properties should not have Get<prop>/Set<prop> functions
	
	-- A base_<prop> member is autogenerated, it is initialized with the modifiable prop's default value.
	-- A SetBase(prop, value) function is provided.
	-- SetBase(prop, value) can be used to set the base_<prop> value, which is the value upon which modifications are applied.
	-- It automatically recalcs the actual modifiable value after the base val is changed.
	-- Syntax: self:SetBase("property_name", val)
	
	-- OnModifiableValueChanged(prop) callback function is provided.
	-- It is called whenever a modifiable property's value has been changed. This can be either due to modifiers getting changed or due to the base value getting changed.
	-- It is part of the InitDoneMethods group, hence all of a classes parents implementations will get called, including the classes own implementation. The call calls parents' impl. first.
	
	-- A ModifyValue(value, prop, [modification]) function is provided.
	-- It applies all provided modifications or if none are provided the current property modifications to value.

	-- Modifications keyed by property name
	--	for each property we keep a table
	--   .amount, .percent .cap - aggregated values (value = base_value * (100 + Min(percent, cap)) / 100 + amount)
	--   [1], [2], ... - contributing modifiers
	modifications = false,
}

function Modifiable:InitBaseProperties()
	for _, meta in ipairs(self:GetProperties()) do
		if meta.modifiable then
			local prop = meta.id
			self["base_" .. prop] = self[prop]
		end
	end
end

Modifiable.Init = Modifiable.InitBaseProperties

function Modifiable:UpdateModifier(action, modifier, amount, percent)
	-- we keep the action parameter in case we want to keep the modifiers in a list for text display purposes
	if amount == 0 and percent == 0 then return end
	local prop = modifier.prop
	local base_prop = "base_" .. prop
	
	if not self:HasMember(base_prop) then
		return
	end
	local modifications = self.modifications
	if not modifications then
		modifications = {}
		self.modifications = modifications
	end
	local modification = modifications[prop]
	if not modification then
		local prop_meta = self:GetPropertyMetadata(prop)
		modification = { amount = 0, percent = 100, min = prop_meta and prop_meta.min, max = prop_meta and prop_meta.max }
		modifications[prop] = modification
	end
	
	modification.amount = (modification.amount or 0) + amount
	modification.percent = (modification.percent or 100) + percent
	
	if action == "add" then
		modification[#modification +1] = modifier
	elseif action == "remove" then
		table.remove_entry(modification, modifier)
	end
	
	-- recalc value
	local old_value = self[prop]
	local base_value = self[base_prop]
	if type(base_value) ~= "number" then
		-- savegame compat
		assert(type(old_value) == "number")
		base_value = old_value
		self[base_prop] = base_value
	end
	local value = DirectlyModifiedConstValue(prop, base_value) or base_value
	value = self:ModifyValue(value, prop, modification)
	if old_value ~= value then
		self[prop] = value
		self:RecursiveCall(true, "OnModifiableValueChanged", prop, old_value,value)
	end
end

local max_int64 = 2^63 - 1
local min_int64 = -(2^63)
function Modifiable:ModifyValue(value, prop, modification) -- apply modifiers of a prop to a value
	if type(value) ~= "number" then
		assert(false, "Invalid value!")
		return 0
	end
	if not modification then
		local modifications = self.modifications
		modification = modifications and modifications[prop]
	end
	if modification then
		value = MulDivRound(value, modification.percent or 100, 100) + (modification.amount or 0)
		value = Clamp(value, modification.min or min_int64, modification.max or max_int64)
	end
	return value
end

--these modifications have not been applied to any obj, so we have to calc vals,
function Modifiable:ModifyValueWithNonAppliedModifications(value, prop_id, label_modifiers)	
	local total_modification = { amount = 0, percent = 100 }
	
	for mod_id, modifier in pairs(label_modifiers or empty_table) do --if from tech effect, mod id is the tech effect obj, else idk
		if modifier.prop == prop_id then
			total_modification.amount = (modifier.amount or 0) + total_modification.amount
			total_modification.percent = (modifier.percent or 0) + total_modification.percent
		end
	end
	
	return Modifiable.ModifyValue(self, value, prop_id, total_modification)
end

function Modifiable:SetBase(prop, value)
	self["base_" .. prop] = value
	value = self:ModifyValue(value, prop)
	if self[prop] ~= value then
		local old_value = self[prop]
		self[prop] = value
		self:RecursiveCall(true, "OnModifiableValueChanged", prop, old_value, value)
	end
end

function Modifiable:GetClassValue(prop)
	return  (getmetatable(self))[prop]
end

function Modifiable:RestoreBase(prop)
	self:SetBase(prop, self:GetClassValue(prop))
end

function Modifiable:GetPropertyModifierIds(prop)
	local modifications = self.modifications
	if not modifications then return empty_table end
	local modification = modifications[prop]
	if not modification then return empty_table end

	local mod_ids = {}
	for _, mod in ipairs(modification) do
		mod_ids[#mod_ids+1] = mod.id
	end

	return mod_ids
end

function Modifiable:GetPropertyModifiers(prop)
	local modifications = self.modifications
	if not modifications then return empty_table end
	return modifications[prop]
end

function Modifiable:GetPropertyModifierTexts(prop)
	local modification = self:GetPropertyModifiers(prop)
	if not modification then return empty_table end

	local mod_texts = {}
	for _, mod in ipairs(modification) do
		if mod.display_text then
			mod_texts[#mod_texts+1] = T{mod.display_text, mod}
		end
	end

	return mod_texts
end

function Modifiable:FindModifier(id, prop)
	if not self.modifications then return end
	local modification = self.modifications[prop]
	return table.find_value(modification, "id", id)
end

function Modifiable:OnModifiableValueChanged(prop,old_value, new_value)
end

function Modifiable:SetModifier(prop, id, amount, percent, display_text)
	amount, percent = amount or 0, percent or 0
	local modifier = self:FindModifier(id, prop)
	if modifier then
		if amount~=0 or percent~=0 then
			local amount_change, percent_change = amount-modifier.amount, percent-modifier.percent
			if amount_change ~= 0 or percent_change ~= 0 then
				self:UpdateModifier("change", modifier, amount_change, percent_change)
				modifier.amount, modifier.percent = amount, percent
			end
			modifier.display_text = display_text
		else
			self:UpdateModifier("remove", modifier, -modifier.amount, -modifier.percent)
		end
	elseif amount~=0 or percent~=0 then
		self:UpdateModifier("add", { 
			id = id,
			prop = prop,
			amount = amount,
			percent = percent,
			display_text = display_text,
		}, amount, percent)
	end
end

if Platform.developer then
function OnMsg.ClassesGenerate(classdefs)
	for name, def in pairs(classdefs) do
		local properties = def.properties
		for _, meta in ipairs(properties or empty_table) do
			if meta.modifiable then
				local prop = meta.id
				--print(name, prop)
				if def["Get" .. prop] or def["Set" .. prop] then
					printf("Class %s should not have accessor functions for the modifiable property %s", name, prop)
				end
				def["base_" .. prop] = false
			end
		end
	end
end
end


----- Modifier

DefineClass.Modifier = {
	__parents = { "InitDone" },
	id = false,
	prop = false,
	amount = 0,
	percent = 0,
	display_text = false,
}

----- LabelModifier

DefineClass.LabelModifier = {
	__parents = { "Modifier" },
	container = false,
	label = false,
	id = false,
	check_if_prop_exists = false,
	working = false,
}

function LabelModifier:Init()
	self:TurnOn()
end

function LabelModifier:Done()
	self:TurnOff()
end

function LabelModifier:Change(amount, percent)
	amount, percent = amount or 0, percent or 0
	local amount_change, percent_change = amount-self.amount, percent-self.percent
	if amount_change ~= 0 or percent_change ~= 0 then
		if self.working then
			self:TurnOff()
			self.amount, self.percent = amount, percent
			self:TurnOn()
		else
			self.amount, self.percent = amount, percent
		end
	end
end

function LabelModifier:TurnOn()
	self.working = true
	self.container:SetLabelModifier(self.label, self.id, self, self.check_if_prop_exists)
end

function LabelModifier:TurnOff()
	self.working = false
	self.container:SetLabelModifier(self.label, self.id, nil)
end

function LabelModifier:IsApplied()
	return self.working
end

----- ObjectModifier

DefineClass.ObjectModifier = {
	__parents = { "Modifier" },
	target = false,
	is_applied = false,
	display_text = false,
}

function ObjectModifier:Init()
	self:Add()
end

function ObjectModifier:Done()
	self:Remove()
end

function ObjectModifier:Add()
	if not self.is_applied then
		self.target:UpdateModifier("add", self, self.amount, self.percent)
		self.is_applied = true
	end
end

function ObjectModifier:Remove()
	if self.is_applied then
		self.target:UpdateModifier("remove", self, -self.amount, -self.percent)
		self.is_applied = false
	end
end

ObjectModifier.TurnOn = ObjectModifier.Add
ObjectModifier.TurnOff = ObjectModifier.Remove

function ObjectModifier:Change(amount, percent, display_text)
	amount, percent = amount or 0, percent or 0
	local amount_change, percent_change = amount-self.amount, percent-self.percent
	if amount_change ~= 0 or percent_change ~= 0 then
		if self.is_applied then
			self.target:UpdateModifier("change", self, amount_change, percent_change )
		end
	end
	self.amount, self.percent = amount, percent
	self.display_text = display_text
end

function ObjectModifier:IsApplied()
	return self.is_applied
end

---one modifier to rule them all.
DefineClass.MultipleObjectsModifier = {
	__parents = { "Modifier" },
	targets = false,
	init_passed = false,
}

function MultipleObjectsModifier:Add(t)
	t:UpdateModifier("add", self, self.amount, self.percent)
end

function MultipleObjectsModifier:Remove(t)
	t:UpdateModifier("remove", self, -self.amount, -self.percent)
end

function MultipleObjectsModifier:Init()
	self.targets = self.targets or {}
	for i = 1, #self.targets do
		self:Add(self.targets[i])
	end
	
	self.init_passed = true
end

function MultipleObjectsModifier:Done()
	for i = 1, #(self.targets or "") do
		self:Remove(self.targets[i])
	end
end

function MultipleObjectsModifier:AddTarget(t)
	table.insert(self.targets, t)
	if self.init_passed then
		self:Add(t)
	end
end

function MultipleObjectsModifier:RemoveTarget(t)
	table.remove_entry(self.targets, t)
	if self.init_passed then
		self:Remove(t)
	end
end

function MultipleObjectsModifier:CleanInvalidTargets()
	for i = #self.targets, 1, -1 do
		if not IsValid(self.targets[i]) then
			table.remove(self.targets, i)
		end
	end
end

function MultipleObjectsModifier:CanDelete()
	if #self.targets == 0 then return true end
	for i = 1, #self.targets do
		if IsValid(self.targets[i]) then return false end
	end
	
	return true
end

function MultipleObjectsModifier:Change(amount, percent)
	amount, percent = amount or 0, percent or 0
	local amount_change, percent_change = amount-self.amount, percent-self.percent
	if amount_change ~= 0 or percent_change ~= 0 then
		for i = 1, #(self.targets or "") do
			self.targets[i]:UpdateModifier("change", self, amount_change, percent_change )
		end
	end
	self.amount, self.percent = amount, percent
end


------ Global Game Consts

--[[@@@
@class Consts
Consts is a class container for modifiable game constants. g_Consts is its global instance used to access the const values.
Reference: [GameValue](ModItemGameValue.md.html)
--]]

DefineClass.Consts = {
	__parents = { "Modifiable" }
}

function Consts:OnModifiableValueChanged(prop,old_value, new_value)
	Msg("ConstValueChanged", prop, old_value, new_value)
end

GlobalObj("g_Consts", "Consts")

-- apply mod items
function OnMsg.NewMap()
	for _, mod in ipairs(ModsLoaded or empty_table) do
		for _, item in ipairs(mod.items) do
			if item:IsKindOf("ModItemGameValue") and item.id ~= "" then
				-- create a modifier object from this mod item
				g_Consts:UpdateModifier("add", Modifier:new{
						prop = item.id,
						amount = item.amount,
						percent = item.percent
					}, item.amount, item.percent)
			end
		end
	end
end

-- add as (modifiable) properties to a class all const defs from a given group
-- 		DefinClass.A = { __parents = { "Modifiable" }, ... }
--		AddConstGroupAsModifiableProperties(A, "Gameplay")
function AddConstGroupAsModifiableProperties(classdef, group)
	assert(Presets.ConstDef[group])
	local properties = classdef.properties or {}
	classdef.properties = properties
	for _, const in ipairs(Presets.ConstDef[group] or empty_table) do
		if const.type == "number" or const.type == nil then
			properties[#properties + 1] = {
				category = group,
				id = const.id,
				editor = "number",
				default = const.value,
				scale = const.scale, 
				modifiable = true,
				name = const.name,
				help = const.help,
			}
		end
	end
end

----

if FirstLoad then
	ModifiablePropsComboItems = {}
	ModifiablePropScale = {}
end

function OnMsg.ClassesBuilt()
	local scale = {}
	ClassDescendants("Modifiable", function(name, classdef)
		local class_props = classdef:GetProperties()
		for i = 1,#class_props do
			local prop = class_props[i]
			if prop.modifiable then
				local new_scale = GetPropScale(prop.scale)
				local existing_scale = scale[prop.id]
				if not existing_scale then
					scale[prop.id] = new_scale
				elseif existing_scale ~= new_scale then
					assert(false, "Modifiable property with different scale factors!")
				end
			end
		end
	end)
	ModifiablePropsComboItems = table.keys(scale)
	table.sort(ModifiablePropsComboItems, CmpLower)
	ModifiablePropScale = scale
end

function ClassModifiablePropsCombo(obj)
	local existing, props = {}, {}
	local class_props = obj:GetProperties()
	for i = 1,#class_props do
		local prop = class_props[i]
		if prop.modifiable and not existing[prop.id] then
			existing[prop.id] = true
			props[#props + 1] = {value = prop.id, text = prop.name or prop.id}
		end
	end
	TSort(props, "text")
	return props
end

----

if Platform.developer then

RecursiveCallIgnoreChecks.OnModifiableValueChanged = true

end