--[[
name: WaveFlavours
description: A version of the WaveFlavours synthesis algorithm for Protoplug 
author: phil@synaesmedia.net / Mentufacturer
--]]

require "include/protoplug"

local attack = 100
local attackRate = 1/attack
local release = 10000
local decayRate = 1/release

-- set up wave tables
local wave1 = {}
local wave2 = {}
local wave3 = {}


-- SCALEIT(it,lo1,hi1,lo2,hi2) (((it-lo1)/(hi1-lo1))*(hi2-lo2))+lo2

function scaleit(x,lo1,hi1,lo2,hi2) 
	return (((x-lo1)/(hi1-lo1))*(hi2-lo2))+lo2
end

function p2i(p) 
  return math.floor(scaleit(p,0,math.pi*2,0,255))
end




function make_processor(time_max, process_fn, w1, w2)
	return {
		tMax = time_max,
		t = 0,
		iMax = 255,
		i = 0,
		wave1 = w1,
		wave2 = w2,
		tick = function(self) 
			self.t = (self.t + 1) % self.tMax
			if self.t == 0 then
				process_fn(self.i,self.wave1,self.wave2)
				self.i = (self.i + 1) % self.iMax
			end
		end
	}
end


function swap(i,w1,w2)
	x  = w1[i]
	w1[i]=w2[i]
	w2[i]=x
end


local swapper = make_processor(100,swap,wave1,wave2)

function invert(i,w1,w2)
	w1[i]=1-w1[i]
end

local inverter = make_processor(100001,invert,wave1,wave2)

function reverse(i,w1,w2)
	x = w1[i]
	w1[i]=w1[255-i]
	w1[255-i]=x
end

local reverser = make_processor(100000003,reverse,wave1,wave2)

local playwave = wave1

--- 

polyGen.initTracks(8)

function polyGen.VTrack:init()

	-- create per-track fields here
	self.phase = 0
	self.releasePos = release	


	local a=0
	local da=2 * math.pi / 255

	for i=0,255 do
		wave1[i]=math.sin(a)
		a=a+da
		if i < 128 then
			wave2[i]=-0.7
		else
			wave2[i]=0.7
		end 
		wave3[i]= scaleit(i,0,255,-1,1)
	end

end

function polyGen.VTrack:addProcessBlock(samples, smax)
	local amp = 1
	for i = 0,smax do
		
		swapper:tick()
		inverter:tick()
		reverser:tick()
		
		if not self.noteIsOn then
			-- release is finished : idle track
			if self.releasePos>=release then break end
			-- release is under way
			amp = 1-self.releasePos*decayRate
			self.releasePos = self.releasePos+1
		end
		
		self.phase = (self.phase + (self.noteFreq*math.pi*2)) % (math.pi*2)
		
		local trackSample = playwave[p2i(self.phase)]
		samples[0][i] = samples[0][i] + trackSample -- left
		samples[1][i] = samples[1][i] + trackSample -- right
	end
end

function polyGen.VTrack:noteOff(note, ev)
	self.releasePos = 0
end 

function polyGen.VTrack:noteOn(note, vel, ev)
	-- start the sinewave at 0 for a clickless attack
	self.phase = 0
end
