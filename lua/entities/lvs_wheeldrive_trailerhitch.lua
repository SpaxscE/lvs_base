AddCSLuaFile()

ENT.Type            = "anim"
ENT.DoNotDuplicate = true

ENT.RenderGroup = RENDERGROUP_BOTH

local IgnoreDistance = 200
local GrabDistance = 150
local HookupDistance = 32

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
	self:NetworkVar( "Entity",1, "TargetBase" )
	self:NetworkVar( "Entity",2, "DragTarget" )
	self:NetworkVar( "Int",0, "HitchType" )

	if SERVER then
		self:SetHitchType( LVS.HITCHTYPE_NONE or -1 )
	end
end

if SERVER then
	util.AddNetworkString( "lvs_trailerhitch" )

	net.Receive( "lvs_trailerhitch", function( len, ply )
		local ent = net.ReadEntity()

		if not IsValid( ent ) or not isfunction( ent.StartDrag ) then return end

		if ent.IsLinkInProgress then return end

		if IsValid( ent:GetTargetBase() ) then
			ent:Decouple()
		else
			ent:StartDrag( ply )
			ent._HandBrakeForceDisabled = true
		end
	end )

	function ENT:StartDrag( ply )
		if IsValid( self.GrabEnt ) or IsValid( ply._HitchGrabEnt ) then return end

		if self:GetHitchType() ~= LVS.HITCHTYPE_FEMALE then return end

		local base = self:GetBase()

		if not IsValid( ply ) or not ply:Alive() or ply:InVehicle() or ply:GetObserverMode() ~= OBS_MODE_NONE or not ply:KeyDown( IN_WALK ) or (ply:GetShootPos() - self:GetPos()):Length() > GrabDistance or not IsValid( base ) then return end

		ply:SprintDisable()

		self.GrabEnt = ents.Create( "prop_physics" )

		ply._HitchGrabEnt = self.GrabEnt

		if not IsValid( self.GrabEnt ) then return end

		self.GrabEnt:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )
		self.GrabEnt:SetPos( self:GetPos() )
		self.GrabEnt:SetAngles( self:GetAngles() )
		self.GrabEnt:SetCollisionGroup( COLLISION_GROUP_WORLD )
		self.GrabEnt:Spawn()
		self.GrabEnt:Activate()
		self.GrabEnt:SetNoDraw( true ) 
		self.GrabEnt.DoNotDuplicate = true
		self:DeleteOnRemove( self.GrabEnt )

		self:SetDragTarget( ply )

		local PhysObj = self.GrabEnt:GetPhysicsObject()

		if not IsValid( PhysObj ) then return end

		PhysObj:SetMass( 50000 )
		PhysObj:EnableMotion( false )

		constraint.Ballsocket( base, self.GrabEnt, 0, 0, vector_origin, 0, 0, 1 )

		self.GrabEnt:SetSolid( SOLID_NONE )

		base:OnStartDrag( self, ply )
		base._HandBrakeForceDisabled = true

		base._DragOriginalCollisionGroup = base:GetCollisionGroup()
		base:SetCollisionGroup( COLLISION_GROUP_WORLD )

		if base.GetWheels then
			for _, wheel in pairs( base:GetWheels() ) do
				if not IsValid( wheel ) then continue end

				wheel._DragOriginalCollisionGroup = wheel:GetCollisionGroup()
				wheel:SetCollisionGroup( COLLISION_GROUP_WORLD )
			end
		end

		self:NextThink( CurTime() )
	end

	function ENT:StopDrag()
		if IsValid( self.GrabEnt ) then
			self.GrabEnt:Remove()
		end

		local ply = self:GetDragTarget()

		if IsValid( ply ) then
			ply:SprintEnable()
		end

		local base = self:GetBase()

		if IsValid( base ) then

			base:OnStopDrag( self, ply )
			base._HandBrakeForceDisabled = nil

			if IsValid( ply ) then base:SetPhysicsAttacker( ply ) end
	
			if base._DragOriginalCollisionGroup then
				base:SetCollisionGroup( base._DragOriginalCollisionGroup )
				base._DragOriginalCollisionGroup = nil
			end

			if base.GetWheels then
				for _, wheel in pairs( base:GetWheels() ) do
					if not IsValid( wheel ) then continue end

					if IsValid( ply ) then wheel:SetPhysicsAttacker( ply ) end

					if wheel._DragOriginalCollisionGroup then
						wheel:SetCollisionGroup( wheel._DragOriginalCollisionGroup )
						wheel._DragOriginalCollisionGroup = nil
					end
				end
			end
		end

		self:SetDragTarget( NULL )

		for _, ent in ipairs( ents.FindByClass( "lvs_wheeldrive_trailerhitch" ) ) do
			if ent:GetHitchType() ~= LVS.HITCHTYPE_MALE then continue end

			local dist = (self:GetPos() - ent:GetPos()):Length()

			if dist > HookupDistance then continue end

			self:CoupleTo( ent )

			break
		end
	end

	function ENT:Drag( ply )
		if not IsValid( self.GrabEnt ) or ply:InVehicle() or not ply:KeyDown( IN_WALK ) or not ply:Alive() or ply:GetObserverMode() ~= OBS_MODE_NONE then
			self:StopDrag()

			return
		end

		if not self.GrabEnt.TargetAngle then
			self.GrabEnt.TargetAngle = ply:EyeAngles().y
		end

		local TargetAngle = ply:EyeAngles()

		self.GrabEnt.TargetAngle = math.ApproachAngle( self.GrabEnt.TargetAngle, TargetAngle.y, FrameTime() * 500 )

		TargetAngle.p = math.max( TargetAngle.p, -15 )

		TargetAngle.y = self.GrabEnt.TargetAngle

		local TargetPos = ply:GetShootPos() + TargetAngle:Forward() * 80

		if (self:GetPos() - TargetPos):Length() > GrabDistance then self:StopDrag() return end

		self.GrabEnt:SetPos( TargetPos )

		local base = self:GetBase()

		if not IsValid( base ) then return end

		base:PhysWake()

		if base.WheelsOnGround then
			if base:WheelsOnGround() then return end
		else
			if base:OnGround() then return end
		end

		local PhysObj = base:GetPhysicsObject()
	
		if not IsValid( PhysObj ) then return end
	
		PhysObj:SetAngleVelocity( PhysObj:GetAngleVelocity() * 0.8 )
		PhysObj:SetVelocity( PhysObj:GetVelocity() * 0.8 )
	end

	function ENT:Initialize()
		self:SetSolid( SOLID_NONE )
		self:SetMoveType( MOVETYPE_NONE )
		self:DrawShadow( false )
	end

	function ENT:Decouple()
		local TargetBase = self:GetTargetBase()

		self:SetTargetBase( NULL )

		if not IsValid( self.HitchConstraint ) then return end

		local base = self:GetBase()

		if IsValid( base ) then
			base:OnCoupleChanged( TargetBase, self.HitchTarget, false )
			TargetBase:OnCoupleChanged( self:GetBase(), self, false )
		end

		self.HitchConstraint:Remove()

		self.HitchTarget = nil
	end

	function ENT:CoupleTo( target )
		if not IsValid( target ) or IsValid( target.HitchConstraint ) or IsValid( self.HitchConstraint ) then return end

		local base = self:GetBase()

		if self.IsLinkInProgress or not IsValid( base ) or IsValid( self.PosEnt ) then return end

		self.IsLinkInProgress = true

		if self:GetHitchType() ~= LVS.HITCHTYPE_FEMALE or target:GetHitchType() ~= LVS.HITCHTYPE_MALE then self.IsLinkInProgress = nil return end

		self.PosEnt = ents.Create( "prop_physics" )

		if not IsValid( self.PosEnt ) then self.IsLinkInProgress = nil return end

		self.PosEnt:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )
		self.PosEnt:SetPos( self:GetPos() )
		self.PosEnt:SetAngles( self:GetAngles() )
		self.PosEnt:SetCollisionGroup( COLLISION_GROUP_WORLD )
		self.PosEnt:Spawn()
		self.PosEnt:Activate()
		self.PosEnt:SetNoDraw( true ) 
		self.PosEnt.DoNotDuplicate = true
		self:DeleteOnRemove( self.PosEnt )

		local PhysObj = self.PosEnt:GetPhysicsObject()

		if not IsValid( PhysObj ) then self.IsLinkInProgress = nil return end

		PhysObj:SetMass( 50000 )
		PhysObj:EnableMotion( false )

		constraint.Ballsocket( base, self.PosEnt, 0, 0, vector_origin, 0, 0, 1 )

		local targetBase = target:GetBase()

		base:OnCoupleChanged( targetBase, target, true )
		targetBase:OnCoupleChanged( self:GetBase(), self, true )

		self.PosEnt:SetSolid( SOLID_NONE )

		timer.Simple( 0, function()
			if not IsValid( self.PosEnt ) then
				self.IsLinkInProgress = nil

				return
			end
	
			if not IsValid( target ) or not IsValid( targetBase ) then
				self.PosEnt:Remove()
	
				self.IsLinkInProgress = nil
	
				return
			end
	
			self.PosEnt:SetPos( target:GetPos() )

			constraint.Weld( self.PosEnt, targetBase, 0, 0, 0, false, false )

			timer.Simple( 0.25, function()
				if not IsValid( base ) or not IsValid( targetBase ) or not IsValid( self.PosEnt ) then self.IsLinkInProgress = nil return end

				self.HitchTarget = target
				self.HitchConstraint = constraint.Ballsocket( base, targetBase, 0, 0, targetBase:WorldToLocal( self.PosEnt:GetPos() ), 0, 0, 1 )

				target.HitchConstraint = self.HitchConstraint

				self:SetTargetBase( targetBase )

				self.PosEnt:Remove()

				self.IsLinkInProgress = nil 
			end )
		end )
	end

	function ENT:Think()

		local ply = self:GetDragTarget()

		if IsValid( ply ) then
			self:Drag( ply )

			self:NextThink( CurTime() )
		else
			self:NextThink( CurTime() + 9999 )
		end

		return true
	end

	function ENT:OnRemove()
		self:StopDrag()
	end

	return
