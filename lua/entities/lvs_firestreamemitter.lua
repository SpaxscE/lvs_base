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

	local FlameSize = self:GetFlameSize() * 2
	local FlameVel = self:GetFlameVelocity()

	local Vel = Dir * FlameVel

	local trace
	local Dist = 0
	local MaxDist = FlameVel * self:GetFlameLifeTime()

	local targets = {}

	while Dist < MaxDist do
		Vel = Vel + Grav * Res

		local StartPos = Pos
		local EndPos = Pos + Vel * Res

		Dist = Dist + (StartPos - EndPos):Length()

		local FlameRadius = FlameSize * (Dist / MaxDist)
		local FlameHull = Vector( FlameRadius, FlameRadius, FlameRadius )

		local traceData = {
			start = StartPos,
			endpos = EndPos,
			mins = -FlameHull,
			maxs = FlameHull,
			filter =  self,
		}
		trace = util.TraceLine( traceData )

		--debugoverlay.Sphere( (StartPos + EndPos) * 0.5, FlameRadius, 0.05)

		Pos = EndPos

		local traceFilter = { self }

		for i = 1, 10 do
			traceData.filter = traceFilter

			local hullTrace = util.TraceHull( traceData )

			if not hullTrace.Hit or not IsValid( hullTrace.Entity ) then break end

			table.insert( traceFilter, hullTrace.Entity )

			targets[ hullTrace.Entity:EntIndex() ] = hullTrace.HitPos
		end

		if trace.Hit then
			if IsValid( trace.Entity ) then
				targets[ trace.Entity:EntIndex() ] = trace.HitPos
			end

			break
		end
	end

	return targets
end

if SERVER then
	ENT.FlameStartSound = "lvs/weapons/flame_start.wav"
	ENT.FlameStopSound = "lvs/weapons/flame_end.wav"
	ENT.FlameLoopSound = "lvs/weapons/flame_loop.wav"

	function ENT:SetDamage( num ) self._dmg = num end
	function ENT:SetAttacker( ent ) self._attacker = ent end

	function ENT:GetAttacker() return self._attacker or NULL end
	function ENT:GetDamage() return (self._dmg or 100) end

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
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )
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

	function ENT:SendDamage( victim, pos )
		if not IsValid( victim ) then return end

		local attacker = self:GetAttacker()

		local dmg = DamageInfo()
		dmg:SetDamage( self:GetDamage() * FrameTime() )
		dmg:SetAttacker( IsValid( attacker ) and attacker or game.GetWorld() )
		dmg:SetInflictor( self:GetTarget() )
		dmg:SetDamageType( DMG_BURN )
		dmg:SetDamagePosition( pos or vector_origin )
		victim:TakeDamageInfo( dmg )
	end

	function ENT:HandleDamage()
		for entid, pos in pairs( self:FindTargets() ) do
			self:SendDamage( Entity( entid ), pos )
		end
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
