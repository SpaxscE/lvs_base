
ENT.Base = "lvs_base_starfighter"

ENT.PrintName = "[LVS] Base Gunship"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.ThrustVtol = 30
ENT.ThrustRateVtol = 2

function ENT:CalcVtolThrottle( ply, cmd )
	local Delta = FrameTime()

	local ThrottleZero = self:GetThrottle() <= 0

	local VtolX = ThrottleZero and (ply:lvsKeyDown( "-VTOL_X_SF" ) and -1 or 0) or 0
	local VtolY = ((ply:lvsKeyDown( "+VTOL_Y_SF" ) and 1 or 0) - (ply:lvsKeyDown( "-VTOL_Y_SF" ) and 1 or 0)) + ((ply:lvsKeyDown( "-ROLL_SF" ) and 1 or 0) - (ply:lvsKeyDown( "+ROLL_SF" ) and 1 or 0))
	local VtolZ = ((ply:lvsKeyDown( "+VTOL_Z_SF" ) and 1 or 0) - (ply:lvsKeyDown( "-VTOL_Z_SF" ) and 1 or 0))

	local DesiredVtol = Vector(VtolX,VtolY,VtolZ)
	local NewVtolMove = self:GetNWVtolMove() + (DesiredVtol - self:GetNWVtolMove()) * self.ThrustRateVtol * Delta

	if not ThrottleZero or self:WorldToLocal( self:GetPos() + self:GetVelocity() ).x > 100 then
		NewVtolMove.x = 0
	end

	self:SetVtolMove( NewVtolMove )
end

function ENT:GetVtolMove()
	if self:GetEngineActive() and not self:GetAI() then
		return self:GetNWVtolMove() * self.ThrustVtol * (1 - math.min( self:GetThrottle(), 1 ) ^ 2)
	else
		return Vector(0,0,0)
	end
end