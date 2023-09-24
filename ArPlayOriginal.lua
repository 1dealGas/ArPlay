go.property("fumen_id", 0)
go.property("sound_speed", 1)
go.property("display_losts", false)
go.property("options", false)

----------------  Important Note  ----------------
--
--
-- A.Steps Before Creating An ArPlay Instance
--
--   I.Register Components of Current Song. Check ArState for Details.
--     Ar__current_song_id = false
--     Ar__current_plate = false
--     Ar__current_sound = false
--     Ar__current_illust = false
--  
--   II.Set Dimfunc and Dedimfunc Following the Template below.
--      function ArTr__dimfunc()
--      	-- Loads the Arf File.
--      	local fm_string = sys.load_resource(WHICH_CHART)
--      	local fm_func = loadstring(demofm_string)
--      	Ar__fumens = fm_func()  -- For multiple Arfs: {Arf1,Arf2,···}
--      	demofm_string = nil
--      	demofm_func = nil
--      	-- For multiple Arfs, Specify the Fumen Id for Each Arf.
--     		sound.stop(Ar__current_sound)
--      	factory.create("Ar:/Pragma#ArcPlay",_,_,{sound_speed = SOUND_SPEED, display_losts = true, options=true})
--      end
--
--     function ArTr__dedimfunc()
--     		-- Records the Init Time.
--     		Ar__init_time = socket.gettime() * 1000
--     		Ar__paused_time = 0
--     		sound.play(Ar__current_sound)
--     end
--
--   III.Dim Down.
--       ArTr__dim()
--
--
-- B.Traits to be Implemented
--
--   ArPlay Properties:
--   	◆ Multiinstance with Fumen Id
--   	◆ Sound Speed [0.2,3)
--   	  -- Supports Changing Sound Speed At Runtime:
--   	     if Ar__arplays[1]>0 then
--   	     	for i=3,Ar__arplays[2] do
--   	     		if Ar__arplays[i] then msg.post(Ar__arplays[i], "ar_sound_speed", {VALUE}) end
--   	     	end
--   	     end
--   	◆ Optional Lost Counter
--   	◆ Options Panel
--
--   ArPlay Built-in:
--   	◇ Another
--   	  A. Display Another Wish/Hint
--   	  B. Terminate Unselected ArPlay Instance
--   	◆ ArIf Array
--   	  {2,mstime1,false,mstime2,"Won't Show the Score"}
--		◆ Camera Array
--   	  See the Function ArCamera()
--		◆ DTime Array
--   	  See the Function ArDTime()
--   	  After Enabling this Trait, Make the WishIndex Distributed by DTime.
--
--   In the Plate:
--   	◆ Toggle DayMode
--   	  if Ar__arplays[3] then msg.post(Ar__arplays[3], "ar_toggle_daymode") end
--   	◇ Optional Illust Tint Effect
--   	◇ Attach Script Component with ArPlay's Message Posting
--
--   	  -- In Arf
--   	  Arf.Info.Traits.Attach = hash("Spec")
--
--   	  -- In Plate#Spec
--   	  function on_message(self, message_id, message)
--   	      if message_id == hash_ar_enable then
--   	      elseif message_id == hash_ar_update then
--   	      elseif message_id == hash_ar_disable then
--   	  end
--
--
-- C.Arf Format Requirement
--   
--   -- Header
--   local v = vmath.vector4
--   local t = vmath.vector3
--   local e = {}
--
--   -- Arf Emobdiment
--   local f={
-- 	 	Aerials = "Arf",
-- 	 	Info = {
--   		Traits = e,
--   		Madeby = "··|··  Inherited from Project Solace",
--   		Init = -152,
--   		End = 225554,  -- ms_of_last_object + index_scale
--   		Hints = 1029
--   	},
-- 	 	Wish = {
-- 	 		{3,0,v(6,1,-152,0),v(6,1,630,0),···},
--   		···
-- 	 	},
-- 	 	Hint = {v(6,1,630,0),···},
-- 	 	Index = {
-- 	 		Scale = 512,
-- 	 		Wish = {{1},{1},···},
-- 	 		Hint = {e,{1},···},
-- 	 		Wgo = {0,0,···},  -- The amount of 0 depends on the max size of WishIndex Group.
-- 	 		Hgo = {0,0,···},  -- The amount of 0 depends on the maxium value of #HintIndex[k-1]+#HintIndex[k]+#HintIndex[k+1].
-- 	 		Ago = {0,0,···},  -- The amount of 0 depends on the maxium value of #HintIndex[k-1]+#HintIndex[k]+#HintIndex[k+1].
-- 	 		Vecs = {t(),t(),···},  -- The amount of 0 depends on the max size of WishIndex Group.
-- 	 		Tints = {0,0,···}  -- The amount of 0 depends on the max size of WishIndex Group.
--   	}
--   }
--
--   -- Tailer
--   return f
--
--   1. At the Head of Each Wish Group, Poll Progress(3) and ZIndex(z) Are Contained.
--   2. x[0,16]  y[0,8]  z:int[1,16]
--   3. Wish Node: v(x,y,time,easetype);  Hint: v(x,y,mstime,z);  For easetype, See the Function ease().
--   4. "time" Refers to mstime if DTime is Disabled, and to DTime if DTime is Enabled.
--   5. For "easetype", See the Function ease().
--   6. For Empty Tables( {} ), Replace them with e.
--   7. Wish&Hint Index Begins at 0.
--   8. Madeby: "Level  Author"
--
--
--------------------------------------------------

local v3 = vmath.vector3
local v4 = vmath.vector4
local current_interpolated = v4(0)

--  System Settings  --
--
local HINTSIZE2 = 337.5  -- Size of A Hint.
local HITZONE = 37  -- Must Smaller than 510-ANIM_LENGTH(=140).
local SWEEP = 100  -- And Also Smaller than 370.

local OPTANIM_LENGTH = 0.37
local PLAYBACK = go.PLAYBACK_ONCE_FORWARD
local EASE_EXPAND = go.EASING_OUTCUBIC
local EASE_CLOSE = go.EASING_OUTCUBIC

local DELIT = v4(0.2037, 0.2037, 0.2037, 1)
local NJLIT = v4(0.3737, 0.3737, 0.3737, 1)

local HITCOMMON = v4(0.73, 0.73, 0.73, 1)
local HITDAY = v4(0.73, 0.6244921875, 0.4591015625, 1)
local EAR = v4(0.3125, 0.5625, 0.63671875, 1)
local LAT = v4(0.63671875, 0.38671875, 0.3125, 1)

