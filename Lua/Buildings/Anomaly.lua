function GetSequenceListIndex(sequence, sequence_list)
	local list = DataInstances.Scenario[sequence_list]
	if not list then
		printf("Subsurface anomaly sequence start failed - probably missing sequence list %s?", sequence_list)
		assert(list)
		return false
	end
	
	local sequence_index = table.find(list, "name", sequence)
	local found_sequence = sequence_index and sequence_index > 0
	if not found_sequence then
		assert(found_sequence, "Subsurface anomaly sequence cannot find " .. sequence .. " in " .. sequence_list)
		return false
	end

	return sequence_index
end

local anomaly_tech_actions = {
	{ text = T(1, "Unlock Breakthrough"), value = "breakthrough" },
	{ text = T(2, "Unlock Tech"), value = "unlock" },
	{ text = T(3, "Grant Research"), value = "complete" },
	{ text = T(8693, "Grant Resources"), value = "resources" },
}

DefineClass.SubsurfaceAnomalyMarker = {
	__parents = { "DepositMarker", "SafariSight" },
	properties = {
		{ category = "Anomaly", name = T(4, "Tech Action"),             id = "tech_action",              editor = "dropdownlist", default = false, items = anomaly_tech_actions },
		{ category = "Anomaly", name = T(5, "Sequence"),                id = "sequence",                 editor = "dropdownlist", default = "",    items = function(marker) return table.map(DataInstances.Scenario[marker.sequence_list], "name") end, help = "Sequence to start when the anomaly is scanned" },
		{ category = "Anomaly", name = T(3775, "Sequence List"),        id = "sequence_list",            editor = "dropdownlist", default = "Anomalies",     items = function() return table.map(DataInstances.Scenario, "name") end, },
		{ category = "Anomaly", name = T(6, "Depth Layer"),             id = "depth_layer",              editor = "number",       default = 1,     min = 1, max = const.DepositDeepestLayer}, --depth layer
		{ category = "Anomaly", name = T(7, "Is Revealed"),             id = "revealed",                 editor = "bool",         default = false },
		{ category = "Anomaly", name = T(8, "Breakthrough Tech"),       id = "breakthrough_tech",        editor = "text",         default = "" },
		{ category = "Anomaly", name = T(8694, "Granted Resource"),     id = "granted_resource",         editor = "dropdownlist", default = "", items = ResourcesDropDownListItems, },
		{ category = "Anomaly", name = T(8695, "Granted Amount"),       id = "granted_amount",           editor = "number",       default = 0, min = 0, scale = const.ResourceScale, },
	},
	new_pos_if_obstruct = true,

	sight_name = T(12701, "Anomaly"),
	sight_category = "Environmental Hotspot",
	sight_satisfaction = 5,
}

function SubsurfaceAnomalyMarker:Init()
	if self.sequence ~= "" and self.sequence_list ~= "" then
		assert(GetSequenceListIndex(self.sequence, self.sequence_list))
	end
end

function SubsurfaceAnomalyMarker:EditorGetText()
	return "Anomaly " .. (self.tech_action or self.sequence)
end

function SubsurfaceAnomalyMarker:GetDepthClass()
	return self.depth_layer <= 1 and "subsurface" or "deep"
end

function SubsurfaceAnomalyMarker:IsActive()
	return IsValid(self.placed_obj)
end

function PlaceAnomaly(params, map_id)
	local classdef = params.tech_action and rawget(g_Classes, "SubsurfaceAnomaly_" .. params.tech_action) or SubsurfaceAnomaly
	return classdef:new(params, map_id)
end

function SubsurfaceAnomalyMarker:PlaceAnomaly(sequence)
	return PlaceAnomaly({
		depth_layer = self.depth_layer,
		revealed = self.revealed,
		tech_action = self.tech_action,
		granted_resource = self.granted_resource,
		granted_amount = self.granted_amount,
		sequence = sequence,
		sequence_list = self.sequence_list,
		breakthrough_tech = self.breakthrough_tech, --randomly assigned in City:InitBreakThroughAnomalies
	}, self:GetMapID())
end

function SubsurfaceAnomalyMarker:SpawnDeposit()
	local sequence = self.sequence
	
	if not self.tech_action then
		if self.sequence == "" and self.sequence_list ~= "" then
			sequence = table.rand(DataInstances.Scenario[self.sequence_list]).name
		end
	
		if self.sequence_list ~= "" then
			assert(GetSequenceListIndex(sequence, self.sequence_list))
		end
	end

	return self:PlaceAnomaly(sequence)
