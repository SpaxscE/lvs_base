AddCSLuaFile()

ENT.Type            = "anim"
ENT.DoNotDuplicate = true

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Base" )
	self:NetworkVar( "Entity",1, "DoorHandler" )

	self:NetworkVar( "Bool",0, "Active" )
	self:NetworkVar( "Bool",1, "HighActive" )
	self:NetworkVar( "Bool",2, "FogActive" )

	if SERVER then
		self:NetworkVarNotify( "Active", self.OnActiveChanged )
	end
end

if SERVER then
	function ENT:Initialize()	
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false )
	end

	function ENT:OnActiveChanged( name, old, new)
		if new == old then return end

		local DoorHandler = self:GetDoorHandler()

		if not IsValid( DoorHandler ) then return end

		if new then
			if not DoorHandler:IsOpen() then
				DoorHandler:Open()
			end
		else
			if DoorHandler:IsOpen() then
				DoorHandler:Close()
			end
		end
	end

	function ENT:Think()
		local DoorHandler = self:GetDoorHandler()

		if not IsValid( DoorHandler ) then
			self:NextThink( CurTime() + 1 )
		else
			self:NextThink( CurTime() )

			if self:GetActive() and not DoorHandler:IsOpen() then
				DoorHandler:Open()
			end
		end

		return true
	end

	function ENT:OnTakeDamage( dmginfo )
	end

	return
end

function ENT:Initialize()
	local base = self:GetBase()

	if not IsValid( base ) or not isfunction( base.IsInitialized ) or not base:IsInitialized() then

		timer.Simple( 1, function()
			if not IsValid( self ) then return end

			self:Initialize()
		end )

		return
	end

	if not istable( base.Lights ) then return end

	self:InitializeLights( base, base.Lights )

	for typeid, typedata in pairs( base.Lights ) do
		if not typedata.Siren or not typedata.Trigger then continue end

		if not istable( self._TriggerList ) then
			self._TriggerList = {}
		end

		local data = {}
		data.pattern = {}

		for id, n in ipairs( string.Explode( "", typedata.Trigger ) ) do
			data.pattern[ id ] = tonumber( n or 0 )
		end

		data.cur = 1
		data.max = #data.pattern

		self._TriggerList[ typedata.Trigger ] = data
	end
end

