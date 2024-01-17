local tiger_susdata = {}
for i = 1,8 do
	tiger_susdata[i] = { 
		attachment = "vehicle_suspension_l_"..i,
		poseparameter = "suspension_left_"..i,
	}
	
	local ir = i + 8
	tiger_susdata[ir] = { 
		attachment = "vehicle_suspension_r_"..i,
		poseparameter = "suspension_right_"..i,
	}
end

local function mg_fire(ply,vehicle,shootOrigin,shootDirection)
	vehicle:EmitSound("tiger_fire_mg_new")
	
	local projectile = {}
		projectile.filter = vehicle.VehicleData["filter"]
		projectile.shootOrigin = shootOrigin
		projectile.shootDirection = shootDirection
		projectile.attacker = ply
		projectile.Tracer	= 1
		projectile.Spread = Vector(0.015,0.015,0.015)
		projectile.HullSize = 5
		projectile.attackingent = vehicle
		projectile.Damage = 20
		projectile.Force = 12
	simfphys.FireHitScan( projectile )
end

local function cannon_fire(ply,vehicle,shootOrigin,shootDirection)
	vehicle:EmitSound("tiger_fire")
	vehicle:EmitSound("tiger_reload")
	
	local effectdata = EffectData()
		effectdata:SetEntity( vehicle )
	util.Effect( "simfphys_tiger_muzzle", effectdata )
	
	vehicle:GetPhysicsObject():ApplyForceOffset( -shootDirection * 400000, shootOrigin ) 
	
	local projectile = {}
		projectile.filter = vehicle.VehicleData["filter"]
		projectile.shootOrigin = shootOrigin
		projectile.shootDirection = shootDirection
		projectile.attacker = ply
		projectile.attackingent = vehicle
		projectile.Damage = 3000
		projectile.Force = 6000
		projectile.Size = 20
		projectile.DeflectAng = 20
		projectile.BlastRadius = 300
		projectile.BlastDamage = 500
		projectile.BlastEffect = "simfphys_tankweapon_explosion"
	
	simfphys.FirePhysProjectile( projectile )
end

function simfphys.weapon:ValidClasses()
	
	local classes = {
		"sim_fphys_tank"
	}
	
	return classes
end

