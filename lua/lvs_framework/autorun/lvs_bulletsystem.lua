
LVS._ActiveBullets = {}

function LVS:GetBullet( index )
	if not LVS._ActiveBullets then return end

	return LVS._ActiveBullets[ index ]
end

local NewBullet = {}
NewBullet.__index = NewBullet 

function NewBullet:SetPos( pos )
	self.curpos = pos
end

function NewBullet:GetPos()
	if not self.curpos then return self.Src end

	return self.curpos
end

function NewBullet:GetDir()
	return self.Dir or Vector(0,0,0)
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

local function HandleBullets()
	local T = CurTime()
	local FT = FrameTime()

	for id, bullet in pairs( LVS._ActiveBullets ) do -- loop through bullet table
		if bullet:GetSpawnTime() + 5 < T then -- destroy all bullets older than 5 seconds
			LVS._ActiveBullets[ id ] = nil
			continue
		end

		local start = bullet.Src
		local dir = bullet.Dir
		local TimeAlive = bullet:GetTimeAlive()
		local pos = dir * TimeAlive * bullet.Velocity
		local mul = bullet:GetLength()
		local Is2ndTickAlive = TimeAlive > FT * 2 -- this system is slow. Takes atleast 2 ticks before it spawns. We need to trace from startpos until lua catches up

		-- startpos, direction and curtime of creation is networked to client. 
		-- The Bullet position is simulated by doing startpos + dir * time * velocity
		if SERVER then
			bullet:SetPos( start + pos )
		else
			if IsValid( bullet.Entity ) then -- if the vehicle entity is valid...
				local inv = 1 - mul

				-- ..."parent" the bullet to the vehicle for a very short time. This will give the illusion of the bullet not lagging behind even tho it is fired later on client
				bullet:SetPos( start * mul + bullet.Entity:LocalToWorld( bullet.SrcEntity ) * inv + pos )
			else
				bullet:SetPos( start + pos )
			end
		end

		local Filter
		if IsValid( bullet.Entity ) then
			Filter = bullet.Entity:GetCrosshairFilterEnts() -- auto filter all entities that are attached to the vehicle
		end

		local trace = util.TraceHull( {
			start = Is2ndTickAlive and start + pos - dir or start,
			endpos = start + pos + dir * bullet.Velocity * FT,
			filter = Filter,
			mins = Vector(-1,-1,-1) * bullet.HullSize,
			maxs = Vector(1,1,1) * bullet.HullSize,
			mask = MASK_SHOT_HULL
		} )

		--debugoverlay.Line( Is2ndTickAlive and start + pos - dir or start, start + pos + dir * bullet.Velocity * FT, Color( 255, 255, 255 ), true )

		if CLIENT then
			if not bullet.Muted and mul == 1 and LVS.EnableBulletNearmiss then
				-- whats more expensive, spamming this effect or doing distance checks to localplayer for each bullet think? Alternative method?
				local effectdata = EffectData()
				effectdata:SetOrigin( bullet:GetPos() )
				effectdata:SetFlags( 2 )
				util.Effect( "TracerSound", effectdata )
			end

			if not bullet.HasHitWater then
				local traceWater = util.TraceLine( {
					start = start + pos - dir,
					endpos = start + pos + dir * bullet.Velocity * FT,
					filter = Filter,
					mask = MASK_WATER,
				} )

				if traceWater.Hit then
					LVS._ActiveBullets[ id ].HasHitWater = true

					local effectdata = EffectData()
					effectdata:SetOrigin( traceWater.HitPos )
					effectdata:SetScale( 10 + bullet.HullSize * 0.5 )
					effectdata:SetFlags( 2 )
					util.Effect( "WaterSplash", effectdata, true, true )
				end
			end
		end

		if trace.Hit then
			-- hulltrace doesnt hit the wall due to its hullsize...
			-- so this needs an extra trace line
			local traceImpact = util.TraceLine( {
				start = Is2ndTickAlive and start + pos - dir or start,
				endpos = start + pos + dir * 50000,
				filter = Filter,
				mask = MASK_SHOT_HULL
			} )

			if SERVER then
				local EndPos = traceImpact.Hit and traceImpact.HitPos or trace.HitPos

				local dmginfo = DamageInfo()
				dmginfo:SetDamage( bullet.Damage )
				dmginfo:SetAttacker( (IsValid( bullet.Attacker ) and bullet.Attacker) or (IsValid( bullet.Entity ) and bullet.Entity) or game.GetWorld() )
				dmginfo:SetDamageType( DMG_AIRBOAT )
				dmginfo:SetInflictor( (IsValid( bullet.Entity ) and bullet.Entity) or (IsValid( bullet.Attacker ) and bullet.Attacker) or game.GetWorld() )
				dmginfo:SetDamagePosition( EndPos )
				dmginfo:SetDamageForce( bullet.Dir * bullet.Force ) 

				if bullet.Callback then
					bullet.Callback( bullet.Attacker, traceImpact, dmginfo )
				end

				trace.Entity:TakeDamageInfo( dmginfo )

				if bullet.SplashDamage and bullet.SplashDamageRadius then
					local effectdata = EffectData()
					effectdata:SetOrigin( EndPos )
					effectdata:SetNormal( trace.HitWorld and trace.HitNormal or dir )
					effectdata:SetMagnitude( bullet.SplashDamageRadius / 250 )
					util.Effect( bullet.SplashDamageEffect, effectdata )

					dmginfo:SetDamageType( DMG_SONIC )
					dmginfo:SetDamage( bullet.SplashDamage )

					util.BlastDamageInfo( dmginfo, EndPos, bullet.SplashDamageRadius )
				end
			else
				if not traceImpact.HitSky then
					local effectdata = EffectData()
					effectdata:SetOrigin( traceImpact.HitPos )
					effectdata:SetEntity( traceImpact.Entity )
					effectdata:SetStart( start )
					effectdata:SetNormal( traceImpact.HitNormal )
					effectdata:SetSurfaceProp( traceImpact.SurfaceProps )
					util.Effect( "Impact", effectdata )
				end
			end

			LVS._ActiveBullets[ id ] = nil
		end
	end
