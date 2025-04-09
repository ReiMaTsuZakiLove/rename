rename - 使用说明

直接下载那个bat文件用就行

这是一个给文件统一名字的脚本，本脚本的对象是同文件夹中所有的文件，建议新建一个文件夹将需要改名的文件和本脚本放在一起

示例都是脸滚键盘打出来的，并无任何意义，如果想要增加功能可以自己加,目前支持以下指令

1. 普通删除模式
	格式: [要删除的字符串]

	示例: 输入[ThZu.Cc]  
	[ThZu.Cc]abp-664 →abp-664 
    
2. 添加前缀 (-a)
	格式: -a 前缀内容

	示例: 输入-a CTNOZ-  
	151→CTNOZ-151
    
3. 删除首个匹配前内容 (-b)
	格式: -b 删除第一组关键词及之前的所有内容 

	示例: -b あず希,  
	あず希,あず希が女性用バイ○グラとお酒を飲んでSEXしてみた →あず希が女性用バイ○グラとお酒を飲んでSEXしてみた
    
4. 将文件名中的关键词A改为关键词B(-c)
	格式: -c 原内容 新内容

	示例: -c 乙愛麗絲 乙アリス 
	MVSD-504 乙愛麗絲 → MVSD-504 乙アリス 
    
5. 从（第一个关键词A）到（第一个关键词B）之间包括关键词在内所有的字符都删除 (-ft)
	格式: -c 起始符 结束符

	示例: 输入-ft []
	[ThZu.Cc]WANZ-152→WANZ-152

通用功能说明：
	支持带空格参数（用引号包裹）
	自动处理文件名冲突（自动添加序号）
	排除系统保护文件（如pagefile.sys）
	空文件名自动设置为“1”

顺带提一嘴，用deepseek来debug真好用啊
