if SERVER then return end

local granular = {}
granular.ActiveSounds = {}

function granular.Update()
	local T = CurTime()

	for id, data in pairs( granular.ActiveSounds ) do
		if not IsValid( data.sound ) or data.finishtime < T then
			data.sound:Stop()

			granular.ActiveSounds[ id ] = nil

			continue
		end

		local volume = (1 - (math.max( T - data.fadeout, 0 ) / (data.finishtime - data.fadeout)) - math.max( (data.fadein - T) / (data.fadein - data.starttime), 0 )) ^ 5

		data.sound:SetVolume( volume )
	end
end

function granular.PlaySound( filename, starttime, duration, fadein, fadeout, fadeexp )
	if not isnumber( starttime ) or not isnumber( duration ) or not isnumber( fadein ) or not isnumber( fadeout ) then return end

	if not fadeexp then fadeexp = 1 end

	starttime = math.max( starttime, 0 )
	fadeout = math.max( fadeout, RealFrameTime() )

	sound.PlayFile( "sound/"..filename, "noblock noplay", function( station, errCode, errStr )
		if not IsValid( station ) then return end

		station:SetTime( starttime, true )
		station:SetVolume( 0 )
		station:Play()

		local T = CurTime()

		local start = T
		local finish = start + duration

		local data = {
			sound = station,
			starttime = start,
			finishtime = finish,
			fadein = start + fadein,
			fadeout = finish - fadeout,
		}

		table.insert( granular.ActiveSounds, data )
	end )
end

--granular.PlaySound( "lvs/vehicles/ferrari_360/eng_granular.wav", 0, 1, 0, 1 )

local Next = 0
local OldRatio = 0
local SoundLength = 3.8
hook.Add( "Think", "lvs_granular_sound", function()
	granular:Update()

	local T = CurTime()
	local FT = FrameTime()

	if Next > T then return end

	local ratio = math.abs( math.Clamp( (LocalPlayer():EyeAngles().p - 45) / 90,-1,0) )

	local start = ratio * SoundLength
	local duration = 0.1
	local fadein = 0.1
	local fadeout = 0.25

	granular.PlaySound( "lvs/vehicles/ferrari_360/eng_granular.wav", start - fadein, duration + fadein + fadeout, fadein, fadeout )

	OldRatio = ratio

	Next = T + duration
end )