AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_prediction.lua" )
AddCSLuaFile( "sh_turret.lua" )
include("shared.lua")
include( "sh_turret.lua" )

ENT.SpawnNormalOffset = 45

function ENT:OnSpawn( PObj )
	PObj:SetMass( 2500 )

	local DriverSeat = self:AddDriverSeat( Vector(-30,0,43), Angle(0,-90,0) )
	DriverSeat.HidePlayer = true

	local GunnerSeat = self:AddPassengerSeat( Vector(-61,0,60), Angle(0,-90,0) )
	GunnerSeat.HidePlayer = true
	self:SetGunnerSeat( GunnerSeat )

	self.sndBTL = self:AddSoundEmitter( Vector(0,0,0), "lvs/vehicles/laat/ballturret_loop.wav", "lvs/vehicles/laat/ballturret_loop.wav" )
	self.sndBTL:SetSoundLevel( 110 )

	local ID = self:LookupAttachment( "gunner" )
	local Attachment = self:GetAttachment( ID )

	if Attachment then
		local Pos,Ang = LocalToWorld( Vector(0,-15,0), Angle(180,0,-90), Attachment.Pos, Attachment.Ang )

		GunnerSeat:SetParent( NULL )
		GunnerSeat:SetPos( Pos )
		GunnerSeat:SetAngles( Ang )
		GunnerSeat:SetParent( self )

		self.sndBTL:SetParent( NULL )
		self.sndBTL:SetPos( Pos )
		self.sndBTL:SetAngles( Ang )
		self.sndBTL:SetParent( self )
	end

	local WheelMass = 25
	local WheelRadius = 14
	local WheelPos = {
		Vector(-85,-60,-12),
		Vector(-5,-60,-11),
		Vector(80,-60,-8),
		Vector(-85,60,-12),
		Vector(-5,60,-11),
		Vector(80,60,-8),
	}

	for _, Pos in pairs( WheelPos ) do
		self:AddWheel( Pos, WheelRadius, WheelMass, 10 )
	end

	self:AddEngineSound( Vector(0,0,30) )

	local ID = self:LookupAttachment( "muzzle_left" )
	local Muzzle = self:GetAttachment( ID )
	self.SNDLeft = self:AddSoundEmitter( self:WorldToLocal( Muzzle.Pos ), "lvs/vehicles/iftx/fire.mp3", "lvs/vehicles/iftx/fire.mp3" )
	self.SNDLeft:SetSoundLevel( 110 )
	self.SNDLeft:SetParent( self, ID )

	local ID = self:LookupAttachment( "muzzle_right" )
	local Muzzle = self:GetAttachment( ID )
	self.SNDRight = self:AddSoundEmitter( self:WorldToLocal( Muzzle.Pos ), "lvs/vehicles/iftx/fire.mp3", "lvs/vehicles/iftx/fire.mp3" )
	self.SNDRight:SetSoundLevel( 110 )
	self.SNDRight:SetParent( self, ID )

	--Armor spots protecting the weakspots
	self:AddDSArmor( {
		pos = Vector(-70,0,35),
		ang = Angle(0,0,0),
		mins = Vector(-10,-40,-30),
		maxs =  Vector(10,40,30),
		Callback = function( tbl, ent, dmginfo )
		end
	} )

	-- weak spots
	self:AddDS( {
		pos = Vector(-95,0,35),
		ang = Angle(0,0,0),
		mins = Vector(-10,-25,-25),
		maxs =  Vector(10,25,25),
		Callback = function( tbl, ent, dmginfo )
			if dmginfo:GetDamage() <= 0 then return end

			dmginfo:ScaleDamage( 1.5 )
		end
	} )
end

function ENT:AnimHatch()
	local pod = self:GetGunnerSeat()

	if not IsValid( pod ) then return end

	local HasTurret = self:GetBodygroup(1) == 2 and not IsValid( pod:GetDriver() )

	local Rate = FrameTime() * 5
	self.smHatch = self.smHatch and self.smHatch + math.Clamp((HasTurret and 1 or 0) - self.smHatch,-Rate,Rate) or 0

	if not HasTurret and self.smHatch > 0.7 then self.smHatch = 0.7 end

	self:SetPoseParameter( "close_hatch", self.smHatch )
end

function ENT:AnimMove()
	local phys = self:GetPhysicsObject()

	if not IsValid( phys ) then return end

	local steer = phys:GetAngleVelocity().z

	local VelL = self:WorldToLocal( self:GetPos() + self:GetVelocity() )

	self:SetPoseParameter( "move_x", math.Clamp(-VelL.x / self.MaxVelocityX,-1,1) )
	self:SetPoseParameter( "move_y", math.Clamp(-VelL.y / self.MaxVelocityY + steer / 100,-1,1) )
end

function ENT:OnTick()
	self:AnimHatch()
	self:AnimMove()
end

function ENT:OnCollision( data, physobj )
	if self:WorldToLocal( data.HitPos ).z < 0 then return true end -- dont detect collision  when the lower part of the model touches the ground

	return false
end

function ENT:OnIsCarried( name, old, new)
	if new == old then return end

	if new then
		self:SetPoseParameter( "move_x", 0 )
		self:SetPoseParameter( "move_y", 0 )

		self:SetBTLFire( false )

		self:SetDisabled( true )
	else
		self:SetDisabled( false )
	end
end

function ENT:OnVehicleSpecificToggled( IsActive )
	self:SetBodygroup(2, (self:GetBodygroup(2) == 1) and 0 or 1 )
	self:EmitSound( "buttons/lightswitch2.wav", 75, 105 )
end

function ENT:BallturretDamage( target, attacker, HitPos, HitDir )
	if not IsValid( target ) then return end

	if not IsValid( attacker ) then
		attacker = self
	end

	if target ~= self then
		local dmginfo = DamageInfo()
		dmginfo:SetDamage( 250 * FrameTime() )
		dmginfo:SetAttacker( attacker )
		dmginfo:SetDamageType( DMG_SHOCK + DMG_ENERGYBEAM + DMG_AIRBOAT )
		dmginfo:SetInflictor( self ) 
		dmginfo:SetDamagePosition( HitPos ) 
		dmginfo:SetDamageForce( HitDir * 10000 ) 
		target:TakeDamageInfo( dmginfo )
	end
end

