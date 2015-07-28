Promise              = require 'bluebird'
svg2js               = require 'svgo/lib/svgo/svg2js'
plugins              = require 'svgo/lib/svgo/plugins'
pathUtils            = require 'svgo/plugins/_path'
cleanupNumericValues = require 'svgo/plugins/cleanupNumericValues'
convertPathData      = require 'svgo/plugins/convertPathData'
convertShapeToPath   = require 'svgo/plugins/convertShapeToPath'
removeHiddenElems    = require 'svgo/plugins/removeHiddenElems'
convertCircleToPath  = require './convertCircleToPath'
{Tesselator}         = require './tesselator'

tesselatorPlugin = (tesselationScale) ->
  tesselator = new Tesselator(tesselationScale)
  paths = []
  return {
    type   : 'perItem'
    active : true
    fn     : (item) ->
      if item.isElem(['path']) and item.hasAttr('d')
        paths.push tesselator.tesselateCurves pathUtils.relative2absolute(item.pathJS)
    paths : paths
  }

module.exports = tesselate = (svgString, scale) ->
  new Promise((res, rej) -> svg2js(svgString, res)).then((items) ->
    tesselator = tesselatorPlugin(scale)

    plugins(items, [[
      cleanupNumericValues
      removeHiddenElems
      convertShapeToPath
      convertCircleToPath
      convertPathData
      tesselator
    ]])

    return tesselator.paths
  )
