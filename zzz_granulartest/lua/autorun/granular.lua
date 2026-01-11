if SERVER then return end

local testsound = "eng_granular.wav"

local granular = {}
granular.ActiveSounds = {}
granular.FileLengths = {}

function granular.Update()
	local T = CurTime()

	for id, data in pairs( granular.ActiveSounds ) do
		if not IsValid( data.sound ) or data.finishtime < T then
			data.sound:Stop()

			granular.ActiveSounds[ id ] = nil

			continue
		end

		local volume = (1 - (math.max( T - data.fadeout, 0 ) / (data.finishtime - data.fadeout)) - math.max( (data.fadein - T) / (data.fadein - data.starttime), 0 )) * data.volume

		data.sound:SetVolume( volume )
	end
end

function granular.PlaySound( filename, volume, starttime, duration, fadein, fadeout, fadeexp )
	if not isnumber( starttime ) or not isnumber( volume ) or not isnumber( duration ) or not isnumber( fadein ) or not isnumber( fadeout ) then return end

	if not fadeexp then fadeexp = 1 end

	starttime = math.max( starttime, 0 )
	fadeout = math.max( fadeout, RealFrameTime() )

	sound.PlayFile( "sound/"..filename, "noblock noplay", function( station, errCode, errStr )
		if not IsValid( station ) then return end

		station:SetTime( starttime, true )
		station:SetVolume( 0 )
		station:Play()

		if not granular.FileLengths[ filename ] then
			granular.FileLengths[ filename ] = station:GetLength()
		end

		local T = CurTime()

		local start = T
		local finish = start + duration

		local data = {
			sound = station,
			filename = filename,
			starttime = start,
			finishtime = finish,
			fadein = start + fadein,
			fadeout = finish - fadeout,
			volume = volume,
		}

		table.insert( granular.ActiveSounds, data )
	end )
end

local Next = 0
hook.Add( "Think", "lvs_granular_sound", function()
	granular:Update()

	local T = CurTime()
	local FT = FrameTime()

	if Next > T then return end

	local ratio = math.abs( math.Clamp( (LocalPlayer():EyeAngles().p - 45) / 90 + math.cos( CurTime() * 1500 ) * 0.015,-1,0) )
	local invratio = math.max(1 - ratio,0)

	local start = ratio * (granular.FileLengths[ testsound ] or 1)

	local duration = (0.01 + invratio * 0.09) + math.Rand(0,1) * (0.001 + invratio * 0.019)
	local fadein = 0.05 + math.Rand(0,1) * 0.05
	local fadeout = 0.2 + math.Rand(0,1) * 0.05

	granular.PlaySound( testsound, 1, start - fadein, duration + fadein + fadeout, fadein, fadeout )

	Next = T + duration
end )