function simfphys.weapon:Initialize( vehicle )
	vehicle:SetNWBool( "SpecialCam_Loader", true )
	vehicle:SetNWFloat( "SpecialCam_LoaderTime", 5 )
	
	simfphys.RegisterCrosshair( vehicle:GetDriverSeat(), { Direction = Vector(0,0,1), Type = 2 } )
	simfphys.RegisterCamera( vehicle:GetDriverSeat(), Vector(20,0,-130), Vector(0,60,75), true, "muzzle" )
	
	if not istable( vehicle.PassengerSeats ) or not istable( vehicle.pSeat ) then return end

	simfphys.RegisterCrosshair( vehicle.pSeat[1] , { Attachment = "muzzle_machinegun", Type = 1 } )
	simfphys.RegisterCamera( vehicle.pSeat[1], Vector(35,-105,-15), Vector(35,-105,25), true )
	
	simfphys.RegisterCamera( vehicle.pSeat[2], Vector(0,0,25), Vector(0,0,25), false )
	simfphys.RegisterCamera( vehicle.pSeat[3], Vector(0,0,25), Vector(0,0,25), false )
	
	timer.Simple( 1, function()
		if not IsValid( vehicle ) then return end
		if not vehicle.VehicleData["filter"] then print("[simfphys Armed Vehicle Pack] ERROR:TRACE FILTER IS INVALID. PLEASE UPDATE SIMFPHYS BASE") return end
		
		vehicle.WheelOnGround = function( ent )
			ent.FrontWheelPowered = ent:GetPowerDistribution() ~= 1
			ent.RearWheelPowered = ent:GetPowerDistribution() ~= -1
			
			for i = 1, table.Count( ent.Wheels ) do
				local Wheel = ent.Wheels[i]		
				if IsValid( Wheel ) then
					local dmgMul = Wheel:GetDamaged() and 0.5 or 1
					local surfacemul = simfphys.TractionData[Wheel:GetSurfaceMaterial():lower()]
					
					ent.VehicleData[ "SurfaceMul_" .. i ] = (surfacemul and math.max(surfacemul,0.001) or 1) * dmgMul
					
					local WheelPos = ent:LogicWheelPos( i )
					
					local WheelRadius = WheelPos.IsFrontWheel and ent.FrontWheelRadius or ent.RearWheelRadius
					local startpos = Wheel:GetPos()
					local dir = -ent.Up
					local len = WheelRadius + math.Clamp(-ent.Vel.z / 50,2.5,6)
					local HullSize = Vector(WheelRadius,WheelRadius,0)
					local tr = util.TraceHull( {
						start = startpos,
						endpos = startpos + dir * len,
						maxs = HullSize,
						mins = -HullSize,
						filter = ent.VehicleData["filter"]
					} )
					
					local onground = self:IsOnGround( vehicle ) and 1 or 0
					Wheel:SetOnGround( onground )
					ent.VehicleData[ "onGround_" .. i ] = onground
					
					if tr.Hit then
						Wheel:SetSpeed( Wheel.FX )
						Wheel:SetSkidSound( Wheel.skid )
						Wheel:SetSurfaceMaterial( util.GetSurfacePropName( tr.SurfaceProps ) )
					end
				end
			end
			
			local FrontOnGround = math.max(ent.VehicleData[ "onGround_1" ],ent.VehicleData[ "onGround_2" ])
			local RearOnGround = math.max(ent.VehicleData[ "onGround_3" ],ent.VehicleData[ "onGround_4" ])
			
			ent.DriveWheelsOnGround = math.max(ent.FrontWheelPowered and FrontOnGround or 0,ent.RearWheelPowered and RearOnGround or 0)
		end
	end)
end

function simfphys.weapon:ControlTurret( vehicle, deltapos )
	local pod = vehicle:GetDriverSeat()
	
	if not IsValid( pod ) then return end
	
	local ply = pod:GetDriver()
	
	if not IsValid( ply ) then return end
	
	local safemode = ply:KeyDown( IN_WALK )

	if vehicle.ButtonSafeMode ~= safemode then
		vehicle.ButtonSafeMode = safemode
		
		if safemode then
			vehicle:SetNWBool( "TurretSafeMode", not vehicle:GetNWBool( "TurretSafeMode", true ) )
		end
	end
	
	if vehicle:GetNWBool( "TurretSafeMode", true ) then return end
	
	local ID = vehicle:LookupAttachment( "muzzle" )
	local Attachment = vehicle:GetAttachment( ID )
	
	self:AimCannon( ply, vehicle, pod, Attachment )
	
	local shootOrigin = Attachment.Pos + deltapos * engine.TickInterval()
	
	local fire = ply:KeyDown( IN_ATTACK )
	local fire2 = ply:KeyDown( IN_ATTACK2 )

	if fire then
		self:PrimaryAttack( vehicle, ply, shootOrigin, Attachment )
	end
	
	local Rate = FrameTime() / 8
	vehicle.smTmpHMG = vehicle.smTmpHMG and vehicle.smTmpHMG + math.Clamp((fire2 and 1 or 0) - vehicle.smTmpHMG,-Rate * 4,Rate) or 0
	
	if fire2 then
		self:SecondaryAttack( vehicle, ply, shootOrigin - Attachment.Ang:Up() * 155 - Attachment.Ang:Forward() * 20, Attachment.Ang )
	end
end

