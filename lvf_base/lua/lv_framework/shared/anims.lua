
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