function ENT:InitializeLights( base, data )

	if not istable( data ) then return end

	local materials = base:GetMaterials()

	for typeid, typedata in pairs( data ) do
		if not typedata.Trigger then
			data[typeid] = nil
		end

		if typedata.SubMaterialID then
			if isstring( typedata.SubMaterialID ) then
				local ID = table.KeyFromValue( materials, typedata.SubMaterialID )

				if isnumber( ID ) then
					data[typeid].SubMaterialID = ID - 1
				end
			end

			data[typeid].SubMaterial = self:CreateSubMaterial( typedata.SubMaterialID, typedata.Trigger )
			data[typeid].SubMaterialBrightness = typedata.SubMaterialBrightness or 1
		end

		if typedata.Sprites then
			for lightsid, lightsdata in pairs( typedata.Sprites ) do
				data[typeid].Sprites[ lightsid ].PixVis = util.GetPixelVisibleHandle()

				if isstring( lightsdata.pos ) then
					data[typeid].Sprites[ lightsid ].att = base:LookupAttachment( lightsdata.pos )
				else
					data[typeid].Sprites[ lightsid ].pos = isvector( lightsdata.pos ) and lightsdata.pos or vector_origin
				end

				data[typeid].Sprites[ lightsid ].mat = isstring( lightsdata.mat ) and Material( lightsdata.mat ) or Material( "sprites/light_ignorez" )
				data[typeid].Sprites[ lightsid ].width = lightsdata.width or 50
				data[typeid].Sprites[ lightsid ].height = lightsdata.height or 50
				data[typeid].Sprites[ lightsid ].colorR = lightsdata.colorR or 255
				data[typeid].Sprites[ lightsid ].colorG = lightsdata.colorG or 255
				data[typeid].Sprites[ lightsid ].colorB = lightsdata.colorB or 255
				data[typeid].Sprites[ lightsid ].colorA = lightsdata.colorA or 255
			end
		end

		if typedata.ProjectedTextures then
			for projid, projdata in pairs( typedata.ProjectedTextures ) do
				if typedata.Trigger == "high" then
					data[typeid].ProjectedTextures[ projid ].PixVis = util.GetPixelVisibleHandle()
				end

				if isstring( projdata.pos ) then
					local attachID = base:LookupAttachment( projdata.pos )

					data[typeid].ProjectedTextures[ projid ].att = attachID


					-- detect if the attachment is upside down
					local att = base:GetAttachment( attachID )
					if att then
						if base:WorldToLocalAngles( att.Ang ):Up().z < -0.9 then
							data[typeid].ProjectedTextures[ projid ].FixRotation = true
						end
					end
				else
					data[typeid].ProjectedTextures[ projid ].pos = projdata.pos or vector_origin
					data[typeid].ProjectedTextures[ projid ].ang = projdata.ang or angle_zero
				end

				data[typeid].ProjectedTextures[ projid ].mat = projdata.mat or (typedata.Trigger == "high" and "effects/flashlight/soft" or "effects/lvs/car_projectedtexture")
				data[typeid].ProjectedTextures[ projid ].farz = projdata.farz or (typedata.Trigger == "high" and 4000 or 1000)
				data[typeid].ProjectedTextures[ projid ].nearz = projdata.nearz or 65
				data[typeid].ProjectedTextures[ projid ].fov = projdata.fov or (typedata.Trigger == "high" and 40 or 60)
				data[typeid].ProjectedTextures[ projid ].colorR = projdata.colorR or 255
				data[typeid].ProjectedTextures[ projid ].colorG = projdata.colorG or 255
				data[typeid].ProjectedTextures[ projid ].colorB = projdata.colorB or 255
				data[typeid].ProjectedTextures[ projid ].colorA = projdata.colorA or 255
				data[typeid].ProjectedTextures[ projid ].color = Color( projdata.colorR or 255, projdata.colorG or 255, projdata.colorB or 255 )
				data[typeid].ProjectedTextures[ projid ].brightness = projdata.brightness or (typedata.Trigger == "high" and 5 or 5)
				data[typeid].ProjectedTextures[ projid ].shadows = projdata.shadows == true
			end
		end

		if typedata.DynamicLights then
			for dLightid, dLightdata in pairs( typedata.DynamicLights ) do

				if isstring( dLightdata.pos ) then
					data[typeid].DynamicLights[ dLightid ].att = base:LookupAttachment( dLightdata.pos )
				else
					data[typeid].DynamicLights[ dLightid ].pos = isvector( dLightdata.pos ) and dLightdata.pos or vector_origin
				end

				data[typeid].DynamicLights[ dLightid ].colorR = dLightdata.colorR or 255
				data[typeid].DynamicLights[ dLightid ].colorG = dLightdata.colorG or 255
				data[typeid].DynamicLights[ dLightid ].colorB = dLightdata.colorB or 255
				data[typeid].DynamicLights[ dLightid ].brightness = dLightdata.brightness or 0.1
				data[typeid].DynamicLights[ dLightid ].decay = dLightdata.decay or 1000
				data[typeid].DynamicLights[ dLightid ].size = dLightdata.size or 128
				data[typeid].DynamicLights[ dLightid ].lifetime = dLightdata.lifetime or 0.1
			end
		end
	end

	self.Enabled = true
end

function ENT:CreateSubMaterial( SubMaterialID, name )
	local base = self:GetBase()

	if not IsValid( base ) or not isnumber( SubMaterialID ) then return end

	local mat = base:GetMaterials()[ SubMaterialID + 1 ]

	if not mat then return end

	local string_data = file.Read( "materials/"..mat..".vmt", "GAME" )

	if not string_data then return end

	return CreateMaterial( name..SubMaterialID..base:GetClass()..base:EntIndex(), "VertexLitGeneric", util.KeyValuesToTable( string_data ) )
