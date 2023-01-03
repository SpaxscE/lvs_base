AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.DoNotDuplicate = true

ENT._LVS = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )

	self:NetworkVar( "Bool",0, "Active" )

	self:NetworkVar( "String",1, "Sound")
	self:NetworkVar( "String",2, "SoundInterior")

	self:NetworkVar( "Int",0, "SoundLevel" )

	if SERVER then
		self:SetSoundLevel( 110 )
	end
end

if SERVER then
	util.AddNetworkString( "lvs_soundemitter_playonce" )

	function ENT:Initialize()	
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )
		debugoverlay.Cross( self:GetPos(), 50, 5, Color( 150, 150, 150 ) )
	end

	function ENT:Think()
		return false
	end

	function ENT:UpdateTransmitState() 
		return TRANSMIT_ALWAYS
	end

	function ENT:PlayOnce( pitch, volume )
		net.Start( "lvs_soundemitter_playonce", true )
			net.WriteEntity( self )
			net.WriteInt( pitch or 100, 9 )
			net.WriteFloat( volume or 1 )
		net.SendPVS( self:GetPos() )
	end

	function ENT:Play()
		self:SetActive( true )
	end

	function ENT:Stop()
		self:SetActive( false )
	end

	return
end

net.Receive( "lvs_soundemitter_playonce", function( len )
	local ent = net.ReadEntity()

	if not IsValid( ent ) or not ent.PlayOnce then return end

	ent:PlayOnce( net.ReadInt( 9 ), net.ReadFloat() )
end )

function ENT:PlayOnce( pitch, volume )
	local ply = LocalPlayer()
	local veh = ply:lvsGetVehicle()

	local snd = self:GetSound()
	local snd_int = self:GetSoundInterior()

	if snd == snd_int then self:EmitSound( snd, self:GetSoundLevel(), pitch, volume, CHAN_WEAPON ) return end

	if IsValid( veh ) and veh == self:GetBase() and ply:GetViewEntity() == ply then
		local pod = ply:GetVehicle()

		if IsValid( pod ) then
			if pod:GetThirdPersonMode() then
				self:EmitSound( snd, self:GetSoundLevel(), pitch, volume, CHAN_WEAPON )
			else
				self:EmitSound( snd_int, self:GetSoundLevel(), pitch, volume, CHAN_WEAPON )
			end
		else
			self:EmitSound( snd, self:GetSoundLevel(), pitch, volume, CHAN_WEAPON )
		end
	else
		self:EmitSound( snd, self:GetSoundLevel(), pitch, volume, CHAN_WEAPON )
	end
end

function ENT:Initialize()
end

function ENT:RemoveSounds()
	if self.snd then
		self.snd:Stop()
		self.snd = nil
	end

	if self.snd_int then
		self.snd_int:Stop()
		self.snd_int = nil
	end
end

function ENT:HandleSounds()
	if not self.snd_int then return end

	local ply = LocalPlayer()
	local veh = ply:lvsGetVehicle()

	if IsValid( veh ) and veh == self:GetBase() and ply:GetViewEntity() == ply then
		local pod = ply:GetVehicle()

		if IsValid( pod ) then
			if pod:GetThirdPersonMode() then
				if self.snd then self.snd:ChangeVolume( 1 ) end
				if self.snd_int then self.snd_int:ChangeVolume( 0 ) end
			else
				if self.snd then self.snd:ChangeVolume( 0 ) end
				if self.snd_int then self.snd_int:ChangeVolume( 1 ) end
			end
		else
			if self.snd then self.snd:ChangeVolume( 1 ) end
			if self.snd_int then self.snd_int:ChangeVolume( 0 ) end
		end
	else
		if self.snd then self.snd:ChangeVolume( 1 ) end
		if self.snd_int then self.snd_int:ChangeVolume( 0 ) end
	end
end

function ENT:StartSounds()
	local snd = self:GetSound()
	local snd_int = self:GetSoundInterior()

	if snd ~= "" then
		self.snd = CreateSound( self, snd )
		self.snd:SetSoundLevel( self:GetSoundLevel() )
		self.snd:PlayEx(0,100)
	end

	if snd == snd_int then
		self.snd:ChangeVolume( 1, 0 )

		return
	end

	if snd_int ~= "" then
		self.snd_int = CreateSound( self, snd_int )
		self.snd_int:SetSoundLevel( self:GetSoundLevel() )
		self.snd_int:PlayEx(0,100)
	end
end

function ENT:StopSounds()
	self.NextActive = CurTime() + 0.12

	if self.snd then
		self.snd:ChangeVolume( 0, 0.1 )
	end

	if self.snd_int then
		self.snd_int:ChangeVolume( 0, 0.1 )
	end

	timer.Simple(0.11, function()
		if not IsValid( self ) then return end
		self:RemoveSounds()
	end)
end

function ENT:OnActiveChanged( Active )
	if Active then
		self:StartSounds()
	else
		self:StopSounds()
	end
end

ENT._oldActive = false
function ENT:Think()
	local Active = self:GetActive() and (self.NextActive or 0) < CurTime()

	if self._oldActive ~= Active then
		self._oldActive = Active
		self:OnActiveChanged( Active )
	end

	if Active then
		self:HandleSounds()
	end
end

function ENT:OnRemove()
	self:RemoveSounds()
end

function ENT:Draw()
end

function ENT:DrawTranslucent()
end
