AddCSLuaFile()

ENT.Type            = "anim"
ENT.DoNotDuplicate = true

ENT.RenderGroup = RENDERGROUP_BOTH 

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )

	self:NetworkVar( "Float",0, "HP" )
	self:NetworkVar( "Float",1, "MaxHP" )
	self:NetworkVar( "Float",2, "IgnoreForce" )

	self:NetworkVar( "Vector",0, "Mins" )
	self:NetworkVar( "Vector",1, "Maxs" )

	self:NetworkVar( "Bool",0, "Destroyed" )

	self:NetworkVar( "String",0, "Label" )

	if SERVER then
		self:SetMaxHP( 100 )
		self:SetHP( 100 )
		self:SetLabel( "Armor Plate" )
	end
end

if SERVER then
	function ENT:Initialize()	
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )
	end

	function ENT:Think()
		return false
	end

	function ENT:OnHealthChanged( dmginfo, old, new )
		if old == new then return end
	end

	function ENT:OnRepaired()
	end

	function ENT:OnDestroyed( dmginfo )
	end

	function ENT:OnTakeDamage( dmginfo )
	end

	function ENT:TakeTransmittedDamage( dmginfo )
		local Force = dmginfo:GetDamageForce()

		local Damage = dmginfo:GetDamage()
		local DamageForce = Force:Length()
		local IsBlastDamage = dmginfo:IsDamageType( DMG_BLAST )

		local CurHealth = self:GetHP()

		local pos = dmginfo:GetDamagePosition()
		local dir = Force:GetNormalized()

		local base = self:GetBase()

		-- translate force value to armor penetration value is Force * 0.1
		-- mm to inch is * 0.0393701
		-- so correct value is * 0.00393701
		local pLength = DamageForce * 0.00393701

		local TraceData = {
			start = pos - dir * pLength,
			endpos = pos + dir * pLength,
		}

		local trace = util.TraceLine( TraceData )

		-- parent stays the same
		local parent = trace.Entity
		local parentPos = trace.HitPos
		local parentDir = trace.HitNormal

		-- only one extra iteration should be enough ...
		if IsValid( trace.Entity ) and isfunction( trace.Entity.GetBase ) and trace.Entity:GetBase() == base then

			TraceData.filter = trace.Entity

			local FilteredTrace = util.TraceLine( TraceData )

			if FilteredTrace.Hit then
				trace = FilteredTrace
			end

			trace.Entity = base
		end

		local DotHitNormal = math.Clamp( trace.HitNormal:Dot( dir ) ,-1,1) 

		local Armor = self:GetIgnoreForce()
		local ArmorEffective = Armor / math.abs( DotHitNormal )

		if math.abs( DotHitNormal ) > 0.9 then
			ArmorEffective = Armor
		end

		local DisableBounce = false

		local Inflictor = dmginfo:GetInflictor()

		if IsValid( Inflictor ) then
			if Inflictor.DisableBallistics or Inflictor:IsNPC() or Inflictor:IsNextBot() then
				DisableBounce = true
			end
		end

		if DamageForce <= ArmorEffective and not IsBlastDamage then
			local T = CurTime()

			if trace.Entity ~= base then
				self._NextBounce = T + 1

				return false
			end

			local Ax = math.acos( DotHitNormal )
			local HitAngle = 90 - (180 - math.deg( Ax ))

			if HitAngle > 30 then
				local effectdata = EffectData()
					effectdata:SetOrigin( trace.HitPos )
					effectdata:SetNormal( -dir )
				util.Effect( "manhacksparks", effectdata, true, true )
	
				self._NextBounce = T + 1

				return false
			end

			local NewDir = dir - trace.HitNormal * math.cos( Ax ) * 2

			if (self._NextBounce or 0) > T or DisableBounce then
				local effectdata = EffectData()
					effectdata:SetOrigin( trace.HitPos )
					effectdata:SetNormal( NewDir:GetNormalized() * 0.25 )
				util.Effect( "manhacksparks", effectdata, true, true )

				return false
			end

			self._NextBounce = T + 1

			local hit_decal = ents.Create( "lvs_armor_bounce" )
			hit_decal:SetPos( trace.HitPos )
			hit_decal:SetAngles( NewDir:Angle() )
			hit_decal:Spawn()
			hit_decal:Activate()
			hit_decal:EmitSound("lvs/armor_rico"..math.random(1,6)..".wav", 95, 100, math.min( dmginfo:GetDamage() / 1000, 1 ) )

			local PhysObj = hit_decal:GetPhysicsObject()
			if not IsValid( PhysObj ) then return false end

			PhysObj:EnableDrag( false )
			PhysObj:SetVelocityInstantaneous( NewDir * 2000 + Vector(0,0,250) )
			PhysObj:SetAngleVelocityInstantaneous( VectorRand() * 250 )

			return false
		end

		local NewHealth = math.Clamp( CurHealth - Damage, 0, self:GetMaxHP() )

		self:OnHealthChanged( dmginfo, CurHealth, NewHealth )
		self:SetHP( NewHealth )

		if NewHealth <= 0 and not self:GetDestroyed() then
			self:SetDestroyed( true )
			self:OnDestroyed( dmginfo )
		end

		local hit_decal = ents.Create( "lvs_armor_penetrate" )
		hit_decal:SetPos( parentPos + parentDir * 0.2 )
		hit_decal:SetAngles( parentDir:Angle() + Angle(90,0,0) )
		hit_decal:Spawn()
		hit_decal:Activate()
		hit_decal:SetParent( parent )

		return true
	end

	return