end

function ENT:ResetSubMaterials()
	local base = self:GetBase()

	if not IsValid( base ) then return end

	local data = base.Lights

	if not istable( data ) then return end

	for typeid, typedata in pairs( data ) do
		if not typedata.SubMaterialID or not typedata.SubMaterial then continue end

		base:SetSubMaterial(typedata.SubMaterialID, "")
	end
end

function ENT:CreateProjectedTexture( id, mat, col, brightness, shadows, nearz, farz, fov )
	if not mat then return end

	local thelamp = ProjectedTexture()
	thelamp:SetTexture( mat )
	thelamp:SetColor( col )
	thelamp:SetBrightness( brightness ) 
	thelamp:SetEnableShadows( shadows ) 
	thelamp:SetNearZ( nearz ) 
	thelamp:SetFarZ( farz ) 
	thelamp:SetFOV( fov )

	if istable( self._ProjectedTextures ) then
		if IsValid( self._ProjectedTextures[ id ] ) then
			self._ProjectedTextures[ id ]:Remove()
			self._ProjectedTextures[ id ] = nil
		end
	else
		self._ProjectedTextures = {}
	end

	self._ProjectedTextures[ id ] = thelamp

	return thelamp
end

function ENT:GetProjectedTexture( id )
	if not id or not istable( self._ProjectedTextures ) then return end

	return self._ProjectedTextures[ id ]
end

function ENT:RemoveProjectedTexture( id )
	if not id or not istable( self._ProjectedTextures ) then return end

	if IsValid( self._ProjectedTextures[ id ] ) then
		self._ProjectedTextures[ id ]:Remove()
		self._ProjectedTextures[ id ] = nil
	end
end

function ENT:ClearProjectedTextures()
	if not istable( self._ProjectedTextures ) then return end

	for id, proj in pairs( self._ProjectedTextures ) do
		if IsValid( proj ) then
			proj:Remove()
		end

		self._ProjectedTextures[ id ] = nil
	end
end

local function DistanceMul( ent )
	local dist = (LocalPlayer():GetPos() - ent:GetPos()):LengthSqr() / 10000000

	return math.max( 1 - dist, 0 )
end

