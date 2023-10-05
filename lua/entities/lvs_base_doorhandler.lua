AddCSLuaFile()

ENT.Type            = "anim"
ENT.DoNotDuplicate = true

ENT.RenderGroup = RENDERGROUP_BOTH 

ENT.UseRange = 75

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )

	self:NetworkVar( "Bool",0, "Active" )

	self:NetworkVar( "String",0, "PoseName" )

	self:NetworkVar( "Vector",0, "Mins" )
	self:NetworkVar( "Vector",1, "Maxs" )

	self:NetworkVar( "Float",0, "Rate" )
	self:NetworkVar( "Float",1, "RateExponent" )

	self:NetworkVar( "Float",2, "PoseMin" )
	self:NetworkVar( "Float",3, "PoseMax" )

	if SERVER then
		self:SetRate( 10 )
		self:SetRateExponent( 2 )

		self:SetPoseMax( 1 )
	end
end

function ENT:IsOpen()
	return self:GetActive()
end

if SERVER then
	AccessorFunc(ENT, "soundopen", "SoundOpen", FORCE_STRING)
	AccessorFunc(ENT, "soundclose", "SoundClose", FORCE_STRING)

	AccessorFunc(ENT, "maxsopen", "MaxsOpen", FORCE_VECTOR)
	AccessorFunc(ENT, "minsopen", "MinsOpen", FORCE_VECTOR)

	AccessorFunc(ENT, "maxsclosed", "MaxsClosed", FORCE_VECTOR)
	AccessorFunc(ENT, "minsclosed", "MinsClosed", FORCE_VECTOR)


	util.AddNetworkString( "lvscar_player_interact" )

	net.Receive( "lvscar_player_interact", function( length, ply )
		if not IsValid( ply ) then return end

		local ent = net.ReadEntity()

		if not IsValid( ent ) then return end

		if (ply:GetPos() - ent:GetPos()):Length() > (ent.UseRang or 75) * 2 then return end

		ent:Use( ply, ply )
	end)

	function ENT:LinkToSeat( ent )
		if not IsValid( ent ) or not ent:IsVehicle() then

			ErrorNoHalt( "[LVS] Couldn't link seat to doorsystem. Entity expected, got "..tostring( ent ).."\n" )

			return
		end

		self._LinkedSeat = ent
	end

	function ENT:GetLinkedSeat()
		return self._LinkedSeat
	end

	function ENT:Initialize()	
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:SetUseType( SIMPLE_USE )
		self:DrawShadow( false )
		debugoverlay.Cross( self:GetPos(), 15, 5, Color( 255, 223, 127 ) )
	end

	function ENT:Use( ply )
		if not IsValid( ply ) then return end

		local Base = self:GetBase()

		if not IsValid( Base ) then return end

		if not Base:IsUseAllowed( ply ) then return end

		if self:IsOpen() then
			self:Close( ply )
		else
			self:Open( ply )
		end
	end

	function ENT:OnOpen( ply )
	end

	function ENT:OnClosed( ply )
	end

	function ENT:OpenAndClose( ply )
		self:Open( ply )

		self._PreventClosing = true

		timer.Simple(0.5, function()
			if not IsValid( self ) then return end

			self:Close( ply )

			self._PreventClosing = false
		end )
	end

	function ENT:Open( ply )
		if self:IsOpen() then return end

		if IsValid( self._LinkedSeat ) then
			local Driver = self._LinkedSeat:GetDriver()

			if IsValid( Driver ) and ply ~= Driver then return end
		end

		self:SetActive( true )
		self:SetMins( self:GetMinsOpen() )
		self:SetMaxs( self:GetMaxsOpen() )

		self:OnOpen( ply )

		local snd = self:GetSoundOpen()

		if not snd then return end

		self:EmitSound( snd )
	end

	function ENT:Close( ply )
		if not self:IsOpen() then return end

		self:SetActive( false )
		self:SetMins( self:GetMinsClosed() )
		self:SetMaxs( self:GetMaxsClosed() )

		self:OnClosed( ply )

		local snd = self:GetSoundClose()

		if not snd then return end

		self:EmitSound( snd )
	end

	function ENT:OnDriverChanged( oldDriver, newDriver, pod )
		if self._PreventClosing then return end

		if IsValid( newDriver ) then
			if self:IsOpen() then
				self:Close( newDriver )
			end
		else
			timer.Simple( FrameTime() * 2, function()
				if not IsValid( self ) or not IsValid( oldDriver ) or IsValid( self._Driver ) then return end

				if oldDriver:lvsGetVehicle() == self:GetBase() then return end

				if not self:IsOpen() then
					self:OpenAndClose()
				end
			end )
		end
	end

	function ENT:Think()
		if IsValid( self._LinkedSeat ) then
			local Driver = self._LinkedSeat:GetDriver()
	
			if self._Driver ~= Driver then
			
				self:OnDriverChanged( self._Driver, Driver, self._LinkedSeat )

				self._Driver = Driver
			end
		end

		self:NextThink( CurTime() + 0.25 )

		return true
	end

	function ENT:OnTakeDamage( dmginfo )
	end

	return
end

function ENT:Initialize()
end

function ENT:Think()
	local Base = self:GetBase()

	if not IsValid( Base ) then return end

	local Target = self:GetActive() and self:GetPoseMax() or self:GetPoseMin()
	local poseName = self:GetPoseName()

	if poseName == "" then return end

	self.sm_pp = self.sm_pp and self.sm_pp + (Target - self.sm_pp) * RealFrameTime() * self:GetRate() or 0

	local value = self.sm_pp ^ self:GetRateExponent()

	if string.StartsWith( poseName, "!" ) then
		Base:SetBonePoseParameter( poseName, value )
	else
		Base:SetPoseParameter( poseName, value )
	end
end

function ENT:OnRemove()
end

function ENT:Draw()
end

local LVS = LVS
ENT.ColorSelect = Color(127,255,127,150)
ENT.ColorNormal = Color(255,0,0,150)
ENT.ColorTransBlack = Color(0,0,0,150)
ENT.OutlineThickness = Vector(0.5,0.5,0.5)

function ENT:DrawTranslucent()
	local ply = LocalPlayer()

	if not IsValid( ply ) or ply:InVehicle() or not ply:KeyDown( IN_SPEED ) then return end

	local boxOrigin = self:GetPos()
	local boxAngles = self:GetAngles()
	local boxMins = self:GetMins()
	local boxMaxs = self:GetMaxs()

	local HitPos, _, _ = util.IntersectRayWithOBB( ply:GetShootPos(), ply:GetAimVector() * self.UseRange, boxOrigin, boxAngles, boxMins, boxMaxs )

	local InRange = isvector( HitPos )

	if InRange then
		local Use = ply:KeyDown( IN_USE )

		if self.old_Use ~= Use then
			self.old_Use = Use

			if Use then
				net.Start( "lvscar_player_interact" )
					net.WriteEntity( self )
				net.SendToServer()
			end
		end
	end

	if not LVS.DeveloperEnabled then return end

	local Col = InRange and self.ColorSelect or self.ColorNormal

	render.SetColorMaterial()
	render.DrawBox( boxOrigin, boxAngles, boxMins, boxMaxs, Col )
	render.DrawBox( boxOrigin, boxAngles, boxMaxs + self.OutlineThickness, boxMins - self.OutlineThickness, self.ColorTransBlack )
end
