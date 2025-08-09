-- El Búfer
-- @mofongo
-- A simple buffer looper, two playback loops, arc compatible


-- ##### LIBRARIES ##### --
lfo = require 'lfo'
local util = require 'util'
pattern_time = require 'pattern_time' -- use the pattern_time lib in this script




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

 -- table to hold state for our three voices
voices = {}
local focused_voice = 1

-- Default audio file path
audio_file = _path.dust.."audio/mofongo/clarinet-vibes-loops.wav"

-- Arc integration.
local Arcify = include("lib/arcify")
arcify = Arcify.new()
 

-- ##### INITIALIZATION ##### --
function init()

  -- pattern time setup
  enc_pattern = pattern_time.new()
  enc_pattern.process = parse_enc_pattern
  pattern_message = "press K3 to start recording"
  erase_message = "(no pattern recorded)"
  overdub_message = ""

  screen_dirty = true
  -- Screen refresh loop to update the UI when screen_dirty is true.
  screen_timer = clock.run(
    function()
      while true do
        clock.sleep(1/15)
        if screen_dirty then
          redraw()
          screen_dirty = false
        end
      end
    end
  )

  -- Hook into arcify's delta handler to also update pattern_time
  local original_delta_handler = arcify.a_.delta
  arcify.a_.delta = function(n, d)
    -- First, call arcify's original handler so parameter mapping still works
    original_delta_handler(n, d)
    
    -- If the encoder is not in the range we care about, do nothing.
    -- Then, add our custom logic for pattern_time
    if n >= 1 and n <= 4 then
      record_enc_value()
    end
  end

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

    --temp hacks
    softcut.level(3,0)
    -- softcut.level(2,0)
    softcut.pan(1,-.5)
    softcut.pan(2,.5)
    params:default()

  end
-- end of INITIALIZATION --

-- ##### HANDLERS ##### --

-- Pattern time helpers --
function record_enc_value()
  local values_to_record = {}
  for i = 1, 4 do
    -- Get the parameter ID mapped to the current encoder
    local param_id = arcify:param_id_at_encoder(i)
    if param_id then
      -- If a parameter is mapped, record its ID and current value
      values_to_record[i] = { id = param_id, value = params:get(param_id) }
    else
      -- If no parameter is mapped, record nil
      values_to_record[i] = nil
    end
  end
  -- Watch the collected values with pattern_time
  enc_pattern:watch({ values = values_to_record })
end

function parse_enc_pattern(data)
  if data and data.values then
    for i = 1, 4 do
      local recorded_param = data.values[i]
      if recorded_param then
        params:set(recorded_param.id, recorded_param.value)
      end
    end
  end
end

-- handle key presses
function key(n,z)
  if n == 3 and z == 1 then
    if enc_pattern.rec == 1 then
      enc_pattern:rec_stop()
      enc_pattern:start()
      pattern_message = "playing, press K3 to stop"
      erase_message = "press K2 to erase"
      overdub_message = "hold K1 to overdub"
    elseif enc_pattern.count == 0 then
      enc_pattern:rec_start()
      record_enc_value()
      pattern_message = "recording, press K3 to stop"
      erase_message = "press K2 to erase"
      overdub_message = ""
    elseif enc_pattern.play == 1 then
      enc_pattern:stop()
      pattern_message = "stopped, press K3 to play"
      erase_message = "press K2 to erase"
      overdub_message = ""
    else
      enc_pattern:start()
      pattern_message = "playing, press K3 to stop"
      erase_message = "press K2 to erase"
      overdub_message = "hold K1 to overdub"
    end
  elseif n == 2 and z == 1 then
    enc_pattern:rec_stop()
    enc_pattern:stop()
    enc_pattern:clear()
    erase_message = "(no pattern recorded)"
    pattern_message = "press K3 to start recording"
    overdub_message = ""
  elseif n == 1 then
    enc_pattern:set_overdub(z)
    overdub_message = z == 1 and "overdubbing" or "hold K1 to overdub"
  end
  screen_dirty = true
end

function redraw()
  screen.clear()

  -- Draw loop representations
  screen.level(15)
  screen.line_width(2)
  screen.font_size(7)

  -- Loop 1
  screen.move(0, 10)
  screen.text("L1")
  -- The controlspec for loop points is 0-5 seconds. We map this to screen width.
  -- The screen coordinates will go from 15 to 127 to leave room for the label.
  local start_x1 = scale_value(loop_values[1].start, 0, 5, 15, 127)
  local end_x1 = scale_value(loop_values[1].end_, 0, 5, 15, 127)
  screen.move(start_x1, 10)
  screen.line(end_x1, 10)
  screen.stroke()

  -- Loop 2
  screen.move(0, 20)
  screen.text("L2")
  local start_x2 = scale_value(loop_values[2].start, 0, 5, 15, 127)
  local end_x2 = scale_value(loop_values[2].end_, 0, 5, 15, 127)
  screen.move(start_x2, 20)
  screen.line(end_x2, 20)
  screen.stroke()

  -- Draw file info text
  screen.level(8)
  screen.move(0, 35)
  screen.text(get_filename_from_path(audio_file))

  -- Pattern Time Messages
  screen.level(15)
  screen.move(0, 50)
  screen.text(pattern_message)
  screen.move(0, 60)
  screen.text(erase_message)
  -- Note: overdub_message might not fit on screen.

  screen.update()
end