AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:OnSpawn( PObj )
	self:SetBodygroup( 14, 1 ) 
	self:SetBodygroup( 13, 1 ) 

	PObj:SetMass( 5000 )

	self:AddDriverSeat( Vector(32,0,67.5), Angle(0,-90,0) )

	self:AddWheel( Vector(78.12,55,15.16), 13, 600 )
	self:AddWheel( Vector(78.12,-55,15.16), 13, 600 )
	self:AddWheel( Vector(-146.61,0,76), 13, 1200, LVS.WHEEL_STEER_REAR )

	local Engine = self:AddEngine( Vector(115,0,75) )

	local data = {}
		data.SoundPath = "LFS_BF109_RPM1"
		data.StartPitch = 100
		data.MinPitch = 0
		data.MaxPitch = 255
		data.PitchMul = 300
		data.UseDoppler = true
		data.FadeIn = 0
		data.FadeOut = 0.2
		data.FadeSpeed = 1.5
	Engine:AddSound( data )

	local data = {}
		data.SoundPath = "LFS_BF109_RPM2"
		data.StartPitch = 20
		data.MinPitch = 0
		data.MaxPitch = 160
		data.PitchMul = 280
		data.UseDoppler = true
		data.FadeIn = 0.2
		data.FadeOut = 0.4
		data.FadeSpeed = 1.5
	Engine:AddSound( data )

	local data = {}
		data.SoundPath = "LFS_BF109_RPM3"
		data.StartPitch = 60
		data.MinPitch = 0
		data.MaxPitch = 255
		data.PitchMul = 110
		data.UseDoppler = true
		data.FadeIn = 0.4
		data.FadeOut = 0.65
		data.FadeSpeed = 1.5
	Engine:AddSound( data )

	local data = {}
		data.SoundPath = "LFS_BF109_RPM4"
		data.StartPitch = 75
		data.MinPitch = 0
		data.MaxPitch = 255
		data.PitchMul = 50
		data.UseDoppler = true
		data.FadeIn = 0.65
		data.FadeOut = 1
		data.FadeSpeed = 1
	Engine:AddSound( data )
end

function ENT:OnLandingGearToggled( IsDeployed )
	self:EmitSound( "lvs/vehicles/bf109/gear.wav" )
end