
function ENT:OnLeftTrackRepaired()
end

function ENT:OnRightTrackRepaired()
end

function ENT:OnLeftTrackDestroyed()
end

function ENT:OnRightTrackDestroyed()
end

function ENT:GetTrackPhysics()
	return self._TrackPhysics
end

function ENT:CreateTrackPhysics( mdl )
	if IsValid( self._TrackPhysics ) then return self._TrackPhysics end

	if not isstring( mdl ) then return NULL end

	local TrackPhysics = ents.Create( "lvs_wheeldrive_trackphysics" )

	if not IsValid( TrackPhysics ) then return NULL end

	TrackPhysics:SetModel( mdl )
	TrackPhysics:SetPos( self:GetPos() )
	TrackPhysics:SetAngles( self:GetAngles() )
	TrackPhysics:Spawn()
	TrackPhysics:Activate()
	TrackPhysics:SetBase( self )
	self:TransferCPPI( TrackPhysics )
	self:DeleteOnRemove( TrackPhysics )

	self._TrackPhysics = TrackPhysics

	local weld_constraint = constraint.Weld( TrackPhysics, self, 0, 0 )
	weld_constraint.DoNotDuplicate = true

	return TrackPhysics
end

function ENT:CreateWheelChain( wheels )
	if not istable( wheels ) then return end

	local Lock = 0.0001
	local VectorNull = Vector(0,0,0)

	for _, wheel in pairs( wheels ) do
		if not IsValid( wheel ) then continue end

		wheel:SetWheelChainMode( true )
		wheel:SetWidth( 0 )
		wheel:SetCollisionBounds( VectorNull, VectorNull )
	end

	for i = 2, #wheels do
		local prev = wheels[ i - 1 ]
		local cur = wheels[ i ]

		if not IsValid( cur ) or not IsValid( prev ) then continue end

		local B = constraint.AdvBallsocket(prev,cur,0,0,vector_origin,vector_origin,0,0,-Lock,-180,-180,Lock,180,180,0,0,0,1,1)
		B.DoNotDuplicate = true

		local Rope = constraint.Rope(prev,cur,0,0,vector_origin,vector_origin,(prev:GetPos() - cur:GetPos()):Length(), 0, 0, 0,"cable/cable2", false)
		Rope.DoNotDuplicate = true
	end

	local WheelChain = {}

	WheelChain.OnDestroyed = function( ent )
		if not IsValid( ent ) or ent._tracksDestroyed then return end

		ent._tracksDestroyed = true

		self:OnTrackDestroyed( ent.wheeltype )
		self:OnHandleTrackGib( ent.wheeltype, true )

		for _, wheel in pairs( wheels ) do
			if not IsValid( wheel ) then continue end

			wheel:Destroy()
		end
	end

	WheelChain.OnRepaired = function( ent )
		for _, wheel in pairs( wheels ) do
			if not IsValid( wheel ) then continue end

			wheel:Repair()
		end

		if not IsValid( ent ) or not ent._tracksDestroyed then return end

		ent._tracksDestroyed = nil

		self:OnTrackRepaired( ent.wheeltype )
		self:OnHandleTrackGib( ent.wheeltype, false )
	end

	WheelChain.OnHealthChanged = function( ent, dmginfo, old, new )
		if new >= old then return end

		for _, wheel in pairs( wheels ) do
			if not IsValid( wheel ) then continue end

			wheel:SetDamaged( true )
		end
	end

	return WheelChain
end

function ENT:SetTrackArmor( Armor, WheelChain )
	if not IsValid( Armor ) then return end

	Armor.OnDestroyed = WheelChain.OnDestroyed
	Armor.OnRepaired = WheelChain.OnRepaired
	Armor.OnHealthChanged = WheelChain.OnHealthChanged
	Armor:SetLabel( "Tracks" )
end

function ENT:OnTrackRepaired( wheeltype )
	if wheeltype == LVS.WHEELTYPE_LEFT then
		self:OnLeftTrackRepaired()
	end

	if wheeltype == LVS.WHEELTYPE_RIGHT then
		self:OnRightTrackRepaired()
	end
end

function ENT:OnTrackDestroyed( wheeltype )
	if wheeltype == LVS.WHEELTYPE_LEFT then
		self:OnLeftTrackDestroyed()
	end

	if wheeltype == LVS.WHEELTYPE_RIGHT then
		self:OnRightTrackDestroyed()
	end
end

function ENT:SetTrackArmorLeft( Armor, WheelChain )

	Armor.wheeltype = LVS.WHEELTYPE_LEFT

	self:SetTrackArmor( Armor, WheelChain )
end

function ENT:SetTrackArmorRight( Armor, WheelChain )

	Armor.wheeltype = LVS.WHEELTYPE_RIGHT

	self:SetTrackArmor( Armor, WheelChain )
end

function ENT:OnHandleTrackGib( wheeltype, destroy )
	local TrackPhys = self:GetTrackPhysics()

	if not IsValid( TrackPhys ) then return end

	if destroy then
		TrackPhys:SpawnGib( wheeltype )

		return
	end

	TrackPhys:ClearGib()
end
