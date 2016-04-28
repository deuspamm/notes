#简述鱼骨是如何把quartz做成一个通用服务的

## 场景及问题
1. 鱼骨是做企业任务管理的，这里面会涉及到不少的业务都需要通过定时任务来完成，比如：周期任务的生成，任务到期定时提醒，这篇文章中不会涉及到具体的实现，主要是讲一下思路。

## 分析
> 需求假设
* 鱼骨有一个通用的定时作业系统，和业务无耦合，可以被各个业务场景调用，实现各个业务场景中的定时需求（基础要求）。
* 这套作业系统中，需要有一些管理功能，比如查询当前有哪些任务，这些任务的状态，上次触发时间等信息。基本都是qtz_triggers，qtz_job_details表中的信息管理员能简单的暂时，恢复调度器(基础要求）。
* 需要查询历史的触发器，及所有触发器每次的执行情况，主要是是否成功（这部分quartz没有，需要自已开发）

> 根据需求1，需要划分在各种场景中，哪些是通用的，哪些不是差异化的？
* 触发器，job 的管理接口应该是通用的，可以管理后台查看触发器的相关信息（包括分组，名称，上次执行时间），差异化的应该是当任务被触发后需要具体做的事情，比如：周期任务生成触发器被触发后应该要生成相应的任务，而到期提醒的触发器触发后应该下发push消息通知。
* 解决办法可以这样：
  各个系统实现当任务被触发后要做的具体事情，而把参数留给jobdetail,同把通过callback参数把处理这个业务的url地址给jobdetail。这样就可以所有的定时任务封装成一个统一的http任务。每当触发的时候，任务只需要往jobdetail中指定的callback地址上传生成jobdetail的时候设置参数。具体要做什么就由业务平台自己决定，而作业服务只专注自己的调度业务。

> 需求2是一个比较基础的需求，通过实现一个列表过滤查询的接口和调用quartz自己的管理接口就可以实现

> 需求3这部分需要定制，quartz默认是会删除执行完成的trigger的，而且也不会有执行结果的记录。这两个功能都需要定制。
* 具体的做法是实现自己的StdJDBCDelegate继承org.quartz.impl.jdbcjobstore.StdJDBCDelegate，并重写其中删除trigger的方法。在删除之前先备份。
``` java
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
```
qtz_triggers_back 备份表的sql
```sql
CREATE TABLE `qtz_triggers_back` (
	`SCHED_NAME` varchar(120) CHARACTER SET utf8 NOT NULL,
	`TRIGGER_NAME` varchar(200) CHARACTER SET utf8 NOT NULL,
	`TRIGGER_GROUP` varchar(200) CHARACTER SET utf8 NOT NULL,
	`JOB_NAME` varchar(200) CHARACTER SET utf8 NOT NULL,
	`JOB_GROUP` varchar(200) CHARACTER SET utf8 NOT NULL,
	`DESCRIPTION` varchar(250) CHARACTER SET utf8 DEFAULT NULL,
	`NEXT_FIRE_TIME` bigint(13) DEFAULT NULL,
	`PREV_FIRE_TIME` bigint(13) DEFAULT NULL,
	`PRIORITY` int(11) DEFAULT NULL,
	`TRIGGER_STATE` varchar(16) CHARACTER SET utf8 NOT NULL,
	`TRIGGER_TYPE` varchar(8) CHARACTER SET utf8 NOT NULL,
	`START_TIME` bigint(13) NOT NULL,
	`END_TIME` bigint(13) DEFAULT NULL,
	`CALENDAR_NAME` varchar(200) CHARACTER SET utf8 DEFAULT NULL,
	`MISFIRE_INSTR` smallint(2) DEFAULT NULL,
	`JOB_DATA` blob DEFAULT NULL
) ENGINE=`InnoDB` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='' CHECKSUM=0 DELAY_KEY_WRITE=0;
```
至于记录job每次的执行结果就更简单了，在httpjob的调用结果中根据业务系统的回执记录就可以了
```java
package com.yugu.service.quartz.job;

import com.lenxeon.utils.httpclient.HttpClientUtils;
import com.lenxeon.utils.httpclient.HttpObject;
import com.lenxeon.utils.io.JsonUtils;
import com.lenxeon.utils.uuid.UUIDUtils;
import com.yugu.service.quartz.dao.SchedulerDao;
import com.yugu.service.quartz.dao.impl.SchedulerDaoImpl;
import org.apache.commons.collections.MapUtils;
import org.apache.commons.lang.StringUtils;
import org.quartz.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;


public class HttpCallbackServiceJob extends BasicJob {

    private static Logger logger = LoggerFactory.getLogger(HttpCallbackServiceJob.class);

    @Override
    public void execute(JobExecutionContext jobExecutionContext) throws JobExecutionException {
        boolean success = false;
        JobDetail jd = jobExecutionContext.getJobDetail();
        JobDataMap cfg = jd.getJobDataMap();
        SchedulerDao schedulerService = new SchedulerDaoImpl();
        int httpStatus = 0;
        String httpResp = "";
        try {
            String callback = MapUtils.getString(cfg, "callback");
            String method = MapUtils.getString(cfg, "method");
            String req_token = UUIDUtils.uuidHibernate();
            if (StringUtils.contains(callback, "?")) {
                callback = callback + "&req_token=" + req_token + "&unique=" + UUIDUtils.base58Uuid();
            } else {
                callback = callback + "?req_token=" + req_token + "&unique=" + UUIDUtils.base58Uuid();
            }

            int executeTimes = MapUtils.getIntValue(cfg, EXECUTE_TIMES, 0);
            executeTimes++;
            cfg.put(EXECUTE_TIMES, String.valueOf(executeTimes));
            if (StringUtils.isNotBlank(callback)) {
                HttpObject httpObject = new HttpObject();
                if ("post".equals(method)) {
                    httpObject = HttpClientUtils.postString(callback, cfg, new HashMap<String, String>());
                }
                if ("get".equals(method)) {
                    httpObject = HttpClientUtils.getObject(callback);
                }
                httpStatus = httpObject.getCode();
                httpResp = httpObject.getHtml();
                logger.info("HttpCallbackService.process:" + callback + "\t" + JsonUtils.toJson(cfg) + "\t" + httpResp);
                success = check(httpObject);
                if (success) {
                    int executeSuccessTimes = MapUtils.getIntValue(cfg, EXECUTE_SUCCESS_TIMES, 0);
                    executeSuccessTimes++;
                    cfg.put(EXECUTE_SUCCESS_TIMES, String.valueOf(executeSuccessTimes));
                }
            }
        } catch (Exception e) {

        } finally {
            TriggerKey triggerKey = jobExecutionContext.getTrigger().getKey();
            int status = success ? 0 : -1;
            int i = schedulerService.saveTriggerLog(triggerKey.getName(), triggerKey.getGroup(), jobExecutionContext.getFireTime(), httpStatus, httpResp, status);
            logger.info("HttpCallbackService:save_log\t result=" + i);
            if (!success) {
                logger.info("HttpCallbackService:error" + JsonUtils.toJson(cfg));
                throw new JobExecutionException("HttpCallbackService:error" + JsonUtils.toJson(cfg));
            }
        }
    }

    private boolean check(HttpObject object) {
        boolean result = false;
        if (object != null) {
            if (object.getCode() >= 200 && object.getCode() < 300) {
                Map res = (Map) JsonUtils.toBean(object.getHtml(), Map.class);
                if (StringUtils.equals(MapUtils.getString(res, "result"), "success") || MapUtils.getIntValue(res, "result", -1) == 0) {
                    result = true;
                }
            }
        }
        return result;
    }
}

```
