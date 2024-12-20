AddCSLuaFile()

ENT.Type            = "anim"

ENT.RenderGroup = RENDERGROUP_BOTH 

ENT.LifeTime = 15

if SERVER then
	local CountTotal = {}

	function ENT:Initialize()
		CountTotal[ self:EntIndex() ] = true

		local Num = table.Count( CountTotal )

		if (Num > 30 and math.random(1,2) == 1) or Num > 60 then
			self:Remove()

			return
		end

		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )
		self.DieTime = CurTime() + self.LifeTime
	end

	function ENT:OnRemove()
		CountTotal[ self:EntIndex() ] = nil
	end

	function ENT:Think()
		self:NextThink( CurTime() + 0.1 )

		if not IsValid( self:GetParent() ) then self:Remove() return end

		if (self.DieTime or 0) > CurTime() then return true end

		self:Remove()

		return false
	end

	return
end

ENT.GlowMat1 = Material( "particle/particle_ring_wave_8" )
ENT.GlowMat2 = Material( "sprites/light_glow02_add" )
ENT.DecalMat = Material( "particle/particle_noisesphere" )
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

local CountTotal = {}

function ENT:Initialize()
	CountTotal[ self:EntIndex() ] = true

	self.RandomAng = math.random(0,360)
	self.DieTime = CurTime() + self.LifeTime

	local Pos = self:GetPos()
	local Dir = self:GetUp()

	self.emitter = ParticleEmitter( Pos, false )

	self:EmitSound( "lvs/armor_pen_"..math.random(1,3)..".wav", 95 )
end

function ENT:Smoke()
	local T = CurTime()

	if (self.DieTime or 0) < T then return end

	if not IsValid( self.emitter ) then return end

	if (self.NextFX or 0) < T then
		self.NextFX = T + 0.2 + table.Count( CountTotal ) / 50

		local particle = self.emitter:Add( self.MatSmoke[math.random(1,#self.MatSmoke)], self:GetPos() )

		if particle then
			particle:SetVelocity( self:GetUp() * 60 + VectorRand() * 30 )
			particle:SetDieTime( math.Rand(1.5,2) )
			particle:SetAirResistance( 100 ) 
			particle:SetStartAlpha( 30 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 0 )
			particle:SetEndSize( 60 )
			particle:SetRollDelta( math.Rand( -1, 1 ) )
			particle:SetColor( 50,50,50 )
			particle:SetGravity( Vector( 0, 0, 200 ) )
			particle:SetCollide( false )
		end
	end
end

function ENT:Think()
	self:Smoke()
end

function ENT:OnRemove()
	CountTotal[ self:EntIndex() ] = nil

	if not IsValid(self.emitter) then return end

	self.emitter:Finish()
end

function ENT:Draw()
	local Timed = 1 - (self.DieTime - CurTime()) / self.LifeTime
	local Scale = math.max(math.min(2 - Timed * 2,1),0)

	local Scale02 = math.max(Scale - 0.8,0) / 0.2

	cam.Start3D2D( self:GetPos() + self:GetAngles():Up(), self:GetAngles(), 1 )
		surface.SetDrawColor( 255 * Scale02, (93 + 50 * Scale) * Scale02, (50 * Scale) * Scale02, (200 * Scale) * Scale02 )

		surface.SetMaterial( self.GlowMat1 )
		surface.DrawTexturedRectRotated( 0, 0, 8 , 8 , self.RandomAng )

		surface.SetMaterial( self.GlowMat2 )
		surface.DrawTexturedRectRotated( 0, 0, 16 , 16 , self.RandomAng )

		surface.SetDrawColor( 0, 0, 0, 255 )
		surface.SetMaterial( self.DecalMat )
		surface.DrawTexturedRectRotated( 0, 0, 16 , 16 , self.RandomAng )
	cam.End3D2D()
end

function ENT:DrawTranslucent()
	self:Draw()
end
