CodeMirror = require 'codemirror'
require 'codemirror/addon/edit/matchtags'
require 'codemirror/addon/selection/active-line'

CodeMirror.defineMode "elaborate", ->
  tags = ['i', 'b', 'u']

  startState: ->
    state = {}
    state[tag] = false for tag in tags
    state


  token: (stream, state) ->
    regexpStartTag = new RegExp("<(#{tags.join('|')})>")
    regexpEndTag = new RegExp("<(\/#{tags.join('|\/')})>")

    regexpStartAnno = new RegExp("<\\d+>")
    regexpEndAnno = new RegExp("<\/\\d+>")
#    open_i = stream.string.search(/<i>/)
    if (matched = stream.match(regexpStartTag))
      state[matched[1]] = true
      return 'tag'
    else if (matched = stream.match(regexpEndTag))
      state[matched[1].substr(1)] = false
      return 'tag'
    else if (matched = stream.match(regexpStartAnno))
      return 'annotation'
    else if (matched = stream.match(regexpEndAnno))
      return 'annotation'
    else
      stream.next()

      tokenName = []

      if state.i
        tokenName.push 'em'

      if state.u
        tokenName.push 'link'

      if state.b
        tokenName.push 'strong'

      if tokenName.length
        return tokenName.join(' ')
      else
        return null
#      stream.skipTo('>')
#
#    console.log stream
#    console.log stream.string.substr(stream.start)







html = """
van <b>d<u>een</b></u> Heer <1>Maurg</1><u>neau</u>lt Presid<i>ent </i> v<i>an\'t </i>E<i>dele</i><i> </i>hof.
"""

module.exports =
  document.addEventListener 'DOMContentLoaded', ->
    codeMirror = CodeMirror document.getElementById('app'),
      value: html
      lineNumbers: true
      lineWrapping: true
      mode: 'elaborate'
      matchTags: bothTags: true
      styleActiveLine: true


