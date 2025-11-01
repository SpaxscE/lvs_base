AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "Jerry Can (Petrol)"
ENT.Author = "Luna"
ENT.Category = "[LVS]"

ENT.Spawnable		= true
ENT.AdminOnly		= false

ENT.AutomaticFrameAdvance = true

ENT.FuelAmount = 500 -- seconds
ENT.FuelType = LVS.FUELTYPE_PETROL

ENT.lvsGasStationFillSpeed = 0.05
ENT.lvsGasStationRefillMe = true

ENT.PhysicsSounds = true

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Active" )
	self:NetworkVar( "Float", 0, "Fuel" )
	self:NetworkVar( "Entity",0, "User" )

	if SERVER then
		self:SetFuel( 1 )
	end
end

function ENT:IsOpen()
	return self:GetActive()
end

function ENT:IsUpright()
	local Up = self:GetUp()

	return Up.z > 0.5
end

function ENT:GetFuelType()
	return self.FuelType
end

function ENT:GetSize()
	return (self.FuelAmount * LVS.FuelScale)
end

function ENT:GetFuelType()
	return self.FuelType
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

	function ENT:Initialize()	
		self:SetModel( "models/misc/fuel_can.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
	end

	function ENT:OnRefueled()
		self:EmitSound( "vehicles/jetski/jetski_no_gas_start.wav" )
	end

	function ENT:TakeFuel( Need )
		local Fuel = self:GetFuel()
		local Size = self:GetSize()
		local Available = math.min( Size * Fuel, Size* self.lvsGasStationFillSpeed )
		local Give = math.min( Need, Available )

		self:SetFuel( Fuel - Give / Size )

		return Give
	end

	function ENT:giveSWEP( ply )
		self:EmitSound("common/wpn_select.wav")

		ply:SetSuppressPickupNotices( true )
		ply:Give( "weapon_lvsfuelfiller" )
		ply:SetSuppressPickupNotices( false )

		ply:SelectWeapon( "weapon_lvsfuelfiller" )
		self:SetUser( ply )

		local SWEP = ply:GetWeapon( "weapon_lvsfuelfiller" )
	
		if not IsValid( SWEP ) then return end

		SWEP:SetFuelType( self:GetFuelType() )
		SWEP:SetCallbackTarget( self )
	end

	function ENT:removeSWEP( ply )
		if ply:HasWeapon( "weapon_lvsfuelfiller" ) then
			ply:StripWeapon( "weapon_lvsfuelfiller" )
			ply:SwitchToDefaultWeapon()
		end
		self:SetUser( NULL )
	end

	function ENT:checkSWEP( ply )
		if not ply:Alive() or ply:InVehicle() then

			self:removeSWEP( ply )

			return
		end

		local weapon = ply:GetActiveWeapon()

		if not IsValid( weapon ) or weapon:GetClass() ~= "weapon_lvsfuelfiller" then
			self:removeSWEP( ply )

			return
		end

		if (ply:GetPos() - self:GetPos()):LengthSqr() < 150000 then return end

		self:removeSWEP( ply )
	end

	function ENT:Think()
		if self:IsOpen() and not self:IsUpright() then
			local amount = FrameTime() * 0.25

			self:SetFuel( math.max( self:GetFuel() - amount, 0 ) )
		end

		local ply = self:GetUser()
		local T = CurTime()

		if IsValid( ply ) then
			self:checkSWEP( ply )
		end

		self:NextThink( T )

		return true
	end

	function ENT:Use( ply )
		if not IsValid( ply ) or not ply:IsPlayer() then return end

		local Active = self:GetActive()
		local User = self:GetUser()

		if IsValid( User ) and User == ply then
			self:removeSWEP( ply )
			self:PlayAnimation( "close" )
			self:SetActive( false )

			return
		end

		if Active then
			if ply:HasWeapon("weapon_lvsfuelfiller") or ply:KeyDown( IN_WALK ) or ply:KeyDown( IN_SPEED ) then
				self:PlayAnimation( "close" )
				self:SetActive( false )
			else
				if not IsValid( User ) then
					self:giveSWEP( ply )
				end
			end
	
			return
		end

		self:SetActive ( true )
		self:PlayAnimation( "open" )
		self:EmitSound("buttons/lever7.wav")
	end

	function ENT:OnRemove()
		local User = self:GetUser()

		if not IsValid( User ) then return end

		self:removeSWEP( User )
	end

	function ENT:PhysicsCollide( data, physobj )
	end

	function ENT:OnTakeDamage( dmginfo )
	end

	function ENT:PlayAnimation( animation, playbackrate )
		playbackrate = playbackrate or 1

		local sequence = self:LookupSequence( animation )

		self:ResetSequence( sequence )
		self:SetPlaybackRate( playbackrate )
		self:SetSequence( sequence )
	end
end

if CLIENT then
	ENT.FrameMat = Material( "lvs/3d2dmats/frame.png" )
	ENT.RefuelMat = Material( "lvs/3d2dmats/refuel.png" )

	function ENT:Draw()
		self:DrawModel()
		self:DrawCable()

		local ply = LocalPlayer()
		local Pos = self:GetPos()

		if not IsValid( ply ) then return end

		if ply:HasWeapon("weapon_lvsfuelfiller") then return end

		if (ply:GetPos() - Pos):LengthSqr() > 5000000 then return end

		local data = LVS.FUELTYPES[ self.FuelType ]
		local Text = data.name
		local IconColor = Color( data.color.x, data.color.y, data.color.z, 255 )

		for i = -1, 1, 2 do
			cam.Start3D2D( self:LocalToWorld( Vector(0,4 * i,0) ), self:LocalToWorldAngles( Angle(0,90 + 90 * i,90) ), 0.1 )
				surface.SetDrawColor( IconColor )

				surface.SetMaterial( self.FrameMat )
				surface.DrawTexturedRect( -50, -50, 100, 100 )

				surface.SetMaterial( self.RefuelMat )
				surface.DrawTexturedRect( -50, -50, 100, 100 )

				draw.SimpleText( Text, "LVS_FONT", 0, 75, IconColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

				draw.SimpleText( math.Round( self:GetFuel() * 100, 0 ).."%", "LVS_FONT", 0, 95, IconColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			cam.End3D2D()
		end
	end

	local cable = Material( "cable/cable2" )
	local function bezier(p0, p1, p2, p3, t)
		local e = p0 + t * (p1 - p0)
		local f = p1 + t * (p2 - p1)
		local g = p2 + t * (p3 - p2)

		local h = e + t * (f - e)
		local i = f + t * (g - f)

		local p = h + t * (i - h)

		return p
	end

	function ENT:DrawCable()
		local plyL = LocalPlayer()

		if not IsValid( plyL ) then return end

		if plyL:GetPos():DistToSqr( self:GetPos() ) > 350000 then return end

		local ply = self:GetUser()

		if not IsValid( ply ) then return end

		local pos = self:LocalToWorld( Vector(10,0,45) )
		local ang = self:LocalToWorldAngles( Angle(0,90,90) )

		local startPos = self:LocalToWorld( Vector(7,0,5) )
		local p2 = self:LocalToWorld( Vector(8,0,40) )
		local p3
		local endPos

		local id = ply:LookupAttachment("anim_attachment_rh")
		local attachment = ply:GetAttachment( id )

		if not attachment then return end

		endPos = (attachment.Pos + attachment.Ang:Forward() * -3 + attachment.Ang:Right() * 2 + attachment.Ang:Up() * -3.5)
		p3 = endPos + attachment.Ang:Right() * 5 - attachment.Ang:Up() * 20

		render.StartBeam( 15 )
		render.SetMaterial( cable )

		for i = 0,15 do
			local pos = bezier(startPos, p2, p3, endPos, i / 14)

			local Col = (render.GetLightColor( pos ) * 0.8 + Vector(0.2,0.2,0.2)) * 255

			render.AddBeam( pos, 1, 0, Color(Col.r,Col.g,Col.b,255) )
		end

		render.EndBeam()
	end

	function ENT:OnRemove()
		self:StopPour()
	end

	function ENT:StartPour()
		if self.snd then return end

		self.snd =  CreateSound( self, "lvs/jerrycan_use.wav" )
		self.snd:PlayEx(0.5,80)
		self.snd:ChangePitch(120,3)
	end

	function ENT:StopPour()
		if not self.snd then return end

		self.snd:Stop()
		self.snd = nil
	end

	function ENT:DoEffect()
		local Up = self:GetUp()
		local Pos = self:LocalToWorld( Vector(7.19,-0.01,10.46) )

		local emitter = ParticleEmitter( Pos, false )
		local particle = emitter:Add( "effects/slime1", Pos )

		if particle then
			particle:SetVelocity( Up * math.abs( Up.z ) * 100 )
			particle:SetGravity( Vector( 0, 0, -600 ) )
			particle:SetDieTime( 2 )
			particle:SetAirResistance( 0 ) 
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 1.5 )
			particle:SetEndSize( 1.5 )
			particle:SetRoll( math.Rand( -1, 1 ) )
			particle:SetColor( 240,200,0,255 )
			particle:SetCollide( true )
			particle:SetCollideCallback( function( part, hitpos, hitnormal )
				local effectdata = EffectData() 
					effectdata:SetOrigin( hitpos ) 
					effectdata:SetNormal( hitnormal * 2 ) 
					effectdata:SetMagnitude( 0.2 ) 
					effectdata:SetScale( 0.2 ) 
					effectdata:SetRadius( 0.2 ) 
				util.Effect( "StriderBlood", effectdata )

				sound.Play( "ambient/water/water_spray"..math.random(1,3)..".wav", hitpos, 55, math.Rand(95,105), 0.5 )

				particle:SetDieTime( 0 )

				if not IsValid( self ) then return false end

				if not self.LastPos then self.LastPos = hitpos end

				if (self.LastPos - hitpos):Length() < 10 then
					return
				end

				self.LastPos = hitpos

				util.Decal( "BeerSplash", hitpos + hitnormal * 2, hitpos - hitnormal * 2 )
			end )
		end

		emitter:Finish()
	end

	function ENT:Think()
		self:SetNextClientThink( CurTime() + 0.02 )

		if self:GetFuel() <= 0 then self:StopPour() return end

		local T = CurTime()

		if not self:IsOpen() or self:IsUpright() then

			self:StopPour()

			return true
		end

		self:StartPour()

		self:DoEffect()

		return true
	end
end