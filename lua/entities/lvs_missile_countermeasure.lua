AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "Flare"
ENT.Author = "Luna"
ENT.Information = "LVS Flare"
ENT.Category = "[LVS]"

ENT.Spawnable		= true
ENT.AdminOnly		= true

ENT.lvsFlare = true

function ENT:SetupDataTables()
	self:NetworkVar( "Float",0, "DieTime" )
	self:NetworkVar( "Float",1, "NWLifeTime" )
	self:NetworkVar( "Entity",0, "Vehicle" )

	if SERVER then
		self:SetDieTime( CurTime() + 5 )
		self:SetNWLifeTime( 5 )
	end
end

function ENT:SetLifeTime( time )
	self:SetDieTime( CurTime() + time )
	self:SetNWLifeTime( time )
end

function ENT:GetLifeTime()
	return self:GetNWLifeTime()
end

function ENT:GetIntensity()
	return math.Clamp( ((self:GetDieTime() - CurTime()) / self:GetLifeTime()) * 8,0,1) ^ 2
end

if SERVER then
	function ENT:SpawnFunction( ply, tr, ClassName )

		local ent = ents.Create( ClassName )
		ent:SetPos( ply:GetShootPos() )
		ent:SetAngles( ply:EyeAngles() )
		ent:Spawn()
		ent:Activate()

		local PhysObj = ent:GetPhysicsObject()

		if IsValid( PhysObj ) then
			PhysObj:SetVelocityInstantaneous( ply:GetAimVector() * 2500 )
		end

		ent:SetLifeTime( 2 )

		return ent
	end

	function ENT:Initialize()	
		self:SetModel( "models/maxofs2d/hover_classic.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:PhysWake()
		self:DrawShadow( false )
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )

		LVS:AddFlare( self )
	end

	function ENT:Think()
		local T = CurTime()

		if self:GetDieTime() < T or self:WaterLevel() >= 2 then
			self:Remove()

			return false
		end

		self:NextThink( T + 0.1 )

		return true
	end

	function ENT:PhysicsCollide( data )
	end

	function ENT:OnTakeDamage( dmginfo )	
	end
else
	function ENT:Initialize()
		self.snd = CreateSound(self, "weapons/flaregun/burn.wav")
		self.snd:SetSoundLevel( 80 )
		self.snd:PlayEx(0.5,100)

		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
			effectdata:SetEntity( self )
		util.Effect( "lvs_countermissile_trail", effectdata )

		LVS:AddFlareToHUD( self )
	end

	function ENT:IsVisible()
		local EntTable = self:GetTable()

		if not EntTable.PixVis then
			EntTable.PixVis = util.GetPixelVisibleHandle()
		end

		return util.PixelVisible( self:GetPos(), 256, EntTable.PixVis ) > 0.1
	end

	function ENT:Draw()
	end

	function ENT:CalcDoppler()
		local Ent = LocalPlayer()

		local ViewEnt = Ent:GetViewEntity()

		if Ent:lvsGetVehicle() == self then
			if ViewEnt == Ent then
				Ent = self
			else
				Ent = ViewEnt
			end
		else
			Ent = ViewEnt
		end

		local sVel = self:GetVelocity()
		local oVel = Ent:GetVelocity()

		local SubVel = oVel - sVel
		local SubPos = self:GetPos() - Ent:GetPos()

		local DirPos = SubPos:GetNormalized()
		local DirVel = SubVel:GetNormalized()

		local A = math.acos( math.Clamp( DirVel:Dot( DirPos ) ,-1,1) )

		return (1 + math.cos( A ) * SubVel:Length() / 13503.9)
	end

	function ENT:Think()
		local EntTable = self:GetTable()

		if not EntTable.snd then return end

		local Intensity = self:GetIntensity()
		EntTable.snd:ChangeVolume( Intensity * 0.5, 0.1 )
		EntTable.snd:ChangePitch( 100 * self:CalcDoppler() )
	end

	function ENT:SoundStop()
		if not self.snd then return end

		self.snd:Stop()
	end

	function ENT:OnRemove()
		self:SoundStop()

		self.PixVis = nil
	end
end
