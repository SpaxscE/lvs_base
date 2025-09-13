AddCSLuaFile()

ENT.Base = "lvs_item_spikestrip"

ENT.AutomaticFrameAdvance = true

ENT.PhysicsSounds = true

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/diggercars/shared/spikestrip_fold.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetTrigger( true )
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
		self:AddEFlags( EFL_NO_PHYSCANNON_INTERACTION )
		self:SetUseType( SIMPLE_USE )

		local PhysObj = self:GetPhysicsObject()

		if not IsValid( PhysObj ) then return end

		PhysObj:EnableDrag( false )
	end

	function ENT:UpdateFold()
		if not self._StartFold then return end

		if not self._poseValue then
			self._poseValue = 0

			self:EmitSound("buttons/lever4.wav")
		end

		if self._poseValue >= 1 then return end

		self._poseValue = math.min( self._poseValue + FrameTime(), 1 )

		self:SetPoseParameter( "fold", self._poseValue )
	end

	function ENT:PhysicsCollide( data, physobj )
		self._StartFold = true
	end

	function ENT:Use( ply )
		if not IsValid( ply ) or not ply:IsPlayer() then return end

		local PhysObj = self:GetPhysicsObject()

		if not IsValid( PhysObj ) then return end

		if PhysObj:IsMotionEnabled() then return end

		if ply:HasWeapon("weapon_lvsspikestrip") then return end

		ply:EmitSound("items/ammo_pickup.wav")
		ply:Give("weapon_lvsspikestrip")
		ply:SelectWeapon("weapon_lvsspikestrip")

		self:Remove()
	end

	return
end

function ENT:Draw( flags )
	self:DrawModel( flags )
end

function ENT:DrawTranslucent( flags )
	self:DrawModel( flags )
end