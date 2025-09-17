AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "Fire"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.Spawnable		= false
ENT.AdminOnly		= false

ENT.RenderGroup = RENDERGROUP_BOTH 

function ENT:SetupDataTables()
	self:NetworkVar( "Entity", 0, "Emitter" )
	self:NetworkVar( "Float", 0, "LifeTime" )
	self:NetworkVar( "Float", 1, "DieTime" )

	if SERVER then
		self:SetLifeTime( math.Rand(8,12) )
	end
end

function ENT:GetSize()
	return math.min( (self:GetDieTime() - CurTime()) / self:GetLifeTime() * 10, 1) ^ 2
end

if SERVER then
	function ENT:SpawnFunction( ply, tr, ClassName )
		if not tr.Hit then return end

		local ent = ents.Create( ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal )
		ent:SetAngles( tr.HitNormal:Angle() + Angle(90,0,0) )
		ent:Spawn()
		ent:Activate()

		return ent
	end

	function ENT:SetDamage( num ) self._dmg = num end
	function ENT:SetAttacker( ent ) self._attacker = ent end

	function ENT:GetAttacker() return self._attacker or NULL end
	function ENT:GetDamage() return (self._dmg or 3) end

	function ENT:SendDamage( victim, pos )
		if not IsValid( victim ) then return end

		if victim:IsPlayer() and victim:InVehicle() and victim:GetCollisionGroup() ~= COLLISION_GROUP_PLAYER then return end

		local attacker = self:GetAttacker()

		local dmg = DamageInfo()
		dmg:SetDamage( self:GetDamage() )
		dmg:SetAttacker( IsValid( attacker ) and attacker or game.GetWorld() )
		dmg:SetInflictor( self )
		dmg:SetDamageType( DMG_BURN + DMG_PREVENT_PHYSICS_FORCE )
		dmg:SetDamagePosition( pos or vector_origin )
		victim:TakeDamageInfo( dmg )
	end

	function ENT:Initialize()
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )

		self:SetDieTime( CurTime() + self:GetLifeTime() )

		if self:WaterLevel() > 0 then self:Remove() end
	end

	function ENT:Think()
		local T = CurTime()

		self:NextThink( T )

		if T > self:GetDieTime() then
			self:Remove()
		end

		local EntTable = self:GetTable()

		if (EntTable._NextDamage or 0) < T then
			EntTable._NextDamage = T + 0.5

			local Size = self:GetSize()
			local startpos = self:LocalToWorld( Vector(0,0,1) )
			local endpos = self:LocalToWorld( Vector(0,0,Size * 120) )

			local maxs = Vector(80,80,0) * Size
			local mins = Vector(-80,-80,0) * Size

			local trace = util.TraceHull( {
				start = startpos,
				endpos = endpos,
				maxs = maxs,
				mins = mins,
				filter = self,
			} )

			if not trace.Hit or not IsValid( trace.Entity ) then return true end

			self:SendDamage( trace.Entity, trace.HitPos, 1 )
		end

		return true
	end

	function ENT:PhysicsCollide( data, physobj )
	end

	function ENT:OnRemove()
	end

	return
end

local GlowMat = Material( "sprites/light_glow02_add" )
local Materials = {
	"particle/smokesprites_0001",
	"particle/smokesprites_0002",
	"particle/smokesprites_0003",
	"particle/smokesprites_0004",
	"particle/smokesprites_0005",
	"particle/smokesprites_0006",
	"particle/smokesprites_0007",
	"particle/smokesprites_0008",
	"particle/smokesprites_0009",
	"particle/smokesprites_0010",
	"particle/smokesprites_0011",
	"particle/smokesprites_0012",
	"particle/smokesprites_0013",
	"particle/smokesprites_0014",
	"particle/smokesprites_0015",
	"particle/smokesprites_0016"
}

function ENT:Initialize()
	self.snd = CreateSound(self, "ambient/fire/fire_small_loop"..math.random(1,2)..".wav")
	self.snd:SetSoundLevel( 60 )
	self.snd:Play()
end

function ENT:Draw( flags )
end

function ENT:DrawTranslucent( flags )
	local Size = self:GetSize() * 200

	render.SetMaterial( GlowMat )
	render.DrawSprite( self:GetPos(), Size, Size, Color( 255, 150, 75, 255) )
end

function ENT:SoundStop()
	if self.snd then
		self.snd:Stop()
	end
end

function ENT:OnRemove()
	self:SoundStop()
	self:StopEmitter()
	self:StopEmitter3D()
end

function ENT:GetParticleEmitter( Pos )
	local EntTable = self:GetTable()

	local T = CurTime()

	if IsValid( EntTable.Emitter ) and (EntTable.EmitterTime or 0) > T then
		return EntTable.Emitter
	end

	self:StopEmitter()

	EntTable.Emitter = ParticleEmitter( Pos, false )
	EntTable.EmitterTime = T + 2

	return EntTable.Emitter
