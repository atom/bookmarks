_ = require 'underscore-plus'
{Subscriber} = require 'emissary'

module.exports =
class Bookmarks
  Subscriber.includeInto(this)

  constructor: (editorView) ->
    {@editor, @gutter} = editorView

    @subscribe editorView, 'editor:display-updated', @renderBookmarkMarkers
    @subscribe @editor.getBuffer(), 'bookmarks:created bookmarks:destroyed', @renderBookmarkMarkers
    @subscribe @editor, 'destroyed', => @unsubscribe()

    @subscribeToCommand editorView, 'bookmarks:toggle-bookmark', @toggleBookmark
    @subscribeToCommand editorView, 'bookmarks:jump-to-next-bookmark', @jumpToNextBookmark
    @subscribeToCommand editorView, 'bookmarks:jump-to-previous-bookmark', @jumpToPreviousBookmark
    @subscribeToCommand editorView, 'bookmarks:clear-bookmarks', @clearBookmarks

  toggleBookmark: =>
    cursors = @editor.getCursors()
    for cursor in cursors
      position = cursor.getBufferPosition()
      bookmarks = @findBookmarkMarkers(startBufferRow: position.row)

      if bookmarks?.length > 0
        bookmark.destroy() for bookmark in bookmarks
        @editor.getBuffer().emit 'bookmarks:destroyed'
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
    for marker in markers when marker.isValid()
      row = marker.getBufferRange().start.row
      @gutter.addClassToLine(row, 'bookmarked')

    null

  jumpToBookmark: (getBookmarkFunction) =>
    cursor = @editor.getCursor()
    position = cursor.getBufferPosition()
    bookmarkMarker = @[getBookmarkFunction](position.row)

    if bookmarkMarker
      @editor.setSelectedBufferRange(bookmarkMarker.getBufferRange(), autoscroll: true)
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
    bookmark = @displayBuffer().markBufferRange(range, @bookmarkMarkerAttributes(invalidate: 'surround'))
    @subscribe bookmark, 'changed', ({isValid}) ->
      bookmark.destroy() unless isValid
    @editor.getBuffer().emit 'bookmarks:created'
    bookmark

  findBookmarkMarkers: (attributes={}) ->
    @displayBuffer().findMarkers(@bookmarkMarkerAttributes(attributes))

  bookmarkMarkerAttributes: (attributes={}) ->
    _.extend(attributes, class: 'bookmark')

  displayBuffer: ->
    @editor.displayBuffer
