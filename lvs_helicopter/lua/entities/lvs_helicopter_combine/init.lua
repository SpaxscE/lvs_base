AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:OnSpawn( PObj )
	local DriverSeat = self:AddDriverSeat( Vector(120,0,-40), Angle(0,-90,0) )
	DriverSeat:SetCameraDistance( 0.2 )

	self:AddEngineSound( Vector(0,0,0) )

	self.Rotor = self:AddRotor( Vector(0,0,65), Angle(15,0,0), 310, -4000 )
	self.Rotor:SetHP( 50 )
	function self.Rotor:OnDestroyed( base )
		local ID = base:LookupBone( "Chopper.Rotor_Blur" )
		base:ManipulateBoneScale( ID, Vector(0,0,0) )

		base:DestroyEngine()

		self:EmitSound( "physics/metal/metal_box_break2.wav" )
	end

	self.TailRotor = self:AddRotor( Vector(-218,4,-1.8), Angle(0,0,90), 25, -6000 )
	self.TailRotor:SetHP( 25 )
	function self.TailRotor:OnDestroyed( base )
		base:DestroySteering( -2.5 )
		base:SnapTailRotor()

		self:EmitSound( "physics/metal/metal_box_break2.wav" )
	end

	self:AddDS( {
		pos = Vector(-218,4,-1.8),
		ang = Angle(0,0,0),
		mins = Vector(-25,-5,-25),
		maxs =  Vector(25,5,25),
		Callback = function( tbl, ent, dmginfo )
			if dmginfo:GetDamage() <= 0 then return end

			ent.TailRotor:TakeDamageInfo( dmginfo )
		end
	} )
end

function ENT:SnapTailRotor()
	if self.TailDestroyed then return end

	self.TailDestroyed = true

	local ent = ents.Create( "prop_physics" )
	ent:SetModel( "models/gibs/helicopter_brokenpiece_05_tailfan.mdl" )
	ent:SetPos( self:LocalToWorld( Vector(-153.476349,1.618453,3.479492) ) )
	ent:SetAngles( self:GetAngles() )
	ent:Spawn()
	ent:Activate()
	ent:SetRenderMode( RENDERMODE_TRANSALPHA )
	ent:SetCollisionGroup( COLLISION_GROUP_WORLD )

	self:DeleteOnRemove( ent )

	local PhysObj = ent:GetPhysicsObject()

	if not IsValid( PhysObj ) then return end

	PhysObj:SetVelocityInstantaneous( self:GetVelocity()  )
	PhysObj:AddAngleVelocity( VectorRand() * 500 ) 
	PhysObj:EnableDrag( false ) 

	local effectdata = EffectData()
		effectdata:SetOrigin( ent:GetPos() )
		effectdata:SetStart( PhysObj:GetMassCenter() )
		effectdata:SetEntity( ent )
		effectdata:SetScale( 0.1 )
		effectdata:SetMagnitude( math.Rand(0.5,2.5) )
	util.Effect( "lvs_firetrail", effectdata )

	local BonesToScale = {
		"Chopper.Tail",
		"Chopper.Blade_Tail",
	}

	for _, name in pairs( BonesToScale ) do
		local ID = self:LookupBone( name )
		self:ManipulateBoneScale( ID, Vector(0,0,0) )
	end
end

function ENT:GetMissileOffset()
	return Vector(-60,0,0)
end

function ENT:OnEngineActiveChanged( Active )
	if Active then
		self:EmitSound( "lvs/vehicles/helicopter/start.wav" )
	end
end