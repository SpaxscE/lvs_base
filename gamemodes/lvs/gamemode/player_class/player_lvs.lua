
AddCSLuaFile()

DEFINE_BASECLASS( "player_default" )

local PLAYER = {}

PLAYER.SlowWalkSpeed		= 75
PLAYER.WalkSpeed 			= 150
PLAYER.RunSpeed			= 300

PLAYER.CrouchedWalkSpeed	= 0.3		-- Multiply move speed by this when crouching

PLAYER.DuckSpeed			= 0.1		-- How fast to go from not ducking, to ducking
PLAYER.UnDuckSpeed			= 0.1		-- How fast to go from ducking, to not ducking

PLAYER.JumpPower			= 200		-- How powerful our jump should be
PLAYER.CanUseFlashlight		= true		-- Can we use the flashlight
PLAYER.MaxHealth			= 100		-- Max health we can have
PLAYER.MaxArmor				= 100		-- Max armor we can have
PLAYER.StartHealth			= 100		-- How much health we start with
PLAYER.StartArmor			= 100			-- How much armour we start with
PLAYER.DropWeaponOnDie		= false		-- Do we drop our weapon when we die
PLAYER.TeammateNoCollide	= true		-- Do we collide with teammates or run straight through them
PLAYER.AvoidPlayers			= true		-- Automatically swerves around other players
PLAYER.UseVMHands			= true		-- Uses viewmodel hands

PLAYER.TauntCam = TauntCamera()

function PLAYER:SetupDataTables()

	BaseClass.SetupDataTables( self )

end

function PLAYER:Loadout()

	local GameState = GAMEMODE:GetGameState()

	self.Player:RemoveAllAmmo()

	if GameState ~= GAMESTATE_BUILD then
		if not hook.Run( "LVS.PlayerLoadoutWeapons", self.Player ) and GetConVar( "lvs_weapons" ):GetBool() then
			self.Player:GiveAmmo( 40, "SniperRound", true )

			self.Player:Give( "weapon_lvslasergun" )
			self.Player:Give( "weapon_lvsantitankgun" )
			self.Player:Give( "weapon_lvsmines" )
		end
	end

	self.Player:Give( "weapon_lvsspawnpoint" )

	if not hook.Run( "LVS.PlayerLoadoutTools", self.Player ) then
		if GameState ~= GAMESTATE_WAIT_FOR_PLAYERS then
			if GameState <= GAMESTATE_BUILD then
				self.Player:Give( "weapon_lvsfortifications" )
			end

			if GameState > GAMESTATE_START then
				self.Player:Give( "weapon_lvsvehicles" )
				self.Player:Give( "weapon_lvsweldingtorch" )
			end
		else
			self.Player:Give( "weapon_lvsvehicles" )
			self.Player:Give( "weapon_lvsweldingtorch" )
		end
	end

	self.Player:SwitchToDefaultWeapon()

end

function PLAYER:ShouldDrawLocal()

	if ( self.TauntCam:ShouldDrawLocalPlayer( self.Player, self.Player:IsPlayingTaunt() ) ) then return true end

end

function PLAYER:CreateMove( cmd )

	if ( self.TauntCam:CreateMove( cmd, self.Player, self.Player:IsPlayingTaunt() ) ) then return true end

end

function PLAYER:CalcView( view )

	if ( self.TauntCam:CalcView( view, self.Player, self.Player:IsPlayingTaunt() ) ) then return true end

	-- Your stuff here

end

function PLAYER:StartMove( move )
end

function PLAYER:FinishMove( move )
end

player_manager.RegisterClass( "player_lvs", PLAYER, "player_default" )
