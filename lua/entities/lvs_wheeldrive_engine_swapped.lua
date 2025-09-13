AddCSLuaFile()

ENT.Base = "lvs_wheeldrive_engine"
DEFINE_BASECLASS( "lvs_wheeldrive_engine" )

ENT.DoNotDuplicate = true

ENT._LVS = true

ENT.lvsEngine = true

if SERVER then
	util.AddNetworkString( "lvs_engine_swap" )

	net.Receive("lvs_engine_swap", function( len, ply )
		local ent = net.ReadEntity()

		if not IsValid( ent ) or not ent.lvsEngine then return end

		if not istable( ent.EngineSounds ) then return end

		net.Start("lvs_engine_swap")
			net.WriteEntity( ent )
			net.WriteTable( ent.EngineSounds )
		net.Send( ply )
	end)
else
	net.Receive("lvs_engine_swap", function( len )
		local ent = net.ReadEntity()

		if not IsValid( ent ) then return end

		ent.EngineSounds = net.ReadTable()
	end)

	function ENT:Think()
		local vehicle = self:GetBase()

		if not IsValid( vehicle ) then return end

		self:DamageFX( vehicle )

		if not self.EngineSounds then
			self.EngineSounds = {}

			net.Start("lvs_engine_swap")
				net.WriteEntity( self )
			net.SendToServer()

			return
		end

		local EngineActive = vehicle:GetEngineActive()

		if self._oldEnActive ~= EngineActive then
			self._oldEnActive = EngineActive

			self:OnEngineActiveChanged( EngineActive )
		end

		if EngineActive then
			self:HandleEngineSounds( vehicle )
			self:ExhaustFX( vehicle )
		end
	end
end