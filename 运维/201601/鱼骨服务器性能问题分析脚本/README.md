#鱼骨linx定时任务脚本规范


## 场景、起因
  由于业务接口越来越多，为了掌握系统性能情况，所以考虑对所有的controller和service进行日志监控，并结合shell进行分析

## 拦截器及配置

```java
package com.fishbone.aop;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.ProceedingJoinPoint;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ServiceAspect {

    private static Logger logger = LoggerFactory.getLogger(com.fishbone.aop.ServiceAspect.class);

    public void doAfter(JoinPoint jp) {
    }

    public Object doAround(ProceedingJoinPoint pjp) throws Throwable {
        long time = System.currentTimeMillis();
        Object retVal = pjp.proceed();
        time = System.currentTimeMillis() - time;
        String method = pjp.getTarget().getClass().getName() + "." + pjp.getSignature().getName();
        logger.info("ServiceAspect\ttask\t" + method + "\t" + time);
        return retVal;
    }

    public void doBefore(JoinPoint jp) {
    }

    public void doThrowing(JoinPoint jp, Throwable ex) {
        System.out.println(ex.getMessage());
    }
}
```
配置

```xml
<aop:config>
    <aop:aspect id="TestAspect" ref="TestAspect">
        <!--配置com.spring.service包下所有类或接口的所有方法-->
        <aop:pointcut id="businessService" expression="execution(* com.fishbone..*Impl.*(..))" />
        <aop:before pointcut-ref="businessService" method="doBefore"/>
        <aop:after pointcut-ref="businessService" method="doAfter"/>
        <aop:around pointcut-ref="businessService" method="doAround"/>
        <aop:after-throwing pointcut-ref="businessService" method="doThrowing" throwing="ex"/>
    </aop:aspect>
</aop:config>
```

## 执行日志展示

```shell
grep ServiceAspect catalina.out  | grep task
2016-01-14 06:09:05 - 	ServiceAspect	task	com.fishbone.res.dao.impl.TagServiceImpl.list	1
2016-01-14 06:09:05 - 	ServiceAspect	task	com.fishbone.res.dao.impl.ResServiceImpl.loadRelRes	70
2016-01-14 06:09:05 - 	ServiceAspect	task	com.fishbone.task.dao.impl.TaskServiceImpl.sync	85
2016-01-14 06:09:05 - 	ServiceAspect	task	com.fishbone.res.dao.impl.ResServiceImpl.loadRelRes	0
2016-01-14 06:09:05 - 	ServiceAspect	task	com.fishbone.task.dao.impl.TaskServiceImpl.loadRelRes	0
2016-01-14 06:09:05 - 	ServiceAspect	task	com.fishbone.uc.dao.impl.UserServiceImpl.getUser	1
2016-01-14 06:09:05 - 	ServiceAspect	task	com.fishbone.uc.dao.impl.UserServiceImpl.cache	0
2016-01-14 06:09:05 - 	ServiceAspect	task	com.fishbone.uc.dao.impl.UserServiceImpl.cache	0
2016-01-14 06:09:05 - 	ServiceAspect	task	com.fishbone.task.dao.impl.TaskServiceImpl.syncDeletedCount	4
2016-01-14 06:09:05 - 	ServiceAspect	task	com.fishbone.task.dao.impl.TaskServiceImpl.syncDeletedTask	5
2016-01-14 06:09:05 - 	ServiceAspect	task	com.fishbone.uc.dao.impl.UserServiceImpl.getUser	1
2016-01-14 06:09:05 - 	ServiceAspect	task	com.fishbone.uc.dao.impl.UserServiceImpl.cache	1
```

```shell
找出其中有问题的，比如先看最严重的，大于100ms的

==============end  task===============

==============start task===============
grep ServiceAspect catalina.out  | grep task | awk -F ' ' '$7>100 {print $1" "$6" " $7}' | grep ^2016 |sort | awk '{a[$2]+=$3;b[$2]++}END{for(n in a)print a[n]/b[n]"\t"n}'

436	com.fishbone.res.dao.impl.ResServiceImpl.getMeta
1971.62	com.fishbone.bbs.dao.impl.PostServiceImpl.countV2
149.938	com.fishbone.kpi.dao.impl.AimInsItemServiceImpl.listTask
108	com.fishbone.task.dao.impl.TaskServiceImpl.save
119	com.fishbone.report.dao.impl.ReportItemServiceImpl.save
243.708	com.fishbone.hr.dao.impl.SignStatServiceImpl.list
360.333	com.fishbone.task.dao.impl.TaskServiceImpl.getChild
255	com.fishbone.kpi.dao.impl.AimInsItemServiceImpl.save
167.076	com.fishbone.task.dao.impl.TaskServiceImpl.sync
204.857	com.fishbone.task.dao.impl.TaskServiceImpl.countTaskByMongo
==============end  task===============
```
