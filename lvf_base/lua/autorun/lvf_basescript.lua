--DO NOT EDIT OR REUPLOAD THIS FILE

local meta = FindMetaTable( "Player" )

globLVF = istable( globLVF ) and globLVF or {}

globLVF.pSwitchKeys = {[KEY_1] = 1,[KEY_2] = 2,[KEY_3] = 3,[KEY_4] = 4,[KEY_5] = 5,[KEY_6] = 6,[KEY_7] = 7,[KEY_8] = 8,[KEY_9] = 9,[KEY_0] = 10}
globLVF.pSwitchKeysInv = {[1] = KEY_1,[2] = KEY_2,[3] = KEY_3,[4] = KEY_4,[5] = KEY_5,[6] = KEY_6,[7] = KEY_7,[8] = KEY_8,[9] = KEY_9,[10] = KEY_0}

function meta:lvfGetVehicle()
	if not self:InVehicle() then return NULL end

	local Pod = self:GetVehicle()

	if not IsValid( Pod ) then return NULL end

	if Pod.LVFchecked then

		return Pod.LVFBaseEnt

	else
		local Parent = Pod:GetParent()
		
		if not IsValid( Parent ) then return NULL end

		if not Parent.LVF then return NULL end

		Pod.LVFchecked = true
		Pod.LVFBaseEnt = Parent

		return Parent
	end
end


hook.Add("CalcMainActivity", "!!!lvf_playeranimations", function(ply)
	if not ply.lvfGetVehicle then return end

	local Ent = ply:lvfGetVehicle()

	if IsValid( Ent ) then
		local A,B = Ent:CalcMainActivity( ply )

		if A and B then
			return A, B
		end
	end
end)

if SERVER then 
	util.AddNetworkString( "lvf_player_request_filter" )

	net.Receive( "lvf_player_request_filter", function( length, ply )
		if not IsValid( ply ) then return end

		local LVFent = net.ReadEntity()

		if not IsValid( LVFent ) then return end

		if not istable( LVFent.CrosshairFilterEnts ) then
			LVFent.CrosshairFilterEnts = {}

			for _, Entity in pairs( constraint.GetAllConstrainedEntities( LVFent ) ) do
				if IsValid( Entity ) then
					if not Entity:GetNoDraw() then -- dont add nodraw entites. They are NULL for client anyway
						table.insert( LVFent.CrosshairFilterEnts, Entity )
					end
				end
			end

			for _, Parent in pairs( LVFent.CrosshairFilterEnts ) do
				local Childs = Parent:GetChildren()
				for _, Child in pairs( Childs ) do
					if IsValid( Child ) then
						table.insert( LVFent.CrosshairFilterEnts, Child )
					end
				end
			end
		end

		net.Start( "lvf_player_request_filter" )
			net.WriteEntity( LVFent )
			net.WriteTable( LVFent.CrosshairFilterEnts )
		net.Send( ply )
	end)

	hook.Add( "PlayerButtonDown", "!!!lvfButtonDown", function( ply, button )
		local vehicle = ply:lvfGetVehicle()

		if not IsValid( vehicle ) then return end

		if button == KEY_1 then
			if ply == vehicle:GetDriver() then
				if vehicle:GetlvfLockedStatus() then
					vehicle:UnLock()
				else
					vehicle:Lock()
				end
			else
				if not IsValid( vehicle:GetDriver() ) and not vehicle:GetAI() then
					ply:ExitVehicle()

					local DriverSeat = vehicle:GetDriverSeat()

					if IsValid( DriverSeat ) then
						timer.Simple( FrameTime(), function()
							if not IsValid( vehicle ) or not IsValid( ply ) then return end
							if IsValid( vehicle:GetDriver() ) or not IsValid( DriverSeat ) or vehicle:GetAI() then return end
							
							ply:EnterVehicle( DriverSeat )
							
							timer.Simple( FrameTime() * 2, function()
								if not IsValid( ply ) or not IsValid( vehicle ) then return end
								ply:SetEyeAngles( Angle(0,vehicle:GetAngles().y,0) )
							end)
						end)
					end
				end
			end
		else
			for _, Pod in pairs( vehicle:GetPassengerSeats() ) do
				if IsValid( Pod ) then
					if Pod:GetNWInt( "pPodIndex", 3 ) == globLVF.pSwitchKeys[ button ] then
						if not IsValid( Pod:GetDriver() ) then
							ply:ExitVehicle()

							timer.Simple( FrameTime(), function()
								if not IsValid( Pod ) or not IsValid( ply ) then return end
								if IsValid( Pod:GetDriver() ) then return end

								ply:EnterVehicle( Pod )
							end)
						end
					end
				end
			end
		end
	end )
end