local INIT = v4(0.1337, 0.1337, 0.1337, 1)
local LST = v4(1, 0.51, 0.51, 1)

local hlratio = 0
local HIT = HITCOMMON
local function hintinit(dt)
	hlratio = 0.07 * (510+dt) / 140
	INIT.x = 0.1337 + hlratio
	INIT.y = 0.1337 + hlratio
	INIT.z = 0.1337 + hlratio
	return INIT
end
local function hintlost(dt)
	hlratio = 0.437 - dt*0.00037
	LST.x = hlratio
	LST.y = 0.51*hlratio
	LST.z = 0.51*hlratio
	return LST
end

--
-----------------------------

-- Update: Haptics Related.
--
local haptics_supported = false
local hapticsfunc = false
local iosh = false

local has_hint_judged = false
local last_vibration_time = 0

if Ar__mobile=="Android" then
	if vibrate then
		haptics_supported = true
		hapticsfunc = vibrate.trigger
	end
elseif Ar__mobile then
	if (taptic_engine) and taptic_engine.isSupported() then
		haptics_supported = true
		hapticsfunc = taptic_engine.impact
		iosh = taptic_engine.IMPACT_MEDIUM
	end
end
--
-----------------------------

local Ar = hash("Ar")
local url = msg.url
local Exit = url("Ar:/ArIf#Exit")
local Options = url("Ar:/ArIf#Options")
local ArcWish = url("Ar:/Pragma#ArcWish")
local ArcHint = url("Ar:/Pragma#ArcHint")
local ArcAnim = url("Ar:/Pragma#ArcAnim")
local ArIf = url("Ar:/ArIf#Label")
local hash = hash

local hash_sprite = hash("Sprite")
local hash_px = hash("position.x")
local hash_py = hash("position.y")
local hash_pz = hash("position.z")
local hash_tint = hash("tint")
local hash_tintw = hash("tint.w")
local hash_sound_speed = hash("speed")

local tdelay = timer.delay
local gc = collectgarbage
local str_step = "step"

local send = msg.post
local spawn_from = factory.create
local playflp = sprite.play_flipbook
local goanimc = go.cancel_animations
local parent = go.set_parent
local scale = go.set_scale
local animg = go.animate
local del = go.delete
local set = go.set

local intfrac = math.modf
local floor = math.floor
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt

local hash_enable = hash("enable")
local hash_disable = hash("disable")
local hash_ar_update = hash("ar_update")
local hash_ar_enable = hash("ar_enable")
local hash_ar_disable = hash("ar_disable")
local hash_ar_ui_final = hash("ar_ui_final")
local set_position = go.set_position
local self_pos = go.get_position

local tostr = tostring
local fmt = string.format
local label_set_text = label.set_text
local str_empty = ""
local fmt_score = "◇  %d"
local fmt_score_max = "◇  %d · Perfection Obtained"
local fmt_score_and_lost = "◇  %d · %d"

--  Easing System
--
local easecalc = 0
local function ease(ratio, typeid)
	--
	-- InCirc
	if typeid == 1 then easecalc = sqrt( 1 - ratio*ratio ); return ( 1 - easecalc )
	--
	-- OutCirc
	elseif typeid == 2 then easecalc = 1 - ratio; return sqrt( 1 - easecalc*easecalc )
	--
	-- InQuad
	elseif typeid == 3 then return ratio*ratio
	--
	-- OutQuad
	elseif typeid == 4 then easecalc = 1 - ratio; return ( 1 - easecalc*easecalc )
	--
	-- InQuart
	elseif typeid == 5 then easecalc = ratio*ratio; return ( easecalc*easecalc )
	--
	-- OutQuart
	elseif typeid == 6 then easecalc = 1 - ratio; easecalc = easecalc*easecalc; return ( 1 - easecalc*easecalc )
	else return ratio end
end
--
-- Input: Detection
--
local HINTSIZE = HINTSIZE2/2
local tdx,tdy,ofi = false,false,false
local function has_touch_near(x,y,of,selfx)
	for i=4,of[3] do
		ofi = of[i]
		if ofi.z>0 then
			tdy = ofi.y - y
			if tdy<=HINTSIZE and tdy>=-HINTSIZE then
				tdx = ofi.x - x - selfx
				if tdx<=HINTSIZE and tdx>=-HINTSIZE then
					return true
				end
			end
		end
	end
end
--
-- Input: Block "Covered" Hints
--
local blocked = {}
local blnum = 0
local bdx = 0
local bdy = 0
local fsafe=true
local function safe(x,y)
	if x then
		if blnum==0 then
			blnum = 1
			blocked[1] = x
			blocked[2] = y
			return true
		elseif blnum==1 then
			bdx = x - blocked[1]
			bdy = y - blocked[2]
			if bdx<=HINTSIZE2 and bdy<=HINTSIZE2 and bdx>=-HINTSIZE2 and bdy>=-HINTSIZE2 then
				return false
			else
				blnum = 2
				blocked[3] = x
				blocked[4] = y
				return true
			end
		else
			fsafe = true
			for i=blnum,1,-1 do
				bdx = x - blocked[i*2-1]
				bdy = y - blocked[i*2]
				if bdx<=HINTSIZE2 and bdy<=HINTSIZE2 and bdx>=-HINTSIZE2 and bdy>=-HINTSIZE2 then
					fsafe = false
					break
				end
			end
			if fsafe then
				blnum = blnum + 1
				blocked[blnum*2-1] = x
				blocked[blnum*2] = y
			end
			return fsafe
		end
	elseif #blocked~=0 then
		blnum = 0
		for i=#blocked,1,-1 do
			blocked[i] = nil
		end
	end
