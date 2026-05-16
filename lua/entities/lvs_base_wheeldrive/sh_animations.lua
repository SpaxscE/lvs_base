
function ENT:CalcMainActivityPassenger( ply )
end

function ENT:CalcMainActivity( ply )
	if ply ~= self:GetDriver() then return self:CalcMainActivityPassenger( ply ) end

	if ply.m_bWasNoclipping then 
		ply.m_bWasNoclipping = nil 
		ply:AnimResetGestureSlot( GESTURE_SLOT_CUSTOM ) 
		
		if CLIENT then 
			ply:SetIK( true )
		end 
	end 

	ply.CalcIdeal = ACT_STAND
	ply.CalcSeqOverride = ply:LookupSequence( "drive_jeep" )

	return ply.CalcIdeal, ply.CalcSeqOverride
end

function ENT:UpdateAnimation( ply, velocity, maxseqgroundspeed )
	ply:SetPlaybackRate( 1 )

	if CLIENT then
		if ply == self:GetDriver() then
			if ply:lvsMouseAim() then
				local LocalAngles = ply:GetVehicle():WorldToLocalAngles( ply:EyeAngles() - Angle(0,90,0) )

				ply:SetPoseParameter( "head_pitch", LocalAngles.p )
				ply:SetPoseParameter( "head_yaw", LocalAngles.y )

				ply:SetPoseParameter("aim_pitch", 0 )
				ply:SetPoseParameter("aim_yaw", 0 )
			end

			ply:SetPoseParameter( "vehicle_steer", self:GetSteer() /  self:GetMaxSteerAngle() )
			ply:InvalidateBoneCache()
		end

		GAMEMODE:GrabEarAnimation( ply )
		GAMEMODE:MouthMoveAnimation( ply )
	end

	return false
end
