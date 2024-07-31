TOOL.Category		= "LVS"
TOOL.Name		= "#tool.lvsturret.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

cleanup.Register( "lvsturret" )
CreateConVar("sbox_maxlvsturret", 1, "FCVAR_NOTIFY")

TOOL.ClientConVar[ "delay" ] 		= "0.05"
TOOL.ClientConVar[ "damage" ] 		= "15"
TOOL.ClientConVar[ "speed" ] 		= "30000"
TOOL.ClientConVar[ "size" ] 		= "1"
TOOL.ClientConVar[ "spread" ] 		= "0"
TOOL.ClientConVar[ "penetration" ] 	= "10"
TOOL.ClientConVar[ "splashdamage" ] = "0"
TOOL.ClientConVar[ "splashradius" ] 	= "0"
TOOL.ClientConVar[ "tracer" ] 		= "lvs_tracer_orange"
TOOL.ClientConVar[ "splasheffect" ] 	= "lvs_bullet_impact"

if CLIENT then
	language.Add( "tool.lvsturret.name", "Projectile Turret" )
	language.Add( "tool.lvsturret.desc", "A Tool used to spawn Turrets" )
	language.Add( "tool.lvsturret.0", "Left click to spawn or update a turret" )
	language.Add( "tool.lvsturret.1", "Left click to spawn or update a turret" )
	
	language.Add( "Cleanup_lvsturret", "[LVS] Projectile Turret" )
	language.Add( "Cleaned_lvsturret", "Cleaned up all [LVS] Projectile Turrets" )

	language.Add( "SBoxLimit_lvsturret", "You've reached the Projectile Turret limit!" )
end

function TOOL:LeftClick( trace )

	if CLIENT then return true end
	
	local ply = self:GetOwner()

	if not istable( WireLib ) then
		ply:PrintMessage( HUD_PRINTTALK, "[LVS]: WIREMOD REQUIRED" )
		ply:SendLua( "gui.OpenURL( 'https://steamcommunity.com/sharedfiles/filedetails/?id=160250458' )") 
	end
	
	if IsValid( trace.Entity ) and trace.Entity:GetClass():lower() == "lvs_turret" then 
		self:UpdateTurret( trace.Entity )
	else
		local turret = self:MakeTurret( ply, trace.HitPos + trace.HitNormal * 5 )
		
		undo.Create("Turret")
			undo.AddEntity( turret )
			undo.SetPlayer( ply )
		undo.Finish()
	end
	
	return true
end

function TOOL:RightClick( trace )
	return false
end

if SERVER then
	function TOOL:UpdateTurret( ent )
		if not IsValid( ent ) then return end

		ent:SetShootDelay( self:GetClientNumber( "delay" ) )
		ent:SetDamage( math.Clamp( self:GetClientNumber( "damage" ), 0, 1000 ) )
		ent:SetSpeed( math.Clamp( self:GetClientNumber( "speed" ), 10000, 100000 ) )
		ent:SetSize( math.Clamp( self:GetClientNumber( "size" ), 0, 50 ) )
		ent:SetSpread( math.Clamp( self:GetClientNumber( "spread" ), 0, 1 ) )
		ent:SetPenetration( math.Clamp( self:GetClientNumber( "penetration" ), 0, 500 ) )
		ent:SetSplashDamage( math.Clamp( self:GetClientNumber( "splashdamage" ), 0, 1000 ) )
		ent:SetSplashDamageRadius( math.Clamp( self:GetClientNumber( "splashradius" ), 0, 750 ) )
		ent:SetTracer( self:GetClientInfo( "tracer" ) )
		ent:SetSplashDamageType( self:GetClientInfo( "splasheffect" ) )
	end

	function TOOL:MakeTurret( ply, Pos, Ang )

		if not ply:CheckLimit( "lvsturret" ) then return NULL end

		local turret = ents.Create( "lvs_turret" )
		
		if not IsValid( turret )  then return NULL end

		turret:SetPos( Pos )
		turret:SetAngles( Angle(0,0,0) )
		turret:Spawn()

		turret.Attacker = ply

		self:UpdateTurret( turret )

		ply:AddCount( "lvsturret", turret )
		ply:AddCleanup( "lvsturret", turret )

		return turret
	end
end

local ConVarsDefault = TOOL:BuildConVarList()
function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl( "ComboBox", { MenuButton = 1, Folder = "lvs_turrets", Options = { [ "#preset.default" ] = ConVarsDefault }, CVars = table.GetKeys( ConVarsDefault ) } )

	CPanel:AddControl( "Header", { Text = "#tool.lvsturret.name", Description	= "#tool.lvsturret.desc" }  )

	local TracerEffect = {Label = "Tracer Effect", MenuButton = 0, Options={}, CVars = {}}
	local TracerOptions = {
		["LaserBlue"] = "lvs_laser_blue",
		["LaserRed"] = "lvs_laser_red",
		["LaserGreen"] = "lvs_laser_green",
		["TracerGreen"] = "lvs_tracer_green",
		["TracerOrange"] = "lvs_tracer_orange",
		["TracerWhite"] = "lvs_tracer_white",
		["TracerYellow"] = "lvs_tracer_yellow",
		["AutoCannon"] = "lvs_tracer_autocannon",
		["Cannon"] = "lvs_tracer_cannon",
	}
	for id, name in pairs( TracerOptions ) do
		if not file.Exists( "effects/"..name..".lua", "LUA" ) then continue end
		TracerEffect["Options"][id]	= { lvsturret_tracer = name }
	end
	CPanel:AddControl("ComboBox", TracerEffect )

	CPanel:AddControl( "Slider", { Label = "Shoot Delay", Type = "Float", Min = 0, Max = 2.0, Command = "lvsturret_delay" } )

	CPanel:AddControl( "Slider", { Label = "Damage", Type = "Float", Min = 0, Max = 1000, Command = "lvsturret_damage" } )

	CPanel:AddControl( "Slider", { Label = "Bullet Speed", Type = "Float", Min = 10000, Max = 100000, Command = "lvsturret_speed" } )

	CPanel:AddControl( "Slider", { Label = "Bullet Spread", Type = "Float", Min = 0, Max = 1, Command = "lvsturret_spread" } )

	CPanel:AddControl( "Slider", { Label = "Hull Size", Type = "Float", Min = 0, Max = 50, Command = "lvsturret_size" } )

	CPanel:AddControl( "Slider", { Label = "Armor Penetration (mm)", Type = "Float", Min = 0, Max = 500, Command = "lvsturret_penetration" } )

	CPanel:AddControl( "Slider", { Label = "Splash Damage", Type = "Float", Min = 0, Max = 1000, Command = "lvsturret_splashdamage" } )

	CPanel:AddControl( "Slider", { Label = "Splash Radius", Type = "Float", Min = 0, Max = 750, Command = "lvsturret_splashradius" } )

	local SplashType = {Label = "Splash Type", MenuButton = 0, Options={}, CVars = {}}
	SplashType["Options"][ "Shrapnel" ] = { lvsturret_splasheffect = "lvs_bullet_impact" }
	SplashType["Options"][ "Explosive" ] = { lvsturret_splasheffect =  "lvs_bullet_impact_explosive" }
	CPanel:AddControl("ComboBox", SplashType )
end
