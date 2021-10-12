
DefineClass.SupplyConnectionGrid = {
	water = false,
	electricity = false,
}

function SupplyConnectionGrid.new(class)
	return setmetatable({}, class)
end

function SupplyConnectionGrid:Build(hex_width, hex_height)
	self.electricity = NewHierarchicalGrid(hex_width, hex_height, 16, 32)
	self.water = NewHierarchicalGrid(hex_width, hex_height, 16, 32)
end
