_ = require 'underscore-plus'
{$} = require 'atom-space-pen-views'
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
    @createWrapIcon()

  createWrapIcon: ->
    wrapIcon = document.createElement('div')
    wrapIcon.classList.add('bookmark-wrap-icon')
    @wrapIcon = $(wrapIcon)

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

  showWrapIcon: (icon) ->
    editorView = atom.views.getView(@editor)
    return unless editorView?.parentNode?

    # Attach to the parent of the active editor, that way we can position it
    # correctly over the active editor.
    editorView.parentNode.appendChild(@wrapIcon[0])

    # FIXME: This animation should be in CSS
    @wrapIcon.attr('class', "bookmark-wrap-icon #{icon}").fadeIn()
    clearTimeout(@wrapTimeout)
    @wrapTimeout = setTimeout (=> @wrapIcon.fadeOut()), 1000

  getPreviousBookmark: (bufferRow) ->
    markers = @markerLayer.getMarkers()
    return null unless markers.length
    return markers[0] if markers.length is 1

    bookmarkIndex = _.sortedIndex markers, bufferRow, (marker) ->
      if marker.getBufferRange then marker.getBufferRange().start.row else marker

    bookmarkIndex--

    if bookmarkIndex < 0
      if atom.config.get('bookmarks.wrapBuffer')
        @showWrapIcon('icon-move-down')
        bookmarkIndex = markers.length - 1
      else
        null

    markers[bookmarkIndex]

  getNextBookmark: (bufferRow) ->
    markers = @markerLayer.getMarkers()
    return null unless markers.length
    return markers[0] if markers.length is 1

    bookmarkIndex = _.sortedIndex markers, bufferRow, (marker) ->
      if marker.getBufferRange then marker.getBufferRange().start.row else marker

    bookmarkIndex++ if markers[bookmarkIndex] and markers[bookmarkIndex].getBufferRange().start.row is bufferRow

    if bookmarkIndex >= markers.length
      if atom.config.get('bookmarks.wrapBuffer')
        @showWrapIcon('icon-move-up')
        bookmarkIndex = 0
      else
        null

    markers[bookmarkIndex]

  createBookmarkMarker: (range) ->
    bookmark = @markerLayer.markBufferRange(range, {invalidate: 'surround'})
    @disposables.add bookmark.onDidChange ({isValid}) -> bookmark.destroy() unless isValid
    bookmark
