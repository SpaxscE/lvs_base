AddCSLuaFile()

ENT.Base = "lvs_fortification"

ENT.DamageIgnoreForce = 3000

if CLIENT then return end

ENT.DamageIgnoreType = DMG_SNIPER + DMG_BULLET + DMG_CLUB + DMG_DROWN + DMG_PARALYZE + DMG_NERVEGAS + DMG_POISON + DMG_BURN

function ENT:PhysicsCollide( data, physobj )
end