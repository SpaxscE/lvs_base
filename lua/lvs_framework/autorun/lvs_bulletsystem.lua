local LVS = LVS

LVS._ActiveBullets = {}

function LVS:RemoveBullet( index )
	LVS._ActiveBullets[ index ] = nil
end

function LVS:GetBullet( index )
	if not LVS._ActiveBullets then return end

	return LVS._ActiveBullets[ index ]
end

local NewBullet = {}
NewBullet.__index = NewBullet 

function NewBullet:SetPos( pos )
	self.curpos = pos
end

function NewBullet:GetBulletIndex()
	return self.bulletindex
end

function NewBullet:Remove()
	local index = self.bulletindex

	if SERVER then
		-- prevents ghost bullets if the client fails to detect the hit
		net.Start( "lvs_remove_bullet", true )
			net.WriteInt( index, 13 )
		net.SendPVS( self:GetPos() )
	end

	LVS:RemoveBullet( index )
end

function NewBullet:GetPos()
	if not self.curpos then return self.Src end

	return self.curpos
end

function NewBullet:SetGravity( new )
	self.Gravity = new
end

function NewBullet:GetGravity()
	return self.Gravity or vector_origin
end

function NewBullet:GetDir()
	return self.Dir or vector_origin
end

function NewBullet:SetDir( newdir )
	self.Dir = newdir
end

function NewBullet:GetTimeAlive()
	return CurTime() - self.StartTime
end

function NewBullet:GetSpawnTime()
	if SERVER then
		return self.StartTime
	else
		return math.min( self.StartTimeCL, CurTime() ) -- time when the bullet is received on client
	end
end

function NewBullet:GetLength()
	return math.min((CurTime() - self:GetSpawnTime()) * 14,1)
end

function NewBullet:HandleWaterImpact( traceStart, traceEnd, Filter )
	if self.HasHitWater then return end

	local traceWater = util.TraceLine( {
		start = traceStart,
		endpos = traceEnd,
		filter = Filter,
		mask = MASK_WATER,
	} )

	if not traceWater.Hit then return end

	self.HasHitWater = true

	local effectdata = EffectData()
	effectdata:SetOrigin( traceWater.HitPos )
	effectdata:SetScale( 10 + self.HullSize * 0.5 )
	effectdata:SetFlags( 2 )
	util.Effect( "WaterSplash", effectdata, true, true )
end

function NewBullet:HandleFlybySound( EarPos )
	if self.Muted or not LVS.EnableBulletNearmiss then return end

	local BulletPos = self:GetPos()

	local EarDist = (EarPos - BulletPos):LengthSqr()

	if self.OldEarDist and self.OldEarDist < EarDist then

		if EarDist < 250000 then
			local effectdata = EffectData()
			effectdata:SetOrigin( EarPos + (BulletPos - EarPos):GetNormalized() * 20 )
			effectdata:SetFlags( 2 )
			util.Effect( "TracerSound", effectdata )
		end

		self.Muted = true
	end

	self.OldEarDist = EarDist
end

function NewBullet:DoBulletFlight( TimeAlive )

	local StartPos = self.Src
	local StartDirection = self.StartDir

	local Velocity = self.Velocity

	local PosOffset

	-- startpos, direction and curtime of creation is networked to client. 
	-- the bullet position is simulated by doing startpos + dir * time * velocity
	if self.EnableBallistics then
		local PosTheoretical = StartDirection * TimeAlive * Velocity

		PosOffset = PosTheoretical + self:GetGravity() * (TimeAlive ^ 2)

		self:SetDir( (StartPos + PosOffset - StartPos):GetNormalized() )
	else
		PosOffset = self.Dir * TimeAlive * Velocity
	end

	if SERVER then
		self:SetPos( StartPos + PosOffset )
	else

		-- "parent" the bullet to the vehicle for a very short time on client. This will give the illusion of the bullet not lagging behind even tho it is fired later on client
		if IsValid( self.Entity ) and self.SrcEntity then
			local mul = self:GetLength()
			local inv = 1 - mul

			self:SetPos( StartPos * mul + self.Entity:LocalToWorld( self.SrcEntity ) * inv + PosOffset )

			return
		end

		-- if no parent detected, run same code as server
		self:SetPos( StartPos + PosOffset )
	end
