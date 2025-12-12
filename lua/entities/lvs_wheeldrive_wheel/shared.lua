
ENT.PrintName = "Wheel"

ENT.Type            = "anim"
ENT.DoNotDuplicate = true

ENT.RenderGroup = RENDERGROUP_BOTH 

ENT._lvsRepairToolLabel = "Wheel"
ENT._lvsNoPhysgunInteraction = true

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "Radius")
	self:NetworkVar( "Float", 1, "Width")

	self:NetworkVar( "Float", 2, "Camber" )
	self:NetworkVar( "Float", 3, "Caster" )
	self:NetworkVar( "Float", 4, "Toe" )

	self:NetworkVar( "Float", 5, "RPM" )

	self:NetworkVar( "Float", 6, "HP" )
	self:NetworkVar( "Float", 7, "MaxHP" )

	self:NetworkVar( "Angle", 0, "AlignmentAngle" )

	self:NetworkVar( "Entity", 0, "Base" )

	self:NetworkVar( "Bool", 0, "HideModel" )
	self:NetworkVar( "Bool", 1, "Destroyed" )
	self:NetworkVar( "Bool", 2, "NWDamaged" )
	self:NetworkVar( "Bool", 3, "WheelChainMode" )

	if SERVER then
		self:SetMaxHP( 100 )
		self:SetHP( 100 )
		self:SetWidth( 3 )

		self:NetworkVarNotify( "HP", self.HealthValueChanged )
	end
end

function ENT:GetDamaged()
	return self:GetNWDamaged()
end

function ENT:VelToRPM( speed )
	if not speed then return 0 end

	return speed * 60 / math.pi / (self:GetRadius() * 2)
end

function ENT:RPMToVel( rpm )
	if not rpm then return 0 end

	return (math.pi * rpm * self:GetRadius() * 2) / 60
end

function ENT:CheckAlignment()
	self.CamberCasterToe = (math.abs( self:GetToe() ) + math.abs( self:GetCaster() ) + math.abs( self:GetCamber() )) ~= 0

	if CLIENT then return end

	local SteerType = self:GetSteerType()
	local Caster = self:GetCaster()

	local Camber = math.abs( self:GetCamber() )
	local CamberValue1 = (math.min( Camber, 15 ) / 15) * 0.3
	local CamberValue2 = (math.Clamp( Camber - 15, 0, 65 ) / 65) * 0.7

	local CasterValue = (math.min( math.abs( Caster ), 15 ) / 15) * math.max( 1 - Camber / 10, 0 )

	if SteerType == LVS.WHEEL_STEER_NONE then CasterValue = 0 end

	if SteerType == LVS.WHEEL_STEER_FRONT and Caster < 0 then CasterValue = 0 end

	if SteerType == LVS.WHEEL_STEER_REAR and Caster > 0 then CasterValue = 0 end

	local TractionValue = 1 - CamberValue1 -  CamberValue2 + CasterValue

	self:PhysicsMaterialUpdate( TractionValue )

	return TractionValue
end