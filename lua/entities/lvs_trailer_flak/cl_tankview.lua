
include("entities/lvs_tank_wheeldrive/modules/cl_tankview.lua")

function ENT:TankViewOverride( ply, pos, angles, fov, pod )
	if ply == self:GetDriver() and not pod:GetThirdPersonMode() then
		local ID1 = self:LookupAttachment( "seat" )
		local ID2 = self:LookupAttachment( "muzzle" )

		local Att1 = self:GetAttachment( ID1 )
		local Att2 = self:GetAttachment( ID2 )

		if Att1 and Att2 then
			local dir = Att2.Ang:Right()
			pos =  Att1.Pos - Att1.Ang:Right() * 27 + dir * 1.5
		end

	end

	return pos, angles, fov
end
