AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "sh_weapons.lua" )
AddCSLuaFile( "sh_velocity_changer.lua" )
AddCSLuaFile( "sh_variables.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_effects.lua" )
AddCSLuaFile( "cl_hud.lua" )
AddCSLuaFile( "cl_optics.lua" )
AddCSLuaFile( "cl_trailsystem.lua" )
AddCSLuaFile( "cl_seatswitcher.lua" )
AddCSLuaFile( "cl_boneposeparemeter.lua" )
include("shared.lua")
include("sh_weapons.lua")
include("sh_velocity_changer.lua")
include("sh_variables.lua")
include("sv_ai.lua")
include("sv_cppi.lua")
include("sv_duping.lua")
include("sv_pod.lua")
include("sv_engine.lua")
include("sv_physics.lua")
include("sv_physics_damagesystem.lua")
include("sv_damagesystem.lua")
include("sv_shieldsystem.lua")
include("sv_doorsystem.lua")

ENT.WaterLevelPreventStart = 1
ENT.WaterLevelAutoStop = 2
ENT.WaterLevelDestroyAI = 2

function ENT:SpawnFunction( ply, tr, ClassName )

	if ply:InVehicle() then
		local ent = ents.Create( ClassName )
		ent:StoreCPPI( ply )
		ent:SetPos( ply:GetPos() + Vector(0,0,100 + ent.SpawnNormalOffset) )
		ent:SetAngles( Angle(0, ply:EyeAngles().y, 0 ) )
		ent:Spawn()
		ent:Activate()

		return ent
	else
		if not tr.Hit then return end

		local ent = ents.Create( ClassName )
		ent:StoreCPPI( ply )
		ent:SetPos( tr.HitPos + tr.HitNormal * ent.SpawnNormalOffset )
		ent:SetAngles( Angle(0, ply:EyeAngles().y, 0 ) )
		ent:Spawn()
		ent:Activate()

		return ent
	end
end

function ENT:Initialize()
	self:SetModel( self.MDL )

	self:PhysicsInit( SOLID_VPHYSICS, self.MassCenterOverride )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	self:SetRenderMode( RENDERMODE_NORMAL )

	-- this is so vj npcs can still see us
	self:AddEFlags( EFL_DONTBLOCKLOS )

	-- this is for our npc relationship system to work
	self:AddFlags( FL_OBJECT )

	local PObj = self:GetPhysicsObject()

	if not IsValid( PObj ) then 
		self:Remove()

		print("LVS: missing model. Vehicle terminated.")

		return
	end

	PObj:SetMaterial( "default_silent" )
	PObj:EnableMotion( false )
	PObj:EnableDrag( false )

	timer.Simple(0, function()
		if not IsValid( self ) or not IsValid( PObj ) then print("LVS: ERROR couldn't initialize vehicle.") return end

		self:PostInitialize( PObj )
	end)

	if not istable( self.GibModels ) then return end

	for _, modelName in ipairs( self.GibModels ) do
		util.PrecacheModel( modelName )
	end
end

function ENT:PostInitialize( PObj )
	local SpawnSuccess, ErrorMsg = pcall( function() self:OnSpawn( PObj ) end )

	if not SpawnSuccess then
		ErrorNoHalt( "\n[ERROR] "..ErrorMsg.."\n\n" )
	end

	self:StartMotionController()

	self:AutoAI()

	self:CallOnRemove( "finish_weapons_on_delete", function( ent )
		ent:WeaponsFinish()

		for _, pod in pairs( ent:GetPassengerSeats() ) do
			if not IsValid( pod ) then continue end

			local weapon = pod:lvsGetWeapon()

			if not IsValid( weapon ) or not weapon._activeWeapon then continue end

			local CurWeapon = self.WEAPONS[ weapon:GetPodIndex() ][ weapon._activeWeapon ]

			if not CurWeapon then continue end

			if CurWeapon.FinishAttack then
				CurWeapon.FinishAttack( weapon )
			end
		end

		ent:WeaponsOnRemove()
	end)

	self:SetlvsReady( true )
	self:GetCrosshairFilterEnts()

	self:OnSpawnFinish( PObj )
end

function ENT:OnSpawnFinish( PObj )
	if GetConVar( "developer" ):GetInt() ~= 1 then
		PObj:EnableMotion( true )
	end

	self:PhysWake()
end

function ENT:OnSpawn( PObj )
end

