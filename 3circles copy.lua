-- 3Circles
-- a three-voice looping sampler with arc control
-- for norns

-- require libraries
local arc = require 'arc'
local softcut = require 'softcut'
local lfo = require 'lfo'
-- local util = require 'util'


-- script state
local voices = {} -- table to hold state for our three voices
local focused_voice = 1

-- Hardcoded audio file paths
audio_files = "/home/we/dust/audio/mofongo/vibes-loops/clarinet-vibes-loops.wav"

myarc = {}
function init()
  -- create state for each voice
 myarc = arc.connect()
  softcut.buffer_read_stereo(audio_files, 0, 0, -1, 1, 1)
  for i = 1, 3 do
    voices[i] = {
    
      file = audio_files,
      -- these are stored as normalized values (0 to 1)
      loop_start_norm = 0,
      loop_end_norm = 1,
      lfo = lfo.new()
    }

    -- configure softcut for each voice
    softcut.enable(i, 1)
    softcut.buffer(i, 2)
    softcut.loop(i, 1)
    softcut.position(i, 0)
    softcut.level(i, 1.0) -- Start with full volume, LFO will modulate it
    softcut.play(i, 1)

    -- *** FIX: Load the hardcoded file into the buffer with correct arguments ***
    -- The path (string) comes first, then the buffer number (number).
  
    
    -- Set initial loop points in seconds after buffer is loaded
    softcut.loop_start(i, 0)
    softcut.loop_end(i, 2)

    -- configure LFO for each voice
    voices[i].lfo.shape = 'sine'
    voices[i].lfo.min = 0 -- LFO modulates from silent
    voices[i].lfo.max = 1 -- to full volume
    voices[i].lfo.freq = 0.25 -- default to a slow rate (frequency in Hz)
    voices[i].lfo.action = function(val)
      -- softcut.level(i, val)
    end
    voices[i].lfo:start()
  end



  -- initial screen and arc draw
  redraw()
  -- arc_refresh()
end

-- handle key presses
-- function key(n, z)
--   if n == 2 and z == 1 then
--     focused_voice = (focused_voice % 3) + 1
--     redraw()
--     arc_refresh()
--   end
-- end

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
-- function arc_refresh()
--   local voice = voices[focused_voice]

--   --myarc.all(0)

--   -- set encoder 1 to show loop start
--   local start_led = math.floor(voice.loop_start_norm * 63) + 1
--   myarc:led(1, start_led, 15)

--   -- set encoder 2 to show loop end
--   local end_led = math.floor(voice.loop_end_norm * 63) + 1
--   myarc:led(2, end_led, 15)

--   -- set encoder 3 to show lfo frequency (log scaled for better feel)
--   local lfo_scaled = (math.log(voice.lfo.freq / 0.01) / math.log(20 / 0.01))
--   local lfo_led = math.floor(lfo_scaled * 63) + 1
--   myarc:led(3, lfo_led, 15)


-- end

-- draw to screen
function redraw()
  -- screen.clear()
  -- screen.aa(0)
  -- screen.line_width(1)

  -- -- draw info for each voice
  -- for i = 1, 3 do
  --   local y_pos = 10 + ((i - 1) * 16)
  --   -- local file_name = voices[i].file:match("([^/]+)$") or "..."
  --   local lfo_freq_formatted = string.format("%.2f", voices[i].lfo.freq)

  --   -- highlight focused voice
  --   if i == focused_voice then
  --     screen.level(15)
  --     screen.rect(0, y_pos - 8, 128, 14):fill()
  --     screen.level(0)
  --     screen.move(3, y_pos)
  --     screen.text(">" .. i .. ": " .. i)
  --     screen.level(15)
  --     screen.move(125, y_pos)
  --     screen.text_right(lfo_freq_formatted .. "hz")
  --   else
  --     screen.level(6)
  --     screen.move(3, y_pos)
  --     screen.text(" " .. i .. ": " .. i)
  --     screen.move(125, y_pos)
  --     screen.text_right(lfo_freq_formatted .. "hz")
  --   end
  -- end

  -- screen.update()
end

-- -- cleanup on script removal
-- function cleanup()
--   for i=1,3 do
--     if voices[i] and voices[i].lfo then voices[i].lfo:stop() end
--   end
--   arc.cleanup()
-- end