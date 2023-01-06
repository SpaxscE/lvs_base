
AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "AI Vehicle Spammer"
ENT.Author = "Luna"
ENT.Information = "AI Vehicle Spawner. Spammer in the hands of a Minge."
ENT.Category = "[LVS]"

ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.Editable = true

function ENT:SetupDataTables()
	local AllSents = scripted_ents.GetList() 
	local SpawnOptions = {}

	for _, v in pairs( AllSents ) do
		if not v or not istable( v.t ) or not v.t.Spawnable then continue end

		if v.t.Base and (string.StartWith( v.t.Base:lower(), "lvs_base" ) or string.StartWith( v.t.Base:lower(), "lunasflightschool" )) then
			if v.t.Category and v.t.PrintName then
				local nicename = v.t.Category.." - "..v.t.PrintName
				if not table.HasValue( SpawnOptions, nicename ) then
					SpawnOptions[nicename] = v.t.ClassName
				end
			end
		end
	end

	self:NetworkVar( "String",0, "Type",	{ KeyName = "Vehicle Type",Edit = { type = "Combo",	order = 1,values = SpawnOptions,category = "Vehicle-Options"} } )
	self:NetworkVar( "Int",3, "TeamOverride", { KeyName = "AI Team", Edit = { type = "Int", order = 4,min = -1, max = 3, category = "Vehicle-Options"} } )
	self:NetworkVar( "Int",4, "RespawnTime", { KeyName = "spawntime", Edit = { type = "Int", order = 5,min = 1, max = 120, category = "Vehicle-Options"} } )
	self:NetworkVar( "Int",5, "Amount", { KeyName = "amount", Edit = { type = "Int", order = 6,min = 1, max = 10, category = "Vehicle-Options"} } )
	self:NetworkVar( "Int",6, "SpawnWithSkin", { KeyName = "spawnwithskin", Edit = { type = "Int", order = 8,min = 0, max = 16, category = "Vehicle-Options"} } )
	self:NetworkVar( "Int",7, "SpawnWithHealth", { KeyName = "spawnwithhealth", Edit = { type = "Int", order = 9,min = 0, max = 50000, category = "Vehicle-Options"} } )
	self:NetworkVar( "Int",8, "SpawnWithShield", { KeyName = "spawnwithshield", Edit = { type = "Int", order = 10,min = 0, max = 50000, category = "Vehicle-Options"} } )

	self:NetworkVar( "Int",10, "SelfDestructAfterAmount", { KeyName = "selfdestructafteramount", Edit = { type = "Int", order = 22,min = 0, max = 100, category = "Spawner-Options"} } )
	self:NetworkVar( "Bool",2, "MasterSwitch" )

	if SERVER then
		self:NetworkVarNotify( "Type", self.OnTypeChanged )

		self:SetRespawnTime( 2 )
		self:SetAmount( 1 )
		self:SetSelfDestructAfterAmount( 0 )
		self:SetSpawnWithHealth( 0 )
		self:SetSpawnWithShield( 0 )
		self:SetTeamOverride( -1 )
	end
end