function ENT:LightsThink( base )
	local EntID = base:EntIndex()
	local Class = base:GetClass()
	local data = base.Lights

	if not istable( data ) then return end

	local brightness = DistanceMul( self )

	for typeid, typedata in pairs( data ) do
		local mul = self:GetTypeActivator( typedata.Trigger ) * brightness
		local active = mul > 0.01

		if typedata.Trigger == "main" then
			if self:GetHighActive() then
				active = false
			end
		end

		if typedata.ProjectedTextures then
			for projid, projdata in pairs( typedata.ProjectedTextures ) do
				local id = typeid.."-"..projid

				local proj = self:GetProjectedTexture( id )
				local proj_active = active

				if proj_active and istable( projdata.bodygroup ) then
					if not base:BodygroupIsValid( projdata.bodygroup.name, projdata.bodygroup.active ) then
						proj_active = false
					end
				end

				if IsValid( proj ) then
					if proj_active then
						proj:SetBrightness( projdata.brightness * mul ) 

						if projdata.att then
							local att = base:GetAttachment( projdata.att )

							if att then
								proj:SetPos( att.Pos )

								-- its upside down...
								if projdata.FixRotation then
									att.Ang:RotateAroundAxis( att.Ang:Forward(), 180 )
								end

								proj:SetAngles( att.Ang )
							end
						else
							if not isvector( projdata.pos ) then self:InitializeLights( base ) break end

							proj:SetPos( base:LocalToWorld( projdata.pos ) )
							proj:SetAngles( base:LocalToWorldAngles( projdata.ang ) )
						end

						proj:Update()
					else
						self:RemoveProjectedTexture( id )
					end
				else
					if proj_active then
						self:CreateProjectedTexture( id, projdata.mat, projdata.color, projdata.brightness, projdata.shadows, projdata.nearz, projdata.farz, projdata.fov )
					else
						self:RemoveProjectedTexture( id )
					end
				end
			end
		end

		if typedata.DynamicLights then
			for dLightid, dLightdata in pairs( typedata.DynamicLights ) do
				if not active then continue end

				local dlight = DynamicLight( self:EntIndex() * 1000 + dLightid )

				if not dlight then continue end

				local pos

				if dLightdata.att then
					local att = base:GetAttachment( dLightdata.att )

					if not att then
						dlight.pos = vector_origin
					else
						dlight.pos = att.Pos
					end
				else
					if not isvector( dLightdata.pos ) then self:InitializeLights( base ) break end

					dlight.pos = base:LocalToWorld( dLightdata.pos )
				end

				dlight.r = dLightdata.colorR
				dlight.g = dLightdata.colorG
				dlight.b = dLightdata.colorB
				dlight.brightness = dLightdata.brightness
				dlight.decay = dLightdata.decay
				dlight.size = dLightdata.size
				dlight.dietime = CurTime() + dLightdata.lifetime
			end
		end

		if not isnumber( typedata.SubMaterialID ) or not typedata.SubMaterial then continue end

		typedata.SubMaterial:SetFloat("$detailblendfactor", mul * typedata.SubMaterialBrightness )

		if typedata.SubMaterialValue ~= active then
			data[typeid].SubMaterialValue = active
			base:SetSubMaterial(typedata.SubMaterialID, "!"..typedata.Trigger..typedata.SubMaterialID..Class..EntID)
		end
	end
end

function ENT:LerpActivator( name, target, rate )
	name =  "_sm"..name

	if not self[ name ] then self[ name ] = 0 end

	if not rate then rate = 10 end

	self[ name ] = self[ name ] + (target - self[ name ]) * rate

	return self[ name ]
end

function ENT:GetTypeActivator( name )
	if not self[ "_sm"..name ] then return 0 end

	return self[ "_sm"..name ] ^ 2
end

local Left = {
	[1] = true,
	[3] = true,
}
local Right = {
	[2] = true,
	[3] = true,
}

