
function ENT:GetAimVector()
	if self:GetAI() then
		local Dir = self._ai_look_dir or self.VectorNull

		self:SetNWAimVector( Dir )

		return Dir
	end

	local Driver = self:GetDriver()

	if IsValid( Driver ) then
		return Driver:GetAimVector()
	else
		return self.VectorNull
	end
end

function ENT:AITargetInFront( ent, range )
	if not IsValid( ent ) then return false end

	if not range then range = 45 end

	local DirToTarget = (ent:GetPos() - self:GetPos()):GetNormalized()

	local InFront = math.deg( math.acos( math.Clamp( self:GetForward():Dot( DirToTarget ) ,-1,1) ) ) < range

	return InFront
end

function ENT:RunAI()
	local Target = self:AIGetTarget()

	if not IsValid( Target ) then
		self._ai_look_dir = self:GetForward()
		self._AIFireInput = false

		return
	end

	self._ai_look_dir = (Target:GetPos() - self:GetPos()):GetNormalized()

	local StartPos = self:GetPos()

	local trace = util.TraceHull( {
		start =  StartPos,
		endpos = (StartPos + self._ai_look_dir * 50000),
		mins = Vector( -50, -50, -50 ),
		maxs = Vector( 50, 50, 50 ),
		filter = self:GetCrosshairFilterEnts()
	} )

	if not self:AIHasWeapon( self:GetSelectedWeapon() ) then
		self._AIFireInput = false

		return
	end

	if IsValid( trace.Entity ) and trace.Entity.GetAITEAM then
		self._AIFireInput = (trace.Entity:GetAITEAM() ~= self:GetAITEAM() or trace.Entity:GetAITEAM() == 0)
	else
		self._AIFireInput = true
	end
end

function ENT:AIGetTarget()
	local Base = self:GetVehicle()

	if not IsValid( Base ) then return NULL end

	return Base:AIGetTarget()
end
