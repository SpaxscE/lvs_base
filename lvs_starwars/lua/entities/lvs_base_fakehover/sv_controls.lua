
function ENT:StartCommand( ply, cmd )
	if self:GetDriver() ~= ply then return end

	local Forward = cmd:KeyDown( IN_FORWARD )
	local Back = cmd:KeyDown( IN_BACK )
	local Left = cmd:KeyDown( IN_MOVELEFT )
	local Right = cmd:KeyDown( IN_MOVERIGHT )
	local Boost = cmd:KeyDown( IN_SPEED )

	local X = (Forward and 1 or 0) - (Back and 1 or 0)
	local Y = (Left and 1 or 0) - (Right and 1 or 0)

	self:SetMove( X, Y, Boost )
end

function ENT:SetSteer( Steer )
	if not isnumber( Steer ) then return end

	self._steer = math.Clamp( Steer, -1, 1 )
end

function ENT:GetSteer()
	return (self._steer or 0)
end

function ENT:SetMove( X, Y, Boost )
	if not isnumber( X ) or not isnumber( Y ) then return end

	X = math.Clamp( X, -1, 1 )
	Y = math.Clamp( Y, -1, 1 )
	Z = Boost and 1 or 0

	self._move = Vector( X, Y, Z )
end

function ENT:GetMove()
	return (self._move or Vector(0,0,0))
end
