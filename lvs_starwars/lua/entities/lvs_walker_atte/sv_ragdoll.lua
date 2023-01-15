
function ENT:UnRagdoll()
	if not self.Constrainer then return end

	self:SetTargetSpeed( 200 )
	self:SetIsRagdoll( false )

	local RearEnt = self:GetRearEntity()

	for _, ent in pairs( self.Constrainer ) do
		if not IsValid( ent ) then continue end

		if ent ~= self and ent ~= RearEnt then
			ent:Remove()
		end
	end

	self.Constrainer = nil

	self.DoNotDuplicate = false
end

function ENT:BecomeRagdoll()
	if self.Constrainer then return end

	self:SetIsRagdoll( true )

	self:EmitSound( "lvs/vehicles/atte/becomeragdoll.ogg", 85 )

	local RearEnt = self:GetRearEntity()

	self.Constrainer = {
		[-1] = RearEnt,
		[0] = self,
	}

	self.DoNotDuplicate = true

	local legs = {
		[1] = {
			mdl = "models/blu/atte_smallleg_part3.mdl",
			pos = Vector(179.38000488281,49.489994049072,135.75967407227),
			ang = Angle(44.215007781982,150.94340515137,63.648578643799),
			constraintent = 0,
			relative = self,
			mass = 100,
		},
		[2] = {
			mdl = "models/blu/atte_smallleg_part2.mdl",
			pos = Vector(141.20703125,75.184730529785,92.679763793945),
			ang = Angle(26.416994094849,-0.40378132462502,-69.192375183105),
			constraintent = 1,
			relative = self,
			mass = 100,
		},
		[3] = {
			mdl = "models/blu/atte_smallleg_part1.mdl",
			pos = Vector(200,73.965484619141,65.000106811523),
			ang = Angle(-0,0,-3.3350533445997),
			constraintent = 2,
			relative = self,
			mass = 500,
		},
		[4] = {
			mdl = "models/blu/atte_smallleg_part3.mdl",
			pos = Vector(179.38000488281,-49.490013122559,135.75991821289),
			ang = Angle(44.198577880859,-150.89817810059,-63.583557128906),
			constraintent = 0,
			relative = self,
			mass = 100,
		},
		[5] = {
			mdl = "models/blu/atte_smallleg_part2.mdl",
			pos = Vector(143.69384765625,-73.068077087402,97.717414855957),
			ang = Angle(26.42932510376,0.37080633640289,69.134086608887),
			constraintent = 4,
			relative = self,
			mass = 100,
		},
		[6] = {
			mdl = "models/blu/atte_smallleg_part1.mdl",
			pos = Vector(200,-74.034530639648,64.999870300293),
			ang = Angle(-7.6842994189974,180,3.3350533445997),
			constraintent = 5,
			relative = self,
			mass = 500,
		},
		[7] = {
			mdl = "models/blu/atte_smallleg_part3.mdl",
			pos = Vector(-144.56005859375,-68.160011291504,126.38916015625),
			ang = Angle(40.543598175049,-1.4966688156128,87.698204040527),
			constraintent = -1,
			relative = RearEnt,
			mass = 100,
		},
		[8] = {
			mdl = "models/blu/atte_smallleg_part2.mdl",
			pos = Vector(-97.947143554688,-73.435012817383,84.695648193359),
			ang = Angle(20.146644592285,-179.35815429688,-88.137001037598),
			constraintent = 7,
			relative = RearEnt,
			mass = 100,
		},
		[9] = {
			mdl = "models/blu/atte_smallleg_part1.mdl",
			pos = Vector(-160,-74.034530639648,65.000846862793),
			ang = Angle(-7.6842994189974,180,3.3350533445997),
			constraintent = 8,
			relative = RearEnt,
			mass = 500,
		},

		[10] = {
			mdl = "models/blu/atte_smallleg_part3.mdl",
			pos = Vector(-144.56005859375,68.160026550293,126.3892364502),
			ang = Angle(40.544513702393,1.4415748119354,-87.782958984375),
			constraintent = -1,
			relative = RearEnt,
			mass = 100,
		},
		[11] = {
			mdl = "models/blu/atte_smallleg_part2.mdl",
			pos = Vector(-100.01416015625,73.222549438477,90.318885803223),
			ang = Angle(20.146047592163,179.3818359375,88.205642700195),
			constraintent = 10,
			relative = RearEnt,
			mass = 100,
		},
		[12] = {
			mdl = "models/blu/atte_smallleg_part1.mdl",
			pos = Vector(-160.00012207031,73.965484619141,64.999130249023),
			ang = Angle(-0,0,-3.3350533445997),
			constraintent = 11,
			relative = RearEnt,
			mass = 500,
		},
		[13] = {
			mdl = "models/blu/atte_bigleg.mdl",
			pos = Vector(-2.7337646484375,-104.31359863281,136.90048217773),
			ang = Angle(67.58911895752,-85.624977111816,-4.3076190948486),
			constraintent = -1,
			relative = RearEnt,
			mass = 1000,
		},
		[14] = {
			mdl = "models/blu/atte_bigfoot.mdl",
			pos = Vector(-16,-143.04605102539,49.999664306641),
			ang = Angle(-7.6842994189974,180,3.3350533445997),
			constraintent = 13,
			relative = RearEnt,
			mass = 5000,
		},
		[15] = {
			mdl = "models/blu/atte_bigleg.mdl",
			pos = Vector(-2.72802734375,104.31448364258,136.93844604492),
			ang = Angle(67.650489807129,85.622894287109,4.307954788208),
			constraintent = -1,
			relative = RearEnt,
			mass = 1000,
		},
		[16] = {
			mdl = "models/blu/atte_bigfoot.mdl",
			pos = Vector(15.999877929688,142.95399475098,50.000293731689),
			ang = Angle(-0,0,-3.3350533445997),
			constraintent = 15,
			relative = RearEnt,
			mass = 5000,
		},
	}

	for k, v in pairs( legs ) do
		if not IsValid( v.relative ) then continue end

		local ent = ents.Create( "lvs_walker_atte_component" )
		ent:SetModel( v.mdl )
		ent:SetPos( v.relative:LocalToWorld( v.pos ) )
		ent:SetAngles( v.relative:LocalToWorldAngles( v.ang ) )
		ent:SetBase( self )
		ent:Spawn()
		ent:Activate()
		ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
		self:DeleteOnRemove( ent )

		self.Constrainer[ k ] = ent

		local PhysObj = ent:GetPhysicsObject()
		if IsValid( PhysObj ) then
			PhysObj:SetMass( v.mass )
		end

		self:TransferCPPI( ent )

		ent.DoNotDuplicate = true
	end

	for k, v in pairs( legs ) do
		local ent = self.Constrainer[ k ]
		local TargetEnt = self.Constrainer[ v.constraintent ]
		if not IsValid( ent ) or not IsValid( TargetEnt ) then continue end

		local ballsocket = constraint.AdvBallsocket(ent, TargetEnt,0,0, Vector(0,0,0), Vector(0,0,0),0,0, -30, -30, -30, 30, 30, 30, 0, 0, 0, 0, 1)
		ballsocket.DoNotDuplicate = true
		self:TransferCPPI( ballsocket )
	end

	self:ForceMotion()
end

function ENT:NudgeRagdoll()
	if not istable( self.Constrainer ) then return end

	for _, ent in pairs( self.Constrainer ) do
		if not IsValid( ent ) or ent == self or ent == self:GetRearEntity() then continue end

		local PhysObj = ent:GetPhysicsObject()

		if not IsValid( PhysObj ) then continue end

		PhysObj:EnableMotion( false )

		ent:SetPos( ent:GetPos() + self:GetUp() * 100 )

		timer.Simple( FrameTime() * 2, function()
			if not IsValid( ent ) then return end

			local PhysObj = ent:GetPhysicsObject()
			if IsValid( PhysObj ) then
				PhysObj:EnableMotion( true )
			end
		end)
	end
end

function ENT:ForceMotion()
	for _, ent in ipairs( self:GetContraption() ) do
		if not IsValid( ent ) then continue end

		local phys = ent:GetPhysicsObject()

		if not IsValid( phys ) then continue end

		if not phys:IsMotionEnabled() then
			phys:EnableMotion( true )
		end
	end
end