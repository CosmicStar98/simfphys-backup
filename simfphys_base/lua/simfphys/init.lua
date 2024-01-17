if SERVER then
	AddCSLuaFile("simfphys/client/fonts.lua")
	AddCSLuaFile("simfphys/client/tab.lua")
	AddCSLuaFile("simfphys/client/hud.lua")
	AddCSLuaFile("simfphys/client/seatcontrols.lua")
	AddCSLuaFile("simfphys/client/lighting.lua")
	AddCSLuaFile("simfphys/client/damage.lua")
	AddCSLuaFile("simfphys/client/poseparameter.lua")
	
	AddCSLuaFile("simfphys/anim.lua")
	AddCSLuaFile("simfphys/base_functions.lua")
	AddCSLuaFile("simfphys/base_lights.lua")
	AddCSLuaFile("simfphys/base_vehicles.lua")
	AddCSLuaFile("simfphys/view.lua")
	
	include("simfphys/base_functions.lua")
	include("simfphys/server/exitpoints.lua")
	include("simfphys/server/spawner.lua")
	include("simfphys/server/seatcontrols.lua")
	include("simfphys/server/poseparameter.lua")
	include("simfphys/server/joystick.lua")
	include("simfphys/server/damage.lua")
end
	
if CLIENT then
	killicon.Add( "gmod_sent_vehicle_fphysics_base", "HUD/killicons/simfphys_car", Color( 255, 80, 0, 255 ) )

	include("simfphys/base_functions.lua")
	include("simfphys/client/fonts.lua")
	include("simfphys/client/tab.lua")
	include("simfphys/client/hud.lua")
	include("simfphys/client/seatcontrols.lua")
	include("simfphys/client/lighting.lua")
	include("simfphys/client/damage.lua")
	include("simfphys/client/poseparameter.lua")
end

include("simfphys/anim.lua")
include("simfphys/base_lights.lua")
include("simfphys/base_vehicles.lua")
include("simfphys/view.lua")
