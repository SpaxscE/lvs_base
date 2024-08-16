AddCSLuaFile()

ENT.Base = "lvs_fortification"

ENT.RenderGroup = RENDERGROUP_BOTH 

ENT._lvsPlayerSpawnPoint = true

ENT.DefaultHP = 1000
ENT.DamageIgnoreType = DMG_GENERIC

function ENT:UpdateTransmitState() 
	return TRANSMIT_ALWAYS
end

function ENT:GetAITEAM()
	local ply = self:GetCreatedBy()

	if not IsValid( ply ) then return 0 end

	return ply:lvsGetAITeam()
end

if SERVER then
	function ENT:Initialize()	
		self:SetModel( "models/maxofs2d/hover_plate.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )
		self:SetUseType( SIMPLE_USE )

		local PObj = self:GetPhysicsObject()

		if not IsValid( PObj ) then 
			self:Remove()

			return
		end

		PObj:EnableMotion( false )
	end

	function ENT:Use( ply )
		if ply:lvsGetAITeam() ~= self:GetAITEAM() then return end

		local T = CurTime()

		if (ply._NextUseSpawnUse or 0) > T then return end

		ply._NextUseSpawnUse = T + 2

		self:EmitSound("buttons/button1.wav")

		ply:ReapplyLoadout()

		ply:SetHealth( ply:GetMaxHealth() )
		ply:SetArmor( ply:GetMaxArmor() )

		local GoalEnt = GAMEMODE:GetGoalEntity()

		if not IsValid( GoalEnt ) or GoalEnt:GetHoldingPlayer() ~= ply then return end

		GAMEMODE:OnPlayerDeliverGoal( ply, self, GoalEnt )

		GoalEnt:Deliver( self )
	end

	function ENT:Think()
		return false
	end

	function ENT:PhysicsCollide( data, physobj )
	end

	function ENT:OnDestroyed()
		GAMEMODE:GameSpawnPointRemoved( self:GetCreatedBy(), self )
	end
end

if CLIENT then
	local ColFriend = GAMEMODE.ColorFriend
	local ColEnemy = GAMEMODE.ColorEnemy

	local ring = Material( "effects/select_ring" )
	local mat = Material( "sprites/light_glow02_add" )

	_LVS_ALL_SPAWN_POINTS = {}

	function ENT:Initialize()
		for _, ent in pairs( ents.FindByClass( self:GetClass() ) ) do
			if table.HasValue( _LVS_ALL_SPAWN_POINTS, ent ) then continue end

			table.insert( _LVS_ALL_SPAWN_POINTS, ent )
		end
	end

	function ENT:GetTeamColor()
		if self:GetAITEAM() ~= LocalPlayer():lvsGetAITeam() then return ColEnemy end

		return ColFriend
	end

	local Mat = Material( "lvs/3d2dmats/refil.png" )

	function ENT:GetPixVis()
		if self.PixVis then return self.PixVis end

		self.PixVis = util.GetPixelVisibleHandle()

		return self.PixVis
	end

	function ENT:DrawTranslucent( flags )
		local Col = self:GetTeamColor()

		local Pos = self:LocalToWorld( Vector(0,0,20) )

		render.SetMaterial( ring )
		render.DrawSprite( Pos, 24 + math.Rand(-1,1), 24 + math.Rand(-1,1), Col )

		render.SetMaterial( mat )
		render.DrawSprite( Pos, 100, 100, Col )

		local ply = LocalPlayer()

		if not IsValid( ply ) or ply:InVehicle() then return end

		if ply:lvsGetAITeam() ~= self:GetAITEAM() then return end

		for i = 0, 1 do
			cam.Start3D2D( Pos, self:LocalToWorldAngles( Angle(0,180 * i + CurTime() * 100,90) ), 0.2 )
				surface.SetDrawColor( color_white )

				surface.SetMaterial( Mat )
				surface.DrawTexturedRect( -100, -100, 200, 200 )
			cam.End3D2D()
		end
	end

	function ENT:Draw( flags )
		self:DrawModel()
	end

	function ENT:OnRemove()
		for id, ent in pairs( _LVS_ALL_SPAWN_POINTS ) do
			if IsValid( ent ) and ent ~= self then continue end

			_LVS_ALL_SPAWN_POINTS[ id ] = nil
		end
	end

	function ENT:Think()
	end
end
