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
    openexternal =  atom.config.get('zsy-fuzzy-finder.openExternal')

    task = Task.once(
      taskPath,
      atom.project.getPaths(),
      followSymlinks,
      ignoreVcsIgnores,
      ignoredNames,
      true, ->
        callback(projectPaths)
    )

    task.on 'load-paths:paths-found', (paths) ->
      if not paths
        return
      for path in paths
          if _fs.isDirectorySync(path)
              projectPaths.push(path)
          else if _path.extname(path) in openexternal
              projectPaths.push(path)

    task
