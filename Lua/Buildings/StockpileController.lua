-------------------------------------------------------------------------------------------------------------
--controls N stockpiles that stockpile the SAME resource type, distributes resources evenly between all stockpiles
--the stockpiles may or may not have demand/supply requests
--currently, shared storages are unsupported.
-------------------------------------------------------------------------------------------------------------

DefineClass.StockpileController = {
	__parents = { "InitDone" },
	
	parent = false,
	next_stockpile_idx = 1,
	current_stockpile_idx_stockpiled_amount = 0,
	stockpile_spots = false, --defines where to place stockpiles, stockpile will be placed for each of the spots in this arr.
	stockpiles = false,
	total_stockpiled = 0,
	
	has_demand_request = false,
	has_supply_request = true,
	max_x = false,
	max_y = false,
	max_z = false,
	
	stockpile_class = "ResourceStockpile",
	stockpiled_resource = "Metals",
	max_storage = false,
	
	additional_stockpile_params = false,
	stock_max = 0,
}

function StockpileController:GameInit()
	self:CreateStockpiles()
end

function StockpileController:CreateStockpiles()
	local stock_max = 0
	self.stockpiles = {}
	local map_id = self:GetMapID()
	local realm = GetRealm(self)
	realm:SuspendPassEdits("CreateStockpiles")
	for i = 1, #(self.stockpile_spots or "") do
		local spot = self.stockpile_spots[i]
		if not self.parent:HasSpot(spot) then
			print("once", self.parent:GetEntity(), "doesn't have spot", spot)
			spot = "Origin"
		end
		local first, last = self.parent:GetSpotRange("idle", spot)
		for j = first, last do
			local params = {	resource = self.stockpiled_resource, 
						parent = self,
						destroy_when_empty = false, 
						has_demand_request = self.has_demand_request,
						has_supply_request = self.has_supply_request,
						max_x = self.max_x or nil,
						max_y = self.max_y or nil,
						max_z = self.max_z or nil,
					}
					
			for k, v in pairs(self.additional_stockpile_params or empty_table) do
				params[k] = v
			end
			
			local s = PlaceObjectIn(self.stockpile_class, map_id, params)
			self.parent:Attach(s, j)
			self.stockpiles[#self.stockpiles + 1] = s
			stock_max = stock_max + s:GetMax() * const.ResourceScale
		end
	end
	realm:ResumePassEdits("CreateStockpiles")
	self.stock_max = stock_max
end

function StockpileController:ReleaseStockpiles()
	if not self.stockpiles then return end
	for i = 1, #self.stockpiles do
		if self.stockpiles[i].count > 0 then
			self.stockpiles[i]:DisconnectFromParent()
		else
			DoneObject(self.stockpiles[i])
		end
	end
	
	self.total_stockpiled = 0
	
	self.stockpiles = false
end

function StockpileController:GetStoredAmount()
	return self.total_stockpiled
end

function StockpileController:TestStoredAmountConsistency()
	local t = 0
	for i = 1, #self.stockpiles do
		t = t + self.stockpiles[i]:GetStoredAmount()
	end
	
	if self.total_stockpiled ~= t then
		self:SetColorModifier(RGBA(255, 0, 0, 0))
		return false
	end
	
	return true
end

function StockpileController:GetNextStockpileIndex(stockpiles, look_for_least_stockpiled)
	stockpiles = stockpiles or self.stockpiles
	local lowest = Max(stockpiles[1]:GetStoredAmount(), stockpiles[1].init_with_amount)
	local lowest_idx = 1
	for i = 2, #stockpiles do
		local a = Max(stockpiles[i]:GetStoredAmount(), stockpiles[i].init_with_amount)
		if (look_for_least_stockpiled and a < lowest) or (not look_for_least_stockpiled and a > lowest) then
			lowest = a
			lowest_idx = i
		end
	end
	
	return lowest_idx
end

function StockpileController:UpdateTotalStockpile(amount, resource)
	if resource==self.stockpiled_resource then
		self.total_stockpiled = self.total_stockpiled + amount
	end
end

function StockpileController:UpdateStockpileAmounts(amount_stored)
	if not self.stockpiles or #self.stockpiles <= 0 then return end --no stockpiles, nothing to do here.
	local total_stockpiled = self.total_stockpiled
	
	local amount_to_stock = amount_stored - total_stockpiled
	
	local step_amount = GetResourceInfo(self.stockpiled_resource).unit_amount
	local cs = self.current_stockpile_idx_stockpiled_amount
	
	--refresh idx so we don't go below zero
	self.next_stockpile_idx = amount_to_stock < 0 and self.stockpiles[self.next_stockpile_idx]:GetStoredAmount() <= 0 and self:GetNextStockpileIndex(self.stockpiles, false) or self.next_stockpile_idx
	
	if amount_to_stock > 0 then
		while amount_to_stock > 0 do
			local amount_to_stock_next = Max((cs + amount_to_stock) - step_amount, 0)
			amount_to_stock = Min(amount_to_stock, step_amount - cs)
			assert(amount_to_stock > 0)
			self.stockpiles[self.next_stockpile_idx]:AddResourceAmount(amount_to_stock)
			cs = cs + amount_to_stock
			total_stockpiled = total_stockpiled + amount_to_stock
			
			if cs >= step_amount then
				assert(cs == step_amount) --otherwise we messed up.
				self.next_stockpile_idx = self:GetNextStockpileIndex(self.stockpiles, true)
				cs = 0
			end
			
			amount_to_stock = amount_to_stock_next
		end
	else --- remove from stockpiles
		while amount_to_stock < 0 do
			local amount = Min(step_amount, -amount_to_stock)
			amount = cs ~= 0 and Min(cs, amount) or amount
			assert(amount > 0)
			amount_to_stock = amount_to_stock + amount
			self.stockpiles[self.next_stockpile_idx]:AddResourceAmount(-amount)
			cs = cs == 0 and step_amount - amount or cs - amount
			total_stockpiled = total_stockpiled - amount
			
			if cs <= 0 then
				assert(cs == 0)
				self.next_stockpile_idx = self:GetNextStockpileIndex(self.stockpiles, false)
			end
		end
	end
	
	assert(amount_to_stock == 0)
	self.current_stockpile_idx_stockpiled_amount = cs	
	self.total_stockpiled = total_stockpiled
end
