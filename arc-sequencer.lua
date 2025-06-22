-- 3Circles
-- a three-voice looping sampler with arc control
-- for norns


lfo = require 'lfo'
-- local util = require 'util'


-- script state
voices = {} -- table to hold state for our three voices
local focused_voice = 1

-- Hardcoded audio file paths
-- audio_file = "/home/we/dust/audio/mofongo/vibes-loops/clarinet-vibes-loops.wav"
audio_file = _path.dust.."audio/mofongo/clarinet-vibes-loops.wav"

local Arcify = include("lib/arcify")
local arcify = Arcify.new()

function init()
  -- create state for each voice
  --myarc = arc.connect()
  print_info(audio_file)
  softcut.buffer_clear()
  softcut.buffer_read_stereo(audio_file, 0, 0, -1, 1, 1)



  for i = 1, 3 do
    voices[i] = {
      file = audio_file,
      -- these are stored as normalized values (0 to 1)
      loop_start_norm = 0,
      loop_end_norm = 1,
    }
    voices[i].mylfo = lfo:add{
      shape = 'random',
      min = 0, -- LFO modulates from silent
      max = 1, -- to full volume
      depth = .5,
      period = .5, -- default to a slow rate (frequency in Hz)
      action = function(scaled, raw) softcut.position(i, raw) end
    }
    voices[i].mylfo:start()
    -- configure softcut for each voice
    softcut.enable(i, 1)
    softcut.buffer(i, 2)
    softcut.loop(i, 1)
    softcut.position(i, 0)
    softcut.level(i, 1.0) -- Start with full volume, LFO will modulate it
    softcut.play(i, 1)
    -- Set initial loop points in seconds after buffer is loaded
    softcut.loop_start(i, 0)
    softcut.loop_end(i, 2)
    -- configure LFO for each voic
  end -- set up voices and softcut parameters




    -- 
  
  
    params:add {
        type = "control",
        id = "Loop 1 Start",
        name = "Start",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 0.5),
        action = function(value)
            softcut.loop_start(1, value)
            redraw()
        end
    }
    params:add {
        type = "control",
        id = "Loop 1 End",
        name = "End",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 0.5),
        action = function(value)
           softcut.loop_end(1, value)
            redraw()
        end
    }
    params:add {
        type = "control",
        id = "Loop 2 Start",
        name = "Start",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 0.5),
        action = function(value)
            softcut.loop_start(2, value)
            redraw()
        end
    }
    params:add {
        type = "control",
        id = "Loop 2 End",
        name = "End",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 0.5),
        action = function(value)
           softcut.loop_end(2, value)
            redraw()
        end
    }
    params:add {
        type = "control",
        id = "Loop 3 Start",
        name = "Start",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 0.5),
        action = function(value)
            softcut.loop_start(3, value)
            redraw()
        end
    }
    params:add {
        type = "control",
        id = "Loop 3 End",
        name = "End",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 0.5),
        action = function(value)
           softcut.loop_end(3, value)
            redraw()
        end
    }
    -- register parameters with arcify
    arcify:register("Loop 1 Start", 0.01)
    arcify:register("Loop 1 End", 0.01)
    arcify:register("Loop 2 Start", 0.01)
    arcify:register("Loop 2 End", 0.01)
    arcify:register("Loop 3 Start", 0.01)
    arcify:register("Loop 3 End", 0.01)

    -- after registering all your params run add_params()
    -- to make them visible in norns params menu
    arcify:add_params()
    
    --temp hacks
    softcut.level(3,0)
    -- softcut.level(2,0)
    softcut.pan(1,-.5)
    softcut.pan(2,.5)
end


focused_voice = 1

-- handle key presses
function key(n, z)
  if n == 2 and z == 1 then
    focused_voice = (focused_voice % 3) + 1
    redraw()
    arc_refresh()
    print("key 2 pressed, focused voice: " .. focused_voice)
  end
end

-- handle arc encoder turns
-- function myarc(n, d)
--   local voice = voices[focused_voice]
--   local sc_voice = focused_voice
--   local redraw_all = false

--   -- scale encoder sensitivity
--   d = d / 150

--   if n == 1 then -- loop start
--     voice.loop_start_norm = util.clamp(voice.loop_start_norm + d, 0, voice.loop_end_norm)
--     -- *** FIX: convert normalized value to seconds for softcut ***
--     softcut.loop_start(sc_voice, voice.loop_start_norm * 2)
--     redraw_all = true
--   elseif n == 2 then -- loop end
--     voice.loop_end_norm = util.clamp(voice.loop_end_norm + d, voice.loop_start_norm, 1)
--     -- *** FIX: convert normalized value to seconds for softcut ***
--     softcut.loop_end(sc_voice, voice.loop_end_norm * 2)
--     redraw_all = true
--   elseif n == 3 then -- lfo speed (frequency)
--     -- use a logarithmic scale for more musical control over frequency
--     local current_freq = voice.lfo.freq
--     voice.lfo.freq = util.clamp(current_freq * (1 + (d * 2)), 0.01, 20)
--     redraw_all = true
--   end

--   if redraw_all then
--     redraw()
--     -- arc_refresh()
--   end
-- end

-- function to update all arc leds based on state


-- old redraw function
-- function redraw()
--   screen.clear()
--   screen.aa(0)
--   screen.line_width(1)
--   screen.text("active voice>" .. focused_voice)

--   -- draw info for each voice
--   for i = 1, 3 do
--     local y_pos = 10 + ((i - 1) * 16)
--     -- local file_name = voices[i].file:match("([^/]+)$") or "..."
--     local lfo_freq_formatted = string.format("%.2f", voices[i].lfo.freq)

--     -- highlight focused voice
--     if i == focused_voice then
--       screen.level(15)
--       screen.rect(0, y_pos - 8, 128, 14):fill()
--       screen.level(0)
--       screen.move(3, y_pos)
--       screen.text(">" .. i .. ": " .. i)
--       screen.level(15)
--       screen.move(125, y_pos)
--       screen.text_right(lfo_freq_formatted .. "hz")
--     else
--       screen.level(6)
--       screen.move(3, y_pos)
--       screen.text(" " .. i .. ": " .. i)
--       screen.move(125, y_pos)
--       screen.text_right(lfo_freq_formatted .. "hz")
--     end
--   end

--   screen.update()
-- end

-- -- cleanup on script removal
-- function cleanup()
--   for i=1,3 do
--     if voices[i] and voices[i].lfo then voices[i].lfo:stop() end
--   end
--   arc.cleanup()
-- end

function arc_key(z)
	if z == 1 then
		km = metro.new(key_timer,500,1)
	elseif km then
		--print("keyshort")
		metro.stop(km)
		mode = mode + 1
		if mode==8 then mode=2 end
		ps("mode: %s",modetext[mode])
	else
		--print("friction off")
		f = 1
	end
end

function key_timer()
	--print("keylong!")
	metro.stop(km)
	km = nil
	if mode ~= 1 then
		mode = 1 
		pset_write(1,c)
	end
	f = friction
end
function redraw()
  screen.clear()
  screen.level(3)
  screen.font_face(10)
  screen.font_size(10)
  screen.move(0,50)
  screen.text("active voice>" .. focused_voice)
  screen.update()
end

function print_info(file)
  if util.file_exists(file) == true then
    local ch, samples, samplerate = audio.file_info(file)
    local duration = samples/samplerate
    print("loading file: "..file)
    print("  channels:\t"..ch)
    print("  samples:\t"..samples)
    print("  sample rate:\t"..samplerate.."hz")
    print("  duration:\t"..duration.." sec")
  else print "read_wav(): file not found" end
end