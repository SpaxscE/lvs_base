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

WEAPON["TURBO"] = {
	Icon = Material("lvs/weapons/nos.png"),
	HeatRateUp = 0.1,
	HeatRateDown = 0.2,
	Attack = function( ent )
		local PhysObj = ent:GetPhysicsObject()
		if not IsValid( PhysObj ) then return end
		local THR = ent:GetThrottle()
		local FT = FrameTime()

		local Vel = ent:GetVelocity():Length()

		PhysObj:ApplyForceCenter( ent:GetForward() * math.Clamp(ent.MaxVelocity + 500 - Vel,0,1) * PhysObj:GetMass() * THR * FT * 150 ) -- increase speed
		PhysObj:AddAngleVelocity( PhysObj:GetAngleVelocity() * FT * 0.25 * THR ) -- increase turn rate
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