
function ENT:UpdateHydraulics( ply, cmd )
	if not self._HydraulicControlers then return end

	local all = ply:lvsKeyDown( "CAR_HYDRAULIC" )

	if self._HydToggleAll ~= all then
		self._HydToggleAll = all

		if all then
			self._HydToggleHeight = not self._HydToggleHeight
		end
	end

	local HeightAll = self._HydToggleHeight and 1 or 0
	local Invert = self._HydToggleHeight and -1 or 1

	local FRONT = ply:lvsKeyDown( "CAR_HYDRAULIC_FRONT" )
	local REAR = ply:lvsKeyDown( "CAR_HYDRAULIC_REAR" )
	local LEFT = ply:lvsKeyDown( "CAR_HYDRAULIC_LEFT" )
	local RIGHT = ply:lvsKeyDown( "CAR_HYDRAULIC_RIGHT" )

	local FL = (FRONT or LEFT) and Invert or 0
	local FR = (FRONT or RIGHT) and Invert or 0
	local RL = (REAR or LEFT) and Invert or 0
	local RR = (REAR or RIGHT) and Invert or 0

	local HeightType = {
		[""] = HeightAll,
		["fl"] = HeightAll + FL,
		["fr"] = HeightAll + FR,
		["rl"] = HeightAll + RL,
		["rr"] = HeightAll + RR,
	}

	local Rate = FrameTime() * 10

	for _, control in ipairs( self._HydraulicControlers ) do
		local curHeight = control:GetHeight()
		local desHeight = HeightType[ control:GetType() ]

		if curHeight == desHeight then control:OnFinish() continue end

		control:SetHeight( curHeight + math.Clamp(desHeight - curHeight,-Rate,Rate) )
	end
end

local HYD = {}
HYD.__index = HYD
function HYD:Initialize()
end
function HYD:GetHeight()
	if not IsValid( self._WheelEntity ) then return 0 end

	return self._WheelEntity:GetSuspensionHeight()
end
function HYD:SetHeight( new )
	if not IsValid( self._WheelEntity ) then return end

	self:OnStart()

	self._WheelEntity:SetSuspensionHeight( new )
end
function HYD:OnStart()
	if self.IsUpdatingHeight then return end

	self.IsUpdatingHeight = true

	if not IsValid( self._BaseEntity ) then return end

	if self:GetHeight() > 0.5 then
		self._BaseEntity:EmitSound("lvs/vehicles/generic/vehicle_hydraulic_down.ogg", 75, 100, 0.5, CHAN_WEAPON)
	else
		self._BaseEntity:EmitSound("lvs/vehicles/generic/vehicle_hydraulic_up.ogg", 75, 100, 0.5, CHAN_WEAPON)
	end
end
function HYD:OnFinish()
	if not self.IsUpdatingHeight then return end

	self.IsUpdatingHeight = nil

	if not IsValid( self._WheelEntity ) then return end

	self._WheelEntity:EmitSound("lvs/vehicles/generic/vehicle_hydraulic_collide"..math.random(1,2)..".ogg", 75, 100, 0.5)
end
function HYD:GetType()
	return self._WheelType
end

function ENT:CreateHydraulicControler( type, wheel )
	if not istable( self._HydraulicControlers ) then
		self._HydraulicControlers = {}
	end

	local controller = {}

	setmetatable( controller, HYD )

	controller._BaseEntity = self
	controller._WheelEntity = wheel
	controller._WheelType = type or ""
	controller:Initialize()

	table.insert( self._HydraulicControlers, controller )
end
