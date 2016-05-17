#dubbo学习总结

## 前言
1. 我是这样划分系统的： 工具库 + 平台规范 + 服务 + 业务

1.1 工具库：redis,memcache,zk,json,email,httpclient等，主要是常用工具的封装，规范，简化开发者的代码，降低使用者的门槛

1.2 平台规范：dao,各种抽象逻辑，自定义的annotion,json ObjectMapper,统一异常处理，一些通用逻辑，和工具的不同之处在于适用范围更小，带一些自定义的色彩，想要使用就必须遵守一定的规范

1.3 服务：服务之所以是服务相于工具来讲应该更强大，能力更强，这么举例：发送短信工具只需要能把短信发出去，有个日志就ok了，如果产品有更多的要求：重试策略，群发机制，定时机制，查询统计，下发限制，退订，等等到这个时候可能就不是一个简单的工具能完成的，需要将这块当成一个功能模块来做，而这个功能模块跟业务又不一样，它并不是一定要属于哪个系统的，只要你规划的够好，你可以为你们公司的其它所有有类似需求的场景提供服务，甚至为别的公司提供服务

> 需要注意的是：在这个系统中，我们将所有的业务也当成了服务来做

## 需求假设分析
1. 集中部署和分开部署，可以将所有的服务集中部署到一个jvm中，也可以支持每一个服务独立部署（如果真有一个业务的量很大的话）
1. 服务调用服务的情况如何处理

## 整体简绍

这张图展示了项目的整体结构
![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/dubbo学习总结/dubbo-all.png)

api模块的目录结构(主要是实体，自定异常，接口)
![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/dubbo学习总结/dubbo-api.png)

provider模块的目录结构（接口实现,dao,dao实现,其它）
![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/dubbo学习总结/dubbo-provider.png)

##独立部署的关键配置

先看其中一个provider的pom.xml文件,注意关键的plugins一段，首先它指定了main方法，其次它会解包dubbo.jar文件，并复制其中的启动脚本，assembly会将依赖和conf下的配置文件一并打包得到一个tar文件，具体的可以参考dubbo官方demo中的provider

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <artifactId>apps</artifactId>
        <groupId>com.zendlab.apps.module</groupId>
        <version>1.0-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>

    <artifactId>app-uc-user-provider</artifactId>

    <dependencies>
        <dependency>
            <groupId>com.zendlab.apps.module</groupId>
            <artifactId>app-uc-user-api</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>
        <dependency>
            <groupId>com.zendlab.apps.module</groupId>
            <artifactId>app-commons-api</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>

            <plugin>
                <artifactId>maven-dependency-plugin</artifactId>
                <executions>
                    <execution>
                        <id>unpack</id>
                        <phase>package</phase>
                        <goals>
                            <goal>unpack</goal>
                        </goals>
                        <configuration>
                            <artifactItems>
                                <artifactItem>
                                    <groupId>com.alibaba</groupId>
                                    <artifactId>dubbo</artifactId>
                                    <version>2.5.3</version>
                                    <outputDirectory>${project.build.directory}/dubbo</outputDirectory>
                                    <includes>META-INF/assembly/**</includes>
                                </artifactItem>
                            </artifactItems>
                        </configuration>
                    </execution>
                </executions>
            </plugin>

            <plugin>
                <artifactId>maven-assembly-plugin</artifactId>
                <configuration>
                    <archive>
                        <manifest>
                            <mainClass>com.lenxeon.apps.uc.user.init.Main</mainClass>
                        </manifest>
                    </archive>
                    <descriptor>src/main/assembly/assembly.xml</descriptor>
                </configuration>
                <executions>
                    <execution>
                        <id>make-assembly</id>
                        <phase>package</phase>
                        <goals>
                            <goal>single</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>

            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <configuration>
                    <source>1.7</source>
                    <target>1.7</target>
                    <encoding>utf-8</encoding>
                </configuration>
            </plugin>
        </plugins>

        <resources>
            <resource>
                <directory>src/main/java</directory>
                <includes>
                    <include>**/*.properties</include>
                    <include>**/*.xml</include>
                </includes>
                <filtering>false</filtering>
            </resource>
            <resource>
                <directory>src/main/resources</directory>
                <includes>
                    <include>**/*</include>
                </includes>
                <filtering>false</filtering>
            </resource>
        </resources>
    </build>

