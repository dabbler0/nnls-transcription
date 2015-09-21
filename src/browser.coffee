fnnls = require './fnnls.coffee'
capture = require './capture.coffee'
numeric = require 'numeric'

canvas = document.createElement 'canvas'
canvas.width = canvas.height = 500
document.body.appendChild canvas

ctx = canvas.getContext '2d'

WINDOW_SIZE = 1024

fft = new FFT WINDOW_SIZE * 2, 11025
capture.listen (event) ->
  fft.forward(event.inputBuffer.getChannelData(0))

  if currentlyRecording
    for i in [0...WINDOW_SIZE]
      currentAvg[i] += fft.spectrum[i]
      length += 1

  max = Math.max.apply(@, fft.spectrum)

  ctx.clearRect 0, 0, 500, 500

  # Draw the FFT
  if PROFILES.length > 0
    weights = fnnls.fnnls(PROFILES, ([x] for x in fft.spectrum))
    max = Math.max.apply(@, weights)
    ctx.fillStyle = '#000'
    for el, i in weights
      ctx.fillRect((i / weights.length * 500), (500 - el / max * 500), (500 / weights.length), (el / max * 500))

capture.activateInput(WINDOW_SIZE * 2)

PROFILES = []

currentAvg = (0 for [0...WINDOW_SIZE])
length = 0
currentlyRecording = false

document.getElementById('capture_new').addEventListener 'click', ->
  if currentlyRecording
    if PROFILES.length > 0
      PROFILES = numeric.transpose PROFILES
    PROFILES.push currentAvg.map (x) -> x / length
    pcanvas = document.createElement 'canvas'
    pcanvas.width = pcanvas.height = 500
    pctx = pcanvas.getContext '2d'

    max = Math.max.apply(@, PROFILES[PROFILES.length - 1])

    pctx.beginPath()
    pctx.moveTo 0, 0
    for el, i in PROFILES[PROFILES.length - 1]
      pctx.lineTo i / (WINDOW_SIZE) * 500, 500 - el / max * 500
    pctx.strokeStyle = '#000'
    pctx.stroke()

    document.body.appendChild pcanvas
    PROFILES = numeric.transpose PROFILES

    length = 0; currentAvg = (0 for [0...WINDOW_SIZE])
    currentlyRecording = false
  else
    currentlyRecording = true
