
function EFFECT:Init( data )
	local Pos = data:GetOrigin()
	local Ent = data:GetEntity()

	if not IsValid( Ent ) then return end

	local emitter = Ent:GetParticleEmitter( Ent:GetPos() )

	if not IsValid( emitter ) then return end

	local Vel = Ent:GetVelocity()
	Vel.z = 0

	local Speed = Vel:Length()

	if Speed < 50 then return end

	local Steer = math.abs( Ent:GetSteer() )

	local ShouldPlaySound = false

	local T = CurTime()

	local LightColor = render.GetLightColor( Pos )
	local VecCol = Vector(0.8,0.9,1) * math.min(0.25 + (((0.2126 * LightColor.r) + (0.7152 * LightColor.g) + (0.0722 * LightColor.b))) * 2, 1 ) * 255

	local mul = math.min(Speed * 0.005,1)
	local invmul = 1 - mul

	local EntPos = Ent:GetPos()
	local Len = Ent:BoundingRadius() * 1.5
	local MoveDir = Vel:GetNormalized()
	local MoveAng = MoveDir:Angle()

	local Target = LocalPlayer()

	if IsValid( Target ) then
		ShouldPlaySound = Target:lvsGetVehicle() == Ent

		local ViewEnt = Target:GetViewEntity()

		if IsValid( ViewEnt ) then
			Target = ViewEnt
		end
	end

	local SwapSides = math.abs( Ent:GetSteer() ) > 0.9
	local Res = math.max( math.Round( (Target:GetPos() - Pos):LengthSqr() / 2500000, 0 ), 5 )

	for i = -135, 135, Res do
		local Dir = Angle(0,MoveAng.y+i,0):Forward()

		local StartPos = Pos + Dir * Len
		local EndPos = Pos

		local trace = util.TraceLine( {
			start = StartPos,
			endpos = EndPos,
			filter = Ent,
			ignoreworld = true,
			whitelist = true,
		} )

		if not trace.Hit then continue end

		local fxPos = Ent:WorldToLocal( trace.HitPos + trace.HitNormal * 2 )
		if SwapSides then fxPos.y = -fxPos.y end
		fxPos = Ent:LocalToWorld( fxPos )

		local particle = emitter:Add( "effects/splash4", fxPos + Vector(0,0,math.Rand(-5,5) * mul) )

		if not particle then continue end

		local pfxVel = Ent:WorldToLocal( EntPos + Dir * Speed * 0.5 + trace.HitNormal * Speed * 0.25 )
		if SwapSides then pfxVel.y = -pfxVel.y end
		pfxVel = Ent:LocalToWorld( pfxVel ) - EntPos

		local pfxMul = math.Clamp( pfxVel.z / 250, 1, 2 )

		particle:SetVelocity( pfxVel )
		particle:SetDieTime( (math.Rand(0.8,0.8) + math.Rand(0.2,0.4) * invmul) * pfxMul )
		particle:SetAirResistance( 60 ) 
		particle:SetStartAlpha( ((pfxMul / 2) ^ 2) * 255 )
		particle:SetEndAlpha( 0 )
		particle:SetStartSize( 5 + math.Rand(5,10) * mul )
		particle:SetEndSize( 15 + math.Rand(10,20) * mul * pfxMul )
		particle:SetRoll( math.Rand(-1,1) * math.Rand(50,150) )
		particle:SetRollDelta( math.Rand(-1,1) * pfxMul * mul * 0.5 )
		particle:SetColor(VecCol.r,VecCol.g,VecCol.b)
		particle:SetGravity( Vector( 0, 0, -600 * math.Rand(1,1 + Steer * 3) ) - Vel * math.abs( i * 0.15 ) / 65 )
		particle:SetCollide( false )
		particle:SetNextThink( T )
		particle:SetThinkFunction( function( p )
			local fxpos = p:GetPos()

			p:SetNextThink( CurTime() )

			if fxpos.z > Pos.z then return end

			p:SetDieTime( 0 )

			if not IsValid( Ent ) or math.random(1,6) ~= 2 then return end

			local startpos = Vector(fxpos.x,fxpos.y,Pos.z + 1)

			local volume = math.min( math.abs( p:GetVelocity().z ) / 100, 1 )

			if ShouldPlaySound and volume > 0.2 and p:GetStartSize() > 13 and math.random(1,10) == 1 then
				local pitch = math.Rand(95,105) * math.Clamp( 1.5 - volume * 0.9,0.5,1)

				if pitch < 58 then
					sound.Play( "vehicles/airboat/pontoon_splash"..math.random(1,2)..".wav", startpos, 75, math.Rand(95,105), volume * 0.1, 0 )
				else
					if Speed < 600 then
						sound.Play( "ambient/water/water_splash"..math.random(1,3)..".wav", startpos, 75, pitch, volume * 0.1, 0 )
					end
				end
			end

			if not ShouldPlaySound then return end

			local emitter3D = Ent:GetParticleEmitter3D( Ent:GetPos() )

			if not IsValid( emitter3D ) then return end

			local particle = emitter3D:Add("effects/splashwake1", startpos )

			if not particle then return end

			local scale = math.Rand(0.5,2)
			local size = p:GetEndSize()
			local vsize = Vector(size,size,size)

			particle:SetStartSize( size * scale * 0.5 )
			particle:SetEndSize( size * scale )
			particle:SetDieTime( math.Rand(0.5,1) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetPos( startpos )
			particle:SetAngles( Angle(-90,math.Rand(-180,180),0) )
			particle:SetColor(VecCol.r,VecCol.g,VecCol.b)
			particle:SetNextThink( CurTime() )
			particle:SetThinkFunction( function( pfx )

				local startpos = pfx:GetPos()
				local endpos = startpos - Vector(0,0,100)

				local trace = util.TraceHull( {
					start = startpos,
					endpos = endpos,
					filter = Ent,
					whitelist = true,
					mins = -vsize,
					maxs = vsize,
				} )

				if trace.Hit then pfx:SetDieTime( 0 ) return end

				pfx:SetNextThink( CurTime() )
			end )
		end )
	end
end


function EFFECT:Think()
	return false
end

function EFFECT:Render()
end