function ENT:Think()
	self:NextThink( CurTime() )

	if not self:IsInitialized() then return true end

	self:HandleActive()
	self:HandleStart()
	self:PhysicsThink()
	self:DamageThink()
	self:WeaponsThink()
	self:ShieldThink()

	if self:GetAI() then self:RunAI() end

	self:OnTick()

	return true
end

function ENT:OnDriverChanged( Old, New, VehicleIsActive )
	self:OnPassengerChanged( Old, New, 1 )
end

function ENT:OnPassengerChanged( Old, New, PodIndex )
end

function ENT:OnSwitchSeat( ply, oldpod, newpod )
end

function ENT:OnTick()
end

function ENT:OnRemoved()
end

function ENT:OnRemove()
	self:OnRemoved()
end

function ENT:Lock()
	for _, Handler in pairs( self:GetDoorHandlers() ) do
		if not IsValid( Handler ) then continue end

		Handler:Close( ply )
	end

	if self:GetlvsLockedStatus() then return end

	self:SetlvsLockedStatus( true )
	self:EmitSound( "doors/latchlocked2.wav" )
end

function ENT:UnLock()
	if not self:GetlvsLockedStatus() then return end

	self:SetlvsLockedStatus( false )
	self:EmitSound( "doors/latchunlocked1.wav" )
end

function ENT:IsUseAllowed( ply )
	if not IsValid( ply ) then return false end

	if (ply._lvsNextUse or 0) > CurTime() then return false end

	if self:GetlvsLockedStatus() or (LVS.TeamPassenger and ((self:GetAITEAM() ~= ply:lvsGetAITeam()) and ply:lvsGetAITeam() ~= 0 and self:GetAITEAM() ~= 0)) then 
		self:EmitSound( "doors/default_locked.wav" )

		return false
	end

	return true
end

function ENT:Use( ply )
	if not self:IsUseAllowed( ply ) then return end

	if not istable( self._DoorHandlers ) then
		self:SetPassenger( ply )

		return
	end

	if ply:GetMoveType() == MOVETYPE_NOCLIP then
		ply._lvsNextExit = CurTime() + 0.5

		self:SetPassenger( ply )

		return
	end

	if ply:KeyDown( IN_SPEED ) then return end

	local Handler = self:GetDoorHandler( ply )

	if not IsValid( Handler ) then
		if self:HasDoorSystem() and ply:GetMoveType() == MOVETYPE_WALK then
			return
		end

		self:SetPassenger( ply )

		return
	end

	local Pod = Handler:GetLinkedSeat()

	if not IsValid( Pod ) then Handler:Use( ply ) return end

	if not Handler:IsOpen() then Handler:Open( ply ) return end

	if Handler:IsOpen() then
		Handler:Close( ply )
	else
		Handler:OpenAndClose( ply )
	end

	if ply:KeyDown( IN_WALK ) then

		self:SetPassenger( ply )

		return
	end

	local DriverSeat = self:GetDriverSeat()

	if Pod ~= self:GetDriverSeat() then
		if IsValid( Pod:GetDriver() ) then
			self:SetPassenger( ply )
		else
			ply:EnterVehicle( Pod )
			self:AlignView( ply )

			hook.Run( "LVS.UpdateRelationship", self )
		end

		return
	end

	if self:GetAI() then
		self:SetPassenger( ply )

		return
	end

	if IsValid( Pod:GetDriver() ) then
		self:SetPassenger( ply )

		return
	end

	if hook.Run( "LVS.CanPlayerDrive", ply, self ) ~= false then
		ply:EnterVehicle( Pod )
		self:AlignView( ply )

		hook.Run( "LVS.UpdateRelationship", self )
	else
		hook.Run( "LVS.OnPlayerCannotDrive", ply, self )
	end
end

function ENT:OnTakeDamage( dmginfo )
	self:CalcShieldDamage( dmginfo )
	self:CalcDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
	self:OnAITakeDamage( dmginfo )
	self:RemoveAllDecals()
end

function ENT:OnMaintenance()
end

function ENT:UpdateTransmitState() 
	return TRANSMIT_ALWAYS
end

function ENT:GetMissileOffset()
	return self:OBBCenter()
end

function ENT:RebuildCrosshairFilterEnts()
	self.CrosshairFilterEnts = nil

	local CrosshairFilterEnts = table.Copy( self:GetCrosshairFilterEnts() )

	for id, entity in pairs( CrosshairFilterEnts ) do
		if not IsValid( entity ) or entity:GetNoDraw() then
			CrosshairFilterEnts[ id ] = nil
		end
	end

	net.Start( "lvs_player_request_filter" )
		net.WriteEntity( self )
		net.WriteTable( CrosshairFilterEnts )
	net.Broadcast()