end

if SERVER then
	util.AddNetworkString( "lvs_fire_bullet" )

	hook.Add( "Tick", "!!!!lvs_bullet_handler", function( ply, ent ) -- from what i understand, think can "skip" on lag, while tick still simulates all steps
		HandleBullets()
	end )

	function LVS:FireBullet( data )
		local bullet = {}

		setmetatable( bullet, NewBullet )

		bullet.TracerName = data.TracerName or "lvs_tracer_orange"
		bullet.Src = data.Src or Vector(0,0,0)
		bullet.Dir = (data.Dir + VectorRand() * (data.Spread or Vector(0,0,0)) * 0.5):GetNormalized()
		bullet.Force = data.Force or 10
		bullet.HullSize = data.HullSize or 5
		bullet.Velocity = data.Velocity or 2500
		bullet.Attacker = IsValid( data.Attacker ) and data.Attacker or (IsValid( data.Entity ) and data.Entity or game.GetWorld())
		bullet.Damage = data.Damage or 10
		bullet.Entity = data.Entity
		bullet.Filter = data.Filter or bullet.Entity
		bullet.SrcEntity = data.SrcEntity or Vector(0,0,0)
		bullet.Callback = data.Callback
		bullet.SplashDamage = data.SplashDamage
		bullet.SplashDamageRadius = data.SplashDamageRadius
		bullet.SplashDamageEffect = data.SplashDamageEffect or "lvs_bullet_impact"
		bullet.StartTime = CurTime()

		local ReplaceEffect = isstring( bullet.SplashDamageEffect )

		if InfMap then
			for _, ply in ipairs( player.GetAll() ) do
				local NewPos = Vector( bullet.Src.x, bullet.Src.y, bullet.Src.z ) - InfMap.unlocalize_vector( Vector(), ply.CHUNK_OFFSET )

				net.Start( "lvs_fire_bullet", true )
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
				net.Send( ply )
			end
		else
			net.Start( "lvs_fire_bullet", true )
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
			net.SendPVS( bullet.Src )
		end

		table.insert(LVS._ActiveBullets, bullet )
	end
else
	local Index = 0
	local MaxIndex = 4094 -- this is the util.effect limit

	net.Receive( "lvs_fire_bullet", function( length )
		local bullet = {}

		setmetatable( bullet, NewBullet )

		bullet.TracerName = net.ReadString()
		bullet.Src = Vector(net.ReadFloat(),net.ReadFloat(),net.ReadFloat())
		bullet.Dir = net.ReadAngle():Forward()
		bullet.StartTime = net.ReadFloat()
		bullet.HullSize = net.ReadFloat()
		bullet.Entity = net.ReadEntity()
		bullet.SrcEntity = Vector(net.ReadFloat(),net.ReadFloat(),net.ReadFloat())
		bullet.Velocity = net.ReadFloat()

		if net.ReadBool() then
			bullet.SplashDamageEffect = net.ReadString()
		else
			bullet.SplashDamageEffect = "lvs_bullet_impact"
		end

		bullet.StartTimeCL = CurTime() + RealFrameTime()

		local ply = LocalPlayer()
		bullet.Muted = IsValid( ply ) and bullet.Entity == ply:lvsGetVehicle()

		Index = Index + 1
		if Index > 4094 then
			Index = 1
		end

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