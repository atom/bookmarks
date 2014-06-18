{$, EditorView, View} = require 'atom'
path = require 'path'

module.exports =
class RegexDialog extends View
  @content: ->
    @div class: 'bookmarks-view-dialog overlay from-top', =>
      @label class: 'icon', 'Enter regular expression:'
      @subview 'miniEditor', new EditorView(mini: true)
      @div class: 'error-message', outlet: 'errorMessage'

  initialize: ->
    @on 'core:confirm', => @onConfirm(@miniEditor.getText())
    @on 'core:cancel', => @cancel()
    @miniEditor.hiddenInput.on 'focusout', => @remove()

  onConfirm: (regexString) ->
    regex = new RegExp(regexString, 'gi')
    @editor = atom.workspace.getActiveEditor()
    try
      @editor.scan regex, (object) =>
        range = [[object.range.start.row, 0], [object.range.start.row, 0]]
        bookmark = @editor.markBufferRange(range, @bookmarkMarkerAttributes(invalidate: 'surround'))
        @subscribe bookmark, 'changed', ({isValid}) ->
          bookmark.destroy() unless isValid
      @editor.getBuffer().emit 'bookmarks:created'
      @remove()
      @editor.focus()
    catch e
      @showError(e.message)

  bookmarkMarkerAttributes: (attributes={}) ->
    _.extend(attributes, class: 'bookmark')

  attach: ->
    atom.workspaceView.append(this)
    @miniEditor.focus()

  close: ->
    @remove()
    atom.workspaceView.focus()

  cancel: ->
    @remove()
    atom.workspaceView.focus()

  showError: (message='') ->
    @errorMessage.text(message)
    @flashError() if message
