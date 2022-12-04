-- a very bad exit script
-- bscly a copy of simfphys exit script retrofitted to lfs and then retrofitted to lvs because im too lazy to recreate this piece of shit 

hook.Add( "PlayerLeaveVehicle", "!!LVS_Exit", function( ply, vehicle )
	if not ply:IsPlayer() then return end

	local Pod = ply:GetVehicle()
	local Parent = ply:lvsGetVehicle()

	if not IsValid( Pod ) or not IsValid( Parent ) then return end

	--[[
	if not simfphys.LFS.FreezeTeams:GetBool() then
		ply:lfsSetAITeam( Parent:GetAITEAM() )
	end
	]]

	local ent = Pod
	local b_ent = Parent

	local Center = b_ent:LocalToWorld( b_ent:OBBCenter() )
	local vel = b_ent:GetVelocity()
	local radius = b_ent:BoundingRadius()
	local HullSize = Vector(18,18,0)
	local Filter1 = {ent,ply}
	local Filter2 = {ent,ply,b_ent}

	for _, filterEntity in pairs( constraint.GetAllConstrainedEntities( b_ent ) ) do
		if IsValid( filterEntity ) then
			table.insert( Filter2, filterEntity )
		end
	end

	if vel:Length() > 250 then
		local pos = b_ent:GetPos()
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
		local pos = ent:GetPos()
		local targetpos = (pos + ent:GetRight() * 80)
		
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
		
		local check0 = (HitWall == true or HitGround == false or util.IsInWorld( targetpos ) == false) and (pos - ent:GetRight() * 80) or targetpos
		local tr = util.TraceHull( {
			start = check0,
			endpos = check0 + Vector(0,0,80),
			maxs = HullSize,
			mins = -HullSize,
			filter = Filter1
		} )
		local traceto = util.TraceLine( {start = Center,endpos = check0,filter = Filter2} )
		local HitWall = tr.Hit or traceto.hit
		
		local check1 = (HitWall == true or HitGround == false or util.IsInWorld( check0 ) == false) and (pos + ent:GetUp() * 100) or check0
		
		local tr = util.TraceHull( {
			start = check1,
			endpos = check1 + Vector(0,0,80),
			maxs = HullSize,
			mins = -HullSize,
			filter = Filter1
		} )
		local traceto = util.TraceLine( {start = Center,endpos = check1,filter = Filter2} )
		local HitWall = tr.Hit or traceto.hit
		local check2 = (HitWall == true or util.IsInWorld( check1 ) == false) and (pos - ent:GetUp() * 100) or check1
		
		local tr = util.TraceHull( {
			start = check2,
			endpos = check2 + Vector(0,0,80),
			maxs = HullSize,
			mins = -HullSize,
			filter = Filter1
		} )
		local traceto = util.TraceLine( {start = Center,endpos = check2,filter = Filter2} )
		local HitWall = tr.Hit or traceto.hit
		local check3 = (HitWall == true or util.IsInWorld( check2 ) == false) and b_ent:LocalToWorld( Vector(0,radius,0) ) or check2
		
		local tr = util.TraceHull( {
			start = check3,
			endpos = check3 + Vector(0,0,80),
			maxs = HullSize,
			mins = -HullSize,
			filter = Filter1
		} )
		local traceto = util.TraceLine( {start = Center,endpos = check3,filter = Filter2} )
		local HitWall = tr.Hit or traceto.hit
		local check4 = (HitWall == true or util.IsInWorld( check3 ) == false) and b_ent:LocalToWorld( Vector(0,-radius,0) ) or check3
		
		local tr = util.TraceHull( {
			start = check4,
			endpos = check4 + Vector(0,0,80),
			maxs = HullSize,
			mins = -HullSize,
			filter = Filter1
		} )
		local traceto = util.TraceLine( {start = Center,endpos = check4,filter = Filter2} )
		local HitWall = tr.Hit or traceto.hit
		local exitpoint = (HitWall == true or util.IsInWorld( check4 ) == false) and b_ent:LocalToWorld( Vector(0,0,0) ) or check4
		
		if isvector( ent.ExitPos ) then
			exitpoint = b_ent:LocalToWorld( ent.ExitPos )
		end
		
		if util.IsInWorld( exitpoint ) then
			ply:SetPos(exitpoint)
			ply:SetEyeAngles((pos - exitpoint):Angle())
		end
	end
end )