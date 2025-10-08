AddCSLuaFile()

ENT.Type            = "anim"
ENT.DoNotDuplicate = true

ENT.RenderGroup = RENDERGROUP_BOTH 

ENT.UseRange = 75

ENT._UseTargetAllowed = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
	self:NetworkVar( "Entity",1, "LinkedSeat" )

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

function ENT:IsServerSide()
	local EntTable = self:GetTable()

	if isbool( EntTable._IsServerSide ) then return EntTable._IsServerSide end

	local PoseName = self:GetPoseName()

	if PoseName == "" then return false end

	local IsServerSide = string.StartsWith( PoseName, "^" )

	EntTable._IsServerSide = IsServerSide

	return IsServerSide
end

function ENT:IsOpen()
	return self:GetActive()
end

function ENT:InRange( ply, Range )
	local boxOrigin = self:GetPos()
	local boxAngles = self:GetAngles()
	local boxMins = self:GetMins()
	local boxMaxs = self:GetMaxs()

	local HitPos, _, _ = util.IntersectRayWithOBB( ply:GetShootPos(), ply:GetAimVector() * Range, boxOrigin, boxAngles, boxMins, boxMaxs )

	return isvector( HitPos )
end

if SERVER then
	AccessorFunc(ENT, "soundopen", "SoundOpen", FORCE_STRING)
	AccessorFunc(ENT, "soundclose", "SoundClose", FORCE_STRING)

	AccessorFunc(ENT, "maxsopen", "MaxsOpen", FORCE_VECTOR)
	AccessorFunc(ENT, "minsopen", "MinsOpen", FORCE_VECTOR)

	AccessorFunc(ENT, "maxsclosed", "MaxsClosed", FORCE_VECTOR)
	AccessorFunc(ENT, "minsclosed", "MinsClosed", FORCE_VECTOR)


	util.AddNetworkString( "lvs_doorhandler_interact" )

	net.Receive( "lvs_doorhandler_interact", function( length, ply )
		if not IsValid( ply ) then return end

		local ent = net.ReadEntity()

		if not IsValid( ent ) or not ent._UseTargetAllowed or not ent.UseRange or ply:InVehicle() then return end

		local Range = ent.UseRange * 2

		if (ply:GetPos() - ent:GetPos()):Length() > Range then return end

		if not ent:InRange( ply, Range ) then return end

		ent:Use( ply, ply )
	end)

	function ENT:LinkToSeat( ent )
		if not IsValid( ent ) or not ent:IsVehicle() then

			ErrorNoHalt( "[LVS] Couldn't link seat to doorsystem. Entity expected, got "..tostring( ent ).."\n" )

			return
		end

		self:SetLinkedSeat( ent )
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

	function ENT:DisableOnBodyGroup( group, subgroup )
		self._BodyGroupDisable = group
		self._BodySubGroupDisable = subgroup
	end

	function ENT:IsBodyGroupDisabled()
		if not self._BodyGroupDisable or not self._BodySubGroupDisable then return false end

		local base = self:GetBase()

		if not IsValid( base ) then return false end

		return base:GetBodygroup( self._BodyGroupDisable ) == self._BodySubGroupDisable
	end

	function ENT:Open( ply )
		if self:IsOpen() then return end

		self:SetActive( true )
		self:SetMins( self:GetMinsOpen() )
		self:SetMaxs( self:GetMaxsOpen() )

		if self:IsBodyGroupDisabled() then return end

		self:OnOpen( ply )

		local snd = self:GetSoundOpen()

		if not snd then return end

		self:EmitSound( snd )
	end

	function ENT:Close( ply )
		if not self:IsOpen() then
			if self:IsBodyGroupDisabled() then
				self:Open( ply )
			end

			return
		end

		if self:IsBodyGroupDisabled() then return end

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

	function ENT:SetPoseParameterSV()
		local Base = self:GetBase()

		if not IsValid( Base ) then return end

		local Target = self:GetActive() and self:GetPoseMax() or self:GetPoseMin()
		local poseName = self:GetPoseName()

		if poseName == "" then return end

		local EntTable = self:GetTable()

		EntTable.sm_pp = EntTable.sm_pp and EntTable.sm_pp + (Target - EntTable.sm_pp) * FrameTime() * self:GetRate() or 0

		local value = EntTable.sm_pp ^ self:GetRateExponent()

		Base:SetPoseParameter( string.Replace(poseName, "^", ""), value )
	end

	function ENT:Think()
		local LinkedSeat = self:GetLinkedSeat()

		if IsValid( LinkedSeat ) then
			local Driver = LinkedSeat:GetDriver()
	
			if self._Driver ~= Driver then
			
				self:OnDriverChanged( self._Driver, Driver, LinkedSeat )

				self._Driver = Driver
			end
		end

		if self:IsServerSide() then
			self:SetPoseParameterSV()

			self:NextThink( CurTime() )
		else
			self:NextThink( CurTime() + 0.25 )
		end

		return true
	end

	function ENT:OnTakeDamage( dmginfo )
	end

	return
