include("shared.lua")

ENT.TrackSystemEnable = false
ENT.TrackHull = Vector(1,1,1)
ENT.TrackData = {}

function ENT:CalcTrackScrollTexture()
	local EntTable = self:GetTable()

	if not EntTable.TrackSystemEnable then return end

	local DriveWheelFL = self:GetTrackDriveWheelLeft()
	if IsValid( DriveWheelFL ) then
		local rotation = self:WorldToLocalAngles( DriveWheelFL:GetAngles() ).r
		local scroll = self:CalcScroll( "scroll_left", rotation )

		self:SetPoseParameter(EntTable.TrackPoseParameterLeft, scroll * EntTable.TrackPoseParameterLeftMul )
		self:SetSubMaterial( EntTable.TrackLeftSubMaterialID, self:ScrollTexture( "left", EntTable.TrackScrollTexture, EntTable.TrackLeftSubMaterialMul * scroll ) )
	end

	local DriveWheelFR = self:GetTrackDriveWheelRight()
	if IsValid( DriveWheelFR ) then
		local rotation = self:WorldToLocalAngles( DriveWheelFR:GetAngles() ).r
		local scroll = self:CalcScroll( "scroll_right", rotation )

		self:SetPoseParameter(EntTable.TrackPoseParameterRight, scroll * EntTable.TrackPoseParameterRightMul )
		self:SetSubMaterial( EntTable.TrackRightSubMaterialID, self:ScrollTexture( "right", EntTable.TrackScrollTexture, EntTable.TrackRightSubMaterialMul * scroll ) )
	end
end

local WorldUp = Vector(0,0,1)

function ENT:CalcTracks()
	local EntTable = self:GetTable()

	if self:GetHP() <= 0 then
		if EntTable._ResetSubMaterials then
			EntTable._ResetSubMaterials = nil
			for i = 0, 128 do
				self:SetSubMaterial( i )
			end
		end

		return
	end

	EntTable._ResetSubMaterials = true

	local T = CurTime()

	if (EntTable._NextCalcTracks or 0) < T then
		local ply = LocalPlayer()

		if not IsValid( ply ) then return end

		local ViewEnt = ply:GetViewEntity()
		if IsValid( ViewEnt ) then
			ply = ViewEnt
		end

		local Delay = math.min( (self:GetPos() - ply:GetPos()):LengthSqr() * 0.00000005, 1 )

		EntTable._NextCalcTracks = T + Delay

		local Mul = math.max( Delay / RealFrameTime(), 1 )

		local TrackHull = EntTable.TrackHull * (math.max( WorldUp:Dot( self:GetUp() ), 0 ) ^ 2)

		EntTable._TrackPoseParameters = {}

		for _, data in pairs( EntTable.TrackData ) do
			if not istable( data.Attachment ) or not istable( data.PoseParameter ) then continue end
			if not isstring( data.PoseParameter.name ) then continue end

			local att = self:GetAttachment( self:LookupAttachment( data.Attachment.name ) )

			if not att then continue end

			local traceLength = data.Attachment.traceLength or 100
			local toGroundDistance = data.Attachment.toGroundDistance or 20

			local trace = util.TraceHull( {
				start = att.Pos,
				endpos = att.Pos - self:GetUp() * traceLength,
				filter = self:GetCrosshairFilterEnts(),
				mins = -TrackHull,
				maxs = TrackHull,
			} )

			local Rate = data.PoseParameter.lerpSpeed or 25
			local Dist = (att.Pos - trace.HitPos):Length() + EntTable.TrackHull.z - toGroundDistance

			local RangeMul = data.PoseParameter.rangeMultiplier or 1

			if data.IsBonePP == nil then
				data.IsBonePP = string.StartsWith( data.PoseParameter.name, "!" )

				continue

			end

			EntTable._TrackPoseParameters[ data.PoseParameter.name ] = {}
			EntTable._TrackPoseParameters[ data.PoseParameter.name ].IsBonePP = data.IsBonePP

			if data.IsBonePP then
				EntTable._TrackPoseParameters[ data.PoseParameter.name ].Pose = math.Clamp( self:QuickLerp( data.PoseParameter.name, Dist * RangeMul, Rate * Mul ) / (data.PoseParameter.range or 10), 0 , 1 )
			else
				EntTable._TrackPoseParameters[ data.PoseParameter.name ].Pose = self:QuickLerp( data.PoseParameter.name, Dist * RangeMul, Rate * Mul )
			end
		end
	end

	if not EntTable._TrackPoseParameters then return end

	for name, data in pairs( EntTable._TrackPoseParameters ) do
		if data.IsBonePP then
			self:SetBonePoseParameter( name, data.Pose )

			continue
		end
		self:SetPoseParameter( name, data.Pose )
	end

	self:CalcTrackScrollTexture()
end

DEFINE_BASECLASS( "lvs_base_wheeldrive" )

function ENT:Think()
	if not self:IsInitialized() then return end

	self:CalcTracks()

	BaseClass.Think( self )
 end

ENT.TrackSounds = "lvs/vehicles/sherman/tracks_loop.wav"

ENT.TireSoundTypes = {
	["skid"] = "common/null.wav",
	["skid_dirt"] = "lvs/vehicles/generic/wheel_skid_dirt.wav",
	["skid_wet"] = "common/null.wav",
	["tracks_damage_layer"] = "lvs/tracks_damaged_loop.wav",
	["tire_damage_layer"] = "lvs/wheel_destroyed_loop.wav",
}

function ENT:TireSoundThink()
	for snd, _ in pairs( self.TireSoundTypes ) do
		local T = self:GetTireSoundTime( snd )

		if T > 0 then
			local speed = self:GetVelocity():Length()

			local sound = self:StartTireSound( snd )

			if string.StartsWith( snd, "skid" ) or snd == "tire_damage_layer" then
				local vel = speed
				speed = math.max( math.abs( self:GetWheelVelocity() ) - vel, 0 ) * 5 + vel
			end

			local volume = math.min(speed / math.max( self.MaxVelocity, self.MaxVelocityReverse ),1) ^ 2 * T
			local pitch = 100 + math.Clamp((speed - 400) / 200,0,155)

			if snd == "tracks_damage_layer" then
				volume = math.min( speed / 100, 1 ) * T
			end

			sound:ChangeVolume( volume, 0 )
			sound:ChangePitch( pitch, 0.5 ) 
		else
			self:StopTireSound( snd )
		end
	end
end

function ENT:DoTireSound( snd )
	if not istable( self._TireSounds ) then
		self._TireSounds = {}
	end

	if string.StartsWith( snd, "roll" ) then
		snd = "roll"
	end

	self._TireSounds[ snd ] = CurTime() + self.TireSoundFade
end

function ENT:StartTireSound( snd )
	if not self.TireSoundTypes[ snd ] or not istable( self._ActiveTireSounds ) then
		self._ActiveTireSounds = {}
	end

	if self._ActiveTireSounds[ snd ] then return self._ActiveTireSounds[ snd ] end

	local sound = CreateSound( self, (snd == "roll") and self.TrackSounds or self.TireSoundTypes[ snd ]  )
	sound:SetSoundLevel( string.StartsWith( snd, "skid" ) and self.TireSoundLevelSkid or self.TireSoundLevelRoll )
	sound:PlayEx(0,100)

	self._ActiveTireSounds[ snd ] = sound

	return sound
end
