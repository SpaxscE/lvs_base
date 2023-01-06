AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "Maintenance Station"
ENT.Author = "Luna"
ENT.Information = "Repairs Vehicles"
ENT.Category = "[LVS]"

ENT.Spawnable		= true
ENT.AdminOnly		= false

ENT.FoundVehicles = {}

function ENT:SetupDataTables()
end

if SERVER then
	function ENT:SpawnFunction( ply, tr, ClassName )
		if not tr.Hit then return end

		local ent = ents.Create( ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal )
		ent:Spawn()
		ent:Activate()

		return ent
	end

	function ENT:OnTakeDamage( dmginfo )
	end

	function ENT:Initialize()	
		self:SetModel( "models/props_vehicles/generatortrailer01.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:DrawShadow( false )
		self:SetTrigger( true )
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )
	end

	function ENT:Refil( entity )
		if not IsValid( entity ) then return end

		if entity.LFS and entity.StartMaintenance then
			entity:StartMaintenance()
			return
		end

		if not entity.LVS then return end

		if entity:GetHP() ~= entity:GetMaxHP() then
			entity:SetHP( entity:GetMaxHP() )
			entity:EmitSound("npc/dog/dog_servo2.wav")
		end

		local AmmoIsSet = false

		for id, weapon in pairs( entity.WEAPONS ) do
			local MaxAmmo = weapon.Ammo or -1
			local CurAmmo = weapon._CurAmmo or -1

			if CurAmmo == MaxAmmo then continue end

			entity.WEAPONS[ id ]._CurAmmo = MaxAmmo

			AmmoIsSet = true
		end

		if AmmoIsSet then
			entity:EmitSound("items/ammo_pickup.wav")
			entity:SetNWAmmo( entity:GetAmmo() )
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

	function ENT:Think()
		return false
	end
end

if CLIENT then
	local WhiteList = {
		["weapon_physgun"] = true,
		["weapon_physcannon"] = true,
		["gmod_tool"] = true,
	}

	local mat = Material( "models/wireframe" )
	local FrameMat = Material( "lvs/3d2dmats/frame.png" )
	local RepairMat = Material( "lvs/3d2dmats/repair.png" )
	function ENT:Draw()
		local ply = LocalPlayer()
		local Small = false

		if IsValid( ply ) and not IsValid( ply:lvsGetVehicle() ) then
			self:DrawModel()

			Small = true

			if GetConVarNumber( "cl_draweffectrings" ) == 0 then return end

			local ply = LocalPlayer()
			local wep = ply:GetActiveWeapon()

			if not IsValid( wep ) then return end

			local weapon_name = wep:GetClass()

			if not WhiteList[ weapon_name ] then
				return
			end
		end

		local Pos = self:GetPos()

		for i = 0, 180, 180 do
			cam.Start3D2D( self:LocalToWorld( Vector(0,0, self:OBBMins().z + 2 ) ), self:LocalToWorldAngles( Angle(i,90,0) ), 0.25 )
				surface.SetDrawColor( 255, 150, 0, 255 )

				surface.SetMaterial( FrameMat )
				surface.DrawTexturedRect( -512, -512, 1024, 1024 )

				surface.SetMaterial( RepairMat )
				if Small then
					surface.DrawTexturedRect( -256, 0, 512, 512 )
				else
					surface.DrawTexturedRect( -512, -512, 1024, 1024 )
				end
			cam.End3D2D()
		end
	end

	function ENT:OnRemove()
		if IsValid( self._RepairMDL ) then
			self._RepairMDL:Remove()
		end
	end
end