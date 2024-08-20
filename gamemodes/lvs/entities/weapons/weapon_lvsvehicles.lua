AddCSLuaFile()

SWEP.Category				= "[LVS]"
SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false
SWEP.ViewModel			= "models/weapons/c_slam.mdl"
SWEP.WorldModel			= "models/weapons/w_slam.mdl"
SWEP.UseHands				= true

SWEP.HoldType				= "pistol"

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip		= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= true
SWEP.Secondary.Ammo		= "none"

SWEP.SpawnDistance = 512
SWEP.RemoveDistance = 512
SWEP.RemoveTime = 10

function SWEP:GetRemoveTime()
	if GAMEMODE:GetGameState() <= GAMESTATE_BUILD then return 1 end

	return self.RemoveTime
end

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 1, "VehicleRemoveTime" )
	self:NetworkVar( "Entity", 1, "Vehicle" )
end

function SWEP:GetTrace()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	local Trace = ply:GetEyeTrace()

	local SpawnAllowed = (Trace.HitPos - ply:GetShootPos()):Length() < self.SpawnDistance

	local StartPos = Trace.HitPos + Vector(0,0,8)

	local roofTrace = util.TraceHull( {
		start = StartPos,
		endpos = StartPos + Vector(0,0,160),
		mins = Vector( -8, -8, 0 ),
		maxs = Vector( 8, 8, 0 ),
		mask = MASK_SOLID_BRUSHONLY
	} )

	if roofTrace.Hit then
		SpawnAllowed = false
	end

	return Trace, SpawnAllowed
end

