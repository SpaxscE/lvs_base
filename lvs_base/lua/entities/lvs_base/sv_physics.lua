
function ENT:GetWorldGravity()
	local PhysObj = self:GetPhysicsObject()

	if not IsValid( PhysObj ) or not PhysObj:IsGravityEnabled() then return 0 end

	return physenv.GetGravity():Length()
end

function ENT:GetWorldUp()
	local Gravity = physenv.GetGravity()

	if Gravity:Length() > 0 then
		return -Gravity:GetNormalized()
	else
		return Vector(0,0,1)
	end
end

function ENT:PhysicsSimulate( phys, deltatime )
end

function ENT:PhysicsStopScape()
	if self._lvsScrapeData then
		if self._lvsScrapeData.sound then
			self._lvsScrapeData.sound:Stop()
		end
	end

	self._lvsScrapeData = nil
end

function ENT:PhysicsStartScrape( pos, dir )
	local startpos = self:LocalToWorld( pos )

	local trace = util.TraceLine( {
		start = startpos - dir * 5,
		endpos = startpos + dir * 5,
		filter = self:GetCrosshairFilterEnts()
	} )

	if trace.Hit then
		local sound

		if self._lvsScrapeData and self._lvsScrapeData.sound then
			sound = self._lvsScrapeData.sound
		else
			sound = CreateSound( self, "LVS.Physics.Scrape" )
			sound:PlayEx( 0, 90 + math.min( (self:GetVelocity():Length() / 2000) * 10,10) )
		end

		self._lvsScrapeData = {
			dir = dir,
			pos = pos,
			sound = sound,
		}

		self:CallOnRemove( "stop_scraping", function( self )
			self:PhysicsStopScape()
		end)
	end
end

function ENT:PhysicsThink()
	if not self._lvsScrapeData then return end

	local startpos = self:LocalToWorld( self._lvsScrapeData.pos )

	local trace = util.TraceLine( {
		start = startpos - self._lvsScrapeData.dir,
		endpos = startpos + self._lvsScrapeData.dir * 5,
		filter = self:GetCrosshairFilterEnts()
	} )

	local Vel = self:GetVelocity():Length()

	if trace.Hit and Vel > 25 then
		local vol = math.min(math.max(Vel - 50,0) / 1000,1)

		local effectdata = EffectData()
		effectdata:SetOrigin( trace.HitPos + trace.HitNormal )
		effectdata:SetNormal( trace.HitNormal )
		effectdata:SetMagnitude( vol )
		util.Effect( "lvs_physics_scrape", effectdata, true, true )

		self._lvsScrapeData.sound:ChangeVolume( vol, 0.1 )
	else
		self:PhysicsStopScape()
	end
end

function ENT:TakeCollisionDamage( damage, attacker )
	if not IsValid( attacker ) then
		attacker = game.GetWorld()
	end

	local dmginfo = DamageInfo()
	dmginfo:SetDamage( damage )
	dmginfo:SetAttacker( attacker )
	dmginfo:SetInflictor( attacker )
	dmginfo:SetDamageType( DMG_CRUSH + DMG_VEHICLE ) -- this will communicate to the damage system to handle this kind of damage differently.
	self:TakeDamageInfo( dmginfo )
end

function ENT:PhysicsCollide( data, physobj )
	if self:IsDestroyed() then
		self.MarkForDestruction = true
	end

	local HitEnt = data.HitEntity

	self:PhysicsStartScrape( self:WorldToLocal( data.HitPos ), data.HitNormal )

	if IsValid( data.HitEntity ) then
		if data.HitEntity:IsPlayer() or data.HitEntity:IsNPC() then
			return
		end
	end

	if self:GetAI() and not self:IsPlayerHolding() then
		if self:WaterLevel() >= self.WaterLevelDestroyAI then
			self:SetDestroyed( true )
			self.MarkForDestruction = true

			return
		end

		self:TakeCollisionDamage( data.OurOldVelocity:Length() - data.OurNewVelocity:Length(), data.HitEntity )

		return
	end

	if self:WaterLevel() >= self.WaterLevelAutoStop then
		self:StopEngine()
	end

	if data.Speed > 60 and data.DeltaTime > 0.2 then
		local VelDif = data.OurOldVelocity:Length() - data.OurNewVelocity:Length()

		local effectdata = EffectData()
		effectdata:SetOrigin( data.HitPos )
		util.Effect( "lvs_physics_impact", effectdata, true, true )

		if VelDif > 700 then
			self:EmitSound( "LVS.Physics.Crash", 75, 95 + math.min(VelDif / 1000,1) * 10, math.min(VelDif / 800,1) )

			if self:GetHP() <= self:GetMaxHP() * 0.5 then -- this will effectivly disable collision damage for anything that isnt in combat. It's more fun to fly like this tbh
				self:TakeCollisionDamage( VelDif, data.HitEntity )
			end
		else
			self:EmitSound( "LVS.Physics.Impact", 75, 100, math.min(0.1 + VelDif / 700,1) )
		end
	end
end
