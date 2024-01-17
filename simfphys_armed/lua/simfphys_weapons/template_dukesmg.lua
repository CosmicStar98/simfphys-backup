-- this script is called SEVERSIDE ONLY.

function simfphys.weapon:ValidClasses()
	
	local classes = {
		--"sim_fphys_dukes",   -- uncomment this to add weapons to the dukes
	}
	
	return classes
end

function simfphys.weapon:Initialize( vehicle )
	vehicle.ForceTransmission = 1   -- Force automatic transmission
end

function simfphys.weapon:Think( vehicle )
	local ply = vehicle:GetDriver()
	
	if not IsValid( ply ) then return end
	
	local fire = ply:KeyDown( IN_ATTACK )
	local fire2 = ply:KeyDown( IN_ATTACK2 )
	
	
	local AimDirToForwardDir = math.deg( math.acos( math.Clamp( vehicle.Forward:Dot( ply:EyeAngles():Forward() ) ,-1,1) ) )
	
	if AimDirToForwardDir > 30 then return end  -- if we are aiming sideways or back (angle greater than 30° relative to forward direction of the car) dont allow weapons
	
	if fire then
		self:PrimaryAttack( vehicle, ply )
	end
	
	if fire2 then
		self:SecondaryAttack( vehicle, ply )
	end
end

function simfphys.weapon:FireBullet( ply, vehicle, shootDirection, shootOrigin )

	local bullet = {}
		bullet.Num 			= 1
		bullet.Src 			= shootOrigin
		bullet.Dir 			= shootDirection
		bullet.Spread 		= Vector(0.06,0.06,0)
		bullet.Tracer		= 1
		bullet.TracerName	= "simfphys_tracer"
		bullet.Force		= 4
		bullet.Damage		= 25
		bullet.HullSize		= 10
		bullet.Attacker 	= ply
	vehicle:FireBullets( bullet )
	
	vehicle:EmitSound("Weapon_SMG1.NPC_Single")
end

function simfphys.weapon:FireMortar( ply, vehicle, shootDirection, shootOrigin )
	vehicle:EmitSound("Weapon_Mortar.Single")
	
	local projectile = {}
		projectile.filter = vehicle.VehicleData["filter"]
		projectile.shootOrigin = shootOrigin
		projectile.shootDirection = shootDirection
		projectile.attacker = ply
		projectile.attackingent = vehicle
		projectile.Damage = 1000
		projectile.Force = 6000
		projectile.Size = 10
		projectile.BlastRadius = 200
		projectile.BlastDamage = 50
		projectile.BlastEffect = "simfphys_tankweapon_explosion_small"
	simfphys.FirePhysProjectile( projectile )
end

function simfphys.weapon:PrimaryAttack( vehicle, ply )
	if not self:CanPrimaryAttack( vehicle ) then return end
	
	local shootDirection = ply:EyeAngles():Forward()

	self:FireBullet( ply, vehicle, shootDirection, vehicle:LocalToWorld( Vector(108.53,-25.34,-2.48) ) )
	self:FireBullet( ply, vehicle, shootDirection, vehicle:LocalToWorld( Vector(108.53,25.34,-2.48) ) )
	
	
	self:SetNextPrimaryFire( vehicle, CurTime() + 0.1 )
end

function simfphys.weapon:SecondaryAttack( vehicle, ply )
	
	if not self:CanSecondaryAttack( vehicle ) then return end
	
	local shootDirection = ply:EyeAngles():Forward()
	
	self:FireMortar( ply, vehicle, shootDirection, vehicle:LocalToWorld( Vector(108.53,0,-2.48) ) )
	
	self:SetNextSecondaryFire( vehicle, CurTime() + 1 )
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
