-- El Bufer
-- @mofongo
-- A simple buffer looper, two playback loops, arc compatible


lfo = require 'lfo'
-- local util = require 'util'
fileselect = require('fileselect')

-- helper function to extract filename from a full path
function get_filename_from_path(path)
  if path then
    return path:match("([^/]+)$") or path
  end
  return ""
end
tau = math.pi * 2
positions = {-1,-1,-1,-1}
modes = {"speed", "pitch"}
mode = 1
hold = false

REFRESH_RATE = 0.03

recording = false
-- script state
voices = {} -- table to hold state for our three voices
local focused_voice = 1

-- Hardcoded audio file paths
-- audio_file = "/home/we/dust/audio/mofongo/vibes-loops/clarinet-vibes-loops.wav"
audio_file = _path.dust.."audio/mofongo/clarinet-vibes-loops.wav"
print("Using audio file: " .. get_filename_from_path(audio_file))
-- audio_file = _path.dust.."audio/mofongo/250424_0045 acoustic casino experimental sounds.wav"
  -- audio_file = _path.dust.."audio/mofongo/250413_0042_solo_classical.wav"
local Arcify = include("lib/arcify")
my_arc = arc.connect()


arcify = Arcify.new()
 
-- function arcify:update (num, delta) 
--   print(num)
--   print(delta)
-- end
  
  
 arc_is = "totot"

function init()

  

  -- counter = metro.init(stop_recording, 1, 1) -- Call stop_recording after 1 second, once.
  -- counter.event = function(voice_num)
  --   softcut.rec(1, 0)
  --   softcut.rec_level(1, 0)
  --   recording = false
  --   print(string.format("Stopped recording voice:" .. voice_num))
  -- end
  -- p = poll.set("amp_in_l")
  --   p.callback = function(val)
  --     if val > 0.02 then record_to_buffer(1) end
  --  end
  -- p:start()
  -- create state for each voice
  --myarc = arc.connect()
  -- print_info(audio_file)
  softcut.level_input_cut(1,1,1.0)
  softcut.recpre_slew_time (1, .5)

  softcut.rec_level(1,0)
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
      shape = 'trial',
      min = 0, -- LFO modulates from silent
      max = 1, -- to full volume
      depth = .5,
      period = 1, -- default to a slow rate (frequency in Hz)
      action = function(scaled, raw) 
        softcut.position(i, raw) 
        softcut.level(i, scaled) -- Set the level based on LFO output  
        end
    }
    -- voices[1].myarclfo = lfo:add{
    --   shape = 'random',
    --   min = -100, -- LFO modulates from silent
    --   max = 100, -- to full volume
    --   depth = .5,
    --   period = .5, -- default to a slow rate (frequency in Hz)
    --   action = function(scaled, raw) lfolog(scaled) end
    -- }
    
    -- voices[i].mylfo:start()
    -- voices[i].myarclfo:start()
    -- configure softcut for each voice
    softcut.enable(i, 1)
    softcut.level_slew_time(1, .25)
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




  params:add_file("audio_file", "Audio File", audio_file)
  params:set_action("audio_file", function(file)
    if util.file_exists(file) then
      audio_file = file
      print("Selected audio file: " .. get_filename_from_path(audio_file))

      softcut.buffer_clear()
      softcut.buffer_read_stereo(audio_file, 0, 0, -1, 1, 1)
      -- Optionally reset loop points for all voices
      for i = 1, 3 do
        softcut.loop_start(i, 0)
        softcut.loop_end(i, 2)
        voices[i].file = audio_file
      end
      redraw()
    else
      print("File not found: " .. file)
    end
  end)

  params:add {
      type = "control",
      id = "Loop 1 Start",
        name = "Start 1",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 0.5),
        action = function(value)
            softcut.loop_start(1, value)
            redraw()
        end
    }
    params:add {
        type = "control",
        id = "Loop 1 End",
        name = "End 1",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 0.5),
        action = function(value)
           softcut.loop_end(1, value)
            redraw()
        end
    }
    params:add {
        type = "control",
        id = "Loop 2 Start",
        name = "Start 2",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 0.5),
        action = function(value)
            softcut.loop_start(2, value)
            redraw()
        end
    }
    params:add {
        type = "control",
        id = "Loop 2 End",
        name = "End 2",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 0.5),
        action = function(value)
           softcut.loop_end(2, value)
            redraw()
        end
    }
    params:add {
        type = "control",
        id = "Loop 3 Start",
        name = "Start 3",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 0.5),
        action = function(value)
            softcut.loop_start(3, value)
            redraw()
        end
    }
    params:add {
        type = "control",
        id = "Loop 3 End",
        name = "End 3",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 0.5),
        action = function(value)
           softcut.loop_end(3, value)
            redraw()
        end
    }
    -- register parameters with arcify

      print("Arcify initialized, registering parameters.")
      arcify:register("Loop 1 Start", 0.01)
      arcify:register("Loop 1 End", 0.01)
      arcify:register("Loop 2 Start", 0.01)
      arcify:register("Loop 2 End", 0.01)
      arcify:register("Loop 3 Start", 0.01)
      arcify:register("Loop 3 End", 0.01)

      -- after registering all your params run add_params()
      -- to make them visible in norns params menu
      arcify:add_params()

  -- detect if arc is connected

    if my_arc.name ~= "none" and my_arc.device ~= nil then
      print("Arc connected: " .. my_arc.name)
      arc_is = "supertrue"
    else
      print("No Arc connected")
      arc_is = "bigfalse"
    end

    --temp hacks
    softcut.level(3,0)
    -- softcut.level(2,0)
    softcut.pan(1,-.5)
    softcut.pan(2,.5)
    params:default()

  end



function lfolog(scaled)
  arcify:update(i, scaled) 
  print(scaled)
end

focused_voice = 1
function record_to_buffer(voice_num)
  print("Record to buffer" .. voice_num)
  if recording then
     print("break")
    else
      -- softcut.buffer_clear(voice_num) -- Clear the specific buffer for the chosen voice
      softcut.rec_level(1,1)
      -- softcut.position(voice_num, 0) -- Reset the playhead position to the start for the chosen voice
      softcut.rec(voice_num, 1)
      recording = true
      print("inside record else")
      counter:start() -- Start the metro (time and count are preset in init)
    end
end
-- handle key presses
function key(n, z)
  if z == 1 then
    if n == 2 then
    focused_voice = (focused_voice % 3) + 1
    redraw()
    -- arc_refresh()
    print("key 2 pressed, focused voice: " .. focused_voice)
    elseif n == 3 then
      record_to_buffer(1)
    end
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
  screen.font_face(1)
  screen.font_size(7)
  screen.move(0,50)
  screen.text("File:")
  screen.move(0,58)
  screen.text(get_filename_from_path(audio_file))
  screen.update()
end
function print_info(file)
  if util.file_exists(file) == true then
    local ch, samples, samplerate = audio.file_info(file)
    local duration = samples/samplerate
    print("loading file: "..get_filename_from_path(file))
    print("  channels:\t"..ch)
    print("  samples:\t"..samples)
    print("  sample rate:\t"..samplerate.."hz")
    print("  duration:\t"..duration.." sec")
  else print "read_wav(): file not found" end
end