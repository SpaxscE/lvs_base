-- a very bad exit script
-- bscly a copy of simfphys exit script retrofitted to lfs and then retrofitted to lvs because im too lazy to recreate this piece of shit 

hook.Add( "PlayerUse", "!!!LVS_FIX_RE_ENTER", function( ply, ent )
	if ent.LVS and (ply._lvsNextUse or 0) > CurTime() then return false end
end )

hook.Add( "PlayerLeaveVehicle", "!!LVS_Exit", function( ply, Pod )
	if not ply:IsPlayer() then return end

	local Vehicle = ply:lvsGetVehicle()

	if not IsValid( Vehicle ) then return end

	ply._lvsNextUse = CurTime() + 0.25

	local Center = Vehicle:LocalToWorld( Vehicle:OBBCenter() )
	local vel = Vehicle:GetVelocity()
	local radius = Vehicle:BoundingRadius()
	local HullSize = Vector(18,18,0)
	local Filter1 = { Pod, ply }
	local Filter2 = { Pod, ply, Vehicle }

	for _, filterEntity in pairs( constraint.GetAllConstrainedEntities( Vehicle ) ) do
		if IsValid( filterEntity ) then
			table.insert( Filter2, filterEntity )
		end
	end

	if vel:Length() > 250 then
		local pos = Vehicle:GetPos()
		local dir = vel:GetNormalized()
		local targetpos = pos - dir *  (radius + 40)
		
		local tr = util.TraceHull( {
			start = Center,
			endpos = targetpos - Vector(0,0,10),
			maxs = HullSize,
			mins = -HullSize,
			filter = Filter2
		} )
		
		local exitpoint = tr.HitPos + Vector(0,0,10)
		
		if util.IsInWorld( exitpoint ) then
			ply:SetPos(exitpoint)
			ply:SetEyeAngles((pos - exitpoint):Angle())
		end
	else
		local pos = Pod:GetPos()
		local targetpos = (pos + Pod:GetRight() * 80)
		
		local tr1 = util.TraceLine( {
			start = targetpos,
			endpos = targetpos - Vector(0,0,100),
			filter = {}
		} )
		local tr2 = util.TraceHull( {
			start = targetpos,
			endpos = targetpos + Vector(0,0,80),
			maxs = HullSize,
			mins = -HullSize,
			filter = Filter1
		} )
		local traceto = util.TraceLine( {start = Center,endpos = targetpos,filter = Filter2} )
		
		local HitGround = tr1.Hit
		local HitWall = tr2.Hit or traceto.Hit
		
		local check0 = (HitWall == true or HitGround == false or util.IsInWorld( targetpos ) == false) and (pos - Pod:GetRight() * 80) or targetpos
		local tr = util.TraceHull( {
			start = check0,
			endpos = check0 + Vector(0,0,80),
			maxs = HullSize,
			mins = -HullSize,
			filter = Filter1
		} )
		local traceto = util.TraceLine( {start = Center,endpos = check0,filter = Filter2} )
		local HitWall = tr.Hit or traceto.hit
		
		local check1 = (HitWall == true or HitGround == false or util.IsInWorld( check0 ) == false) and (pos + Pod:GetUp() * 100) or check0
		
		local tr = util.TraceHull( {
			start = check1,
			endpos = check1 + Vector(0,0,80),
			maxs = HullSize,
			mins = -HullSize,
			filter = Filter1
		} )
		local traceto = util.TraceLine( {start = Center,endpos = check1,filter = Filter2} )
		local HitWall = tr.Hit or traceto.hit
		local check2 = (HitWall == true or util.IsInWorld( check1 ) == false) and (pos - Pod:GetUp() * 100) or check1
		
		local tr = util.TraceHull( {
			start = check2,
			endpos = check2 + Vector(0,0,80),
			maxs = HullSize,
			mins = -HullSize,
			filter = Filter1
		} )
		local traceto = util.TraceLine( {start = Center,endpos = check2,filter = Filter2} )
		local HitWall = tr.Hit or traceto.hit
		local check3 = (HitWall == true or util.IsInWorld( check2 ) == false) and Vehicle:LocalToWorld( Vector(0,radius,0) ) or check2
		
		local tr = util.TraceHull( {
			start = check3,
			endpos = check3 + Vector(0,0,80),
			maxs = HullSize,
			mins = -HullSize,
			filter = Filter1
		} )
		local traceto = util.TraceLine( {start = Center,endpos = check3,filter = Filter2} )
		local HitWall = tr.Hit or traceto.hit
		local check4 = (HitWall == true or util.IsInWorld( check3 ) == false) and Vehicle:LocalToWorld( Vector(0,-radius,0) ) or check3
		
		local tr = util.TraceHull( {
			start = check4,
			endpos = check4 + Vector(0,0,80),
			maxs = HullSize,
			mins = -HullSize,
			filter = Filter1
		} )
		local traceto = util.TraceLine( {start = Center,endpos = check4,filter = Filter2} )
		local HitWall = tr.Hit or traceto.hit
		local exitpoint = (HitWall == true or util.IsInWorld( check4 ) == false) and Vehicle:LocalToWorld( Vector(0,0,0) ) or check4
		
		if isvector( Pod.ExitPos ) then
			exitpoint = Vehicle:LocalToWorld( Pod.ExitPos )
		end

		if util.IsInWorld( exitpoint ) then
			ply:SetPos( exitpoint )
			ply:SetEyeAngles( (pos - exitpoint):Angle() )
		end
	end
end )