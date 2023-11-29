-- Aerials/Pragma/ArInput.script

local hash = hash
local post = msg.post
local v3 = vmath.vector3
local time = socket.gettime
local del = go.delete

local hash_touch = hash("touch")
local hash_touch_multi = hash("touch_multi")
local hash_ar_judge = hash("ar_judge")
local hash_ar_uitouch = hash("ar_uitouch")
local hash_ar_subtouch = hash("ar_subtouch")

-- x,y,z.
-- z==0 for invalid
-- z==1 for pressed
-- z==2 for moving
-- z==-1 for released
local current = false
local uitouchxyz = {0,0}

local not_pressed = false
local not_released = false
local has_touch_pressed = false
local has_touch_released = false

local cx = 0
local cy = 0
local cv = 0
local cid = 0
local msglen = 4

local aru = false
local arp = false

local function multitouch(self, action_id, action)
	if Ar__focuslost then
	elseif action_id==hash_touch_multi then

		-- Initialize.
		--
		local touch = action.touch
		local touchti = false
		
		has_touch_pressed = false
		cx,cy,cv = Ar__center_x,Ar__center_y,Ar__posdiv

		msglen = #touch
		for ti = 1, msglen do
			
			touchti = touch[ti]
			cid = touchti.id + 5

			if cid>current[4] then
				current[4] = cid
				current[cid] = v3()
			end

			current[cid].x = 900 + (touchti.screen_x - cx) / cv
			current[cid].y = 540 + (touchti.screen_y - cy) / cv
			not_pressed = not touchti.pressed
			not_released = not touchti.released
			
			if not_pressed and not_released then
				current[cid].z = 2
			elseif not_released then
				current[cid].z = 1
				has_touch_pressed = true
			else
				current[cid].z = -1
				has_touch_released = true
			end
			
		end

		for i = msglen+5, current[4] do current[i].z=0 end
		-- Upload to ArPlays (if there is)
		--
		
		if arp[1] > 0 then	
			current[1] = time()*1000
			current[2] = has_touch_pressed
			current[3] = has_touch_released
			for i=3, arp[2] do
				if arp[i] then
					post(arp[i], hash_ar_judge, current)
				end
			end	
		else
			arp[2] = 3
		end

		
		-- Upload to UINodes (if there is)
		-- UI Touches will be comsumed by the last UI Node.
		--
		local uitouch = current[5]		
		if uitouch.z~=0 and aru[1]>0 then
			
			local last = true
			uitouchxyz[1] = uitouch.x
			uitouchxyz[2] = uitouch.y
			uitouchxyz[3] = uitouch.z
			
			for i=aru[2], 3, -1 do
				if aru[i] then
					if last then
						post(aru[i], hash_ar_uitouch, uitouchxyz)
						last = false
					else
						post(aru[i], hash_ar_subtouch, uitouchxyz)
					end
				end
			end
			
		elseif afu[1]==0 then
			aru[2] = 3
		end
		
	end
end

local curx = 0
local cury = 0
local curz = 0
local function cursor(self, action_id, action)
	if Ar__focuslost then
	elseif action_id==hash_touch then

		
		current[2] = false
		current[3] = false
		cx,cy,cv = Ar__center_x,Ar__center_y,Ar__posdiv

		
		-- Status Check
		--
		not_pressed = not action.pressed
		not_released = not action.released
		curx = 900 + (action.screen_x - Ar__center_x) / Ar__posdiv
		cury = 540 + (action.screen_y - Ar__center_y) / Ar__posdiv
		if not_pressed and not_released then
			curz = 2
		elseif not_released then
			curz = 1
			current[2] = true
		else
			curz = -1
			current[3] = true
		end

		
		-- Upload to ArPlays (if there is)
		--
		if arp[1] > 0 then
			current[1] = time()*1000
			current[5].x = curx
			current[5].y = cury
			current[5].z = curz
			for i=3, arp[2] do
				if arp[i] then
					post(arp[i], hash_ar_judge, current)
				end
			end		
		else
			arp[2] = 3
		end

		
		-- Upload to UINodes (if there is)
		-- UI Touches will be comsumed by the last UI Node.
		--
		if aru[1]>0 then
			
			local last = true
			uitouchxyz[1] = curx
			uitouchxyz[2] = cury
			uitouchxyz[3] = curz
			
			for i=aru[2], 3, -1 do
				if aru[i] then
					if last then
						post(aru[i], hash_ar_uitouch, uitouchxyz)
						last = false
					else
						post(aru[i], hash_ar_subtouch, uitouchxyz)
					end
				end
			end
			
		else
			aru[2] = 3
		end
		
	end
end


if Ar__mobile then
	current = {
		-- Input Time, Any Pressed, Any Released, Table Length
		0, false, false, 9,
		-- Touches.
		v3(),v3(),v3(),v3(),v3()
	}
	on_input = multitouch
else
	current = {0, false, false, 5, v3()}
	on_input = cursor
end

function init(self)
	if Ar__init_error then del()
	else
		post("#", "acquire_input_focus")
		arp = Ar__arplays
		aru = Ar__uinodes
	end
end