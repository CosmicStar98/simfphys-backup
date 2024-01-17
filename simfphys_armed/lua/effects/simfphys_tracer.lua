--DO NOT EDIT OR REUPLOAD THIS FILE

EFFECT.Mat = Material( "effects/simfphys_armed/spark" )

local Materials = {
	"particle/smokesprites_0001",
	"particle/smokesprites_0002",
	"particle/smokesprites_0003",
	"particle/smokesprites_0004",
	"particle/smokesprites_0005",
	"particle/smokesprites_0006",
	"particle/smokesprites_0007",
	"particle/smokesprites_0008",
	"particle/smokesprites_0009",
	"particle/smokesprites_0010",
	"particle/smokesprites_0011",
	"particle/smokesprites_0012",
	"particle/smokesprites_0013",
	"particle/smokesprites_0014",
	"particle/smokesprites_0015",
	"particle/smokesprites_0016"
}

function EFFECT:Init( data )

	self.StartPos = data:GetStart()
	self.EndPos = data:GetOrigin()
	
	self.Dir = self.EndPos - self.StartPos

	self:SetRenderBoundsWS( self.StartPos, self.EndPos )

	self.TracerTime = math.min( 1, self.StartPos:Distance( self.EndPos ) / 15000 )
	
	self.Length = math.Rand( 0.05, 0.1 )

	-- Die when it reaches its target
	self.DieTime = CurTime() + self.TracerTime
	
	local Dir = self.Dir:GetNormalized()
	
	local emitter = ParticleEmitter( self.StartPos, false )
	
	for i = 0, 12 do
		local Pos = self.StartPos + Dir * i * 0.7 * math.random(1,2) * 0.5
		
		local particle = emitter:Add( "effects/muzzleflash2", Pos )
		local Size = 1
		
		if particle then
			particle:SetVelocity( Dir * 800 )
			particle:SetDieTime( 0.05 )
			particle:SetStartAlpha( 255 * Size )
			particle:SetStartSize( math.max( math.random(10,24) - i * 0.5,0.1 ) * Size )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -1, 1 ) )
			particle:SetColor( 255,255,255 )
			particle:SetCollide( false )
		end
		
		
	end
	
	for i = 0,20 do
		local particle = emitter:Add( Materials[math.random(1,table.Count( Materials ))],self.StartPos )
		
		local rCol = 255
		
		if particle then
			particle:SetVelocity( Dir * math.Rand(1000,3000) + VectorRand() * math.Rand(0,10) )
			particle:SetDieTime( math.Rand(0.05,0.2) )
			particle:SetAirResistance( math.Rand(50,100) ) 
			particle:SetStartAlpha( 20 )
			particle:SetStartSize( 2 )
			particle:SetEndSize( math.Rand(5,10) )
			particle:SetRoll( math.Rand(-1,1) )
			particle:SetColor( rCol,rCol,rCol )
			particle:SetGravity( VectorRand() * 200 + Vector(0,0,200) )
			particle:SetCollide( false )
		end
	end
	
	emitter:Finish()
	
end

function EFFECT:Think()

	if CurTime() > self.DieTime then
		return false
	end

	return true

end

function EFFECT:Render()

	local fDelta = ( self.DieTime - CurTime() ) / self.TracerTime
	fDelta = math.Clamp( fDelta, 0, 1 ) ^ 1

	local sinWave = math.sin( fDelta * math.pi )
	
	local Pos1 = self.EndPos - self.Dir * ( fDelta - sinWave * self.Length )
	
	render.SetMaterial( self.Mat )
	render.DrawBeam( Pos1,
		self.EndPos - self.Dir * ( fDelta + sinWave * self.Length ),
		15, 1, 0, Color( 255, 255, 255, 255 ) )
end
