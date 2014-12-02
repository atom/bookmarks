Bookmarks = null
ReactBookmarks = null
BookmarksView = null

module.exports =
  activate: ->
    bookmarksView = null

    atom.commands.add 'atom-workspace',
      'bookmarks:view-all', =>
        unless bookmarksList?
          BookmarksView ?= require './bookmarks-view'
          bookmarksView = new BookmarksView()
        bookmarksView.toggle()

    atom.workspace.observeTextEditors (textEditor) =>
      Bookmarks ?= require './bookmarks'
      bookmarks = new Bookmarks(textEditor)
