-- this script is called SEVERSIDE ONLY.

function simfphys.weapon:ValidClasses()
	
	local classes = {
		--"sim_fphys_jeep",
		"sim_fphys_testvehicle",  -- all classes listed in this table will be using this weapon
		"my_vehicle",  -- you can add as many vehicles you want
	}
	
	return classes
end

function simfphys.weapon:Initialize( vehicle ) -- "vehicle" is the "gmod_sent_vehicle_fphysics_base" entity. 
	-- this function is called once the weapon is initialized
end

function simfphys.weapon:Think( vehicle )
	-- this function is called on tick
	
	local ply = vehicle:GetDriver()
	
	if not IsValid( ply ) then return end
	
	local fire = ply:KeyDown( IN_ATTACK )
	local fire2 = ply:KeyDown( IN_ATTACK2 )
	
	if fire then
		self:PrimaryAttack( vehicle, ply )
	end
	
	if fire2 then
		self:SecondaryAttack( vehicle, ply )
	end
end


function simfphys.weapon:PrimaryAttack( vehicle, ply )
	if not self:CanPrimaryAttack( vehicle ) then return end
	
	--primary attack code here
	print("primary fire")
	vehicle:EmitSound("Weapon_SMG1.NPC_Single")
	
	self:SetNextPrimaryFire( vehicle, CurTime() + 0.1 )
end

function simfphys.weapon:SecondaryAttack( vehicle, ply )
	
	if not self:CanSecondaryAttack( vehicle ) then return end
	
	--secondary attack code here
	print("secondary fire")
	vehicle:EmitSound("Weapon_Mortar.Single")
	
	self:SetNextSecondaryFire( vehicle, CurTime() + 0.3 )
end

function simfphys.weapon:CanPrimaryAttack( vehicle )
	vehicle.NextShoot = vehicle.NextShoot or 0
	return vehicle.NextShoot < CurTime()
end

function simfphys.weapon:SetNextPrimaryFire( vehicle, time )
	vehicle.NextShoot = time
end

function simfphys.weapon:CanSecondaryAttack( vehicle )
	vehicle.NextShoot2 = vehicle.NextShoot2 or 0
	return vehicle.NextShoot2 < CurTime()
end

function simfphys.weapon:SetNextSecondaryFire( vehicle, time )
	vehicle.NextShoot2 = time
end


--[[
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
 some handy variables and functions:

vehicle:IsInitialized()  -- checks if the vehicle is fully spawned



------------------------------------------
-- driver / driverseat
local pod = vehicle:GetDriverSeat()  -- gets the driver seat
local ply = pod:GetDriver()  -- gets the driver
------------------------------------------



------------------------------------------
-- passenger / passengerseat
local pod = vehicle.pSeat[1] -- gets the first passenger seat
local ply = pod:GetDriver()  -- gets the driver of the passenger seat

-- but make sure the vehicle you call it on actually has passenger seats or it will throw an error. Add an safety check that prevents this:

if not istable( vehicle.pSeat ) then return end  -- will bail out of the script incase there are no passenger seats
local pod = vehicle.pSeat[1]
local ply = pod:GetDriver()
------------------------------------------


------------------------------------------
-- crosshair
simfphys.RegisterCrosshair( <pod_entity> , { Attachment = <string name attachment>, Direction = <vector direction> } )  -- registers an crosshair to the pod_entity. 

alternative (if you have two barrels and need the center of them):

local data = {}
data.Attachment = "minigun_barell_left" -- used for the direction
data.Direction = Vector(1,0,0)
data.Attach_Start_Left = "minigun_barell_right"   -- used as postion 1
data.Attach_Start_Right = "minigun_barell_left"  -- used as postion 2
simfphys.RegisterCrosshair( vehicle:GetDriverSeat(), data )
------------------------------------------


------------------------------------------
-- camera
simfphys.RegisterCamera( <pod_entity>, <vector position firstperson>, <vector position thirdperson> )
------------------------------------------



there are more lua functions wich can be found on simfphys.com

]]