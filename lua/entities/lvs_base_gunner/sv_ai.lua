
function ENT:GetAimVector()
	if self:GetAI() then
		local Dir = self._ai_look_dir or self.VectorNull

		self:SetNWAimVector( Dir )

		return Dir
	end

	local Driver = self:GetDriver()

	if IsValid( Driver ) then
		if self._AimVectorUnlocked then
			local pod = self:GetDriverSeat()

			if IsValid( pod ) then
				return pod:WorldToLocalAngles( Driver:EyeAngles() ):Forward()
			end
		end

		return Driver:GetAimVector()
	else
		return self:GetForward()
	end
end

function ENT:RunAI()
	local EntTable = self:GetTable()

	local Target = self:AIGetTarget( EntTable )

	if not IsValid( Target ) then
		EntTable._ai_look_dir = self:GetForward()
		EntTable._AIFireInput = false

		return
	end

	local TargetPos = Target:GetPos()

	if EntTable._AIFireInput then
		local T = CurTime() * 0.5 + self:EntIndex()
		local X = math.cos( T ) * 32
		local Y = math.sin( T ) * 32
		local Z = math.sin( math.cos( T / 0.5 ) * math.pi ) * 32
		TargetPos = Target:LocalToWorld( Target:OBBCenter() + Vector(X,Y,Z) )
	end

	EntTable._ai_look_dir = (TargetPos - self:GetPos()):GetNormalized()

	local StartPos = self:GetPos()

	local trace = util.TraceHull( {
		start =  StartPos,
		endpos = (StartPos + EntTable._ai_look_dir * 50000),
		mins = Vector( -50, -50, -50 ),
		maxs = Vector( 50, 50, 50 ),
		filter = self:GetCrosshairFilterEnts()
	} )

	if not self:AIHasWeapon( self:GetSelectedWeapon() ) then
		EntTable._AIFireInput = false

		return
	end

	if IsValid( trace.Entity ) and trace.Entity.GetAITEAM then
		EntTable._AIFireInput = (trace.Entity:GetAITEAM() ~= self:GetAITEAM() or trace.Entity:GetAITEAM() == 0)
	else
		EntTable._AIFireInput = true
	end
end

function ENT:AIGetTarget( EntTable )
	local Base = self:GetVehicle()

	if not IsValid( Base ) then return NULL end

	if Base:GetAI() then
		return Base:AIGetTarget()
	end

	if not isnumber( EntTable.ViewConeAdd ) then
		EntTable.ViewConeAdd = math.min( 100 + math.abs( Base:WorldToLocalAngles( self:GetAngles() ).y ), 360 )
	end

	return Base:AIGetTarget( EntTable.ViewConeAdd )
end

function ENT:AITargetInFront( ent, range )
	local Base = self:GetVehicle()

	if not IsValid( Base ) then return NULL end

	return Base:AITargetInFront( ent, range )
end

