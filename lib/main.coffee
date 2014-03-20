Bookmarks = null
BookmarksView = null

module.exports =
  activate: ->
    bookmarksList = null

    atom.workspaceView.command 'bookmarks:view-all', ->
      unless bookmarksList?
        BookmarksListView ?= require './bookmarks-view'
        bookmarksList = new BookmarksListView()
      bookmarksList.toggle()

    atom.workspaceView.eachEditorView (editor) ->
      if editor.attached and editor.getPane()?
        Bookmarks ?= require './bookmarks'
        new Bookmarks(editor)
