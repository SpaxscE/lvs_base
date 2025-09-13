AddCSLuaFile()

ENT.Type            = "anim"

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )

	self:NetworkVar( "Entity",1, "Wheel" )

	self:NetworkVar( "Float",0, "Pose0" )
	self:NetworkVar( "Float",1, "Pose1" )

	self:NetworkVar( "String",0, "NameID" )
end

if SERVER then
	function ENT:Initialize()	
		self:SetModel( "models/dav0r/hoverball.mdl" )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )
	end

	function ENT:Think()
		return false
	end
end

if CLIENT then
	function ENT:Draw()
	end

	function ENT:OnRemove()
	end

	function ENT:Think()
		local Base = self:GetBase()
		local Wheel = self:GetWheel()

		if not IsValid( Base ) or not IsValid( Wheel ) then return end

		local id = self:GetNameID()
		local rotation = -self:WorldToLocalAngles( Wheel:GetAngles() ).r

		local zpos = Base:WorldToLocal( Wheel:GetPos() ).z

		if Wheel:GetNWDamaged() then zpos = zpos - Base.WheelPhysicsTireHeight end

		Base:SetPoseParameter("vehicle_wheel_"..id.."_spin",rotation)
		Base:SetPoseParameter("vehicle_wheel_"..id.."_height",math.Remap( zpos, self:GetPose0(), self:GetPose1(), 0, 1))
	end
end
