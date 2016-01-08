## 文件名修改  
-| FuzzyFinder:> ZsyFuzzyFinder  
-| fuzzy-finder:> zsy-fuzzy-finder  

## 文件修改  
-| zsy-finder-view.coffee  

-> change line 8  
shell = require 'shell'  

-> change line 102  
ext = path.extname(filePath)  
if fs.isDirectorySync(filePath)  
  typeClass = 'icon-file-directory'  
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

-> line 211  
else if fs.isDirectorySync(filePath)  
  @cancel()  
  shell.openExternal("#{filePath}")  
else if path.extname(filePath) in @openExternal  
  @cancel()  
  shell.openExternal("#{filePath}")  

# main  
-> add line:19  
openExternal:  
  type: 'array'  
  default: ['.psd', '.lnk']  
  description: 'specify file open external app not use atom'  

# load-paths-handler.coffee  
-> line 80  
@pathLoaded(folderPath, ->)  