if CLIENT then
	net.Receive( "lvf_player_request_filter", function( length )
		local LVFent = net.ReadEntity()

		if not IsValid( LVFent ) then return end

		local Filter = net.ReadTable()

		LVFent.CrosshairFilterEnts = Filter
	end )

	hook.Add( "CalcView", "!!!!LVF_calcview", function(ply, pos, angles, fov)
		if ply:GetViewEntity() ~= ply then return end
		
		local Pod = ply:GetVehicle()
		local Parent = ply:lvfGetVehicle()
		
		if not IsValid( Pod ) or not IsValid( Parent ) then return end

		local view = {}
		view.origin = pos
		view.fov = fov
		view.drawviewer = true
		view.angles = ply:EyeAngles()

		if not Pod:GetThirdPersonMode() then
			
			view.drawviewer = false
			
			return Parent:LVFCalcViewFirstPerson( view, ply )
		end

		local radius = 500
	
		local TargetOrigin = view.origin - view.angles:Forward() * radius  + view.angles:Up() * radius * 0.2
		local WallOffset = 4

		local tr = util.TraceHull( {
			start = view.origin,
			endpos = TargetOrigin,
			filter = function( e )
				local c = e:GetClass()
				local collide = not c:StartWith( "prop_physics" ) and not c:StartWith( "prop_dynamic" ) and not c:StartWith( "prop_ragdoll" ) and not e:IsVehicle() and not c:StartWith( "gmod_" ) and not c:StartWith( "player" ) and not e.LVF

				return collide
			end,
			mins = Vector( -WallOffset, -WallOffset, -WallOffset ),
			maxs = Vector( WallOffset, WallOffset, WallOffset ),
		} )
		
		view.origin = tr.HitPos

		if tr.Hit and not tr.StartSolid then
			view.origin = view.origin + tr.HitNormal * WallOffset
		end

		return Parent:LVFCalcViewThirdPerson( view, ply )
	end )

	surface.CreateFont( "LVF_FONT_SWITCHER", {
		font = "Verdana",
		extended = false,
		size = 16,
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

	local LockText = Material( "lvf_locked.png" )
	local smHider = 0
	local function PaintSeatSwitcher( ent, X, Y )
		local me = LocalPlayer()

		if not IsValid( ent ) then return end

		local pSeats = ent:GetPassengerSeats()
		local SeatCount = table.Count( pSeats ) 

		if SeatCount <= 0 then return end
		
		pSeats[0] = ent:GetDriverSeat()

		draw.NoTexture() 

		local MySeat = me:GetVehicle():GetNWInt( "pPodIndex", -1 )

		local Passengers = {}
		for _, ply in pairs( player.GetAll() ) do
			if ply:lvfGetVehicle() == ent then
				local Pod = ply:GetVehicle()
				Passengers[ Pod:GetNWInt( "pPodIndex", -1 ) ] = ply:GetName()
			end
		end
		if ent:GetAI() then
			Passengers[1] = "[AI] "..ent.PrintName
		end
		
		me.SwitcherTime = me.SwitcherTime or 0
		me.oldPassengers = me.oldPassengers or {}
		
		local Time = CurTime()
		for k, v in pairs( Passengers ) do
			if me.oldPassengers[k] ~= v then
				me.oldPassengers[k] = v
				me.SwitcherTime = Time + 2
			end
		end
		for k, v in pairs( me.oldPassengers ) do
			if not Passengers[k] then
				me.oldPassengers[k] = nil
				me.SwitcherTime = Time + 2
			end
		end

		for _, v in pairs( globLVF.pSwitchKeysInv ) do
			if input.IsKeyDown(v) then
				me.SwitcherTime = Time + 2
			end
		end

		local Hide = me.SwitcherTime > Time
		smHider = smHider + ((Hide and 1 or 0) - smHider) * RealFrameTime() * 15
		local Alpha1 = 135 + 110 * smHider 
		local HiderOffset = 300 * smHider
		local Offset = -50
		local yPos = Y - (SeatCount + 1) * 30 - 10

		for _, Pod in pairs( pSeats ) do
			local I = Pod:GetNWInt( "pPodIndex", -1 )
			if I >= 0 then
				if I == MySeat then
					draw.RoundedBox(5, X + Offset - HiderOffset, yPos + I * 30, 35 + HiderOffset, 25, Color(127,100,0,100 + 50 * smHider) )
				else
					draw.RoundedBox(5, X + Offset - HiderOffset, yPos + I * 30, 35 + HiderOffset, 25, Color(0,0,0,100 + 50 * smHider) )
				end
				if I == SeatCount then
					if ent:GetlvfLockedStatus() then
						surface.SetDrawColor( 255, 255, 255, 255 )
						surface.SetMaterial( LockText  )
						surface.DrawTexturedRect( X + Offset - HiderOffset - 25, yPos + I * 30, 25, 25 )
					end
				end
				if Hide then
					if Passengers[I] then
						draw.DrawText( Passengers[I], "LVF_FONT_SWITCHER", X + 40 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255,  Alpha1 ), TEXT_ALIGN_LEFT )
					else
						draw.DrawText( "-", "LVF_FONT_SWITCHER", X + 40 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255,  Alpha1 ), TEXT_ALIGN_LEFT )
					end
					
					draw.DrawText( "["..I.."]", "LVF_FONT_SWITCHER", X + 17 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255, Alpha1 ), TEXT_ALIGN_CENTER )
				else
					if Passengers[I] then
						draw.DrawText( "[^"..I.."]", "LVF_FONT_SWITCHER", X + 17 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255, Alpha1 ), TEXT_ALIGN_CENTER )
					else
						draw.DrawText( "["..I.."]", "LVF_FONT_SWITCHER", X + 17 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255, Alpha1 ), TEXT_ALIGN_CENTER )
					end
				end
			end
		end
	end

	hook.Add( "HUDPaint", "!!!!!LVF_hud", function()
		local ply = LocalPlayer()
		
		if ply:GetViewEntity() ~= ply then return end
		
		local Pod = ply:GetVehicle()
		local Parent = ply:lvfGetVehicle()

		if not IsValid( Pod ) or not IsValid( Parent ) then 
			ply.oldPassengers = {}
			
			return
		end

		local X = ScrW()
		local Y = ScrH()

		PaintSeatSwitcher( Parent, X, Y )

		Parent:LVFHudPaint( X, Y, ply )
	end )
end