end
--
-- Update: DTime and Camera System
--
local last_since = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local last_to = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local last_base = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local last_ratio = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local function ArDTime(nodes, progress, zindex)
	--
	-- DTime Nodes:
	-- {
	-- 	[ZIndex] = {2,t(since_ms,base,ratio),···},
	-- 	···
	-- }
	--
	-- To Control the Size of Arf, Please Clamp Your DTime into [0,512000].
	--
	if nodes then

		local zn = nodes[zindex]
		if (zn) and #zn>1 and progress>=zn[2].x then

			local ls = last_since[zindex]
			if progress>=ls and progress<last_to[zindex] then
				return last_base[zindex] + (progress-ls)*last_ratio[zindex]
			else

				-- Gets Poll Progress, and Guards the Progress.
				local znlen = #zn
				local poll_progress = zn[1]
				while poll_progress > 2 and progress < zn[poll_progress].x do
					poll_progress = poll_progress - 1
				end

				-- Interpolate
				local result = false
				while not(poll_progress>znlen or result) do
					local p = zn[poll_progress+1]
					if (p) and progress>=zn[poll_progress].x and progress<p.x then
						--
						last_to[zindex] = p.x
						--
						p = zn[poll_progress]
						local sincems = p.x
						local base = p.y
						local ratio = p.z
						result = base + (progress-sincems)*ratio
						--
						last_since[zindex] = sincems
						last_base[zindex] = base
						last_ratio[zindex] = ratio
						--
						zn[1] = poll_progress
					elseif poll_progress==znlen then
						p = zn[poll_progress]
						local sincems = p.x
						local base = p.y
						local ratio = p.z
						result = base + (progress-sincems)*ratio
						--
						last_since[zindex] = sincems
						last_to[zindex] = 512000
						last_base[zindex] = base
						last_ratio[zindex] = ratio
						--
						zn[1] = poll_progress
					else
						poll_progress = poll_progress+1
					end
				end
				
				return result or 2
			end
		else
			return progress
		end
	else
		for i=1,16 do
			last_since[i],last_to[i],last_base[i],last_ratio[i] = 0,0,0,0
		end
	end
end

local function ArCamera(nodes, progress, zindex)
	--
	-- Cam Nodes:
	-- {
	-- 	[ZIndex] = {
	-- 		[1] = {2,t(node_ms,value,easetype),···},  -- xscale
	-- 		[2] = {2,t(node_ms,value,easetype),···},  -- yscale
	-- 		[3] = {2,t(node_ms,value,easetype),···},  -- rotrad
	-- 		[4] = {2,t(node_ms,value,easetype),···},  -- xdelta
	-- 		[5] = {2,t(node_ms,value,easetype),···}  -- ydelta
	-- 	},
	-- 	···
	-- }
	--
	-- Return Order: xscale,yscale,rotrad,xdelta,ydelta
	--
	if progress then
		
		local xscale = 1
		local yscale = 1
		local rotrad = 0
		local xdelta = 0
		local ydelta = 0

		local zf = floor(zindex)

		if nodes[zf] then
			local zn = nodes[zf]
			
			if (zn[1]) and #zn[1]>1 and progress>=zn[1][2].x then
				local znt = zn[1]
				local zntlen = #znt
				if progress >= znt[zntlen].x then
					xscale = znt[zntlen].y
				else
					local poll_progress = znt[1]
					local type_interpolated = false
					while poll_progress ~= zntlen and not type_interpolated do
						if znt[poll_progress].x <= progress and znt[poll_progress+1].x > progress then
							local t0 = znt[poll_progress].x
							local v0 = znt[poll_progress].y
							local etype = znt[poll_progress].z
							local dt = znt[poll_progress+1].x - t0
							local dv = znt[poll_progress+1].y - v0
							local ratio = (progress-t0) / dt
							if etype==0 then xscale = v0 + dv*ratio
							else xscale = v0 + dv*ease(ratio, etype)
							end
							type_interpolated = true
							znt[1] = poll_progress
						else
							poll_progress = poll_progress + 1
						end
					end
				end
			end

			if (zn[2]) and #zn[2]>1 and progress>=zn[2][2].x then
				local znt = zn[2]
				local zntlen = #znt
				if progress >= znt[zntlen].x then
					yscale = znt[zntlen].y
				else
					local poll_progress = znt[1]
					local type_interpolated = false
					while poll_progress ~= zntlen and not type_interpolated do
						if znt[poll_progress].x <= progress and znt[poll_progress+1].x > progress then
							local t0 = znt[poll_progress].x
							local v0 = znt[poll_progress].y
							local etype = znt[poll_progress].z
							local dt = znt[poll_progress+1].x - t0
							local dv = znt[poll_progress+1].y - v0
							local ratio = (progress-t0) / dt
							if etype==0 then yscale = v0 + dv*ratio
							else yscale = v0 + dv*ease(ratio, etype)
							end
							type_interpolated = true
							znt[1] = poll_progress
						else
							poll_progress = poll_progress + 1
						end
					end
				end
			end

			if (zn[3]) and #zn[3]>1 and progress>=zn[3][2].x then
				local znt = zn[3]
				local zntlen = #znt
				if progress >= znt[zntlen].x then
					rotrad = znt[zntlen].y
				else
					local poll_progress = znt[1]
					local type_interpolated = false
					while poll_progress ~= zntlen and not type_interpolated do
						if znt[poll_progress].x <= progress and znt[poll_progress+1].x > progress then
							local t0 = znt[poll_progress].x
							local v0 = znt[poll_progress].y
							local etype = znt[poll_progress].z
							local dt = znt[poll_progress+1].x - t0
							local dv = znt[poll_progress+1].y - v0
							local ratio = (progress-t0) / dt
							if etype==0 then rotrad = v0 + dv*ratio
							else rotrad = v0 + dv*ease(ratio, etype)
							end
							type_interpolated = true
							znt[1] = poll_progress
						else
							poll_progress = poll_progress + 1
						end
					end
				end
			end

			if (zn[4]) and #zn[4]>1 and progress>=zn[4][2].x then
				local znt = zn[4]
				local zntlen = #znt
				if progress >= znt[zntlen].x then
					xdelta = znt[zntlen].y
				else
					local poll_progress = znt[1]
					local type_interpolated = false
					while poll_progress ~= zntlen and not type_interpolated do
						if znt[poll_progress].x <= progress and znt[poll_progress+1].x > progress then
							local t0 = znt[poll_progress].x
							local v0 = znt[poll_progress].y
							local etype = znt[poll_progress].z
							local dt = znt[poll_progress+1].x - t0
							local dv = znt[poll_progress+1].y - v0
							local ratio = (progress-t0) / dt
							if etype==0 then xdelta = v0 + dv*ratio
							else xdelta = v0 + dv*ease(ratio, etype)
							end
							type_interpolated = true
							znt[1] = poll_progress
						else
							poll_progress = poll_progress + 1
						end
					end
				end
			end

			if (zn[5]) and #zn[5]>1 and progress>=zn[5][2].x then
				local znt = zn[5]
				local zntlen = #znt
				if progress >= znt[zntlen].x then
					ydelta = znt[zntlen].y
				else
					local poll_progress = znt[1]
					local type_interpolated = false
					while poll_progress ~= zntlen and not type_interpolated do
						if znt[poll_progress].x <= progress and znt[poll_progress+1].x > progress then
							local t0 = znt[poll_progress].x
							local v0 = znt[poll_progress].y
							local etype = znt[poll_progress].z
							local dt = znt[poll_progress+1].x - t0
							local dv = znt[poll_progress+1].y - v0
							local ratio = (progress-t0) / dt
							if etype==0 then ydelta = v0 + dv*ratio
							else ydelta = v0 + dv*ease(ratio, etype)
							end
							type_interpolated = true
							znt[1] = poll_progress
						else
							poll_progress = poll_progress + 1
						end
					end
				end
			end
			
		end
		return xscale,yscale,rotrad,xdelta,ydelta
		
	else
		for zi=1,16 do
			local zn = nodes[zi]
			if zn then
				if zn[1] then zn[1][1] = 2 end
				if zn[2] then zn[2][1] = 2 end
				if zn[3] then zn[3][1] = 2 end
				if zn[4] then zn[4][1] = 2 end
				if zn[5] then zn[5][1] = 2 end
			end
		end
	end
