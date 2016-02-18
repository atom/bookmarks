_ = require 'underscore-plus'
{Subscriber} = require 'emissary'

module.exports =
class ReactBookmarks
  Subscriber.includeInto(this)

  constructor: (@editor) ->
    @subscribe atom.commands.add atom.views.getView(@editor),
      'bookmarks:toggle-bookmark': @toggleBookmark
      'bookmarks:jump-to-next-bookmark': @jumpToNextBookmark
      'bookmarks:jump-to-previous-bookmark': @jumpToPreviousBookmark
      'bookmarks:clear-bookmarks': @clearBookmarks

    @addDecorationsForBookmarks()

  destroy: ->
    @commandsDisposable.destroy()

  toggleBookmark: =>
    cursors = @editor.getCursors()
    for cursor in cursors
      range = @editor.getSelectedBufferRange()
      bookmarks = @findBookmarkMarkers(intersectsBufferRowRange: [range.start.row, range.end.row])

      if bookmarks?.length > 0
        bookmark.destroy() for bookmark in bookmarks
      else
        @createBookmarkMarker(range)

  addDecorationsForBookmarks: =>
    for bookmark in @findBookmarkMarkers() when bookmark.isValid()
      @editor.decorateMarker(bookmark, {type: 'line-number', class: 'bookmarked'})

    null

  clearBookmarks: =>
    bookmark.destroy() for bookmark in @findBookmarkMarkers()

  jumpToNextBookmark: =>
    @jumpToBookmark('getNextBookmark')

  jumpToPreviousBookmark: =>
    @jumpToBookmark('getPreviousBookmark')

  jumpToBookmark: (getBookmarkFunction) =>
    cursor = @editor.getLastCursor()
    position = cursor.getMarker().getStartBufferPosition()
    bookmarkMarker = @[getBookmarkFunction](position.row)

    if bookmarkMarker
      @editor.setSelectedBufferRange(bookmarkMarker.getBufferRange(), autoscroll: false)
      @editor.scrollToCursorPosition()
    else
      atom.beep()

  getPreviousBookmark: (bufferRow) ->
    markers = @findBookmarkMarkers()
    return null unless markers.length
    return markers[0] if markers.length is 1

    bookmarkIndex = _.sortedIndex markers, bufferRow, (marker) ->
      if marker.getBufferRange then marker.getBufferRange().start.row else marker

    bookmarkIndex--
    bookmarkIndex = markers.length - 1 if bookmarkIndex < 0

    markers[bookmarkIndex]

  getNextBookmark: (bufferRow) ->
    markers = @findBookmarkMarkers()
    return null unless markers.length
    return markers[0] if markers.length is 1

    bookmarkIndex = _.sortedIndex markers, bufferRow, (marker) ->
      if marker.getBufferRange then marker.getBufferRange().start.row else marker

    bookmarkIndex++ if markers[bookmarkIndex] and markers[bookmarkIndex].getBufferRange().start.row is bufferRow
    bookmarkIndex = 0 if bookmarkIndex >= markers.length

    markers[bookmarkIndex]

  createBookmarkMarker: (range) ->
    bookmark = @displayBuffer().markBufferRange(range, @bookmarkMarkerAttributes(invalidate: 'surround'))
    @subscribe bookmark.onDidChange ({isValid}) ->
      bookmark.destroy() unless isValid
    @editor.decorateMarker(bookmark, {type: 'line-number', class: 'bookmarked'})
    bookmark

  findBookmarkMarkers: (attributes={}) ->
    @displayBuffer().findMarkers(@bookmarkMarkerAttributes(attributes))

  bookmarkMarkerAttributes: (attributes={}) ->
    _.extend(attributes, class: 'bookmark')

  displayBuffer: ->
    @editor.displayBuffer
