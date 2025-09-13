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
	self:NetworkVar( "Float", 1, "FlameLifeTime" )
	self:NetworkVar( "Float", 2, "FlameSize" )

	self:NetworkVar( "Bool", 0, "Active" )
	self:NetworkVar( "String", 0, "TargetAttachment" )
	self:NetworkVar( "Entity", 0, "Target" )

	if SERVER then
		self:SetFlameLifeTime( 1.5 )
		self:SetFlameVelocity( 1000 )
		self:SetFlameSize( 80 )
	end
end

function ENT:GetTargetVelocity()
	local Target = self:GetTarget()

	if not IsValid( Target ) then return vector_origin end

	return Target:GetVelocity()
end

function ENT:GetPosition()
	local Pos = self:GetPos()
	local Dir = self:GetForward()

	local Target = self:GetTarget()
	local Attachment = self:GetTargetAttachment()

	if IsValid( Target ) and Attachment ~= "" then
		local ID = Target:LookupAttachment( Attachment )
		local Muzzle = Target:GetAttachment( ID )
		Pos = Muzzle.Pos
		Dir = Muzzle.Ang:Forward()
	end

	return Pos, Dir
end

local Grav = Vector(0,0,-600)
local Res = 0.05
function ENT:FindTargets()
	local Pos, Dir = self:GetPosition()

	local FlameVel = self:GetFlameVelocity()

	local Vel = Dir * FlameVel

	local trace
	local Dist = 0
	local MaxDist = FlameVel * self:GetFlameLifeTime()

	while Dist < MaxDist do
		Vel = Vel + Grav * Res

		local StartPos = Pos
		local EndPos = Pos + Vel * Res

		Dist = Dist + (StartPos - EndPos):Length()

		trace = util.TraceLine( {
			start = StartPos,
			endpos = EndPos,
			filter =  self,
		} )

		Pos = EndPos

		if trace.Hit then
			break
		end
	end

	return trace.HitPos
end

if SERVER then
	ENT.FlameStartSound = "lvs/weapons/flame_start.wav"
	ENT.FlameStopSound = "lvs/weapons/flame_end.wav"
	ENT.FlameLoopSound = "lvs/weapons/flame_loop.wav"

	function ENT:SetAttacker( ent ) self._attacker = ent end
	function ENT:GetAttacker() return self._attacker or NULL end

	function ENT:SetEntityFilter( filter )
		if not istable( filter ) then return end

		self._FilterEnts = {}

		for _, ent in pairs( filter ) do
			self._FilterEnts[ ent ] = true
		end
	end
	function ENT:GetEntityFilter()
		return self._FilterEnts or {}
	end

	function ENT:SetActiveDelay( num )
		self._activationdelay = num
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
		if self:GetActive() then return end

		self:SetActive( true )
		self:HandleActive()

		local effectdata = EffectData()
			effectdata:SetOrigin( self:LocalToWorld( self:OBBCenter() ) )
			effectdata:SetEntity( self )
			effectdata:SetMagnitude( self:GetActiveDelay() )
		util.Effect( "lvs_flamestream_start", effectdata )

		self:EmitSound( self.FlameStartSound )
	end

	function ENT:Disable()
		if not self:GetActive() then return end

		self:SetActive( false )
		self:HandleActive()

		local effectdata = EffectData()
			effectdata:SetOrigin( self:LocalToWorld( self:OBBCenter() ) )
			effectdata:SetEntity( self )
			effectdata:SetMagnitude( self:GetActiveDelay() )
		util.Effect( "lvs_flamestream_finish", effectdata )

		self:EmitSound( self.FlameStopSound )

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

			self._snd = self:StartLoopingSound( self.FlameLoopSound )
		end

		self:NextThink( T )
	end

	function ENT:HandleDamage()
		--for _, ent in ipairs( self:FindTargets() ) do
		--	ent:Ignite( 5 )
		--end
	end

	function ENT:Think()

		self:HandleActive()

		if self:GetActive() then
			self:HandleDamage()
		end

		return true
	end

	return
end

function ENT:Draw( flags )
end

function ENT:Think()
end