end

function NewBullet:OnCollide( trace )
	if CLIENT then return end

	if trace.Entity == self.LastDamageTarget then return end

	local Attacker = (IsValid( self.Attacker ) and self.Attacker) or (IsValid( self.Entity ) and self.Entity) or game.GetWorld()
	local Inflictor = (IsValid( self.Entity ) and self.Entity) or (IsValid( self.Attacker ) and self.Attacker) or game.GetWorld()

	local dmginfo = DamageInfo()
	dmginfo:SetDamage( self.Damage )
	dmginfo:SetAttacker( Attacker )
	dmginfo:SetInflictor( Inflictor )
	dmginfo:SetDamageType( DMG_AIRBOAT )
	dmginfo:SetDamagePosition( trace.HitPos )

	if self.Force1km then
		local Mul = math.min( (self.Src - trace.HitPos):Length() / 39370, 1 )
		local invMul = math.max( 1 - Mul, 0 )

		dmginfo:SetDamageForce( self.Dir * (self.Force * invMul + self.Force1km * Mul) )
	else
		dmginfo:SetDamageForce( self.Dir * self.Force )
	end

	if self.Callback then
		self.Callback( Attacker, trace, dmginfo )
	end

	if trace.Entity:GetClass() == "func_breakable_surf" then
		-- this will cause the entire thing to just fall apart
		dmginfo:SetDamageType( DMG_BLAST )
	end

	trace.Entity:DispatchTraceAttack( dmginfo, trace )

	self.LastDamageTarget = trace.Entity
end

function NewBullet:OnCollideFinal( trace )
	if CLIENT then return end

	self:OnCollide( trace )

	if not self.SplashDamage or not self.SplashDamageRadius then return end

	local effectdata = EffectData()
	effectdata:SetOrigin( trace.HitPos )
	effectdata:SetNormal( trace.HitWorld and trace.HitNormal or self.Dir )
	effectdata:SetMagnitude( self.SplashDamageRadius / 250 )
	util.Effect( self.SplashDamageEffect, effectdata )

	local Attacker = (IsValid( self.Attacker ) and self.Attacker) or (IsValid( self.Entity ) and self.Entity) or game.GetWorld()
	local Inflictor = (IsValid( self.Entity ) and self.Entity) or (IsValid( self.Attacker ) and self.Attacker) or game.GetWorld()

	LVS:BlastDamage( trace.HitPos, self.Dir, Attacker, Inflictor, self.SplashDamage, self.SplashDamageType, self.SplashDamageRadius, self.SplashDamageForce )
end

function NewBullet:HandleCollision( traceStart, traceEnd, Filter )
	local TraceMask = self.HullSize <= 1 and MASK_SHOT_PORTAL or MASK_SHOT_HULL

	local traceLine
	local traceHull

	if self.HullTraceResult then
		traceHull = self.HullTraceResult
	else
		traceLine = util.TraceLine( {
			start = traceStart,
			endpos = traceEnd,
			filter = Filter,
			mask = TraceMask
		} )

		local trace = util.TraceHull( {
			start = traceStart,
			endpos = traceEnd,
			filter = Filter,
			mins = self.Mins,
			maxs = self.Maxs,
			mask = TraceMask,
			ignoreworld = true
		} )

		if traceLine.Entity == trace.Entity and trace.Hit and traceLine.Hit then
			trace = traceLine
		end

		if trace.Hit then
			self.HullTraceResult = trace
			traceHull = trace

			self:OnCollide( trace )
		else
			traceHull = { Hit = false }
		end
	end

	if not traceLine then
		traceLine = util.TraceLine( {
			start = traceStart,
			endpos = traceEnd,
			filter = Filter,
			mask = TraceMask
		} )
	end

	if not traceLine.Hit then
		return
	end

	self:OnCollideFinal( traceLine )

	self:Remove()

	if SERVER then return end

	if not traceLine.HitSky then
		local effectdata = EffectData()
		effectdata:SetOrigin( traceLine.HitPos )
		effectdata:SetEntity( traceLine.Entity )
		effectdata:SetStart( traceStart )
		effectdata:SetNormal( traceLine.HitNormal )
		effectdata:SetSurfaceProp( traceLine.SurfaceProps )
		util.Effect( "Impact", effectdata )
	end
