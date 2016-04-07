Bookmarks = null
ReactBookmarks = null
BookmarksView = null

module.exports =
  activate: ->
    editorsBookmarks = []
    bookmarksView = null

    atom.commands.add 'atom-workspace',
      'bookmarks:view-all', ->
        unless bookmarksList?
          BookmarksView ?= require './bookmarks-view'
          bookmarksView = new BookmarksView(editorsBookmarks)
        bookmarksView.toggle()

    atom.workspace.observeTextEditors (textEditor) ->
      Bookmarks ?= require './bookmarks'
      editorsBookmarks.push(new Bookmarks(textEditor))