function ENT:CalcTypeActivators( base )
	local base = self:GetBase()

	if not IsValid( base ) then return end

	local main = self:GetActive() and 1 or 0
	local high = self:GetHighActive() and 1 or 0
	local fog = self:GetFogActive() and 1 or 0
	local brake = base:GetBrake() > 0 and 1 or 0
	local reverse = base:GetReverse() and 1 or 0

	local engineActive = base:GetEngineActive() and 1 or 0

	local Flasher = base:GetTurnFlasher()
	local TurnMode = base:GetTurnMode()

	local turnleft = (Left[ TurnMode ] and Flasher) and 1 or 0
	local turnright = (Right[ TurnMode ] and Flasher) and 1 or 0

	local Rate = RealFrameTime() * 10

	self:LerpActivator( "active", engineActive, Rate )
	self:LerpActivator( "fog", fog, Rate )
	self:LerpActivator( "brake", brake, Rate )
	self:LerpActivator( "reverse", reverse, Rate )
	self:LerpActivator( "turnleft", turnleft, Rate * 2 )
	self:LerpActivator( "turnright", turnright, Rate * 2 )

	local DoorHandler = self:GetDoorHandler()
	if IsValid( DoorHandler ) then
		main = (DoorHandler.sm_pp or 0) >= 0.5 and main or 0
		high = (DoorHandler.sm_pp or 0) >= 0.5 and high or 0
	end

	self:LerpActivator( "main", main, Rate )

	if Left[ TurnMode ] then
		if main >= 0.5 then
			self:LerpActivator( "main+brake+turnleft", main * 0.8 + turnleft * 1.5, Rate )
		else
			self:LerpActivator( "main+brake+turnleft", turnleft, Rate )
		end
	else
		if main >= 0.5 then
			self:LerpActivator( "main+brake+turnleft", main * 0.8 + brake * 1.5, Rate )
		else
			self:LerpActivator( "main+brake+turnleft", brake, Rate )
		end
	end

	if Right[ TurnMode ] then
		if main >= 0.5 then
			self:LerpActivator( "main+brake+turnright", main * 0.8 + turnright * 1.5, Rate )
		else
			self:LerpActivator( "main+brake+turnright", turnright, Rate )
		end
	else
		if main >= 0.5 then
			self:LerpActivator( "main+brake+turnright", main * 0.8 + brake * 1.5, Rate )
		else
			self:LerpActivator( "main+brake+turnright", brake, Rate )
		end
	end

	if main >= 0.5 then
		self:LerpActivator( "main+brake", main * 0.8 + brake * 1.2, Rate )
	else
		self:LerpActivator( "main+brake", brake, Rate )
	end

	self:LerpActivator( "main+high", main + high, Rate )

	self:LerpActivator( "main+fog", main + fog, Rate )

	self:LerpActivator( "high", high, Rate )

	if not istable( self._TriggerList ) then return end

	local RateSiren = math.min( Rate * 50, 1 )

	if base:GetSirenMode() < 0 then
		for id, data in pairs( self._TriggerList ) do
			self:LerpActivator( id, 0, RateSiren )
		end

		return
	end

	for id, data in pairs( self._TriggerList ) do
		self:LerpActivator( id, data.pattern[ data.cur ], RateSiren )
	end

	local T = CurTime() + self:EntIndex() * 1337

	if (self._calcNext or 0) > T then return end

	self._calcNext = T + 0.1

	for id, data in pairs( self._TriggerList ) do
		data.cur = data.cur + 1

		if data.cur > data.max then
			data.cur = 1
		end
	end
end

ENT.LensFlare1 = Material( "effects/lvs/car_lensflare" )
ENT.LensFlare2 = Material( "sprites/light_ignorez" )
ENT.LightMaterial = Material( "effects/lvs/car_spotlight" )
function ENT:GetAmbientLight( base )
	local T = CurTime()
	local FT = RealFrameTime()
	local ply = LocalPlayer()

	if not IsValid( ply ) then return 0, vector_origin end

	local plyPos = ply:GetShootPos()

	local ViewEnt = ply:GetViewEntity()

	if IsValid( ViewEnt ) and ViewEnt ~= ply then
		plyPos = ViewEnt:GetPos()
	end

	local EntTable = self:GetTable()

	if (EntTable._NextLightCheck or 0) > T then return (EntTable._AmbientLightMul or 0), plyPos end

	local LightVeh = render.GetLightColor( base:LocalToWorld( base:OBBCenter() ) )
	local LightPlayer = render.GetLightColor( plyPos )
	local AmbientLightMul =  (1 - math.min( LightVeh:Dot( LightPlayer ) * 200, 1 )) ^ 2

	EntTable._NextLightCheck = T + FT

	if not EntTable._AmbientLightMul then
		EntTable._AmbientLightMul = 0
	end

	EntTable._AmbientLightMul = EntTable._AmbientLightMul and EntTable._AmbientLightMul + (AmbientLightMul - EntTable._AmbientLightMul) * FT or 0

	return EntTable._AmbientLightMul, plyPos
end

local DoMagic = {
	["main"] = true,
	["high"] = true,
	["main+high"] = true,
}

