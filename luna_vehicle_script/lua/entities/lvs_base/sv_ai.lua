
function ENT:RunAI()
end

function ENT:AutoAI()
	if IsValid( self._OwnerEntLVS ) then
		if self._OwnerEntLVS:InVehicle() then
			if self._OwnerEntLVS:IsAdmin() then
				self:SetAI( true )
			end
		end
	end
end

function ENT:OnCreateAI()
end

function ENT:OnRemoveAI()
end

function ENT:OnToggleAI( name, old, new)
	if new == old then return end
	
	if new == true then
		local Driver = self:GetDriver()
		
		if IsValid( Driver ) then
			Driver:ExitVehicle()
		end

		self:SetActive( true )
		self:OnCreateAI()
	else
		self:SetActive( false )
		self:OnRemoveAI()
	end
end

function ENT:AITargetInFront( ent, range )
	if not IsValid( ent ) then return false end
	if not range then range = 45 end
	
	local DirToTarget = (ent:GetPos() - self:GetPos()):GetNormalized()
	
	local InFront = math.deg( math.acos( math.Clamp( self:GetForward():Dot( DirToTarget ) ,-1,1) ) ) < range

	return InFront
end

function ENT:AICanSee( otherEnt )
	if not IsValid( otherEnt ) then return false end

	local trace = {
		start = self:LocalToWorld( self:OBBCenter() ),
		endpos = otherEnt:LocalToWorld( otherEnt:OBBCenter() ),
		mins = Vector( -10, -10, -10 ),
		maxs = Vector( 10, 10, 10 ),
		filter = self:GetCrosshairFilterEnts(),
	}

	return util.TraceHull( trace ).Entity == otherEnt
end

function ENT:AIGetTarget()
	if (self._lvsNextAICheck or 0) > CurTime() then return self._LastAITarget end

	self._lvsNextAICheck = CurTime() + 2
	
	local MyPos = self:GetPos()
	local MyTeam = self:GetAITEAM()

	if MyTeam == 0 then self._LastAITarget = NULL return NULL end

	local players = player.GetAll()

	local ClosestTarget = NULL
	local TargetDistance = 60000

	if not LVS.IgnorePlayers then
		for _, v in pairs( player.GetAll() ) do
			if not v:Alive() then continue end

			local Dist = (v:GetPos() - MyPos):Length()

			if Dist > TargetDistance then continue end

			local Veh = v:lvsGetVehicle()

			if IsValid( Veh ) then
				if self:AICanSee( Veh ) and Veh ~= self then
					local HisTeam = Veh:GetAITEAM()

					if HisTeam == 0 then continue end

					if HisTeam ~= MyTeam or HisTeam == 3 then
						ClosestTarget = v
						TargetDistance = Dist
					end
				end
			else
				local HisTeam = v:lvsGetAITeam()
				if not v:IsLineOfSightClear( self ) or HisTeam == 0 then continue end

				if HisTeam ~= MyTeam or HisTeam == 3 then
					ClosestTarget = v
					TargetDistance = Dist
				end
			end
		end
	end

	if not LVS.IgnoreNPCs then
		for _, v in pairs( LVS:GetNPCs() ) do

			local HisTeam = LVS:GetNPCRelationship( v:GetClass() )

			if HisTeam == 0 or (HisTeam == MyTeam and HisTeam ~= 3) then continue end

			local Dist = (v:GetPos() - MyPos):Length()

			if Dist > TargetDistance or not self:AICanSee( v ) then continue end

			ClosestTarget = v
			TargetDistance = Dist
		end
	end

	for _, veh in pairs( LVS:GetVehicles() ) do
		if veh == self then continue end

		local Dist = (veh:GetPos() - MyPos):Length()

		if Dist > TargetDistance or not self:AITargetInFront( veh, 100 ) then continue end

		local HisTeam = veh:GetAITEAM()

		if HisTeam == 0 then continue end

		if HisTeam == self:GetAITEAM() then
			if HisTeam ~= 3 then continue end
		end

		if self:AICanSee( veh ) then
			ClosestTarget = veh
			TargetDistance = Dist
		end
	end

	self._LastAITarget = ClosestTarget
	
	return ClosestTarget
end