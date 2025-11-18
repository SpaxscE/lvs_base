ENT.Type            = "anim"

ENT.PrintName = "LBaseEntity"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.VJ_ID_Destructible = true

ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_BOTH 

ENT.Editable = true

ENT.LVS = true

ENT.MDL = "models/props_c17/trappropeller_engine.mdl"

ENT.AITEAM = 0

ENT.MaxHealth = 100
ENT.MaxShield = 0

ENT.SpawnNormalOffset = 15
ENT.HitGroundLength = 10

ENT.lvsDisableZoom = true

function ENT:AddDT( type, name, data )
	if not self.DTlist then self.DTlist = {} end

	if self.DTlist[ type ] then
		self.DTlist[ type ] = self.DTlist[ type ] + 1
	else
		self.DTlist[ type ] = 0
	end

	self:NetworkVar( type, self.DTlist[ type ], name, data )
end

function ENT:CreateBaseDT()
	local InitWeaponsSuccess, ErrorMsg = pcall( function() self:InitWeapons() end )

	--prevent people from manually calling it in on onspawn
	self.InitWeapons = nil

	if not InitWeaponsSuccess then
		ErrorNoHalt( "\n[ERROR] "..ErrorMsg.."\n\n" )
	end

	self:AddDT( "Entity", "Driver" )
	self:AddDT( "Entity", "DriverSeat" )

	self:AddDT( "Bool", "Active" )
	self:AddDT( "Bool", "EngineActive" )
	self:AddDT( "Bool", "AI",	{ KeyName = "aicontrolled",	Edit = { type = "Boolean",	order = 1,	category = "AI"} } )

	local ShowAIGunnerInMenu = false

	if istable( self.WEAPONS ) then
		for id, _ in pairs( self.WEAPONS ) do
			if id == 1 then continue end

			ShowAIGunnerInMenu = true

			break
		end
	end

	if ShowAIGunnerInMenu then
		self:AddDT( "Bool", "AIGunners",	{ KeyName = "aigunners",	Edit = { type = "Boolean",	order = 2,	category = "AI"} } )
	else
		self:AddDT( "Bool", "AIGunners" )
	end

	self:AddDT( "Bool", "lvsLockedStatus" )
	self:AddDT( "Bool", "lvsReady" )
	self:AddDT( "Bool", "NWOverheated" )

	self:AddDT( "Int", "AITEAM", { KeyName = "aiteam", Edit = { type = "Int", order = 2,min = 0, max = 3, category = "AI"} } )
	self:AddDT( "Int", "SelectedWeapon" )
	self:AddDT( "Int", "NWAmmo" )

	self:AddDT( "Float", "HP", { KeyName = "health", Edit = { type = "Float", order = 2,min = 0, max = self.MaxHealth, category = "Misc"} } )
	self:AddDT( "Float", "Shield" )
	self:AddDT( "Float", "NWHeat" )

	self:TurretSystemDT()
	self:OnSetupDataTables()

	if SERVER then
		self:NetworkVarNotify( "AI", self.OnToggleAI )
		self:NetworkVarNotify( "HP", self.PDSHealthValueChanged )
		self:NetworkVarNotify( "SelectedWeapon", self.OnWeaponChanged )

		self:SetAITEAM( self.AITEAM )
		self:SetHP( self.MaxHealth )
		self:SetShield( self.MaxShield )
		self:SetSelectedWeapon( 1 )
	end
end

function ENT:TurretSystemDT()
end

function ENT:SetupDataTables()
	self:CreateBaseDT()
end

function ENT:OnSetupDataTables()
end

function ENT:CalcMainActivity( ply )
end

function ENT:GetPlayerBoneManipulation( ply, PodID )
	return self.PlayerBoneManipulate[ PodID ] or {}
end

function ENT:UpdateAnimation( ply, velocity, maxseqgroundspeed )
	ply:SetPlaybackRate( 1 )

	if CLIENT then
		GAMEMODE:GrabEarAnimation( ply )
		GAMEMODE:MouthMoveAnimation( ply )
	end

	return false
end

function ENT:StartCommand( ply, cmd )
end

function ENT:HitGround()
	local trace = util.TraceLine( {
		start = self:LocalToWorld( self:OBBCenter() ),
		endpos = self:LocalToWorld( Vector(0,0,self:OBBMins().z - self.HitGroundLength) ),
		filter = self:GetCrosshairFilterEnts()
	} )
	
	return trace.Hit 
end

function ENT:Sign( n )
	if n > 0 then return 1 end

	if n < 0 then return -1 end

	return 0
end

