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

全部建完后的样子，同时可以把最外层的src目录给删除了，用不着
![ls 查看监控状态](https://github.com/lenxeon/notes/blob/master/后端/201604/mvn实现项目模块化管理方案/step-08.png)


##各个模块的pom如何配置
我们先来假设一下场景：
1. 有一些公共的依赖，比如：commons-lang两个模块都需要依赖
1. mod-02对mod-01有依赖
1. apps模块需要同时依赖mod-01,mod-02两个模块

总的那个pom，添加commons-lang
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.lenxeon</groupId>
    <artifactId>myproject</artifactId>
    <packaging>pom</packaging>
    <version>1.0-SNAPSHOT</version>
    <modules>
        <module>mod-01</module>
        <module>mod-02</module>
        <module>apps</module>
    </modules>

    <dependencies>
        <dependency>
            <groupId>commons-lang</groupId>
            <artifactId>commons-lang</artifactId>
            <version>2.6</version>
        </dependency>
    </dependencies>


</project>
```


mod-02的pom，添加mod-01的依赖
```xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <artifactId>myproject</artifactId>
        <groupId>com.lenxeon</groupId>
        <version>1.0-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>

    <artifactId>mod-02</artifactId>
    <packaging>jar</packaging>

    <name>mod-02</name>
    <url>http://maven.apache.org</url>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>3.8.1</version>
            <scope>test</scope>
        </dependency>

        <dependency>
            <groupId>com.lenxeon</groupId>
            <artifactId>mod-01</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>

    </dependencies>
</project>
```


apps的pom，添加mod-01,mod-02的依赖
```xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <artifactId>myproject</artifactId>
        <groupId>com.lenxeon</groupId>
        <version>1.0-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>

    <artifactId>mod-02</artifactId>
    <packaging>jar</packaging>

    <name>mod-02</name>
    <url>http://maven.apache.org</url>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>3.8.1</version>
            <scope>test</scope>
        </dependency>

        <dependency>
            <groupId>com.lenxeon</groupId>
            <artifactId>mod-01</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>

        <dependency>
            <groupId>com.lenxeon</groupId>
            <artifactId>mod-02</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>

    </dependencies>
</project>
```