if SERVER then
	function ENT:SpawnFunction( ply, tr, ClassName )
		if not tr.Hit then return end

		local ent = ents.Create( ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal * 1 )
		ent:Spawn()
		ent:Activate()

		return ent

	end

	function ENT:OnTakeDamage( dmginfo )
	end

	function ENT:Initialize()	
		self:SetModel( "models/hunter/plates/plate8x8.mdl" )
		
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:DrawShadow( false )

		self:SetCollisionGroup( COLLISION_GROUP_WORLD )
		
		self.NextSpawn = 0
	end

	function ENT:Use( ply )
		if not IsValid( ply ) then return end

		if not IsValid( self.Defusor ) then
			self.Defusor = ply
			self.DefuseTime = CurTime()
		end
	end
	
	function ENT:Think()
		if IsValid( self.Defusor ) and isnumber( self.DefuseTime ) then
			if self.Defusor:KeyDown( IN_USE ) then
				if CurTime() - self.DefuseTime > 1 then
					self:SetMasterSwitch( not self:GetMasterSwitch() )

					for k, v in pairs( ents.FindByClass( "lvs_vehicle_spammer" ) ) do
						if v ~= self and IsValid( v ) then
							v:SetMasterSwitch( self:GetMasterSwitch() )
						end
					end

					if self:GetMasterSwitch() then
						self.Defusor:PrintMessage( HUD_PRINTTALK, "ALL AI-Spawners Enabled")
					else
						self.Defusor:PrintMessage( HUD_PRINTTALK, "ALL AI-Spawners Disabled")
					end

					self.Defusor = nil
				end
			else
				self:SetMasterSwitch( not self:GetMasterSwitch() )

				if self:GetMasterSwitch() then
					self.Defusor:PrintMessage( HUD_PRINTTALK, "AI-Spawner Enabled")
				else
					self.Defusor:PrintMessage( HUD_PRINTTALK, "AI-Spawner Disabled")
				end

				self.Defusor = nil
			end
		end

		if not self:GetMasterSwitch() then return end

		self.spawnedvehicles = self.spawnedvehicles or {}

		if self.ShouldSpawn then
			if self.NextSpawn < CurTime() then
				
				self.ShouldSpawn = false
				
				local pos = self:LocalToWorld( Vector( 0, 0, 150 ) )
				local ang = self:LocalToWorldAngles( Angle( 0, 90, 0 ) )
				
				local Type = self:GetType()
				
				if Type ~= "" then
					local spawnedvehicle = ents.Create( Type )
					
					if IsValid( spawnedvehicle ) then
						spawnedvehicle:SetPos( pos )
						spawnedvehicle:SetAngles( ang )
						spawnedvehicle:Spawn()
						spawnedvehicle:Activate()
						spawnedvehicle:SetAI( true )
						spawnedvehicle:SetSkin( self:GetSpawnWithSkin() )

						if self:GetTeamOverride() >= 0 then
							spawnedvehicle:SetAITEAM( self:GetTeamOverride() )
						end

						if self:GetSpawnWithHealth() > 0 then
							spawnedvehicle.MaxHealth = self:GetSpawnWithHealth()
							spawnedvehicle:SetHP( self:GetSpawnWithHealth() )
						end
	
						if self:GetSpawnWithShield() > 0 then
							spawnedvehicle.MaxShield = self:GetSpawnWithShield()
							spawnedvehicle:SetShield( self:GetSpawnWithShield() )
						end

						if spawnedvehicle.LFS and not spawnedvehicle.DontPushMePlease then
							local PhysObj = spawnedvehicle:GetPhysicsObject()
							
							if IsValid( PhysObj ) then
								PhysObj:SetVelocityInstantaneous( -self:GetRight() * 1000 )
							end
						end

						table.insert( self.spawnedvehicles, spawnedvehicle )

						if self:GetSelfDestructAfterAmount() > 0 then
							self.RemoverCount = isnumber( self.RemoverCount ) and self.RemoverCount + 1 or 1

							if self.RemoverCount >= self:GetSelfDestructAfterAmount() then
								self:Remove()
							end
						end
					end
				end
			end
		else
			local AmountSpawned = 0
			for k,v in pairs( self.spawnedvehicles ) do
				if IsValid( v ) then
					AmountSpawned = AmountSpawned + 1
				else
					self.spawnedvehicles[k] = nil
				end
			end

			if AmountSpawned < self:GetAmount() then
				self.ShouldSpawn = true
				self.NextSpawn = CurTime() + self:GetRespawnTime()
			end
		end

		self:NextThink( CurTime() )

		return true
	end
end

