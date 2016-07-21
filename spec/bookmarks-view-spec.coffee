{$} = require 'atom-space-pen-views'
{values} = require 'underscore-plus'

describe "Bookmarks package", ->
  [workspaceElement, editorElement, editor, bookmarks] = []

  bookmarkedRangesForEditor = (editor) ->
    values(editor.decorationsStateForScreenRowRange(0, editor.getLastScreenRow()))
      .filter (decoration) -> decoration.properties.class is 'bookmarked'
      .map (decoration) -> decoration.screenRange

  beforeEach ->
    spyOn(window, 'setImmediate').andCallFake (fn) -> fn()
    workspaceElement = atom.views.getView(atom.workspace)

    waitsForPromise ->
      atom.workspace.open('sample.js')

    waitsForPromise ->
      atom.packages.activatePackage('bookmarks').then (p) -> bookmarks = p.mainModule

    runs ->
      jasmine.attachToDOM(workspaceElement)
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      spyOn(atom, 'beep')

  describe "toggling bookmarks", ->
    describe "point marker bookmark", ->
      it "creates a marker when toggled", ->
        editor.setCursorBufferPosition([3, 10])
        expect(bookmarkedRangesForEditor(editor)).toEqual []
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor)).toEqual [[[3, 10], [3, 10]]]

      it "removes marker when toggled", ->
        editor.setCursorBufferPosition([3, 10])
        expect(bookmarkedRangesForEditor(editor).length).toBe 0

        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor).length).toBe 1

        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor).length).toBe 0

    describe "multiple point marker bookmark", ->
      it "creates multiple markers when toggled", ->
        editor.setCursorBufferPosition([3, 10])
        editor.addCursorAtBufferPosition([6, 11])
        expect(bookmarkedRangesForEditor(editor)).toEqual []
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor)).toEqual [[[3, 10], [3, 10]], [[6, 11], [6, 11]]]

      it "removes multiple markers when toggled", ->
        editor.setCursorBufferPosition([3, 10])
        editor.addCursorAtBufferPosition([6, 11])
        expect(bookmarkedRangesForEditor(editor).length).toBe 0
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor).length).toBe 2
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor).length).toBe 0

      it "adds and removes multiple markers at the same time", ->
        editor.setCursorBufferPosition([3, 10])
        expect(bookmarkedRangesForEditor(editor).length).toBe 0
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor)).toEqual [[[3, 10], [3, 10]]]

        editor.addCursorAtBufferPosition([6, 11])
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor)).toEqual [[[6, 11], [6, 11]]]

        editor.addCursorAtBufferPosition([8, 8])
        editor.addCursorAtBufferPosition([11, 8])
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor)).toEqual [[[3, 10], [3, 10]], [[8, 8], [8, 8]], [[11, 8], [11, 8]]]

        # reset cursors, and try multiple cursors on same line but different ranges
        editor.setCursorBufferPosition([8, 40])
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor)).toEqual [[[3, 10], [3, 10]], [[11, 8], [11, 8]]]

        editor.addCursorAtBufferPosition([3, 0])
        editor.addCursorAtBufferPosition([11, 0])
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor)).toEqual [[[8, 40], [8, 40]]]

        editor.setCursorBufferPosition([8, 0])
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor).length).toBe 0

    describe "single line range marker bookmark", ->
      it "created a marker when toggled", ->
        editor.setSelectedBufferRanges([[[3, 5], [3, 10]]])
        expect(bookmarkedRangesForEditor(editor)).toEqual []

        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'

        expect(bookmarkedRangesForEditor(editor)).toEqual [[[3, 5], [3, 10]]]

      it "removes marker when toggled", ->
        editor.setSelectedBufferRanges([[[3, 5], [3, 10]]])
        expect(bookmarkedRangesForEditor(editor).length).toBe 0

        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor).length).toBe 1

        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor).length).toBe 0

    describe "multi line range marker bookmark", ->
      it "created a marker when toggled", ->
        editor.setSelectedBufferRanges([[[1, 5], [3, 10]]])
        expect(bookmarkedRangesForEditor(editor)).toEqual []

        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'

        expect(bookmarkedRangesForEditor(editor)).toEqual [[[1, 5], [3, 10]]]

      it "removes marker when toggled", ->
        editor.setSelectedBufferRanges([[[1, 5], [3, 10]]])
        expect(bookmarkedRangesForEditor(editor).length).toBe 0

        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor).length).toBe 1

        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor).length).toBe 0

      it "removes marker when toggled inside bookmark", ->
        editor.setSelectedBufferRanges([[[1, 5], [3, 10]]])
        expect(bookmarkedRangesForEditor(editor).length).toBe 0

        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor).length).toBe 1

        editor.setCursorBufferPosition([2, 2])
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor).length).toBe 0

      it "removes marker when toggled outside bookmark on start row", ->
        editor.setSelectedBufferRanges([[[1, 5], [3, 10]]])
        expect(bookmarkedRangesForEditor(editor).length).toBe 0

        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor).length).toBe 1

        editor.setCursorBufferPosition([1, 2])
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor).length).toBe 0

      it "removes marker when toggled outside bookmark on end row", ->
        editor.setSelectedBufferRanges([[[1, 5], [3, 8]]])
        expect(bookmarkedRangesForEditor(editor).length).toBe 0

        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor).length).toBe 1

        editor.setCursorBufferPosition([3, 10])
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        expect(bookmarkedRangesForEditor(editor).length).toBe 0

    it "toggles proper classes on proper gutter row", ->
      editor.setCursorBufferPosition([3, 10])
      expect(editorElement.shadowRoot.querySelectorAll('.bookmarked').length).toBe 0

      atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
      lines = []

      waitsFor ->
        lines = editorElement.shadowRoot.querySelectorAll('.bookmarked')
        lines.length is 1

      runs ->
        expect(lines[0]).toHaveData("buffer-row", 3)
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'

      waitsFor ->
        editorElement.shadowRoot.querySelectorAll('.bookmarked').length is 0

    it "clears all bookmarks", ->
      editor.setCursorBufferPosition([3, 10])
      atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'

      waitsFor ->
        editorElement.shadowRoot.querySelectorAll('.bookmarked').length is 1

      runs ->
        editor.setCursorBufferPosition([5, 0])
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'

      waitsFor ->
        editorElement.shadowRoot.querySelectorAll('.bookmarked').length is 2

      runs ->
        atom.commands.dispatch editorElement, 'bookmarks:clear-bookmarks'

      waitsFor ->
        editorElement.shadowRoot.querySelectorAll('.bookmarked').length is 0

  describe "when a bookmark is invalidated", ->
    it "creates a marker when toggled", ->
      editor.setCursorBufferPosition([3, 10])
      expect(bookmarkedRangesForEditor(editor).length).toBe 0

      atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
      expect(bookmarkedRangesForEditor(editor).length).toBe 1

      editor.setText('')
      expect(bookmarkedRangesForEditor(editor).length).toBe 0

  describe "jumping between bookmarks", ->

    it "doesnt die when no bookmarks", ->
      editor.setCursorBufferPosition([5, 10])

      atom.commands.dispatch editorElement, 'bookmarks:jump-to-next-bookmark'
      expect(editor.getLastCursor().getBufferPosition()).toEqual [5, 10]
      expect(atom.beep.callCount).toBe 1

      atom.commands.dispatch editorElement, 'bookmarks:jump-to-previous-bookmark'
      expect(editor.getLastCursor().getBufferPosition()).toEqual [5, 10]
      expect(atom.beep.callCount).toBe 2

    describe "with one bookmark", ->
      beforeEach ->
        editor.setCursorBufferPosition([2, 0])
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'

      it "jump-to-next-bookmark jumps to the right place", ->
        editor.setCursorBufferPosition([0, 0])

        atom.commands.dispatch editorElement, 'bookmarks:jump-to-next-bookmark'
        expect(editor.getLastCursor().getBufferPosition()).toEqual [2, 0]

        atom.commands.dispatch editorElement, 'bookmarks:jump-to-next-bookmark'
        expect(editor.getLastCursor().getBufferPosition()).toEqual [2, 0]

        editor.setCursorBufferPosition([5, 0])

        atom.commands.dispatch editorElement, 'bookmarks:jump-to-next-bookmark'
        expect(editor.getLastCursor().getBufferPosition()).toEqual [2, 0]

      it "jump-to-previous-bookmark jumps to the right place", ->
        editor.setCursorBufferPosition([0, 0])

        atom.commands.dispatch editorElement, 'bookmarks:jump-to-previous-bookmark'
        expect(editor.getLastCursor().getBufferPosition()).toEqual [2, 0]

        atom.commands.dispatch editorElement, 'bookmarks:jump-to-previous-bookmark'
        expect(editor.getLastCursor().getBufferPosition()).toEqual [2, 0]

        editor.setCursorBufferPosition([5, 0])

        atom.commands.dispatch editorElement, 'bookmarks:jump-to-previous-bookmark'
        expect(editor.getLastCursor().getBufferPosition()).toEqual [2, 0]

    describe "with bookmarks", ->
      beforeEach ->
        editor.setCursorBufferPosition([2, 0])
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'

        editor.setSelectedBufferRanges([[[8, 4], [10, 0]]])
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'

      it "jump-to-next-bookmark finds next bookmark", ->
        editor.setCursorBufferPosition([0, 0])

        atom.commands.dispatch editorElement, 'bookmarks:jump-to-next-bookmark'
        expect(editor.getLastCursor().getBufferPosition()).toEqual [2, 0]

        atom.commands.dispatch editorElement, 'bookmarks:jump-to-next-bookmark'
        expect(editor.getLastCursor().getMarker().getBufferRange()).toEqual [[8, 4], [10, 0]]

        atom.commands.dispatch editorElement, 'bookmarks:jump-to-next-bookmark'
        expect(editor.getLastCursor().getBufferPosition()).toEqual [2, 0]

        editor.setCursorBufferPosition([11, 0])

        atom.commands.dispatch editorElement, 'bookmarks:jump-to-next-bookmark'
        expect(editor.getLastCursor().getBufferPosition()).toEqual [2, 0]

      it "jump-to-previous-bookmark finds previous bookmark", ->
        editor.setCursorBufferPosition([0, 0])

        atom.commands.dispatch editorElement, 'bookmarks:jump-to-previous-bookmark'
        expect(editor.getLastCursor().getMarker().getBufferRange()).toEqual [[8, 4], [10, 0]]

        atom.commands.dispatch editorElement, 'bookmarks:jump-to-previous-bookmark'
        expect(editor.getLastCursor().getBufferPosition()).toEqual [2, 0]

        atom.commands.dispatch editorElement, 'bookmarks:jump-to-previous-bookmark'
        expect(editor.getLastCursor().getMarker().getBufferRange()).toEqual [[8, 4], [10, 0]]

        editor.setCursorBufferPosition([11, 0])

        atom.commands.dispatch editorElement, 'bookmarks:jump-to-previous-bookmark'
        expect(editor.getLastCursor().getMarker().getBufferRange()).toEqual [[8, 4], [10, 0]]

  describe "browsing bookmarks", ->
    it "displays a select list of all bookmarks", ->
      editor.setCursorBufferPosition([0])
      atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
      editor.setCursorBufferPosition([2])
      atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
      editor.setCursorBufferPosition([4])
      atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'

      atom.commands.dispatch workspaceElement, 'bookmarks:view-all'

      bookmarks = $(workspaceElement).find('.bookmarks-view')
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
        editor.setCursorBufferPosition([8])
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        editor.setCursorBufferPosition([0])

        atom.commands.dispatch workspaceElement, 'bookmarks:view-all'

        bookmarks = $(workspaceElement).find('.bookmarks-view')
        expect(bookmarks).toExist()
        bookmarks.find('.bookmark').mousedown().mouseup()

        waitsFor ->
          editor.getCursorBufferPosition().isEqual([8, 0])

      it "searches the bookmark among all panes", ->
        editor.setCursorBufferPosition([8])
        atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
        editor.setCursorBufferPosition([0])

        pane1 = atom.workspace.getActivePane()
        pane1.splitRight()
        expect(atom.workspace.getActivePane()).not.toEqual pane1

        atom.commands.dispatch workspaceElement, 'bookmarks:view-all'
        bookmarkElement = workspaceElement.querySelector('.bookmarks-view .bookmark')
        atom.commands.dispatch bookmarkElement, 'core:confirm'

        waitsFor ->
          atom.workspace.getActivePane() is pane1

        runs ->
          expect(atom.workspace.getActiveTextEditor()).toEqual editor
          expect(editor.getCursorBufferPosition()).toEqual [8, 0]

  describe "serializing/deserializing bookmarks", ->
    [editor2, editorElement2] = []

    beforeEach ->
      waitsForPromise ->
        atom.workspace.open('sample.coffee').then (e) ->
          editor2 = e
          editorElement2 = atom.views.getView(editor2)

    it "restores bookmarks on all the previously open editors", ->
      editor.setCursorScreenPosition([1, 2])
      atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
      editor2.setCursorScreenPosition([4, 5])
      atom.commands.dispatch editorElement2, 'bookmarks:toggle-bookmark'

      expect(bookmarkedRangesForEditor(editor)).toEqual [[[1, 2], [1, 2]]]
      expect(bookmarkedRangesForEditor(editor2)).toEqual [[[4, 5], [4, 5]]]

      state = bookmarks.serialize()
      bookmarks.deactivate()
      atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
      atom.commands.dispatch editorElement2, 'bookmarks:toggle-bookmark'

      # toggling the bookmark has no effect when the package is deactivated.
      expect(bookmarkedRangesForEditor(editor)).toEqual []
      expect(bookmarkedRangesForEditor(editor2)).toEqual []

      bookmarks.activate(state)

      expect(bookmarkedRangesForEditor(editor)).toEqual [[[1, 2], [1, 2]]]
      expect(bookmarkedRangesForEditor(editor2)).toEqual [[[4, 5], [4, 5]]]

      atom.commands.dispatch editorElement, 'bookmarks:toggle-bookmark'
      atom.commands.dispatch editorElement2, 'bookmarks:toggle-bookmark'

      expect(bookmarkedRangesForEditor(editor)).toEqual []
      expect(bookmarkedRangesForEditor(editor2)).toEqual []
