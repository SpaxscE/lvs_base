
ENT.Base = "lvs_base_fighterplane"

ENT.PrintName = "BF 109"
ENT.Author = "Luna"
ENT.Information = "German World War 2 Fighterplane"
ENT.Category = "[LVS]"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/blu/bf109.mdl"

ENT.AITEAM = 1

ENT.MaxVelocity = 2500
ENT.MaxPerfVelocity = 1800
ENT.MaxThrust = 25

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxSlipAnglePitch = 20
ENT.MaxSlipAngleYaw = 10

ENT.MaxHealth = 1000

sound.Add( {
	name = "LVS.BF109.Engine.Low",
	channel = CHAN_STATIC,
	volume = 1,
	level = 100,
	sound = "lvs/vehicles/bf109/engine_low.wav"
} )

sound.Add( {
	name = "LVS.BF109.Engine.High",
	channel = CHAN_STATIC,
	volume = 1,
	level = 100,
	sound = "lvs/vehicles/bf109/engine_high.wav"
} )

sound.Add( {
	name = "LVS.BF109.Engine.Dist",
	channel = CHAN_STATIC,
	volume = 1,
	level = 125,
	sound = "^lvs/vehicles/bf109/dist.wav"
} )

sound.Add( {
	name = "LVS.BF109.FlyBy",
	channel = CHAN_STATIC,
	level = 100,
	sound = "lvs/vehicles/bf109/flyby.wav"
} )

sound.Add( {
	name = "LFS_BF109_RPM1",
	channel = CHAN_STATIC,
	level = 75,
	sound = "^lfs/bf109/rpm_1.wav"
} )

sound.Add( {
	name = "LFS_BF109_RPM2",
	channel = CHAN_STATIC,
	level = 75,
	sound = "^lfs/bf109/rpm_2.wav"
} )

sound.Add( {
	name = "LFS_BF109_RPM3",
	channel = CHAN_STATIC,
	level = 75,
	sound = "^lfs/bf109/rpm_3.wav"
} )

sound.Add( {
	name = "LFS_BF109_RPM4",
	level = 75,
	sound = "^lfs/bf109/rpm_4.wav"
} )
