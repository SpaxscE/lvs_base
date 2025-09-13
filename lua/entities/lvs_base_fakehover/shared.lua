
ENT.Base = "lvs_base"

ENT.PrintName = "[LVS] Generic Fake Hover"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.ForceLinearMultiplier = 1
ENT.ForceLinearRate = 1

ENT.MaxVelocityX = 300
ENT.MaxVelocityY = 300

ENT.MaxTurnRate = 1

ENT.BoostAddVelocityX = 200
ENT.BoostAddVelocityY = 200

ENT.GroundTraceHitWater = true
ENT.GroundTraceLength = 50
ENT.GroundTraceHull = 100

ENT.DisableBallistics = true

function ENT:SetupDataTables()
	self:AddDT( "Vector", "AIAimVector" )
	self:AddDT( "Bool", "Disabled" )

	if SERVER then
		self:NetworkVarNotify( "Disabled", self.OnDisabled )
	end

	self:CreateBaseDT()
end

function ENT:HitGround()
	local data = {
		start = self:LocalToWorld( self:OBBCenter() ),
		endpos = self:LocalToWorld( Vector(0,0,self:OBBMins().z - self.GroundTraceLength) ),
		mins = Vector( -self.GroundTraceHull, -self.GroundTraceHull, 0 ),
		maxs = Vector( self.GroundTraceHull, self.GroundTraceHull, 0 ),
		filter = self:GetCrosshairFilterEnts()
	}

	local trace = util.TraceHull( data )

	data.mask = MASK_WATER

	local traceWater = util.TraceHull( data )

	return ((trace.Hit or (traceWater.Hit and self.GroundTraceHitWater)) and not trace.HitSky)
end

function ENT:GetThrottle()
	return math.min( self:GetVelocity():Length() / math.abs( self.MaxVelocityX + self.BoostAddVelocityX, self.MaxVelocityY + self.BoostAddVelocityY ), 1 )
end

function ENT:GetMaxThrottle()
	return 1
end

function ENT:GetThrustStrenght()
	return 0
end

function ENT:GetVehicleType()
	return "fakehover"
end