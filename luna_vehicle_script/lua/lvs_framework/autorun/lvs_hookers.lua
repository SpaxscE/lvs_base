
hook.Add( "VehicleMove", "!!!!lvs_vehiclemove", function( ply, vehicle, mv )
	if not ply.lvsGetVehicle then return end

	local veh = ply:lvsGetVehicle()

	if not IsValid( veh ) then return end

	if ply:lvsKeyDown( "VIEWDIST" ) then
		local iWheel = ply:GetCurrentCommand():GetMouseWheel()
		if iWheel ~= 0 and vehicle.SetCameraDistance then
			local newdist = math.Clamp( vehicle:GetCameraDistance() - iWheel * 0.03 * ( 1.1 + vehicle:GetCameraDistance() ), -1, 10 )
			vehicle:SetCameraDistance( newdist )
		end
	end

	if CLIENT and not IsFirstTimePredicted() then return end
	
	local KeyThirdPerson = ply:lvsKeyDown("THIRDPERSON")

	if ply._lvsOldThirdPerson ~= KeyThirdPerson then
		ply._lvsOldThirdPerson = KeyThirdPerson

		if KeyThirdPerson and vehicle.SetThirdPersonMode then
			vehicle:SetThirdPersonMode( not vehicle:GetThirdPersonMode() )
		end
	end

	return true
end )

hook.Add( "PhysgunPickup", "!!!!lvs_disable_wheel_grab", function( ply, ent )
	if ent.lvsDoNotGrab then return false end
end )

hook.Add("CalcMainActivity", "!!!lvs_playeranimations", function(ply)
	if not ply.lvsGetVehicle then return end

	local Ent = ply:lvsGetVehicle()

	if IsValid( Ent ) then
		local A,B = Ent:CalcMainActivity( ply )

		if A and B then
			return A, B
		end
	end
end)

hook.Add( "StartCommand", "!!!!LVS_grab_command", function( ply, cmd )
	if not ply.lvsGetVehicle then return end

	local veh = ply:lvsGetVehicle()

	if not IsValid( veh ) then return end

	veh:StartCommand( ply, cmd )
end )

if CLIENT then
	hook.Add( "PlayerBindPress", "!!!!_LVS_HideZOOM", function( ply, bind, pressed )
		if not ply.lvsGetVehicle or not IsValid( ply:lvsGetVehicle() ) then return end

		if string.find( bind, "+zoom" ) then
			return true
		end
	end )

	hook.Add( "HUDPaint", "!!!!!LVS_hud", function()
		local ply = LocalPlayer()

		if ply:GetViewEntity() ~= ply then return end

		local Pod = ply:GetVehicle()
		local Parent = ply:lvsGetVehicle()

		if not IsValid( Pod ) or not IsValid( Parent ) then
			ply._lvsoldPassengers = {}

			return
		end

		local X = ScrW()
		local Y = ScrH()

		Parent:LVSHudPaint( X, Y, ply )
		Parent:LVSHudPaintSeatSwitcher( X, Y, ply )
	end )

	return
end

hook.Add( "EntityTakeDamage", "!!!_lvs_fix_vehicle_explosion_damage", function( target, dmginfo )
	if not target:IsPlayer() or not dmginfo:IsExplosionDamage() then return end

	local veh = target:lvsGetVehicle()

	if not IsValid( veh ) then return end

	dmginfo:SetDamage( 0 )
end )