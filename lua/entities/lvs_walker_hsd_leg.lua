AddCSLuaFile()

ENT.Type            = "anim"

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
	self:NetworkVar( "String",0, "LocationIndex" )
end

if SERVER then
	function ENT:Initialize()	
		self:SetModel( "models/blu/hsd_leg_1.mdl" )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
	end

	function ENT:Think()
		return false
	end
else 
	include( "entities/lvs_walker_atte/cl_ikfunctions.lua" )

	local Length1 = 140
	local Length2 = 300

	local Length3 = 20
	local Length4 = 20

	local LegData1 = {
		Leg1 = {MDL = "models/blu/hsd_leg_2.mdl", Ang = Angle(0,-90,-90), Pos = Vector(0,0,0)},
		Leg2 = {MDL = "models/blu/hsd_leg_4.mdl", Ang = Angle(180,90,4), Pos = Vector(20,0,-12)},
		Foot = {MDL = "models/blu/hsd_foot.mdl", Ang = Angle(0,0,0), Pos = Vector(0,-2,0)}
	}

	local LegData2 = {
		Leg1 = {MDL = "models/blu/hsd_leg_3.mdl", Ang = Angle(0,90,-90), Pos = Vector(0,0,0)},
	}

	local StartPositions = {
		["FL"] = Vector(150,270,0),
		["FR"] = Vector(150,-270,0),
		["RL"] = Vector(-150,270,0),
		["RR"] = Vector(-150,-270,0),
	}

	local LocToID = {
		[1] = "RL",
		[2] = "FL",
		[3] = "RR",
		[4] = "FR",
	}

	function ENT:Think()
		local Base = self:GetBase()

		if not IsValid( Base ) then return end

		if Base:GetIsRagdoll() then 
			self:LegClearAll()

			return
		end

		local LocIndex = self:GetLocationIndex()

		if not Base:HitGround() then
			local Pos = Base:LocalToWorld( StartPositions[ LocIndex ] )

			self:RunIK( Pos, Base )
			self._OldPos = Pos
			self._smPos = Pos

			return
		end

		local Up = Base:GetUp()
		local Forward = Base:GetForward()
		local Vel = Base:GetVelocity()

		local Speed = Vel:Length()
		local VelForwardMul = math.min( Speed / 100, 1 )
		local VelForward = Vel:GetNormalized() * VelForwardMul + Forward * (1 - VelForwardMul)

		local TraceStart = Base:LocalToWorld( StartPositions[ LocIndex ] ) + VelForward * math.Clamp( 400 - Speed * 2, 100, 200 ) * VelForwardMul

		local trace = util.TraceLine( { 
			start = TraceStart + Vector(0,0,200),
			endpos = TraceStart - Vector(0,0,100), 
			filter = function( ent ) 
				if ent == Base or Base.HoverCollisionFilter[ ent:GetCollisionGroup() ] then return false end 

				return true
			end,
		} )

		local UpdateLeg = LocToID[ Base:GetUpdateLeg() ] == LocIndex

		self._OldPos = self._OldPos or trace.HitPos
		self._smPos = self._smPos or self._OldPos

		if self._OldUpdateLeg ~= UpdateLeg then
			self._OldUpdateLeg = UpdateLeg

			if UpdateLeg then
				self.UpdateNow = true
			end
		end

		if self.UpdateNow and not self.MoveLeg then
			sound.Play( Sound( "lvs/vehicles/hsd/hydraulic_stop0"..math.random(1,2)..".wav" ), self:GetPos(), SNDLVL_100dB )

			self.UpdateNow = nil
			self.MoveLeg = true
			self.MoveDelta = 0
		end

		local ShaftOffset = 0
		local ENDPOS = self._smPos + Up * 20

		if self.MoveLeg then
			local traceWater = util.TraceLine( {
				start = TraceStart + Vector(0,0,200),
				endpos = ENDPOS,
				filter = Base:GetCrosshairFilterEnts(),
				mask = MASK_WATER,
			} )

			if traceWater.Hit then
				local T = CurTime()

				if (self._NextFX or 0) < T then
					self._NextFX = T + 0.05
	
					local effectdata = EffectData()
						effectdata:SetOrigin( traceWater.HitPos )
						effectdata:SetEntity( Base )
						effectdata:SetMagnitude( 50 )
					util.Effect( "lvs_hover_water", effectdata )
				end
			end

			if self.MoveDelta >= 1 then
				self.MoveLeg = false
				self.MoveDelta = nil

				sound.Play( Sound( "lvs/vehicles/hsd/footstep0"..math.random(1,3)..".wav" ), ENDPOS, SNDLVL_100dB )

				local effectdata = EffectData()
					effectdata:SetOrigin( trace.HitPos )
				util.Effect( "lvs_walker_stomp", effectdata )

				sound.Play( Sound( "lvs/vehicles/hsd/hydraulic_start0"..math.random(1,2)..".wav" ), self:GetPos(), SNDLVL_100dB )
			else
				self.MoveDelta = math.min( self.MoveDelta + RealFrameTime() * 2, 1 )
	
				self._smPos = LerpVector( self.MoveDelta, self._OldPos, trace.HitPos )

				local MulZ =  math.max( math.sin( self.MoveDelta * math.pi ), 0 )

				ShaftOffset = MulZ ^ 2 * 30
				ENDPOS = ENDPOS + Up * MulZ * 50
			end
		else
			self._OldPos = self._smPos
		end

		self:RunIK( ENDPOS, Base, ShaftOffset )
	end

	function ENT:RunIK( ENDPOS, Base, shaftoffset )
		shaftoffset = shaftoffset or 0

		local Ang = Base:WorldToLocalAngles( (ENDPOS - self:GetPos()):Angle() )

		self:SetAngles( Base:LocalToWorldAngles( Angle(0,Ang.y + 90,0) ) )

		local ID = self:LookupAttachment( "lower" )
		local Att = self:GetAttachment( ID )

		if not Att then return end

		local Pos, Ang = WorldToLocal( ENDPOS, (ENDPOS - Att.Pos):Angle(), Att.Pos, self:LocalToWorldAngles( Angle(0,-90,0) ) )

		local STARTPOS = Att.Pos

		self:GetLegEnts( 1, Length1, Length2, self:LocalToWorldAngles( Angle(0,180,135) ), STARTPOS, ENDPOS, LegData1 )

		if not self.IK_Joints[ 1 ] or not IsValid( self.IK_Joints[ 1 ].Attachment2 ) then return end

		local shaft = self.IK_Joints[ 1 ].Attachment2

		shaft:SetPoseParameter( "extrude", shaftoffset )
		shaft:InvalidateBoneCache()

		local ID1 = self:LookupAttachment( "upper" )
		local Start = self:GetAttachment( ID1 )

		if not Start then return end

		local ID2 = shaft:LookupAttachment( "upper_end" )
		local End = shaft:GetAttachment( ID2 )

		if not End then return end

		self:GetLegEnts( 2, Length3, Length4, self:LocalToWorldAngles( Angle(0,0,-45) ), Start.Pos, End.Pos, LegData2 )

		if not self.IK_Joints[ 2 ] or not IsValid( self.IK_Joints[ 2 ].Attachment1 ) then return end

		local strut = self.IK_Joints[ 2 ].Attachment1
		strut:SetPoseParameter( "extrude", (Start.Pos - End.Pos):Length() )
		strut:InvalidateBoneCache()
	end

	function ENT:OnRemove()
		self:OnRemoved()
	end

	function ENT:Draw()
		local Base = self:GetBase()

		if not IsValid( Base ) then return end

		if Base:GetIsRagdoll() then return end

		self:DrawModel()
	end
end