function ENT:VectorSubtractNormal( Normal, Velocity )
	local VelForward = Velocity:GetNormalized()

	local Ax = math.acos( math.Clamp( Normal:Dot( VelForward ) ,-1,1) )

	local Fx = math.cos( Ax ) * Velocity:Length()

	local NewVelocity = Velocity - Normal * math.abs( Fx )

	return NewVelocity
end

function ENT:VectorSplitNormal( Normal, Velocity )
	return math.cos( math.acos( math.Clamp( Normal:Dot( Velocity:GetNormalized() ) ,-1,1) ) ) * Velocity:Length()
end

function ENT:AngleBetweenNormal( Dir1, Dir2 )
	return math.deg( math.acos( math.Clamp( Dir1:Dot( Dir2 ) ,-1,1) ) )
end

function ENT:GetMaxShield()
	return self.MaxShield
end

function ENT:GetShieldPercent()
	return self:GetShield() / self:GetMaxShield()
end

function ENT:GetMaxHP()
	return self.MaxHealth
end

function ENT:IsInitialized()
	if not self.GetlvsReady then return false end -- in case this is called BEFORE setupdatatables

	return self:GetlvsReady()
end

function ENT:GetWeaponHandler( num )
	if num == 1 then return self end

	local pod = self:GetPassengerSeat( num )

	if not IsValid( pod ) then return NULL end

	return pod:lvsGetWeapon()
end

function ENT:GetPassengerSeat( num )
	if num == 1 then
		return self:GetDriverSeat()
	else
		for _, Pod in pairs( self:GetPassengerSeats() ) do

			if not IsValid( Pod ) then continue end

			local id = Pod:lvsGetPodIndex()

			if id == -1 then continue end

			if id == num then
				return Pod
			end
		end

		return NULL
	end
end

function ENT:GetPassengerSeats()
	if not self:IsInitialized() then return {} end

	if not istable( self.pSeats ) then
		self.pSeats = {}

		local DriverSeat = self:GetDriverSeat()

		for _, v in pairs( self:GetChildren() ) do
			if v ~= DriverSeat and v:GetClass():lower() == "prop_vehicle_prisoner_pod" then
				table.insert( self.pSeats, v )
			end
		end
	end

	return self.pSeats
end

function ENT:HasActiveSoundEmitters()
	local active = false

	for _, emitter in ipairs( self:GetChildren() ) do
		if emitter:GetClass() ~= "lvs_soundemitter" then continue end

		if not IsValid( emitter ) or not emitter.GetActive or not emitter.GetActiveVisible then continue end

		if emitter:GetActive() and emitter:GetActiveVisible() then
			active = true

			break
		end
	end

	return active
end

function ENT:GetPassenger( num )
	if num == 1 then
		return self:GetDriver()
	else
		for _, Pod in pairs( self:GetPassengerSeats() ) do

			if not IsValid( Pod ) then
				return NULL
			end

			local id = Pod:lvsGetPodIndex()

			if id == -1 then continue end

			if id == num then
				return Pod:GetDriver()
			end
		end

		return NULL
	end
end

function ENT:GetEveryone()
	local plys = {}

	local Pilot = self:GetDriver()
	if IsValid( Pilot ) then
		table.insert( plys, Pilot )
	end

	for _, Pod in pairs( self:GetPassengerSeats() ) do
		if not IsValid( Pod ) then continue end

		local ply = Pod:GetDriver()

		if not IsValid( ply ) then continue end

		table.insert( plys, ply )
	end

	return plys
end

function ENT:GetPodIndex()
	return 1
end

function ENT:PlayAnimation( animation, playbackrate )
	playbackrate = playbackrate or 1

	local sequence = self:LookupSequence( animation )

	self:ResetSequence( sequence )
	self:SetPlaybackRate( playbackrate )
	self:SetSequence( sequence )
end

function ENT:GetVehicle()
	return self
end

function ENT:GetVehicleType()
	return "LBaseEntity"
end

function ENT:GetBoneInfo( BoneName )
	local BoneID = self:LookupBone( BoneName )
	local numHitBoxSets = self:GetHitboxSetCount()

	if not BoneID then
		goto SkipLoop
	end

	for hboxset = 0, numHitBoxSets - 1 do
		local numHitBoxes = self:GetHitBoxCount( hboxset )

		for hitbox=0, numHitBoxes - 1 do
			local bone = self:GetHitBoxBone( hitbox, hboxset )
			local name = self:GetBoneName( bone )

			if BoneName ~= name then continue end

			local mins, maxs = self:GetHitBoxBounds( hitbox, hboxset )
			local pos, ang = self:GetBonePosition( BoneID )

			return self:WorldToLocal( pos ), self:WorldToLocalAngles( ang ), mins, maxs
		end
	end

	:: SkipLoop ::

	return vector_origin, angle_zero, vector_origin, vector_origin
end
