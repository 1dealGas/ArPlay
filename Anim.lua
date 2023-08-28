-- Aerials/Pragma/Anim.script
-- Settings.
local HITCOMMON = vmath.vector4(1)
local HITDAY = vmath.vector4(1,0.85546875,0.62890625,1)
local LATE = vmath.vector4(0.63671875, 0.38671875, 0.3125, 1)
local EARLY = vmath.vector4(0.3125, 0.5625, 0.63671875, 1)
local ANIM_LENGTH = 370  -- Must Larger than 193.7.
local HITZONE = 37

-- Methods.
local url = msg.url
local send = msg.post
local set = go.set
local scale = go.set_scale

-- Experimental Update:
-- Use msg.url to Access a Component from a Go Spawned by a Factory.
local hash_ar = hash("Ar")
local hash_sprite = hash("Sprite")
local tint = hash("tint")

-- Properties?
local euler = hash("euler.z")
local hash_ar_opacity = hash("ar_opacity")

-- Messages.
local hash_ar_update = hash("ar_update")
local hash_ar_disable = hash("ar_disable")
local hash_ar_toggle_daymode = hash("ar_toggle_daymode")
local hash_enable = hash("enable")
local hash_disable = hash("disable")

-- Related to the Factory.
local create = factory.create
local parent = go.set_parent
local del = go.delete
local ArcAnimi = url("Ar:/Pragma#ArcAnimi")

local HIT = HITCOMMON
function init(self)
	if self.done then
	else
		local self_url = url()

		local l = create(ArcAnimi)
		parent(l, self_url)
		send(l, hash_disable)
		self.animl = l
		self.spritel = url(hash_ar,l,hash_sprite)

		local r = create(ArcAnimi)
		parent(r, self_url)
		send(r, hash_disable)
		self.animr = r
		self.spriter = url(hash_ar,r,hash_sprite)
		
		self.disabled = true
		self.done = true
	end
end

local daymode = false
function on_message(self, message_id, message)
	
	if message_id == hash_ar_disable then
		if self.disabled then
		else
			send(self.animl, hash_disable)
			send(self.animr, hash_disable)
			self.disabled = true
		end
		
	elseif message_id == hash_ar_update then
		
		--
		-- message == {anim_progress, dt}
		--

		-- Enable Child Gos.
		if self.disabled then
			send(self.animl, hash_enable)
			send(self.animr, hash_enable)
			self.disabled = false
		end

		-- Gets References.
		local l = self.animl
		local r = self.animr
		local ls = self.spritel
		local rs = self.spriter

		-- Preparations.
		local anim_progress = message[1]
		local dt = message[2]
		local calculate = 0
		if anim_progress>ANIM_LENGTH or anim_progress<0 then
			send(l, hash_disable)
			send(r, hash_disable)
			self.disabled = true
		else
			
			-- Animating Opacity.
			if anim_progress >= 73 then
				calculate = (anim_progress-73)/(ANIM_LENGTH-73)
				calculate = 0.637 * calculate * (2-calculate)
				calculate = 0.637 - calculate
			else
				calculate = anim_progress * 0.01
				calculate = 0.637 * calculate * (2-calculate)
				calculate = 0.17199 + calculate
			end

			-- Animating Tint.
			if dt<HITZONE and dt>-HITZONE then
				HIT.w = calculate
				set(ls, tint, HIT)
				set(rs, tint, HIT)
			elseif dt>=HITZONE then
				LATE.w = calculate
				set(ls, tint, LATE)
				set(rs, tint, LATE)
			else
				EARLY.w = calculate
				set(ls, tint, EARLY)
				set(rs, tint, EARLY)
			end

			-- Animating AnimL.
			if anim_progress<=193.7 then
				calculate = anim_progress/193.7
				set(l, euler, 45 + 28*calculate)
				calculate = calculate * (2-calculate)
				scale( 0.637 + calculate , l)
			else
				set(l, euler, 73)
				scale(1.637, l)
			end
			
			-- Animating AnimR.
			calculate = anim_progress/ANIM_LENGTH
			calculate = calculate * (2-calculate)
			set(r, euler, 45 - 8*calculate)
			scale( 0.637 + calculate , r)
		end
		
	elseif message_id==hash_ar_toggle_daymode then
		if daymode then
			HIT = HITCOMMON
			daymode = false
		else
			HIT = HITDAY
			daymode = true
		end
	end
	
end

function final(self)
	del(self.animl)
	del(self.animr)
end
