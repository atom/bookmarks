Bookmarks = null
ReactBookmarks = null
BookmarksView = null

module.exports =
  activate: ->
    bookmarksView = null

    atom.workspaceView.command 'bookmarks:view-all', ->
      unless bookmarksList?
        BookmarksView ?= require './bookmarks-view'
        bookmarksView = new BookmarksView()
      bookmarksView.toggle()

    atom.workspaceView.eachEditorView (editorView) ->
      if editorView.attached and editorView.getPane()?
        Bookmarks ?= require './bookmarks'
        new Bookmarks(editorView)