end



----------------  DEFOLD LIFECYCLE FUNCTIONS  ----------------
--
local last_arif_progress = 0
function init(self)

	-- Registers the ArPlay Instance to the Input System.
	local fm = false
	local self_url = url().path
	
	if self.fumen_id==0 then
		Ar__arplays[1],Ar__arplays[2],Ar__arplays[3] = 1, 3, self_url
	else
		local fmno = self.fumen_id + 2
		Ar__arplays[1] = Ar__arplays[1] + 1
		if Ar__arplays[2] < fmno then Ar__arplays[2] = fmno end
		Ar__arplays[fmno] = self_url
	end
	self.url = self_url

	-- Transfers an Arf's Reference.
	if self.fumen_id == 0 then
		fm = Ar__fumens
		Ar__current_total_hints = fm.Info.Hints
		Ar__fumens = {}
	else
		fm = Ar__fumens[self.fumen_id]
		self.totalhints = fm.Info.Hints
		Ar__current_total_hints = Ar__current_total_hints + self.totalhints
		Ar__fumens[self.fumen_id] = nil
	end

	-- Does Stuff about Tags.
	-- Tag System is Under Construction.
	--
	local traited = fm.Info.Traits
	if traited.Camera then
		local cam_prim = traited.Camera
		self.Camera = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
		for i=1,16 do
			if cam_prim[i] then self.Camera[i] = cam_prim[i] end
		end
	end
	if traited.DTime then
		local dt_prim = traited.DTime
		
		self.DTime = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
		for i=1,16 do
			if dt_prim[i] then self.DTime[i] = dt_prim[i] end
		end
		ArDTime()
		
		self.has = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
		local w = fm.Wish
		local h = fm.Hint
		local zg = 0

		for g=1,#w do
			zg = floor(w[g][2])
			self.has[zg] = true
		end
		for hi=1,#h do
			zg = floor(h[hi].w)
			self.has[zg] = true
		end
		
	end
	if traited.ArIf then
		local _if = traited.ArIf
		if _if[3]~=nil and #_if%2==1 then
			last_arif_progress = 0
			self.ArIf = _if
		end
	end
	--
	--
	-- Sets the Info, and Decreases the Index Depth when Polling.
	-- Note that Defold doesn't support the method collectgarbage("stop").
	if self.fumen_id < 2 then
		gc("setpause", 104857600)
		set(Ar__current_sound, hash_sound_speed, self.sound_speed)
		label_set_text(ArIf, fm.Info.Madeby)
	end

	self.Init = fm.Info.Init
	self.End = fm.Info.End

	self.Wish = fm.Wish
	self.Hint = fm.Hint

	self.index_scale = fm.Index.Scale
	self.Windex = fm.Index.Wish
	self.Hindex = fm.Index.Hint
	self.Wgo = fm.Index.Wgo
	self.Hgo = fm.Index.Hgo
	self.Vecs = fm.Index.Vecs
	self.Tints = fm.Index.Tints

	if Ar__play_animation then
		self.play_animation = true
		self.Ago = fm.Index.Ago
	end

	fm = nil

	-- Precaculates Hints' Actual Positions.
	local hints = self.Hint
	if self.Camera then
		local cam = self.Camera
		for i=1, #hints do
			-- Camera Configuration for Current Frame.
			local pos = hints[i]
			local posx = pos.x
			local posy = pos.y
			local xscale = 1
			local yscale = 1
			local rotrad = 0
			local xdelta = 0
			local ydelta = 0
			xscale,yscale,rotrad,xdelta,ydelta = ArCamera(cam, pos.z, floor(pos.w))
			-- Transformation.
			if rotrad > -0.01 and rotrad < 0.01 then
				posx = 8 + (posx - 8) * xscale + xdelta
				posy = 4 + (posy - 4) * yscale + ydelta
			else
				local dx = (posx - 8) * xscale
				local dy = (posy - 4) * yscale
				posx = 8 + dx*cos(rotrad) - dy*sin(rotrad) + xdelta
				posy = 4 + dx*sin(rotrad) + dy*cos(rotrad) + ydelta
			end
			pos.x = posx * 112.5
			pos.y = posy * 112.5 + 90
			pos.w = 0
		end
		ArCamera(cam)
	else
		for i=1, #hints do
			hints[i].x = hints[i].x * 112.5
			hints[i].y = hints[i].y * 112.5 + 90
			hints[i].w = 0
		end
	end

	-- Loads the Object Group, with Disable/Enable Messages.
	local currenthash = 0

	local w = self.Wgo
	local typ = hash(tostr(Ar__current_song_id))
	for i=1,#w do
		currenthash = spawn_from(ArcWish)
		parent(currenthash, self_url)
		currenthash = url(Ar, currenthash, hash_sprite)
		playflp(currenthash, typ)
		send(currenthash, hash_disable)
		w[i] = currenthash
	end

	local h = self.Hgo
	for i=1,#h do
		currenthash = spawn_from(ArcHint)
		parent(currenthash, self_url)
		currenthash = url(Ar, currenthash, hash_sprite)
		if Ar__expand_hints then
			scale(1.37, currenthash)
		end
		send(currenthash, hash_disable)
		h[i] = currenthash
	end

	if self.play_animation then
		local a = self.Ago
		for i=1,#a do
			currenthash = spawn_from(ArcAnim)
			parent(currenthash, self_url)
			send(currenthash, hash_disable)
			a[i] = currenthash
		end
	end

	-- Update: Loads UI Nodes.
	if self.options then
		self.options = spawn_from(Options)
	elseif self.fumen_id < 2 then
		self.exit = spawn_from(Exit)
	end

end


