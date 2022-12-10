include("shared.lua")
include("sh_func.lua")

ENT.IconVehicleLocked = Material( "lvs_locked.png" )

function ENT:LVSHudPaint( X, Y, ply )
	local Throttle = math.Round(self:GetThrottle() * 100,0)
	local speed = math.Round( self:GetVelocity():Length() * 0.09144,0)

	draw.SimpleText( "THR", "LVS_FONT", 10, 10, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	draw.SimpleText( Throttle.."%" , "LVS_FONT", 120, 10, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

	draw.SimpleText( "IAS", "LVS_FONT", 10, 35, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	draw.SimpleText( speed.."km/h", "LVS_FONT", 120, 35, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
end

function ENT:LVSHudPaintSeatSwitcher( X, Y, ply )
	local pSeats = self:GetPassengerSeats()
	local SeatCount = table.Count( pSeats ) 

	if SeatCount <= 0 then return end

	pSeats[0] = self:GetDriverSeat()

	draw.NoTexture() 

	local MySeat = ply:GetVehicle():GetNWInt( "pPodIndex", -1 )

	local Passengers = {}
	for _, player in pairs( player.GetAll() ) do
		if player:lvsGetVehicle() == self then
			local Pod = player:GetVehicle()
			Passengers[ Pod:GetNWInt( "pPodIndex", -1 ) ] = player:GetName()
		end
	end
	if self:GetAI() then
		Passengers[1] = "[AI] "..self.PrintName
	end

	ply.SwitcherTime = ply.SwitcherTime or 0
	ply._lvsoldPassengers = ply._lvsoldPassengers or {}

	local Time = CurTime()
	for k, v in pairs( Passengers ) do
		if ply._lvsoldPassengers[k] ~= v then
			ply._lvsoldPassengers[k] = v
			ply.SwitcherTime = Time + 2
		end
	end
	for k, v in pairs( ply._lvsoldPassengers ) do
		if not Passengers[k] then
			ply._lvsoldPassengers[k] = nil
			ply.SwitcherTime = Time + 2
		end
	end
	for _, v in pairs( LVS.pSwitchKeysInv ) do
		if input.IsKeyDown(v) then
			ply.SwitcherTime = Time + 2
		end
	end

	local Hide = ply.SwitcherTime > Time

	ply.smHider = ply.smHider and (ply.smHider + ((Hide and 1 or 0) - ply.smHider) * RealFrameTime() * 15) or 0

	local Alpha1 = 135 + 110 * ply.smHider 
	local HiderOffset = 300 * ply.smHider
	local Offset = -50
	local yPos = Y - (SeatCount + 1) * 30 - 10

	for _, Pod in pairs( pSeats ) do
		local I = Pod:GetNWInt( "pPodIndex", -1 )
		if I >= 0 then
			if I == MySeat then
				draw.RoundedBox(5, X + Offset - HiderOffset, yPos + I * 30, 35 + HiderOffset, 25, Color(LVS.ThemeColor.r, LVS.ThemeColor.g, LVS.ThemeColor.b,100 + 50 * ply.smHider) )
			else
				draw.RoundedBox(5, X + Offset - HiderOffset, yPos + I * 30, 35 + HiderOffset, 25, Color(0,0,0,100 + 50 * ply.smHider) )
			end
			if I == SeatCount then
				if self:GetlvsLockedStatus() then
					surface.SetDrawColor( 255, 255, 255, 255 )
					surface.SetMaterial( self.IconVehicleLocked  )
					surface.DrawTexturedRect( X + Offset - HiderOffset - 25, yPos + I * 30, 25, 25 )
				end
			end
			if Hide then
				if Passengers[I] then
					draw.DrawText( Passengers[I], "LVS_FONT_SWITCHER", X + 40 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255,  Alpha1 ), TEXT_ALIGN_LEFT )
				else
					draw.DrawText( "-", "LVS_FONT_SWITCHER", X + 40 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255,  Alpha1 ), TEXT_ALIGN_LEFT )
				end
				
				draw.DrawText( "["..I.."]", "LVS_FONT_SWITCHER", X + 17 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255, Alpha1 ), TEXT_ALIGN_CENTER )
			else
				if Passengers[I] then
					draw.DrawText( "[^"..I.."]", "LVS_FONT_SWITCHER", X + 17 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255, Alpha1 ), TEXT_ALIGN_CENTER )
				else
					draw.DrawText( "["..I.."]", "LVS_FONT_SWITCHER", X + 17 + Offset - HiderOffset, yPos + I * 30 + 2.5, Color( 255, 255, 255, Alpha1 ), TEXT_ALIGN_CENTER )
				end
			end
		end
	end