end

DefineClass.SubsurfaceSpecialAnomalyMarker = {
	__parents = { "SubsurfaceAnomalyMarker" },
	properties = {
		{ category = "Anomaly", name = T(1000067, "Display Name"), id = "display_name", editor = "text", default = "", translate = true},
		{ category = "Anomaly", name = T(1000017, "Description"), id = "description", editor = "text", default = "", translate = true},
	},
	rare = false,
}

function SubsurfaceSpecialAnomalyMarker:PlaceAnomaly(sequence)
	return PlaceAnomaly({
		display_name = self.display_name ~= "" and self.display_name or nil,
		description = self.description ~= "" and self.description or nil,
		tech_action = self.tech_action,
		granted_resource = self.granted_resource,
		granted_amount = self.granted_amount,
		sequence = sequence,
		sequence_list = self.sequence_list,
		breakthrough_tech = self.breakthrough_tech,
		rare = self.rare,
	}, self:GetMapID())
end

function SubsurfaceSpecialAnomalyMarker:EditorGetText()
	local prefix = self.rare and "Rare anomaly " or "Special Anomaly " 
	return prefix .. (self.tech_action or self.sequence)
end

DefineClass.SubsurfaceRareAnomalyMarker = {
	__parents = { "SubsurfaceSpecialAnomalyMarker" },
	display_name = T(14309, "Rare anomaly"),
	description = T(14310, "Our scans have picked up a trace of something potentially revolutionary. We should investigate this as soon as possible.<newline><newline>Send an RC Explorer to analyze the Anomaly."),
	sequence_list = "UndergroundAnomalies_Rare",
	rare = true,
}

DefineClass.SubsurfaceAnomaly = {
	__parents = { "SubsurfaceDeposit", "PinnableObject", "UngridedObstacle", "InfopanelObj", "Shapeshifter" },
	flags = { gofRealTimeAnim = true },
	
	rare = false,

	entity = "Anomaly_01",
	
	properties =
	{
		{ name = T(4, "Tech Action"),             id = "tech_action",              editor = "dropdownlist", default = false, items = anomaly_tech_actions },
		{ name = T(5, "Sequence"),                id = "sequence",                 editor = "dropdownlist", items = function() return table.map(DataInstances.Scenario.Anomalies, "name") end, default = "", help = "Sequence to start when the anomaly is scanned" },
		{ name = T(8694, "Granted Resource"), 			id = "granted_resource",			 editor = "dropdownlist", default = "", items = ResourcesDropDownListItems, },
		{ name = T(8695, "Granted Amount"),				id = "granted_amount",				 editor = "number", 		 default = 0, min = 0, scale = const.ResourceScale, },
		{ name = T(8696, "Expiration Time"),				id = "expiration_time",			 editor = "number",		 default = 0, scale = const.HourDuration },
	},
	
	display_name = T(9, "Anomaly"),
	display_icon = "UI/Icons/Buildings/anomaly.tga",
	
	-- pin section
	pin_rollover = T(10, "<Description>"),
	pin_summary1 = "",
	pin_progress_value = "",
	pin_progress_max = "",
	pin_on_start = false,
	
	scanning_progress = false,
	spawn_time = false,
	expiration_thread = false,
	
	resource = "Anomaly",
	breakthrough_tech = false,
	description = false,
	
	city_label = "Anomaly",
	
	fx_actor_class = "SubsurfaceAnomaly",
	ip_template = "ipAnomaly",
	
	auto_rover = false,
}

function SubsurfaceAnomaly:GetModifiedBSphereRadius(r)
	return MulDivRound(r, 75, 100)
end

DefineClass.SubsurfaceAnomaly_breakthrough = {
	__parents = { "SubsurfaceAnomaly" },
	entity = "Anomaly_02",
	tech_action = "breakthrough",
	description = T(11, "Our scientists believe that this Anomaly may lead to a <em>Breakthrough</em>.<newline><newline>Send an <em>Explorer</em> to analyze the Anomaly."),
}

DefineClass.SubsurfaceAnomaly_unlock = {
	__parents = { "SubsurfaceAnomaly" },
	entity = "Anomaly_04",
	tech_action = "unlock",
	description = T(12, "Scans have detected some interesting readings that might help us discover <em>new Technologies</em>.<newline><newline>Send an <em>Explorer</em> to analyze the Anomaly."),
}
function SubsurfaceAnomaly_breakthrough:EditorGetText()
	return "Breakthrough Anomaly"
