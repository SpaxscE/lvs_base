
function ENT:InitWeaponBTL()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/laserbeam.png")
	weapon.Ammo = -1
	weapon.Delay = 0
	weapon.HeatRateUp = 0
	weapon.HeatRateDown = 0
	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	weapon.StartAttack = function( ent )
	end
	weapon.FinishAttack = function( ent )
	end
	weapon.OnThink = function( ent, active )
	end
	weapon.CalcView = function( ent, ply, pos, angles, fov, pod )
		local view = {}
		view.origin = pos
		view.angles = angles
		view.fov = fov
		view.drawviewer = false

		local ID = ent:LookupAttachment( "muzzle_ballturret_left" )
		local Muzzle = ent:GetAttachment( ID )

		if Muzzle then
			local Pos,Ang = LocalToWorld( Vector(0,25,-45), Angle(270,0,-90), Muzzle.Pos, Muzzle.Ang )

			view.origin = Pos
		end
		return view
	end
	weapon.HudPaint = function( ent, X, Y, ply )
	end
	self:AddWeapon( weapon, 3 )
end