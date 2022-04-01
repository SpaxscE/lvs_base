
local meta = FindMetaTable( "Player" )

function meta:GetView()
	return self.ViewAngles or Angle(0,0,0)
end

function meta:GetMiniVehicle()
	if not self:InVehicle() then return NULL end

	local Pod = self:GetVehicle()

	if not IsValid( Pod ) then return NULL end

	if Pod.miniLFSchecked then

		return Pod.miniLFSBaseEnt

	else
		local Parent = Pod:GetParent()

		if not IsValid( Parent ) then return NULL end

		if not Parent.MiniLFS then return NULL end

		Pod.miniLFSchecked = true
		Pod.miniLFSBaseEnt = Parent

		return Parent
	end
end

if SERVER then
	util.AddNetworkString( "sync_server_view" )

	net.Receive( "sync_server_view", function( len, ply )
		ply.ViewAngles = Angle( net.ReadFloat(), net.ReadFloat(), net.ReadFloat() )
	end )

	hook.Add("CanExitVehicle","!!!!!!CanExitVehicle",function(vehicle,ply)
		if IsValid( ply:GetMiniVehicle() ) then return false end
	end)
else
	local chatopen = false
	hook.Add( "FinishChat", "!!!chatend", function()
		chatopen = false
	end)

	hook.Add( "StartChat", "!!!!chatstart", function()
		chatopen = true
	end)

	local NextNW = 0
	local NWDelay = 0.03
	function meta:SetView( ang )
		self.ViewAngles = ang

		if NextNW < CurTime() then
			NextNW = CurTime() + NWDelay

			net.Start( "sync_server_view" )
				net.WriteFloat( ang.p )
				net.WriteFloat( ang.y )
				net.WriteFloat( ang.r )
			net.SendToServer()
		end
	end

	hook.Add("SpawnMenuOpen", "!!!!!!11DisableSpawnmenu", function()
		if IsValid( LocalPlayer():GetMiniVehicle() ) then return false end
	end)

	local Sensitivity = 0.03
	local LAST_CALL = 0
	hook.Add( "CreateMove", "MouseStuff", function( cmd )
		local ply = LocalPlayer()

		local DELTA = (CurTime() - LAST_CALL)
		LAST_CALL = CurTime()

		if not IsValid( ply:GetMiniVehicle() ) then
			ply:SetView( Angle(0,0,0) )
		else
			local X = cmd:GetMouseX() * Sensitivity
			local Y = cmd:GetMouseY() * Sensitivity
			local Z = ((input.IsKeyDown( KEY_E ) and 1 or 0) - (input.IsKeyDown( KEY_Q ) and 1 or 0)) * DELTA * 75

			if chatopen then
				Z = 0
			end

			local Ang = ply:GetView()
			Ang:RotateAroundAxis( Ang:Right(), -Y )
			Ang:RotateAroundAxis( Ang:Up(), -X )
			Ang:RotateAroundAxis( Ang:Forward(), Z )

			ply:SetView( Ang )
		end
	end )

	hook.Add( "CalcView", "!!!!!!smollLFS_calcview", function(ply, pos, angles, fov)
		if ply:GetViewEntity() ~= ply then return end

		local Pod = ply:GetVehicle()
		local Parent = ply:GetMiniVehicle()

		if not IsValid( Pod ) or not IsValid( Parent ) then return end

		local Vel = Parent:GetVelocity():Length()

		Parent.smFov = Parent.smFov and (Parent.smFov + ((math.Clamp(Vel / Parent.MaxSpeed / 10,0,1) ^ 2) * 25 - Parent.smFov) * RealFrameTime()) or 0
		local view = {}
		view.origin = pos
		view.fov = 60 + Parent.smFov
		view.drawviewer = false
		view.angles = ply:GetView()

		local radius = 8
		radius = radius + radius * Pod:GetCameraDistance()
		
		local TargetOrigin = view.origin - view.angles:Forward() * radius  + view.angles:Up() * radius * 0.1
		local WallOffset = 1

		local tr = util.TraceHull( {
			start = view.origin,
			endpos = TargetOrigin,
			filter = function( e )
				local c = e:GetClass()
				local collide = not c:StartWith( "prop_physics" ) and not c:StartWith( "prop_dynamic" ) and not c:StartWith( "prop_ragdoll" ) and not e:IsVehicle() and not c:StartWith( "gmod_" ) and not c:StartWith( "player" ) and not e.MiniLFS

				return collide
			end,
			mins = Vector( -WallOffset, -WallOffset, -WallOffset ),
			maxs = Vector( WallOffset, WallOffset, WallOffset ),
		} )

		view.origin = tr.HitPos

		if tr.Hit and not tr.StartSolid then
			view.origin = view.origin
		end

		return Parent:LFSCalcViewThirdPerson( view, ply )
	end )

	hook.Add( "HUDPaint", "!!!!!!!!miniLFS_hud", function()
		local ply = LocalPlayer()

		if ply:GetViewEntity() ~= ply then return end

		local Pod = ply:GetVehicle()
		local Parent = ply:GetMiniVehicle()

		if not IsValid( Pod ) or not IsValid( Parent ) then 
			return
		end

		local startpos = Parent:GetRotorPos()
		local TracePlane = util.TraceLine( {
			start = startpos,
			endpos = (startpos + Parent:GetForward() * 50000),
			filter = Parent,
		} )

		local TracePilot = util.TraceLine( {
			start = startpos,
			endpos = (startpos + ply:GetView():Forward() * 50000),
			filter = Parent,
		} )

		local HitPlane = TracePlane.HitPos:ToScreen()
		local HitPilot = TracePilot.HitPos:ToScreen()

		local Sub = Vector(HitPilot.x,HitPilot.y,0) - Vector(HitPlane.x,HitPlane.y,0)
		local Len = Sub:Length()
		local Dir = Sub:GetNormalized()

		Parent:LFSHudPaintInfoText()
		Parent:LFSHudPaintCrosshair( HitPlane, HitPilot )
	end )

	surface.CreateFont( "miniLFS_FONT", {
		font = "Verdana",
		extended = false,
		size = 20,
		weight = 2000,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = true,
		additive = false,
		outline = false,
	} )
end