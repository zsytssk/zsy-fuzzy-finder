module.exports =
  config:
    ignoredNames:
      type: 'array'
      default: []
      description: 'List of string glob patterns. Files and directories matching these patterns will be ignored. This list is merged with the list defined by the core `Ignored Names` config setting. Example: `.git, ._*, Thumbs.db`.'
    searchAllPanes:
      type: 'boolean'
      default: false
      description: 'Search all panes when opening files. If disabled, only the active pane is searched. Holding `shift` inverts this setting.'
    preserveLastSearch:
      type: 'boolean'
      default: false
      description: 'Remember the typed query when closing the fuzzy finder and use that as the starting query next time the fuzzy finder is opened.'
    useAlternateScoring:
      type: 'boolean'
      default: true
      description: 'Use an alternative scoring approach which prefers run of consecutive characters, acronyms and start of words. (Experimental)'
    openExternal:
      type: 'array'
      default: ['.psd', '.lnk']
      description: 'specify file open external app not use atom'

  activate: (state) ->
    @active = true

    atom.commands.add 'atom-workspace',
      'zsy-fuzzy-finder:toggle-file-finder': =>
        @createProjectView().toggle()

    process.nextTick => @startLoadPathsTask()

    for editor in atom.workspace.getTextEditors()
      editor.lastOpened = state[editor.getPath()]

    atom.workspace.observePanes (pane) ->
      pane.observeActiveItem (item) -> item?.lastOpened = Date.now()

  deactivate: ->
    if @zsyOpenExternalView?
      @zsyOpenExternalView.destroy()
      @zsyOpenExternalView = null
    if @bufferView?
      @bufferView.destroy()
      @bufferView = null
    if @gitStatusView?
      @gitStatusView.destroy()
      @gitStatusView = null
    @projectPaths = null
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

  startLoadPathsTask: ->
    @stopLoadPathsTask()

    return unless @active
    return if atom.project.getPaths().length is 0

    PathLoader = require './path-loader'
    @loadPathsTask = PathLoader.startTask (@projectPaths) =>
    @projectPathsSubscription = atom.project.onDidChangePaths =>
      @projectPaths = null
      @stopLoadPathsTask()

  stopLoadPathsTask: ->
    @projectPathsSubscription?.dispose()
    @projectPathsSubscription = null
    @loadPathsTask?.terminate()
    @loadPathsTask = null