end

local HitchEnts = {}

function ENT:Initialize()
	table.insert( HitchEnts, self )
end

function ENT:OnRemove()
	for id, e in pairs( HitchEnts ) do
		if IsValid( e ) then continue end

		HitchEnts[ id ] = nil
	end
end

function ENT:Draw()
end

local function DrawDiamond( X, Y, radius )
	local segmentdist = 90
	local radius2 = radius + 1
	
	for a = 0, 360, segmentdist do
		surface.DrawLine( X + math.cos( math.rad( a ) ) * radius, Y - math.sin( math.rad( a ) ) * radius, X + math.cos( math.rad( a + segmentdist ) ) * radius, Y - math.sin( math.rad( a + segmentdist ) ) * radius )
		surface.DrawLine( X + math.cos( math.rad( a ) ) * radius2, Y - math.sin( math.rad( a ) ) * radius2, X + math.cos( math.rad( a + segmentdist ) ) * radius2, Y - math.sin( math.rad( a + segmentdist ) ) * radius2 )
	end
end

local function DrawText( x, y, text, col )
	local font = "TargetIDSmall"
	draw.SimpleText( text, font, x + 1, y + 1, Color( 0, 0, 0, 120 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	draw.SimpleText( text, font, x + 2, y + 2, Color( 0, 0, 0, 50 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	draw.SimpleText( text, font, x, y, col or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
end

local circle = Material( "vgui/circle" )
local radius = 6
local Col = Color(255,191,0,255)

local boxMins = Vector(-5,-5,-5)
local boxMaxs = Vector(5,5,5)

function ENT:DrawInfoCoupled( ply )
	local boxOrigin = self:GetPos()
	local scr = boxOrigin:ToScreen()

	if not scr.visible then return end

	local shootPos = ply:GetShootPos()

	local boxAngles = self:GetAngles()

	if (boxOrigin - shootPos):Length() > 250 then return end

	local HitPos, _, _ = util.IntersectRayWithOBB( shootPos, ply:GetAimVector() * GrabDistance, boxOrigin, boxAngles, boxMins, boxMaxs )

	local X = scr.x
	local Y = scr.y

	cam.Start2D()
		if HitPos then
			surface.SetDrawColor( 255, 255, 255, 255 )

			local Key = input.LookupBinding( "+walk" )

			if not isstring( Key ) then Key = "[+walk not bound]" end

			DrawText( X, Y + 20, "press "..Key.." to decouple!",Color(255,255,255,255) )

			local KeyUse = ply:KeyDown( IN_WALK )

			if self.OldKeyUse ~= KeyUse then
				self.OldKeyUse = KeyUse

				if KeyUse then
					net.Start( "lvs_trailerhitch" )
						net.WriteEntity( self )
					net.SendToServer()
				end
			end
		else
			surface.SetDrawColor( Col.r, Col.g, Col.b, Col.a )
		end

		DrawDiamond( X, Y, radius )
		surface.SetDrawColor( 0, 0, 0, 80 )
		DrawDiamond( X + 1, Y + 1, radius )
	cam.End2D()
end

function ENT:DrawInfo( ply )
	local boxOrigin = self:GetPos()
	local scr = boxOrigin:ToScreen()

	if not scr.visible then return end

	local shootPos = ply:GetShootPos()

	local boxAngles = self:GetAngles()

	if (boxOrigin - shootPos):Length() > 250 then return end

	local HitPos, _, _ = util.IntersectRayWithOBB( shootPos, ply:GetAimVector() * GrabDistance, boxOrigin, boxAngles, boxMins, boxMaxs )

	local X = scr.x
	local Y = scr.y

	local DragTarget = self:GetDragTarget()
	local IsBeingDragged = IsValid( DragTarget )
	local HasTarget = false

	if IsBeingDragged then
		cam.Start2D()

		for id, ent in pairs( HitchEnts ) do
			if ent == self then continue end

			if not IsValid( ent ) or ent:GetHitchType() ~= LVS.HITCHTYPE_MALE then continue end

			local tpos = ent:GetPos()

			local dist = (tpos - boxOrigin):Length()

			if dist > IgnoreDistance then continue end

			local tscr = tpos:ToScreen()

			if not tscr.visible then continue end

			local tX = tscr.x
			local tY = tscr.y

			if dist < HookupDistance and IsBeingDragged then
				HasTarget = true
			end

			surface.SetMaterial( circle )
			surface.SetDrawColor( 0, 0, 0, 80 )
			surface.DrawTexturedRect( tX - radius * 0.5 + 1, tY - radius * 0.5 + 1, radius, radius )

			if HasTarget then
				surface.SetDrawColor( 0, 255, 0, 255 )
			else
				surface.SetDrawColor( Col.r, Col.g, Col.b, Col.a )
			end

			surface.DrawTexturedRect( tX - radius * 0.5, tY - radius * 0.5, radius, radius )

			if not HasTarget then continue end

			surface.DrawLine( X, Y, tX, tY )

			break
		end

		local radiusB = 25 + math.cos( CurTime() * 10 ) * 2

		if HasTarget then
			surface.SetDrawColor( 0, 255, 0, 255 )
		else
			surface.SetDrawColor( 255, 0, 0, 255 )
		end

		DrawDiamond( X, Y, radiusB )
		surface.SetDrawColor( 0, 0, 0, 80 )
		DrawDiamond( X + 1, Y + 1, radiusB )

		if HasTarget then
			DrawText( X, Y + 35, "release to couple",Color(0,255,0,255) )
		else
			DrawText( X, Y + 35, "in use by "..DragTarget:GetName(),Color(255,0,0,255) )
		end

		cam.End2D()

		return
	end

	cam.Start2D()
		if HitPos then
			surface.SetDrawColor( 255, 255, 255, 255 )

			local Key = input.LookupBinding( "+walk" )

			if not isstring( Key ) then Key = "[+walk not bound]" end

			DrawText( X, Y + 20, "hold "..Key.." to drag!",Color(255,255,255,255) )

			local KeyUse = ply:KeyDown( IN_WALK )

			if self.OldKeyUse ~= KeyUse then
				self.OldKeyUse = KeyUse

				if KeyUse then
					surface.PlaySound("common/wpn_select.wav")

					net.Start( "lvs_trailerhitch" )
						net.WriteEntity( self )
					net.SendToServer()
				end
			end
		else
			surface.SetDrawColor( Col.r, Col.g, Col.b, Col.a )
		end

		DrawDiamond( X, Y, radius )
		surface.SetDrawColor( 0, 0, 0, 80 )
		DrawDiamond( X + 1, Y + 1, radius )
	cam.End2D()
end

function ENT:DrawTranslucent()
	local ply = LocalPlayer()

	if not IsValid( ply ) or IsValid( ply:lvsGetVehicle() ) or self:GetHitchType() ~= LVS.HITCHTYPE_FEMALE then return end

	local wep = ply:GetActiveWeapon()

	if IsValid( wep ) and wep:GetClass() == "gmod_camera" then return end

	if IsValid( self:GetTargetBase() ) then
		self:DrawInfoCoupled( ply )

		return
	end

	self:DrawInfo( ply )
end
