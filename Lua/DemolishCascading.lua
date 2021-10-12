DefineClass.DemolishCascading = {
	cascade_cable_deletion_enabled = true, --use to disable chunk cable deletion (for building placement for example)		
	cascade_cable_deletion_dsiable_reasons = false,
}

function DemolishCascading:Init()
	self.cascade_cable_deletion_dsiable_reasons = {}
end

function DemolishCascading:SetCableCascadeDeletion(val, reason)
	if val then
		self.cascade_cable_deletion_dsiable_reasons[reason] = nil
		if not next(self.cascade_cable_deletion_dsiable_reasons) then
			self.cascade_cable_deletion_enabled = true
		end
	else
		self.cascade_cable_deletion_dsiable_reasons[reason] = true
		self.cascade_cable_deletion_enabled = false
	end
end
