module.exports =
  config:
    ignoredNames:
      type: 'array'
      default: []
      description: 'List of string glob patterns. Files and directories matching these patterns will be ignored. This list is merged with the list defined by the core `Ignored Names` config setting. Example: `.git, ._*, Thumbs.db`.'
    openExternal:
      type: 'array'
      default: ['.psd', '.lnk']
      description: 'specify file open in external app'

  activate: (state) ->
    @active = true

    atom.commands.add 'atom-workspace',
      'zsy-fuzzy-finder:open-external': =>
        @createProjectView().toggle()

    atom.commands.add 'atom-workspace',
      'zsy-fuzzy-finder:complete-path': =>
        @createCompleteView().toggle()

    process.nextTick => @startLoadPathsTask()

    for editor in atom.workspace.getTextEditors()
      editor.lastOpened = state[editor.getPath()]

    atom.workspace.observePanes (pane) ->
      pane.observeActiveItem (item) -> item?.lastOpened = Date.now()

  deactivate: ->
    if @zsyOpenExternalView?
      @zsyOpenExternalView.destroy()
      @zsyOpenExternalView = null
    if @zsyCompletePathView?
      @zsyCompletePathView.destroy()
      @zsyCompletePathView = null
    @projectPaths = null
    @completePaths = null
    @stopLoadPathsTask()
    @active = false

  serialize: ->
    paths = {}
    for editor in atom.workspace.getTextEditors()
      path = editor.getPath()
      paths[path] = editor.lastOpened if path?
    paths

  createProjectView: ->
    @stopLoadPathsTask()

    unless @zsyOpenExternalView?
      ZsyOpenExternalView  = require './zsy-open-external-view'
      @zsyOpenExternalView = new ZsyOpenExternalView(@projectPaths)
      @projectPaths = null
    @zsyOpenExternalView

  createCompleteView: ->
    @stopLoadPathsTask()
    @zsyCompletePathView = null
    ZsyCompletePathView  = require './zsy-complete-path-view'
    @zsyCompletePathView = new ZsyCompletePathView(@completePaths)
    @completePaths = null
    @zsyCompletePathView

  startLoadPathsTask: ->
    @stopLoadPathsTask()

    return unless @active
    return if atom.project.getPaths().length is 0

    PathLoader = require './external-path-loader'
    @loadPathsTask = PathLoader.startTask (@projectPaths) =>
    @projectPathsSubscription = atom.project.onDidChangePaths =>
      @projectPaths = null
      @stopLoadPathsTask()

  stopLoadPathsTask: ->
    @projectPathsSubscription?.dispose()
    @projectPathsSubscription = null
    @loadPathsTask?.terminate()
    @loadPathsTask = null
