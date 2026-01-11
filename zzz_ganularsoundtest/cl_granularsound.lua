
LVS.SOUNDTYPE_GRANULAR = 5

local meta = FindMetaTable( "Entity" )

local granular = {}
granular.ActiveSounds = {}
granular.FileLengths = {}

function LVS:GetFileLength( filename )
	if not granular.FileLengths[ filename ] then
		sound.PlayFile( "sound/"..filename, "noblock noplay", function( station, errCode, errStr )
			if not IsValid( station ) then granular.FileLengths[ filename ] = 1 return end

			granular.FileLengths[ filename ] = station:GetLength()
		end )
	end

	return granular.FileLengths[ filename ] or 1
end

function granular.Update()
	local T = CurTime()

	for id, data in pairs( granular.ActiveSounds ) do
		if not IsValid( data.sound ) or not IsValid( data.entity ) or data.finishtime < T then
			data.sound:Stop()

			granular.ActiveSounds[ id ] = nil

			continue
		end

		local volume = (1 - (math.max( T - data.fadeout, 0 ) / (data.finishtime - data.fadeout)) - math.max( (data.fadein - T) / (data.fadein - data.starttime), 0 )) * data.volume

		data.sound:SetPos( data.entity:GetPos() )
		data.sound:SetVolume( volume )
	end
end

function meta:lvsEmitSound( filename, volume, starttime, duration, fadein, fadeout, fadeexp )
	if not isnumber( starttime ) or not isnumber( volume ) or not isnumber( duration ) or not isnumber( fadein ) or not isnumber( fadeout ) then return end

	if not fadeexp then fadeexp = 1 end

	starttime = math.max( starttime, 0 )
	fadeout = math.max( fadeout, RealFrameTime() )

	sound.PlayFile( "sound/"..filename, "noblock noplay", function( station, errCode, errStr )
		if not IsValid( station ) then return end

		station:SetPos( self:GetPos() )
		station:SetTime( starttime, true )
		station:SetVolume( 0 )
		station:Play()

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
			entity = self,
		}

		table.insert( granular.ActiveSounds, data )
	end )
end

hook.Add( "Think", "lvs_granular_sound", function()
	granular:Update()
end )