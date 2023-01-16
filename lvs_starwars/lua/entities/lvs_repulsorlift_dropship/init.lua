AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

ENT.SpawnNormalOffset = 25

function ENT:OnSpawn( PObj )
	PObj:SetMass( 10000 )

	local DriverSeat = self:AddDriverSeat( Vector(207,0,120), Angle(0,-90,0) )
	DriverSeat:SetCameraDistance( 1 )
	DriverSeat.ExitPos = Vector(75,0,36)

	local GunnerSeat = self:AddPassengerSeat( Vector(-250,0,250), Angle(0,90,0) )
	GunnerSeat.ExitPos = Vector(75,0,36)
	GunnerSeat.HidePlayer = true
	self:SetGunnerSeat( GunnerSeat )

	self:AddEngine( Vector(-385,0,255) )
	self:AddEngineSound( Vector(-180,0,230) )

	self.PrimarySND = self:AddSoundEmitter( Vector(256,0,36), "lvs/vehicles/laat/fire.mp3", "lvs/vehicles/laat/fire.mp3" )
	self.PrimarySND:SetSoundLevel( 110 )

	self.SNDTail = self:AddSoundEmitter( Vector(-440,0,157), "lvs/vehicles/arc170/fire_gunner.mp3", "lvs/vehicles/arc170/fire_gunner.mp3" )
	self.SNDTail:SetSoundLevel( 110 )
end

function ENT:OnEngineActiveChanged( Active )
	if Active then
		self:EmitSound( "lvs/vehicles/naboo_n1_starfighter/start.wav" )
	else
		self:EmitSound( "lvs/vehicles/laat/landing.wav" )
	end
end

function ENT:OnTick()
	self:Grabber()
end

function ENT:ToggleGrabber()
	self.GrabberEnabled = not self.GrabberEnabled

	if self.GrabberEnabled then
		self:EmitSound( "LVS.LAAT.GRABBER" )

		if IsValid( self.PICKUP_ENT ) then
			self.PosEnt = ents.Create( "prop_physics" )

			if IsValid( self.PosEnt ) then
				self.PosEnt:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )
				self.PosEnt:SetPos( self.PICKUP_ENT:GetPos() )
				self.PosEnt:SetAngles( self.PICKUP_ENT:GetAngles() )
				self.PosEnt:SetCollisionGroup( COLLISION_GROUP_WORLD )
				self.PosEnt:Spawn()
				self.PosEnt:Activate()
				self.PosEnt:SetNoDraw( true ) 
				self:DeleteOnRemove( self.PosEnt )

				constraint.Weld( self.PosEnt, self.PICKUP_ENT, 0, 0, 0, false, false )

				if self.PICKUP_ENT.GetRearEntity then
					local RearEnt = self.PICKUP_ENT:GetRearEntity()
					RearEnt:SetAngles( self.PICKUP_ENT:GetAngles() )
					RearEnt:SetPos( self.PICKUP_ENT:GetPos() )
					constraint.Weld( self.PosEnt, RearEnt, 0, 0, 0, false, false )
					
					self.OldCollisionGroup2 = RearEnt:GetCollisionGroup()
					
					RearEnt:SetCollisionGroup( COLLISION_GROUP_WORLD )
					
					self:ResetFilters()
				end

				self:ResetFilters()

				self:SetHeldEntity( self.PICKUP_ENT )

				self.OldCollisionGroup = self:GetHeldEntity():GetCollisionGroup()
				self:GetHeldEntity():SetCollisionGroup( COLLISION_GROUP_WORLD )

				if self:GetHeldEntity().SetIsCarried then
					self:GetHeldEntity():SetIsCarried( true )
				end
			else
				self.GrabberEnabled = false
				print("[LVS] LAATc: ERROR COULDN'T CREATE PICKUP_ENT")
			end
		end
	else
		if IsValid( self:GetHeldEntity() ) then
			if self:CanDrop() then
				self:DropHeldEntity()
			else
				self:EmitSound( "LVS.LAAT.GRABBER_CANTDROP" )
				self.GrabberEnabled = true
			end
		else
			self:EmitSound( "LVS.LAAT.GRABBER" )
		end
	end
end

