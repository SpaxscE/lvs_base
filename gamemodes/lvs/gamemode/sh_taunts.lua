
GM.GenderVoices = {
	TeamKill = {
		Male = {
			"vo/npc/male01/pardonme01.wav",
			"vo/npc/male01/pardonme02.wav",
			"vo/npc/male01/excuseme01.wav",
			"vo/npc/male01/excuseme02.wav",
			"vo/npc/male01/sorry01.wav",
			"vo/npc/male01/sorry02.wav",
			"vo/npc/male01/sorry03.wav",
			"vo/npc/male01/whoops01.wav",
			"vo/npc/male01/question26.wav",
			"vo/npc/male01/goodgod.wav",
			"vo/npc/male01/watchwhat.wav",
			"vo/npc/male01/wetrustedyou01.wav",
			"vo/npc/male01/wetrustedyou02.wav",
			"vo/npc/male01/heretohelp01.wav",
			"vo/npc/male01/heretohelp02.wav",
			"vo/npc/male01/notthemanithought01.wav",
			"vo/npc/male01/notthemanithought02.wav",
		},
		Female = {
			"vo/npc/female01/pardonme01.wav",
			"vo/npc/female01/pardonme02.wav",
			"vo/npc/female01/excuseme01.wav",
			"vo/npc/female01/excuseme02.wav",
			"vo/npc/female01/sorry01.wav",
			"vo/npc/female01/sorry02.wav",
			"vo/npc/female01/sorry03.wav",
			"vo/npc/female01/whoops01.wav",
			"vo/npc/female01/question26.wav",
			"vo/npc/female01/goodgod.wav",
			"vo/npc/female01/watchwhat.wav",
			"vo/npc/female01/wetrustedyou01.wav",
			"vo/npc/female01/wetrustedyou02.wav",
			"vo/npc/female01/heretohelp01.wav",
			"vo/npc/female01/heretohelp02.wav",
			"vo/npc/female01/notthemanithought01.wav",
			"vo/npc/female01/notthemanithought02.wav",
		},
	},
	Kill = {
		Male = {
			"vo/npc/male01/nice.wav",
			"vo/npc/male01/fantastic01.wav",
			"vo/npc/male01/fantastic02.wav",
			"vo/npc/male01/oneforme.wav",
			"vo/npc/male01/yougotit02.wav",
			"vo/npc/male01/yeah02.wav",
			"vo/npc/male01/question01.wav",
			"vo/npc/male01/question02.wav",
			"vo/npc/male01/question03.wav",
			"vo/npc/male01/question04.wav",
			"vo/npc/male01/question05.wav",
			"vo/npc/male01/question07.wav",
			"vo/npc/male01/question10.wav",
			"vo/npc/male01/question11.wav",
			"vo/npc/male01/question25.wav",
			"vo/npc/male01/question29.wav",
			"vo/npc/male01/question30.wav",
		},
		Female = {
			"vo/npc/female01/nice01.wav",
			"vo/npc/female01/nice02.wav",
			"vo/npc/female01/fantastic01.wav",
			"vo/npc/female01/fantastic02.wav",
			"vo/npc/female01/yougotit02.wav",
			"vo/npc/female01/yeah02.wav",
			"vo/npc/female01/question01.wav",
			"vo/npc/female01/question02.wav",
			"vo/npc/female01/question03.wav",
			"vo/npc/female01/question04.wav",
			"vo/npc/female01/question05.wav",
			"vo/npc/female01/question07.wav",
			"vo/npc/female01/question10.wav",
			"vo/npc/female01/question11.wav",
			"vo/npc/female01/question25.wav",
			"vo/npc/female01/question29.wav",
			"vo/npc/female01/question30.wav",
		},
	},
	KillAggro = {
		Male = {
			"vo/npc/male01/likethat.wav",
			"vo/npc/male01/gotone01.wav",
			"vo/npc/male01/gotone02.wav",
			"vo/npc/male01/question22.wav",
		},
		Female = {
			"vo/npc/female01/likethat.wav",
			"vo/npc/female01/gotone01.wav",
			"vo/npc/female01/gotone02.wav",
			"vo/npc/female01/question22.wav",
		},
	},
}

local meta = FindMetaTable( "Player" )

-- gmod gender function copyright Luna/Julie werding/Blu-x92
-- there are only two genders, Male and Female. Gender is defined by the body. This can not be changed.
function meta:GetGender()
	local Model = self:GetModel()

	if self._oldModel == Model and self._Gender then return self._Gender end

	self._oldModel = Model

	-- body defines gender
	for _, entry in pairs( self:GetSubModels() ) do
		if string.match( entry.name, "f_anm.mdl" ) then
			self._Gender = "Female"

			return "Female"
		end
	end

	self._Gender = "Male"

	return "Male"
end

if CLIENT then
	function meta:PlayTaunt( name )
		self:EmitSound( name , 90, 100, 1, CHAN_VOICE )
	end

	net.Receive( "lvs_playertaunts", function( len )
		local target = net.ReadEntity()
		local sound = net.ReadString()

		if not IsValid( target ) then return end

		local ply = LocalPlayer()

		if target == ply then return end

		target:PlayTaunt( sound )
	end )

	return
end

util.AddNetworkString( "lvs_playertaunts" )

function meta:PlayTaunt( name )
	local  T = CurTime()

	if not self._LastTauntSaid then
		self._LastTauntSaid = {}
	end

	if self._LastTauntSaid[ name ] and self._LastTauntSaid[ name ] > T then return end

	if (self._LastSaid or 0) > T then return end

	net.Start( "lvs_playertaunts" )
		net.WriteEntity( self )
		net.WriteString( name )
	net.SendPAS( self:GetShootPos() )

	self._LastTauntSaid[ name ] = T + math.random(45,120)

	self._LastSaid = T + math.random(3,4)
end

function GM:HandlePlayerTaunt( attacker, victim, is_teamkill )
	local T = CurTime()

	local Gender = attacker:GetGender()

	timer.Simple(0.3, function()
		if not IsValid( attacker ) then return end

		attacker._Intentional = attacker:KeyDown( IN_ATTACK )
	end)

	if is_teamkill then
		timer.Simple(1, function()
			if not IsValid( attacker ) or not attacker:Alive() then return end

			attacker:PlayTaunt( table.Random( self.GenderVoices.TeamKill[ Gender ] ) )
		end)
	else
		timer.Simple(1, function()
			if not IsValid( attacker ) or not attacker:Alive() then return end

			if attacker._Intentional then
				attacker:PlayTaunt( table.Random( self.GenderVoices.KillAggro[ Gender ] ) )
			else
				attacker:PlayTaunt( table.Random( self.GenderVoices.Kill[ Gender ] ) )
			end
		end)
	end
end
