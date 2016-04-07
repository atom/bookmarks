_ = require 'underscore-plus'
{CompositeDisposable} = require 'atom'

module.exports =
class ReactBookmarks
  constructor: (@editor) ->
    @disposables = new CompositeDisposable
    @disposables.add atom.commands.add atom.views.getView(@editor),
      'bookmarks:toggle-bookmark': @toggleBookmark
      'bookmarks:jump-to-next-bookmark': @jumpToNextBookmark
      'bookmarks:jump-to-previous-bookmark': @jumpToPreviousBookmark
      'bookmarks:clear-bookmarks': @clearBookmarks

    @addDecorationsForBookmarks()

  destroy: ->
    @disposables.dispose()

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
    bookmark = @editor.markBufferRange(range, @bookmarkMarkerAttributes(invalidate: 'surround'))
    @editor.decorateMarker(bookmark, {type: 'line-number', class: 'bookmarked'})
    @disposables.add bookmark.onDidChange ({isValid}) -> bookmark.destroy() unless isValid
    bookmark

  findBookmarkMarkers: (attributes={}) ->
    @editor.findMarkers(@bookmarkMarkerAttributes(attributes))

  bookmarkMarkerAttributes: (attributes={}) ->
    _.extend(attributes, class: 'bookmark')