function ENT:OnDestroyed()
	self:DropHeldEntity()
end

function ENT:OnRemoved()
	self:DropHeldEntity()
end

function ENT:DropHeldEntity()
	self:ResetFilters()

	if IsValid( self.PosEnt ) then
		self.PosEnt:Remove()
	end

	local FrontEnt = self:GetHeldEntity()

	if IsValid( FrontEnt ) then
		if FrontEnt.SetIsCarried then
			FrontEnt:SetIsCarried( false )
		end

		if FrontEnt.GetRearEntity then
			local RearEnt = self:GetHeldEntity():GetRearEntity()

			RearEnt:SetCollisionGroup( self.OldCollisionGroup2 or COLLISION_GROUP_NONE  )
		end

		FrontEnt:SetCollisionGroup( self.OldCollisionGroup or COLLISION_GROUP_NONE )
		FrontEnt.smSpeed = 200
	end

	self:SetHeldEntity( NULL )
end

function ENT:Grabber()
	local Rate = FrameTime()
	local Active = self.GrabberEnabled

	self.smGrabber = self.smGrabber and self.smGrabber + math.Clamp( (Active and 0 or 1) - self.smGrabber,-Rate,Rate) or 0
	self:SetPoseParameter("grabber", self.smGrabber )

	if Active then
		if IsValid( self.PosEnt ) then
			local PObj = self.PosEnt:GetPhysicsObject()

			if PObj:IsMotionEnabled() then
				PObj:EnableMotion( false )
			end

			local HeldEntity = self:GetHeldEntity()
			if IsValid( HeldEntity ) then
				self.PosEnt:SetPos( self:LocalToWorld( HeldEntity.LAATC_PICKUP_POS or Vector(0,0,0) ) + self:GetVelocity() * FrameTime() )
				self.PosEnt:SetAngles( self:LocalToWorldAngles( HeldEntity.LAATC_PICKUP_Angle or Angle(0,0,0) ) )
			end

			if self:GetAI() then self:SetAI( false ) end
		end
	else
		if (self.NextFind or 0) < CurTime() then
			self.NextFind = CurTime() + 1

			local StartPos = self:LocalToWorld( Vector(-120,0,100) )

			self.PICKUP_ENT = NULL
			local Dist = 1000
			local SphereRadius = 150

			if istable( GravHull ) then SphereRadius = 300 end

			for k, v in pairs( ents.FindInSphere( StartPos, SphereRadius ) ) do
				if v.LAATC_PICKUPABLE then

					local Len = (StartPos - v:GetPos()):Length()

					if Len < Dist then
						self.PICKUP_ENT = v
						Dist = Len
					end
				end
			end
		end
	end
end

function ENT:HitGround()
	if IsValid( self:GetHeldEntity() ) then
		return false
	end

	local tr = util.TraceLine( {
		start = self:LocalToWorld( Vector(0,0,100) ),
		endpos = self:LocalToWorld( Vector(0,0,-20) ),
		filter = function( ent ) 
			if ( ent == self ) then 
				return false
			end
		end
	} )

	return tr.Hit 
end

function ENT:CanDrop()
	local HeldEntity = self:GetHeldEntity()

	if not IsValid( HeldEntity ) then
		local tr = util.TraceLine( {
			start = self:LocalToWorld( Vector(0,0,100) ),
			endpos = self:LocalToWorld( Vector(0,0,-150) ),
			filter = function( ent ) 
				if ent == self or ent == HeldEntity then 
					return false
				end

				return true
			end
		} )

		return tr.Hit
	else
		if HeldEntity.LAATC_DROP_IN_AIR then return true end

		local TraceStart = 100
		local TraceLength = isnumber( HeldEntity.LAATC_DROP_DISTANCE ) and HeldEntity.LAATC_DROP_DISTANCE or 250

		local tr = util.TraceLine( {
			start = self:LocalToWorld( Vector(0,0,TraceStart) ),
			endpos = self:LocalToWorld( Vector(0,0,TraceStart - TraceLength) ),
			filter = function( ent ) 
				if ent == self or ent == HeldEntity then 
					return false
				end

				return true
			end
		} )

		return tr.Hit
	end
end