local daymode = false
local hash_ar_judge = hash("ar_judge")
local hash_ar_sound_speed = hash("ar_sound_speed")
local hash_ar_show_options = hash("ar_show_options")
local hash_ar_hide_options = hash("ar_hide_options")
local hash_ar_toggle_daymode = hash("ar_toggle_daymode")
local hash_ar_update_time = hash("ar_update_time")
function on_message(self, message_id, message, _sender)
	--
	-- Hint(x,y,z,w)
	-- z: Target Hit Time(ms)
	-- w:
	--	 (-inf, -1) Lit, Judged
	--	 -1 Lit, NonJudged
	--	 0 Nonlit, NonJudged
	--	 1 Nonhit Lost(Sweeped)
	--	 (1, +inf) Judged
	--
	if message_id==hash_ar_judge then

		-- Preparations.
		--
		local spd, origtime = self.sound_speed, message[1]
		local itime = (origtime - Ar__init_time - Ar__paused_time)*spd - Ar__audio_delay + Ar__input_delay
		if itime<2 then itime=2 end

		-- Optimization for Multiple ArPlay Instances.
		--
		if itime>=self.Init and itime<self.End then
			local current_index_group = floor(itime/self.index_scale) + 1
			if current_index_group < 1 then current_index_group = 1 end

			local touch = message
			local hindex = self.Hindex
			local target = false
			-- local g1 = hindex[current_index_group-1]
			-- local g2 = hindex[current_index_group]
			-- local g3 = hindex[current_index_group+1]
			local hint = self.Hint
			local chid = false
			local chint = false
			
			local selfx = 0
			if self.options then
				selfx = self_pos().x
			end

			-- Clear the Cache of "has_touch_near" Function, for Optimization Usage.
			--
			-- has_touch_near()
			has_hint_judged = false
			--
			----

			-- Light&Delit Hints, then Judge.
			--
			if touch[2] then
				--
				local mint, dt, chz, chw = 0
				safe()
				--
				--------  Judge Start  --------
				for t=-1,1 do
					target = hindex[current_index_group+t]
					if (target) and #target~=0 then
						for i=1,#target do
							chid = target[i]
							chint = hint[chid]
							chz = chint.z
							chw = chint.w

							-- Asserted to be Sorted
							dt = (itime - chz) / spd
							if dt <- SWEEP then break end

							local htn = has_touch_near(chint.x, chint.y, touch, selfx)
							if chw == 0 or chw == -1 then
								if htn then
									chint.w = -1
									chw = -1
								else
									chint.w = 0
								end
							elseif (chw < -1) and not htn then
								chint.w = -chw
							end

							if chw == -1 and dt<SWEEP then
								
								local issafe = safe(chint.x, chint.y)  -- Must Register the Current Pivot.
								if mint == 0 or mint == chz then
									
									if mint==0 then mint=chz end
									has_hint_judged = true
									chint.w = -itime
									
									if dt<HITZONE and dt>-HITZONE then Ar__current_score = Ar__current_score + 1
									else Ar__current_lost = Ar__current_lost + 1
									end									
									
								elseif dt<HITZONE and dt>-HITZONE and issafe then
									Ar__current_score = Ar__current_score + 1
									has_hint_judged = true
									chint.w = -itime
								end
								
							end
						end
					end
				end
				--------  Judge Complete  --------
				if has_hint_judged and haptics_supported and Ar__haptics then
					if origtime-last_vibration_time <= 37 then
					else last_vibration_time = origtime
						if iosh then hapticsfunc(iosh)
						else hapticsfunc()
						end
					end
				end
			else
				for t=-1,1 do
					target = hindex[current_index_group+t]
					local dt, chz, chw
					if (target) and #target~=0 then
						for i=1,#target do
							
							chid = target[i]
							chint = hint[chid]
							chz = chint.z
							chw = chint.w

							-- Asserted to be Sorted
							dt = (itime - chz) / spd
							if dt <- SWEEP then break end
							
							local htn = has_touch_near(chint.x, chint.y, touch, selfx)
							if chw==0 or chw==-1 then
								if htn then chint.w = -1
								else chint.w = 0
								end
							elseif (chw < -1) and not htn then chint.w = -chw
							end
							
						end
					end
				end
			end
		end
	elseif message_id==hash_ar_update_time then
		self.arloc = false
	elseif message_id==hash_ar_toggle_daymode and self.fumen_id<2 then
		if daymode then
			HIT = HITCOMMON
			if Ar__play_animation then send(self.Ago[1], hash_ar_toggle_daymode) end
			daymode = false
		else
			HIT = HITDAY
			if Ar__play_animation then send(self.Ago[1], hash_ar_toggle_daymode) end
			daymode = true
		end
	elseif message_id==hash_ar_sound_speed then
		local last_spd = self.sound_speed
		local spd = message[1] or 1; if spd<0.2 or spd>=3 then spd=1 end
		if self.fumen_id<2 then
			set(Ar__current_sound, hash_sound_speed, spd)
			Ar__paused_time = Ar__paused_time + (self.arloc or 0)*(spd-last_spd)/spd
		end
		self.sound_speed = spd
		self.arloc = false
	elseif self.options then
		if message_id == hash_ar_show_options then
			goanimc(self.url, hash_px)
			animg(self.url, hash_px, PLAYBACK, -337.5, EASE_EXPAND, OPTANIM_LENGTH)
		elseif message_id == hash_ar_hide_options then
			goanimc(self.url, hash_px)
			animg(self.url, hash_px, PLAYBACK, 0, EASE_CLOSE, OPTANIM_LENGTH)
		end
	end
end


