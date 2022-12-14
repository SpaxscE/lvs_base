
function ENT:SetNextPrimary( delay )
	self.NextPrimary = CurTime() + delay
end

function ENT:CanPrimaryAttack()
	self.NextPrimary = self.NextPrimary or 0
	return self.NextPrimary < CurTime()
end

function ENT:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	self:SetNextPrimary( 0.1 )
	
	self.MirrorPrimary = not self.MirrorPrimary

	local Mirror = self.MirrorPrimary and -1 or 1

	self:EmitSound("test.wav",75,100 + math.Rand(-5,5),1,CHAN_WEAPON)

	local bullet = {}
	bullet.Num 	= 1
	bullet.Src 	= self:LocalToWorld( Vector(109.29,7.13 * Mirror,92.85) )
	bullet.Dir 	= self:GetForward()
	bullet.Spread 	= Vector( 0.015,  0.015, 0 )
	bullet.TracerName = "lvs_bullet_base"
	bullet.Force	= 10
	bullet.HullSize 	= 5
	bullet.Damage	= 10
	bullet.Velocity = 25000
	bullet.Attacker 	= self:GetDriver()
	bullet.Callback = function(att, tr, dmginfo)
		local effectdata = EffectData()
		effectdata:SetOrigin( tr.HitPos )
		util.Effect( "lvs_bullet_hit", effectdata )
	end

	self:FireBullet( bullet )
end
