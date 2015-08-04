path = require "path"
fs = require 'fs-plus'
{GitRepository} = require 'atom'

module.exports =
  repositoryCache: {}

  getRepoCache: ->
    module.exports.repositoryCache

  getRepoCacheSize: ->
    Object.keys(module.exports.repositoryCache).length

  resetRepoCache: ->
    module.exports.repositoryCache = {}
    
  repoForPath: (goalPath) ->
    result = null
    project = null
    _this = module.exports
    for projectPath, i in atom.project.getPaths()
      if goalPath.indexOf(projectPath) is 0
        project = projectPath
    # can't find related projects, so repo can't be assigned
    return unless project?
    walkUpwards = (startDir, toDir) ->
      if fs.existsSync(startDir + '/.git')
        for provider in atom.project.repositoryProviders
          if _this.repositoryCache[startDir]
            return _this.repositoryCache[startDir]
          for dProvider in atom.project.directoryProviders
            break if directory = dProvider.directoryForURISync(startDir)
          repo = GitRepository.open(startDir, {project: provider.project, \
                                               refreshOnWindowFocus: atom.config.get('tree-view.refreshVcsStatusOnFocusChange') > _this.getRepoCacheSize()})
          return null unless repo
          repo.onDidDestroy(-> delete _this.repositoryCache[startDir])
          _this.repositoryCache[startDir] = repo
          return repo
      if startDir is toDir
        return null
      dirName = path.dirname(startDir)
      return if dirName is startDir  # reached top
      return walkUpwards(dirName, project)
    return walkUpwards(path.normalize(goalPath), project)

  relativizePath: (goalPath) ->
    for projectPath in atom.project.getPaths()
      if goalPath is projectPath or goalPath.indexOf(projectPath + path.sep) is 0
        return [projectPath, path.relative(projectPath, goalPath)]
    [null, goalPath]
