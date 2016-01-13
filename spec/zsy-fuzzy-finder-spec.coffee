OpenPath = require '../lib/main'

describe "zsy-fuzzy-finder:open-external", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('zsy-fuzzy-finder')

  describe "when the zsy-fuzzy-finder:open-external event is triggered", ->
    it "hides and shows the modal panel", ->

      atom.commands.dispatch workspaceElement, 'zsy-fuzzy-finder:open-external'

      waitsForPromise ->
        activationPromise

      runs ->
        atom.commands.dispatch workspaceElement, 'zsy-fuzzy-finder:open-external'

describe "zsy-fuzzy-finder:complete-path", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('zsy-fuzzy-finder')

  describe "when the zsy-fuzzy-finder:complete-path event is triggered", ->
    it "hides and shows the modal panel", ->

      atom.commands.dispatch workspaceElement, 'zsy-fuzzy-finder:complete-path'

      waitsForPromise ->
        activationPromise

      runs ->
        atom.commands.dispatch workspaceElement, 'zsy-fuzzy-finder:complete-path'
