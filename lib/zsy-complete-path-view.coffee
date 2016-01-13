{$} = require 'atom-space-pen-views'
{Disposable, CompositeDisposable} = require 'atom'
humanize = require 'humanize-plus'
fs = require 'fs-plus'
shell = require 'shell'

ZsySelectListView = require './zsy-select-list-view.coffee'
PathLoader = require './complete-path-loader'

module.exports =
class ZsyCompletePathView extends ZsySelectListView
  paths: null
  reloadPaths: true
  reloadAfterFirstLoad: false

  initialize: (@paths) ->
    super
    @disposables = new CompositeDisposable
    @reloadPaths = false if @paths?.length > 0

    windowFocused = =>
      # return
      if @paths?
        @reloadPaths = true
      else
        # The window gained focused while the first task was still running
        # so let it complete but reload the paths on the next populate call.
        @reloadAfterFirstLoad = true

    window.addEventListener('focus', windowFocused)
    @disposables.add new Disposable -> window.removeEventListener('focus', windowFocused)

    @subscribeToConfig()

    @disposables.add atom.project.onDidChangePaths =>
      @reloadPaths = true
      @paths = null

  subscribeToConfig: ->
    @disposables.add atom.config.onDidChange 'zsy-fuzzy-finder.ignoredNames', =>
      @reloadPaths = true

    @disposables.add atom.config.onDidChange 'core.followSymlinks', =>
      @reloadPaths = true

    @disposables.add atom.config.onDidChange 'core.ignoredNames', =>
      @reloadPaths = true

    @disposables.add atom.config.onDidChange 'core.excludeVcsIgnoredPaths', =>
      @reloadPaths = true

  toggle: ->
    editor = atom.workspace.getActiveTextEditor()
    proPaths = atom.project.getPaths()
    if not editor.getPath()
      return event.abortKeyBinding()
    for pPath in proPaths
      if editor.getPath().indexOf(pPath) == -1
        continue
      else if editor.getPath().indexOf(pPath) != -1
        proPath = pPath
        break
    if not proPath
      return event.abortKeyBinding()
    if @panel?.isVisible()
      @cancel()
    else
      @populate()
      @show()

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'Project is empty'
    else
      super

  populate: ->
    @setItems(@paths) if @paths?

    if atom.project.getPaths().length is 0
      @setItems([])
      return

    if @reloadPaths
      @reloadPaths = false

      task = @runLoadPathsTask =>
        if @reloadAfterFirstLoad
          @reloadPaths = true
          @reloadAfterFirstLoad = false
        @populate()

      if @paths?.length
        @setLoading("Reindexing project\u2026")
      else
        @setLoading("Indexing project\u2026")
        @loadingBadge.text('0')
        pathsFound = 0
        task.on 'load-paths:paths-found', (paths) =>
          pathsFound += paths.length
          @loadingBadge.text(humanize.intComma(pathsFound))

  confirmed: ({filePath}={}, openOptions) ->
    _path = require 'path'
    if not filePath
      @cancel()
    else
      @cancel()
      editor = atom.workspace.getActiveTextEditor()
      curDir = _path.dirname(editor.getPath())
      relativePath = _path.relative(curDir, filePath).replace(/\\/g, '/')
      # if relativePath.indexOf('.') != 0
      #   relativePath = './' + relativePath
      editor.insertText(relativePath)

  destroy: ->
    @loadPathsTask?.terminate()
    @disposables.dispose()
    super

  runLoadPathsTask: (fn) ->
    @loadPathsTask?.terminate()
    @loadPathsTask = PathLoader.startTask (@paths) =>
      @reloadPaths = false
      fn?()