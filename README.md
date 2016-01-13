copy form [atom/fuzzyfinder](https://github.com/atom/fuzzy-finder) for customize function.  

## function  
-| open folder and psd lnk in external app  
-| insert file path in fuzzyfinder  


## default shortcut  

```coffeescript  

	'.atom-workspace':  
		'alt-p': 'zsy-fuzzy-finder:open-external'  

	'atom-text-editor:not([mini])':  
		'alt-a': 'zsy-fuzzy-finder:toggle-complete-path'  

```