end

function ENT:Initialize()
end

function ENT:Think()
	if self:IsServerSide() then return end

	local Base = self:GetBase()

	if not IsValid( Base ) then return end

	local Target = self:GetActive() and self:GetPoseMax() or self:GetPoseMin()
	local poseName = self:GetPoseName()

	if poseName == "" then return end

	local EntTable = self:GetTable()

	EntTable.sm_pp = EntTable.sm_pp and EntTable.sm_pp + (Target - EntTable.sm_pp) * RealFrameTime() * self:GetRate() or 0

	local value = EntTable.sm_pp ^ self:GetRateExponent()

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
ENT.ColorBlack = Color(75,75,75,255)
ENT.OutlineThickness = Vector(0.5,0.5,0.5)

local function DrawText( pos, text, align, col )
	if not align then align = TEXT_ALIGN_CENTER end

	cam.Start2D()
		local data2D = pos:ToScreen()

		if not data2D.visible then return end

		local font = "TargetIDSmall"

		local x = data2D.x
		local y = data2D.y

		draw.DrawText( text, font, x + 1, y + 1, Color( 0, 0, 0, 120 ), align )
		draw.DrawText( text, font, x + 2, y + 2, Color( 0, 0, 0, 50 ), align )
		draw.DrawText( text, font, x, y, col or color_white, align )
	cam.End2D()
end

function ENT:DrawTranslucent()
	local ply = LocalPlayer()

	if not IsValid( ply ) or ply:InVehicle() then return end

	local KeySprint = ply:KeyDown( IN_SPEED )
	local InRange = self:InRange( ply, self.UseRange )

	if LVS.ShowDoorInfo and InRange then
		local pos = (self:LocalToWorld( self:GetMins() ) + self:LocalToWorld( self:GetMaxs() )) * 0.5

		local NameKeyUse = "["..(input.LookupBinding( "+walk" ) or "+walk is not bound to a key").."]"
		local NameKeySprint = "["..(input.LookupBinding( "+speed" ) or "+speed is not bound to a key").."]"

		local boxOrigin = self:GetPos()
		local boxAngles = self:GetAngles()
		local boxMins = self:GetMins()
		local boxMaxs = self:GetMaxs()

		if self:IsOpen() then
			local LinkedSeat = self:GetLinkedSeat()

			if IsValid( LinkedSeat ) then
				if not KeySprint then
					render.DrawWireframeBox( boxOrigin, boxAngles, boxMins, boxMaxs, self.ColorBlack )
					render.DrawWireframeBox( LinkedSeat:GetPos(), LinkedSeat:GetAngles(), LinkedSeat:OBBMins(), LinkedSeat:OBBMaxs(), color_white )

					DrawText( pos, NameKeyUse.." \n".."Enter ", TEXT_ALIGN_RIGHT )
					DrawText( pos, " "..NameKeySprint.."\n".." Close", TEXT_ALIGN_LEFT, self.ColorBlack )
				else
					render.DrawWireframeBox( LinkedSeat:GetPos(), LinkedSeat:GetAngles(), LinkedSeat:OBBMins(), LinkedSeat:OBBMaxs(), self.ColorBlack )
					render.DrawWireframeBox( boxOrigin, boxAngles, boxMins, boxMaxs, color_white )

					DrawText( pos, NameKeySprint.." \n".."Enter ", TEXT_ALIGN_RIGHT, self.ColorBlack )
					DrawText( pos, " "..NameKeyUse.."\n".." Close", TEXT_ALIGN_LEFT )
				end
			else
				DrawText( pos, NameKeyUse.."\n".."Close", TEXT_ALIGN_CENTER )
				render.DrawWireframeBox( boxOrigin, boxAngles, boxMins, boxMaxs, color_white )
			end
		else
			DrawText( pos, NameKeyUse.."\n".."Open", TEXT_ALIGN_CENTER )
			render.DrawWireframeBox( boxOrigin, boxAngles, boxMins, boxMaxs, color_white )
		end
	end

	if not KeySprint then return end

	if InRange then
		local EntTable = self:GetTable()

		local Use = ply:KeyDown( IN_USE )

		if EntTable.old_Use ~= Use then
			EntTable.old_Use = Use

			if Use then
				net.Start( "lvs_doorhandler_interact" )
					net.WriteEntity( self )
				net.SendToServer()
			end
		end
	end

	if not LVS.DeveloperEnabled then return end

	local boxOrigin = self:GetPos()
	local boxAngles = self:GetAngles()
	local boxMins = self:GetMins()
	local boxMaxs = self:GetMaxs()

	local EntTable = self:GetTable()

	local Col = InRange and EntTable.ColorSelect or EntTable.ColorNormal

	render.SetColorMaterial()
	render.DrawBox( boxOrigin, boxAngles, boxMins, boxMaxs, Col )
	render.DrawBox( boxOrigin, boxAngles, boxMaxs + EntTable.OutlineThickness, boxMins - EntTable.OutlineThickness, EntTable.ColorTransBlack )
end
