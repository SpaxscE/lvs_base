
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
