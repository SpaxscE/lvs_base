
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
	hook.Add( "HUDPaint", "!!!!!LVS_hud", function()
		local ply = LocalPlayer()

		if ply:GetViewEntity() ~= ply then return end

		local Pod = ply:GetVehicle()
		local Parent = ply:lvsGetVehicle()

		if not IsValid( Pod ) or not IsValid( Parent ) then
			ply.oldPassengers = {}

			return
		end

		Parent:LVSHudPaint( ScrW(), ScrH(), ply )
	end )
end