DefineClass.Mysteries = {
	mystery_id = "",
	mystery = false,
}

function Mysteries:SetMystery(mys)
	assert(self.mystery == false, "Only one mystery per playthrough.")
	self.mystery = mys
end

function Mysteries:SelectMystery()
	local mystery = g_CurrentMissionParams.idMystery or "none"
	local map_data = ActiveMapData
	if not map_data.GameLogic
		or not map_data.StartMystery
		or map_data.MapType == "system"
		or g_Tutorial
		or g_CurrentMissionParams.challenge_id
	then
		return
	end
	
	if mystery == "random" then
		local mysteries = ClassDescendantsList("MysteryBase")
		local filtered = {}
		local played_mysteries = AccountStorage.PlayedMysteries
		for i = #mysteries, 1, -1 do
			local name = mysteries[i]
			if not Platform.developer and not IsDlcAvailable(g_Classes[name].dlc) then
				table.remove(mysteries, i)
			elseif not played_mysteries or not played_mysteries[name] then
				filtered[#filtered + 1] = name
			end
		end
		if #filtered > 0 then
			mystery = SessionRandom:TableRand(filtered)
		else
			mystery = SessionRandom:TableRand(mysteries)
		end
	end
	if mystery ~= "none" then
		self.mystery_id = mystery
	end
end

function OnMsg.PreNewGame()
	if ActiveMapData.IsRandomMap then
		ActiveMapData.StartMystery = true
	end
end

-- fixup for older savegames
function OnMsg.PostLoadGame()
	if UIColony.mystery then
		UIColony.mystery_id = UIColony.mystery.class
		--reload resource pretty desc/name
		UIColony.mystery:ApplyMysteryResourceProperties()
	end
end

function OnMsg.Autorun()
	if UIColony and UIColony.mystery then
		--so script reload doesnt load up defaults from game const
		UIColony.mystery:ApplyMysteryResourceProperties()
	end
end

function Mysteries:InitMysteries()
	if self.mystery_id ~= "" then
		g_Classes[self.mystery_id]:new{mysteries = self}
	end
	
	Msg("MysteryChosen")
end

function Mysteries.CopyMove(self, other)
	CopyMoveClassFields(other, self,
	{
		"mystery",
		"mystery_id"
	})
end

function Mysteries:FixMystery()
	if self.mystery then
		self.mystery.mysteries = UIColony
		self.mystery.city = nil
	end
end

function OnMsg.MysteryBegin()
	--mark mystery as played
	local current_mystery = UIColony.mystery
	local played_mysteries = AccountStorage.PlayedMysteries or {}
	if current_mystery and not played_mysteries[current_mystery.class] then
		played_mysteries[current_mystery.class] = true
		AccountStorage.PlayedMysteries = played_mysteries
		SaveAccountStorage(5000)
	end
end

function OnMsg.MysteryEnd(outcome)
	local current_mystery = UIColony.mystery
	local finished_mysteries = AccountStorage.FinishedMysteries or {}
	if current_mystery and not finished_mysteries[current_mystery.class] then
		finished_mysteries[current_mystery.class] = true
		AccountStorage.FinishedMysteries = finished_mysteries
		SaveAccountStorage(5000)
	end
end

---------------------------------------------------------------------------------------------

function CheatStartMystery(mystery_id)
	local research = UIColony
	local mysteries = UIColony
	
	if not CheatsEnabled() then
		print("cheats not enabled")
		return
	end
	
	if not mysteries or not g_Classes[mystery_id] then
		print("mystery not available", mystery_id)
		return
	end

	if mysteries and mysteries.mystery then
		print("finishing ongoing mystery", mysteries.mystery_id)
		CheatFinishMystery(mysteries.mystery_id)
		mysteries.mystery = false
		mysteries.mystery_id = ""
	end

	mysteries.mystery_id = mystery_id

	if research then
		local fields = Presets.TechFieldPreset.Default
		for i=1,#fields do
			local field = fields[i]
			local field_id = field.id
			local list = research.tech_field[field_id] or {}
			research.tech_field[field_id] = list
			for _, tech in ipairs(Presets.TechPreset[field_id]) do
				if tech.mystery == mystery_id then
					assert(not field.discoverable, "Discoverable mystery tech?!")
					local tech_id = tech.id
					if not research.tech_status[tech_id] then
						list[#list + 1] = tech_id
						research.tech_status[tech_id] = {
							points = 0,
							field = field_id,
						}
						tech:EffectsInit(UIColony)
					else					
						print("Tech already present", tech_id, "for mystery", mystery_id)
					end
				end
			end
		end
	end

	mysteries:InitMysteries()
	print("started", mystery_id)
end

function CheatFinishMystery(mystery_id)
	local finished_mysteries = AccountStorage.FinishedMysteries or {}
	local all_mysteries = ClassDescendantsList("MysteryBase")
	local exists = table.find(all_mysteries, mystery_id)
	if not finished_mysteries[mystery_id] and exists then
		finished_mysteries[mystery_id] = true
		AccountStorage.FinishedMysteries = finished_mysteries
		SaveAccountStorage(5000)
	end
end

function CheatClearAllFinishedMysteries()
	AccountStorage.FinishedMysteries = {}
	SaveAccountStorage(5000)
end
