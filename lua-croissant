--[[
name: croissant
description: MIDI processor VST/AU for Protoplug. 
I'm going to create a library that emulates the functionality I use from Sonic-Pi for generative / algorithmic music. 
Starting with the ring (cyclic array) data-structure.
author: phil@synaesmedia.net
--]]

require "include/protoplug"

local blockEvents = {}



function ring(ns) 
	local count = 0
	for _ in pairs(ns) do count = count + 1 end
	return {
		notes = ns,
		noItems = count,
		current = 0,	
		choose = function(self) 
			r = math.random(self.noItems)
			x = self.notes[r]
			return x
		end,
		tick = function(self)
			if (self.current > self.noItems-1) then
				self.current = 0
			end
			self.current = self.current + 1 
			return self.notes[self.current]
		end
	} 
end
 
local scale = ring({0, 3, 7, 11, 12, 17})
local off_buffer = {}

function plugin.processBlock(samples, smax, midiBuf)
	blockEvents = {} 
	for ev in midiBuf:eachEvent() do
		if ev:isNoteOn() then
			local root = ev:getNote()			
			local note = root + scale:choose()
			off_buffer[root] = note
			play(ev:getChannel(),note,ev:getVel())
		elseif ev:isNoteOff() then
			local note = off_buffer[ev:getNote()]
			if not note == nil then
				play_off(ev:getChannel(),note)
			end
		end	 
	end
	-- fill midi buffer with prepared notes
	midiBuf:clear()
	if #blockEvents>0 then
		for _,e in ipairs(blockEvents) do
			midiBuf:addEvent(e)
		end 
	end
end

function play(chan,note,vel)
	local newEv = midi.Event.noteOn(chan,note,vel)
	table.insert(blockEvents, newEv)
end
 

function play_off(chan,note)
	local newEv = midi.Event.noteOff(chan,note)
	table.insert(blockEvents, newEv)
end
