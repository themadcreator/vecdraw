_         = require 'lodash'
jade      = require 'jade'
tesselate = require './tesselate'

class SvgLineRenderer
  _toJadeLine : (line) ->
    data = _.chain(line)
      .map((seg, i) ->
        if i is 0
          "M #{seg[0]},#{seg[1]}"
        else
          "L #{seg[0]},#{seg[1]}"
      )
      .join(' ')
      .value()
    return """path(fill="none",stroke="black",d="#{data}")"""

  render : (lines, width = 800, height = 800) ->
    jade.render """
doctype xml
svg(version="1.1",xmlns="http://www.w3.org/2000/svg",xmlns:xlink="http://www.w3.org/1999/xlink",width="#{width}px",height="#{height}px",viewBox="0 0 #{width} #{height}")
  #{lines.map(@_toJadeLine).join('\n  ')}
"""


fileName = process.argv[2] ? './test.svg'
svgTest  = require('fs').readFileSync(fileName, 'utf-8')
tesselate(svgTest, 3.0).then (lines) ->
  console.log new SvgLineRenderer().render(lines)
