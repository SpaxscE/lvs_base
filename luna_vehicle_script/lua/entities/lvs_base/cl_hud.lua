
function ENT:LVSHudPaint( X, Y, ply )
end

function ENT:HitMarker( LastHitMarker, CriticalHit )
	self.LastHitMarker = LastHitMarker
	self.LastHitMarkerIsCrit = CriticalHit

	LocalPlayer():EmitSound( CriticalHit and "lvs/hit_crit.wav" or "lvs/hit.wav", 140, math.random(95,105), 1, CHAN_ITEM2 )
end

function ENT:GetHitMarker()
	return self.LastHitMarker or 0, self.LastHitMarkerIsCrit
end

function ENT:KillMarker( LastKillMarker )
	self.LastKillMarker = LastKillMarker
end

function ENT:GetKillMarker()
	return self.LastKillMarker or 0
end