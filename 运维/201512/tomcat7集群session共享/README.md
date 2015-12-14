#tomcat7集群session共享


## 场景、起因
  由于使用了nginx+多tomcat7作为后端集群，因此就会面临session共享的问题，假如后端上有三台服务器：A,B,C
如果用户登陆这次请求是由A完成，在没有session共享的情况下，当用户请求被分配到B，C服务器上后将面临
被要求重新登陆的情况

## 部署session共享
  这里我已经整理好了所需要的所有的jar文件，大家只需要下载![jar](https://github.com/lenxeon/notes/blob/master/运维/201512/tomcat7集群session共享/jar.zip)解压到tomcat7下的lib目录即可
  修改配置文件conf/context.xml中增加（注意修改配置中的ip）

```
<Manager className="de.javakaffee.web.msm.MemcachedBackupSessionManager"
  memcachedNodes="n1:ip1:11211,n2:ip2:11211"
  lockingMode="auto"
  sticky="false"
  requestUriIgnorePattern= ".*\.(png|gif|jpg|css|js)$"
  sessionBackupAsync= "false"
  sessionBackupTimeout= "100"
  copyCollectionsForSerialization="true"
  transcoderFactoryClass="de.javakaffee.web.msm.serializer.kryo.KryoTranscoderFactory"
/>
```


![ls 查看监控状态](https://github.com/lenxeon/notes/blob/master/运维/201512/tomcat7集群session共享/Session共享.png)
