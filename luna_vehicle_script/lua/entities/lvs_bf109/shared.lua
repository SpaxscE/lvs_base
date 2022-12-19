
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

ENT.WEAPONS = {
	[1] = {
		Icon = Material("lvs_weapons/hmg.png"),
		Ammo = 100,
		Delay = 0.25,
		HeatRate = 0.05,
		Attack = function( ent ) end,
		StartAttack = function( ent ) PrintChat("start 1") end,
		FinishAttack = function( ent ) PrintChat("stop 1") end,
		OnSelect = function( ent ) end,
		OnDeselect = function( ent ) end,
		OnThink = function( ent, active ) end,
	},
	[2] = {
		Icon = Material("lvs_weapons/mg.png"),
		Ammo = 600,
		Delay = 0.1,
		HeatRate = 0.001,
		StartAttack = function( ent ) PrintChat("start 2") end,
		FinishAttack = function( ent ) PrintChat("stop 2")  end,
		Attack = function( ent ) end,
		OnSelect = function( ent ) end,
		OnDeselect = function( ent ) end,
		OnThink = function( ent, active ) end,
	}
}

ENT.EngineSounds = {
	{
		sound = "^lvs/vehicles/bf109/dist.wav",
		sound_int = "",
		Pitch = 80,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 40,
		FadeIn = 0.35,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
		VolumeMin = 0,
		VolumeMax = 1,
		SoundLevel = 110,
	},
	{
		sound = "lvs/vehicles/bf109/engine_compressor.wav",
		sound_int = "",
		Pitch = 50,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 60,
		FadeIn = 0.35,
		FadeOut = 1,
		FadeSpeed = 5,
		UseDoppler = true,
		VolumeMin = 0,
		VolumeMax = 0.25,
		SoundLevel = 120,
	},
	{
		sound = "lvs/vehicles/bf109/engine_low.wav",
		Pitch = 80,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 300,
		FadeIn = 0,
		FadeOut = 0.15,
		FadeSpeed = 1.5,
		UseDoppler = false,
	},
	{
		sound = "lvs/vehicles/bf109/engine_mid.wav",
		Pitch = 80,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 80,
		FadeIn = 0.15,
		FadeOut = 0.35,
		FadeSpeed = 1.5,
		UseDoppler = true,
	},
	{
		sound = "lvs/vehicles/bf109/engine_high.wav",
		sound_int = "lvs/vehicles/bf109/engine_high_int.wav",
		Pitch = 50,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 60,
		FadeIn = 0.35,
		FadeOut = 1,
		FadeSpeed = 1,
		UseDoppler = true,
	},
}
