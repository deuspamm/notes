#优化-使用logback来管理日志

## 场景及预期
1. 日志的输出分三种：控制台，info文件，error文件
1. 控制台的级别设置在info级别，同时要饱含对warn,erro级别的日志
1. info文件中只输出info级别的日志
1. error文件中输出warn和error级别的日志

## 以前我们是使用slf4j+properties配置文件的方式来管理的，主要是问题是感觉不直观，而且有一些问题也没有弄明白

``` properties
#设置日志的根级别。
#log4j中有五级logger FATAL = 0, ERROR = 3, WARN = 4, INFO = 6, DEBUG = 7
#OFF、FATAL、ERROR、WARN、INFO、DEBUG、ALL
log4j.rootLogger = DEBUG,INFO,infoTXT,errorTXT

log4j.logger.org.apache=ERROR
log4j.logger.org.springframework=ERROR
log4j.logger.org.securityfilter=ERROR
log4j.logger.org.displaytag=ERROR
log4j.logger.com.danga.MemCached.MemCachedClient=ERROR
log4j.logger.com.danga.MemCached=ERROR

log4j.appender.Console=org.apache.log4j.ConsoleAppender
log4j.appender.Console.layout=org.apache.log4j.PatternLayout
log4j.appender.Console.layout.ConversionPattern=%d [%t] %-5p [%c] - %m%n

log4j.appender.INFO =  org.apache.log4j.ConsoleAppender
log4j.appender.INFO.layout = org.apache.log4j.PatternLayout
log4j.appender.INFO.layout.ConversionPattern=%d{yyyy-MM-dd HH:mm:ss} - %m%n

log4j.appender.DEBUG =  org.apache.log4j.ConsoleAppender
log4j.appender.DEBUG.layout = org.apache.log4j.PatternLayout
log4j.appender.DEBUG.layout.ConversionPattern=%d{yyyy-MM-dd HH:mm:ss} - %m%n

log4j.logger.java.sql = ERROR
log4j.logger.java.sql.Connection = ERROR
log4j.logger.java.sql.Statement = ERROR
log4j.logger.java.sql.PreparedStatement = ERROR
log4j.logger.java.sql.ResultSet = ERROR
log4j.logger.com.ibatis = ERROR
log4j.logger.com.ibatis.common.jdbc.SimpleDataSource = ERROR
log4j.logger.com.ibatis.common.jdbc.ScriptRunner = ERROR
log4j.logger.com.ibatis.sqlmap.engine.impl.SqlMapClientDelegate = ERROR

# All hibernate log output of "info" level or higher goes to stdout.
# For more verbose logging, change the "info" to "debug" on the last line.
log4j.logger.org.hibernate.ps.PreparedStatementCache=WARN
log4j.logger.org.hibernate=WARN

# Changing the log level to DEBUG will result in Hibernate generated
# SQL to be logged.
log4j.logger.org.hibernate.SQL=ERROR

# Changing the log level to DEBUG will result in the PreparedStatement
# bound variable values to be logged.
log4j.logger.org.hibernate.type=ERROR


#5 定义 TXT 输出到文件
log4j.logger.infoTXT=warn
log4j.appender.infoTXT = org.apache.log4j.DailyRollingFileAppender
log4j.appender.infoTXT.Threshold = WARN
log4j.appender.infoTXT.append=true
#6 定义 TXT 要输出到哪一个文件
log4j.appender.infoTXT.File = ./logs/apps/appsInfo.log
log4j.appender.infoTXT.DatePattern='.'yyyy-MM-dd'.log'
#9 定义 TXT 的布局模式为PatternLayout
log4j.appender.infoTXT.layout = org.apache.log4j.PatternLayout
#10 定义 TXT 的输出格式
log4j.appender.infoTXT.layout.ConversionPattern = %d{yyyy-MM-dd HH:mm:ss}:%p %t %c - %m%n

#5 定义 TXT 输出到文件
log4j.logger.errorTXT=error
log4j.appender.errorTXT = org.apache.log4j.DailyRollingFileAppender
log4j.appender.errorTXT.Threshold = ERROR
log4j.appender.errorTXT.append=true
#6 定义 TXT 要输出到哪一个文件
log4j.appender.errorTXT.File = ./logs/apps/appsErro.log
log4j.appender.errorTXT.DatePattern='.'yyyy-MM-dd'.log'
#9 定义 TXT 的布局模式为PatternLayout
log4j.appender.errorTXT.layout = org.apache.log4j.PatternLayout
#10 定义 TXT 的输出格式
log4j.appender.errorTXT.layout.ConversionPattern = %d{yyyy-MM-dd HH:mm:ss}:%p %t %c - %m%n
```

## 在了解了logback后，感觉比较满足我们的要求，所以做了一次尝试,注释比较全面了，完全实现了我们的预期

