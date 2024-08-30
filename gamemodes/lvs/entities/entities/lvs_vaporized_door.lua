AddCSLuaFile()

ENT.Type            = "anim"

ENT.RenderGroup = RENDERGROUP_BOTH 

function ENT:SetupDataTables()
	self:NetworkVar( "Vector", 0, "HolePos" )
	self:NetworkVar( "Vector", 1, "HoleDir" )
end

if SERVER then
	function ENT:Initialize()
		self:SetSolid( SOLID_NONE )
		self:SetMoveType( MOVETYPE_NONE )
		self:DrawShadow( false )

		local Dissolver = ents.Create("env_entity_dissolver")

		local Time = CurTime()

		Dissolver:SetKeyValue("magnitude","0.5")
		Dissolver:SetKeyValue("dissolvetype","0")
		Dissolver:SetPos( self:GetPos() )
		Dissolver:Spawn()
		Dissolver:Activate()

		self:SetName("cockdestroyer"..Time)

		Dissolver:Fire("dissolve","cockdestroyer"..Time,0)
		Dissolver:Fire( "kill", "",  0.1 )

		self:EmitSound("ambient/energy/weld"..math.random(1,2)..".wav")
	end

	function ENT:Think()
		return false
	end

	function ENT:PhysicsCollide( data, physobj )
	end

	function ENT:OnTakeDamage( dmginfo )
	end
end

if CLIENT then
	local Delay = 2

	function ENT:Initialize()
		self.FinishTime = CurTime() + Delay
	end

	function ENT:GetHoleCutter()
		if IsValid( self._HoleCutter ) then return self._HoleCutter end

		self._HoleCutter = ClientsideModel( "models/XQM/Rails/gumball_1.mdl" )
		self._HoleCutter:SetPos( self:LocalToWorld( self:GetHolePos() ) )
		self._HoleCutter:SetAngles( self:GetAngles() )
		self._HoleCutter:SetParent( self )
		self._HoleCutter:SetNoDraw( true )

		return self._HoleCutter
	end

	local ring = Material( "effects/select_ring" )

	function ENT:GetBounds()
		local mins = self:OBBMins()
		local maxs = self:OBBMaxs()

		local X = math.abs( mins.x ) + math.abs( maxs.x )
		local Y = math.abs( mins.y ) + math.abs( maxs.y )
		local Z = math.abs( mins.z ) + math.abs( maxs.z )

		local L = math.max( X, Y, Z )

		local Scale = self:GetScale()
		local InvScale = 1 - Scale

		return (Vector(L,L,L) * InvScale + Vector( X, Y, Z ) * 1.5 * Scale) * Scale
	end

	function ENT:GetScale()
		return (1 - math.max( (self.FinishTime - CurTime()) / Delay, 0 ))
	end

	function ENT:DrawTranslucent( flags )
		local Scale = self:GetScale()

		if Scale >= 1 then return end

		local InvScale = 1 - Scale

		local Bounds = self:GetBounds()
		local Dir = self:GetHoleDir()

		cam.Start3D2D( self:LocalToWorld( self:GetHolePos() ) - Dir, Dir:Angle() + Angle(90,0,0), 1.8 )
			surface.SetDrawColor( Color(150 * InvScale, 200 * InvScale, 255 * InvScale, 255 * InvScale) )
			surface.SetMaterial( ring )
			surface.DrawTexturedRect( -Bounds.z * 0.5, -Bounds.y * 0.5, Bounds.z, Bounds.y )
		cam.End3D2D()

		self:Draw( flags )
	end

	function ENT:Draw( flags )
		local Scale = self:GetScale()

		if Scale >= 1 then return end

		local HoleCutter = self:GetHoleCutter()

		local Bounds = self:GetBounds()
	
		local mat = Matrix()
		mat:Scale( Bounds * 0.05 )

		HoleCutter:EnableMatrix("RenderMultiply", mat)

		render.SetStencilWriteMask( 0xFF )
		render.SetStencilTestMask( 0xFF )
		render.SetStencilReferenceValue( 0 )
		render.SetStencilPassOperation( STENCIL_KEEP )
		render.SetStencilZFailOperation( STENCIL_KEEP )
		render.ClearStencil()

		render.SetStencilEnable( true )
		render.SetStencilReferenceValue( 1 )
		render.SetStencilCompareFunction( STENCIL_NEVER )
		render.SetStencilFailOperation( STENCIL_REPLACE )

		HoleCutter:DrawModel( flags )

		render.SetStencilCompareFunction( STENCIL_NOTEQUAL )
		render.SetStencilFailOperation( STENCIL_KEEP )

		self:DrawModel( flags )

		render.SetStencilEnable( false )
	end

	function ENT:OnRemove()
		self:GetHoleCutter():Remove()
	end

	function ENT:Think()
	end
end
