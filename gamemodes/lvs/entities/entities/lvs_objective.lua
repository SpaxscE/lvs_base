AddCSLuaFile()

ENT.Type            = "anim"

ENT.RenderGroup = RENDERGROUP_BOTH 

ENT._lvsLaserGunDetectHit = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",1, "HoldingPlayer" )
	self:NetworkVar( "Entity",2, "LinkedSpawnPoint" )

	self:NetworkVar( "Float", 1, "LastTouched" )
end

function ENT:GetAITEAM()
	local spawnpoint =  self:GetLinkedSpawnPoint()

	if IsValid( spawnpoint ) then return spawnpoint:GetAITEAM() end
	
	local ply = self:GetHoldingPlayer()

	if not IsValid( ply ) then return 0 end

	return ply:lvsGetAITeam()
end

function ENT:UpdateTransmitState() 
	return TRANSMIT_ALWAYS
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:DrawShadow( false )
		self:SetTrigger( true )
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )
	end

	function ENT:StartTouch( entity )
		self:Pickup( entity )
	end

	function ENT:EndTouch( entity )
	end

	function ENT:Touch( entity )
	end

	function ENT:Deliver( entity )
		self._IsDelivered = true
		self._DeliveredPlayer = self:GetHoldingPlayer()
		self._DeliveredTeam = entity:GetAITEAM()

		self:SetLinkedSpawnPoint( entity )
		self:SetHoldingPlayer( NULL )
		self:SetPos( entity:GetPos() + Vector(0,0,10) )
	end

	function ENT:Pickup( entity )
		if IsValid( self:GetHoldingPlayer() ) then return end

		if not IsValid( entity ) or not entity:IsPlayer() then return end

		local Team = entity:lvsGetAITeam() 

		if Team ~= 1 and Team ~= 2 then return end

		self:SetHoldingPlayer( entity )
		self:SetLinkedSpawnPoint( NULL )
		self:SetSolid( SOLID_NONE )
		self:SetTrigger( false )
		self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )

		GAMEMODE:OnPlayerPickupGoal( entity, Team, self )
	end

	function ENT:Drop( ply, team )
		self:SetHoldingPlayer( NULL )
		self:SetLinkedSpawnPoint( NULL )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetTrigger( true )
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )

		if self._IsDelivered then
			GAMEMODE:OnPlayerDropGoal( self._DeliveredPlayer, self._DeliveredTeam, self )

			self._IsDelivered = nil
			self._DeliveredTeam = nil
			self._DeliveredPlayer = nil

			return
		end
	
		GAMEMODE:OnPlayerDropGoal( ply, team, self )
	end

	function ENT:Think()
		self:NextThink( CurTime() )

		local PhysObj = self:GetPhysicsObject()

		if IsValid( PhysObj ) and PhysObj:IsMotionEnabled() and not self:IsPlayerHolding() then
			PhysObj:EnableMotion( false )
		end

		if self._IsDelivered then
			local LinkedSpawn = self:GetLinkedSpawnPoint()

			if IsValid( LinkedSpawn ) then

				GAMEMODE:DeliveredGoalThink( self._DeliveredPlayer, self:GetAITEAM() )

				return true
			end

			self:Drop()

			return true
		end

		local ply = self:GetHoldingPlayer()

		if not IsValid( ply ) then return true end

		local Team = ply:lvsGetAITeam() 

		if not ply:Alive() or (Team ~= 1 and Team ~= 2) then
			self:Drop( ply, Team )

			return true
		end

		self:SetPos( ply:GetShootPos() )

		return true
	end

	function ENT:PhysicsCollide( data, physobj )
	end

	function ENT:OnTakeDamage( dmginfo )
		self:SetLastTouched( CurTime() )
	end

	hook.Add( "PlayerDisconnected", "!!!!lvs_drop_goal_on_disconnect", function( ply )
		local GoalEnt = GAMEMODE:GetGoalEntity()

		if not IsValid( GoalEnt ) or GoalEnt:GetHoldingPlayer() ~= ply then return end

		local Team = ply:lvsGetAITeam() 

		GoalEnt:Drop( ply, Team )
	end )
else
	local ring = Material( "effects/select_ring" )
	local mat = Material( "sprites/light_glow02_add" )
	local Mat = Material( "lvs/3d2dmats/arrow.png" )

	function ENT:DrawTranslucent( flags )
		if IsValid( self:GetHoldingPlayer() ) then return end

		local Pos = self:GetPos() + Vector(0,0,10)

		if IsValid( self:GetLinkedSpawnPoint() ) then
			render.SetMaterial( ring )
			render.DrawSprite( Pos, 27 + math.Rand(-1,1), 27 + math.Rand(-1,1), GAMEMODE.ColorNeutral )

			return
		end

		local T = CurTime()

		if (self:GetLastTouched() + 0.25) > T then
			render.SetMaterial( ring )
			render.DrawSprite( Pos, 14 + math.Rand(-10,10), 14 + math.Rand(-10,10), Color(150,200,255) )

			render.SetMaterial( mat )
			render.DrawSprite( Pos, 100, 100, Color(150,200,255) )

			cam.Start3D2D( Pos, Angle(math.cos( T ) * 360, math.cos( T * 2 ) * 360,math.sin( T ) * 360), 0.1 )
				surface.SetDrawColor( color_white )

				surface.SetMaterial( Mat )
				surface.DrawTexturedRect( -100, -100, 200, 200 )
			cam.End3D2D()

			if (self._NextFX or 0) < T then
				self._NextFX = T + 0.02
	
				local effectdata = EffectData()
					effectdata:SetOrigin( Pos + VectorRand() * math.Rand(-10,10) )
					effectdata:SetNormal( VectorRand() )
				util.Effect( "lvs_lasergun_hitwall_other", effectdata )
			end

			return
		else
			render.SetMaterial( ring )
			render.DrawSprite( Pos, 24 + math.Rand(-1,1), 24 + math.Rand(-1,1), GAMEMODE.ColorNeutral )

			render.SetMaterial( mat )
			render.DrawSprite( Pos, 100, 100, GAMEMODE.ColorNeutral )
		end

		local ply = self:GetHoldingPlayer()

		if IsValid( ply ) then return end

		for i = 0, 1 do
			cam.Start3D2D( Pos, Angle(180,180 * i + T * 100,90), 0.1 )
				surface.SetDrawColor( color_white )

				surface.SetMaterial( Mat )
				surface.DrawTexturedRect( -100, -100, 200, 200 )
			cam.End3D2D()
		end
	end

	function ENT:Draw( flags )
	end
end