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
	if SERVER and self.EnableBallistics then
		net.Start( "lvs_remove_bullet", true )
			net.WriteInt( self.bulletindex, 13 )
		net.Broadcast()

		LVS._ActiveBullets[ self.bulletindex ] = nil

		return
	end

	LVS:RemoveBullet( self.bulletindex )
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

local function HandleBullets()
	local T = CurTime()
	local FT = FrameTime()

	for id, bullet in pairs( LVS._ActiveBullets ) do -- loop through bullet table
		if bullet:GetSpawnTime() + 5 < T then -- destroy all bullets older than 5 seconds
			LVS._ActiveBullets[ id ] = nil
			continue
		end

		local start = bullet.Src
		local dir = bullet.StartDir
		local TimeAlive = bullet:GetTimeAlive()

		if TimeAlive < 0 then continue end

		local pos

		if bullet.EnableBallistics then
			local posUnaffected = dir * TimeAlive * bullet.Velocity

			pos = posUnaffected + bullet:GetGravity() * (TimeAlive ^ 2)

			bullet:SetDir( ((start + pos) - start):GetNormalized() )
		else
			pos = dir * TimeAlive * bullet.Velocity
		end

		local mul = bullet:GetLength()

		-- startpos, direction and curtime of creation is networked to client. 
		-- The Bullet position is simulated by doing startpos + dir * time * velocity
		if SERVER then
			bullet:SetPos( start + pos )
		else
			if IsValid( bullet.Entity ) and bullet.SrcEntity then -- if the vehicle entity is valid...
				local inv = 1 - mul

				-- ..."parent" the bullet to the vehicle for a very short time. This will give the illusion of the bullet not lagging behind even tho it is fired later on client
				bullet:SetPos( start * mul + bullet.Entity:LocalToWorld( bullet.SrcEntity ) * inv + pos )
			else
				bullet:SetPos( start + pos )
			end
		end

		local TraceMask = bullet.HullSize <= 1 and MASK_SHOT_PORTAL or MASK_SHOT_HULL
		local Filter = bullet.Filter

		local trace = util.TraceHull( {
			start = start,
			endpos = start + pos + dir * bullet.Velocity * FT,
			filter = Filter,
			mins = bullet.Mins,
			maxs = bullet.Maxs,
			mask = TraceMask
		} )

		--debugoverlay.Line( start, start + pos + dir * bullet.Velocity * FT, Color( 255, 255, 255 ), true )

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

		-- !!workaround!! todo: implement proper breaking
		if IsValid( trace.Entity ) and trace.Entity:GetClass() == "func_breakable_surf" then
			if SERVER then trace.Entity:Fire("break") end

			trace.Hit = false -- goes right through...
		end

		if trace.Hit then
			-- hulltrace doesnt hit the wall due to its hullsize...
			-- so this needs an extra trace line
			local traceImpact = util.TraceLine( {
				start = start,
				endpos = start + pos + dir * 250,
				filter = Filter,
				mask = TraceMask
			} )

			if SERVER then
				local EndPos = traceImpact.Hit and traceImpact.HitPos or trace.HitPos

				local dmginfo = DamageInfo()
				dmginfo:SetDamage( bullet.Damage )
				dmginfo:SetAttacker( (IsValid( bullet.Attacker ) and bullet.Attacker) or (IsValid( bullet.Entity ) and bullet.Entity) or game.GetWorld() )
				dmginfo:SetDamageType( DMG_AIRBOAT )
				dmginfo:SetInflictor( (IsValid( bullet.Entity ) and bullet.Entity) or (IsValid( bullet.Attacker ) and bullet.Attacker) or game.GetWorld() )
				dmginfo:SetDamagePosition( EndPos )

				if bullet.Force1km then
					local Mul = math.min( (start - EndPos):Length() / 39370, 1 )
					local invMul = math.max( 1 - Mul, 0 )
					dmginfo:SetDamageForce( bullet.Dir * (bullet.Force * invMul + bullet.Force1km * Mul) )
				else
					dmginfo:SetDamageForce( bullet.Dir * bullet.Force )
				end

				if bullet.Callback then
					bullet.Callback( bullet.Attacker, trace, dmginfo )
				end

				trace.Entity:TakeDamageInfo( dmginfo )

				if IsValid( trace.Entity ) and trace.Entity.GetBloodColor then
					local BloodColor = trace.Entity:GetBloodColor()

					if BloodColor and BloodColor ~= DONT_BLEED then
						local effectdata = EffectData()
						effectdata:SetOrigin( EndPos )
						effectdata:SetColor( BloodColor )
						util.Effect( "BloodImpact", effectdata, true, true )
					end
				end

				if bullet.SplashDamage and bullet.SplashDamageRadius then
					local effectdata = EffectData()
					effectdata:SetOrigin( EndPos )
					effectdata:SetNormal( trace.HitWorld and trace.HitNormal or dir )
					effectdata:SetMagnitude( bullet.SplashDamageRadius / 250 )
					util.Effect( bullet.SplashDamageEffect, effectdata )

					dmginfo:SetDamageType( bullet.SplashDamageType )
					dmginfo:SetDamage( bullet.SplashDamage )

					local BlastPos = EndPos
		
					if bullet.SplashDamageType == DMG_BLAST and IsValid( trace.Entity ) then
						BlastPos = trace.Entity:GetPos()

						if isfunction( trace.Entity.GetBase ) then
							local Base = trace.Entity:GetBase()
		
							if IsValid( Base ) and isentity( Base ) then
								BlastPos = Base:GetPos()
							end
						end
					end

					util.BlastDamageInfo( dmginfo, BlastPos, bullet.SplashDamageRadius )
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

			bullet:Remove()
		end
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