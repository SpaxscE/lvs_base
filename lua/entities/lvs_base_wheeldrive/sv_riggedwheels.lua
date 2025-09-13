
local function SetAll( ent, n )
	if not IsValid( ent ) then return end

	ent:SetPoseParameter("vehicle_wheel_fl_height",n) 
	ent:SetPoseParameter("vehicle_wheel_fr_height",n) 
	ent:SetPoseParameter("vehicle_wheel_rl_height",n) 
	ent:SetPoseParameter("vehicle_wheel_rr_height",n)
end

function ENT:CreateRigControler( name, wheelEntity, min, max )
	local RigHandler = ents.Create( "lvs_wheeldrive_righandler" )

	if not IsValid( RigHandler ) then
		self:Remove()

		print("LVS: Failed to create righandler entity. Vehicle terminated.")

		return
	end

	RigHandler:SetPos( self:GetPos() )
	RigHandler:SetAngles( self:GetAngles() )
	RigHandler:Spawn()
	RigHandler:Activate()
	RigHandler:SetParent( self )
	RigHandler:SetBase( self )
	RigHandler:SetPose0( min )
	RigHandler:SetPose1( max )
	RigHandler:SetWheel( wheelEntity )
	RigHandler:SetNameID( name )

	self:DeleteOnRemove( RigHandler )

	self:TransferCPPI( RigHandler )

	return RigHandler
end

function ENT:AddWheelsUsingRig( FrontRadius, RearRadius, data )
	if not istable( data ) then data = {} end

	local Body = ents.Create( "prop_dynamic" )
	Body:SetModel( self:GetModel() )
	Body:SetPos( self:GetPos() )
	Body:SetAngles( self:GetAngles() )
	Body:SetMoveType( MOVETYPE_NONE )
	Body:Spawn()
	Body:Activate()
	Body:SetColor( Color(255,255,255,0) )
	Body:SetRenderMode( RENDERMODE_TRANSCOLOR )

	SetAll( Body, 0 )

	SafeRemoveEntityDelayed( Body, 0.3 )

	local id_fl = Body:LookupAttachment( "wheel_fl" )
	local id_fr = Body:LookupAttachment( "wheel_fr" )
	local id_rl = Body:LookupAttachment( "wheel_rl" )
	local id_rr = Body:LookupAttachment( "wheel_rr" )

	local ForwardAngle = angle_zero

	if not isnumber( FrontRadius ) or not isnumber( RearRadius ) or id_fl == 0 or id_fr == 0 or id_rl == 0 or id_rr == 0 then return NULL, NULL, NULL, NULL, ForwardAngle end

	local pFL0 = Body:WorldToLocal( Body:GetAttachment( id_fl ).Pos )
	local pFR0 = Body:WorldToLocal( Body:GetAttachment( id_fr ).Pos )
	local pRL0 = Body:WorldToLocal( Body:GetAttachment( id_rl ).Pos )
	local pRR0 = Body:WorldToLocal( Body:GetAttachment( id_rr ).Pos )

	local ForwardAngle = ((pFL0 + pFR0) / 2 - (pRL0 + pRR0) / 2):Angle()
	ForwardAngle.p = 0
	ForwardAngle.y = math.Round( ForwardAngle.y, 0 )
	ForwardAngle.r = 0
	ForwardAngle:Normalize() 

	local FL = self:AddWheel( { hide = (not isstring( data.mdl_fl )), pos = pFL0, radius = FrontRadius, mdl = data.mdl_fl, mdl_ang = data.mdl_ang_fl } )
	local FR = self:AddWheel( { hide = (not isstring( data.mdl_fr )), pos = pFR0, radius = FrontRadius, mdl = data.mdl_fr, mdl_ang = data.mdl_ang_fr } )
	local RL = self:AddWheel( { hide = (not isstring( data.mdl_rl )), pos = pRL0, radius = RearRadius, mdl = data.mdl_rl, mdl_ang = data.mdl_ang_rl } )
	local RR = self:AddWheel( { hide = (not isstring( data.mdl_rr )), pos = pRR0, radius = RearRadius, mdl = data.mdl_rr, mdl_ang = data.mdl_ang_rr } )

	SetAll( Body, 1 )

	timer.Simple( 0.15, function()
		if not IsValid( self ) or not IsValid( Body ) then return end

		local pFL1 = Body:WorldToLocal( Body:GetAttachment( id_fl ).Pos )
		local pFR1 = Body:WorldToLocal( Body:GetAttachment( id_fr ).Pos )
		local pRL1 = Body:WorldToLocal( Body:GetAttachment( id_rl ).Pos )
		local pRR1 = Body:WorldToLocal( Body:GetAttachment( id_rr ).Pos )

		self:CreateRigControler( "fl", FL, pFL0.z, pFL1.z )
		self:CreateRigControler( "fr", FR, pFR0.z, pFR1.z )
		self:CreateRigControler( "rl", RL, pRL0.z, pRL1.z )
		self:CreateRigControler( "rr", RR, pRR0.z, pRR1.z )
	end )

	return FL, FR, RL, RR, ForwardAngle
end