end

function ENT:LVSCalcView( ply, pos, angles, fov, pod )
	return LVS:CalcView( self, ply, pos, angles, fov, pod )
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:DrawTranslucent()
end

function ENT:Initialize()
end

function ENT:OnFrame()
end

function ENT:OnActiveChanged( Active )
	if Active then
		self:StartWindSounds()
	else
		self:StopWindSounds()
	end
end

function ENT:OnEngineActiveChanged( Active )
end

function ENT:StartWindSounds()
	self._WindSFX = CreateSound( self, "LVS.Physics.Wind" )
	self._WindSFX:PlayEx(0,100)

	self._WaterSFX = CreateSound( self, "LVS.Physics.Water" )
	self._WaterSFX:PlayEx(0,100)
end

function ENT:StopWindSounds()
	if self._WindSFX then
		self._WindSFX:Stop()
		self._WindSFX = nil
	end

	if self._WaterSFX then
		self._WaterSFX:Stop()
		self._WaterSFX = nil
	end
end

function ENT:HandleActive()
	local Active = self:GetActive()
	local EngineActive = self:GetEngineActive()

	if self._oldActive ~= Active then
		self._oldActive = Active
		self:OnActiveChanged( Active )
	end

	if self._oldEnActive ~= EngineActive then
		self._oldEnActive = EngineActive
		self:OnEngineActiveChanged( EngineActive )
	end

	return Active
end

function ENT:Think()
	if self:HandleActive() then
		self:DoVehicleFX()
	end

	self:OnFrame()
end

function ENT:DoVehicleFX()
	local Vel = self:GetVelocity():Length()

	if self._WindSFX then self._WindSFX:ChangeVolume( math.Clamp( (Vel - 1200) / 2800,0,1 ), 0.25 ) end

	if Vel < 1500 then
		if self._WaterSFX then self._WaterSFX:ChangeVolume( 0, 0.25 ) end

		return
	end

	if (self.nextFX or 0) < CurTime() then
		self.nextFX = CurTime() + 0.05

		local CenterPos = self:LocalToWorld( self:OBBCenter() )

		local trace = util.TraceLine( {
			start = CenterPos + Vector(0,0,25),
			endpos = CenterPos - Vector(0,0,450),
			filter = self:GetCrosshairFilterEnts(),
		} )

		local traceWater = util.TraceLine( {
			start = CenterPos + Vector(0,0,25),
			endpos = CenterPos - Vector(0,0,450),
			filter = self:GetCrosshairFilterEnts(),
			mask = MASK_WATER,
		} )

		if traceWater.Hit and trace.HitPos.z < traceWater.HitPos.z then 
			local effectdata = EffectData()
				effectdata:SetOrigin( traceWater.HitPos )
				effectdata:SetEntity( self )
			util.Effect( "lvs_physics_water", effectdata )

			if self._WaterSFX then self._WaterSFX:ChangeVolume( 1, 1 ) end
		else
			if self._WaterSFX then self._WaterSFX:ChangeVolume( 0, 0.25 ) end
		end

		if trace.Hit then
			local effectdata = EffectData()
				effectdata:SetOrigin( trace.HitPos )
				effectdata:SetEntity( self )
			util.Effect( "lvs_physics_dust", effectdata )
		end
	end
end

function ENT:GetParticleEmitter( Pos )
	if self.Emitter then
		if self.EmitterTime > CurTime() then
			return self.Emitter
		end
	end

	if IsValid( self.Emitter ) then
		self.Emitter:Finish()
	end

	self.Emitter = ParticleEmitter( Pos, false )
	self.EmitterTime = CurTime() + 2

	return self.Emitter
end

function ENT:OnRemove()
	self:StopSounds()
	self:StopEmitter()
	self:StopWindSounds()
end

function ENT:StopSounds()
end

function ENT:StopEmitter()
	if IsValid( self.Emitter ) then
		self.Emitter:Finish()
	end
end

function ENT:GetCrosshairFilterEnts()
	if not istable( self.CrosshairFilterEnts ) then
		self.CrosshairFilterEnts = {self}

		-- lets ask the server to build the filter for us because it has access to constraint.GetAllConstrainedEntities() 
		net.Start( "lvs_player_request_filter" )
			net.WriteEntity( self )
		net.SendToServer()
	end

	return self.CrosshairFilterEnts
end
