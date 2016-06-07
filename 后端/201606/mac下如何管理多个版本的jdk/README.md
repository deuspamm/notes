#使用zookeeper+config-toolkit管理系统中的配置文件

## 场景及预期
1. mac下是默认有安装jdk1.6的，如果需要安装多个版本的jdk可以使用brew来安装，如果你还不知道mac下的homebrew赶快上网搜索一下吧
1.

## 偶然的机会了解到了config-toolkit
> 基于zookeeper，修改后集群自动同步，监听会实时将变化更新到系统中，采用map做为数据缓存，每次在Map中拿配置，界面也还不错
``` properties

* 动画演示
![ls](https://github.com/lenxeon/notes/blob/master/后端/201606/使用zookeeper+config-toolkit管理系统中的配置文件/config.gif)

* 管理界面
![ls](https://github.com/lenxeon/notes/blob/master/后端/201606/使用zookeeper+config-toolkit管理系统中的配置文件/config.png)


jenv enable-plugin export
