ENT.Type            = "anim"

ENT.PrintName = "LBaseGunner"
ENT.Author = "Luna"
ENT.Information = "Luna's Vehicle Script"
ENT.Category = "[LVS]"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true

ENT.LVS_GUNNER = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Driver" )
	self:NetworkVar( "Entity",1, "DriverSeat" )

	self:NetworkVar( "Int", 0, "PodIndex")
	self:NetworkVar( "Int", 1, "NWAmmo")
	self:NetworkVar( "Int", 2, "SelectedWeapon" )

	self:NetworkVar( "Float", 0, "NWHeat" )

	if SERVER then
		self:NetworkVarNotify( "SelectedWeapon", self.OnWeaponChanged )
	end
end

function ENT:GetVehicle()
	local Pod = self:GetParent()

	if not IsValid( Pod ) then return NULL end

	return Pod:GetParent()
end

function ENT:GetAI()
	local veh = self:GetVehicle()

	if not IsValid( veh ) then return false end

	return 
end

function ENT:HasWeapon( ID )
	local Base = self:GetVehicle()

	if not IsValid( Base ) then return false end

	return istable( Base.WEAPONS[ self:GetPodIndex() ][ ID ] )
end

function ENT:AIHasWeapon( ID )
	local Base = self:GetVehicle()

	if not IsValid( Base ) then return false end

	local weapon = Base.WEAPONS[ self:GetPodIndex() ][ ID ]

	if not istable( weapon ) then return false end

	return weapon.UseableByAI
end

function ENT:GetActiveWeapon()
	local SelectedID = self:GetSelectedWeapon()

	local Base = self:GetVehicle()

	if not IsValid( Base ) then return {}, SelectedID end

	local CurWeapon = Base.WEAPONS[ self:GetPodIndex() ][ SelectedID ]

	return CurWeapon, SelectedID
end

function ENT:GetMaxAmmo()
	local CurWeapon = self:GetActiveWeapon()

	if not CurWeapon then return -1 end

	return CurWeapon.Ammo or -1
end