local frame_limit_gc = 0
local time = socket.gettime
local last_culled,last_hgo,last_ago = 0,0,0
local last_score,last_losts,last_string = false,false,""
local last_vec = { {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }
local lvls = { {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }
function update(self, tslf)
	if Ar__active and (not Ar__focuslost) then

		-- Obtains the Time Variables.
		-- Ar__time: A Global Variable Updated in the Render Script, As an Endeavor to Make the Timestep Stable.
		-- tslf: Time Since Last Frame. There are lots of "dt" used below.

		if self.arloc then self.arloc = self.arloc + tslf*1000
		else self.arloc = time()*1000 - Ar__init_time - Ar__paused_time
		end
		
		local spd = self.sound_speed
		local progress = self.arloc*spd - Ar__audio_delay
		-- local progress = ( Ar__time + tslf*1000 )*spd - Ar__audio_delay
		if progress >= self.End then
			del()
		elseif progress >= self.Init then
			
			----------------  GAME LOGICS  ----------------

			-- Sets the Current Index Group.
			local current_index_group = 0
			current_index_group = floor(progress/self.index_scale) + 1
			if current_index_group < 1 then current_index_group = 1 end

			-- Transfers a Vector Group.
			local vecs = self.Vecs
			local tints = self.Tints

			-- Draws Wishes.
			local wgo = self.Wgo
			local ip_index = 1  -- Tracks How Many Wishes are Interpolated.
			local culled_index = 1  -- Tracks How Many Wishes Should be Drawed.
			
			if self.DTime then
				
				local zip1 = 2
				for zi = 1,16 do
					if self.has[zi] then

						zip1 = zi+1
						local dtime = ArDTime(self.DTime, progress, zi)

						if dtime < 2 then dtime = 2 end
						local dgroup = floor(dtime/self.index_scale) + 1
						if dgroup < 1 then dgroup = 1 end

						if (self.Windex[dgroup]) and #self.Windex[dgroup] ~= 0 then
							--
							-- I.Interpolate the Positions, Append them after the Repetition Detection.
							--
							local group_id = 0  -- the Index of Current Wish Group.
							local current_wish = 0
							local current_x0 = 0
							local current_y0 = 0
							local current_t0 = 0
							local current_dx = 0
							local current_dy = 0
							local current_dt = 0
							local current_type = 0
							local interpolate_ratio = 0

							local current_indexes = self.Windex[dgroup]
							for i=1, #current_indexes do
								group_id = current_indexes[i]
								--
								-- Group Scale
								-- A.Interpolate
								--
								current_wish = self.Wish[group_id]
								local current_wish_len = #current_wish
								local wish_interpolated = false
								if current_wish_len > 3 and current_wish[2] >= zi and current_wish[2] < zip1 then
									--
									-- Node Scale
									--

									-- DTime: Poll Progress Guard
									local poll_progress = current_wish[1]
									while poll_progress>3 and current_wish[poll_progress].z > dtime do
										poll_progress = poll_progress-1
									end

									while poll_progress ~= current_wish_len and not wish_interpolated do
										if current_wish[poll_progress].z <= dtime and current_wish[poll_progress+1].z > dtime then
											current_x0 = current_wish[poll_progress].x
											current_y0 = current_wish[poll_progress].y
											current_t0 = current_wish[poll_progress].z
											current_type = current_wish[poll_progress].w
											current_dx = current_wish[poll_progress+1].x - current_x0
											current_dy = current_wish[poll_progress+1].y - current_y0
											current_dt = current_wish[poll_progress+1].z - current_t0
											interpolate_ratio = (dtime-current_t0) / current_dt
											if current_type == 0 then
												current_interpolated.x = current_x0 + current_dx*interpolate_ratio
												current_interpolated.y = current_y0 + current_dy*interpolate_ratio
											else
												local typex = 0
												local typey = 0
												-- typex,typey = intfrac(current_type)
												-- typey = floor( typey*10 + 0.5 )
												typex = floor(current_type/10)
												typey = current_type%10
												current_interpolated.x = current_x0 + current_dx*ease(interpolate_ratio, typex)
												current_interpolated.y = current_y0 + current_dy*ease(interpolate_ratio, typey)
											end

											-- Update: Set Z and Hint.
											--
											current_interpolated.z = current_wish[2]
											if poll_progress == 3 then
												if interpolate_ratio <= 0.237 then
													current_interpolated.w = 2 + interpolate_ratio
												else
													current_interpolated.w = 0
												end
											elseif poll_progress == current_wish_len-1 and interpolate_ratio >= 0.763 then
												current_interpolated.w = -2 - interpolate_ratio
											else
												current_interpolated.w = 0
											end

											wish_interpolated = true
											current_wish[1] = poll_progress
										else
											poll_progress = poll_progress + 1
										end
									end
								end

								if wish_interpolated then
									local _x, _y, _z = current_interpolated.x, current_interpolated.y, current_interpolated.z
									local _lastvec, _lvls, _lvl = last_vec[zi], lvls[zi]
									--
									-- B.Appending for Initial Condition.
									--
									if ip_index == 1 then
										vecs[1].x, vecs[1].y, vecs[1].z = _x, _y, _z
										tints[1] = current_interpolated.w
		
										_lvl = floor(_x*109)+floor(_y*113)
										_lastvec[_lvl] = 1
										_lvls[1] = _lvl

										ip_index = 2
									-- 
									-- C.Appending after Other Wishes.
									--
									else
										_lvl = floor(_x*109)+floor(_y*113)
										local _lv = _lastvec[_lvl]

										if _lv then tints[_lv] = 0
										else

											vecs[ip_index].x, vecs[ip_index].y, vecs[ip_index].z = _x, _y, _z
											tints[ip_index] = current_interpolated.w

											_lastvec[_lvl] = ip_index
											_lvls[#_lvls+1] = _lvl
											ip_index = ip_index + 1

										end
									end
								end
							end
						end
					end
				end
			else
				if (self.Windex[current_index_group]) and #self.Windex[current_index_group] ~= 0 then
					--
					-- I.Interpolate the Positions, Append them after the Repetition Detection.
					--
					
					local group_id = 0  -- the Index of Current Wish Group.
					local current_wish = 0
					local current_x0 = 0
					local current_y0 = 0
					local current_t0 = 0
					local current_dx = 0
					local current_dy = 0
					local current_dt = 0
					local current_type = 0
					local interpolate_ratio = 0

					local current_indexes = self.Windex[current_index_group]
					for i=1, #current_indexes do
						group_id = current_indexes[i]
						--
						-- Group Scale
						-- A.Interpolate
						--
						current_wish = self.Wish[group_id]
						local current_wish_len = #current_wish
						local wish_interpolated = false
						if current_wish_len > 3 then
							--
							-- Node Scale
							--
							
							-- Poll Progress Guard
							local poll_progress = current_wish[1]
							while poll_progress>3 and current_wish[poll_progress].z > progress do
								poll_progress = poll_progress-1
							end
							
							while poll_progress ~= current_wish_len and not wish_interpolated do
								if current_wish[poll_progress].z <= progress and current_wish[poll_progress+1].z > progress then
									current_x0 = current_wish[poll_progress].x
									current_y0 = current_wish[poll_progress].y
									current_t0 = current_wish[poll_progress].z
									current_type = current_wish[poll_progress].w
									current_dx = current_wish[poll_progress+1].x - current_x0
									current_dy = current_wish[poll_progress+1].y - current_y0
									current_dt = current_wish[poll_progress+1].z - current_t0
									interpolate_ratio = (progress-current_t0) / current_dt
									if current_type == 0 then
										current_interpolated.x = current_x0 + current_dx*interpolate_ratio
										current_interpolated.y = current_y0 + current_dy*interpolate_ratio
									else
										local typex = 0
										local typey = 0
										-- typex,typey = intfrac(current_type)
										-- typey = floor( typey*10 + 0.5 )
										typex = floor(current_type/10)
										typey = current_type%10
										current_interpolated.x = current_x0 + current_dx*ease(interpolate_ratio, typex)
										current_interpolated.y = current_y0 + current_dy*ease(interpolate_ratio, typey)
									end

									-- Update: Set Z and Hint.
									--
									current_interpolated.z = current_wish[2]
									if poll_progress == 3 then
										if interpolate_ratio <= 0.237 then
											current_interpolated.w = 2 + interpolate_ratio
										else
											current_interpolated.w = 0
										end
									elseif poll_progress == current_wish_len-1 and interpolate_ratio >= 0.763 then
										current_interpolated.w = -2 - interpolate_ratio
									else
										current_interpolated.w = 0
									end

									wish_interpolated = true
									current_wish[1] = poll_progress
								else
									poll_progress = poll_progress + 1
								end
							end
						end

						if wish_interpolated then
							local _x, _y, _z = current_interpolated.x, current_interpolated.y, current_interpolated.z
							local _zl = floor(_z)
							local _lastvec, _lvls, _lvl = last_vec[_zl], lvls[_zl]
							--
							-- B.Appending for Initial Condition.
							--
							if ip_index == 1 then
								vecs[1].x, vecs[1].y, vecs[1].z = _x, _y, _z
								tints[1] = current_interpolated.w

								_lvl = floor(_x*109)+floor(_y*113)
								_lastvec[_lvl] = 1
								_lvls[1] = _lvl

								ip_index = 2
							-- 
							-- C.Appending after Other Wishes.
							--
							else
								_lvl = floor(_x*109)+floor(_y*113)
								local _lv = _lastvec[_lvl]

								if _lv then tints[_lv] = 0
								else

									vecs[ip_index].x, vecs[ip_index].y, vecs[ip_index].z = _x, _y, _z
									tints[ip_index] = current_interpolated.w

									_lastvec[_lvl] = ip_index
									_lvls[#_lvls+1] = _lvl
									ip_index = ip_index + 1

								end
							end
						end
					end
				end
			end
			--
			-- Cleanup.
			--
			for ly = 1,16 do
				local _lv, _lvls = last_vec[ly], lvls[ly]
				for it = 1, #_lvls do
					_lv[ _lvls[it] ] = nil
					_lvls[it] = nil
				end
			end
			--
			-- II.Do Tranformations with Camera Parameters.
			--
			local cam = self.Camera
			for i=1, ip_index-1 do

				local pos = vecs[i]
				local ctint = tints[i]

				if cam then
					-- Camera Configuration for Current Frame.
					local xscale = 1
					local yscale = 1
					local rotrad = 0
					local xdelta = 0
					local ydelta = 0
					xscale,yscale,rotrad,xdelta,ydelta = ArCamera(cam, progress, pos.z)
					-- Transformation.
					if rotrad > -0.01 and rotrad < 0.01 then
						pos.x = 8 + (pos.x - 8) * xscale + xdelta
						pos.y = 4 + (pos.y - 4) * yscale + ydelta
					else
						local dx = (pos.x - 8) * xscale
						local dy = (pos.y - 4) * yscale
						pos.x = 8 + dx*cos(rotrad) - dy*sin(rotrad) + xdelta
						pos.y = 4 + dx*sin(rotrad) + dy*cos(rotrad) + ydelta
					end
				end
				pos.x = pos.x * 112.5
				pos.y = pos.y * 112.5 + 90
				if pos.x >= 66 and pos.x <= 1734 and pos.y >= 66 and pos.y <= 1014 then

					_,pos.z = intfrac(pos.z)
					local currenthash_wish = wgo[culled_index]

					--
					-- Update: Simple Tint&Scale Effect for Wishes.
					-- InQuart: easecalc = ratio*ratio; return ( easecalc*easecalc )
					-- OutQuart: easecalc = 1 - ratio; easecalc = easecalc*easecalc; return ( 1 - easecalc*easecalc )
					--
					local tintw = 1
					local expand_wish = 1
					if ctint >=2 then
						tintw = ctint - 2
						tintw = 1 - tintw / 0.237
						expand_wish = 1 + tintw*tintw/2
						tintw = 1 - tintw*tintw*tintw
					elseif ctint <=-2 then
						tintw = 3 + ctint
						tintw = tintw / 0.237
						tintw = tintw*tintw*tintw
					end
					set(currenthash_wish, hash_tintw, tintw)
					scale(expand_wish, currenthash_wish)
					--
					--

					set_position(pos, currenthash_wish)
					if culled_index>last_culled then send(currenthash_wish, hash_enable) end
					culled_index = culled_index + 1

				end
			end
			--
			-- Hide Unused WishGos.
			--
			if culled_index-1 < last_culled then
				for i=culled_index, last_culled do
					send(wgo[i], hash_disable)
				end
			end
			last_culled = culled_index - 1
			--
			-- Hint Related Preparations.
			--
			local hindex = self.Hindex
			local hint = self.Hint
			local target = false
			local chid = false
			local chint = false
			local dt = 0
			local pt = 0
			--
			-- Sweep Nonhit Losts, And Draw Hints&Anims.
			--
			local hgo = self.Hgo
			local hgo_index = 1
			local ago = false
			local ago_index = 1
			if self.play_animation then
				ago = self.Ago
			end
			--
			for g=-1,1 do
				target = hindex[current_index_group+g]
				if (target) and #target~=0 then
					for i=1,#target do
						chid = target[i]
						chint = hint[chid]
						dt = (progress - chint.z)/spd
						--
						if dt>SWEEP and (chint.w==0 or chint.w==-1) then
							chint.w = 1
							Ar__current_lost = Ar__current_lost + 1
						elseif dt<-510 then break
						end
						--
						local thisgo = false
						if dt<370 and dt>=-370 then
							--
							vecs[i].x = chint.x
							vecs[i].y = chint.y
							--
							if chint.w==0 then
								vecs[i].z = -0.74
								thisgo = hgo[hgo_index]
								set_position(vecs[i], thisgo)
								set(thisgo, hash_tint, DELIT)
								if hgo_index>last_hgo then send(thisgo, hash_enable) end
								hgo_index = hgo_index + 1
							elseif chint.w==-1 then
								vecs[i].z = -0.73
								thisgo = hgo[hgo_index]
								set_position(vecs[i], thisgo)
								set(thisgo, hash_tint, NJLIT)
								if hgo_index>last_hgo then send(thisgo, hash_enable) end
								hgo_index = hgo_index + 1
							elseif chint.w<-1 then
								vecs[i].z = -0.71
								thisgo = hgo[hgo_index]
								set_position(vecs[i], thisgo)
								if hgo_index>last_hgo then send(thisgo, hash_enable) end
								hgo_index = hgo_index + 1

								-- Show Early/Late on Hint.
								dt = ( -chint.w - chint.z )/spd
								if dt<HITZONE and dt>-HITZONE then
									set(thisgo, hash_tint, HIT)
								elseif dt>=HITZONE then
									set(thisgo, hash_tint, LAT)
								else
									set(thisgo, hash_tint, EAR)
								end

							elseif chint.w==1 then
								vecs[i].z = -0.72+dt*0.00001
								thisgo = hgo[hgo_index]
								set_position(vecs[i], thisgo)
								set(thisgo, hash_tint, hintlost(dt) )
								if hgo_index>last_hgo then send(thisgo, hash_enable) end
								hgo_index = hgo_index + 1
							elseif ago and chint.w>1 then
								pt = (progress-chint.w) / spd
								vecs[i].z = -0.7 - pt*0.00001
								thisgo = ago[ago_index]
								set_position(vecs[i], thisgo)
								send(thisgo, hash_ar_update, { pt, (chint.w-chint.z)/spd } )
								ago_index = ago_index + 1
							end
						elseif ago and dt<510 and chint.w>1 then
							
							pt = (progress-chint.w) / spd

							vecs[i].x = chint.x
							vecs[i].y = chint.y
							vecs[i].z = -0.7 - pt*0.00001

							thisgo = ago[ago_index]
							set_position(vecs[i], thisgo)
							send(thisgo, hash_ar_update, { (progress-chint.w)/spd, (chint.w-chint.z)/spd } )
							ago_index = ago_index + 1
						elseif dt<-370 then
							vecs[i].x = chint.x
							vecs[i].y = chint.y
							vecs[i].z = -0.75 - dt*0.00001

							thisgo = hgo[hgo_index]
							set_position(vecs[i], thisgo)
							set(thisgo, hash_tint, hintinit(dt) )
							if hgo_index>last_hgo then send(thisgo, hash_enable) end
							hgo_index = hgo_index + 1
						end
					end
				end
			end
			--
			-- Hide Unused HintGos and AnimGos.
			--
			if hgo_index-1 < last_hgo then
				for i=hgo_index, last_hgo do
					send(hgo[i], hash_disable)
				end
			end
			if (ago) and ago_index-1 < last_ago then
				for i=ago_index, last_ago do
					send(ago[i], hash_ar_disable)
				end
			end
			last_hgo = hgo_index - 1
			last_ago = ago_index - 1
			--
			-- Update ArIf, Do GC.
			--
			if self.fumen_id < 2 then

				local show_score = true
				if Ar__current_score == 0 and Ar__current_lost == 0 then show_score = false end
				
				if self.ArIf then
					
					local _if = self.ArIf
					local _ifsize = #_if
					local _ifsm1 = _ifsize-1

					local prg = _if[1]
					local text = _if[_ifsize]

					if prg==_ifsm1 then
						if text then show_score = false end
					elseif progress>=_if[_ifsm1] then
						if text then show_score = false; label_set_text(ArIf, text)
						else label_set_text(ArIf, last_string)
						end _if[1] = _ifsm1
					elseif progress>=_if[2] then
						
						while prg>2 and progress<_if[prg] do prg=prg-2 end
						for i=prg,_ifsize-3,2 do
							if progress>=_if[i] and progress<_if[i+2] then
								prg = i
								text = _if[i+1]
								
								if text then
									show_score = false
									if prg ~= last_arif_progress then label_set_text(ArIf, text) end
								elseif prg ~= last_arif_progress and _if[i-1] then
									label_set_text(ArIf, last_string)
								end
								
								break
							end
						end

						_if[1] = prg
						last_arif_progress = prg
						
					end
				end

				if show_score then
					if Ar__current_score == last_score and Ar__current_lost == last_losts then
					else
						if Ar__current_score == Ar__current_total_hints then
							last_string = fmt(fmt_score_max,Ar__current_score)
						elseif self.display_losts then
							last_string = fmt(fmt_score_and_lost,Ar__current_score,Ar__current_lost)
						else
							last_string = fmt(fmt_score,Ar__current_score)
						end
						last_score = Ar__current_score
						last_losts = Ar__current_lost
						label_set_text(ArIf, last_string)
					end
				end

				if frame_limit_gc < 4 then
					frame_limit_gc = frame_limit_gc + 1
				else
					frame_limit_gc = 0
					gc(str_step)
				end

			end
			----------------  GAME LOGICS  ----------------
		end
	end
end


function final(self)

	-- Update: Calculate Remainging Losts.
	if self.remove_branch or Ar__current_score == Ar__current_total_hints then
	elseif self.display_losts then
		
		local final_lost_counter = 0
		local hint = self.Hint
		
		local hw = 0
		for i=1,#hint do
			hw = hint[i].w
			if hw == 0 or hw==-1 then final_lost_counter = final_lost_counter+1 end
		end
		
		Ar__current_lost = Ar__current_lost+final_lost_counter
		label_set_text(ArIf, fmt(fmt_score_and_lost,Ar__current_score,Ar__current_lost) )
		
	end
	
	if self.fumen_id == 0 then
		Ar__arplays[1], Ar__arplays[2], Ar__arplays[3] = 0,0,nil
		Ar__current_total_hints = 0
	else
		Ar__arplays[1] = Ar__arplays[1] - 1
		Ar__arplays[self.fumen_id+2] = nil
		Ar__current_total_hints = Ar__current_total_hints - self.totalhints
		if Ar__arplays[1] == 0 then Ar__arplays[2] = 0 end		
	end

	-- Self Sweeping.
	local target = false
	if self.Wgo then
		target = self.Wgo
		for i=1,#target do target[i] = target[i].path end
		del(target)
		self.Wgo = nil
	end
	if self.Hgo then
		target = self.Hgo
		for i=1,#target do target[i] = target[i].path end
		del(target)
		self.Hgo = nil
	end
	if (self.play_animation) and self.Ago then
		del(self.Ago)
		self.Ago = nil
	end

	-- UINode Sweeping.
	if self.options then
		send(self.options, hash_ar_ui_final)
		self.options = nil
	elseif self.exit then
		send(self.exit, hash_ar_ui_final)
		self.exit = nil
	end
	
	-- For Demo Usage Only.
	gc()
	gc("restart")
end