</project>
```

assembly.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<assembly>
	<id>assembly</id>
	<formats>
		<format>tar.gz</format>
	</formats>
	<includeBaseDirectory>true</includeBaseDirectory>
	<fileSets>
		<fileSet>
			<directory>${project.build.directory}/dubbo/META-INF/assembly/bin</directory>
			<outputDirectory>bin</outputDirectory>
			<fileMode>0755</fileMode>
		</fileSet>
		<fileSet>
			<directory>src/main/assembly/conf</directory>
			<outputDirectory>conf</outputDirectory>
			<fileMode>0644</fileMode>
		</fileSet>
	</fileSets>
	<dependencySets>
		<dependencySet>
			<outputDirectory>lib</outputDirectory>
		</dependencySet>
	</dependencySets>
</assembly>
```

dubbo.properties
```properties
dubbo.container=log4j,spring
dubbo.application.name=my-apps-all
dubbo.application.owner=
dubbo.registry.address=zookeeper://127.0.0.1:2181
#dubbo.registry.address=redis://127.0.0.1:6379
#dubbo.registry.address=dubbo://127.0.0.1:9090
#dubbo.registry.address=multicast://224.5.6.7:1234
dubbo.monitor.protocol=registry
dubbo.log4j.file=logs/commons-provider.log
dubbo.log4j.level=WARN
```
以上这些都可以在dubbo官网的demo中找到

执行打包命令后可以在target下得到一个*-assembly.tar.gz的包(我的叫app-uc-user-provider-assembly.tar.gz)

>mvn clean package install -e -U -Dmaven.test.skip=true

>cd target && tar -zxvf app-uc-user-provider-assembly.tar.gz

>cd bin && ./start.sh

打包后的文件结构
![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/dubbo学习总结/dubbo-gz.png)

启动，关闭服务
![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/dubbo学习总结/dubbo-gz.png)

##集中部署服务：在我们的场景中，我们并不想完全独立的部署服务

首先需要建一个web模块,添加需要启动的provider依懒
![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/dubbo学习总结/dubbo-jersey-pom.png)

添加spring的加载扫描规则
![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/dubbo学习总结/dubbo-jersey-provider.png)

多个服务集中部署时，可能有多个服务都需要依赖同一个服务的情况，所以消费者统一采用了注解的方式，避免bean id冲突
![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/dubbo学习总结/dubbo-customer.png)

 spring-dubbo.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>

<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:p="http://www.springframework.org/schema/p"
       xmlns:aop="http://www.springframework.org/schema/aop"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:mvc="http://www.springframework.org/schema/mvc"
       xmlns:dubbo="http://code.alibabatech.com/schema/dubbo"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
    http://www.springframework.org/schema/beans/spring-beans.xsd
    http://www.springframework.org/schema/mvc
    http://www.springframework.org/schema/mvc/spring-mvc.xsd
    http://www.springframework.org/schema/aop
    http://www.springframework.org/schema/aop/spring-aop-3.0.xsd
    http://www.springframework.org/schema/context
    http://www.springframework.org/schema/context/spring-context.xsd
    http://code.alibabatech.com/schema/dubbo
    http://code.alibabatech.com/schema/dubbo/dubbo.xsd">

    <!--服务提供都名称-->
    <dubbo:application name="my-apps-all"/>
    <!-- zookeeper注册 -->
    <!--<dubbo:registry protocol="zookeeper" address="192.168.1.11:2181,192.168.1.12:2181,192.168.1.13:2181"/>-->
    <dubbo:registry protocol="zookeeper" address="127.0.0.1:2181"/>
    <!-- dubbo提供服务的端口 -->
    <dubbo:protocol name="dubbo" port="20890"/>
    <dubbo:provider threads="200" delay="-1" timeout="6000" retries="0" connections="200" accepts="2000"/>
    <dubbo:consumer check="false" lazy="true"/>
    <!--annotion扫描目录-->
    <dubbo:annotation package="com.lenxeon.apps"/>

    <!--spring加载目录-->
    <context:component-scan base-package="com.lenxeon"/>
    <!--Resource Autowired-->
    <context:annotation-config />
    <!--HandlerMapping-->
    <mvc:annotation-driven/>


    <import resource="spring-datasource.xml"/>
    <!--<import resource="classpath*:spring-vailidator.xml"/>-->


    <!--<import resource="classpath*:beans-*.xml"/>-->
    <import resource="classpath*:META-INF/spring/dubbo-service.xml"/>

    <import resource="spring-aop.xml"/>
    <import resource="spring-i18.xml"/>
    <import resource="spring-quartz.xml"/>
    <import resource="spring-shiro.xml"/>
</beans>
```
