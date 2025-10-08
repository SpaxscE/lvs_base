include("shared.lua")
include("cl_effects.lua")
include("cl_skidmarks.lua")

function ENT:Initialize()
	local Mins, Maxs = self:GetRenderBounds()

	self:SetRenderBounds( Mins, Maxs, Vector( 50, 50, 50 ) )

	self:DrawShadow( false )
end

if GravHull then
	function ENT:DrawWheel( flags )
		self:SetAngles( self:LocalToWorldAngles( self:GetAlignmentAngle() ) ) -- GravHull overwrites SetRenderAngles, but SetAngles works too...

		self:DrawModel( flags )
	end
else
	function ENT:DrawWheel( flags )
		self:SetRenderAngles( self:LocalToWorldAngles( self:GetAlignmentAngle() ) )

		self:DrawModel( flags )
	end
end

function ENT:DrawWheelBroken( flags )
	local base = self:GetBase()

	if not IsValid( base ) or not LVS.MapDoneLoading then
		self:DrawModel( flags )

		return
	end

	-- Alternative method, tuning wheels... Workaround for diggers wheel pack. Flickers for some people... it is what it is
	if self:GetBoneCount() > 1 then
		local pos = self:GetPos()

		self:SetRenderOrigin( pos - base:GetUp() * base.WheelPhysicsTireHeight )
		self:DrawWheel( flags )
		self:SetRenderOrigin()

		return
	end

	-- bone position method... more reliable and works on infmap, but doesnt work on diggers wheel pack

	self:SetupBones()

	local pos, ang = self:GetBonePosition( 0 )

	if not pos then self:DrawModel( flags ) return end

	self:SetBonePosition( 0, pos - base:GetUp() * base.WheelPhysicsTireHeight, ang )

	self:DrawWheel( flags )

	self:SetBonePosition( 0, pos , ang )
end

function ENT:DrawParentedWheel( flags )
	local base = self:GetBase()

	if not IsValid( base ) or not LVS.MapDoneLoading then
		self:DrawModel( flags )

		return
	end

	local Up = base:GetUp()
	local WheelRadius = self:GetRadius()
	local MaxTravel = self:GetSuspensionTravel()

	-- Alternative method, tuning wheels... Workaround for diggers wheel pack. Flickers for some people... it is what it is
	if self:GetBoneCount() > 1 then
		local startpos = self:GetPos()

		local trace = util.TraceLine( {
			start = startpos,
			endpos = startpos - Up * MaxTravel,
			filter = base:GetCrosshairFilterEnts()
		} )

		self:SetRenderOrigin( trace.HitPos + Up * WheelRadius )
		self:DrawWheel( flags )
		self:SetRenderOrigin()

		return
	end

	-- bone position method... more reliable and works on infmap, but doesnt work on diggers wheel pack

	self:SetupBones()

	local startpos, ang = self:GetBonePosition( 0 )

	if not startpos then self:DrawModel( flags ) return end

	local trace = util.TraceLine( {
		start = startpos,
		endpos = startpos - Up * MaxTravel,
		filter = base:GetCrosshairFilterEnts()
	} )

	self:SetBonePosition( 0, trace.HitPos + Up * WheelRadius, ang )

	self:DrawWheel( flags )

	self:SetBonePosition( 0, startpos , ang )
end

function ENT:Draw( flags )
	if self:GetHideModel() then return end

	if self:IsParented() then
		self:DrawParentedWheel( flags )

		return
	end

	if self:GetNWDamaged() then

		self:DrawWheelBroken( flags )

		return
	end

	self:DrawWheel( flags )
end

function ENT:DrawTranslucent()
	self:CalcWheelEffects()
end

function ENT:Think()
	self:CalcWheelSlip()

	self:SetNextClientThink( CurTime() + 0.1 )

	return true
end

function ENT:OnRemove()
	self:StopWheelEffects()
end

function ENT:CalcWheelSlip()
	local Base = self:GetBase()

	if not IsValid( Base ) then return end

	local Vel = self:GetVelocity()
	local VelLength = Vel:Length()

	local rpmTheoretical = self:VelToRPM( VelLength )
	local rpm = math.abs( self:GetRPM() )

	self._WheelSlip = math.max( rpm - rpmTheoretical - 80, 0 ) ^ 2 + math.max( math.abs( Base:VectorSplitNormal( self:GetForward(), Vel * 4 ) ) - VelLength, 0 )
	self._WheelSkid = VelLength + self._WheelSlip
end

function ENT:GetSlip()
	return (self._WheelSlip or 0)
end

function ENT:GetSkid()
	return (self._WheelSkid or 0)
end
