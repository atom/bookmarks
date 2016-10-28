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
    if @markerLayer.getMarkerCount() > 0
      bufferRow = @editor.getLastCursor().getMarker().getStartBufferPosition().row
      markers = @markerLayer.getMarkers().sort((a, b) -> a.compare(b))
      bookmarkMarker = markers.find((marker) -> marker.getBufferRange().start.row > bufferRow) ? markers[0]
      @editor.setSelectedBufferRange(bookmarkMarker.getBufferRange(), autoscroll: false)
      @editor.scrollToCursorPosition()
    else
      atom.beep()

  jumpToPreviousBookmark: =>
    if @markerLayer.getMarkerCount() > 0
      bufferRow = @editor.getLastCursor().getMarker().getStartBufferPosition().row
      markers = @markerLayer.getMarkers().sort((a, b) -> b.compare(a))
      bookmarkMarker = markers.find((marker) -> marker.getBufferRange().start.row < bufferRow) ? markers[0]
      @editor.setSelectedBufferRange(bookmarkMarker.getBufferRange(), autoscroll: false)
      @editor.scrollToCursorPosition()
    else
      atom.beep()

  createBookmarkMarker: (range) ->
    bookmark = @markerLayer.markBufferRange(range, {invalidate: 'surround'})
    @disposables.add bookmark.onDidChange ({isValid}) -> bookmark.destroy() unless isValid
    bookmark
