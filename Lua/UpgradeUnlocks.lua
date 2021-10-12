DefineClass.UpgradeUnlocks = {
	unlocked_upgrades = false,
}

function UpgradeUnlocks:Init()
	self.unlocked_upgrades = {}

	CreateGameTimeThread(function(self)
		-- unlock some upgrades by default
		self:UnlockUpgrade("Mohole_ExpandMohole_1")
		self:UnlockUpgrade("Mohole_ExpandMohole_2")
		self:UnlockUpgrade("Mohole_ExpandMohole_3")
		self:UnlockUpgrade("Excavator_ImprovedRefining_1")
		self:UnlockUpgrade("Excavator_ImprovedRefining_2")
		self:UnlockUpgrade("Excavator_ImprovedRefining_3")
	end, self)
end

function UpgradeUnlocks:IsUpgradeUnlocked(id)
	if id == "" then
		return false
	end
	return self.unlocked_upgrades[id] or false
end

function UpgradeUnlocks:UnlockUpgrade(id)
	self.unlocked_upgrades[id] = true
	Msg("UpgradeUnlocked", id, self)
end

function UpgradeUnlocks.CopyMove(self, other)
	CopyMoveClassFields(other, self,
	{
		"unlocked_upgrades"
	})
end
