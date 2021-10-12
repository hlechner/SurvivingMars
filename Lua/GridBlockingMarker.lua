local type_tile = const.TerrainTypeTileSize

DefineClass.GridBlockingMarker = {
	__parents = { "EditorMarker" },
}

function GridBlockingMarker:SnapToGrid()
	local snapped_angle = SnapWorldToHexAngle(self:GetAngle())
	self:SetAngle(snapped_angle)
	
	local pos = SnapWorldToHex(self:GetPos())
	self:SetPos(pos)
end

if Platform.developer then
function GridBlockingMarker:GameInit()
	self:SnapToGrid()
end

GridBlockingMarker.EditorCallbackPlace = GridBlockingMarker.SnapToGrid
GridBlockingMarker.EditorCallbackRotate = GridBlockingMarker.SnapToGrid
GridBlockingMarker.EditorCallbackMove = GridBlockingMarker.SnapToGrid
end