end

DefineClass.SubsurfaceAnomaly_complete = {
	__parents = { "SubsurfaceAnomaly" },
	entity = "Anomaly_05",
	tech_action = "complete",
	description = T(13, "Sensors readings suggest that this Anomaly will help us with our current <em>Research</em> goals.<newline><newline>Send an <em>Explorer</em> to analyze the Anomaly."),
}
DefineClass.SubsurfaceAnomaly_aliens = {
	__parents = { "SubsurfaceAnomaly" },
	entity = "Anomaly_03",
	tech_action = "aliens",
	description = T(14, "We have detected alien artifacts at this location that will <em>speed up</em> our Research efforts.<newline><newline>Send an <em>Explorer</em> to analyze the Anomaly."),
}

function SubsurfaceAnomaly:Init()
	self.scanning_progress = 0
end

function SubsurfaceAnomaly:GameInit()	
	if self.rare then
		self:ChangeEntity("Rare" .. self.entity)
	end
	
	if self.expiration_time > 0 then
		self.spawn_time = GameTime()
		self.expiration_thread = CreateGameTimeThread(function()
			Sleep(self.expiration_time)
			if not IsValid(self) then
				return
			end
			self:OnExpired()
			DoneObject(self)
		end)
	end
end

function SubsurfaceAnomaly:Done()
	if self == SelectedObj then
		SelectObj()
	end
end

function SubsurfaceAnomaly:StartSequence(sequence, scanner, pos)
	assert(sequence ~= "")
	local sequence_index = GetSequenceListIndex(self.sequence, self.sequence_list)
	local list = DataInstances.Scenario[self.sequence_list]
	
	local expect_instance = list.singleton and sequence_index > 1
	local player, created = CreateSequenceListPlayer(list, self:GetMapID())
	if expect_instance and created then
		print("Not starting", sequence, "because the sequence that spawned this anomaly was restarted.")
		return 
	end

	local state = player:StartSequence(sequence)
	if not state then
		printf("Subsurface anomaly sequence start failed - probably missing sequence %s in list %s?", sequence, self.sequence_list)
		assert(state)
		return
	end

	local registers = player.seq_states[sequence].registers
	registers.anomaly_pos = pos
	if scanner then
		assert(IsKindOf(scanner, "ExplorerRover"))
		registers.rover = scanner
	end
end

