AddCSLuaFile()

ENT.Type            = "anim"

function ENT:SetupDataTables()
	self:NetworkVar( "Int",0, "GameState" )

	self:NetworkVar( "Float",0, "GameTime" )
	self:NetworkVar( "Float",1, "GameTimeAdd" )

	self:NetworkVar( "Float",2, "TimeLeftTeam1" )
	self:NetworkVar( "Float",3, "TimeLeftTeam2" )

	self:NetworkVar( "Entity",1, "GoalEntity" )
	self:NetworkVar( "Vector",1, "GoalPos" )
end

if SERVER then
	function ENT:Initialize()
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )
	end

	function ENT:Think()
		local GoalEntity = self:GetGoalEntity()

		if not IsValid( GoalEntity ) then
			self:NextThink( CurTime() + 1 )

			return true
		end

		self:SetGoalPos( GoalEntity:GetPos() )
		self:NextThink( CurTime() )

		return true
	end

	function ENT:OnRemove()
	end

	function ENT:UpdateTransmitState() 
		return TRANSMIT_ALWAYS
	end
else
	function ENT:Initialize()
		GAMEMODE._NetworkEntity = self
	end

	function ENT:Think()
	end

	function ENT:OnRemove()
	end

	function ENT:Draw()
	end
end
