AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")
include("sv_ai.lua")

function ENT:Initialize()	
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE )
	self:DrawShadow( false )
end

function ENT:Think()
	self:HandleActive()
	self:WeaponsThink()

	if self:GetAI() then
		self:RunAI()
	end
 
	self:NextThink( CurTime() )

	return true
end

function ENT:HandleActive()
	local Pod = self:GetDriverSeat()

	if not IsValid( Pod ) then
		return
	end

	local Driver = Pod:GetDriver()

	if Driver ~= self:GetDriver() then
		local NewDriver = Driver
		local OldDriver = self:GetDriver()

		self:SetDriver( Driver )

		local Base = self:GetVehicle()

		if IsValid( Base ) then
			Base:OnPassengerChanged( OldDriver, NewDriver, Pod:GetNWInt( "pPodIndex", -1 ) )
		end

		if IsValid( Driver ) then
			Driver:lvsBuildControls()
		else
			self:WeaponsFinish()
		end
	end
end

function ENT:OnRemove()
end

function ENT:UpdateTransmitState() 
	return TRANSMIT_ALWAYS
end

function ENT:WeaponsFinish()
	if not self._activeWeapon then return end

	local Base = self:GetVehicle()

	if not IsValid( Base ) then return end

	local CurWeapon = Base.WEAPONS[ self:GetPodIndex() ][ self._activeWeapon ]

	if not CurWeapon then return end

	if CurWeapon.FinishAttack then
		CurWeapon.FinishAttack( self )
	end

	self._activeWeapon = nil
	self.OldAttack = false
end

function ENT:GetAmmo()
	if self:GetAI() then return self:GetMaxAmmo() end

	local CurWeapon = self:GetActiveWeapon()

	if not CurWeapon then return -1 end

	return CurWeapon._CurAmmo or self:GetMaxAmmo()
end

function ENT:TakeAmmo( num )
	if self:GetMaxAmmo() <= 0 then return end

	local CurWeapon = self:GetActiveWeapon()

	CurWeapon._CurAmmo = math.max( self:GetAmmo() - (num or 1), 0 )

	self:SetNWAmmo( CurWeapon._CurAmmo )
end

function ENT:GetHeat()
	local CurWeapon = self:GetActiveWeapon()

	if not CurWeapon then return 0 end

	return (CurWeapon._CurHeat or 0)
end

function ENT:GetOverheated()
	local CurWeapon = self:GetActiveWeapon()

	if not CurWeapon then return false end

	return CurWeapon.Overheated == true
end

function ENT:SetOverheated( overheat )
	if self:GetOverheated() == overheat then return end

	local CurWeapon = self:GetActiveWeapon()

	if not CurWeapon then return end

	CurWeapon.Overheated = overheat

	self:SetNWOverheated( overheat )

	if self:GetHeat() == 0 then return end

	if CurWeapon.OnOverheat then
		CurWeapon.OnOverheat( self )
	end
end

function ENT:SetHeat( heat )
	local CurWeapon = self:GetActiveWeapon()

	if not CurWeapon then return end

	heat = math.Clamp( heat, 0, 1 )

	CurWeapon._CurHeat = heat

	if self:GetNWHeat() == heat then return end

	self:SetNWHeat( heat )
end

function ENT:CanAttack()
	local CurWeapon = self:GetActiveWeapon()

	return (CurWeapon._NextFire or 0) < CurTime()
end

function ENT:SetNextAttack( time )
	local CurWeapon = self:GetActiveWeapon()

	CurWeapon._NextFire = time
end

function ENT:WeaponsShouldFire()
	if self:GetAI() then return self._AIFireInput end

	local ply = self:GetDriver()

	if not IsValid( ply ) then return false end

	return ply:lvsKeyDown( "ATTACK" )
end

function ENT:WeaponsThink()
	local T = CurTime()
	local FT = FrameTime()
	local CurWeapon, SelectedID = self:GetActiveWeapon()

	local Base = self:GetVehicle()

	if not IsValid( Base ) then return end

	for ID, Weapon in pairs( Base.WEAPONS[ self:GetPodIndex() ] ) do
		local IsActive = ID == SelectedID
		if Weapon.OnThink then Weapon.OnThink( self, IsActive ) end

		if IsActive then continue end

		-- cool all inactive weapons down
		Weapon._CurHeat = Weapon._CurHeat and Weapon._CurHeat - math.min( Weapon._CurHeat, (Weapon.HeatRateDown or 0.25) * FT ) or 0
	end

	if not CurWeapon then return end

	local ShouldFire = self:WeaponsShouldFire()
	local CurHeat = self:GetHeat()

	if self:GetOverheated() then
		if CurHeat <= 0 then
			self:SetOverheated( false )
		else
			ShouldFire = false
		end
	else
		if CurHeat >= 1 then
			self:SetOverheated( true )
			ShouldFire = false
		end
	end

	if self:GetMaxAmmo() > 0 then
		if self:GetAmmo() <= 0 then
			ShouldFire = false
		end
	end

	if ShouldFire ~= self.OldAttack then
		self.OldAttack = ShouldFire

		if ShouldFire then
			if CurWeapon.StartAttack then
				CurWeapon.StartAttack( self )
			end
			self._activeWeapon = SelectedID
		else
			self:WeaponsFinish()
		end
	end

	if ShouldFire then
		if not self:CanAttack() then return end

		local ShootDelay = (CurWeapon.Delay or 0)

		self:SetNextAttack( T + ShootDelay )
		self:SetHeat( CurHeat + (CurWeapon.HeatRateUp or 0.2) * math.max(ShootDelay, FT) )

		if not CurWeapon.Attack then return end

		if CurWeapon.Attack( self ) then
			self:SetHeat( CurHeat - math.min( self:GetHeat(), (CurWeapon.HeatRateDown or 0.25) * FT ) )
			self:SetNextAttack( T )
		end
	else
		self:SetHeat( self:GetHeat() - math.min( self:GetHeat(), (CurWeapon.HeatRateDown or 0.25) * FT ) )
	end
end

function ENT:SelectWeapon( ID )
	if not isnumber( ID ) then return end

	local Base = self:GetVehicle()

	if not IsValid( Base ) then return end

	if Base.WEAPONS[ self:GetPodIndex() ][ ID ] then
		self:SetSelectedWeapon( ID )
	end

	local ply = self:GetDriver()

	if not IsValid( ply ) then return end

	net.Start( "lvs_select_weapon" )
	net.Send( ply )
end

function ENT:OnWeaponChanged( name, old, new)
	if new == old then return end

	self:WeaponsFinish()

	local Base = self:GetVehicle()

	if not IsValid( Base ) then return end

	local PrevWeapon = Base.WEAPONS[ self:GetPodIndex() ][ old ]
	if PrevWeapon and PrevWeapon.OnDeselect then
		PrevWeapon.OnDeselect( self )
	end

	local NextWeapon = Base.WEAPONS[ self:GetPodIndex() ][ new ]
	if NextWeapon and NextWeapon.OnSelect then
		NextWeapon.OnSelect( self )
		self:SetNWAmmo( NextWeapon._CurAmmo or NextWeapon.Ammo or -1 )
		self:SetNWOverheated( NextWeapon.Overheated == true )
	end
end

function ENT:LVSFireBullet( data )
	local Base = self:GetVehicle()

	if not IsValid( Base ) then return end

	data.Entity = Base

	data.Velocity = data.Velocity + self:GetVelocity():Length()
	data.SrcEntity = Base:WorldToLocal( data.Src )

	LVS:FireBullet( data )
end
