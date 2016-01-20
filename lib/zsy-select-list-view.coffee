path = require 'path'
{Point, CompositeDisposable} = require 'atom'
{$, $$, SelectListView} = require 'atom-space-pen-views'
{repositoryForPath} = require './helpers'
fs = require 'fs-plus'
fuzzaldrin = require 'fuzzaldrin'
fuzzaldrinPlus = require 'fuzzaldrin-plus'

module.exports =
class ZsySelectListView extends SelectListView
  filePaths: null
  projectRelativePaths: null
  subscriptions: null
  alternateScoring: false
  openExternal: false

  initialize: ->
    super

    @addClass('zsy-fuzzy-finder')
    @setMaxItems(10)
    @subscriptions = new CompositeDisposable

    @alternateScoring = atom.config.get 'zsy-fuzzy-finder.useAlternateScoring'
    @openExternal = atom.config.get 'zsy-fuzzy-finder.openExternal'
    @subscriptions.add atom.config.onDidChange 'zsy-fuzzy-finder.useAlternateScoring', ({newValue}) => @alternateScoring = newValue


  getFilterKey: ->
    'projectRelativePath'

  cancel: ->
    super

  destroy: ->
    @cancel()
    @panel?.destroy()
    @subscriptions?.dispose()
    @subscriptions = null

  viewForItem: ({filePath, projectRelativePath}) ->

    # Style matched characters in search results
    filterQuery = @getFilterQuery()

    if @alternateScoring
      matches = fuzzaldrinPlus.match(projectRelativePath, filterQuery)
    else
      matches = fuzzaldrin.match(projectRelativePath, filterQuery)

    $$ ->

      highlighter = (path, matches, offsetIndex) =>
        lastIndex = 0
        matchedChars = [] # Build up a set of matched chars to be more semantic

        for matchIndex in matches
          matchIndex -= offsetIndex
          continue if matchIndex < 0 # If marking up the basename, omit path matches
          unmatched = path.substring(lastIndex, matchIndex)
          if unmatched
            @span matchedChars.join(''), class: 'character-match' if matchedChars.length
            matchedChars = []
            @text unmatched
          matchedChars.push(path[matchIndex])
          lastIndex = matchIndex + 1

        @span matchedChars.join(''), class: 'character-match' if matchedChars.length

        # Remaining characters are plain text
        @text path.substring(lastIndex)


      @li class: 'two-lines', =>
        if (repo = repositoryForPath(filePath))?
          status = repo.getCachedPathStatus(filePath)
          if repo.isStatusNew(status)
            @div class: 'status status-added icon icon-diff-added'
          else if repo.isStatusModified(status)
            @div class: 'status status-modified icon icon-diff-modified'

        ext = path.extname(filePath)
        if fs.isDirectorySync(filePath)
          typeClass = 'icon-file-directory'
        else if ext == '.lnk'
          typeClass = 'icon-file-symlink-directory'
        else if fs.isReadmePath(filePath)
          typeClass = 'icon-book'
        else if fs.isCompressedExtension(ext)
          typeClass = 'icon-file-zip'
        else if fs.isImageExtension(ext)
          typeClass = 'icon-file-media'
        else if fs.isPdfExtension(ext)
          typeClass = 'icon-file-pdf'
        else if fs.isBinaryExtension(ext)
          typeClass = 'icon-file-binary'
        else
          typeClass = 'icon-file-text'
        fileBasename = path.basename(filePath)
        baseOffset = projectRelativePath.length - fileBasename.length

        if not projectRelativePath
          projectRelativePath = fileBasename

        @div class: "primary-line file icon #{typeClass}", 'data-name': fileBasename, 'data-path': projectRelativePath, -> highlighter(fileBasename, matches, baseOffset)
        @div class: 'secondary-line path no-icon', -> highlighter(projectRelativePath, matches, 0)

  populateList: ->
    if @isQueryALineJump()
      @list.empty()
      @setError('Jump to line in active editor')
    else if @alternateScoring
      @populateAlternateList()
    else
      super


  # Unfortunately  SelectListView do not allow inheritor to handle their own filtering.
  # That would be required to use external knowledge, for example: give a bonus to recent files.
  #
  # Or, in this case: test an alternate scoring algorithm.
  #
  # This is modified copy/paste from SelectListView#populateList, require jQuery!
  # Should be temporary

  populateAlternateList: ->

    return unless @items?

    filterQuery = @getFilterQuery()
    if filterQuery.length
      filteredItems = fuzzaldrinPlus.filter(@items, filterQuery, key: @getFilterKey())
    else
      filteredItems = @items

    @list.empty()
    if filteredItems.length
      @setError(null)

      for i in [0...Math.min(filteredItems.length, @maxItems)]
        item = filteredItems[i]
        itemView = $(@viewForItem(item))
        itemView.data('select-list-item', item)
        @list.append(itemView)

      @selectItemView(@list.find('li:first'))
    else
      @setError(@getEmptyMessage(@items.length, filteredItems.length))



  confirmSelection: ->
    item = @getSelectedItem()
    @confirmed(item, searchAllPanes: atom.config.get('zsy-fuzzy-finder.searchAllPanes'))

  confirmInvertedSelection: ->
    item = @getSelectedItem()
    @confirmed(item, searchAllPanes: not atom.config.get('zsy-fuzzy-finder.searchAllPanes'))

  isQueryALineJump: ->
    query = @filterEditorView.getModel().getText()
    colon = query.indexOf(':')
    trimmedPath = @getFilterQuery().trim()

    trimmedPath is '' and colon isnt -1

  getFilterQuery: ->
    query = super
    colon = query.indexOf(':')
    query = query[0...colon] if colon isnt -1
    # Normalize to backslashes on Windows
    query = query.replace(/\//g, '\\') if process.platform is 'win32'
    query


  setItems: (filePaths) ->
    super(@projectRelativePathsForFilePaths(filePaths))

  projectRelativePathsForFilePaths: (filePaths) ->
    # Don't regenerate project relative paths unless the file paths have changed
    if filePaths isnt @filePaths
      projectHasMultipleDirectories = atom.project.getDirectories().length > 1

      @filePaths = filePaths
      @projectRelativePaths = @filePaths.map (filePath) ->
        [rootPath, projectRelativePath] = atom.project.relativizePath(filePath)
        if rootPath and projectHasMultipleDirectories
          projectRelativePath = path.join(path.basename(rootPath), projectRelativePath)
        {filePath, projectRelativePath}

    @projectRelativePaths

  show: ->
    @storeFocusedElement()
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  hide: ->
    @panel?.hide()

  cancelled: ->
    @hide()