end

function ENT:GetCrosshairFilterEnts()
	if not self:IsInitialized() then return { self } end

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

function ENT:LVSFireBullet( data )
	data.Entity = self
	data.Velocity = data.Velocity + self:GetVelocity():Length()
	data.SrcEntity = self:WorldToLocal( data.Src )

	LVS:FireBullet( data )
end

function ENT:AddSoundEmitter( pos, snd, snd_interior )
	local Emitter = ents.Create( "lvs_soundemitter" )

	if not IsValid( Emitter ) then
		self:Remove()

		print("LVS: Failed to create sound emitter entity. Vehicle terminated.")

		return
	end

	Emitter:SetPos( self:LocalToWorld( pos ) )
	Emitter:SetAngles( self:GetAngles() )
	Emitter:Spawn()
	Emitter:Activate()
	Emitter:SetParent( self )
	Emitter:SetBase( self )

	if snd and not snd_interior then
		Emitter:SetSound( snd )
		Emitter:SetSoundInterior( snd )
	else
		Emitter:SetSound( snd or "" )
		Emitter:SetSoundInterior( snd_interior )
	end

	self:DeleteOnRemove( Emitter )

	self:TransferCPPI( Emitter )

	return Emitter
end

function ENT:AddFlameEmitter( target, attachment )
	if not IsValid( target ) then return end

	local FlameEmitter = ents.Create( "lvs_firestreamemitter" )
	FlameEmitter:AttachTo( target, attachment )
	FlameEmitter:Spawn()
	FlameEmitter:Activate()

	return FlameEmitter
end

function ENT:AddAmmoRack( pos, fxpos, ang, mins, maxs, target )
	local AmmoRack = ents.Create( "lvs_wheeldrive_ammorack" )

	if not IsValid( AmmoRack ) then
		self:Remove()

		print("LVS: Failed to create fueltank entity. Vehicle terminated.")

		return
	end

	if not target then target = self end

	AmmoRack:SetPos( target:LocalToWorld( pos ) )
	AmmoRack:SetAngles( target:GetAngles() )
	AmmoRack:Spawn()
	AmmoRack:Activate()
	AmmoRack:SetParent( target )
	AmmoRack:SetBase( self )
	AmmoRack:SetEffectPosition( fxpos )

	self:DeleteOnRemove( AmmoRack )

	self:TransferCPPI( AmmoRack )

	mins = mins or Vector(-30,-30,-30)
	maxs = maxs or Vector(30,30,30)

	debugoverlay.BoxAngles( target:LocalToWorld( pos ), mins, maxs, target:LocalToWorldAngles( ang ), 15, Color( 255, 0, 0, 255 ) )

	self:AddDS( {
		pos = pos,
		ang = ang,
		mins = mins,
		maxs =  maxs,
		entity = target,
		Callback = function( tbl, ent, dmginfo )
			if not IsValid( AmmoRack ) then return end

			AmmoRack:TakeTransmittedDamage( dmginfo )

			if AmmoRack:GetDestroyed() then return end

			local OriginalDamage = dmginfo:GetDamage()

			dmginfo:SetDamage( math.min( 2, OriginalDamage ) )
		end
	} )

	return AmmoRack
end

function ENT:AddTrailerHitch( pos, hitchtype )
	if not hitchtype then

		hitchtype = LVS.HITCHTYPE_MALE

	end

	local TrailerHitch = ents.Create( "lvs_wheeldrive_trailerhitch" )

	if not IsValid( TrailerHitch ) then
		self:Remove()

		print("LVS: Failed to create trailerhitch entity. Vehicle terminated.")

		return
	end

	TrailerHitch:SetPos( self:LocalToWorld( pos ) )
	TrailerHitch:SetAngles( self:GetAngles() )
	TrailerHitch:Spawn()
	TrailerHitch:Activate()
	TrailerHitch:SetParent( self )
	TrailerHitch:SetBase( self )
	TrailerHitch:SetHitchType( hitchtype )

	self:TransferCPPI( TrailerHitch )

	return TrailerHitch
end

function ENT:OnCoupleChanged( targetVehicle, targetHitch, active )
end

function ENT:OnStartDrag( caller, activator )
end

function ENT:OnStopDrag( caller, activator )
end