function simfphys.weapon:ControlMachinegun( vehicle, deltapos )

	if not istable( vehicle.PassengerSeats ) or not istable( vehicle.pSeat ) then return end
	
	local pod = vehicle.pSeat[1]
	
	if not IsValid( pod ) then return end
	
	local ply = pod:GetDriver()
	
	if not IsValid( ply ) then return end
	
	self:AimMachinegun( ply, vehicle, pod )
	
	local ID = vehicle:LookupAttachment( "muzzle_machinegun" )
	local Attachment = vehicle:GetAttachment( ID )

	local shootOrigin = Attachment.Pos + deltapos * engine.TickInterval()
	
	local fire = ply:KeyDown( IN_ATTACK )

	local Rate = FrameTime() / 8
	vehicle.smTmpMG = vehicle.smTmpMG and vehicle.smTmpMG + math.Clamp((fire and 1 or 0) - vehicle.smTmpMG,-Rate * 4,Rate) or 0
	
	if fire then
		self:TertiaryAttack( vehicle, ply, shootOrigin, Attachment, ID )
	end
end

function simfphys.weapon:GetForwardSpeed( vehicle )
	return vehicle.ForwardSpeed
end

function simfphys.weapon:IsOnGround( vehicle )
	return (vehicle.susOnGround == true)
end

function simfphys.weapon:ModPhysics( vehicle, wheelslocked )
	if wheelslocked and self:IsOnGround( vehicle ) then
		local phys = vehicle:GetPhysicsObject()
		phys:ApplyForceCenter( -vehicle:GetVelocity() * phys:GetMass() * 0.04 )
	end
end

function simfphys.weapon:ControlTrackSounds( vehicle, wheelslocked ) 
	local speed = math.abs( self:GetForwardSpeed( vehicle ) )
	local fastenuf = speed > 20 and not wheelslocked and self:IsOnGround( vehicle )
	
	if fastenuf ~= vehicle.fastenuf then
		vehicle.fastenuf = fastenuf
		
		if fastenuf then
			vehicle.track_snd = CreateSound( vehicle, "simulated_vehicles/tiger/tiger_tracks.wav" )
			vehicle.track_snd:PlayEx(0,0)
			vehicle:CallOnRemove( "stopmesounds", function( vehicle )
				if vehicle.track_snd then
					vehicle.track_snd:Stop()
				end
			end)
		else
			if vehicle.track_snd then
				vehicle.track_snd:Stop()
				vehicle.track_snd = nil
			end
		end
	end
	
	if vehicle.track_snd then
		vehicle.track_snd:ChangePitch( math.Clamp(60 + speed / 80,0,150) ) 
		vehicle.track_snd:ChangeVolume( math.min( math.max(speed - 20,0) / 600,1) ) 
	end
end

function simfphys.weapon:ControlPassengerSeats( vehicle )
	if not vehicle.pSeat then return end
	
	vehicle.sm_pp_yaw = vehicle.sm_pp_yaw and vehicle.sm_pp_yaw or 0
	vehicle.sm_pp_pitch = vehicle.sm_pp_pitch and vehicle.sm_pp_pitch or 0
	
	local Commander = vehicle.pSeat[2]
	if IsValid( Commander ) then
		local ply = Commander:GetDriver()
		local Toggle = false
		if IsValid( ply ) then
			Toggle = ply:KeyDown( IN_JUMP )
		end
		
		if Toggle ~= vehicle.OldToggleC then
			vehicle.OldToggleC = Toggle
			if Toggle then
				vehicle.tg_c_z = not vehicle.tg_c_z
				
				if vehicle.tg_c_z then
					vehicle:EmitSound( "vehicles/atv_ammo_open.wav" )
					simfphys.RegisterCamera( Commander, Vector(0,0,0), Vector(0,0,0), false )
				else
					vehicle:EmitSound( "vehicles/atv_ammo_close.wav" )
					simfphys.RegisterCamera( Commander, Vector(0,0,25), Vector(0,0,25), false )
				end
			end
		end

		local X = math.sin( math.rad( -vehicle.sm_pp_yaw - 50 ) ) * 30
		local Y = math.cos( math.rad( -vehicle.sm_pp_yaw - 50 ) ) * 30
		Commander:SetLocalPos( Vector(X,Y,65 + (vehicle.tg_c_z and 25 or 0)) )
		Commander:SetLocalAngles( Angle(0,vehicle.sm_pp_yaw - 90,0) ) 
	end
	
	local Loader = vehicle.pSeat[3]
	if IsValid( Loader ) then
		local ply = Loader:GetDriver()
		local Toggle = false
		if IsValid( ply ) then
			Toggle = ply:KeyDown( IN_JUMP )
		end
		
		if Toggle ~= vehicle.OldToggleL then
			vehicle.OldToggleL = Toggle
			if Toggle then
				vehicle.tg_l_z = not vehicle.tg_l_z
				
				if vehicle.tg_l_z then
					vehicle:EmitSound( "vehicles/atv_ammo_open.wav" )
					simfphys.RegisterCamera( Loader, Vector(0,0,0), Vector(0,0,0), false )
				else
					vehicle:EmitSound( "vehicles/atv_ammo_close.wav" )
					simfphys.RegisterCamera( Loader, Vector(0,0,25), Vector(0,0,25), false )
				end
			end
		end

		local X = math.sin( math.rad( -vehicle.sm_pp_yaw - 170 ) ) * 28
		local Y = math.cos( math.rad( -vehicle.sm_pp_yaw - 170 ) ) * 28
		Loader:SetLocalPos( Vector(X,Y,60 + (vehicle.tg_l_z and 25 or 0)) )
		Loader:SetLocalAngles( Angle(0,vehicle.sm_pp_yaw - 90,0) ) 
	end
