AddCSLuaFile()

SWEP.DisableBallistics = true

SWEP.AmmoWarningCountClip = 1
SWEP.AmmoWarningCountMag = 4

function SWEP:GetCrosshairFilterEnts()
	return { self, self:GetOwner() }
end

if CLIENT then
	local color_red = Color(255,0,0,255)

	function SWEP:DrawAmmoInfo( X, Y, ply )
		if self.Primary.Ammo == "none" then return end

		if self.Primary.ClipSize == -1 then
			local Ammo = ply:GetAmmoCount( self.Primary.Ammo )

			local ColDyn = Ammo > self.AmmoWarningCountClip and color_white or color_red

			draw.DrawText( "AMMO ", "LVS_FONT", X + 72, Y + 35, ColDyn, TEXT_ALIGN_RIGHT )

			draw.DrawText( Ammo, "LVS_FONT_HUD_LARGE", X + 72, Y + 20, ColDyn, TEXT_ALIGN_LEFT )

			return
		end

		local Clip = self:Clip1()
		local ColDyn = Clip > 1 and color_white or color_red

		draw.DrawText( "AMMO ", "LVS_FONT", X + 72, Y + 35, ColDyn, TEXT_ALIGN_RIGHT )

		draw.DrawText( Clip, "LVS_FONT_HUD_LARGE", X + 72, Y + 20, ColDyn, TEXT_ALIGN_LEFT )

		local Ammo = ply:GetAmmoCount( self.Primary.Ammo )

		local ColDyn2 = Ammo > self.AmmoWarningCountMag and color_white or color_red

		draw.DrawText( "/", "LVS_FONT_HUD_LARGE", X + 96, Y + 30, ColDyn2, TEXT_ALIGN_LEFT )

		draw.DrawText( Ammo, "LVS_FONT", X + 110, Y + 40, ColDyn2, TEXT_ALIGN_LEFT )
	end

	return
end