function SubsurfaceAnomaly:UnlockTechs(scanner)
	local research = scanner and scanner.city.colony or UIColony
	local new_unlocked = {}
	local fields = {}
	for field_id, field in pairs(TechFields) do
		if field.discoverable then
			fields[#fields + 1] = field_id
		end
	end
	table.sort(fields)
	if SessionRandom:Random(100) < 75 then
		while table.count(new_unlocked) < 2 do
			local field, idx = SessionRandom:TableRand(fields)
			if not field then
				break
			end
			local tech_id = research:DiscoverTechInField(field)
			if tech_id then
				new_unlocked[tech_id] = true
			else
				table.remove(fields, idx)
			end
		end
	else
		for i=1,#fields do
			local tech_id = research:DiscoverTechInField(fields[i])
			if tech_id then
				new_unlocked[tech_id] = true
			end
		end
	end
	return table.keys(new_unlocked, true)
end

function GetAnomalyResearchPoints(map_id)
	return SessionRandom:TableRand{1000, 1250, 1500}
end

function SubsurfaceAnomaly:GrantRP(scanner)
	local research = scanner and scanner.city.colony or UIColony
	local points = GetAnomalyResearchPoints(self:GetMapID())
	research:AddResearchPoints(points)
	return points
end

function SubsurfaceAnomaly:OnRevealedValueChanged()
	if not self.revealed then return end
	self:SetScale(const.SignsOverviewCameraScaleDown)
	self:SetVisible(not IsEditorActive())
	self:OnReveal()
end

function SubsurfaceAnomaly:PickVisibilityState()
	self:SetVisible(not IsEditorActive() and self.revealed and g_SignsVisible and g_ResourceIconsVisible)
end

SubsurfaceAnomaly.EditorEnter = SubsurfaceAnomaly.PickVisibilityState
SubsurfaceAnomaly.EditorExit = SubsurfaceAnomaly.PickVisibilityState

function SubsurfaceAnomaly:Setdepth_layer(depth)
	if depth ~= self.depth_layer and depth >= 1 and depth <= const.DepositDeepestLayer then
		self.depth_layer = depth
	end
end

GlobalVar("g_ScannedAnomaly", 0)
function SubsurfaceAnomaly:ScanCompleted(scanner)
	local research = scanner and scanner.city and scanner.city.colony or UIColony
	local tech_action = self.tech_action
	local map_id = self:GetMapID()
	if tech_action == "breakthrough" then
		local def = TechDef[self.breakthrough_tech]
		if not def then
			assert(false, "No such breakthrough tech: " .. self.breakthrough_tech)
		elseif research:SetTechDiscovered(self.breakthrough_tech) then
			AddOnScreenNotification("BreakthroughDiscovered", OpenResearchDialog, {name = def.display_name, context = def, rollover_title = def.display_name, rollover_text = def.description}, nil, map_id)
		else
			-- already discovered
			tech_action = "unlock"
		end
	end
	if tech_action == "unlock" then
		local new_unlocks = self:UnlockTechs(scanner)
		if #new_unlocks > 0 then
			local list_of_techs = {}
			for i=1,#new_unlocks do
				list_of_techs[i] = TechDef[new_unlocks[i]].display_name
			end
			local list_text = table.concat(list_of_techs, '\n')
			AddOnScreenNotification("TechUnlockAnomalyAnalyzed", function()
				CreateRealTimeThread(function()
					local res = WaitPopupNotification("AnomalyAnalyzed", { params = {list_text = list_text}, start_minimized = false })
					if res == 1 then
						OpenResearchDialog()
					end
					RemoveOnScreenNotification("TechUnlockAnomalyAnalyzed", map_id)
				end)
			end, nil, nil, map_id)
		else
			tech_action = "complete"
		end
	end
	if tech_action == "complete" then
		local points = self:GrantRP(scanner)
		if points then
			AddOnScreenNotification("GrantRP", nil, {points = points, resource = "Research"}, nil, map_id)
		end
	elseif tech_action == "resources" then
		if self.granted_resource ~= "" and self.granted_amount > 0 then
			PlaceResourceStockpile_Delayed(self:GetPos(), self:GetMapID(), self.granted_resource, self.granted_amount, self:GetAngle(), true)
		end
		AddOnScreenNotification("GrantRP", nil, {points = self.granted_amount, resource = self.granted_resource}, nil, map_id)
	elseif tech_action == "aliens" then
		AddOnScreenNotification("AlienArtifactsAnomalyAnalyzed", nil, {}, nil, map_id)
	end
	HintDisable("HintAnomaly")
	--@@@msg AnomalyAnalyzed,anomaly- fired when a new anomaly has been completely analized.
	if self:GetMapID() == MainMapID then
		g_ScannedAnomaly = g_ScannedAnomaly + 1
	end
	Msg("AnomalyAnalyzed", self)
	
	if self.sequence ~= "" then
		self:StartSequence(self.sequence, scanner, self:GetVisualPos())
	end
end

function SubsurfaceAnomaly:OnReveal()
	RequestNewObjsNotif(g_RecentlyRevAnomalies, self, self:GetMapID())
	--@@@msg AnomalyRevealed,anomaly- fired when an anomaly has been releaved.
	Msg("AnomalyRevealed", self)
	if self.rare then
		PlayFX("Revealed", "start", self)
	end
	--[[
	print("--ANOMALY REVEALED--")
	print("")
	print("Anomaly:")
	print(" Max Amount", self.max_amount)
	print(" Amount Left", self.amount)
	print(" Grade", self.grade)
	print(" Depth(Layer)", self.depth_layer)
	--]]
end

function SubsurfaceAnomaly:Getexpiration_progress()
	if not self.spawn_time or self.expiration_time <= 0 then
		return 0
	end
	return MulDivRound(GameTime() - self.spawn_time, 100, self.expiration_time)
end

function SubsurfaceAnomaly:OnExpired()
end

function SubsurfaceAnomaly:CheatScan()
	self:ScanCompleted(nil)
	self:delete()
end

GlobalVar("g_RecentlyRevAnomalies", {})
GlobalGameTimeThread("RecentlyRevAnomaliesNotif", function()
	HandleNewObjsNotif(g_RecentlyRevAnomalies, "NewAnomalies", "expire")
end)

DefineClass.SA_SpawnDepositAtAnomaly = {
	__parents = { "SequenceAction" },
	
	properties =
	{
		{ name = T(15, "Resource"), id = "resource", default = "all", editor = "dropdownlist", items = function() return ResourcesDropDownListItems end },
		{ name = T(1000100, "Amount"), id = "amount", editor = "number", default = 50000, scale = const.ResourceScale},	 --quantity
		{ name = T(16, "Grade"), id = "grade", editor = "dropdownlist", default = "Average", items = function() return DepositGradesTable end}, --grade
		{ name = T(6, "Depth Layer"), id = "depth_layer", editor = "number", default = 1, min = 1, max = const.DepositDeepestLayer}, --depth layer
	},

	Menu = "Gameplay",
	MenuName = "Spawn Deposit at Anomaly",
	MenuSection = "Anomaly",
	RestrictToList = "Scenario",
}

function SA_SpawnDepositAtAnomaly:ShortDescription()
	return string.format("Spawn %s deposit", self.resource)
end

function SA_SpawnDepositAtAnomaly:Exec(sequence_player, ip, seq, registers)
	local class = "SubsurfaceDeposit" .. self.resource
	if not g_Classes[class] then 
		sequence_player:Error(self, string.format("invalid resource %s", self.resource))
		return false
	end
	if registers.anomaly_pos then
		local map_id = sequence_player.map_id
		local marker = PlaceObjectIn("SubsurfaceDepositMarker", map_id)
		marker.resource = self.resource
		marker:SetPos(registers.anomaly_pos)

		marker.grade = self.grade
		marker.max_amount = self.amount
		marker.depth_layer = self.depth_layer
		marker.revealed = true
		
		local deposit = marker:PlaceDeposit()
		if deposit then
			deposit:PickVisibilityState()
		end
	else
		sequence_player:Error(self, string.format("invalid anomaly"))
	end
end

DefineClass.SA_SpawnEffectDepositAtAnomaly = {
	__parents = {"SequenceAction"},
	properties = {
		{ category = "Effect", id = "effect_type", name = "Effect Type", editor = "combo", items = ClassDescendantsCombo("EffectDeposit"), default = "" },
	},
	
	Menu = "Gameplay",
	MenuName = "Spawn EffectDeposit at Anomaly",
	MenuSection = "Anomaly",
	RestrictToList = "Scenario",
}

function SA_SpawnEffectDepositAtAnomaly:ShortDescription()
	local effect_type = (self.effect_type ~= "") and self.effect_type or "EffectDeposit"
	return string.format("Place %s at Anomaly", effect_type)
end

function SA_SpawnEffectDepositAtAnomaly:Exec(sequence_player, ip, seq, registers)
	local class = self.effect_type
	if not g_Classes[class] then 
		sequence_player:Error(self, string.format("invalid effect deposit %s", self.self.effect_type))
		return false
	end
	if registers.anomaly_pos then
		local map_id = sequence_player.map_id
		local deposit = PlaceEffectDeposit(self.effect_type, {}, map_id)
		if deposit then
			deposit:SetRevealed(true)
		end
		
		deposit:SetPos(registers.anomaly_pos)
	else
		sequence_player:Error(self, string.format("invalid anomaly"))
	end
end

DefineClass.SA_SpawnDustDevilAtAnomaly = {
	__parents = { "SequenceAction" },
	
	properties = {
		{ name = T(17, "Period, base (s)"), id = "period", editor = "number", min = 0, max = 300*1000, scale = 1000, default = 30*1000 },
		{ name = T(18, "Period, random (s)"), id = "period_random", editor = "number", min = 0, max = 300*1000, scale = 1000, default = 30*1000 },
		{ name = T(19, "Spawn Chance (%)"), id = "probability", editor = "number", min = 0, max = 100, default = 30 },
		{ name = T(20, "Lifetime (s)"), id = "lifetime", editor = "number", min = 0, max = 300*1000, scale = 1000, default = 60*1000 },
--		{ id = "range", editor = "number", min = 50, max = 500, scale = guim },
		{ name = T(21, "Speed (m/s)"), id = "speed", editor = "number", min = 5*guim, max = 100*guim, scale = guim, default = 3*guim},
		{ name = T(3567, "Preset"), id = "preset", editor = "choice", default = "DustDevils_VeryLow", items = DataInstanceCombo("MapSettings_DustDevils") },
	},
	
	Menu = "Gameplay",
	MenuName = "Spawn Dust Devil at Anomaly",
	MenuSection = "Anomaly",
	RestrictToList = "Scenario",
	ip_template = "ipAnomaly",
}

function SA_SpawnDustDevilAtAnomaly:ShortDescription()
	return "Spawn dust devil"
end

function SA_SpawnDustDevilAtAnomaly:Exec(sequence_player, ip, seq, registers)
	local map_id = sequence_player.map_id
	local marker = PlaceObjectIn("PrefabFeatureMarker", map_id, { FeatureType = "Dust Devils" })
	
	marker:SetVisible(false)
	marker:SetPos( registers.anomaly_pos )
	
	local data = DataInstances.MapSettings_DustDevils
	local descr = data[self.preset] or data[1]
	assert(descr)
	if descr then	
		marker.thread = CreateDustDevilMarkerThread(descr, marker)
	end
end

function SubsurfaceAnomaly:GetDescription()
	return self.description or T(22, "Our scans have found some interesting readings in this Sector. Further analysis is needed.<newline><newline>Send an RC Explorer to analyze the Anomaly.")
end

function SubsurfaceAnomaly:GetDisplayName()
	return self.display_name
end

function OnMsg.GatherFXTargets(list)
	list[#list + 1] = "SubsurfaceAnomaly"
end

function OnMsg.GatherFXActions(list) 
    list[#list + 1] = "Revealed"
end

GlobalVar("BreakthroughOrder", {})
function SavegameFixups.FixBreakthroughOrderIds()
	for i, tech in ipairs(BreakthroughOrder) do
		BreakthroughOrder[i] = tech.id
	end
end

function SavegameFixups.FixDuplicateAnomalies()
	for _, anomaly in pairs(MainCity.labels.Anomaly or empty_table) do
		if anomaly.tech_action then
			anomaly.sequence = ""
		end
	end
end

function Colony:GetUnregisteredBreakthroughs()
	local ids = {}
	for _, tech in ipairs(Presets.TechPreset.Breakthroughs) do
		local id = tech.id
		if not table.find(BreakthroughOrder, id) and not self:IsTechDiscovered(id) and self:TechAvailableCondition(tech) then
			ids[#ids + 1] = id
		end
	end
	return ids
end

function City:InitBreakThroughAnomalies()
	local markers = GetRealm(self):MapGet("map", "SubsurfaceAnomalyMarker", function(a) return a.tech_action == "breakthrough" end )
	local available_breakthroughs = table.ifilter(Presets.TechPreset.Breakthroughs, function(_, tech)
		return	UIColony:TechAvailableCondition(tech)
	end, self)
	
	BreakthroughOrder = table.imap(available_breakthroughs, "id")
	
	-- remove discovered
	for i = #BreakthroughOrder, 1, -1 do
		if UIColony:IsTechDiscovered(BreakthroughOrder[i]) then
			table.remove(BreakthroughOrder, i)
		end
	end
	
	-- initialize order
	assert(#BreakthroughOrder >= #markers, "Too many breakthrough anomalies found!")
	StableShuffle(BreakthroughOrder, self:CreateResearchRand("ShuffleBreakThroughTech"), 100)
	table.shuffle(markers, self:CreateResearchRand("ShuffleBreakThroughMarkers"))
	
	-- cap the number of breakthroughs
	while #BreakthroughOrder > #markers do
		table.remove(BreakthroughOrder)
	end
	
	-- reserve techs for planetary anomalies
	local reserved = g_Consts.PlanetaryBreakthroughCount
	for i = 1, reserved do
		-- kill the number of markers reserved for planetary anomalies
		local marker = table.remove(markers)
		DoneObject(marker)
	end
	
	-- assign breakthrough tech to each marker
	local assigned = 0
	while assigned < #markers do
		local idx = #BreakthroughOrder
		local breakthrough_tech = BreakthroughOrder[idx]
		if not breakthrough_tech then
			break
		end
		assigned = assigned + 1
		markers[assigned].breakthrough_tech = breakthrough_tech
		table.remove(BreakthroughOrder, idx)
	end
	if #markers > assigned then
		print("Removing", #markers - assigned, "unassigned breakthrough anomaly markers.")
		for i = assigned + 1, #markers do
			DoneObject(markers[i])
		end
	end
end

function ScanAllAnomalies(breakthrough_only)
	local function reveal(anomaly)
		if not anomaly then return end
		if breakthrough_only and anomaly.tech_action ~= "breakthrough" then return end
		if not anomaly:IsRevealed() then return end
		anomaly:ScanCompleted(false)
		anomaly:delete()
	end

	local realm = GetActiveRealm()
	realm:MapForEach(true, "SubsurfaceAnomaly", reveal)
end
