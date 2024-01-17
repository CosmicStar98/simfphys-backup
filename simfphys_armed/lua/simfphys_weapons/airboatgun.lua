
local function AirboatFire(ply,vehicle,shootOrigin,Attachment,damage)
	local bullet = {}
		bullet.Num 			= 1
		bullet.Src 			= shootOrigin
		bullet.Dir 			= Attachment.Ang:Forward()
		bullet.Spread 		= Vector(0.04,0.04,0)
		bullet.Tracer		= 1
		bullet.TracerName 	= (damage > 10 and "AirboatGunHeavyTracer" or "AirboatGunTracer")
		bullet.Force		= damage
		bullet.Damage		= damage
		bullet.HullSize		= 1
		bullet.DisableOverride = true
		bullet.Callback = function(att, tr, dmginfo)
			dmginfo:SetDamageType(DMG_AIRBOAT)
			
			local effectdata = EffectData()
				effectdata:SetOrigin(  tr.HitPos + tr.HitNormal )
				effectdata:SetNormal( tr.HitNormal )
				effectdata:SetRadius( (damage > 1) and 8 or 3 )
			util.Effect( "cball_bounce", effectdata, true, true )
		end
		bullet.Attacker 	= ply
		
	vehicle:FireBullets( bullet )
end

function simfphys.weapon:ValidClasses()
	
	local classes = {
		"sim_fphys_jeep_armed2",
		"sim_fphys_v8elite_armed2"
	}
	
	return classes
end

function simfphys.weapon:Initialize( vehicle )
	--vehicle:SetBodygroup(1,1)

	local ID = vehicle:LookupAttachment( "gun_ref" )
	local attachmentdata = vehicle:GetAttachment( ID )

	local prop = ents.Create( "gmod_sent_vehicle_fphysics_attachment" )
	prop:SetModel( "models/airboatgun.mdl" )			
	prop:SetPos( attachmentdata.Pos )
	prop:SetAngles( attachmentdata.Ang )
	prop:SetModelScale( 0.5 ) 
	prop:Spawn()
	prop:Activate()
	prop:SetNotSolid( true )
	prop:SetParent( vehicle, ID )
	prop.DoNotDuplicate = true

	simfphys.RegisterCrosshair( vehicle:GetDriverSeat() )
	
	simfphys.SetOwner( vehicle.EntityOwner, prop )
end

function simfphys.weapon:AimWeapon( ply, vehicle, pod )	
	local Aimang = ply:EyeAngles()
	local AimRate = 250
	
	local Angles = vehicle:WorldToLocalAngles( Aimang ) - Angle(0,90,0)
	
	vehicle.sm_pp_yaw = vehicle.sm_pp_yaw and math.ApproachAngle( vehicle.sm_pp_yaw, Angles.y, AimRate * FrameTime() ) or 0
	vehicle.sm_pp_pitch = vehicle.sm_pp_pitch and math.ApproachAngle( vehicle.sm_pp_pitch, Angles.p, AimRate * FrameTime() ) or 0
	
	local TargetAng = Angle(vehicle.sm_pp_pitch,vehicle.sm_pp_yaw,0)
	TargetAng:Normalize() 
	
	vehicle:SetPoseParameter("vehicle_weapon_yaw", -TargetAng.y )
	vehicle:SetPoseParameter("vehicle_weapon_pitch", -TargetAng.p )
	
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
	
	self:AimWeapon( ply, vehicle, pod )
	
	vehicle.wOldPos = vehicle.wOldPos or Vector(0,0,0)
	local deltapos = vehicle:GetPos() - vehicle.wOldPos
	vehicle.wOldPos = vehicle:GetPos()

	local shootOrigin = Attachment.Pos + deltapos * engine.TickInterval()
	
	vehicle.charge = vehicle.charge or 100
	
	local fire = ply:KeyDown( IN_ATTACK ) and vehicle.charge > 0
	
	if fire then
		self:PrimaryAttack( vehicle, ply, shootOrigin, Attachment, ID )
	else
		vehicle.charge = math.min(vehicle.charge + 0.3,100)
	end
	
	vehicle.OldFire = vehicle.OldFire or false
	if vehicle.OldFire ~= fire then
		vehicle.OldFire = fire
		if fire then
			vehicle.wpn = CreateSound( vehicle, "weapons/airboat/airboat_gun_loop2.wav" )
			vehicle.wpn:Play()
			vehicle:CallOnRemove( "stopmesounds", function( vehicle )
				if vehicle.wpn then
					vehicle.wpn:Stop()
				end
			end)
		else
			if vehicle.wpn then
				vehicle.wpn:Stop()
				vehicle.wpn = nil
			end

			vehicle:EmitSound("weapons/airboat/airboat_gun_lastshot"..math.random(1,2)..".wav")
		end
	end
end

function simfphys.weapon:CanPrimaryAttack( vehicle )
	vehicle.NextShoot = vehicle.NextShoot or 0
	return vehicle.NextShoot < CurTime()
end

function simfphys.weapon:SetNextPrimaryFire( vehicle, time )
	vehicle.NextShoot = time
end

function simfphys.weapon:PrimaryAttack( vehicle, ply, shootOrigin, Attachment, ID )
	if not self:CanPrimaryAttack( vehicle ) then return end
	
	local effectdata = EffectData()
		effectdata:SetOrigin( shootOrigin )
		effectdata:SetAngles( Attachment.Ang )
		effectdata:SetEntity( vehicle )
		effectdata:SetAttachment( ID )
		effectdata:SetScale( 1 )
	util.Effect( "AirboatMuzzleFlash", effectdata, true, true )
	
	AirboatFire(ply,vehicle,shootOrigin,Attachment,(vehicle.charge / 5))
	
	vehicle.charge = vehicle.charge - 0.5
	
	if vehicle.charge <= 0 then
		if vehicle.charge > -1 then
			vehicle:EmitSound("weapons/airboat/airboat_gun_energy"..math.Round(math.random(1,2),0)..".wav")
		end
		vehicle.charge = -50
	end
	
	self:SetNextPrimaryFire( vehicle, CurTime() + 0.05 )
end
