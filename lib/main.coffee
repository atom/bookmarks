Bookmarks = null
BookmarksView = null

module.exports =
  activate: ->
    bookmarksView = null

    atom.workspaceView.command 'bookmarks:view-all', ->
      unless bookmarksList?
        BookmarksView ?= require './bookmarks-view'
        bookmarksView = new BookmarksView()
      bookmarksView.toggle()

    atom.workspaceView.eachEditorView (editor) ->
      if editor.attached and editor.getPane()?
        Bookmarks ?= require './bookmarks'
        new Bookmarks(editor)
