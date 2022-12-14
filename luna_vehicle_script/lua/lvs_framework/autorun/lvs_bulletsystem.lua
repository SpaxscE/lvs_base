
LVS._ActiveBullets = {}

local function HandleBullets()
	local T = CurTime()
	local FT = FrameTime()

	for id, bullet in pairs( LVS._ActiveBullets ) do
		if bullet.StartTime + 5 < T then
			LVS._ActiveBullets[ id ] = nil

			continue
		end

		local start = bullet.Src
		local dir = bullet.Dir
		local pos = dir * (T - bullet.StartTime) * bullet.Velocity

		if SERVER then
			LVS._ActiveBullets[ id ].curpos = start + pos
		else
			if IsValid( bullet.Entity ) then
				local mul = math.min( (T - bullet.StartTimeCL),1)
				local inv = 1 - mul

				LVS._ActiveBullets[ id ].curpos = start * mul + bullet.Entity:LocalToWorld( bullet.SrcEntity ) * inv + pos
			else
				LVS._ActiveBullets[ id ].curpos = start + pos
			end
		end

		local Filter
		if IsValid( bullet.Entity ) then
			Filter = bullet.Entity:GetCrosshairFilterEnts()
		end

		local trace = util.TraceHull( {
			start = start + pos - dir,
			endpos = start + pos + dir * bullet.Velocity * FT,
			filter = Filter,
			mins = Vector(-1,-1,-1) * bullet.HullSize,
			maxs = Vector(1,1,1) * bullet.HullSize,
			mask = MASK_SHOT_HULL
		} )

		if trace.Hit then
			if SERVER and bullet.Callback then
				bullet.Callback( bullet.Attacker, trace, dmginfo )
			end

			LVS._ActiveBullets[ id ] = nil
		end
	end
end

if SERVER then
	util.AddNetworkString( "lvs_fire_bullet" )

	hook.Add( "Tick", "!!!!lvs_bullet_handler", function( ply, ent )
		HandleBullets()
	end )

	function LVS:FireBullet( data )
		local bullet = {}
		bullet.TracerName = data.TracerName or "lvs_bullet_base"
		bullet.Src = data.Src or Vector(0,0,0)
		bullet.Dir = (data.Dir + VectorRand() * (data.Spread or Vector(0,0,0)) * 0.5):GetNormalized()
		bullet.Force = data.Force or 10
		bullet.HullSize = data.HullSize or 5
		bullet.Velocity = data.Velocity or 2500
		bullet.Attacker = data.Attacker or NULL
		bullet.Entity = data.Entity
		bullet.Filter = data.Filter or bullet.Entity
		bullet.SrcEntity = data.SrcEntity or Vector(0,0,0)
		bullet.Callback = data.Callback
		bullet.StartTime = CurTime()

		net.Start( "lvs_fire_bullet" )
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
		net.Broadcast()

		table.insert(LVS._ActiveBullets, bullet )
	end
else
	net.Receive( "lvs_fire_bullet", function( length )
		local bullet = {}
		bullet.TracerName = net.ReadString()
		bullet.Src = Vector(net.ReadFloat(),net.ReadFloat(),net.ReadFloat())
		bullet.Dir = net.ReadAngle():Forward()
		bullet.StartTime = net.ReadFloat()
		bullet.HullSize = net.ReadFloat()
		bullet.Entity = net.ReadEntity()
		bullet.SrcEntity = Vector(net.ReadFloat(),net.ReadFloat(),net.ReadFloat())
		bullet.Velocity = net.ReadFloat()
		bullet.StartTimeCL = CurTime()

		local index = 1
		for _,_ in ipairs( LVS._ActiveBullets ) do
			index = index + 1
		end

		LVS._ActiveBullets[ index ] = bullet

		local effectdata = EffectData()
		effectdata:SetOrigin( bullet.Src )
		effectdata:SetNormal( bullet.Dir )
		effectdata:SetFlags( index )
		util.Effect( bullet.TracerName, effectdata )
	end )

	hook.Add( "Think", "!!!!_lvstest", function()
		HandleBullets()
	end )
end