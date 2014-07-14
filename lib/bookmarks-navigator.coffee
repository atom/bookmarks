path = require 'path'
{Subscriber} = require 'emissary'
{$, $$, ScrollView} = require 'atom'

module.exports =
class BookmarksNavigator extends ScrollView
  Subscriber.includeInto(this)
  editor: null

  @content: ->
    @div class: 'bookmarks-navigator-resizer tool-panel panel-right', =>
      @div class: 'bookmarks-navigator-scroller', outlet: 'scroller', =>
        @ul class: 'bookmarks-navigator list-group focusable-panel', tabindex: -1, outlet: 'list'
      @div class: 'bookmarks-navigator-resize-handle', outlet: 'resizeHandle'

  initialize: ->
    super
    @refreshBookmarksList()
    @on 'mousedown', '.bookmarks-navigator-resize-handle', (e) => @resizeStarted(e)
    @on 'mousedown', '.bookmark-list-item', (e) =>
      e.stopPropagation()
      currentTarget = $(e.currentTarget)
      @selectEntry(currentTarget)
    @subscribe atom.workspaceView, 'pane-container:active-pane-item-changed', => @refreshBookmarksList()
    # turn off default scrolling behavior from ScrollView
    @off 'core:move-up'
    @off 'core:move-down'
    @command 'core:move-up', => @moveUp()
    @command 'core:move-down', => @moveDown()

  toggle: ->
    if @isVisible()
      @detach()
    else
      @show()

  show: ->
    @attach() unless @hasParent()
    @focus()

  attach: ->
    atom.workspaceView.appendToRight(this)

  resizeStarted: =>
    $(document.body).on('mousemove', @resizeTreeView)
    $(document.body).on('mouseup', @resizeStopped)

  resizeStopped: =>
    $(document.body).off('mousemove', @resizeTreeView)
    $(document.body).off('mouseup', @resizeStopped)

  resizeTreeView: ({pageX}) =>
    width = $(document.body).width() - pageX
    @width(width)

  getLineText: (bookmark) ->
    bookmark.buffer.lineForRow(bookmark.marker.getStartPosition().row)?.trim()

  refreshBookmarksList: =>
    @list.empty()
    @unsubscribe(@editor)
    @editor = atom.workspace.getActiveEditor()
    @subscribe @editor, 'destroyed', => @unsubscribe()
    @subscribe @editor, 'editor:display-updated contents-modified', @refreshBookmarksList
    @subscribe @editor.getBuffer(), 'bookmarks:created bookmarks:destroyed', @refreshBookmarksList
    @populateBookmarks()

  populateBookmarks: ->
    attributes = class: 'bookmark'
    markers = @editor.findMarkers(attributes)
    for marker in markers
      bookmark = {marker, @editor}
      bookmarkListItem = @viewForItem(bookmark)
      bookmarkListItem.attr('data-line', marker.bufferMarker.getStartPosition().row)
      @list.append(bookmarkListItem)
    if markers.length is 0
      message = $$ ->
        @ul class: 'bookmark-navigator background-message centered', =>
          @li 'No Bookmarks found'
      @list.after(message)
    else
      @list.siblings('.bookmark-navigator.background-message').remove()

  viewForItem: (bookmark) ->
    bookmarkRow = bookmark.marker.bufferMarker.getStartPosition().row
    firstLine = bookmark.editor.buffer.lineForRow(bookmarkRow)?.trim()
    text = firstLine + ":" + bookmarkRow + 1

    $$ ->
      @li class: 'list-item bookmark-list-item', =>
        @span class: 'icon icon-bookmark line-number', bookmarkRow + 1 + ":", =>
        @span class: 'first-line', firstLine

  selectEntry: (entry) =>
    @deselect()
    entryRow = entry.attr('data-line')
    position = [entryRow, 0]
    @editor.setCursorBufferPosition?(position)
    entry.addClass('selected')

  deselect: ->
    @list.find('.selected').removeClass('selected')

  moveDown: ->
    selectedEntry = @list.find('.selected')
    if selectedEntry.next('.bookmark-list-item').hasClass('bookmark-list-item')
      @selectEntry(selectedEntry.next('.bookmark-list-item'))
    @list.focus()

  moveUp: ->
    selectedEntry = @list.find('.selected')
    if selectedEntry.prev('.bookmark-list-item').hasClass('bookmark-list-item')
      @selectEntry(selectedEntry.prev('.bookmark-list-item'))
    @list.focus()
