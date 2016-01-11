## 功能  
# 外部打开  
-> open-external  
-> open_external_list  

# 补全路劲  
-> complete-path  
-> complete_path_list  
-| 只遍历当前的 project 文件夹  
-> 遍历文件的方法必须能接受参数  
-> folder + psd lnk 这种怎么加进去  

## 难点  
-| 查找文件  
-| 异步加载  
-| 缓存结果  


## 附加功能  
-| 复制图片的大小..  
-| 记录 打开的历史  
-> atom plugin save cache  
---&&---  
-| 实在没有办法就放在一个文件里面  


## 问题  
-? 能不能公用一个load file 方法  
-> 这改的乱起八糟，不如自己从头开始写 方法  
-> 或者先尝试改然后再去，怎么重写  

## 其他  
-| pathloader 和其他的没有关系， 不要在里面搞一大堆参数 很恶心