AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_prediction.lua" )
AddCSLuaFile( "sh_turret.lua" )
include("shared.lua")
include( "sh_turret.lua" )

ENT.SpawnNormalOffset = 25

function ENT:OnSpawn( PObj )
	PObj:SetMass( 2500 )

	local DriverSeat = self:AddDriverSeat( Vector(20,0,80), Angle(0,-90,0) )
	DriverSeat.HidePlayer = true
	DriverSeat:SetCameraDistance( -0.5 )

	local GunnerSeat = self:AddPassengerSeat( Vector(-75,0,95), Angle(0,-90,0) )
	GunnerSeat.HidePlayer = true
	GunnerSeat:SetCameraDistance( -0.5 )
	self:SetGunnerSeat( GunnerSeat )

	local WheelMass = 25
	local WheelRadius = 15
	local WheelPos = {
		Vector(0,-30,3),
		Vector(95,-70,4),
		Vector(45,-90,5),
		Vector(120,-40,0),
		Vector(0,30,3),
		Vector(95,70,4),
		Vector(45,90,5),
		Vector(120,40,0),
	}

	for _, Pos in pairs( WheelPos ) do
		self:AddWheel( Pos, WheelRadius, WheelMass, 10 )
	end

	self:AddEngineSound( Vector(11,0,35) )

	local ID = self:LookupAttachment( "muzzle_left" )
	local Muzzle = self:GetAttachment( ID )
	self.SNDLeft = self:AddSoundEmitter( self:WorldToLocal( Muzzle.Pos ), "lvs/vehicles/aat/fire.mp3", "lvs/vehicles/aat/fire.mp3" )
	self.SNDLeft:SetSoundLevel( 110 )
	self.SNDLeft:SetParent( self, ID )

	local ID = self:LookupAttachment( "muzzle_right" )
	local Muzzle = self:GetAttachment( ID )
	self.SNDRight = self:AddSoundEmitter( self:WorldToLocal( Muzzle.Pos ), "lvs/vehicles/aat/fire.mp3", "lvs/vehicles/aat/fire.mp3" )
	self.SNDRight:SetSoundLevel( 110 )
	self.SNDRight:SetParent( self, ID )

	local ID = self:LookupAttachment( "muzzle" )
	local Muzzle = self:GetAttachment( ID )
	self.SNDTurret = self:AddSoundEmitter( self:WorldToLocal( Muzzle.Pos ), "lvs/vehicles/aat/fire_turret.mp3", "lvs/vehicles/aat/fire_turret.mp3" )
	self.SNDTurret:SetSoundLevel( 110 )
	self.SNDTurret:SetParent( self, ID )

	--Armor spots protecting the weakspots
	self:AddDSArmor( {
		pos = Vector(60,0,45),
		ang = Angle(0,0,0),
		mins = Vector(-30,-28,-30),
		maxs =  Vector(30,28,30),
		Callback = function( tbl, ent, dmginfo )
		end
	} )

	self:AddDSArmor( {
		pos = Vector(-30,0,75),
		ang = Angle(0,0,0),
		mins = Vector(-60,-28,-15),
		maxs =  Vector(60,28,15),
		Callback = function( tbl, ent, dmginfo )
		end
	} )

	self:AddDSArmor( {
		pos = Vector(11,0,45),
		ang = Angle(-55,0,0),
		mins = Vector(-15,-28,-30),
		maxs =  Vector(15,28,40),
		Callback = function( tbl, ent, dmginfo )
		end
	} )

	self:AddDSArmor( {
		pos = Vector(80,0,25),
		ang = Angle(0,0,0),
		mins = Vector(-50,-100,-15),
		maxs =  Vector(50,100,15),
		Callback = function( tbl, ent, dmginfo )
		end
	} )

	-- weak spots
	self:AddDS( {
		pos = Vector(11,40,46),
		ang = Angle(-55,0,0),
		mins = Vector(-12,-12,-12),
		maxs =  Vector(12,12,12),
		Callback = function( tbl, ent, dmginfo )
			if dmginfo:GetDamage() <= 0 then return end

			dmginfo:ScaleDamage( 1.5 )
		end
	} )

	self:AddDS( {
		pos = Vector(11,-40,46),
		ang = Angle(-55,0,0),
		mins = Vector(-12,-12,-12),
		maxs =  Vector(12,12,12),
		Callback = function( tbl, ent, dmginfo )
			if dmginfo:GetDamage() <= 0 then return end

			dmginfo:ScaleDamage( 1.5 )
		end
	} )
end

function ENT:OnTick()
end

function ENT:OnCollision( data, physobj )
	if self:WorldToLocal( data.HitPos ).z < 15 then return true end -- dont detect collision  when the lower part of the model touches the ground

	return false
end

function ENT:OnIsCarried( name, old, new)
	if new == old then return end

	if new then
		self:SetDisabled( true )
	else
		self:SetDisabled( false )
	end
end