end

function simfphys.weapon:Think( vehicle )
	if not IsValid( vehicle ) or not vehicle:IsInitialized() then return end
	
	vehicle.wOldPos = vehicle.wOldPos or Vector(0,0,0)
	local deltapos = vehicle:GetPos() - vehicle.wOldPos
	vehicle.wOldPos = vehicle:GetPos()
	
	local handbrake = vehicle:GetHandBrakeEnabled()
	
	self:UpdateSuspension( vehicle )
	self:DoWheelSpin( vehicle )
	self:ControlTurret( vehicle, deltapos )
	self:ControlMachinegun( vehicle, deltapos )
	self:ControlTrackSounds( vehicle, handbrake )
	self:ControlPassengerSeats( vehicle )
	self:ModPhysics( vehicle, handbrake )
end

function simfphys.weapon:PrimaryAttack( vehicle, ply, shootOrigin, Attachment )
	if not self:CanPrimaryAttack( vehicle ) then return end
	
	cannon_fire( ply, vehicle, shootOrigin, Attachment.Ang:Up() )
	
	self:SetNextPrimaryFire( vehicle, CurTime() + 5 )
end

function simfphys.weapon:SecondaryAttack( vehicle, ply, shootOrigin, shootDir )
	
	if not self:CanSecondaryAttack( vehicle ) then return end

	mg_fire( ply, vehicle, shootOrigin, (shootDir + Angle(0,0.5,0)):Up() )
	
	self:SetNextSecondaryFire( vehicle, CurTime() + 0.07 + (vehicle.smTmpHMG ^ 5) * 0.08 )
end

function simfphys.weapon:TertiaryAttack( vehicle, ply, shootOrigin, Attachment, ID )
	
	if not self:CanTertiaryAttack( vehicle ) then return end
	
	mg_fire( ply, vehicle, shootOrigin, Attachment.Ang:Forward() )
	
	self:SetNextTertiaryFire( vehicle, CurTime() + 0.07 + (vehicle.smTmpMG ^ 5) * 0.08 )
end

function simfphys.weapon:AimMachinegun( ply, vehicle, pod )	
	if not IsValid( pod ) then return end

	local Aimang = pod:WorldToLocalAngles( ply:EyeAngles() )
	
	local Angles = vehicle:WorldToLocalAngles( Aimang )
	Angles:Normalize()
	
	local TargetPitch = Angles.p
	local TargetYaw = Angles.y
	
	vehicle:SetPoseParameter("machinegun_yaw", -TargetYaw )
	vehicle:SetPoseParameter("machinegun_pitch", TargetPitch )
end