if CLIENT then
	SWEP.PrintName		= "#lvs_tool_vehicles"
	SWEP.Author			= "Luna"

	SWEP.Slot				= 4
	SWEP.SlotPos			= 1

	SWEP.Purpose			= "#lvs_tool_vehicles_info"
	SWEP.Instructions		= "#lvs_tool_vehicles_instructions"

	SWEP.DrawWeaponInfoBox 	= true

	function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
		draw.SimpleText( "D", "WeaponIcons", x + wide/2, y + tall*0.2, Color( 255, 210, 0, 255 ), TEXT_ALIGN_CENTER )

		-- Borders
		y = y + 10
		x = x + 10
		wide = wide - 20

		-- Draw that mother
		surface.DrawTexturedRect( x, y,  wide , ( wide / 2 ) )

		-- Draw weapon info box
		self:PrintWeaponInfo( x + wide + 20, y + tall * 0.95, alpha )
	end

	local circles = include("includes/circles/circles.lua")

	local Circle = circles.New(CIRCLE_OUTLINED, 30, 0, 0, 5)
	Circle:SetColor( color_white )
	Circle:SetX( ScrW() * 0.5 )
	Circle:SetY( ScrH() * 0.5 )
	Circle:SetStartAngle( 0 )
	Circle:SetEndAngle( 0 )

	local ColorText = Color(255,255,255,255)

	local function DrawText( x, y, text, col )
		local font = "TargetIDSmall"

		draw.DrawText( text, font, x + 1, y + 1, Color( 0, 0, 0, 120 ), TEXT_ALIGN_CENTER )
		draw.DrawText( text, font, x + 2, y + 2, Color( 0, 0, 0, 50 ), TEXT_ALIGN_CENTER )
		draw.DrawText( text, font, x, y, col or color_white, TEXT_ALIGN_CENTER )
	end

	function SWEP:DoDrawCrosshair( x, y )
		local ply = LocalPlayer()

		if not ply:KeyDown( IN_RELOAD ) or ply:InVehicle() and not ply:GetAllowWeaponsInVehicle() then return end

		local Vehicle = self:GetVehicle()

		if not IsValid( Vehicle ) or (ply:GetPos() - Vehicle:GetPos()):Length() > self.RemoveDistance then return end

		local Time = self:GetVehicleRemoveTime() - CurTime()

		local TimeLeft = math.Round( Time, Time > 1 and 0 or 1 )

		if TimeLeft < 0 then return end

		draw.DrawText( TimeLeft, "LVS_FONT_HUD_LARGE", x, y - 20, color_white, TEXT_ALIGN_CENTER )

		return true
	end

	function SWEP:CalcMenu( Open )
		if self._oldOpen == Open then return end

		self._oldOpen = Open

		if Open then
			GAMEMODE:OpenBuyMenu()
		else
			GAMEMODE:CloseBuyMenu()
		end
	end

	local IconInstructionA = Material( "lvs/instructions/mouse_right.png" )
	local IconInstructionB = Material( "lvs/instructions/mouse_left.png" )

	function SWEP:DrawHUD()
		local ply = LocalPlayer()

		if ply:InVehicle() and not ply:GetAllowWeaponsInVehicle() then
			self:CalcMenu( false )

			return
		end

		self:CalcMenu( ply:KeyDown( IN_ATTACK2 ) )

		local Vehicle = self:GetVehicle()

		if ply:KeyDown( IN_RELOAD ) then
			if not IsValid( Vehicle ) or vgui.CursorVisible() then return end

			local X = ScrW() * 0.5
			local Y = ScrH() - 105

			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.SetMaterial( IconInstructionB )
			surface.DrawTexturedRect( X - 32, Y, 64, 64 )

			draw.DrawText( "#lvs_tool_vehicles_store_remove", "LVS_FONT", X, Y + 68, color_white, TEXT_ALIGN_CENTER )
		else
		
			if IsValid( Vehicle ) or vgui.CursorVisible() then return end

			local data = ply:lvsGetCurrentVehicleData()

			local X = ScrW() * 0.5
			local Y = ScrH() - 105

			if not data then
				surface.SetDrawColor( 255, 255, 255, 255 )
				surface.SetMaterial( IconInstructionA )
				surface.DrawTexturedRect( X - 32, Y, 64, 64 )

				draw.DrawText( "#lvs_tool_vehicles_store_open", "LVS_FONT", X, Y + 68, color_white, TEXT_ALIGN_CENTER )

				return
			end

			local CanAfford = ply:CanAfford( data )

			if not CanAfford then return end

			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.SetMaterial( IconInstructionB )
			surface.DrawTexturedRect( X - 32, Y, 64, 64 )

			draw.DrawText( "#lvs_tool_vehicles_store_spawn", "LVS_FONT", X, Y + 68, color_white, TEXT_ALIGN_CENTER )

			return
		end

		local X = ScrW() * 0.5
		local Y = ScrH() * 0.5

		if not IsValid( Vehicle ) then DrawText( X, Y + 34, "#lvs_tool_vehicles_novehicle", Color(255,0,0,255) ) return end

		if (ply:GetPos() - Vehicle:GetPos()):Length() > self.RemoveDistance then
			DrawText( X, Y + 34, "#lvs_tool_vehicles_too_far", Color(255,0,0, math.abs( math.cos( CurTime() * 5 ) ) * 255 ) )

			return
		end

		if #Vehicle:GetEveryone() > 0 then DrawText( X, Y + 34, "#lvs_tool_vehicles_in_use", Color(255,0,0, math.abs( math.cos( CurTime() * 5 ) ) * 255 ) ) return end

		local RemoveTime = math.min( (self:GetVehicleRemoveTime() - CurTime()) / self:GetRemoveTime(), 1 )

		if RemoveTime < 0 then return end

		draw.NoTexture()

		Circle:SetX( X )
		Circle:SetY( Y )
		Circle:SetStartAngle( -360 * RemoveTime )
		Circle:SetEndAngle( 0 )
		Circle()

		DrawText( X, Y + 34, "#lvs_tool_vehicles_sell" )
	end

	local FrameMat = Material( "lvs/3d2dmats/frame.png" )
	local ArrowMat = Material( "lvs/3d2dmats/arrow.png" )

	hook.Add( "PostDrawTranslucentRenderables", "the_system_is_rigged", function( bDrawingDepth, bDrawingSkybox, isDraw3DSkybox )

		if bDrawingDepth or bDrawingSkybox or isDraw3DSkybox then return end

		local ply = LocalPlayer()

		if not IsValid( ply ) then return end

		local SWEP = ply:GetWeapon( "weapon_lvsvehicles" )

		if not IsValid( SWEP ) or SWEP ~= ply:GetActiveWeapon() or (ply:InVehicle() and not ply:GetAllowWeaponsInVehicle()) or ply:KeyDown( IN_RELOAD ) or vgui.CursorVisible() then return end

		local Vehicle = SWEP:GetVehicle()

		if ply:lvsGetCurrentVehicle() == "" or (IsValid( Vehicle ) and Vehicle:GetHP() > 0) then return end

		local trace, allowed = SWEP:GetTrace()

		local pos = trace.HitPos + trace.HitNormal
		local ang = Angle(0,ply:EyeAngles().y - 90,0)

		local CanAfford = ply:CanAfford( ply:lvsGetCurrentVehicleData() )

		if not CanAfford then allowed = false end

		if allowed then
			surface.SetDrawColor( 0, 127, 255, 255 )
		else
			surface.SetDrawColor( 255, 0, 0, 255 )
		end

		cam.Start3D2D( pos, ang, 0.05 )
			surface.SetMaterial( FrameMat )
			surface.DrawTexturedRect( -1024, -1024, 2048, 2048 )
		cam.End3D2D()

		cam.Start3D2D( pos + Vector(0,0,50 + math.cos( CurTime() * 4 ) * 25 ), ang + Angle(0,180,-90), 0.05 )
			surface.SetMaterial( ArrowMat )
			surface.DrawTexturedRect( -512, -512, 1024, 1024 )
		cam.End3D2D()
	end )
