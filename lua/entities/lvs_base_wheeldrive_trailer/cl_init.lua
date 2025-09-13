include("shared.lua")

function ENT:LVSHudPaintInfoText( X, Y, W, H, ScrX, ScrY, ply )
	local kmh = math.Round(self:GetVelocity():Length() * 0.09144,0)

	draw.DrawText( "km/h ", "LVS_FONT", X + 72, Y + 35, color_white, TEXT_ALIGN_RIGHT )
	draw.DrawText( kmh, "LVS_FONT_HUD_LARGE", X + 72, Y + 20, color_white, TEXT_ALIGN_LEFT )
end

-- kill engine sounds
function ENT:OnEngineActiveChanged( Active )
end

-- kill flyby system
function ENT:FlyByThink()
end

function ENT:OnFlyBy( Pitch )
end

function ENT:StopFlyBy()
end
