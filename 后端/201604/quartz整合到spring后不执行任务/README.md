#quartz整合到spring后不执行任务

## 场景及问题
1. 近期把quartz整合到dubbo通用服务中去以后发现新建，停止任务没有问题，但任务并不执行，仔细观察日志后发现一个比较重要的信息：batch acquisition of 0 triggers

## 分析步骤

* 日志

![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/quartz整合到spring后不执行任务/img-01.png)

* 简单的用jd-gui查一下源码中的关键字，定位到
```java
triggers = this.qsRsrcs.getJobStore().acquireNextTriggers(now + this.idleWaitTime, Math.min(availThreadCount, this.qsRsrcs.getMaxBatchSize()), this.qsRsrcs.getBatchTimeWindow());
```

![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/quartz整合到spring后不执行任务/img-02.png)

* 为了搞懂上面这句代码究竟执行了什么，我们在idea中先进入org.quartz.spi.JobStore类，并找到acquireNextTriggers方法，鼠标右键跳转到实现方法，可以从下图中看到这个方法有多个实现。

![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/quartz整合到spring后不执行任务/img-03.png)

* 再结合我们的配置文件中知道trigger的信息是存在于数据库中的，所以应该是jdbc的,所以应该选择上图中的 JobStoreSupport

``` properties
#============================================================================
# Configure Main Scheduler Properties
#============================================================================

org.quartz.scheduler.instanceName = MyClusteredScheduler
org.quartz.scheduler.instanceId = AUTO
org.quartz.scheduler.skipUpdateCheck=true

#============================================================================
# Configure ThreadPool
#============================================================================

org.quartz.threadPool.class = org.quartz.simpl.SimpleThreadPool
org.quartz.threadPool.threadCount = 25
org.quartz.threadPool.threadPriority = 5

#============================================================================
# Configure JobStore
#============================================================================

org.quartz.jobStore.misfireThreshold = 60000

org.quartz.jobStore.class = org.quartz.impl.jdbcjobstore.JobStoreTX
org.quartz.jobStore.driverDelegateClass = com.yugu.service.quartz.dao.impl.StdJDBCDelegate
org.quartz.jobStore.useProperties = false
org.quartz.jobStore.dataSource = myDS
org.quartz.jobStore.tablePrefix = QTZ_

org.quartz.jobStore.isClustered = true
org.quartz.jobStore.maxMisfiresToHandleAtATime=1
org.quartz.jobStore.clusterCheckinInterval = 20000

#============================================================================
# Configure Datasources
#============================================================================
org.quartz.dataSource.myDS.connectionProvider.class = com.yugu.service.utils.DruidQuartzProvider
```

* 继续往下跟踪，如下面两图所示，找到具体的查询方法是：StdJDBCDelegate中的selectTriggerToAcquire


![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/quartz整合到spring后不执行任务/img-04.png)

![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/quartz整合到spring后不执行任务/img-05.png)

* 已经找到具体的位置了，但我不想把quartz的代码都下载下来，重新编译打包，所以可以自己把这个方法实现一遍，直接复制这段源码，并添加一些日志记录，

