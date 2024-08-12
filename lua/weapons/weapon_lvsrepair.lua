AddCSLuaFile()

SWEP.Category				= "[LVS]"
SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false
SWEP.ViewModel			= "models/weapons/c_repairlvs.mdl"
SWEP.WorldModel			= "models/weapons/w_repairlvs.mdl"
SWEP.UseHands				= true

SWEP.HoldType				= "slam"

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip		= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo		= "none"

SWEP.MaxRange = 250

function SWEP:SetupDataTables()
	self:NetworkVar( "Float",0, "FlameTime" )
end

function SWEP:GetLVS()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return NULL end

	local ent = ply:GetEyeTrace().Entity

	if not IsValid( ent ) then return NULL end

	if ent.LVS then return ent end

	if not ent.GetBase then return NULL end

	ent = ent:GetBase()

	if IsValid( ent ) and ent.LVS then return ent end

	return NULL
end

function SWEP:FindClosest()
	local lvsEnt = self:GetLVS()

	if not IsValid( lvsEnt ) then return NULL end

	local ply = self:GetOwner()

	if ply:InVehicle() then return end

	local ShootPos = ply:GetShootPos()
	local AimVector = ply:GetAimVector()

	local ClosestDist = self.MaxRange
	local ClosestPiece = NULL

	for _, entity in pairs( lvsEnt:GetChildren() ) do
		if entity:GetClass() ~= "lvs_armor" then continue end

		local boxOrigin = entity:GetPos()
		local boxAngles = entity:GetAngles()
		local boxMins = entity:GetMins()
		local boxMaxs = entity:GetMaxs()

		local HitPos, _, _ = util.IntersectRayWithOBB( ShootPos, AimVector * 1000, boxOrigin, boxAngles, boxMins, boxMaxs )

		if isvector( HitPos ) then
			local Dist = (ShootPos - HitPos):Length()

			if Dist < ClosestDist then
				ClosestDist = Dist
				ClosestPiece = entity
			end
		end
	end

	return ClosestPiece
end

local function IsEngineMode( AimPos, Engine )
	if not IsValid( Engine ) then return false end

	if not isfunction( Engine.GetDoorHandler ) then return (AimPos - Engine:GetPos()):Length() < 25 end

	local DoorHandler = Engine:GetDoorHandler()

	if IsValid( DoorHandler ) then
		if DoorHandler:IsOpen() then
			return (AimPos - Engine:GetPos()):Length() < 50
		end

		return false
	end

	return (AimPos - Engine:GetPos()):Length() < 25
end

if CLIENT then
	SWEP.PrintName		= "Repair Torch"
	SWEP.Author			= "Blu-x92"

	SWEP.Slot				= 5
	SWEP.SlotPos			= 1

	SWEP.Purpose			= "Repair Broken Armor"
	SWEP.Instructions		= "Primary to Repair\nHold Secondary to switch to Armor Repair Mode"
	SWEP.DrawWeaponInfoBox 	= true

	SWEP.WepSelectIcon 			= surface.GetTextureID( "weapons/lvsrepair" )

	local ColorSelect = Color(0,255,255,50)
	local ColorText = Color(255,255,255,255)

	local function DrawText( pos, text, col )
		cam.Start2D()
			local data2D = pos:ToScreen()

			if not data2D.visible then return end

			local font = "TargetIDSmall"

			local x = data2D.x
			local y = data2D.y

			draw.DrawText( text, font, x + 1, y + 1, Color( 0, 0, 0, 120 ), TEXT_ALIGN_CENTER )
			draw.DrawText( text, font, x + 2, y + 2, Color( 0, 0, 0, 50 ), TEXT_ALIGN_CENTER )
			draw.DrawText( text, font, x, y, col or color_white, TEXT_ALIGN_CENTER )
		cam.End2D()
	end

	function SWEP:DrawEffects( weapon, ply )
		local ID = weapon:LookupAttachment( "muzzle" )

		local Muzzle = weapon:GetAttachment( ID )

		if not Muzzle then return end

		local T = CurTime()

		if self:GetFlameTime() < T or (self._NextFX1 or 0) > T then return end

		self._NextFX1 = T + 0.02

		local effectdata = EffectData()
		effectdata:SetOrigin( Muzzle.Pos )
		effectdata:SetAngles( Muzzle.Ang )
		effectdata:SetScale( 0.5 )
		util.Effect( "MuzzleEffect", effectdata, true, true )

		if (self._NextFX2 or 0) > T then return end

		self._NextFX2 = T + 0.06

		local trace = ply:GetEyeTrace()
		local ShootPos = ply:GetShootPos()

		if (ShootPos - trace.HitPos):Length() > self.MaxRange then return end

		local effectdata = EffectData()
			effectdata:SetOrigin( trace.HitPos )
			effectdata:SetNormal( trace.HitNormal * 0.15 )
		util.Effect( "manhacksparks", effectdata, true, true )

		local dlight = DynamicLight( self:EntIndex() )

		if not dlight then return end

		dlight.pos = (trace.HitPos + ShootPos) * 0.5
		dlight.r = 206
		dlight.g = 253
		dlight.b = 255
		dlight.brightness = 3
		dlight.decay = 1000
		dlight.size = 256
		dlight.dietime = CurTime() + 0.1
	end

	function SWEP:PostDrawViewModel( vm, weapon, ply )
		self:DrawEffects( vm, ply )
	end

	function SWEP:DrawWorldModel( flags )
		self:DrawModel( flags )
		self:DrawEffects( self, self:GetOwner() )
	end

	function SWEP:DrawHUD()
		local ply = self:GetOwner()

		if not IsValid( ply ) or not ply:KeyDown( IN_ATTACK2 ) then
			local lvsEnt = self:GetLVS()
			local Pos = ply:GetEyeTrace().HitPos

			if IsValid( lvsEnt ) and (Pos - ply:GetShootPos()):Length() < self.MaxRange and not ply:InVehicle() then
				if isfunction( lvsEnt.GetEngine ) then
					local Engine = lvsEnt:GetEngine()

					local AimPos = ply:GetEyeTrace().HitPos

					local EngineMode = IsEngineMode( AimPos, Engine )

					if IsValid( Engine ) and EngineMode then
						DrawText( AimPos, "Engine\nHealth: "..math.Round(Engine:GetHP()).."/"..Engine:GetMaxHP(), ColorText )
					else
						DrawText( AimPos, "Frame\nHealth: "..math.Round(lvsEnt:GetHP()).."/"..lvsEnt:GetMaxHP(), ColorText )
					end
				else
					DrawText( ply:GetEyeTrace().HitPos, "Frame\nHealth: "..math.Round(lvsEnt:GetHP()).."/"..lvsEnt:GetMaxHP(), ColorText )
				end
			end

			return
		end

		local Target = self:FindClosest()

		if IsValid( Target ) then
			local boxOrigin = Target:GetPos()
			local boxAngles = Target:GetAngles()
			local boxMins = Target:GetMins()
			local boxMaxs = Target:GetMaxs()

			cam.Start3D()
				render.SetColorMaterial()
				render.DrawBox( boxOrigin, boxAngles, boxMins, boxMaxs, ColorSelect )
			cam.End3D()

			DrawText( Target:LocalToWorld( (boxMins + boxMaxs) * 0.5 ), (Target:GetIgnoreForce() / 100).."mm "..Target:GetLabel().."\nHealth: "..math.Round(Target:GetHP()).."/"..Target:GetMaxHP(), ColorText )
		else
			local Pos = ply:GetEyeTrace().HitPos

			if IsValid( self:GetLVS() ) and (Pos - ply:GetShootPos()):Length() < self.MaxRange and not ply:InVehicle() then
				DrawText( Pos, "No Armor", ColorText )
			end
		end
	end
