# jade = require 'jade'

# svg = '''
#   doctype xml
#   svg(version="1.1",xmlns="http://www.w3.org/2000/svg",xmlns:xlink="http://www.w3.org/1999/xlink",width="144px",height="144px",viewBox="0 0 1440 1440")
#     rect(width="600",height="600")
#     path#rect(d="M1168.981,768.024c0.008-1.008,0.019-2.014,0.019-3.024c0-198.823-161.177-360-360-360c-92.053,0-176.032,34.554-239.686,91.393C560.008,495.477,550.563,495,541,495c-149.117,0-270,114.167-270,255c0,6.03,0.238,12.006,0.674,17.932C169.444,781.873,90,870.103,90,976v30c0,115.5,94.5,210,210,210h840c115.5,0,210-94.5,210-210v-30C1350,870.329,1270.895,782.252,1168.981,768.024z")
#     text#text(x="720",y="920",fill="#fff",text-anchor="middle",style="font-size:280px") X
# '''





# class Svg
#   @attrs : (args) ->


#   @nodes :
#     root : (width, height) ->
#       return """svg(version="1.1",xmlns="http://www.w3.org/2000/svg",xmlns:xlink="http://www.w3.org/1999/xlink",width="#{width}px",height="#{height}px",viewBox="0 0 #{width} #{height}")"""
#     rect : (attrs = {}) ->
#       attrs = Svg.attrs(attrs, {x : 0, y : 0, width : 0, height: 0})
#       return ["rect(#{attrs})"]
#     path : (attrs = {}) ->
#       attrs = Svg.attrs(attrs, {x : 0, y : 0, width : 0, height: 0})
#       return ["rect(#{attrs})"]
#     circle : (attrs = {}) ->
#       attrs = Svg.attrs(attrs, {x : 0, y : 0, width : 0, height: 0})
#       return ["rect(#{attrs})"]


#   constructor : (500, 500) ->
#     node = Svg.nodes.root(width, height)
#     children

#   render : ->

#     ['doctype xml'
#      'svg(version="1.1",xmlns="http://www.w3.org/2000/svg",xmlns:xlink="http://www.w3.org/1999/xlink",width="144px",height="144px",viewBox="0 0 1440 1440")]
#     '''





# console.log jade.render(svg)


# http://antigrain.com/research/adaptive_bezier/
# https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm
# See "Degree Elevation". Convert quadratic curves to cubic then solve cubic


Promise = require 'bluebird'

class SvgParser
  @config :
    strict    : true
    trim      : false
    normalize : true
    lowercase : true
    xmlns     : true
    position  : false

  parse : (svgString) ->
    return new Promise (resolve, reject) => @_parse(svgString, resolve, reject)

  _parse : (svgString, resolve, reject) ->
    sax = require('sax').parser(SvgParser.config.strict, SvgParser.config)

    root        = {}
    current     = root
    stack       = [root]
    textContext = null

    pushToContent = (child) ->
      (current.children ?= []).push(child)
      return child

    sax.ondoctype = (doctype) ->
      pushToContent({doctype})

    sax.onprocessinginstruction = (processinginstruction) ->
      pushToContent({processinginstruction})

    sax.oncomment = (comment) ->
      pushToContent({comment : comment.trim()})

    sax.oncdata = (cdata) ->
      pushToContent({cdata})

    sax.onopentag = (data) ->
      elem = {tag : data.name}

      for name, value of data.attributes
        elem.attrs ?= {}
        elem.attrs[name] = value.value

      current = pushToContent(elem)

      # Save info about <text> tag to prevent trimming of meaningful whitespace
      if (data.name is 'text' and not data.prefix)
        textContext = current

      stack.push(elem)

    sax.ontext = (text) ->
      if (/\S/.test(text) or textContext)
        if (not textContext) then text = text.trim()
        pushToContent({text})

    sax.onclosetag = ->
      last = stack.pop()

      # Trim text inside <text> tag.
      if (last is textContext)
        #trim(textContext)
        textContext = null

      current = stack[stack.length - 1]

    sax.onend = ->
      resolve(root.children)

    sax.onerror = reject

    sax.write(svgString).close()
    return



eachPath = (svgString, callback) ->
  sax = require('sax').parser(SvgParser.config.strict, SvgParser.config)
  sax.write(svgString).close()

  return new Promise (resolve, reject) ->

    sax.onopentag = (data) ->
      if data.name is 'path' then callback(data)
      sax.onerror = reject
      sax.onend = resolve

    sax.write(svgString).close()



fs = require 'fs'
fileContents = fs.readFileSync('./simple.svg', 'utf-8')
# new SvgParser().parse(fileContents).then (root) -> console.log JSON.stringify(root, null, 2)

_          = require 'lodash'
bezier     = require 'adaptive-bezier-curve'
pathParser = require 'svg-path-parser'

class PathParser
  parse : () ->
    points = []

    toPoints = (cmd, keys) ->
      pts = _.map(keys, (kk) -> _.map(kk, (k) -> cmd[k]))
      if cmd.relative
        lastPoint = points[points.length - 1]
        for p in pts
          p[0] += lastPoint[0]
          p[1] += lastPoint[1]
      return pts


    for cmd in pathParser(pathString)
      pts = switch cmd
        when 'moveto' then toPoints(cmd, ['x', 'y'])
        when 'lineto' then toPoints(cmd, ['x', 'y'])
        when 'curveto' then toPoints(cmd, [['x1', 'y2'],[]])


eachPath(fileContents, (elem) ->
  pathString = elem.attributes.d.value



)
