local WEAPON = {}

WEAPON["DEFAULT"] = {
	Icon = Material("lvs/weapons/bullet.png"),
	Ammo = 9999,
	Delay = 0,
	HeatRateUp = 0.2,
	HeatRateDown = 0.25,
	Attack = function( ent ) end,
	StartAttack = function( ent ) end,
	FinishAttack = function( ent ) end,
	OnSelect = function( ent ) end,
	OnDeselect = function( ent ) end,
	OnThink = function( ent, active ) end,
	OnOverheat = function( ent ) end,
	OnRemove = function( ent ) end,
}

WEAPON["LMG"] = {
	Icon = Material("lvs/weapons/mg.png"),
	Ammo = 1000,
	Delay = 0.1,
	Attack = function( ent )
		ent.MirrorPrimary = not ent.MirrorPrimary

		local Mirror = ent.MirrorPrimary and -1 or 1

		local Pos = ent:LocalToWorld( ent.PosLMG and Vector(ent.PosLMG.x,ent.PosLMG.y * Mirror,ent.PosLMG.z) or Vector(0,0,0) )
		local Dir = ent.DirLMG or 0

		local effectdata = EffectData()
		effectdata:SetOrigin( Pos )
		effectdata:SetNormal( ent:GetForward() )
		effectdata:SetEntity( ent )
		util.Effect( "lvs_muzzle", effectdata )

		local bullet = {}
		bullet.Src =  Pos
		bullet.Dir = ent:LocalToWorldAngles( Angle(0,-Dir * Mirror,0) ):Forward()
		bullet.Spread 	= Vector( 0.015,  0.015, 0 )
		bullet.TracerName = "lvs_tracer_white"
		bullet.Force	= 10
		bullet.HullSize 	= 50
		bullet.Damage	= 10
		bullet.Velocity = 30000
		bullet.Attacker 	= ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo) end
		ent:LVSFireBullet( bullet )
	end,
	StartAttack = function( ent )
		if not IsValid( ent.SoundEmitter1 ) then
			ent.SoundEmitter1 = ent:AddSoundEmitter( Vector(109.29,0,92.85), "lvs/weapons/mg_light_loop.wav", "lvs/weapons/mg_light_loop_interior.wav" )
			ent.SoundEmitter1:SetSoundLevel( 95 )
		end
	
		ent.SoundEmitter1:Play()
	end,
	FinishAttack = function( ent )
		if IsValid( ent.SoundEmitter1 ) then
			ent.SoundEmitter1:Stop()
		end
	end,
	OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end,
	OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end,
}

WEAPON["TABLE_POINT_MG"] = {
	Icon = Material("lvs/weapons/bullet.png"),
	Ammo = 2000,
	Delay = 0.1,
	Attack = function( ent )
		if not ent.PosTPMG or not ent.DirTPMG then return end

		for i = 1, 2 do
			ent._NumTPMG = ent._NumTPMG and ent._NumTPMG + 1 or 1

			if ent._NumTPMG > #ent.PosTPMG then ent._NumTPMG = 1 end
		
			local Pos = ent:LocalToWorld( ent.PosTPMG[ ent._NumTPMG ] )
			local Dir = ent.DirTPMG[ ent._NumTPMG ]

			local effectdata = EffectData()
			effectdata:SetOrigin( Pos )
			effectdata:SetNormal( ent:GetForward() )
			effectdata:SetEntity( ent )
			util.Effect( "lvs_muzzle", effectdata )

			local bullet = {}
			bullet.Src = Pos
			bullet.Dir = ent:LocalToWorldAngles( Angle(0,-Dir,0) ):Forward()
			bullet.Spread 	= Vector( 0.035,  0.035, 0 )
			bullet.TracerName = "lvs_tracer_yellow"
			bullet.Force	= 10
			bullet.HullSize 	= 25
			bullet.Damage	= 10
			bullet.Velocity = 40000
			bullet.Attacker 	= ent:GetDriver()
			bullet.Callback = function(att, tr, dmginfo) end
			ent:LVSFireBullet( bullet )
		end
	end,
	StartAttack = function( ent )
		if not IsValid( ent.SoundEmitter1 ) then
			ent.SoundEmitter1 = ent:AddSoundEmitter( Vector(109.29,0,92.85), "lvs/weapons/mg_light_loop.wav", "lvs/weapons/mg_light_loop_interior.wav" )
			ent.SoundEmitter1:SetSoundLevel( 95 )
		end
	
		ent.SoundEmitter1:Play()
	end,
	FinishAttack = function( ent )
		if IsValid( ent.SoundEmitter1 ) then
			ent.SoundEmitter1:Stop()
		end
	end,
	OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft3.wav") end,
	OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end,
}