end

function ENT:Initialize()
end

function ENT:OnRemove()
end

function ENT:Think()
end


function ENT:Draw()
end

local function DrawText( pos, text, col )
	cam.Start2D()
		local data2D = pos:ToScreen()

		if not data2D.visible then cam.End2D() return end

		local font = "TargetIDSmall"

		local x = data2D.x
		local y = data2D.y

		draw.DrawText( text, font, x + 1, y + 1, Color( 0, 0, 0, 120 ), TEXT_ALIGN_CENTER )
		draw.DrawText( text, font, x + 2, y + 2, Color( 0, 0, 0, 50 ), TEXT_ALIGN_CENTER )
		draw.DrawText( text, font, x, y, col or color_white, TEXT_ALIGN_CENTER )
	cam.End2D()
end

local LVS = LVS
local BoxMat = Material("models/wireframe")
local ColorSelect = Color(0,127,255,150)
local ColorNormal = Color(50,50,50,150)
local ColorTransBlack = Color(0,0,0,150)
local OutlineThickness = Vector(0.5,0.5,0.5)
local ColorText = Color(255,0,0,255)

function ENT:DrawTranslucent()
	if not LVS.DeveloperEnabled then return end

	local ply = LocalPlayer()

	if not IsValid( ply ) or ply:InVehicle() or not ply:KeyDown( IN_SPEED ) then return end

	local boxOrigin = self:GetPos()
	local boxAngles = self:GetAngles()
	local boxMins = self:GetMins()
	local boxMaxs = self:GetMaxs()

	local HitPos, _, _ = util.IntersectRayWithOBB( ply:GetShootPos(), ply:GetAimVector() * 1000, boxOrigin, boxAngles, boxMins, boxMaxs )

	local InRange = isvector( HitPos )

	local Col = InRange and ColorSelect or ColorNormal

	render.SetColorMaterial()
	render.DrawBox( boxOrigin, boxAngles, boxMins, boxMaxs, Col )
	render.DrawBox( boxOrigin, boxAngles, boxMaxs + OutlineThickness, boxMins - OutlineThickness, ColorTransBlack )

	local boxCenter = (self:LocalToWorld( boxMins ) + self:LocalToWorld( boxMaxs )) * 0.5

	if not InRange then return end

	DrawText( boxCenter, "Armor: "..(self:GetIgnoreForce() / 100).."mm\nHealth:"..self:GetHP().."/"..self:GetMaxHP(), ColorText )
end
