fnnls = require '../src/fnnls.coffee'

# TESTING!!!
IN_DIMENSIONS = 4096
N_PROFILES = 12

DEBUG = false

# Profiles
PROFILES = []
for [0...N_PROFILES]
  profile = []
  for [0...IN_DIMENSIONS]
    profile.push Math.random()
  PROFILES.push profile

NOISY_PROFILES = PROFILES.map (profile) -> profile.map (el) -> el + Math.random() * 0.01 - 0.005

PROFILES = numeric.transpose PROFILES
NOISY_PROFILES = numeric.transpose NOISY_PROFILES

avgElapsed = 0
mse = 0

# Note profiles.
for i in [0...100]
  console.log "TEST #{i}"
  if DEBUG
    console.log "---------"

  realWeights = ([Math.random()] for [0...N_PROFILES])
  vector = numeric.dot(PROFILES, realWeights)

  # Add noise
  vector = vector.map (row) -> row.map (el) -> el + Math.random() * 0.01 - 0.005

  start = (new Date())
  result = fnnls.fnnls(NOISY_PROFILES, vector)
  elapsed = (new Date() - start)

  avgElapsed += elapsed / 100

  if DEBUG
    console.log "---------"
    console.log "FINISHED IN #{elapsed}"
    console.log result.map((el, i) -> el + '\t\t' + realWeights[i]).join('\n')
    console.log "SUM SQUARED ERROR:"
    console.log result.map((el, i) -> (el - realWeights[i]) ** 2).reduce((a, b) -> a + b)
    console.log "---------"
  else
    se = result.map((el, i) -> (el - realWeights[i]) ** 2).reduce((a, b) -> a + b)
    console.log se

    mse += se / 100

console.log 'AVERAGE ELAPSED TIME', avgElapsed
console.log 'MEAN SQUARED ERROR', mse
