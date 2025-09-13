
function ENT:StartCommand( ply, cmd )
	if self:GetDriver() ~= ply then return end

	local KeyJump = ply:lvsKeyDown( "VSPEC" )

	if self._lvsOldKeyJump ~= KeyJump then
		self._lvsOldKeyJump = KeyJump

		if KeyJump then
			self:ToggleVehicleSpecific()
		end
	end

	local Forward = cmd:KeyDown( IN_FORWARD )
	local Back = cmd:KeyDown( IN_BACK )
	local Left = cmd:KeyDown( IN_MOVELEFT )
	local Right = cmd:KeyDown( IN_MOVERIGHT )
	local Boost = cmd:KeyDown( IN_SPEED )

	local X = (Forward and 1 or 0) - (Back and 1 or 0)
	local Y = (Left and 1 or 0) - (Right and 1 or 0)

	self:SetMove( X, Y, Boost )

	local pod = self:GetDriverSeat()

	if not IsValid( pod ) then return end

	if ply:lvsKeyDown( "FREELOOK" ) then
		self:SetSteerTo( self:GetAngles().y)

		return
	end

	self:SetSteerTo( pod:WorldToLocalAngles( ply:EyeAngles() ).y )
end

function ENT:SetSteerTo( Steer )
	if not isnumber( Steer ) then return end

	self._steer = Steer
end

function ENT:GetSteerTo()
	if not self:GetEngineActive() then return self:GetAngles().y end

	return (self._steer or self:GetAngles().y)
end

function ENT:SetMove( X, Y, Boost )
	if not isnumber( X ) or not isnumber( Y ) then return end

	X = math.Clamp( X, -1, 1 )
	Y = math.Clamp( Y, -1, 1 )
	Z = Boost and 1 or 0

	self._move = Vector( X, Y, Z )
end

function ENT:GetMove()
	if not self:GetEngineActive() then return Vector(0,0,0) end

	return (self._move or Vector(0,0,0))
end
