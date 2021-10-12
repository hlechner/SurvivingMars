DefineClass.Funding = {
	__parents = { "InitDone" },
	funding = false,
	funding_gain = false,
	funding_gain_total = false,
	funding_gain_last = false,
	funding_gain_sol = false,
}

function Funding:Init()
	self.funding = 0
end

function Funding:CopyMove(other)
	CopyMoveClassFields(other, self,
	{
		"funding",
		"funding_gain",
		"funding_gain_total",
		"funding_gain_last",
		"funding_gain_sol",
	})
end

function Funding.ForwardCalls(source, target)
	for _, call in pairs({"GetTotalFundingGain", "GetFunding", "ChangeFunding", "CalcModifiedFunding", "CalcBaseExportFunding"}) do
		source[call] = function(old_target, ...)
			return target[call](target, ...)
		end
	end
end

function Funding:UpdateFunding()
	self.funding_gain_sol = self.funding_gain
	self.funding_gain = false
end

function Funding:CalcBaseExportFunding(amount)
	return MulDivRound(amount or 0, g_Consts.ExportPricePreciousMetals*1000000, const.ResourceScale)
end

function Funding:CalcModifiedFunding(amount, source)
	amount = amount or 0
	if amount > 0 and source~="refund" then
		amount = MulDivRound(amount, g_Consts.FundingGainsModifier, 100)
	end
	return amount
end

function Funding:ChangeFunding(amount, source)
	amount = self:CalcModifiedFunding(amount, source)
	if amount == 0 then
		return
	end
	if (source or "") == "" then
		source = "Other"
	end
	if amount > 0 then
		self.funding_gain_total = self.funding_gain_total or {}
		self.funding_gain_last = self.funding_gain_last or {}
		self.funding_gain = self.funding_gain or {}
		
		self.funding_gain_total[source] = (self.funding_gain_total[source] or 0) + amount
		self.funding_gain[source] = (self.funding_gain[source] or 0) + amount
		self.funding_gain_last[source] = amount
	end
	self.funding = self.funding + amount
	Msg("FundingChanged", self, amount, source)
	return amount
end

function Funding:GetTotalFundingGain()
	local sum = 0
	for _, category in pairs(self.funding_gain_total or empty_table) do
		sum = sum + category
	end
	return sum
end

function Funding:GetFunding()
	return self.funding
end