function simfphys.weapon:AimCannon( ply, vehicle, pod, Attachment )	
	if not IsValid( pod ) then return end
	
	local Aimang = pod:WorldToLocalAngles( ply:EyeAngles() )
	
	local AimRate = 35
	
	local Angles = vehicle:WorldToLocalAngles( Aimang )
	
	vehicle.sm_pp_yaw = vehicle.sm_pp_yaw and math.ApproachAngle( vehicle.sm_pp_yaw, Angles.y, AimRate * FrameTime() ) or 0
	vehicle.sm_pp_pitch = vehicle.sm_pp_pitch and math.ApproachAngle( vehicle.sm_pp_pitch, Angles.p, AimRate * FrameTime() ) or 0
	
	local TargetAng = Angle(vehicle.sm_pp_pitch,vehicle.sm_pp_yaw,0)
	TargetAng:Normalize() 

	vehicle:SetPoseParameter("turret_yaw", TargetAng.y )
	vehicle:SetPoseParameter("turret_pitch", TargetAng.p )
end

function simfphys.weapon:CanPrimaryAttack( vehicle )
	vehicle.NextShoot = vehicle.NextShoot or 0
	return vehicle.NextShoot < CurTime()
end

function simfphys.weapon:CanSecondaryAttack( vehicle )
	vehicle.NextShoot2 = vehicle.NextShoot2 or 0
	return vehicle.NextShoot2 < CurTime()
end

function simfphys.weapon:CanTertiaryAttack( vehicle )
	vehicle.NextShoot3 = vehicle.NextShoot3 or 0
	return vehicle.NextShoot3 < CurTime()
end

function simfphys.weapon:SetNextPrimaryFire( vehicle, time )
	vehicle.NextShoot = time
	
	vehicle:SetNWFloat( "SpecialCam_LoaderNext", time )
end

function simfphys.weapon:SetNextSecondaryFire( vehicle, time )
	vehicle.NextShoot2 = time
end

function simfphys.weapon:SetNextTertiaryFire( vehicle, time )
	vehicle.NextShoot3 = time
end

function simfphys.weapon:UpdateSuspension( vehicle )
	if not vehicle.filterEntities then
		vehicle.filterEntities = player.GetAll()
		table.insert(vehicle.filterEntities, vehicle)
		
		for i, wheel in pairs( ents.FindByClass( "gmod_sent_vehicle_fphysics_wheel" ) ) do
			table.insert(vehicle.filterEntities, wheel)
		end
	end
	
	vehicle.oldDist = istable( vehicle.oldDist ) and vehicle.oldDist or {}
	
	vehicle.susOnGround = false
	
	for i, v in pairs( tiger_susdata ) do
		local pos = vehicle:GetAttachment( vehicle:LookupAttachment( tiger_susdata[i].attachment ) ).Pos
		
		local trace = util.TraceHull( {
			start = pos,
			endpos = pos + vehicle:GetUp() * - 100,
			maxs = Vector(15,15,0),
			mins = -Vector(15,15,0),
			filter = vehicle.filterEntities,
		} )
		local Dist = (pos - trace.HitPos):Length() - 41
		
		if trace.Hit then
			vehicle.susOnGround = true
		end
		
		vehicle.oldDist[i] = vehicle.oldDist[i] and (vehicle.oldDist[i] + math.Clamp(Dist - vehicle.oldDist[i],-5,1)) or 0
		
		vehicle:SetPoseParameter(tiger_susdata[i].poseparameter, vehicle.oldDist[i] )
	end
end

function simfphys.weapon:DoWheelSpin( vehicle )
	local spin_r = vehicle.VehicleData[ "spin_4" ] + vehicle.VehicleData[ "spin_6" ]
	local spin_l = vehicle.VehicleData[ "spin_3" ] + vehicle.VehicleData[ "spin_5" ]
	
	vehicle:SetPoseParameter("spin_wheels_right", spin_r)
	vehicle:SetPoseParameter("spin_wheels_left", spin_l )
	
	net.Start( "simfphys_update_tracks", true )
		net.WriteEntity( vehicle )
		net.WriteFloat( spin_r ) 
		net.WriteFloat( spin_l ) 
	net.Broadcast()
end