AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "88mm Round"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS] - Cars - Items"

ENT.Spawnable		= false
ENT.AdminOnly		= false

ENT.LifeTime = 10

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/misc/88mm_projectile.mdl" )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:PhysicsInit( SOLID_VPHYSICS)

		self.DieTime = CurTime() + self.LifeTime

		self:SetCollisionGroup( COLLISION_GROUP_WORLD )
	end

	function ENT:Think()
		if self.MarkForRemove then self:Remove() return false end

		self:NextThink( CurTime() + 0.1 )

		if (self.DieTime or 0) > CurTime() then return true end

		self:Remove()

		return false
	end

	
	function ENT:PhysicsCollide( data, physobj )
		self.MarkForRemove = true

		local effectdata = EffectData()
		effectdata:SetOrigin( data.HitPos )
		effectdata:SetNormal( -data.HitNormal )
		effectdata:SetMagnitude( 0.5 )
		util.Effect( "lvs_bullet_impact", effectdata )
	end

	return
end

ENT.MatSmoke = {
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
	self.DieTime = CurTime() + self.LifeTime

	self.emitter = ParticleEmitter( self:GetPos(), false )
end

function ENT:Smoke()
	local T = CurTime()

	if (self.DieTime or 0) < T then return end

	if not IsValid( self.emitter ) then return end

	if (self.NextFX or 0) < T then
		self.NextFX = T + 0.02

		local Timed = 1 - (self.DieTime - T) / self.LifeTime
		local Scale = math.max(math.min(2 - Timed * 2,1),0)

		local Pos = self:GetPos() 

		local particle = self.emitter:Add( self.MatSmoke[math.random(1,#self.MatSmoke)], Pos )

		local VecCol = (render.GetLightColor( Pos ) * 0.8 + Vector(0.2,0.2,0.2)) * 255

		if particle then
			particle:SetVelocity( VectorRand() * 10 )
			particle:SetDieTime( math.Rand(0.5,1) )
			particle:SetAirResistance( 100 ) 
			particle:SetStartAlpha( 100 * Scale )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 10 )
			particle:SetEndSize( 20 )
			particle:SetRollDelta( 1 )
			particle:SetColor( VecCol.r, VecCol.g, VecCol.b )
			particle:SetGravity( Vector( 0, 0, 200 ) )
			particle:SetCollide( false )
		end
	end
end

function ENT:Think()
	self:Smoke()
end

function ENT:OnRemove()
	if not self.emitter then return end

	self.emitter:Finish()
end

function ENT:Draw()
	self:DrawModel()
end
