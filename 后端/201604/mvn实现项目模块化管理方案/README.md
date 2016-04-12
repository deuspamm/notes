#mvn实现项目模块化管理方案

## 如果你有这样一个项目，你可能需要mvn实现项目模块化管理方案
1. 如果您有一个项目是一个长久的开发计划
1. 有至少中等应用的规模
1. 需要持续集成开发
1. 今后可能需要不同的团队或者人来负责不同的模块的代码
1. 希望有一个清晰的结构，而不是让所有程序员面对庞大的源码目录
1. 你不希望每一个开发人员都拿到所有的代码
1. 不希望每一次升级都需要漫长的编译等待过程
1. 不希望担心每天程序员会不会改错代码，会不会花很长时间去解决无尽的代码冲突

##先给两张图，看看鱼骨目前的模块化管理

* 整体想法
![ls 查看监控状态](https://github.com/lenxeon/notes/blob/master/后端/201604/mvn实现项目模块化管理方案/鱼骨服务体系架构.png)

* 项目中的模块化
![ls 查看监控状态](https://github.com/lenxeon/notes/blob/master/后端/201604/mvn实现项目模块化管理方案/mvn-all.png)

##如何建出上面的项目

先建一个maven的主项目
![ls 查看监控状态](https://github.com/lenxeon/notes/blob/master/后端/201604/mvn实现项目模块化管理方案/step-01.png)

![ls 查看监控状态](https://github.com/lenxeon/notes/blob/master/后端/201604/mvn实现项目模块化管理方案/step-02.png)

![ls 查看监控状态](https://github.com/lenxeon/notes/blob/master/后端/201604/mvn实现项目模块化管理方案/step-03.png)

添加两个模块，注意打勾和选择的类型
![ls 查看监控状态](https://github.com/lenxeon/notes/blob/master/后端/201604/mvn实现项目模块化管理方案/step-04.png)

![ls 查看监控状态](https://github.com/lenxeon/notes/blob/master/后端/201604/mvn实现项目模块化管理方案/step-05.png)

![ls 查看监控状态](https://github.com/lenxeon/notes/blob/master/后端/201604/mvn实现项目模块化管理方案/step-06.png)

添加一个web的模块，一会儿这个模块要依赖上面两个模块工作
![ls 查看监控状态](https://github.com/lenxeon/notes/blob/master/后端/201604/mvn实现项目模块化管理方案/step-07.png)

![ls 查看监控状态](https://github.com/lenxeon/notes/blob/master/后端/201604/mvn实现项目模块化管理方案/step-08.png)