end

function ENT:EmitFire()
	local Pos = self:GetPos()
	local Dir = self:GetUp()

	local emitter = self:GetParticleEmitter( Pos )
	local emitter3D = self:GetParticleEmitter3D( Pos )

	if not IsValid( emitter ) or not IsValid( emitter3D ) then return end

	local particle = emitter3D:Add( "effects/lvs_base/flamelet"..math.random(1,5), Pos )

	local Size = self:GetSize()

	if particle then
		particle:SetStartSize( 20 * Size )
		particle:SetEndSize( 60 * Size )
		particle:SetDieTime( math.Rand(0.5,1) )
		particle:SetStartAlpha( 255 )
		particle:SetEndAlpha( 0 )
		particle:SetRollDelta( math.Rand(-2,2) )
		particle:SetAngles( Dir:Angle() )
	end

	local fparticle = emitter:Add( "effects/lvs_base/fire", Pos )
	if fparticle then
		fparticle:SetVelocity( (VectorRand() * 30 + Dir * 100) * Size )
		fparticle:SetDieTime( math.Rand(0.6,0.8) )
		fparticle:SetAirResistance( 0 ) 

		fparticle:SetStartAlpha( 255 )
		fparticle:SetEndAlpha( 255 )

		fparticle:SetStartSize( 40 * Size )
		fparticle:SetEndSize( 0 )

		fparticle:SetRollDelta( math.Rand(-2,2) )
		fparticle:SetColor( 255,255,255 )
		fparticle:SetGravity( Vector( 0, 0, 100 ) * Size )
		fparticle:SetCollide( false )
	end

	local fparticle = emitter:Add( "effects/lvs_base/flamelet"..math.random(1,5), Pos )
	if fparticle then
		fparticle:SetVelocity( VectorRand() * 25 * Size )
		fparticle:SetDieTime( math.Rand(0.4,0.8) )
		fparticle:SetStartAlpha( 150 )
		fparticle:SetEndAlpha( 0 )
		fparticle:SetStartSize( 0 )
		fparticle:SetEndSize( math.Rand(60,80) * Size )
		fparticle:SetColor( 255, 255, 255 )
		fparticle:SetGravity( Vector(0,0,100) * Size )
		fparticle:SetRollDelta( math.Rand(-2,2) )
		fparticle:SetAirResistance( 0 )
	end

	for i = 0, 6 do
		local eparticle = emitter:Add( "effects/fire_embers"..math.random(1,2), Pos )

		if not eparticle then continue end

		eparticle:SetVelocity( VectorRand() * 400 * Size )
		eparticle:SetDieTime( math.Rand(0.4,0.6) )
		eparticle:SetStartAlpha( 255 )
		eparticle:SetEndAlpha( 0 )
		eparticle:SetStartSize( 20 * Size )
		eparticle:SetEndSize( 0 )
		eparticle:SetColor( 255, 255, 255 )
		eparticle:SetGravity( Vector(0,0,600) * Size )
		eparticle:SetRollDelta( math.Rand(-8,8) )
		eparticle:SetAirResistance( 300 * Size )
	end

	if math.random(1,3) ~= 1 then return end

	local sparticle = emitter:Add( Materials[ math.random(1, #Materials ) ], Pos )
	if sparticle then
		sparticle:SetVelocity( Dir * 400 * Size )
		sparticle:SetDieTime( math.Rand(2,4) )
		sparticle:SetAirResistance( 500 ) 
		sparticle:SetStartAlpha( 125 )
		sparticle:SetStartSize( 0 )
		sparticle:SetEndSize( 200 * Size )
		sparticle:SetRoll( math.Rand(-3,3)  )
		sparticle:SetRollDelta( math.Rand(-1,1) )
		sparticle:SetColor( 0, 0, 0 )
		sparticle:SetGravity( Vector( 0, 0, 800 ) * Size )
		sparticle:SetCollide( false )
	end
end

function ENT:Think()
	self:EmitFire()

	self:SetNextClientThink( CurTime() + math.Rand(0.01,0.4) )

	return true
end

function ENT:GetParticleEmitter3D( Pos )
	local EntTable = self:GetTable()

	local T = CurTime()

	if IsValid( EntTable.Emitter3D ) and (EntTable.EmitterTime3D or 0) > T then
		return EntTable.Emitter3D
	end

	self:StopEmitter3D()

	EntTable.Emitter3D = ParticleEmitter( Pos, true )
	EntTable.EmitterTime3D = T + 2

	return EntTable.Emitter3D
end


function ENT:StopEmitter()
	if not IsValid( self.Emitter ) then return end

	self.Emitter:Finish()
end

function ENT:StopEmitter3D()
	if not IsValid( self.Emitter3D ) then return end

	self.Emitter3D:Finish()
end