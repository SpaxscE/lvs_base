AddCSLuaFile()

DEFINE_BASECLASS( "base_wire_entity" )

ENT.PrintName		= "Projectile Turret"
ENT.WireDebugName = "Projectile Turret"

ENT.Author		= "Blu-x92"
ENT.Information		= "Projectile Turret"
ENT.Category		= "[LVS]"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false

ENT.Editable = true

ENT.TracerOptions = {
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

ENT.SplashTypeOptions = {
	Shrapnel = "lvs_bullet_impact",
	Explosive = "lvs_bullet_impact_explosive"
}

function ENT:SetupDataTables()
	local TracerOptions = {}

	for id, name in pairs( self.TracerOptions ) do
		if not file.Exists( "effects/"..name..".lua", "LUA" ) then continue end

		TracerOptions[ id ] = name
	end

	self:NetworkVar( "Float",1, "ShootDelay", { KeyName = "Shoot Delay", Edit = { type = "Float", order = 1,min = 0, max = 2, category = "Options"} } )
	self:NetworkVar( "Float",2, "Damage", { KeyName = "Damage", Edit = { type = "Float", order = 2,min = 0, max = 1000, category = "Options"} } )
	self:NetworkVar( "Float",3, "Speed", { KeyName = "Speed", Edit = { type = "Float", order = 3,min = 10000, max = 100000, category = "Options"} } )
	self:NetworkVar( "Float",4, "Size", { KeyName = "Size", Edit = { type = "Float", order = 4,min = 0, max = 50, category = "Options"} } )
	self:NetworkVar( "Float",5, "Spread", { KeyName = "Spread", Edit = { type = "Float", order = 5,min = 0, max = 1, category = "Options"} } )
	self:NetworkVar( "Float",6, "Penetration", { KeyName = "Armor Penetration (mm)", Edit = { type = "Float", order = 6,min = 0, max = 500, category = "Options"} } )
	self:NetworkVar( "Float",7, "SplashDamage", { KeyName = "Splash Damage", Edit = { type = "Float", order = 7,min = 0, max = 1000, category = "Options"} } )
	self:NetworkVar( "Float",8, "SplashDamageRadius", { KeyName = "Splash Damage Radius", Edit = { type = "Float", order = 8,min = 0, max = 750, category = "Options"} } )

	self:NetworkVar( "String", 1, "SplashDamageType", { KeyName = "Splash Damage Type", Edit = { type = "Combo",	order = 9,values = self.SplashTypeOptions,category = "Options"} } )

	self:NetworkVar( "String", 2, "Tracer", { KeyName = "Tracer", Edit = { type = "Combo",	order = 10,values = TracerOptions,category = "Options"} } )

	if SERVER then
		self:SetShootDelay( 0.05 )
		self:SetSpeed( 30000 )
		self:SetDamage( 15 )
		self:SetTracer( "lvs_tracer_orange" )
		self:SetSplashDamageType( "lvs_bullet_impact" )
	end
end

if CLIENT then
	function ENT:GetCrosshairFilterEnts()
		if not istable( self.CrosshairFilterEnts ) then
			self.CrosshairFilterEnts = {self}

			-- lets ask the server to build the filter for us because it has access to constraint.GetAllConstrainedEntities() 
			net.Start( "lvs_player_request_filter" )
				net.WriteEntity( self )
			net.SendToServer()
		end

		return self.CrosshairFilterEnts
	end

	return
end

function ENT:GetCrosshairFilterEnts()
	if not istable( self.CrosshairFilterEnts ) then
		self.CrosshairFilterEnts = {}

		for _, Entity in pairs( constraint.GetAllConstrainedEntities( self ) ) do
			if not IsValid( Entity ) then continue end

			table.insert( self.CrosshairFilterEnts , Entity )
		end

		for _, Parent in pairs( self.CrosshairFilterEnts ) do
			for _, Child in pairs( Parent:GetChildren() ) do
				if not IsValid( Child ) then continue end

				table.insert( self.CrosshairFilterEnts , Child )
			end
		end
	end

	return self.CrosshairFilterEnts
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if not tr.Hit then return end

	local ent = ents.Create( ClassName )
	ent.Attacker = ply
	ent:SetPos( tr.HitPos + tr.HitNormal * 5 )
	ent:Spawn()
	ent:Activate()

	return ent

end

function ENT:TriggerInput( name, value )
	if name == "Fire" then
		self.TriggerFire = value >= 1
	end
end

function ENT:Initialize()	
	self:SetModel( "models/props_junk/PopCan01a.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetCollisionGroup( COLLISION_GROUP_WEAPON  ) 
	
	self:PhysWake()
	
	self.Inputs = WireLib.CreateInputs( self,{"Fire"} )
end

function ENT:SetNextShoot( time )
	self.NextShoot = time
end

function ENT:CanShoot()
	if not self.TriggerFire then return false end
	
	self.NextShoot = self.NextShoot or 0
	
	return self.NextShoot < CurTime()
end

local IsCannon = {
	["lvs_tracer_autocannon"] = 0.25,
	["lvs_tracer_cannon"] = 1,
}

function ENT:Shoot()
	if not self:CanShoot() then return end

	local Tracer = self:GetTracer()

	local bullet = {}
	bullet.Src 	= self:GetPos()
	bullet.Dir 	= self:GetUp()
	bullet.Spread 	= Vector(self:GetSpread(),self:GetSpread(),self:GetSpread())
	bullet.TracerName = Tracer
	bullet.Force	= self:GetPenetration() * 100
	bullet.HullSize 	= self:GetSize()
	bullet.Damage	= self:GetDamage()
	bullet.Velocity = self:GetVelocity():Length() + self:GetSpeed()

	if IsCannon[ Tracer ] then
		self:SetShootDelay( math.max( self:GetShootDelay(), IsCannon[ Tracer ] ) )
	end

	local SplashDamage = self:GetSplashDamage()
	local SplashDamageRadius = self:GetSplashDamageRadius()

	if SplashDamage ~= 0 and SplashDamageRadius ~= 0 then
		bullet.SplashDamage = SplashDamage
		bullet.SplashDamageRadius = SplashDamageRadius

		local SplashEffect = self:GetSplashDamageType()
		local BlastDamage = SplashEffect == "lvs_bullet_impact_explosive"

		bullet.SplashDamageEffect = SplashEffect
		bullet.SplashDamageType = BlastDamage and DMG_BLAST or DMG_SONIC

		if BlastDamage then
			self:SetShootDelay( math.max( self:GetShootDelay(), 0.5 ) )
		end
	end

	bullet.Attacker = IsValid( self.Attacker ) and self.Attacker or self

	bullet.Entity = self
	bullet.SrcEntity = vector_origin

	LVS:FireBullet( bullet )

	self:SetNextShoot( CurTime() + self:GetShootDelay() )
end

function ENT:Think()	

	self.BaseClass.Think( self )
	
	self:Shoot()

	self:NextThink( CurTime() )
	
	return true
end