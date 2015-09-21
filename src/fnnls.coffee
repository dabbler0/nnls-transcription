# FASTNNLS
numeric = require 'numeric'
exports.DEBUG = false

norm = (x) ->
  x.map((el) -> el.reduce((a, b) -> Math.abs(a) + Math.abs(b))).reduce((a, b) -> a + b)

mmax = (x) ->
  max = -Infinity; ind = null
  for row, i in x
    for cell, j in row
      if cell > max
        max = cell
        ind = [i, j]
  return {max, ind}

argmax = (x) ->
  max = -Infinity; ind = null
  for el, i in x
    if el > max
      max = el
      ind = i
  return {max, ind}

exports.fnnls = (x, y, tol, b) ->
  # x is a matrix
  m = x.length; n = x[0].length

  tol ?= Math.max(m, n) * norm(x) * 1e-16
  b ?= (0 for [0...n])

  # STAGE 1:
  # Greedy exclude of all variables with estimated negative correlations.

  # Solve by normal equations a subsystem including
  # those where the previous estimated vector was nonzero
  if b.reduce(Math.max) > 0
    sub = numeric.transpose(numeric.transpose(x).filter((col, i) -> b[i] > 0))
    sp = numeric.solve(
      numeric.dot(numeric.transpose(sub), sub),
      numeric.dot(numeric.transpose(sub), y)
    )

    j = 0
    for el, i in b when el > 0
      b[i] = sp[j]; j++
    while Math.min.apply(@, sp) < 0
      # Clamp the input vector to zero
      b = b.map (x) -> Math.max 0, x
      # Solve by normal equations a subsystem including
      # those where the previous estimated vector was nonzero
      sub = numeric.transpose(numeric.transpose(x).filter((col, i) -> b[i] > 0))
      sp = numeric.solve(
        numeric.dot(numeric.transpose(sub), sub),
        numeric.dot(numeric.transpose(sub), y)
      )
      j = 0
      for el, i in b when el > 0
        b[i] = sp[j]; j++

  # STAGE 2:
  # Something.

  # Find where the input vector is zero
  p = b.map (el) -> el > 0
  r = p.map (el) -> not el

  w = numeric.dot(numeric.transpose(x), numeric.sub(y, numeric.dot(x, b.map((el) -> [el]))))
  {max: wmax, ind} = mmax(w)
  flag = 0

  # Proclaim that we are going to try to use whatever
  # the maximum element of w was
  while (wmax > tol and r.reduce((a, b) -> a or b))
    if exports.DEBUG
      console.log wmax, tol
    p[ind[0]] = true
    r[ind[0]] = false

    # Re-regress
    sub = numeric.transpose(numeric.transpose(x).filter((col, i) -> p[i]))
    sp = numeric.solve(
      numeric.dot(numeric.transpose(sub), sub),
      numeric.dot(numeric.transpose(sub), y)
    )

    while Math.min.apply(@, sp) < -tol
      tsp = (0 for [0...n]); j = 0
      for el, i in tsp when p[i]
        tsp[i] = sp[j]; j++

      rat = (0 for [0...n])
      for el, i in b when p[i]
        rat[i] = b[j] / (sp[j] + b[j]); j++

      alpha = Math.min.apply(@, rat.filter((el) -> el > tol))

      b = b.map (el, i) -> el + alpha[i] * (tsp[i] - el)

      p = b.map (el) -> el > tol
      r = p.map (el) -> not el

      # Re-regress
      sub = numeric.transpose(numeric.transpose(x).filter((col, i) -> p[i]))
      sp = numeric.solve(
        numeric.dot(numeric.transpose(sub), sub),
        numeric.dot(numeric.transpose(sub), y)
      )

    j = 0
    for el, i in b when p[i]
      b[i] = sp[j]; j++

    w = numeric.dot(numeric.transpose(x), numeric.sub(y, numeric.dot(x, b.map((el) -> [el]))))

    {max: wmax, ind} = mmax(w)
    if exports.DEBUG
      console.log wmax, ind
    if p[ind[0]]
      wmax = 0

  return b

