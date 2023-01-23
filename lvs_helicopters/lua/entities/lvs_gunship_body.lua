AddCSLuaFile()

ENT.Type            = "anim"

ENT.Spawnable		= false
ENT.AdminOnly		= false
ENT.DoNotDuplicate = true

ENT.AutomaticFrameAdvance = true

ENT._LVS = true

function ENT:PlayAnimation( animation, playbackrate )
	playbackrate = playbackrate or 1

	local sequence = self:LookupSequence( animation )

	self:ResetSequence( sequence )
	self:SetPlaybackRate( playbackrate )
	self:SetSequence( sequence )
end

if SERVER then
	function ENT:Initialize()	
		self:SetModel( "models/gunship.mdl" )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
	end

	function ENT:Think()	
		self:NextThink( CurTime() )

		return true
	end
else
	function ENT:Initialize()	
	end

	function ENT:Draw()
		self:DrawModel()
	end

	function ENT:Think()
	end

	function ENT:OnRemove()
	end
end