WEAPON["HMG"] = {
	Icon = Material("lvs/weapons/hmg.png"),
	Ammo = 300,
	Delay = 0.14,
	Attack = function( ent )
		ent.MirrorSecondary = not ent.MirrorSecondary

		local Mirror = ent.MirrorSecondary and -1 or 1

		local Pos = ent:LocalToWorld( ent.PosHMG and Vector(ent.PosHMG.x,ent.PosHMG.y * Mirror,ent.PosHMG.z) or Vector(0,0,0) )
		local Dir = ent.DirHMG or 0.5

		local effectdata = EffectData()
		effectdata:SetOrigin( Pos )
		effectdata:SetNormal( ent:GetForward() )
		effectdata:SetEntity( ent )
		util.Effect( "lvs_muzzle", effectdata )

		local bullet = {}
		bullet.Src = Pos
		bullet.Dir = ent:LocalToWorldAngles( Angle(0,-Dir * Mirror,0) ):Forward()
		bullet.Spread 	= Vector( 0.04,  0.04, 0 )
		bullet.TracerName = "lvs_tracer_orange"
		bullet.Force	= 50
		bullet.HullSize 	= 15
		bullet.Damage	= 25
		bullet.SplashDamage = 75
		bullet.SplashDamageRadius = 200
		bullet.Velocity = 12000
		bullet.Attacker 	= ent:GetDriver()
		bullet.Callback = function(att, tr, dmginfo)
		end
		ent:LVSFireBullet( bullet )
	end,
	StartAttack = function( ent )
		if not IsValid( ent.SoundEmitter2 ) then
			ent.SoundEmitter2 = ent:AddSoundEmitter( Vector(109.29,0,92.85), "lvs/weapons/mg_heavy_loop.wav", "lvs/weapons/mg_heavy_loop.wav" )
			ent.SoundEmitter2:SetSoundLevel( 95 )
		end

		ent.SoundEmitter2:Play()
	end,
	FinishAttack = function( ent )
		if IsValid( ent.SoundEmitter2 ) then
			ent.SoundEmitter2:Stop()
		end
		ent:EmitSound("lvs/weapons/mg_heavy_lastshot.wav", 95 )
	end,
	OnSelect = function( ent ) ent:EmitSound("physics/metal/weapon_impact_soft2.wav") end,
	OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end,
}

WEAPON["TURBO"] = {
	Icon = Material("lvs/weapons/nos.png"),
	HeatRateUp = 0.1,
	HeatRateDown = 0.1,
	UseableByAI = false,
	Attack = function( ent )
		local PhysObj = ent:GetPhysicsObject()
		if not IsValid( PhysObj ) then return end
		local THR = ent:GetThrottle()
		local FT = FrameTime()

		local Vel = ent:GetVelocity():Length()

		PhysObj:ApplyForceCenter( ent:GetForward() * math.Clamp(ent.MaxVelocity + 500 - Vel,0,1) * PhysObj:GetMass() * THR * FT * 150 ) -- increase speed
		PhysObj:AddAngleVelocity( PhysObj:GetAngleVelocity() * FT * 0.5 * THR ) -- increase turn rate
	end,
	StartAttack = function( ent )
		ent.TargetThrottle = 1.3
		ent:EmitSound("lvs/vehicles/generic/boost.wav")
	end,
	FinishAttack = function( ent )
		ent.TargetThrottle = 1
	end,
	OnSelect = function( ent )
		ent:EmitSound("buttons/lever5.wav")
	end,
	OnThink = function( ent, active )
		if not ent.TargetThrottle then return end

		local Rate = FrameTime() * 0.5

		ent:SetMaxThrottle( ent:GetMaxThrottle() + math.Clamp(ent.TargetThrottle - ent:GetMaxThrottle(),-Rate,Rate) )

		local MaxThrottle = ent:GetMaxThrottle()

		ent:SetThrottle( MaxThrottle )

		if MaxThrottle == ent.TargetThrottle then
			ent.TargetThrottle = nil
		end
	end,
	OnOverheat = function( ent ) ent:EmitSound("lvs/overheat_boost.wav") end,
}

function LVS:GetWeaponPreset( name )
	if not WEAPON[ name ] then return table.Copy( WEAPON["DEFAULT"] ) end

	return table.Copy( WEAPON[ name ] )
end