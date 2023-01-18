AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:ToggleGravity( PhysObj, Enable )
	if PhysObj:IsGravityEnabled() ~= Enable then
		PhysObj:EnableGravity( Enable )
	end
end

function ENT:TransformNormal( ent, Normal )
	return Normal
end

function ENT:GetAlignment( ent, phys )
	return ent:GetForward(), ent:GetRight()
end

function ENT:GetMoveXY( ent, phys )
	return 0, 0
end

function ENT:GetSteer( ent, phys )
	return 0
end

function ENT:GetHoverHeight( ent, phys )
	return self.HoverHeight
end

function ENT:PhysicsSimulate( phys, deltatime )
	phys:Wake()

	if not self:GetEngineActive() then

		self:ToggleGravity( phys, true )

		return
	end

	local base = phys:GetEntity()
	local vel = phys:GetVelocity()
	local velL = phys:WorldToLocal( phys:GetPos() + vel )

	local masscenter = phys:LocalToWorld( phys:GetMassCenter() )

	local forward, right = self:GetAlignment( base, phys )
	local up = base:GetUp()

	local tracedata = {
		start = masscenter, 
		endpos = masscenter - up * self.HoverTraceLength,
		mins = Vector( -self.HoverHullRadius, -self.HoverHullRadius, 0 ),
		maxs = Vector( self.HoverHullRadius, self.HoverHullRadius, 0 ),
		filter = function( entity )
			if self:GetCrosshairFilterLookup()[ entity:EntIndex() ] or entity:IsPlayer() or entity:IsNPC() or entity:IsVehicle() or self.HoverCollisionFilter[ entity:GetCollisionGroup() ] then
				return false
			end

			return true
		end,
	}

	local trace = util.TraceHull( tracedata )
	local traceLine = util.TraceLine( tracedata )

	local OnGround = (trace.Hit or traceLine.hit) and not trace.HitSky and not traceLine.HitSky

	self:ToggleGravity( phys, not OnGround )

	local Pos = trace.HitPos
	if traceLine.Hit then
		Pos = traceLine.HitPos
	end

	local CurDist = (Pos - masscenter):Length()

	local X, Y = self:GetMoveXY( base, phys )
	local Z = ((self:GetHoverHeight( base, phys ) - CurDist) * 3 - velL.z * 0.5)

	local Normal = self:TransformNormal( base, trace.HitNormal )
	local Pitch = self:AngleBetweenNormal( Normal, forward ) - 90
	local Roll = self:AngleBetweenNormal( Normal, right ) - 90

	local ForceLinear = Vector(X,Y,Z) * 2000 * deltatime * self.ForceLinearMultiplier
	local ForceAngle = ( Vector(-Roll,-Pitch, self:GetSteer( base, phys ) ) * 12 * self.ForceAngleMultiplier - phys:GetAngleVelocity() * self.ForceAngleDampingMultiplier) * 400 * deltatime

	local SIMULATE = OnGround and SIM_LOCAL_ACCELERATION or SIM_NOTHING

	return ForceAngle, ForceLinear, SIMULATE
end
