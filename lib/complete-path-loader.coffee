{Task} = require 'atom'
_fs = require 'fs-plus'
_path = require 'path'

module.exports =
  startTask: (callback) ->
    projectPaths = []
    taskPath = require.resolve('./load-paths-handler')
    followSymlinks = atom.config.get 'core.followSymlinks'
    ignoredNames = atom.config.get('zsy-fuzzy-finder.ignoredNames') ? []
    ignoredNames = ignoredNames.concat(atom.config.get('core.ignoredNames') ? [])
    ignoreVcsIgnores = atom.config.get('core.excludeVcsIgnoredPaths')

    editor = atom.workspace.getActiveTextEditor()
    proPaths = atom.project.getPaths()
    for pPath in proPaths
      if editor.getPath().indexOf(pPath) == -1
        continue
      else if editor.getPath().indexOf(pPath) != -1
        proPath = pPath
        break
    if not proPath
      return

    task = Task.once(
      taskPath,
      [proPath],
      followSymlinks,
      ignoreVcsIgnores,
      ignoredNames,
      false, ->
        callback(projectPaths)
    )

    task.on 'load-paths:paths-found', (paths) ->
      projectPaths.push(paths...)

    task