com.yugu.service.quartz.dao.impl.StdJDBCDelegate
``` java
package com.yugu.service.quartz.dao.impl;


import org.quartz.TriggerKey;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.LinkedList;
import java.util.List;

import static org.quartz.TriggerKey.triggerKey;

public class StdJDBCDelegate extends org.quartz.impl.jdbcjobstore.StdJDBCDelegate {
    Logger logger = LoggerFactory.getLogger(StdJDBCDelegate.class);

    @Override
    public List<TriggerKey> selectTriggerToAcquire(Connection conn, long noLaterThan, long noEarlierThan, int maxCount) throws SQLException {
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<TriggerKey> nextTriggers = new LinkedList<TriggerKey>();
        try {
            String sql = rtp(SELECT_NEXT_TRIGGER_TO_ACQUIRE);
            logger.info("sql:[{}]", sql);
            ps = conn.prepareStatement(sql);
            if (maxCount < 1)
                maxCount = 1;
            logger.info("maxCount:[{}] STATE_WAITING:[{}] STATE_WAITING:[{}] STATE_WAITING:[{}]"
                    , new Object[]{maxCount, STATE_WAITING, new BigDecimal(String.valueOf(noLaterThan)), new BigDecimal(String.valueOf(noEarlierThan))});
            ps.setMaxRows(maxCount);
            ps.setFetchSize(maxCount);
            ps.setString(1, STATE_WAITING);
            ps.setBigDecimal(2, new BigDecimal(String.valueOf(noLaterThan)));
            ps.setBigDecimal(3, new BigDecimal(String.valueOf(noEarlierThan)));
            rs = ps.executeQuery();

            while (rs.next() && nextTriggers.size() <= maxCount) {
                logger.info("trigger:[{}-{}]", new Object[]{COL_TRIGGER_GROUP, COL_TRIGGER_NAME});
                nextTriggers.add(triggerKey(
                        rs.getString(COL_TRIGGER_NAME),
                        rs.getString(COL_TRIGGER_GROUP)));
            }

            return nextTriggers;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    @Override
    public int deleteFiredTriggers(Connection conn, String theInstanceId) throws SQLException {

        PreparedStatement ps = null;
        int var4;
        try {
            ps = conn.prepareStatement(this.rtp("DELETE FROM {0}FIRED_TRIGGERS WHERE SCHED_NAME = {1} AND INSTANCE_NAME = ? AND STATE <> ?"));
            ps.setString(1, theInstanceId);
            ps.setString(2, "EXECUTING");
            var4 = ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
        return var4;
    }

    @Override
    public int deleteFiredTriggers(Connection conn) throws SQLException {
        PreparedStatement ps = null;
        int var3;
        try {
            ps = conn.prepareStatement(this.rtp("DELETE FROM {0}FIRED_TRIGGERS WHERE SCHED_NAME = {1} AND AND STATE <> ?"));
            var3 = ps.executeUpdate();
            ps.setString(1, "EXECUTING");
        } finally {
            closeStatement(ps);
        }
        return var3;
    }

    @Override
    public int deleteFiredTrigger(Connection conn, String entryId) throws SQLException {
        PreparedStatement ps = null;
        int var4;
        try {
            ps = conn.prepareStatement(this.rtp("DELETE FROM {0}FIRED_TRIGGERS WHERE SCHED_NAME = {1} AND ENTRY_ID = ? AND STATE <> ?"));
            ps.setString(1, entryId);
            ps.setString(2, "EXECUTING");
            var4 = ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
        return var4;
    }

    @Override
    public int deleteTrigger(Connection conn, TriggerKey triggerKey) throws SQLException {
        backupTrigger(conn, triggerKey);
        return super.deleteTrigger(conn, triggerKey);
    }

    public int backupTrigger(Connection conn, TriggerKey triggerKey) throws SQLException {
        PreparedStatement ps = null;
        int var4;
        try {
            ps = conn.prepareStatement(this.rtp("DELETE FROM {0}TRIGGERS_BACK WHERE SCHED_NAME = {1} AND TRIGGER_NAME = ? AND TRIGGER_GROUP = ?"));
            ps.setString(1, triggerKey.getName());
            ps.setString(2, triggerKey.getGroup());
            var4 = ps.executeUpdate();

            ps = conn.prepareStatement(this.rtp("INSERT INTO {0}TRIGGERS_BACK SELECT * FROM {0}TRIGGERS WHERE SCHED_NAME = {1} AND TRIGGER_NAME = ? AND TRIGGER_GROUP = ?"));
            ps.setString(1, triggerKey.getName());
            ps.setString(2, triggerKey.getGroup());
            var4 = ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
        return var4;
    }
}

```

* 重启后得到相关日志，发现sql中有一个条件 WHERE SCHED_NAME = 'schedulerFactory'和数据库中的名字不一样，原来配置的叫：MyClusteredScheduler
```
2016-04-28 14:09:50:DEBUG MyClusteredScheduler_QuartzSchedulerThread org.springframework.jdbc.datasource.DataSourceUtils - Returning JDBC Connection to DataSource
2016-04-28 14:09:50:DEBUG MyClusteredScheduler_QuartzSchedulerThread org.quartz.core.QuartzSchedulerThread - batch acquisition of 1 triggers
2016-04-28 14:09:52:INFO MyClusteredScheduler_QuartzSchedulerThread com.yugu.service.quartz.dao.impl.StdJDBCDelegate - sql:[SELECT TRIGGER_NAME, TRIGGER_GROUP, NEXT_FIRE_TIME, PRIORITY FROM QTZ_TRIGGERS WHERE SCHED_NAME = 'schedulerFactory' AND TRIGGER_STATE = ? AND NEXT_FIRE_TIME <= ? AND (MISFIRE_INSTR = -1 OR (MISFIRE_INSTR != -1 AND NEXT_FIRE_TIME >= ?)) ORDER BY NEXT_FIRE_TIME ASC, PRIORITY DESC]
2016-04-28 14:09:52:INFO MyClusteredScheduler_QuartzSchedulerThread com.yugu.service.quartz.dao.impl.StdJDBCDelegate - maxCount:[1] STATE_WAITING:[WAITING] STATE_WAITING:[1461823822579] STATE_WAITING:[1461823732579]
```

* 再看看我们 spring里关于quartz的配置

``` xml
<bean id="schedulerFactory" class="org.springframework.scheduling.quartz.SchedulerFactoryBean">
    <property name="configLocation" value="/META-INF/spring/quartz.properties" />
    <property name="dataSource" ref="dataSource" />
    <property name="overwriteExistingJobs" value="true" />
    <property name="autoStartup" value="true" />
</bean>
```

* 根据配置，进入：org.springframework.scheduling.quartz.SchedulerFactoryBean这个类，找到instanceName关键字，可以知道下面两图中，本来先从配置文件中读到了instanceName然后又用beanid给覆盖了。
![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/quartz整合到spring后不执行任务/img-06.png)
![ls](https://github.com/lenxeon/notes/blob/master/后端/201604/quartz整合到spring后不执行任务/img-07.png)

* 找到了原因，最后我们再次修改一下配置文件，程序正常触发job了。

``` xml
<bean id="MyClusteredScheduler" class="org.springframework.scheduling.quartz.SchedulerFactoryBean">
    <property name="configLocation" value="/META-INF/spring/quartz.properties" />
    <property name="dataSource" ref="dataSource" />
    <property name="overwriteExistingJobs" value="true" />
    <property name="autoStartup" value="true" />
</bean>
```
