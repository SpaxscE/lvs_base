
function ENT:GetEyeTrace( trace_forward )
	local startpos = self:LocalToWorld( self:OBBCenter() )

	local pod = self:GetDriverSeat()

	if IsValid( pod ) then
		startpos = pod:LocalToWorld( pod:OBBCenter() )
	end

	local AimVector = trace_forward and self:GetForward() or self:GetAimVector()

	local data = {
		start = startpos,
		endpos = (startpos + AimVector * 50000),
		filter = self:GetCrosshairFilterEnts(),
	}

	local trace = util.TraceLine( data )

	return trace
end

function ENT:GetAimVector()
	if self:GetAI() then
		return self:GetAIAimVector()
	end

	local Driver = self:GetDriver()

	if not IsValid( Driver ) then return self:GetForward() end

	if SERVER then
		local pod = self:GetDriverSeat()

		if not IsValid( pod ) then return Driver:EyeAngles():Forward() end

		return pod:WorldToLocalAngles( Driver:EyeAngles() ):Forward()
	else
		return Driver:EyeAngles():Forward()
	end
end