function ENT:RenderLights( base, data )
	if not self.Enabled then return end

	local brightness = 1 - DistanceMul( self )

	for _, typedata in pairs( data ) do

		local mul = self:GetTypeActivator( typedata.Trigger )

		if mul < 0.01 then continue end

		if typedata.ProjectedTextures and DoMagic[ typedata.Trigger ] then
			for projid, projdata in pairs( typedata.ProjectedTextures ) do
				if istable( projdata.bodygroup ) then
					if not base:BodygroupIsValid( projdata.bodygroup.name, projdata.bodygroup.active ) then continue end
				end

				local pos
				local dir

				if projdata.att then
					local att = base:GetAttachment( projdata.att )

					if not att then continue end

					pos = att.Pos
					dir =  att.Ang:Forward()

				else
					pos = base:LocalToWorld( projdata.pos )
					dir = base:LocalToWorldAngles( projdata.ang ):Forward()
				end

				if not projdata.colorR or not projdata.colorG or not projdata.colorB or not projdata.brightness then self:InitializeLights( base ) break end

				local L = 100 + 700 * brightness
				local W = 50 + 100 * brightness

				render.SetMaterial( self.LightMaterial )
				render.DrawBeam( pos, pos + dir * L, W, -0.01, 0.99, Color( projdata.colorR * mul, projdata.colorG * mul, projdata.colorB * mul, projdata.brightness ) )

				if not projdata.PixVis then continue end

				local AmbientLightMul, plyPos = self:GetAmbientLight( base )
	
				local visible = util.PixelVisible( pos, 1, projdata.PixVis ) * mul

				if not visible or visible == 0 then continue end

				local aimdir = (plyPos - pos):GetNormalized()

				local ang = base:AngleBetweenNormal( dir, aimdir )

				if ang < 20 then
					local Alpha = 1 - (ang / 20) * 255
					render.SetMaterial( self.LensFlare2 )
					render.DrawSprite( pos, 512, 512, Color( projdata.colorR * mul * AmbientLightMul, projdata.colorG * mul * AmbientLightMul, projdata.colorB * mul * AmbientLightMul, Alpha * visible) )
				end
				if ang < 10 then
					local RGB = 30 * AmbientLightMul * mul
					local Scale = 1 - (ang / 10)
					local Alpha = Scale * 255 * math.Rand(0.8,1.2) * visible
					local ScaleX = 1024 * math.Rand(0.98,1.02)
					local ScaleY = 1024 * math.Rand(0.98,1.02)

					render.SetMaterial( self.LensFlare1 )
					render.DrawSprite( pos, ScaleX, ScaleY, Color(RGB,RGB,RGB,Alpha) )
				end
			end
		end

		if not typedata.Sprites then continue end

		for id, lightsdata in pairs( typedata.Sprites ) do
			if not lightsdata.PixVis then
				continue
			end

			if istable( lightsdata.bodygroup ) then
				if not base:BodygroupIsValid( lightsdata.bodygroup.name, lightsdata.bodygroup.active ) then continue end
			end

			local pos

			if lightsdata.att then
				local att = base:GetAttachment( lightsdata.att )

				if not att then continue end

				pos = att.Pos
			else
				if not isvector( lightsdata.pos ) then self:InitializeLights( base ) break end

				pos = base:LocalToWorld( lightsdata.pos )
			end

			local visible = util.PixelVisible( pos, 2, lightsdata.PixVis )

			if not visible then continue end

			if visible <= 0.1 then continue end

			if isstring( lightsdata.mat ) then self:InitializeLights( base ) break end

			render.SetMaterial( lightsdata.mat )
			render.DrawSprite( pos, lightsdata.width, lightsdata.height , Color(lightsdata.colorR,lightsdata.colorG,lightsdata.colorB,lightsdata.colorA*mul*visible^2) )
		end
	end
end

function ENT:Think()
	local base = self:GetBase()

	if not IsValid( base ) or not self.Enabled then
		self:SetNextClientThink( CurTime() + 1 )

		return true
	end

	self:CalcTypeActivators( base )
	self:LightsThink( base )
end

function ENT:OnRemove()
	self:ClearProjectedTextures()
	self:ResetSubMaterials()
end

function ENT:Draw()
end

function ENT:DrawTranslucent()
end