pom.xml
```xml

    <properties>
        <httpclient.version>4.5.1</httpclient.version>
        <!-- Log libs -->
        <slf4j_version>1.7.2</slf4j_version>
        <jcl_version>1.1</jcl_version>
        <log4j_version>1.2.16</log4j_version>
        <logback_version>1.0.6</logback_version>
        <jcl_over_slf4j_version>1.7.7</jcl_over_slf4j_version>
    </properties>

    <dependency>
        <groupId>org.slf4j</groupId>
        <artifactId>slf4j-api</artifactId>
        <version>${slf4j_version}</version>
    </dependency>
    <dependency>
        <groupId>ch.qos.logback</groupId>
        <artifactId>logback-classic</artifactId>
        <version>${logback_version}</version>
    </dependency>
```

``` xml
<?xml version="1.0" encoding="UTF-8"?>

<configuration>

    <!--属性区-->
	<property name="logBase" value="../logs/" />


    <!--console输出-->
	<appender name="stdout" class="ch.qos.logback.core.ConsoleAppender">
		<encoder>
			<pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{26}[%L] - %msg%n
			</pattern>
		</encoder>
	</appender>

    <!--info 文件输出-->
	<appender name="info" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- 按日期区分的滚动日志 -->
		<rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
			<fileNamePattern>${logBase}/info.%d{yyyy-MM-dd}.gz</fileNamePattern>
			<maxHistory>3</maxHistory>
		</rollingPolicy>
		<encoder>
			<pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36}[%L] - %msg%n
			</pattern>
		</encoder>
	</appender>

    <!--error 文件输出-->
    <appender name="error" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- 按日期区分的滚动日志 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${logBase}/error.%d{yyyy-MM-dd}.gz</fileNamePattern>
            <maxHistory>3</maxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36}[%L] - %msg%n
            </pattern>
        </encoder>
    </appender>


    <!--针对 INFO 级别的日志进行过滤,并输出到 info 文件中-->
    <appender name="async-info" class="ch.qos.logback.classic.AsyncAppender">
        <appender-ref ref="info" />
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>INFO</level>
            <onMatch>ACCEPT</onMatch>
            <onMismatch>DENY</onMismatch>
        </filter>
    </appender>

    <!--针对 ERROR 级别的日志进行过滤,并输出到 error 文件中-->
    <appender name="async-error" class="ch.qos.logback.classic.AsyncAppender">
        <appender-ref ref="error"/>
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>ERROR</level>
            <onMatch>ACCEPT</onMatch>
            <onMismatch>DENY</onMismatch>
        </filter>
    </appender>

    <!--针对 WARN 级别的日志进行过滤,并输出到 error 文件中-->
    <appender name="async-warn" class="ch.qos.logback.classic.AsyncAppender">
        <appender-ref ref="error"/>
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>WARN</level>
            <onMatch>ACCEPT</onMatch>
            <onMismatch>DENY</onMismatch>
        </filter>
    </appender>


    <!--针对不同的包设置不同的级别-->
    <logger name="org.apache" level="INFO" />
    <logger name="org.springframework" level="INFO" />


    <!--&lt;!&ndash;下面这三段的意思是将error,warn级别输出到error文件中,info级别输出到info文件中,同时所有的日志都从控制台上输出&ndash;&gt;-->
    <!--<logger name="com.lenxeon" level="ERROR" additivity="false">-->
        <!--<appender-ref ref="stdout"/>-->
        <!--<appender-ref ref="async-error"/>-->
    <!--</logger>-->

    <!--<logger name="com.lenxeon" level="WARN" additivity="false">-->
        <!--<appender-ref ref="stdout"/>-->
        <!--<appender-ref ref="async-warn"/>-->
    <!--</logger>-->

    <!--<logger name="com.lenxeon" level="INFO" additivity="false">-->
        <!--<appender-ref ref="stdout"/>-->
        <!--<appender-ref ref="async-info"/>-->
    <!--</logger>-->


	<!--总的配置,默认将级别设定在info-->
	<root level="WARN">
		<appender-ref ref="stdout" />
        <appender-ref ref="async-info"/>
        <appender-ref ref="async-warn"/>
        <appender-ref ref="async-error"/>
	</root>
</configuration>
```
单元测试
``` java
package com.lenxeon;

import org.junit.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

//@RunWith(SpringJUnit4ClassRunner.class)  //使用junit4进行测试
//@ContextConfiguration(locations = "classpath:beans.xml")
public class LogTest {

    private static Logger logger = LoggerFactory.getLogger(LogTest.class);

    @Test
    public void test(){
        logger.debug("debug java");
        logger.info("info java");
        logger.warn("warn java");
        Exception ex = new IllegalArgumentException("can not be null");
        logger.error(ex.getMessage(), ex);
        System.out.println("end");
    }

}
```


* 测试效果控制台
![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/优化-使用logback来管理日志/console.png)

* 测试效果info文件
![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/优化-使用logback来管理日志/info.png)

* 测试效果error文件
![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/优化-使用logback来管理日志/error.png)
