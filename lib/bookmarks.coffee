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
      position = cursor.getBufferPosition()
      bookmarks = @findBookmarkMarkers(startBufferRow: position.row)

      if bookmarks?.length > 0
        bookmark.destroy() for bookmark in bookmarks
      else
        @createBookmarkMarker(position.row)

  addDecorationsForBookmarks: =>
    for bookmark in @findBookmarkMarkers() when bookmark.isValid()
      @editor.decorateMarker(bookmark, {type: 'gutter', class: 'bookmarked'})

    null

  clearBookmarks: =>
    bookmark.destroy() for bookmark in @findBookmarkMarkers()

  jumpToNextBookmark: =>
    @jumpToBookmark('getNextBookmark')

  jumpToPreviousBookmark: =>
    @jumpToBookmark('getPreviousBookmark')

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
    @editor.decorateMarker(bookmark, {type: 'gutter', class: 'bookmarked'})
    bookmark

  findBookmarkMarkers: (attributes={}) ->
    @displayBuffer().findMarkers(@bookmarkMarkerAttributes(attributes))

  bookmarkMarkerAttributes: (attributes={}) ->
    _.extend(attributes, class: 'bookmark')

  displayBuffer: ->
    @editor.displayBuffer
