#鱼骨linx定时任务脚本规范


## 场景、起因
  由于业务越来越多，经常需要借助linux crontab服务来执行一些脚本，随着时间的增加，由于没有
固定的规范，时间长了会有不能快速找到想要的文件，也不知道哪个文件管理着哪个服务，每个服务当时
的解决需求是什么。如下图中

![ls 鱼骨linx定时任务脚本规范](https://github.com/lenxeon/notes/blob/master/运维/201512/鱼骨linx定时任务脚本规范/linux任务脚本.png)

## 固定模板
  下面是一个固定的模板,每次有需求时大家只需要复制一分，修改下面的自定义部分，主要包括摘要
描述这个脚本的用途，产品需求等，title用于在日志中显示以及需要请求的url地址。
  另外，我们所有的日志存放在/usr/local/tomcat/sh目录中

```shell
# 自定义部分
# 摘要:每晚全量同步任务到mongodb中
title='每晚全量同步mysql中的任务到mongodb数据库'
url=http://xxx.com/ftask/api/v1/xxx/xxx.json?version=0
#自定义部分结束

#通用逻辑
logpath=/usr/local/tomcat/sh/logs.log
echo -e '\r\n==============start task===============' >> ${logpath}
now=`date "+%Y-%m-%d %H:%M:%S"`--${title}
echo ${now} >> ${logpath}
curl -i ${url} >> ${logpath}
echo -e '\r\n==============end  task===============' >> ${logpath}
```

## 执行日志展示

  从下面的日志中可以很清楚的看到是哪个任务，执行时间，执行结果，可以很方便的查找问题

```logs
==============start task===============
2015-12-15 12:32:38--每晚全量同步mysql中的任务到mongodb数据库
HTTP/1.1 200 OK
Server: openresty/1.9.3.1
Date: Tue, 15 Dec 2015 04:32:38 GMT
Content-Type: application/json;charset=utf-8
Content-Length: 80
Connection: keep-alive
Keep-Alive: timeout=20
Access-Control-Allow-Origin: *

{"result":0,"msg":"已经有同步进程在执行中了，请30秒后再尝试"}
==============end  task===============

==============start task===============
2015-12-15 12:32:39--每晚全量同步mysql中的任务到mongodb数据库
HTTP/1.1 200 OK
Server: openresty/1.9.3.1
Date: Tue, 15 Dec 2015 04:32:39 GMT
Content-Type: application/json;charset=utf-8
Content-Length: 80
Connection: keep-alive
Keep-Alive: timeout=20
Access-Control-Allow-Origin: *

{"result":0,"msg":"已经有同步进程在执行中了，请30秒后再尝试"}
==============end  task===============
```
