
ENT.Base = "lvs_base_starfighter"

ENT.PrintName = "N1 Starfighter"
ENT.Author = "Luna"
ENT.Information = "Starfighter of the Royal Naboo Security Force"
ENT.Category = "[LVS] - Star Wars"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/naboostarfighter.mdl"

ENT.AITEAM = 2

ENT.MaxVelocity = 3000
ENT.MaxThrust = 3000

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxHealth = 450
ENT.MaxShield = 400

function ENT:InitWeapons()
end

ENT.FlyByAdvance = 0.5
ENT.FlyBySound = "lvs/vehicles/bf109/flyby.wav" 
ENT.DeathSound = "lvs/vehicles/generic/crash.wav"