end

local function GetEarPos()
	if SERVER then return vector_origin end

	local EarPos

	local ply = LocalPlayer()
	local ViewEnt = ply:GetViewEntity()

	if ViewEnt == ply then
		if IsValid( ply:lvsGetVehicle() ) then
			EarPos = ply:lvsGetView()
		else
			EarPos = ply:GetShootPos()
		end
	else
		EarPos = ViewEnt:GetPos()
	end

	return EarPos
end

local function HandleBullets()
	local T = CurTime()
	local FT = FrameTime()

	local EarPos = GetEarPos()

	for id, bullet in pairs( LVS._ActiveBullets ) do
		if bullet:GetSpawnTime() + 5 < T then -- destroy all bullets older than 5 seconds
			bullet:Remove()

			continue
		end

		local TimeAlive = bullet:GetTimeAlive()

		if TimeAlive < 0 then continue end -- CurTime() is predicted, this can be a negative number in some cases.

		local Filter = bullet.Filter

		local traceStart = bullet:GetPos()
			bullet:DoBulletFlight( TimeAlive )
		local traceEnd = bullet:GetPos()

		if CLIENT then
			--debugoverlay.Line( traceStart, traceEnd, Color( 255, 255, 255 ), true )

			-- bullet flyby sounds
			bullet:HandleFlybySound( EarPos )

			-- bullet water impact effects
			bullet:HandleWaterImpact( traceStart, traceEnd, Filter )
		end

		bullet:HandleCollision( traceStart, traceEnd, Filter )
	end
end

local vector_one = Vector(1,1,1)

if SERVER then
	util.AddNetworkString( "lvs_fire_bullet" )
	util.AddNetworkString( "lvs_remove_bullet" )

	hook.Add( "Tick", "!!!!lvs_bullet_handler", function( ply, ent ) -- from what i understand, think can "skip" on lag, while tick still simulates all steps
		HandleBullets()
	end )

	local Index = 0
	local MaxIndex = 4094 -- this is the util.effect limit

	function LVS:FireBullet( data )

		Index = Index + 1

		if Index > MaxIndex then
			Index = 1
		end

		LVS._ActiveBullets[ Index ] = nil

		local bullet = {}

		setmetatable( bullet, NewBullet )

		bullet.TracerName = data.TracerName or "lvs_tracer_orange"
		bullet.Src = data.Src or vector_origin
		bullet.Dir = (data.Dir + VectorRand() * (data.Spread or vector_origin) * 0.5):GetNormalized()
		bullet.StartDir = bullet.Dir
		bullet.Force = data.Force or 10

		if data.Force1km then
			bullet.Force1km = data.Force1km
		end

		bullet.HullSize = data.HullSize or 5
		bullet.Mins = -vector_one * bullet.HullSize
		bullet.Maxs = vector_one * bullet.HullSize
		bullet.Velocity = data.Velocity or 2500
		bullet.Attacker = IsValid( data.Attacker ) and data.Attacker or (IsValid( data.Entity ) and data.Entity or game.GetWorld())
		bullet.Damage = data.Damage or 10
		bullet.Entity = data.Entity
		if IsValid( bullet.Entity ) and bullet.Entity.GetCrosshairFilterEnts then
			bullet.Filter = bullet.Entity:GetCrosshairFilterEnts()
		else
			bullet.Filter = bullet.Entity
		end
		bullet.SrcEntity = data.SrcEntity or vector_origin
		bullet.Callback = data.Callback
		bullet.SplashDamage = data.SplashDamage
		bullet.SplashDamageForce = data.SplashDamageForce or 500
		bullet.SplashDamageRadius = data.SplashDamageRadius
		bullet.SplashDamageEffect = data.SplashDamageEffect or "lvs_bullet_impact"
		bullet.SplashDamageType = data.SplashDamageType or DMG_SONIC
		bullet.StartTime = CurTime()
		bullet.EnableBallistics = data.EnableBallistics == true

		if bullet.EnableBallistics then
			bullet:SetGravity( physenv.GetGravity() )
		end

		if InfMap then
			for _, ply in ipairs( player.GetAll() ) do
				local NewPos = Vector( bullet.Src.x, bullet.Src.y, bullet.Src.z ) - InfMap.unlocalize_vector( Vector(), ply.CHUNK_OFFSET )

				net.Start( "lvs_fire_bullet", true )
					net.WriteInt( Index, 13 )
					net.WriteString( bullet.TracerName )
					net.WriteFloat( NewPos.x )
					net.WriteFloat( NewPos.y )
					net.WriteFloat( NewPos.z )
					net.WriteAngle( bullet.Dir:Angle() )
					net.WriteFloat( bullet.StartTime )
					net.WriteFloat( bullet.HullSize )
					net.WriteEntity( bullet.Entity )
					net.WriteFloat( bullet.SrcEntity.x )
					net.WriteFloat( bullet.SrcEntity.y )
					net.WriteFloat( bullet.SrcEntity.z )
					net.WriteFloat( bullet.Velocity )
					net.WriteBool( bullet.EnableBallistics )
				net.Send( ply )
			end
		else
			net.Start( "lvs_fire_bullet", true )
				net.WriteInt( Index, 13 )
				net.WriteString( bullet.TracerName )
				net.WriteFloat( bullet.Src.x )
				net.WriteFloat( bullet.Src.y )
				net.WriteFloat( bullet.Src.z )
				net.WriteAngle( bullet.Dir:Angle() )
				net.WriteFloat( bullet.StartTime )
				net.WriteFloat( bullet.HullSize )
				net.WriteEntity( bullet.Entity )
				net.WriteFloat( bullet.SrcEntity.x )
				net.WriteFloat( bullet.SrcEntity.y )
				net.WriteFloat( bullet.SrcEntity.z )
				net.WriteFloat( bullet.Velocity )
				net.WriteBool( bullet.EnableBallistics )
			net.SendPVS( bullet.Src )
		end

		bullet.bulletindex = Index
		LVS._ActiveBullets[ Index ] = bullet
	end
