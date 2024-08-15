
GAME_GOAL_START = 0
GAME_GOAL_PICKUP = 1
GAME_GOAL_DROP = 2
GAME_GOAL_DELIVER = 3
GAME_GOAL_FINISH = 4

if CLIENT then
	local cVarVolume = CreateClientConVar( "lvs_volume_crowd", 0.2, true, false)

	function GM:PlayCrowdReaction( ent, team, start_inverted )
		local Me = LocalPlayer() 

		local MyTeam = Me:lvsGetAITeam()

		if MyTeam ~= 1 and MyTeam ~= 2 then return end

		local invert = team ~= MyTeam

		if not IsValid( ent ) then
			if invert then
				Me:EmitSound("lvs/tournament/crowd_artifactreveal.ogg", 140, math.Rand(95,105), cVarVolume:GetFloat() )
			else
				Me:EmitSound("lvs/tournament/crowd_positive"..math.random(1,2)..".ogg", 140, math.Rand(95,105), cVarVolume:GetFloat() )
			end

			return
		end

		local Volume = math.Clamp( 1 - (ent:GetPos() - Me:GetPos()):Length() / 2000,0, cVarVolume:GetFloat())

		if Volume <= 0.01 then return end

		if start_inverted then
			if invert then
				Me:EmitSound("lvs/tournament/crowd_positive"..math.random(1,2)..".ogg", 140, math.Rand(95,105), Volume )
			else
				Me:EmitSound("lvs/tournament/crowd_artifactreveal.ogg", 140, math.Rand(95,105), Volume )
			end
		else
			if invert then
				Me:EmitSound("lvs/tournament/crowd_artifactreveal.ogg", 140, math.Rand(95,105), Volume )
			else
				Me:EmitSound("lvs/tournament/crowd_positive"..math.random(1,2)..".ogg", 140, math.Rand(95,105), Volume )
			end
		end
	end

	function GM:OnPlayerPickupGoal( ply, team, ent )
		ent:EmitSound("lvs/tournament/bell_single.ogg", 140, math.Rand(95,105) )

		self:PlayCrowdReaction( ent, team )
	end

	function GM:OnPlayerDropGoal( ply, team, ent )
		ent:EmitSound("lvs/tournament/bell_double.ogg", 140, math.Rand(95,105) )

		self:PlayCrowdReaction( ent, team, true )
	end

	function GM:OnPlayerDeliverGoal( ply, team, ent )
		ent:EmitSound("lvs/tournament/bell_triple.ogg", 140, math.Rand(95,105) )

		self:PlayCrowdReaction( ent, team )
	end

	net.Receive( "lvs_goal_notify", function( len )
		local ply = net.ReadEntity()
		local team = net.ReadInt( 3 )
		local goaltype = net.ReadInt( 4 )
		local ent = GAMEMODE:GetGoalEntity()

		local me = LocalPlayer()

		if me:Team() == TEAM_SPECTATOR then return end

		if goaltype == GAME_GOAL_FINISH then
			me:EmitSound("lvs/tournament/bell_horn_finish.ogg", 140, math.Rand(95,105) )

			GAMEMODE:PlayCrowdReaction( NULL, team )

			return
		end

		if goaltype == GAME_GOAL_START then
			me:EmitSound("lvs/tournament/horn.ogg", 140, math.Rand(95,105) )

			return
		end

		if not IsValid( ent ) then return end

		if goaltype == GAME_GOAL_PICKUP then
			GAMEMODE:OnPlayerPickupGoal( ply, team, ent )

			return
		end

		if goaltype == GAME_GOAL_DROP then
			GAMEMODE:OnPlayerDropGoal( ply, team, ent )

			return
		end

		if goaltype == GAME_GOAL_DELIVER then
			GAMEMODE:OnPlayerDeliverGoal( ply, team, ent )

			return
		end
	end )

	return
end

util.AddNetworkString( "lvs_goal_notify" )

function GM:OnPlayerPickupGoal( ply, team, ent )
	net.Start( "lvs_goal_notify" )
		net.WriteEntity( ply )
		net.WriteInt( team, 3 )
		net.WriteInt( GAME_GOAL_PICKUP, 4 )
	net.Broadcast()

	ply:AddMoney( self.MoneyPerGoal )
end

function GM:OnPlayerDropGoal( ply, team, ent )
	net.Start( "lvs_goal_notify" )
		net.WriteEntity( ply )
		net.WriteInt( team, 3 )
		net.WriteInt( GAME_GOAL_DROP, 4 )
	net.Broadcast()

	ply:AddMoney( self.MoneyPerGoalDrop )
end

function GM:OnPlayerDeliverGoal( ply, target, goal )
	net.Start( "lvs_goal_notify" )
		net.WriteEntity( ply )
		net.WriteInt( goal:GetAITEAM(), 3 )
		net.WriteInt( GAME_GOAL_DELIVER, 4 )
	net.Broadcast()

	ply:AddMoney( self.MoneyPerGoalDelivered )
end

function GM:OnTeamFinishedGoal( team )
	net.Start( "lvs_goal_notify" )
		net.WriteEntity( NULL )
		net.WriteInt( team, 3 )
		net.WriteInt( GAME_GOAL_FINISH, 4 )
	net.Broadcast()
end

function GM:NotifyMatchStart()
	net.Start( "lvs_goal_notify" )
		net.WriteEntity( NULL )
		net.WriteInt( 0, 3 )
		net.WriteInt( GAME_GOAL_START, 4 )
	net.Broadcast()
end
