AddCSLuaFile()

ENT.Base = "lvs_fortification_vehicleblocker"

DEFINE_BASECLASS( "lvs_fortification" )

local DoNotHealType = {
	["plane"] =  true,
	["helicopter"] =  true,
	["starfighter"] =  true,
	["repulsorlift"] =  true,
}
	
if SERVER then
	function ENT:Initialize()
		BaseClass.Initialize( self )

		self:DrawShadow( false )
		self:SetTrigger( true )
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )
	end

	function ENT:Refil( entity )
		if self:IsEnemy( entity ) then return end

		if not entity.LVS then return end

		local Repaired = false

		if entity.GetVehicleType and DoNotHealType[ entity:GetVehicleType() ] then
			goto SkipHeal
		end

		if entity:GetHP() ~= entity:GetMaxHP() then
			entity:SetHP( entity:GetMaxHP() )

			Repaired = true
		end

		:: SkipHeal ::

		for _, part in pairs( entity:GetChildren() ) do
			if part:GetClass() ~= "lvs_armor" then continue end

			part:OnRepaired()

			if part:GetHP() ~= part:GetMaxHP() then
				part:SetHP( part:GetMaxHP() )

				if part:GetDestroyed() then part:SetDestroyed( false ) end

				Repaired = true
			end
		end

		if Repaired then
			entity:EmitSound("npc/dog/dog_servo2.wav")
		end

		if entity:WeaponRestoreAmmo() then
			entity:EmitSound("items/ammo_pickup.wav")
		end

		entity:OnMaintenance()
	end

	function ENT:StartTouch( entity )
		self:Refil( entity )
	end

	function ENT:EndTouch( entity )
		self:Refil( entity )
	end

	function ENT:Touch( entity )
	end

end

if CLIENT then
	local FrameMat = Material( "lvs/3d2dmats/frame.png" )
	local RepairMat = Material( "lvs/3d2dmats/repair.png" )

	function ENT:Draw( flags )
		cam.Start3D2D( self:LocalToWorld( Vector(0,0, self:OBBMins().z + 2 ) ), self:LocalToWorldAngles( Angle(0,-90,0) ), 0.2 )
			surface.SetDrawColor( self:GetTeamColor() )

			surface.SetMaterial( FrameMat )
			surface.DrawTexturedRect( -512, -512, 1024, 1024 )

			if not self:IsEnemy( LocalPlayer() ) then
				surface.SetMaterial( RepairMat )
				surface.SetDrawColor( color_white )
				surface.DrawTexturedRect( -512, -512, 1024, 1024 )
			end

			surface.SetMaterial( RepairMat )
			surface.DrawTexturedRect( -512, -512, 1024, 1024 )
	
		cam.End3D2D()
	end
end