pattern_time = require 'pattern_time'

tau = math.pi * 2
VOICES = 4
positions = {-1,-1,-1,-1}
mode = 1
hold = false

REFRESH_RATE = 0.03

function init()
  enc_pattern = pattern_time.new()
  enc_pattern.process = parse_enc_pattern

  enc_value = {0, 0, 0, 0} -- Track 4 encoders
  pattern_message = "press K3 to start recording"
  erase_message = "(no pattern recorded)"
  overdub_message = ""

  screen_dirty = true
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
end

function record_enc_value()
  enc_pattern:watch(
    {
      ["value"] = {enc_value[1], enc_value[2], enc_value[3], enc_value[4]}
    }
  )
end

function parse_enc_pattern(data)
  enc_value = {data.value[1], data.value[2], data.value[3], data.value[4]}
  screen_dirty = true
end

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

a = arc.connect()

a.delta = function(n,d)

  if n >= 1 and n <= 4 then
    enc_value[n] = enc_value[n] + d
    print("Updated encoder " .. n .. " value to " .. enc_value[n])
    record_enc_value()
    screen_dirty = true
  end
end

arc_redraw = function()
  a:all(0)
  for i=1,4 do
    a:segment(i, 0.5, 0.5 + enc_value[i]/100, 15)
  end
  a:refresh()
end

re = metro.init()
re.time = REFRESH_RATE
re.event = function()
  arc_redraw()
end
re:start()

function redraw()
  screen.clear()
  screen.level(15)
  for i=1,4 do
    screen.move(0,10*i)
    screen.text("encoder "..i.." value: "..enc_value[i])
  end
  screen.move(0,50)
  screen.text(pattern_message)
  screen.move(0,60)
  screen.text(erase_message)
  screen.move(0,70)
  screen.text(overdub_message)
  screen.update()
end