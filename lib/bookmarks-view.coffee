path = require 'path'

{$$, SelectListView} = require 'atom-space-pen-views'

module.exports =
class BookmarksView extends SelectListView
  initialize: (@editorsBookmarks) ->
    super
    @addClass('bookmarks-view')

  destroy: ->
    @remove()
    @panel.destroy()

  getFilterKey: ->
    'filterText'

  attached: ->
    @focusFilterEditor()

  show: ->
    @populateBookmarks()
    @storeFocusedElement()
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  hide: ->
    @panel.hide()

  cancelled: ->
    @hide()

  getFilterText: (bookmark) ->
    segments = []
    bookmarkRow = bookmark.marker.getStartBufferPosition().row
    segments.push(bookmarkRow)
    if bufferPath = bookmark.editor.getPath()
      segments.push(bufferPath)
    if lineText = @getLineText(bookmark)
      segments.push(lineText)
    segments.join(' ')

  getLineText: (bookmark) ->
    bookmark.editor.lineTextForBufferRow(bookmark.marker.getStartBufferPosition().row)?.trim()

  populateBookmarks: ->
    bookmarks = []
    for editorBookmarks in @editorsBookmarks
      editor = editorBookmarks.editor
      continue if editor not in atom.workspace.getTextEditors()
      for marker in editorBookmarks.markerLayer.getMarkers()
        bookmark = {marker, editor}
        bookmark.filterText = @getFilterText(bookmark)
        bookmarks.push(bookmark)
    @setItems(bookmarks)

  viewForItem: (bookmark) ->
    bookmarkStartRow = bookmark.marker.getStartBufferPosition().row
    bookmarkEndRow = bookmark.marker.getEndBufferPosition().row
    if filePath = bookmark.editor.getPath()
      bookmarkLocation = "#{path.basename(filePath)}:#{bookmarkStartRow + 1}"
    else
      bookmarkLocation = "untitled:#{bookmarkStartRow + 1}"
    if bookmarkStartRow isnt bookmarkEndRow
      bookmarkLocation += "-#{bookmarkEndRow + 1}"
    lineText = @getLineText(bookmark)

    $$ ->
      if lineText
        @li class: 'bookmark two-lines', =>
          @div bookmarkLocation, class: 'primary-line'
          @div lineText, class: 'secondary-line line-text'
      else
        @li class: 'bookmark', =>
          @div bookmarkLocation, class: 'primary-line'

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No bookmarks found'
    else
      super

  confirmed: ({editor, marker}) ->
    editor.setSelectedBufferRange(marker.getBufferRange(), autoscroll: true)
    atom.workspace.paneForItem(editor).activate()
    @cancel()
