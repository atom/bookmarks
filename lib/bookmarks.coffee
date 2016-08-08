_ = require 'underscore-plus'
{CompositeDisposable} = require 'atom'

module.exports =
class Bookmarks
  @deserialize: (editor, state) ->
    new Bookmarks(editor, editor.getMarkerLayer(state.markerLayerId))

  constructor: (@editor, @markerLayer) ->
    @disposables = new CompositeDisposable
    @disposables.add atom.commands.add atom.views.getView(@editor),
      'bookmarks:toggle-bookmark': @toggleBookmark
      'bookmarks:jump-to-next-bookmark': @jumpToNextBookmark
      'bookmarks:jump-to-previous-bookmark': @jumpToPreviousBookmark
      'bookmarks:clear-bookmarks': @clearBookmarks

    markerLayerOptions = if @editor.displayLayer? then {persistent: true} else {maintainHistory: true}
    @markerLayer ?= @editor.addMarkerLayer(markerLayerOptions)
    @decorationLayer = @editor.decorateMarkerLayer(@markerLayer, {type: 'line-number', class: 'bookmarked'})
    @disposables.add @editor.onDidDestroy(@destroy.bind(this))

  destroy: ->
    @deactivate()
    @markerLayer.destroy()

  deactivate: ->
    @decorationLayer.destroy()
    @disposables.dispose()

  serialize: ->
    {markerLayerId: @markerLayer.id}

  toggleBookmark: =>
    for range in @editor.getSelectedBufferRanges()
      bookmarks = @markerLayer.findMarkers(intersectsRowRange: [range.start.row, range.end.row])

      if bookmarks?.length > 0
        bookmark.destroy() for bookmark in bookmarks
      else
        @createBookmarkMarker(range)

  clearBookmarks: =>
    bookmark.destroy() for bookmark in @markerLayer.getMarkers()

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
    markers = @markerLayer.getMarkers()
    return null unless markers.length
    return markers[0] if markers.length is 1

    bookmarkIndex = _.sortedIndex markers, bufferRow, (marker) ->
      if marker.getBufferRange then marker.getBufferRange().start.row else marker

    bookmarkIndex--
    bookmarkIndex = markers.length - 1 if bookmarkIndex < 0

    markers[bookmarkIndex]

  getNextBookmark: (bufferRow) ->
    markers = @markerLayer.getMarkers()
    return null unless markers.length
    return markers[0] if markers.length is 1

    bookmarkIndex = _.sortedIndex markers, bufferRow, (marker) ->
      if marker.getBufferRange then marker.getBufferRange().start.row else marker

    bookmarkIndex++ if markers[bookmarkIndex] and markers[bookmarkIndex].getBufferRange().start.row is bufferRow
    bookmarkIndex = 0 if bookmarkIndex >= markers.length

    markers[bookmarkIndex]

  createBookmarkMarker: (range) ->
    bookmark = @markerLayer.markBufferRange(range, {invalidate: 'surround'})
    @disposables.add bookmark.onDidChange ({isValid}) -> bookmark.destroy() unless isValid
    bookmark
