simfphys = istable( simfphys ) and simfphys or {}

AddCSLuaFile("simfphys/init.lua")
include("simfphys/init.lua")

if CLIENT then return end

resource.AddWorkshop("771487490")