else
	net.Receive( "lvs_remove_bullet", function( length )
		LVS:RemoveBullet( net.ReadInt( 13 ) )
	end)

	net.Receive( "lvs_fire_bullet", function( length )
		local Index = net.ReadInt( 13 )

		LVS._ActiveBullets[ Index ] = nil

		local bullet = {}

		setmetatable( bullet, NewBullet )

		bullet.TracerName = net.ReadString()
		bullet.Src = Vector(net.ReadFloat(),net.ReadFloat(),net.ReadFloat())
		bullet.Dir = net.ReadAngle():Forward()
		bullet.StartDir = bullet.Dir
		bullet.StartTime = net.ReadFloat()
		bullet.HullSize = net.ReadFloat()
		bullet.Mins = -vector_one * bullet.HullSize
		bullet.Maxs = vector_one * bullet.HullSize
		bullet.Entity = net.ReadEntity()
		if IsValid( bullet.Entity ) and bullet.Entity.GetCrosshairFilterEnts then
			bullet.Filter = bullet.Entity:GetCrosshairFilterEnts()
		else
			bullet.Filter = bullet.Entity
		end
		bullet.SrcEntity = Vector(net.ReadFloat(),net.ReadFloat(),net.ReadFloat())

		if bullet.SrcEntity == vector_origin then
			bullet.SrcEntity = nil
		end

		bullet.Velocity = net.ReadFloat()

		bullet.EnableBallistics = net.ReadBool()

		if bullet.EnableBallistics then
			bullet:SetGravity( physenv.GetGravity() )
		end

		bullet.StartTimeCL = CurTime() + RealFrameTime()

		local ply = LocalPlayer()

		if IsValid( ply ) then
			bullet.Muted = bullet.Entity == ply:lvsGetVehicle() or bullet.Entity:GetOwner() == ply
		end

		bullet.bulletindex = Index
		LVS._ActiveBullets[ Index ] = bullet

		local effectdata = EffectData()
		effectdata:SetOrigin( bullet.Src )
		effectdata:SetNormal( bullet.Dir )
		effectdata:SetMaterialIndex( Index )
		util.Effect( bullet.TracerName, effectdata )
	end )

	hook.Add( "Think", "!!!!_lvs_bullet_think_cl", function()
		HandleBullets()
	end )
end