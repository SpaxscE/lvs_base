AddCSLuaFile()

ENT.Type            = "anim"
ENT.DoNotDuplicate = true

if SERVER then
	function ENT:Initialize()	
		self:SetModel( "models/dav0r/hoverball.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetRenderMode( RENDERMODE_TRANSALPHA )
		self:AddFlags( FL_OBJECT )

		local PObj = self:GetPhysicsObject()

		if not IsValid( PObj ) then 
			self:Remove()

			return
		end

		PObj:SetMass( 1 )
		PObj:EnableMotion( false )
		PObj:EnableDrag( false )

		self:SetNotSolid( true )
		self:SetColor( Color( 255, 255, 255, 0 ) ) 
		self:SetRenderMode( RENDERMODE_TRANSALPHA )
		self:DrawShadow( false )
	end

	function ENT:Think()
		return false
	end

	return
end

function ENT:Think()
	return false
end

function ENT:Draw()
end
