DefineClass.GameRandom = {
	__parents = {"InitDone"},
	rand_state = false,
}

function GameRandom:Init(seed)
	self.rand_state = RandState(seed)
end

function GameRandom:CopyMove(other)
	self.rand_state = other.rand_state
	other.rand_state = nil
end

function GameRandom:Random(min, max)
	return self.rand_state:Get(min, max)
end

function GameRandom:TableRand(tbl)
	local idx = 1 + self:Random(#tbl)
	return tbl[idx], idx
end

function CreateRand(stable, ...)
	local seed = xxhash(...)
	local function rand(max)
		local value
		value, seed = BraidRandom(seed, max, stable)
		return value
	end
	local function trand(tbl, weight)
		local value, idx
		if weight then
			value, idx, seed = table.weighted_rand(tbl, weight, seed, stable)
		else
			idx, seed = BraidRandom(seed, #tbl, stable)
			idx = idx + 1
			value = tbl[idx]
		end
		return value, idx
	end
	return rand, trand
end
