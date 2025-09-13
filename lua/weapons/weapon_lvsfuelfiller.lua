AddCSLuaFile()

SWEP.Category				= "[LVS]"
SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false
SWEP.ViewModel			= "models/weapons/c_fuelfillerlvs.mdl"
SWEP.WorldModel			= "models/props_equipment/gas_pump_p13.mdl"
SWEP.UseHands				= true

SWEP.HoldType				= "slam"

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip		= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo		= "none"

SWEP.RangeToCap = 24
SWEP.HitDistance = 128

function SWEP:SetupDataTables()
	self:NetworkVar( "Int",0, "FuelType" )
	self:NetworkVar( "Entity",0, "CallbackTarget" )
end

function SWEP:GetTank( entity )
	if entity.lvsGasStationRefillMe then
		return entity
	end

	if not entity.LVS or not entity.GetFuelTank then return NULL end

	return entity:GetFuelTank()
end

function SWEP:GetCap( entity )
	if entity.lvsGasStationRefillMe then
		return entity
	end

	if not entity.LVS or not entity.GetFuelTank then return NULL end

	local FuelTank = entity:GetFuelTank()

	if not IsValid( FuelTank ) then return NULL end

	return FuelTank:GetDoorHandler()
end

if CLIENT then
	SWEP.PrintName		= "Fuel Filler Pistol"
	SWEP.Slot				= 1
	SWEP.SlotPos			= 3

	SWEP.DrawWeaponInfoBox 	= false

	local FrameMat = Material( "lvs/3d2dmats/frame.png" )
	local RefuelMat = Material( "lvs/3d2dmats/refuel.png" )

	function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
	end

	function SWEP:DrawWorldModel()
		local ply = self:GetOwner()

		if not IsValid( ply ) then return end

		local id = ply:LookupAttachment("anim_attachment_rh")
		local attachment = ply:GetAttachment( id )

		if not attachment then return end

		local pos = attachment.Pos + attachment.Ang:Forward() * 6 + attachment.Ang:Right() * -1.5 + attachment.Ang:Up() * 2.2
		local ang = attachment.Ang
		ang:RotateAroundAxis(attachment.Ang:Up(), 20)
		ang:RotateAroundAxis(attachment.Ang:Right(), -30)
		ang:RotateAroundAxis(attachment.Ang:Forward(), 0)

		self:SetRenderOrigin( pos )
		self:SetRenderAngles( ang )

		self:DrawModel()	
	end

	local function DrawText( pos, text, col )
		local data2D = pos:ToScreen()

		if not data2D.visible then return end

		local font = "TargetIDSmall"

		local x = data2D.x
		local y = data2D.y
		draw.SimpleText( text, font, x + 1, y + 1, Color( 0, 0, 0, 120 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( text, font, x + 2, y + 2, Color( 0, 0, 0, 50 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( text, font, x, y, col or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local function DrawIcon( pos, fueltype, fuelamount, visible )
		local data2D = pos:ToScreen()

		if not data2D.visible then return end

		local data = LVS.FUELTYPES[ fueltype ]

		if not istable( data ) then return end

		local x = data2D.x
		local y = data2D.y

		local scale = visible and 2 or 1

		if visible then
			local IconColor = Color( data.color.x, data.color.y, data.color.z, 200 )
			local ScissorScale = 50
			local offset = ScissorScale * scale * fuelamount
			local offset2 = ScissorScale * scale * (1 - fuelamount)

			surface.SetDrawColor( Color(0,0,0,200) )
			render.SetScissorRect(  x - 40 * scale, y - ScissorScale * 0.5 * scale - offset, x + 40 * scale, y + ScissorScale * 0.5 * scale - offset, true )
			surface.SetMaterial( FrameMat )
			surface.DrawTexturedRect( x - 25 * scale, y - 25 * scale, 50 * scale, 50 * scale )
			surface.SetMaterial( RefuelMat )
			surface.DrawTexturedRect( x - 40 * scale, y - 40 * scale, 80 * scale, 80 * scale )

			surface.SetDrawColor( IconColor )
			render.SetScissorRect(  x - 40 * scale, y - ScissorScale * 0.5 * scale + offset2, x + 40 * scale, y + ScissorScale * 0.5 * scale + offset2, true )
			surface.SetMaterial( FrameMat )
			surface.DrawTexturedRect( x - 25 * scale, y - 25 * scale, 50 * scale, 50 * scale )
			surface.SetMaterial( RefuelMat )
			surface.DrawTexturedRect( x - 40 * scale, y - 40 * scale, 80 * scale, 80 * scale )
			render.SetScissorRect( 0,0,0,0,false )

			draw.SimpleText( data.name, "LVS_FONT", x, y - 40 * scale, IconColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		else
			local IconColor = Color( data.color.x, data.color.y, data.color.z, 100 )

			surface.SetDrawColor( IconColor )

			surface.SetMaterial( FrameMat )
			surface.DrawTexturedRect( x - 25 * scale, y - 25 * scale, 50 * scale, 50 * scale )
			surface.SetMaterial( RefuelMat )
			surface.DrawTexturedRect( x - 40 * scale, y - 40 * scale, 80 * scale, 80 * scale )
		end
	end

	function SWEP:DrawHUD()
		local ply = self:GetOwner()

		if not IsValid( ply ) then return end

		local startpos = ply:GetShootPos()
		local endpos = startpos + ply:GetAimVector() * self.HitDistance

		local trace = util.TraceLine( {
			start = startpos ,
			endpos = endpos,
			filter = ply,
			mask = MASK_SHOT_HULL
		} )

		if not IsValid( trace.Entity ) then
			trace = util.TraceHull( {
				start = startpos ,
				endpos = endpos,
				filter = ply,
				mins = Vector( -10, -10, -8 ),
				maxs = Vector( 10, 10, 8 ),
				mask = MASK_SHOT_HULL
			} )
		end

		local FuelTank = self:GetTank( trace.Entity )
		local FuelCap = self:GetCap( trace.Entity )

		if not IsValid( FuelTank ) then return end

		local pos = trace.HitPos
		local fuelamount = FuelTank:GetFuel()
		local fueltype = FuelTank:GetFuelType()

		if fueltype ~= self:GetFuelType() then

			local FuelName = LVS.FUELTYPES[ fueltype ].name or ""

			DrawText( trace.HitPos, "Incorrect Fuel Type. Requires: "..FuelName, Color(255,0,0,255) )

			return
		end

		if not IsValid( FuelCap ) then
			DrawIcon( pos, fueltype, fuelamount, true )
			DrawText( pos, math.Round(fuelamount * 100,1).."%", Color(0,255,0,255) )

			return
		end

		if FuelCap:IsOpen() then
			if (trace.HitPos - FuelCap:GetPos()):Length() > self.RangeToCap then
				DrawIcon( FuelCap:GetPos(), fueltype, fuelamount, false )
				DrawText( pos, "Aim at Fuel Cap!", Color(255,255,0,255) )
			else
				DrawIcon( FuelCap:GetPos(), fueltype, fuelamount, true )
				DrawText( pos, math.Round(fuelamount * 100,1).."%", Color(0,255,0,255) )
			end

			return
		end

		local Key = input.LookupBinding( "+use" )

		if not isstring( Key ) then Key = "[+use is not bound to a key]" end

		local pos = FuelCap:GetPos()

		DrawIcon( pos, fueltype, fuelamount, false )
		DrawText( pos, "Press "..Key.." to Open", Color(255,255,0,255) )
	end
end

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:PrimaryAttack()

	self:SetNextPrimaryFire( CurTime() + 0.5 )

	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	local startpos = ply:GetShootPos()
	local endpos = startpos + ply:GetAimVector() * self.HitDistance

	local trace = util.TraceLine( {
		start = startpos ,
		endpos = endpos,
		filter = ply,
		mask = MASK_SHOT_HULL
	} )

	if not IsValid( trace.Entity ) then
		trace = util.TraceHull( {
			start = startpos ,
			endpos = endpos,
			filter = ply,
			mins = Vector( -10, -10, -8 ),
			maxs = Vector( 10, 10, 8 ),
			mask = MASK_SHOT_HULL
		} )
	end

	self:Refuel( trace )
end

function SWEP:SecondaryAttack()
end

function SWEP:Refuel( trace )
	local entity = trace.Entity

	if CLIENT or not IsValid( entity ) then return end

	local FuelCap = self:GetCap( entity )
	local FuelTank = self:GetTank( entity )

	if not IsValid( FuelTank ) then return end

	if FuelTank:GetFuelType() ~= self:GetFuelType() then return end

	if IsValid( FuelCap ) then
		if not FuelCap:IsOpen() then return end

		if (trace.HitPos - FuelCap:GetPos()):Length() > self.RangeToCap then return end
	end

	if FuelTank:GetFuel() == 1 then return end

	local Target = self:GetCallbackTarget()

	if FuelTank == Target then return end

	if IsValid( Target ) and Target.TakeFuel then
		local Size = FuelTank:GetSize()
		local Cur = FuelTank:GetFuel()
		local Need = 1 - Cur
		local Add = Target:TakeFuel( Need * Size )

		if Add > 0 then
			FuelTank:SetFuel( Cur + Add / Size )
			entity:OnRefueled()
		end

		return
	end

	FuelTank:SetFuel( math.min( FuelTank:GetFuel() + (entity.lvsGasStationFillSpeed or 0.05), 1 ) )
	entity:OnRefueled()
end