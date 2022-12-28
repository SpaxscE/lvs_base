
net.Receive( "lvs_vehicle_destroy", function( len )
	local ent = net.ReadEntity()

	if not IsValid( ent ) then return end

	ent:StartDeathSound()
end )

function ENT:StartDeathSound()
	if not self.DeathSound then return end

	local snd = CreateSound( self, self.DeathSound )
	snd:SetSoundLevel( 120 )
	snd:PlayEx( 1, 50 + 50 * self:CalcDoppler( LocalPlayer() ) )

	LVS.DeathSounds[ self:EntIndex() ] = snd
end

function ENT:StopDeathSound()
	local ply = LocalPlayer():GetViewEntity()

	if not IsValid( ply ) then return end

	local ID = self:EntIndex()

	if not LVS.DeathSounds[ ID ] then return end

	local delay = (self:GetPos() - ply:GetPos()):Length() / 13503.9

	timer.Simple( delay, function()
		LVS.DeathSounds[ ID ]:Stop()
		LVS.DeathSounds[ ID ] = nil
	end )
end