end

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:PrimaryAttack()
	self:SendWeaponAnim( ACT_SLAM_DETONATOR_DETONATE )

	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	if ply:KeyDown( IN_ATTACK2 ) then return end

	if CLIENT then return end

	local Vehicle = self:GetVehicle()

	if IsValid( Vehicle ) then
		if isfunction( Vehicle.IsDestroyed ) and Vehicle:IsDestroyed() then
			timer.Simple( 119.5, function()
				if not IsValid( Vehicle ) then return end

				Vehicle:SetRenderFX( kRenderFxFadeFast  ) 
			end)

			timer.Simple( 120, function()
				if not IsValid( Vehicle ) then return end

				Vehicle:Remove()
			end)
		else
			if ply:KeyDown( IN_RELOAD ) then
				ply:EmitSound("buttons/button14.wav")

				ply:ChatPrint( "#lvs_tool_vehicles_remove" )

				Vehicle:Remove()
			else
				ply:ChatPrint( "#lvs_tool_vehicles_already_have_vehicle" )
			end

			return
		end
	end

	local trace, allowed = self:GetTrace()

	if not allowed then return end

	local class = ply:lvsGetCurrentVehicle()
	local price = GAMEMODE:GetVehiclePrice( class )

	if not ply:CanAfford( price ) then ply:ChatPrint( "#lvs_hint_nomoney" ) return end

	ply._SpawnedVehicle = GAMEMODE:SpawnVehicle( ply, class, trace )

	if not IsValid( ply._SpawnedVehicle ) then return end

	ply:TakeMoney( price )

	self:SetVehicleRemoveTime( CurTime() + self:GetRemoveTime() )

	self:SetVehicle( ply._SpawnedVehicle )

	if (trace.HitPos - ply:GetShootPos()):Length() < self.SpawnDistance * 0.5 then
		self:EnterVehicle( ply._SpawnedVehicle )

		ply._lvsKeyDisabler = CurTime() + 0.5
	end

	ply:ChatPrint( "#lvs_tool_vehicles_buy" )
end

hook.Add( "LVS.CanPlayerDrive", "!!!prevent_thievery", function(ply, vehicle )
	if vehicle ~= ply._SpawnedVehicle then
		ply:ChatPrint( "#lvs_tool_vehicles_cannot_drive" )

		return false
	end
end )

function SWEP:SecondaryAttack()
	self:SendWeaponAnim( ACT_SLAM_DETONATOR_DETONATE )
end

function SWEP:Reload()
end

function SWEP:Deploy()
	self:SendWeaponAnim( ACT_SLAM_DETONATOR_DRAW )

	local ply = self:GetOwner()

	if IsValid( ply ) and IsValid( ply._SpawnedVehicle ) then
		self:SetVehicle( ply._SpawnedVehicle )
	end

	return true
end

function SWEP:HandleVehicleRemove()
	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	local Reload = ply:KeyDown( IN_RELOAD )

	local Vehicle = self:GetVehicle()

	if Reload and IsValid( Vehicle ) and isfunction( Vehicle.GetEveryone ) then
		if #Vehicle:GetEveryone() > 0 then
			Reload = false
		end

		if (ply:GetPos() - Vehicle:GetPos()):Length() > self.RemoveDistance then
			Reload = false
		end
	end

	if self._oldReload ~= Reload then
		self._oldReload = Reload

		if Reload and IsValid( Vehicle ) then
			self._NotifyPlayed = nil
			self:SetVehicleRemoveTime( CurTime() + self:GetRemoveTime() )
		end
	end

	if not Reload or not IsValid( Vehicle ) then return end

	local RemoveTime = (self:GetVehicleRemoveTime() - CurTime()) / self:GetRemoveTime()

	if RemoveTime > 0 then return end

	self:SendWeaponAnim( ACT_SLAM_DETONATOR_DETONATE )

	if CLIENT then return end

	ply:EmitSound("buttons/button15.wav")

	ply:ChatPrint( "#lvs_tool_vehicles_sell_success" )

	ply:AddMoney( GAMEMODE:GetVehiclePrice( Vehicle:GetClass() ) )

	Vehicle:Remove()
end

function SWEP:Think()
	self:HandleVehicleRemove()
end

if SERVER then
	function SWEP:EnterVehicle( target )
		local ply = self:GetOwner()

		if not IsValid( ply ) or not IsValid( target ) or not target.IsInitialized then return end

		if not target:IsInitialized() then

			timer.Simple(0, function()
				if not IsValid( self ) then return end

				self:EnterVehicle( target )
			end)

			return
		end

		local DriverSeat = target:GetDriverSeat()

		if not IsValid( DriverSeat ) then return end

		ply:EnterVehicle( DriverSeat )
	end

	function SWEP:Holster( wep )
		return true
	end

	function SWEP:OnRemove()
	end

	function SWEP:OnDrop()
	end

	return
end

function SWEP:Holster( wep )
	self:CalcMenu( false )

	return true
end

function SWEP:OnRemove()
	self:CalcMenu( false )
end

function SWEP:OnDrop()
	self:CalcMenu( false )
end
