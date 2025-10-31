
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

	if ply:GetAllowWeaponsInVehicle() then
		local pod = ply:GetVehicle()
		local AimAngles = ply:GetAimVector():Angle()

		local Ang = pod:WorldToLocalAngles( AimAngles )

		ply:SetPoseParameter( "aim_pitch", Ang.p )
		ply:SetPoseParameter( "aim_yaw", Ang.y - 90 )
	end

	ply:SetPlaybackRate( 1 )

	if CLIENT then
		if ply == self:GetDriver() then
			ply:SetPoseParameter( "vehicle_steer", self:GetSteer() /  self:GetMaxSteerAngle() )
			ply:InvalidateBoneCache()
		end

		GAMEMODE:GrabEarAnimation( ply )
		GAMEMODE:MouthMoveAnimation( ply )
	end

	return false
end
