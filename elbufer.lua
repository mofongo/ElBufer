-- El Búfer
-- @mofongo
-- A simple buffer looper, two playback loops, arc compatible


-- ##### LIBRARIES ##### --
lfo = require 'lfo'
local util = require 'util'



-- ##### HELPER FUNCTIONS ##### --

-- Extracts just the filename from a full file path.
function get_filename_from_path(path)
  if path then
    return path:match("([^/]+)$") or path
  end
  return ""
end


function scale_value(value, old_min, old_max, new_min, new_max)
  return new_min + (new_max - new_min) * ((value - old_min) / (old_max - old_min))
end

-- ##### GLOBAL STATE & VARIABLES ##### --

-- Stores start/end values for screen display.
local loop_values = {
  {start = 0, end_ = 2},
  {start = 0, end_ = 2}
}


recording = false

 -- table to hold state for our three voices
voices = {}
local focused_voice = 1

-- Default audio file path
audio_file = _path.dust.."audio/mofongo/clarinet-vibes-loops.wav"
print("Using audio file: " .. get_filename_from_path(audio_file))
-- audio_file = _path.dust.."audio/mofongo/250424_0045 acoustic casino experimental sounds.wav"
  -- audio_file = _path.dust.."audio/mofongo/250413_0042_solo_classical.wav"


-- Arc integration.
  local Arcify = include("lib/arcify")
my_arc = arc.connect()


arcify = Arcify.new()
 

-- ##### INITIALIZATION ##### --
function init()


  -- --- Softcut Setup ---
  -- Load the initial audio file into the buffer.
  softcut.buffer_clear()
  softcut.buffer_read_stereo(audio_file, 0, 0, -1, 1, 1)


-- Configure softcut parameters for each voice.
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



-- --- Parameter Setup ---
  -- Create parameters accessible from the norns menu.
  -- File selection parameter.
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
    else
      print("No Arc connected")
    end

    --temp hacks
    softcut.level(3,0)
    -- softcut.level(2,0)
    softcut.pan(1,-.5)
    softcut.pan(2,.5)
    params:default()

  end
-- end of INITIALIZATION --

-- ##### HANDLERS ##### --

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