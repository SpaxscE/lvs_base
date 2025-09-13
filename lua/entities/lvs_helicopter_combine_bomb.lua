AddCSLuaFile()

ENT.Base = "lvs_bomb"
DEFINE_BASECLASS( "lvs_bomb" )

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true

ENT.ExplosionEffect = "lvs_explosion_small"

function ENT:Initialize()
	self:SetModel("models/Combine_Helicopter/helicopter_bomb01.mdl")
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSkin( 1 )
end

if SERVER then
	function ENT:OnTakeDamage( dmginfo )
		if self.IsTimerStarted then
			self:Detonate()
		else
			self:StartDetonationTimer()
		end
	end

	function ENT:Think()	
		local T = CurTime()

		self:NextThink( T )

		self:UpdateTrajectory()

		if not self.SpawnTime then return true end

		if (self.SpawnTime + 30) < T then
			if self.IsTimerStarted then
				self:Detonate()
			else
				self:Destroy()
			end
		end

		return true
	end

	function ENT:StartDetonationTimer()
		if self.IsTimerStarted then return end

		self.IsTimerStarted = true

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

	function ENT:PhysicsCollide( data )
		if istable( self._FilterEnts ) and self._FilterEnts[ data.HitEntity ] then return end

		if IsValid( data.HitEntity ) then
			self:Detonate()
		else
			self:StartDetonationTimer()
		end
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
		if self.snd then
			self.snd:Stop()
			self.snd = nil
		end

		BaseClass.OnRemove( self )
	end

	return
end

function ENT:Enable()
	if self.IsEnabled then return end

	self.IsEnabled = true
end

