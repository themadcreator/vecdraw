
# Circle to path conversion technique from
# http://stackoverflow.com/questions/5737975/circle-drawing-with-svgs-arc-path

toPath = (item, pathData) ->
  item.addAttr({
    name   : 'd'
    prefix : ''
    local  : 'd'
    value  : pathData
  })

  item.renameElem('path')
  item.removeAttr(['cx', 'cy', 'r', 'rx', 'ry'])
  return

convertCircleToPath = (item) ->
  cx = +(item.attr('cx')?.value ? 0)
  cy = +(item.attr('cy')?.value ? 0)
  r  = +(item.attr('r')?.value ? 0)

  # TODO : run cleanupNumericValues to prevent NaNs?
  toPath(item, """
    M #{cx} #{cy}
    m #{-r}, 0
    a #{r} #{r} 0 1 0 #{r * 2} 0
    a #{r} #{r} 0 1 0 #{-r * 2} 0
  """)

convertEllipseToPath = (item) ->
  cx = +(item.attr('cx')?.value ? 0)
  cy = +(item.attr('cy')?.value ? 0)
  rx = +(item.attr('rx')?.value ? 0)
  ry = +(item.attr('ry')?.value ? 0)

  # TODO : run cleanupNumericValues to prevent NaNs?
  toPath(item, """
    M #{cx} #{cy}
    m #{-rx}, 0
    a #{rx} #{ry} 0 1 0 #{rx * 2} 0
    a #{rx} #{ry} 0 1 0 #{-rx * 2} 0
  """)

module.exports =
  type   : 'perItem'
  active : true
  fn     : (item) ->
    if item.isElem('circle') and
        item.hasAttr('cx') and
        item.hasAttr('cy') and
        item.hasAttr('r')
      convertCircleToPath(item)
    else if item.isElem('ellipse') and
        item.hasAttr('cx') and
        item.hasAttr('cy') and
        item.hasAttr('rx') and
        item.hasAttr('ry')
      convertEllipseToPath(item)
    return