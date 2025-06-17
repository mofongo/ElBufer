-- Initialize Softcut for Voice 1
audio.level_adc_cut(1)
audio.level_eng_cut(1)
voices = 3

function init_softcut()
  for i = 1, voices do
    softcut.buffer_clear()
    softcut.enable(i, 1) -- Enable voice i
    softcut.buffer(i, i) -- Assign buffer i to voice i (assuming one buffer per voice)
    softcut.level(i, 1.0) -- Set level for voice i
    softcut.rate(i, 1.0) -- Set playback rate for voice i
    softcut.loop(i, 1) -- Enable looping for voice i
    softcut.loop_start(i, 0) -- Set loop start for voice i
    softcut.loop_end(i, 1) -- Set loop end for voice i
    softcut.position(i,0)
    softcut.play(i,1)
    softcut.fade_time(i, 0.1) 
    -- set input rec level: input channel, voice, level
    softcut.level_input_cut(i,1,1.0)
    softcut.level_input_cut(i,1,1.0)
    softcut.rec_level(i,1)
    softcut.pre_level(i,1)
    softcut.level_slew_time(i,1,0.5)
  end
end


engine.name = 'PolyPerc'
