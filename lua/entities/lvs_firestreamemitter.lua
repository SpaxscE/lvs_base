AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "Flamethrower"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "FlameVelocity" )
	self:NetworkVar( "Bool", 0, "Active" )
	self:NetworkVar( "String", 0, "TargetAttachment" )
	self:NetworkVar( "Entity", 0, "Target" )

	if SERVER then
		self:SetFlameVelocity( 1000 )
	end
end

if SERVER then
	function ENT:SetEntityFilter( filter )
		if not istable( filter ) then return end

		self._FilterEnts = {}

		for _, ent in pairs( filter ) do
			self._FilterEnts[ ent ] = true
		end
	end
	function ENT:SetActiveDelay( num )
		self._activationdelay = num
	end

	function ENT:SetDamage( num ) self._dmg = num end
	function ENT:SetAttacker( ent ) self._attacker = ent end
	function ENT:GetAttacker() return self._attacker or NULL end
	function ENT:GetDamage() return (self._dmg or 2000) end
		function ENT:GetEntityFilter()
		return self._FilterEnts or {}
	end
	function ENT:GetActiveDelay()
		return (self._activationdelay or 0.5)
	end

	function ENT:AttachTo( target, attachment )
		if not IsValid( target ) or IsValid( self:GetTarget() ) then return end

		self:SetPos( target:GetPos() )
		self:SetAngles( target:GetAngles() )
		self:SetParent( target )
		self:SetTarget( target )
		self:SetTargetAttachment( attachment or "" )
	end

	function ENT:Enable()
		self._LastInput = true

		if self:GetActive() then return end

		self._MinTime = CurTime() + self:GetActiveDelay()

		self:SetActive( true )
		self:HandleActive()

		local Delay = self:GetActiveDelay()

		if self._LastFlameActive and self._LastFlameActive > (CurTime() - Delay) then return end

		local effectdata = EffectData()
			effectdata:SetOrigin( self:LocalToWorld( self:OBBCenter() ) )
			effectdata:SetEntity( self )
			effectdata:SetMagnitude( Delay )
		util.Effect( "lvs_flamestream_start", effectdata )

		self:EmitSound("lvs/weapons/flame_start.wav")
	end

	function ENT:Disable()
		self._LastInput = nil

		if not self:GetActive() then return end

		if self._MinTime and self._MinTime > CurTime() then
			timer.Simple( self:GetActiveDelay() + 0.1, function()
				if not IsValid( self ) or self._LastInput then return end

				self:Disable()
			end )

			return
		end

		self:SetActive( false )
		self:HandleActive()
		self:EmitSound("lvs/weapons/flame_end.wav")

		if not self._snd then return end

		self:StopLoopingSound( self._snd )
	end

	function ENT:Initialize()
	end

	function ENT:HandleActive()
		local T = CurTime()
		local Delay = self:GetActiveDelay()

		if not self:GetActive() then
			if self._IsActive then
				self._IsActive = nil
				self._IsFlameActive = nil
			end

			self:NextThink( T + Delay )

			return
		end

		if not self._IsActive then
			self._IsActive = true

			if self._LastFlameActive and self._LastFlameActive > (T - Delay) then
				self:NextThink( T )
			else
				self:NextThink( T + Delay )
			end

			return
		end

		self._LastFlameActive = T

		if not self._IsFlameActive then
			self._IsFlameActive = true

			local effectdata = EffectData()
				effectdata:SetOrigin( self:LocalToWorld( self:OBBCenter() ) )
				effectdata:SetEntity( self )
				effectdata:SetMagnitude( Delay )
			util.Effect( "lvs_flamestream_start", effectdata )

			local effectdata = EffectData()
				effectdata:SetOrigin( self:LocalToWorld( self:OBBCenter() ) )
				effectdata:SetEntity( self )
			util.Effect( "lvs_flamestream", effectdata )

			self._snd = self:StartLoopingSound("lvs/weapons/flame_loop.wav")
		end

		self:NextThink( T )
	end

	function ENT:Think()

		self:HandleActive()

		return true
	end

	return
end

function ENT:Draw( flags )
end

function ENT:Think()
end
