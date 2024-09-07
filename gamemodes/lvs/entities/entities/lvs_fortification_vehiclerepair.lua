AddCSLuaFile()

ENT.Base = "lvs_fortification_vehicleblocker"

DEFINE_BASECLASS( "lvs_fortification" )

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

		if entity:GetHP() ~= entity:GetMaxHP() then
			entity:SetHP( entity:GetMaxHP() )

			Repaired = true
		end

		if entity:OnArmorMaintenance() then
			Repaired = true
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

	function ENT:Initialize()
		self.PixVis = util.GetPixelVisibleHandle()
	end

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

	local BorderDist = 40
	local ArrowMat = Material( "lvs/3d2dmats/arrow.png" )
	local ArrowCol = Color(200,200,200,100)

	hook.Add( "HUDPaint", "!!!draw_vehicle_repair_info", function()
		local ply = LocalPlayer()

		if not IsValid( ply ) or not ply:InVehicle() then return end

		local veh = ply:lvsGetVehicle()

		if not IsValid( veh ) or ply:GetVehicle() ~= veh:GetDriverSeat() then return end

		local ShouldBother = veh:GetHP() < veh:GetMaxHP()

		local maxX = ScrW()
		local maxY = ScrH()

		local EyeAng
		local StartPos = veh:GetPos()

		local pod = ply:GetVehicle()

		local Team = ply:lvsGetAITeam()

		if IsValid( pod ) and pod ~= veh:GetDriverSeat() then
			local weapon = pod:lvsGetWeapon()

			if IsValid( weapon ) then
				EyeAng = weapon:GetAimVector():Angle()
			else
				EyeAng = ply:EyeAngles()
			end
		else
			if veh.GetAimVector then
				EyeAng = veh:GetAimVector():Angle()
			else
				EyeAng = ply:EyeAngles()
			end
		end

		for _, ent in pairs( ents.FindByClass("lvs_fortification_vehiclerepair") ) do
			if ent:GetAITEAM() ~= Team then continue end

			local pos = ent:GetPos()
			local scr = pos:ToScreen()

			local X = math.Clamp( scr.x, BorderDist , maxX - BorderDist  )
			local Y = math.Clamp( scr.y, BorderDist , maxY - BorderDist )

			if X == BorderDist  or X == (maxX - BorderDist ) or Y == BorderDist  or Y == (maxY - BorderDist ) then

				if not ShouldBother then continue end

				local WorldAng = (pos - StartPos):Angle()
				WorldAng:Normalize()

				local _, LAng = WorldToLocal( vector_origin, WorldAng, vector_origin, Angle(0,EyeAng.y,0) )

				local newX = maxX * 0.5 - math.sin( math.rad( LAng.y ) ) * (maxX * 0.5 - 16)
				local newY = maxY * 0.5 - math.cos( math.rad( LAng.y ) ) * (maxY * 0.5 - 16)

				surface.SetDrawColor( ArrowCol )
				surface.SetMaterial( ArrowMat )
				surface.DrawTexturedRectRotated( newX, newY, 32, 32, LAng.y )

				local newX2 = maxX * 0.5 - math.sin( math.rad( LAng.y ) ) * (maxX * 0.5 - 80)
				local newY2 = maxY * 0.5 - math.cos( math.rad( LAng.y ) ) * (maxY * 0.5 - 80)

				surface.SetMaterial( RepairMat )
				surface.DrawTexturedRectRotated( newX2, newY2, 128, 128, 0 )
			else
				local visible = 1
				local Sub = StartPos - pos
				local Dist = Sub:Length()

				if ent.PixVis then
					visible = util.PixelVisible( pos, 64, ent.PixVis )

					if (visible or 0) >= 0.5 and Dist < 1000 then
						continue
					end
				end

				local Col = visible < 0.5 and Color( GAMEMODE.ColorFriendDark.r, GAMEMODE.ColorFriendDark.g, GAMEMODE.ColorFriendDark.b, 100 ) or GAMEMODE.ColorFriend

				surface.SetDrawColor( Col )

				surface.SetMaterial( FrameMat )
				surface.DrawTexturedRect( X - 24, Y - 24, 48, 48 )
		
				surface.SetDrawColor( visible < 0.5 and ArrowCol or color_white )
				surface.SetMaterial( RepairMat )
				surface.DrawTexturedRect( X - 32, Y - 32, 64, 64 )

				draw.SimpleText( math.Round( Dist * 0.0254, 0 ).."m", "LVS_FONT_SWITCHER", X, Y + 24, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
			end
		end
	end )
end