
function ENT:RunAI()
end

function ENT:AutoAI()
	if not IsValid( self._OwnerEntLVS ) then return end

	if self._OwnerEntLVS:InVehicle() then
		if self._OwnerEntLVS:IsAdmin() then
			self:SetAI( true )
		end
	end
end

function ENT:OnCreateAI()
end

function ENT:OnRemoveAI()
end

function ENT:OnToggleAI( name, old, new )
	if new == old then return end

	if not self:IsInitialized() then
		timer.Simple( FrameTime(), function()
			if not IsValid( self ) then return end

			self:OnToggleAI( name, old, new )
		end )

		return
	end

	self:SetAIGunners( new )

	if new == true then
		local Driver = self:GetDriver()
		
		if IsValid( Driver ) then
			Driver:ExitVehicle()
		end

		self:SetActive( true )
		self:OnCreateAI()

		hook.Run( "LVS.UpdateRelationship", self )
	else
		self:SetActive( false )
		self:OnRemoveAI()
	end
end

function ENT:OnAITakeDamage( dmginfo )
end

function ENT:AITargetInFront( ent, range )
	if not IsValid( ent ) then return false end

	if not range then range = 45 end

	if range >= 180 then return true end

	local DirToTarget = (ent:GetPos() - self:GetPos()):GetNormalized()

	local InFront = math.deg( math.acos( math.Clamp( self:GetForward():Dot( DirToTarget ) ,-1,1) ) ) < range

	return InFront
end

function ENT:AICanSee( otherEnt )
	if not IsValid( otherEnt ) then return false end

	local PhysObj = otherEnt:GetPhysicsObject()

	if IsValid( PhysObj ) then
		local trace = {
			start = self:LocalToWorld( self:OBBCenter() ),
			endpos = otherEnt:LocalToWorld( PhysObj:GetMassCenter() ),
			filter = self:GetCrosshairFilterEnts(),
		}

		return util.TraceLine( trace ).Entity == otherEnt
	end

	local trace = {
		start = self:LocalToWorld( self:OBBCenter() ),
		endpos = otherEnt:LocalToWorld( otherEnt:OBBCenter() ),
		filter = self:GetCrosshairFilterEnts(),
	}

	return util.TraceLine( trace ).Entity == otherEnt
end

function ENT:AIGetTarget( viewcone )
	if (self._lvsNextAICheck or 0) > CurTime() then return self._LastAITarget end

	self._lvsNextAICheck = CurTime() + 2
	
	local MyPos = self:GetPos()
	local MyTeam = self:GetAITEAM()

	if MyTeam == 0 then self._LastAITarget = NULL return NULL end

	local ClosestTarget = NULL
	local TargetDistance = 60000

	if not LVS.IgnorePlayers then
		for _, ply in pairs( player.GetAll() ) do
			if not ply:Alive() then continue end

			if ply:IsFlagSet( FL_NOTARGET ) then continue end

			local Dist = (ply:GetPos() - MyPos):Length()

			if Dist > TargetDistance then continue end

			local Veh = ply:lvsGetVehicle()

			if IsValid( Veh ) then
				if self:AICanSee( Veh ) and Veh ~= self then
					local HisTeam = Veh:GetAITEAM()

					if HisTeam == 0 then continue end

					if self.AISearchCone then
						if not self:AITargetInFront( Veh, self.AISearchCone ) then continue end
					end

					if HisTeam ~= MyTeam or HisTeam == 3 then
						ClosestTarget = Veh
						TargetDistance = Dist
					end
				end
			else
				local HisTeam = ply:lvsGetAITeam()
				if not ply:IsLineOfSightClear( self ) or HisTeam == 0 then continue end

				if self.AISearchCone then
					if not self:AITargetInFront( ply, self.AISearchCone ) then continue end
				end
				
				if HisTeam ~= MyTeam or HisTeam == 3 then
					ClosestTarget = ply
					TargetDistance = Dist
				end
			end
		end
	end

	if not LVS.IgnoreNPCs then
		for _, npc in pairs( LVS:GetNPCs() ) do
			local HisTeam = LVS:GetNPCRelationship( npc:GetClass() )

			if HisTeam == 0 or (HisTeam == MyTeam and HisTeam ~= 3) then continue end

			local Dist = (npc:GetPos() - MyPos):Length()

			if Dist > TargetDistance or not self:AICanSee( npc ) then continue end

			if self.AISearchCone then
				if not self:AITargetInFront( npc, self.AISearchCone ) then continue end
			end

			ClosestTarget = npc
			TargetDistance = Dist
		end
	end

	for _, veh in pairs( LVS:GetVehicles() ) do
		if veh:IsDestroyed() then continue end

		if veh == self then continue end

		local Dist = (veh:GetPos() - MyPos):Length()

		if Dist > TargetDistance or not self:AITargetInFront( veh, (viewcone or 100) ) then continue end

		local HisTeam = veh:GetAITEAM()

		if HisTeam == 0 then continue end

		if HisTeam == self:GetAITEAM() then
			if HisTeam ~= 3 then continue end
		end

		if self.AISearchCone then
			if not self:AITargetInFront( veh, self.AISearchCone ) then continue end
		end

		if self:AICanSee( veh ) then
			ClosestTarget = veh
			TargetDistance = Dist
		end
	end

	self._LastAITarget = ClosestTarget
	
	return ClosestTarget
end

function ENT:IsEnemy( ent )
	if not IsValid( ent ) then return false end

	local HisTeam = 0

	if ent:IsNPC() then
		HisTeam = LVS:GetNPCRelationship( ent:GetClass() )
	end

	if ent:IsPlayer() then
		if ent:IsFlagSet( FL_NOTARGET ) then return false end

		local veh = ent:lvsGetVehicle()
		if IsValid( veh ) then
			HisTeam = veh:GetAITEAM()
		else
			HisTeam = ent:lvsGetAITeam()
		end
	end

	if ent.LVS and ent.GetAITEAM then
		HisTeam = ent:GetAITEAM()
	end

	if HisTeam == 0 then return false end

	if HisTeam == 3 then return true end

	return HisTeam ~= self:GetAITEAM()
end