end

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:PrimaryAttack()
	local T = CurTime()

	self:SetNextPrimaryFire( T + 0.15 )

	self:SetFlameTime( T + 0.3 )

	local EngineMode = false
	local ArmorMode = true
	local Target = self:FindClosest()

	local ply = self:GetOwner()

	if IsValid( ply ) and not ply:KeyDown( IN_ATTACK2 ) then
		Target = self:GetLVS()

		if isfunction( Target.GetEngine ) then
			local Engine = Target:GetEngine()

			local AimPos = ply:GetEyeTrace().HitPos

			EngineMode = IsEngineMode( AimPos, Engine )

			if IsValid( Engine ) and EngineMode then
				Target = Engine
			end
		end

		ArmorMode = false
	end

	if not IsValid( Target ) then return end

	local HP = Target:GetHP()
	local MaxHP = Target:GetMaxHP()

	if IsFirstTimePredicted() then
		local trace = ply:GetEyeTrace()

		if HP ~= MaxHP then
			local effectdata = EffectData()
			effectdata:SetOrigin( trace.HitPos )
			effectdata:SetNormal( trace.HitNormal )
			util.Effect( "stunstickimpact", effectdata, true, true )
		end
	end

	if CLIENT then return end

	Target:SetHP( math.min( HP + 7, MaxHP ) )

	if EngineMode and Target:GetDestroyed() then
		Target:SetDestroyed( false )
	end

	if not ArmorMode then return end

	if Target:GetDestroyed() then Target:SetDestroyed( false ) end

	if HP < MaxHP then return end

	Target:OnRepaired()
end

function SWEP:SecondaryAttack()
end

function SWEP:Think()
	local ply = self:GetOwner()

	if not IsValid( ply ) then self:StopSND() return end

	local PlaySound = self:GetFlameTime() >= CurTime() and (ply:GetShootPos() - ply:GetEyeTrace().HitPos):Length() < self.MaxRange

	if PlaySound then
		self:PlaySND()
	else
		self:StopSND()
	end
end

function SWEP:StopSND()
	if CLIENT then return end

	if not self._snd then return end

	self._snd:Stop()
	self._snd = nil
end

function SWEP:PlaySND()
	if CLIENT then return end

	if self._snd then return end

	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	self._snd = CreateSound( ply, "lvs/weldingtorch_loop.wav" )
	self._snd:PlayEx(1, 70 )
end

function SWEP:OnRemove()
	self:StopSND()
end

function SWEP:OnDrop()
	self:StopSND()
end

function SWEP:Holster( wep )
	self:StopSND()
	return true
end
