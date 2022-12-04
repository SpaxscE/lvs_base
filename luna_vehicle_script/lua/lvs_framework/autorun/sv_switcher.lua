hook.Add( "PlayerButtonDown", "!!!lvsButtonDown", function( ply, button )
	local vehicle = ply:lvsGetVehicle()

	if not IsValid( vehicle ) then return end

	if button == KEY_1 then
		if ply == vehicle:GetDriver() then
			if vehicle:GetlvsLockedStatus() then
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
				if Pod:GetNWInt( "pPodIndex", 3 ) == LVS.pSwitchKeys[ button ] then
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
