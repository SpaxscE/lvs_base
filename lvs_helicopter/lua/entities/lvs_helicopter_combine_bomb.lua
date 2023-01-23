AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true

ENT.ExplosionEffect = "lvs_explosion_small"

if SERVER then
	function ENT:SetAttacker( ent ) self._attacker = ent end
	function ENT:GetAttacker() return self._attacker or NULL end

	function ENT:Initialize()	
		self:SetModel("models/Combine_Helicopter/helicopter_bomb01.mdl")
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetSkin( 1 )

		self.DieTime = CurTime() + 30

		self:PhysWake()

		self:SetModelScale( 0 )
		self:SetModelScale( 1, 0.25 )
	end

	function ENT:OnTakeDamage( dmginfo )
		if self.IsEnabled then
			self:Detonate()
		else
			self:Enable()
		end
	end

	function ENT:Think()
		local T = CurTime()

		self:NextThink( T + 0.5 )

		if not self.DieTime then return true end

		if not self.IsEnabled and self.DieTime < T then
			self:Destroy()
		end

		return true
	end

	function ENT:UpdateTransmitState() 
		return TRANSMIT_ALWAYS
	end

	function ENT:Enable()
		if self.IsEnabled then return end

		self.IsEnabled = true

		self.snd = CreateSound( self, "npc/attack_helicopter/aheli_mine_seek_loop1.wav" )
		self.snd:PlayEx( 0, 100 )
		self.snd:ChangeVolume(1, 0.5 )

		self:SetSkin( 0 )

		timer.Simple(3, function()
			if not IsValid( self ) or not self.snd then return end

			self.snd:ChangePitch(160, 1 )

			self:SetSkin( 1 )
		end )

		timer.Simple(3.5, function()
			if not IsValid( self ) then return end

			self:SetSkin( 0 )
		end )

		timer.Simple(3.75, function()
			if not IsValid( self ) then return end

			self:SetSkin( 1 )
		end )

		timer.Simple(4, function()
			if not IsValid( self ) then return end

			self:Detonate()
		end )
	end

	function ENT:PhysicsCollide( data, physobj )
		if self.IsEnabled and IsValid( data.HitEntity ) then
			self:Detonate()
		else
			self:Enable()
		end
	end

	function ENT:Detonate()
		if self.IsDetonated then return end

		self.IsDetonated = true

		local Pos = self:GetPos() 

		local effectdata = EffectData()
			effectdata:SetOrigin( Pos )
		util.Effect( self.ExplosionEffect, effectdata )

		local attacker = self:GetAttacker()

		util.BlastDamage( self, IsValid( attacker ) and attacker or game.GetWorld(), Pos, 250, 150 )

		SafeRemoveEntityDelayed( self, FrameTime() )
	end

	function ENT:Destroy()
		if self.IsDestroyed then return end

		self.IsDestroyed = true

		local mdl = ents.Create( "prop_physics" )
		mdl:SetModel( self:GetModel() )
		mdl:SetPos( self:GetPos() )
		mdl:SetAngles( self:GetAngles() )
		mdl:Spawn()
		mdl:Fire("break")

		self:Remove()
	end

	function ENT:OnRemove()
		if not self.snd then return end

		self.snd:Stop()
		self.snd = nil
	end

	return
end

function ENT:Draw()
	self:DrawModel()
end
