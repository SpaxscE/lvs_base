AddCSLuaFile()

ENT.Base = "lvs_protontorpedo"

ENT.Type            = "anim"

ENT.PrintName = "Concussion Missile"
ENT.Author = "Luna"
ENT.Information = "sprengt dir ein zweites arschloch"
ENT.Category = "[LVS]"

ENT.Spawnable		= true
ENT.AdminOnly		= true

ENT.ExplosionEffect = "lvs_concussion_explosion"
ENT.GlowColor = Color( 255, 40, 100, 255 )

if SERVER then
	function ENT:GetDamage() return
		(self._dmg or 400)
	end

	function ENT:GetRadius() 
		return (self._radius or 150)
	end

	return
end

ENT.GlowMat = Material( "sprites/light_glow02_add" )

function ENT:Enable()	
	if self.IsEnabled then return end

	self.IsEnabled = true

	self.snd = CreateSound(self, "npc/combine_gunship/gunship_crashing1.wav")
	self.snd:SetSoundLevel( 80 )
	self.snd:Play()

	local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetEntity( self )
	util.Effect( "lvs_concussion_trail", effectdata )
end

function ENT:Draw()
	if not self:GetActive() then return end

	self:DrawModel()

	render.SetMaterial( self.GlowMat )

	local pos = self:GetPos()
	local dir = self:GetForward()

	for i = 0, 30 do
		local Size = ((30 - i) / 30) ^ 2 * 128

		render.DrawSprite( pos - dir * i * 7, Size, Size, self.GlowColor )
	end
end