local function cAPCFire(ply,vehicle,shootOrigin,Attachment,damage,ID)	
	local effectdata = EffectData()
		effectdata:SetOrigin( shootOrigin )
		effectdata:SetAngles( Attachment.Ang )
		effectdata:SetEntity( vehicle )
		effectdata:SetAttachment( ID )
		effectdata:SetScale( 1 )
	util.Effect( "AirboatMuzzleFlash", effectdata, true, true )

	local bullet = {}
		bullet.Num 			= 1
		bullet.Src 			= shootOrigin
		bullet.Dir 			= Attachment.Ang:Forward()
		bullet.Spread 		= Vector(0.015,0.015,0)
		bullet.Tracer		= 0
		bullet.TracerName 	= "none"
		bullet.Force		= damage
		bullet.Damage		= damage
		bullet.HullSize		= 1
		bullet.DisableOverride = true
		bullet.Callback = function(att, tr, dmginfo)
			local effectdata = EffectData()
				effectdata:SetEntity( vehicle )
				effectdata:SetAttachment( ID )
				effectdata:SetStart( shootOrigin )
				effectdata:SetOrigin( tr.HitPos )
				effectdata:SetScale( 6000 )
				util.Effect("AR2Tracer", effectdata )
		
			local effectdata = EffectData()
				effectdata:SetOrigin(  tr.HitPos + tr.HitNormal )
				effectdata:SetNormal( tr.HitNormal )
			util.Effect( "AR2Impact", effectdata, true, true )
		end
		bullet.Attacker 	= ply
		
	vehicle:FireBullets( bullet )
end

function simfphys.weapon:ValidClasses()
	
	local classes = {
		"sim_fphys_combineapc_armed"
	}
	
	return classes
end

function simfphys.weapon:Initialize( vehicle )
	local pod = vehicle:GetDriverSeat()
	
	simfphys.RegisterCrosshair( pod )
	
	if not istable( vehicle.PassengerSeats ) or not istable( vehicle.pSeat ) then return end
	
	for i = 1, table.Count( vehicle.pSeat ) do
		simfphys.RegisterCamera( vehicle.pSeat[ i ], Vector(0,30,60), Vector(0,-20,60) )
	end
end

function simfphys.weapon:AimWeapon( ply, vehicle, pod )	
	local Aimang = ply:EyeAngles()
	local AimRate = 250
	
	local Angles = vehicle:WorldToLocalAngles( Aimang ) - Angle(0,90,0)
	
	vehicle.sm_pp_yaw = vehicle.sm_pp_yaw and math.ApproachAngle( vehicle.sm_pp_yaw, Angles.y, AimRate * FrameTime() ) or 0
	vehicle.sm_pp_pitch = vehicle.sm_pp_pitch and math.ApproachAngle( vehicle.sm_pp_pitch, Angles.p, AimRate * FrameTime() ) or 0
	
	local TargetAng = Angle(vehicle.sm_pp_pitch,vehicle.sm_pp_yaw,0)
	TargetAng:Normalize() 
	
	vehicle:SetPoseParameter("vehicle_weapon_yaw", TargetAng.y )
	vehicle:SetPoseParameter("vehicle_weapon_pitch", TargetAng.p )
	
	return Aimang
end

function simfphys.weapon:Think( vehicle )
	local pod = vehicle:GetDriverSeat()
	
	if not IsValid( pod ) then return end
	
	local ply = pod:GetDriver()
	
	local curtime = CurTime()
	
	if not IsValid( ply ) then 
		if vehicle.wpn then
			vehicle.wpn:Stop()
			vehicle.wpn = nil
		end
		return
	end
	
	local ID = vehicle:LookupAttachment( "muzzle" )
	local Attachment = vehicle:GetAttachment( ID )
	
	local Aimang = self:AimWeapon( ply, vehicle, pod )
	
	local tr = util.TraceLine( {
		start = Attachment.Pos,
		endpos = Attachment.Pos + Aimang:Forward() * 10000,
		filter = {vehicle}
	} )
	local Aimpos = tr.HitPos
	
	vehicle.wOldPos = vehicle.wOldPos or Vector(0,0,0)
	local deltapos = vehicle:GetPos() - vehicle.wOldPos
	vehicle.wOldPos = vehicle:GetPos()

	local shootOrigin = Attachment.Pos + deltapos * engine.TickInterval()
	
	vehicle.charge = vehicle.charge or 100
	
	local fire = ply:KeyDown( IN_ATTACK ) and vehicle.charge > 0
	local alt_fire = ply:KeyDown( IN_ATTACK2 )
	
	if not fire then
		vehicle.charge = math.min(vehicle.charge + 0.4,100)
	end
	
	vehicle.NextSecondaryShoot = vehicle.NextSecondaryShoot or 0
	if alt_fire ~= vehicle.afire_pressed then
		vehicle.afire_pressed = alt_fire
		if alt_fire then
			if vehicle.NextSecondaryShoot < curtime then
				if not IsValid(vehicle.missle) then
					vehicle:EmitSound("PropAPC.FireCannon")
					
					local attch = vehicle:GetAttachment( vehicle:LookupAttachment( "cannon_muzzle" ) )
					
					vehicle.missle = ents.Create( "rpg_missile" ) -- need to make my own projectile entity at some point
					vehicle.missle:SetPos( attch.Pos )
					vehicle.missle:SetAngles( attch.Ang - Angle(15,0,0) )
					vehicle.missle:SetOwner( vehicle )
					vehicle.missle:SetSaveValue( "m_flDamage", 250 )
					vehicle.missle:Spawn()
					vehicle.missle:Activate()
					
					vehicle.missle.DirVector = vehicle.missle:GetAngles():Forward()
					
					vehicle.NextSecondaryShoot = curtime + 2
					vehicle.UnlockMissle = curtime + 0.5
				end
			end
		end
	end
	
	if IsValid( vehicle.missle ) then
		if vehicle.UnlockMissle < curtime then
			local targetdir = Aimpos - vehicle.missle:GetPos()
			targetdir:Normalize()
			
			vehicle.missle.DirVector = vehicle.missle.DirVector + (targetdir - vehicle.missle.DirVector) * 0.1
			
			local vel = -vehicle.missle:GetVelocity() + vehicle.missle.DirVector * 1500 + vehicle:GetVelocity()
			
			vehicle.missle:SetVelocity( vel )
			vehicle.missle:SetAngles( vehicle.missle.DirVector:Angle() )
		end
	end
	
	vehicle.NextShoot = vehicle.NextShoot or 0
	if vehicle.NextShoot < curtime then
		if fire then
			cAPCFire(ply,vehicle,shootOrigin,Attachment,25,ID)
			vehicle:EmitSound("Weapon_AR2.Single")
			
			vehicle.charge = vehicle.charge - 2.5
			
			if vehicle.charge <= 0 then
				if vehicle.charge >= -6 then
					vehicle:EmitSound("weapons/airboat/airboat_gun_energy"..math.Round(math.random(1,2),0)..".wav")
				end
				vehicle.charge = -25
			end
			
			vehicle.NextShoot = curtime + 0.12
		end
	end
end
