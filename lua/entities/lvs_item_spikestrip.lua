AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "Spike Strip"
ENT.Author = "Luna"
ENT.Information = "Pops Tires"
ENT.Category = "[LVS]"

ENT.Spawnable		= true
ENT.AdminOnly		= false

ENT.RenderGroup = RENDERGROUP_BOTH 

ENT.PhysicsSounds = true

if SERVER then
	function ENT:SetAttacker( ent ) self._attacker = ent end
	function ENT:GetAttacker() return self._attacker or self end

	function ENT:SpawnFunction( ply, tr, ClassName )
		if not tr.Hit then return end

		local ent = ents.Create( ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal )
		ent:Spawn()
		ent:Activate()
		ent:SetAttacker( ply )

		return ent
	end

	function ENT:OnTakeDamage( dmginfo )
	end

	function ENT:Initialize()
		self:SetModel( "models/diggercars/shared/spikestrip_static.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetTrigger( true )
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
		self:AddEFlags( EFL_NO_PHYSCANNON_INTERACTION )
	end

	function ENT:UpdateFold()
	end
	
	function ENT:Think()
		local PhysObj = self:GetPhysicsObject()

		if IsValid( PhysObj ) and PhysObj:IsMotionEnabled() then
			if PhysObj:IsAsleep() then
				PhysObj:EnableMotion( false )
			end
		end

		self:UpdateFold()

		self:NextThink( CurTime() )

		return true
	end

	function ENT:Use( ply )
	end

	function ENT:OnRemove()
	end

	function ENT:PhysicsCollide( data, physobj )
	end

	function ENT:StartTouch( entity )
	end

	function ENT:EndTouch( entity )
	end

	function ENT:Touch( entity )
		if not IsValid( entity ) or entity:GetClass() ~= "lvs_wheeldrive_wheel" then return end

		local Destroy = entity:GetVelocity():Length() > 200

		if not Destroy then
			for i = 1,3 do
				local L = self:LookupAttachment( "l"..i )
				local R = self:LookupAttachment( "r"..i )

				local attL = self:GetAttachment( L )
				local attR = self:GetAttachment( R )

				if not attL or not attR then continue end

				local trace = util.TraceLine( {
					start = attL.Pos,
					endpos = attR.Pos,
					filter = entity,
					whitelist = true,
				} )

				if trace.Hit then
					Destroy = true

					break
				end
			end
		end

		if not Destroy then return end

		local T = CurTime()

		if (entity._LastSpikeStripPop or 0) > T then return end

		entity._LastSpikeStripPop = T + 2

		local dmginfo = DamageInfo()
		dmginfo:SetDamage( entity:GetHP() )
		dmginfo:SetAttacker( self:GetAttacker() )
		dmginfo:SetDamageType( DMG_PREVENT_PHYSICS_FORCE ) 

		entity:TakeDamageInfo( dmginfo )

		local base = entity:GetBase()

		if not IsValid( base ) then return end

		local PhysObj = base:GetPhysicsObject()

		if not IsValid( PhysObj ) then return end

		PhysObj:ApplyTorqueCenter( Vector(0,0, PhysObj:GetVelocity():Length() * 100 * (PhysObj:GetAngleVelocity().z > 0 and 1 or -1) ) )
	end

	return
end

function ENT:Think()
end

function ENT:Draw( flags )
	self:DrawModel( flags )
end

local spritemat = Material( "sprites/light_glow02_add" )
local spritecolor = Color( 255, 93, 0, 255)

function ENT:DrawTranslucent( flags )
	self:DrawModel( flags )

	local size1 = 16 * (math.abs( math.cos( CurTime() * 4 ) ) ^ 10)
	local size2 = 16 * (math.abs( math.sin( CurTime() * 4 ) ) ^ 10)

	render.SetMaterial( spritemat )
	render.DrawSprite( self:LocalToWorld( Vector(8,-116.5,10) ), size1, size1, spritecolor )
	render.DrawSprite( self:LocalToWorld( Vector(-7,-116.5,10) ), size2, size2, spritecolor )
	render.DrawSprite( self:LocalToWorld( Vector(8,118,10) ), size2, size2, spritecolor )
	render.DrawSprite( self:LocalToWorld( Vector(-7,118,10) ), size1, size1, spritecolor )
end

function ENT:OnRemove()
end