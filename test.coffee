_         = require 'lodash'
jade      = require 'jade'
tesselate = require './src/tesselate'

class SvgLineRenderer
  _toJadeLine : (line) ->
    data = _.chain(line)
      .map((seg, i) ->
        coord = seg.join(',')
        return if i is 0 then "M #{coord}" else "L #{coord}"
      )
      .join(' ')
      .value()
    return """path(fill="none",stroke="black",d="#{data}")"""

  render : (paths, width = 800, height = 800) ->
    pathsString = _.chain(paths)
      .map((path) => _.map(path, @_toJadeLine))
      .flatten()
      .join('\n  ')
      .value()
    jade.render """
doctype xml
svg(version="1.1",xmlns="http://www.w3.org/2000/svg",xmlns:xlink="http://www.w3.org/1999/xlink",width="#{width}px",height="#{height}px",viewBox="0 0 #{width} #{height}")
  #{pathsString}
"""

fileName = process.argv[2] ? './test.svg'
svgTest  = require('fs').readFileSync(fileName, 'utf-8')
tesselate(svgTest, 3.0).then (paths) ->
  console.log new SvgLineRenderer().render(paths)
