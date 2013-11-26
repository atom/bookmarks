{$, _} = require 'atom'

module.exports =
class Bookmarks
  @activate: ->
    bookmarksList = null

    atom.workspaceView.command 'bookmarks:view-all', ->
      unless bookmarksList?
        BookmarksListView = require './bookmarks-view'
        bookmarksList = new BookmarksListView()
      bookmarksList.toggle()

    atom.workspaceView.eachEditor (editor) ->
      new Bookmarks(editor) if editor.attached and editor.getPane()?

  editor: null

  constructor: (@editor) ->
    @gutter = @editor.gutter
    @editor.on 'editor:display-updated', @renderBookmarkMarkers

    @editor.command 'bookmarks:toggle-bookmark', @toggleBookmark
    @editor.command 'bookmarks:jump-to-next-bookmark', @jumpToNextBookmark
    @editor.command 'bookmarks:jump-to-previous-bookmark', @jumpToPreviousBookmark
    @editor.command 'bookmarks:clear-bookmarks', @clearBookmarks

  toggleBookmark: =>
    cursors = @editor.getCursors()
    for cursor in cursors
      position = cursor.getBufferPosition()
      bookmarks = @findBookmarkMarkers(startBufferRow: position.row)

      if bookmarks and bookmarks.length
        bookmark.destroy() for bookmark in bookmarks
      else
        newmark = @createBookmarkMarker(position.row)

    @renderBookmarkMarkers()

  clearBookmarks: =>
    bookmark.destroy() for bookmark in @findBookmarkMarkers()
    @renderBookmarkMarkers()

  jumpToNextBookmark: =>
    @jumpToBookmark('getNextBookmark')

  jumpToPreviousBookmark: =>
    @jumpToBookmark('getPreviousBookmark')

  renderBookmarkMarkers: =>
    return unless @gutter.isVisible()

    @gutter.removeClassFromAllLines('bookmarked')

    markers = @findBookmarkMarkers()
    for marker in markers
      row = marker.getBufferRange().start.row
      @gutter.addClassToLine(row, 'bookmarked')

    null

  ### Internal ###

  jumpToBookmark: (getBookmarkFunction) =>
    cursor = @editor.getCursor()
    position = cursor.getBufferPosition()
    bookmarkMarker = @[getBookmarkFunction](position.row)

    if bookmarkMarker
      @editor.activeEditSession.setSelectedBufferRange(bookmarkMarker.getBufferRange(), autoscroll: true)
    else
      atom.beep()

  getPreviousBookmark: (bufferRow) ->
    markers = @findBookmarkMarkers()
    return null unless markers.length
    return markers[0] if markers.length == 1

    bookmarkIndex = _.sortedIndex markers, bufferRow, (marker) ->
      if marker.getBufferRange then marker.getBufferRange().start.row else marker

    bookmarkIndex--
    bookmarkIndex = markers.length - 1 if bookmarkIndex < 0

    markers[bookmarkIndex]

  getNextBookmark: (bufferRow) ->
    markers = @findBookmarkMarkers()
    return null unless markers.length
    return markers[0] if markers.length == 1

    bookmarkIndex = _.sortedIndex markers, bufferRow, (marker) ->
      if marker.getBufferRange then marker.getBufferRange().start.row else marker

    bookmarkIndex++ if markers[bookmarkIndex] and markers[bookmarkIndex].getBufferRange().start.row == bufferRow
    bookmarkIndex = 0 if bookmarkIndex >= markers.length

    markers[bookmarkIndex]

  createBookmarkMarker: (bufferRow) ->
    range = [[bufferRow, 0], [bufferRow, 0]]

    # TODO: use the 'surround' strategy when collaboration is merged in
    @displayBuffer().markBufferRange(range, @bookmarkMarkerAttributes(invalidationStrategy: 'never'))

  findBookmarkMarkers: (attributes={}) ->
    @displayBuffer().findMarkers(@bookmarkMarkerAttributes(attributes))

  bookmarkMarkerAttributes: (attributes={}) ->
    _.extend(attributes, class: 'bookmark', displayBufferId: @displayBuffer().id)

  displayBuffer: ->
    @editor.activeEditSession.displayBuffer
