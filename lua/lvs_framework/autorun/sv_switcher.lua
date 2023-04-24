hook.Add( "PlayerButtonDown", "!!!lvsSeatSwitcherButtonDown", function( ply, button )
	local vehicle = ply:lvsGetVehicle()

	if not IsValid( vehicle ) then return end

	local CurPod = ply:GetVehicle()

	if button == KEY_1 then
		if ply == vehicle:GetDriver() then
			if vehicle:GetlvsLockedStatus() then
				vehicle:UnLock()
			else
				vehicle:Lock()
			end
		else
			if IsValid( vehicle:GetDriver() ) or vehicle:GetAI() then return end
	
			if hook.Run( "LVS.CanPlayerDrive", ply, vehicle ) == false then
				hook.Run( "LVS.OnPlayerCannotDrive", ply, vehicle )
				return
			end

			ply:ExitVehicle()

			local DriverSeat = vehicle:GetDriverSeat()

			if not IsValid( DriverSeat ) then return end

			if hook.Run( "LVS.OnPlayerRequestSeatSwitch", ply, vehicle, CurPod, DriverSeat ) == false then return end

			timer.Simple( 0, function()
				if not IsValid( vehicle ) or not IsValid( ply ) then return end
				if IsValid( vehicle:GetDriver() ) or not IsValid( DriverSeat ) or vehicle:GetAI() then return end

				ply:EnterVehicle( DriverSeat )
				vehicle:AlignView( ply )
			end)
		end
	else
		for _, Pod in pairs( vehicle:GetPassengerSeats() ) do
			if not IsValid( Pod ) or Pod:GetNWInt( "pPodIndex", 3 ) ~= LVS.pSwitchKeys[ button ] or IsValid( Pod:GetDriver() ) then continue end

			if hook.Run( "LVS.OnPlayerRequestSeatSwitch", ply, vehicle, CurPod, Pod ) == false then continue end

			ply:ExitVehicle()

			timer.Simple( 0, function()
				if not IsValid( Pod ) or not IsValid( ply ) then return end
				if IsValid( Pod:GetDriver() ) then return end

				ply:EnterVehicle( Pod )
				vehicle:AlignView( ply, true )
			end)
		end
	end
end )
