-- El Bufer
-- @mofongo
-- A simple buffer looper, two playback loops, arc compatible


lfo = require 'lfo'
local util = require 'util'
fileselect = require('fileselect')

-- helper function to extract filename from a full path
function get_filename_from_path(path)
  if path then
    return path:match("([^/]+)$") or path
  end
  return ""
end

--- Scales a value from an original range to a new range.
-- This is a general-purpose mapping function.
-- @param value The input number to scale.
-- @param old_min The minimum of the original range.
-- @param old_max The maximum of the original range.
-- @param new_min The minimum of the new range.
-- @param new_max The maximum of the new range.
-- @return The scaled number.
function scale_value(value, old_min, old_max, new_min, new_max)
  return new_min + (new_max - new_min) * ((value - old_min) / (old_max - old_min))
end

tau = math.pi * 2
positions = {-1,-1,-1,-1}
modes = {"speed", "pitch"}
mode = 1
hold = false

REFRESH_RATE = 0.03

-- loop values to use in display
local loop_values = {
  {start = 0, end_ = 2},
  {start = 0, end_ = 2}
}


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
        controlspec = controlspec.new(0, 5, "lin", 0.01, 0),
        action = function(value)
            softcut.loop_start(1, value)
            loop_values[1].start = value
            if value > params:get("Loop 1 End") then
                params:set("Loop 1 End", value)
            else
                redraw()
            end
        end
    }
    params:add {
        type = "control",
        id = "Loop 1 End",
        name = "End 1",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 2),
        action = function(value)
            softcut.loop_end(1, value)
            loop_values[1].end_ = value
            if value < params:get("Loop 1 Start") then
                params:set("Loop 1 Start", value)
            else
                redraw()
            end
        end
    }
    params:add {
        type = "control",
        id = "Loop 2 Start",
        name = "Start 2",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 0),
        action = function(value)
            softcut.loop_start(2, value)
            loop_values[2].start = value
            if value > params:get("Loop 2 End") then
                params:set("Loop 2 End", value)
            else
                redraw()
            end
        end
    }
    params:add {
        type = "control",
        id = "Loop 2 End",
        name = "End 2",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 2),
        action = function(value)
            softcut.loop_end(2, value)
            loop_values[2].end_ = value
            if value < params:get("Loop 2 Start") then
                params:set("Loop 2 Start", value)
            else
                redraw()
            end
        end
    }
    params:add {
        type = "control",
        id = "Loop 3 Start",
        name = "Start 3",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 0),
        action = function(value)
            softcut.loop_start(3, value)
            if value > params:get("Loop 3 End") then
                params:set("Loop 3 End", value)
            else
                redraw()
            end
        end
    }
    params:add {
        type = "control",
        id = "Loop 3 End",
        name = "End 3",
        controlspec = controlspec.new(0, 5, "lin", 0.01, 2),
        action = function(value)
            softcut.loop_end(3, value)
            if value < params:get("Loop 3 Start") then
                params:set("Loop 3 Start", value)
            else
                redraw()
            end
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

  -- Draw loop representations
  screen.level(15)
  screen.line_width(2)
  screen.font_size(7)

  -- Loop 1
  screen.move(0, 20)
  screen.text("L1")
  -- The controlspec for loop points is 0-5 seconds. We map this to screen width.
  -- The screen coordinates will go from 15 to 127 to leave room for the label.
  local start_x1 = scale_value(loop_values[1].start, 0, 5, 15, 127)
  local end_x1 = scale_value(loop_values[1].end_, 0, 5, 15, 127)
  screen.move(start_x1, 20)
  screen.line(end_x1, 20)
  screen.stroke()

  -- Loop 2
  screen.move(0, 30)
  screen.text("L2")
  local start_x2 = scale_value(loop_values[2].start, 0, 5, 15, 127)
  local end_x2 = scale_value(loop_values[2].end_, 0, 5, 15, 127)
  screen.move(start_x2, 30)
  screen.line(end_x2, 30)
  screen.stroke()

  -- Draw file info text
  screen.level(8)
  screen.move(0, 58)
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