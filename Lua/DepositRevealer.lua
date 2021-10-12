DefineClass.DepositRevealer = {
	__parents = { "Object" },
	
	properties = {
		{ id = "scan_range", name = "Scan Range", editor = "number", default = 10000,  help = "Range at which deposits are revealed" },
		{ id = "active_environment", name = "Active Environment", editor = "text", default = "Underground",  help = "Environment to reveal deposits in" },
	},
}

function DepositRevealer:RemoveFromLabels()
	self.city:RemoveFromLabel("DepositRevealer", self)
end

function DepositRevealer:AddToLabels()
	self.city:AddToLabel("DepositRevealer", self)
end