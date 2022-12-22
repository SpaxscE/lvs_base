
function ENT:LVSHudPaint( X, Y, ply )
end

function ENT:HitMarker()
	self.LastHitMarker = CurTime() + 0.15

	LocalPlayer():EmitSound( "lvs/hit.wav", 85, math.random(95,105), 0.4, CHAN_ITEM2 )
end

function ENT:GetHitMarker()
	return self.LastHitMarker or 0
end

function ENT:KillMarker( LastKillMarker )
	self.LastKillMarker = CurTime() + 0.15
end

function ENT:GetKillMarker()
	return self.LastKillMarker or 0
end