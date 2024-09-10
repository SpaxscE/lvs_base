include("shared.lua")

function ENT:Think()
end

function ENT:OnRemove()
end

function ENT:Draw()
end

function ENT:DrawTranslucent()
end

function ENT:GetAimVector()
	if self:GetAI() then
		return self:GetNWAimVector()
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

function ENT:LVSPaintHitMarker( scr )
	local Base = self:GetVehicle()

	if not IsValid( Base ) then return end

	Base:LVSPaintHitMarker( scr )
end

function ENT:LVSDrawCircle( X, Y, target_radius, value )
	local Base = self:GetVehicle()

	if not IsValid( Base ) then return end

	Base:LVSDrawCircle( X, Y, target_radius, value )
end

function ENT:PaintCrosshairCenter( Pos2D, Col )
	local Base = self:GetVehicle()

	if not IsValid( Base ) then return end

	Base:PaintCrosshairCenter( Pos2D, Col )
end

function ENT:PaintCrosshairOuter( Pos2D, Col )
	local Base = self:GetVehicle()

	if not IsValid( Base ) then return end

	Base:PaintCrosshairOuter( Pos2D, Col )
end

function ENT:PaintCrosshairSquare( Pos2D, Col )
	local Base = self:GetVehicle()

	if not IsValid( Base ) then return end

	Base:PaintCrosshairSquare( Pos2D, Col )
end
