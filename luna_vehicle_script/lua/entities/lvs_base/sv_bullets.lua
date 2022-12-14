
function ENT:FireBullet( data )
	data.Entity = self
	data.Velocity = data.Velocity + self:GetVelocity():Length()
	data.SrcEntity = self:WorldToLocal( data.Src )

	LVS:FireBullet( data )
end