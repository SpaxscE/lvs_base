
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
	bullet.HullSize 	= 10
	bullet.Damage	= 50
	bullet.Velocity = 32000
	bullet.Attacker 	= self:GetDriver()
	bullet.Callback = function(att, tr, dmginfo)
	end

	self:FireBullet( bullet )
end

function ENT:FireBullet( data )
	data.Entity = self
	data.Velocity = data.Velocity + self:GetVelocity():Length()
	data.SrcEntity = self:WorldToLocal( data.Src )

	LVS:FireBullet( data )
end