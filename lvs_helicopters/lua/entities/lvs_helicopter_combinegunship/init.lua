AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:OnSpawn( PObj )
	local DriverSeat = self:AddDriverSeat( Vector(200,0,0), Angle(0,-90,0) )
	DriverSeat:SetCameraDistance( 0.2 )
	DriverSeat.HidePlayer = true

	self:AddEngineSound( Vector(-133,0,55) )

	self:DrawShadow( false )

	local Body = ents.Create( "lvs_gunship_body" )
	Body:SetPos( self:GetPos() )
	Body:SetAngles( self:GetAngles() )
	Body:Spawn()
	Body:Activate()
	Body:SetParent( self )
	Body:SetSkin( 1 )
	self:DeleteOnRemove( Body )
	self:TransferCPPI( Body )
	self:SetBody( Body )

	local Rotor = self:AddRotor( Vector(-133,0,55), Angle(0,0,0), 0, 4000 )
	function Rotor:CheckRotorClearance()
		if self:GetDisabled() then self:DeleteRotorWash() return end

		local base = self:GetBase()

		if not IsValid( base ) then self:DeleteRotorWash() return end

		if not base:GetEngineActive() then self:DeleteRotorWash() return end

		local Radius = self:GetRadius()

		if base:GetThrottle() > 0.5 then
			self:CreateRotorWash()
		else
			self:DeleteRotorWash()
		end
	end

	local ID = Body:LookupAttachment( "muzzle" )
	local Muzzle = Body:GetAttachment( ID )
	self.weaponSND = self:AddSoundEmitter( Body:WorldToLocal( Muzzle.Pos ), "npc/combine_gunship/gunship_weapon_fire_loop6.wav", "npc/combine_gunship/gunship_fire_loop1.wav" )
	self.weaponSND:SetSoundLevel( 110 )
	self.weaponSND:SetParent( Body, ID )
end

function ENT:SetRotor( PhysRot )
	local Body = self:GetBody()

	if not IsValid( Body ) then return end

	if self._oldPhysRot ~= PhysRot then
		self._oldPhysTor = PhysRot

		if PhysRot then
			Body:SetSkin( 1 )
		else
			Body:SetSkin( 0 )
		end
	end
end

function ENT:OnTick()
	local PhysRot = self:GetThrottle() < 0.85

	if not self:IsEngineDestroyed() then
		self:SetRotor( PhysRot )
	end

	self:AnimBody()
end

function ENT:AnimBody()
	local PhysObj = self:GetPhysicsObject()

	if not IsValid( PhysObj ) then return end

	local Body = self:GetBody()

	if not IsValid( Body ) then return end

	local FT = FrameTime()

	local LocalAngles = self:WorldToLocalAngles( self:GetAimVector():Angle() )

	local VelL = self:WorldToLocal( self:GetPos() + self:GetVelocity() )
	local AngVel = PhysObj:GetAngleVelocity()
	local Steer = self:GetSteer()

	self._smLocalAngles = self._smLocalAngles and self._smLocalAngles + (LocalAngles - self._smLocalAngles) * FT * 4 or LocalAngles
	self._smVelL = self._smVelL and self._smVelL + (VelL - self._smVelL) * FT * 10 or VelL
	self._smAngVel = self._smAngVel and self._smAngVel + (AngVel - self._smAngVel) * FT * 10 or AngVel
	self._smSteer = self._smSteer and self._smSteer + (Steer - self._smSteer) *  FT * 5 or Steer

	Body:SetPoseParameter("flex_vert", self._smSteer.y * 10 + self._smLocalAngles.p * 0.5 )
	Body:SetPoseParameter("flex_horz", self._smAngVel.z * 0.25 - self._smSteer.x * 10 + self._smLocalAngles.y * 0.5 )
	Body:SetPoseParameter("fin_accel", self._smVelL.x * 0.001 + self._smSteer.y * 2 + self._smVelL.z * 0.01 )
	Body:SetPoseParameter("fin_sway", -self._smVelL.y * 0.001 - self._smSteer.x * 2 )
	Body:SetPoseParameter("antenna_accel", self._smVelL.x * 0.001 )
	Body:SetPoseParameter("antenna_sway", -self._smVelL.y * 0.001 )
end