DefineClass.TimeSeries = {
	__parents = { "InitDone" },
	data = false,
	next_index = 0, -- zero-based!
}

local ts_capacity = 1024

function TimeSeries:Init()
	self.data = {}
	for i = 1, ts_capacity do
		self.data[i] = false
	end
end

function TimeSeries:AddValue(value)
	local next_index = self.next_index
	self.data[next_index % ts_capacity + 1] = value
	self.next_index = next_index + 1
end

function TimeSeries:GetMaxOfLastValues(count)
	local data = self.data
	local index = self.next_index - 1
	local out_index = Min(count, ts_capacity, index + 1)
	local max_value
	while out_index > 0 do
		local value = data[index % ts_capacity + 1]
		if value then
			if not max_value then
				max_value = value
			elseif value > max_value then
				max_value = value
			end
		end
		out_index = out_index - 1
		index = index - 1
	end
	return max_value
end

-- n = -1 .. -ts_capacity
function TimeSeries:GetValue(n)
	return self.data[ (self.next_index + n + ts_capacity) % ts_capacity + 1 ] or 0
end

function TimeSeries:GetLastValue(default_value)
	local data = self.data
	local index = self.next_index - 1
	local min_value, max_value
	local value = data[index % ts_capacity + 1] or default_value or 0
	return value, min_value, max_value
end

function TimeSeries:GetLastValues(count, out_values, default_value)
	out_values = out_values or {}
	local data = self.data
	local index = self.next_index - 1
	local out_index = Min(count, ts_capacity, index + 1)
	for i = count, out_index+1, -1 do
		out_values[i] = default_value or 0
	end
	local min_value, max_value
	while out_index > 0 do
		local value = data[index % ts_capacity + 1]
		if value then
			if not min_value then
				min_value, max_value = value, value
			else
				if value < min_value then
					min_value = value
				else
					if value > max_value then
						max_value = value
					end
				end
			end
		end
		out_values[out_index] = value
		out_index = out_index - 1
		index = index - 1
	end
	return out_values, min_value, max_value
end

function TimeSeries_CalculateGraphValues(rel, desc, scale, terraforming_param, div, mul, day)
	local value1 = desc[1]:GetValue(rel)
	local value2 = desc[2] and desc[2]:GetValue(rel) or nil
	return {
		MulDivRound(value1, mul, div), 
		value1 / scale,
		value2 and MulDivRound(value2, mul, div) or nil,
		value2 and value2 / scale or nil,
		day + rel,
	}
end

-- desc - { ts1, ts2, scale = xxx }
-- day - current day number
-- n - number of values to return, pad with zeroes those not present in timeseries
-- height - max height in pixels permissible
-- axis_divisions - vertical axis will be divided in this many steps
-- returns array, axis_step
-- array contains one table per timeseries value, [1] and [2] come from ts1, [3] and [4] come from ts2 (nil if ts2 not given), [5] is day number
-- [1] and [3] are in pixels
-- axis_step is 1, 2 or 5 * 10^n, such as max value in relevant part of ts1/ts2 is less than axis_divisions * axis_step
function TimeSeries_GetGraphValueHeights(desc, day, n, height, axis_divisions)
	local values = {}
	local max = desc[1]:GetMaxOfLastValues(n)
	if desc[2] then
		max = Max(max, desc[2]:GetMaxOfLastValues(n))
	end
	local scale = desc.scale or 1
	local terraforming_param = desc.terraforming_param
	local axis_step = scale
	while axis_step < 1000000000 do
		if not max or axis_divisions * axis_step > max then break end
		axis_step = 2 * axis_step
		if not max or axis_divisions * axis_step > max then break end
		axis_step = 5 * axis_step / 2
		if not max or axis_divisions * axis_step > max then break end
		axis_step = 2 * axis_step
	end
	local mul = height
	local div = axis_divisions * axis_step
	
	if day > n then
		for i = 1, n do
			local rel = i - n - 1
			values[i] = TimeSeries_CalculateGraphValues(rel, desc, scale, terraforming_param, div, mul, day)
		end
	else
		for i = 1, day - 1 do
			local rel = i - day
			values[i] = TimeSeries_CalculateGraphValues(rel, desc, scale, terraforming_param, div, mul, day)
		end
		for i = day, n do
			values[i] = {0,0,0,0,i}
		end
	end
	return values, axis_step / scale
end
