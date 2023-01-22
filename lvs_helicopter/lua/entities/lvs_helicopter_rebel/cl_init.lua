include("shared.lua")

function ENT:CalcViewPassenger( ply, pos, angles, fov, pod )
	if pod == self:GetGunnerSeat() then return LVS:CalcView( self, ply, pos, angles, fov, pod ) end

	local view = {}
	view.origin = pos
	view.angles = angles
	view.fov = fov
	view.drawviewer = false

	local Pod = ply:GetVehicle()

	if not IsValid( Pod ) then return view end

	if not Pod:GetThirdPersonMode() then
		Pod:SetThirdPersonMode( true )
	end

	local radius = 800

	local TargetOrigin = self:LocalToWorld( Vector(0,0,50) ) - view.angles:Forward() * radius  + view.angles:Up() * radius * 0.2
	local WallOffset = 4

	local tr = util.TraceHull( {
		start = view.origin,
		endpos = TargetOrigin,
		filter = function( e )
			local c = e:GetClass()
			local collide = not c:StartWith( "prop_physics" ) and not c:StartWith( "prop_dynamic" ) and not c:StartWith( "prop_ragdoll" ) and not e:IsVehicle() and not c:StartWith( "gmod_" ) and not c:StartWith( "player" ) and not e.LVS
			
			return collide
		end,
		mins = Vector( -WallOffset, -WallOffset, -WallOffset ),
		maxs = Vector( WallOffset, WallOffset, WallOffset ),
	} )

	view.origin = tr.HitPos

	if tr.Hit and not tr.StartSolid then
		view.origin = view.origin + tr.HitNormal * WallOffset
	end

	return view
end

function ENT:DamageFX()
	self.nextDFX = self.nextDFX or 0

	if self.nextDFX < CurTime() then
		self.nextDFX = CurTime() + 0.05

		local HP = self:GetHP()
		local MaxHP = self:GetMaxHP()

		if HP > MaxHP * 0.25 then return end

		local effectdata = EffectData()
			effectdata:SetOrigin( self:LocalToWorld( Vector(-10,0,80) ) )
			effectdata:SetNormal( self:GetUp() )
			effectdata:SetMagnitude( math.Rand(0.5,1.5) )
			effectdata:SetEntity( self )
		util.Effect( "lvs_exhaust_fire", effectdata )
	end
end

function ENT:OnFrame()
	self:AnimRotor()
	self:DamageFX()
end

function ENT:AnimRotor()
	local RPM = self:GetThrottle() * 2500

	self.RPM = self.RPM and (self.RPM + RPM * RealFrameTime() * 0.5) or 0

	self:SetPoseParameter("rotor_spin", self.RPM )
	self:InvalidateBoneCache()
end
