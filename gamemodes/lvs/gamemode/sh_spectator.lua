
hook.Add( "StartCommand", "lvs_kill_spectator", function( ply, cmd )
	if ply:Team() ~= TEAM_SPECTATOR then return end

	cmd:RemoveKey( IN_ATTACK )
	cmd:RemoveKey( IN_ATTACK2 )
	cmd:RemoveKey( IN_RELOAD )
	cmd:RemoveKey( IN_USE )
	cmd:RemoveKey( IN_RUN )
	cmd:RemoveKey( IN_ALT1 )
	cmd:RemoveKey( IN_ALT2 )
	cmd:RemoveKey( IN_WEAPON1 )
	cmd:RemoveKey( IN_WEAPON2 )
	cmd:RemoveKey( IN_BULLRUSH )
	cmd:RemoveKey( IN_GRENADE1 )
	cmd:RemoveKey( IN_GRENADE2 )
	cmd:RemoveKey( IN_USE )
end )