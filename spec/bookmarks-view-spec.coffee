{WorkspaceView} = require 'atom'

describe "Bookmarks package", ->
  [editor, editSession, displayBuffer] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspace = atom.workspaceView.model
    atom.workspaceView.openSync('sample.js')
    atom.workspaceView.enableKeymap()

    waitsForPromise ->
      atom.packages.activatePackage('bookmarks')

    runs ->
      atom.workspaceView.attachToDom()
      editor = atom.workspaceView.getActiveView()
      editSession = editor.editor
      displayBuffer = editSession.displayBuffer
      spyOn(atom, 'beep')

  describe "toggling bookmarks", ->
    it "creates a marker when toggled", ->
      editSession.setCursorBufferPosition([3, 10])
      expect(displayBuffer.findMarkers(class: 'bookmark').length).toEqual 0

      editor.trigger 'bookmarks:toggle-bookmark'

      markers = displayBuffer.findMarkers(class: 'bookmark')
      expect(markers.length).toEqual 1
      expect(markers[0].getBufferRange()).toEqual [[3, 0], [3, 0]]

    it "removes marker when toggled", ->
      editSession.setCursorBufferPosition([3, 10])
      expect(displayBuffer.findMarkers(class: 'bookmark').length).toEqual 0

      editor.trigger 'bookmarks:toggle-bookmark'
      expect(displayBuffer.findMarkers(class: 'bookmark').length).toEqual 1

      editor.trigger 'bookmarks:toggle-bookmark'
      expect(displayBuffer.findMarkers(class: 'bookmark').length).toEqual 0

    it "toggles proper classes on proper gutter row", ->
      editSession.setCursorBufferPosition([3, 10])
      expect(editor.find('.bookmarked').length).toEqual 0

      editor.trigger 'bookmarks:toggle-bookmark'

      lines = editor.find('.bookmarked')
      expect(lines.length).toEqual 1
      expect(lines).toHaveClass 'line-number-3'

      editor.trigger 'bookmarks:toggle-bookmark'
      expect(editor.find('.bookmarked').length).toEqual 0

    it "clears all bookmarks", ->
      editSession.setCursorBufferPosition([3, 10])
      editor.trigger 'bookmarks:toggle-bookmark'
      editSession.setCursorBufferPosition([5, 0])
      editor.trigger 'bookmarks:toggle-bookmark'

      editor.trigger 'bookmarks:clear-bookmarks'

      expect(editor.find('.bookmarked').length).toEqual 0
      expect(displayBuffer.findMarkers(class: 'bookmark')).toHaveLength 0

  describe "when a bookmark is invalidated", ->
    it "creates a marker when toggled", ->
      editSession.setCursorBufferPosition([3, 10])
      expect(displayBuffer.findMarkers(class: 'bookmark').length).toEqual 0

      editor.trigger 'bookmarks:toggle-bookmark'
      markers = displayBuffer.findMarkers(class: 'bookmark')
      expect(markers.length).toEqual 1

      editor.setText('')
      markers = displayBuffer.findMarkers(class: 'bookmark')
      expect(markers.length).toEqual 0

  describe "jumping between bookmarks", ->

    it "doesnt die when no bookmarks", ->
      editSession.setCursorBufferPosition([5, 10])

      editor.trigger 'bookmarks:jump-to-next-bookmark'
      expect(editSession.getCursor().getBufferPosition()).toEqual [5, 10]
      expect(atom.beep.callCount).toBe 1

      editor.trigger 'bookmarks:jump-to-previous-bookmark'
      expect(editSession.getCursor().getBufferPosition()).toEqual [5, 10]
      expect(atom.beep.callCount).toBe 2

    describe "with one bookmark", ->
      beforeEach ->
        editSession.setCursorBufferPosition([2, 0])
        editor.trigger 'bookmarks:toggle-bookmark'

      it "jump-to-next-bookmark jumps to the right place", ->
        editSession.setCursorBufferPosition([0, 0])

        editor.trigger 'bookmarks:jump-to-next-bookmark'
        expect(editSession.getCursor().getBufferPosition()).toEqual [2, 0]

        editor.trigger 'bookmarks:jump-to-next-bookmark'
        expect(editSession.getCursor().getBufferPosition()).toEqual [2, 0]

        editSession.setCursorBufferPosition([5, 0])

        editor.trigger 'bookmarks:jump-to-next-bookmark'
        expect(editSession.getCursor().getBufferPosition()).toEqual [2, 0]

      it "jump-to-previous-bookmark jumps to the right place", ->
        editSession.setCursorBufferPosition([0, 0])

        editor.trigger 'bookmarks:jump-to-previous-bookmark'
        expect(editSession.getCursor().getBufferPosition()).toEqual [2, 0]

        editor.trigger 'bookmarks:jump-to-previous-bookmark'
        expect(editSession.getCursor().getBufferPosition()).toEqual [2, 0]

        editSession.setCursorBufferPosition([5, 0])

        editor.trigger 'bookmarks:jump-to-previous-bookmark'
        expect(editSession.getCursor().getBufferPosition()).toEqual [2, 0]

    describe "with bookmarks", ->
      beforeEach ->
        editSession.setCursorBufferPosition([2, 0])
        editor.trigger 'bookmarks:toggle-bookmark'

        editSession.setCursorBufferPosition([10, 0])
        editor.trigger 'bookmarks:toggle-bookmark'

      it "jump-to-next-bookmark finds next bookmark", ->
        editSession.setCursorBufferPosition([0, 0])

        editor.trigger 'bookmarks:jump-to-next-bookmark'
        expect(editSession.getCursor().getBufferPosition()).toEqual [2, 0]

        editor.trigger 'bookmarks:jump-to-next-bookmark'
        expect(editSession.getCursor().getBufferPosition()).toEqual [10, 0]

        editor.trigger 'bookmarks:jump-to-next-bookmark'
        expect(editSession.getCursor().getBufferPosition()).toEqual [2, 0]

        editSession.setCursorBufferPosition([11, 0])

        editor.trigger 'bookmarks:jump-to-next-bookmark'
        expect(editSession.getCursor().getBufferPosition()).toEqual [2, 0]

      it "jump-to-previous-bookmark finds previous bookmark", ->
        editSession.setCursorBufferPosition([0, 0])

        editor.trigger 'bookmarks:jump-to-previous-bookmark'
        expect(editSession.getCursor().getBufferPosition()).toEqual [10, 0]

        editor.trigger 'bookmarks:jump-to-previous-bookmark'
        expect(editSession.getCursor().getBufferPosition()).toEqual [2, 0]

        editor.trigger 'bookmarks:jump-to-previous-bookmark'
        expect(editSession.getCursor().getBufferPosition()).toEqual [10, 0]

        editSession.setCursorBufferPosition([11, 0])

        editor.trigger 'bookmarks:jump-to-previous-bookmark'
        expect(editSession.getCursor().getBufferPosition()).toEqual [10, 0]

  describe "browsing bookmarks", ->
    it "displays a select list of all bookmarks", ->
      editSession.setCursorBufferPosition([0])
      editor.trigger 'bookmarks:toggle-bookmark'
      editSession.setCursorBufferPosition([2])
      editor.trigger 'bookmarks:toggle-bookmark'
      editSession.setCursorBufferPosition([4])
      editor.trigger 'bookmarks:toggle-bookmark'

      atom.workspaceView.trigger 'bookmarks:view-all'

      bookmarks = atom.workspaceView.find('.bookmarks-view')
      expect(bookmarks).toExist()
      expect(bookmarks.find('.bookmark').length).toBe 3
      expect(bookmarks.find('.bookmark:eq(0)').find('.primary-line').text()).toBe 'sample.js:1'
      expect(bookmarks.find('.bookmark:eq(0)').find('.secondary-line').text()).toBe 'var quicksort = function () {'
      expect(bookmarks.find('.bookmark:eq(1)').find('.primary-line').text()).toBe 'sample.js:3'
      expect(bookmarks.find('.bookmark:eq(1)').find('.secondary-line').text()).toBe 'if (items.length <= 1) return items;'
      expect(bookmarks.find('.bookmark:eq(2)').find('.primary-line').text()).toBe 'sample.js:5'
      expect(bookmarks.find('.bookmark:eq(2)').find('.secondary-line').text()).toBe 'while(items.length > 0) {'

    describe "when a bookmark is selected", ->
      it "sets the cursor to the location the bookmark", ->
        editSession.setCursorBufferPosition([8])
        editor.trigger 'bookmarks:toggle-bookmark'
        editSession.setCursorBufferPosition([0])

        atom.workspaceView.trigger 'bookmarks:view-all'

        bookmarks = atom.workspaceView.find('.bookmarks-view')
        expect(bookmarks).toExist()
        bookmarks.find('.bookmark').mousedown().mouseup()
        expect(editSession.getCursorBufferPosition()).toEqual [8, 0]