if CLIENT then
	local WhiteList = {
		["weapon_physgun"] = true,
		["weapon_physcannon"] = true,
		["gmod_tool"] = true,
	}

	local TutorialDone = false
	local mat = Material( "models/wireframe" )
	local FrameMat = Material( "lvs/3d2dmats/frame.png" )
	local ArrowMat = Material( "lvs/3d2dmats/arrow.png" )

	function ENT:Draw()
		local ply = LocalPlayer()

		if not IsValid( ply ) then return end

		if TutorialDone then
			if GetConVarNumber( "cl_draweffectrings" ) == 0 then return end

			local wep = ply:GetActiveWeapon()

			if not IsValid( wep ) then return end

			local weapon_name = wep:GetClass()

			if not WhiteList[ weapon_name ] then
				return
			end
		else
			local wep = ply:GetActiveWeapon()

			if not IsValid( wep ) then return end

			local weapon_name = wep:GetClass()

			if not WhiteList[ weapon_name ] then
				if weapon_name == "gmod_camera" then return end

				local Trace = ply:GetEyeTrace()
				if Trace.Entity ~= self or (ply:GetShootPos() - Trace.HitPos):Length() > 800 then return end
			end
		end

		local Pos = self:GetPos()
		local R = 190
		render.SetMaterial( mat )
		render.DrawBox( Pos, self:GetAngles(), Vector(-R,-R,0), Vector(R,R,200), color_white )

		for i = 0, 180, 180 do
			cam.Start3D2D( Pos, self:LocalToWorldAngles( Angle(i,0,0) ), 0.185 )
				if self:GetMasterSwitch() then
					local T4 = CurTime() * 4

					local OY = math.cos( T4 )
					local A = math.max( math.sin( T4 ), 0 )
		
					surface.SetMaterial( ArrowMat )

					if self:GetType() == "" then
						surface.SetDrawColor( 255, 0, 0, A * 255 )
						surface.DrawTexturedRect( -512, -512 + OY * 512, 1024, 1024 )

						surface.SetDrawColor( 255, 0, 0, math.abs( math.cos( T4 ) ) ^ 2 * 255  )
					else
						surface.SetDrawColor( 0, 127, 255, A * 255 )
						surface.DrawTexturedRect( -512, -512 + OY * 512, 1024, 1024 )

						surface.SetDrawColor( 0, 127, 255, 255 )
					end
				else
					surface.SetDrawColor( 255, 0, 0, 255 )
		
					surface.SetMaterial( ArrowMat )
					surface.DrawTexturedRect( -512, -512, 1024, 1024 )
				end

				surface.SetMaterial( FrameMat )
				surface.DrawTexturedRect( -1024, -1024, 2048, 2048 )
			cam.End3D2D()
		end
	end

	hook.Add( "HUDPaint", "!!!!!!!11111lvsvehiclespammer_tutorial", function()
		if TutorialDone then
			hook.Remove( "HUDPaint", "!!!!!!!11111lvsvehiclespammer_tutorial" )
		end

		local ply = LocalPlayer()

		if ply:InVehicle() then return end

		local trace = ply:GetEyeTrace()
		local Dist = (ply:GetShootPos() - trace.HitPos):Length()

		if Dist > 800 then return end

		local Ent = trace.Entity

		if not IsValid( Ent ) then return end

		if Ent:GetClass() ~= "lvs_vehicle_spammer" then return end

		local pos = Ent:GetPos()
		local scr = pos:ToScreen()
		local Alpha = 255

		if Ent:GetType() == "" then
			draw.SimpleText( "Hold C => Right Click on me => Edit Properties => Choose a Type", "LVS_FONT", scr.x, scr.y - 10, Color(255,255,255,Alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		else
			if not Ent:GetMasterSwitch() then
				local Key = input.LookupBinding( "+use" )
				if not isstring( Key ) then Key = "+use is not bound to a key" end

				draw.SimpleText( "Now press ["..Key.."] to enable!", "LVS_FONT", scr.x, scr.y - 10, Color(255,255,255,Alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				draw.SimpleText( "or hold ["..Key.."] to enable globally!", "LVS_FONT", scr.x, scr.y + 10, Color(255,255,255,Alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			else
				TutorialDone = true
			end
		end
	end )
end