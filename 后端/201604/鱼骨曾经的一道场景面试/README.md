#鱼骨曾经的一道场景面试（待完成）

## 场景及问题
1. 频繁的产品需求变更，由于在不同时期对任务分类不同的看法，导致了有对原有分类的调整需求
1. 根据用户的反馈意见和产品功能的进一步深耕优化，新的查询功能的开发需求不可避免
1. 任务数据增长速度较快，mysql性能面临考验（事实上凡事基于硬盘的读都可以认为是性能提升的障碍）
1. 代码维护成本较高，因为sql部分有复用，case较多，可读性较差，对程序员的要求较高

> 任务模块是系统的核心功能之一，功能也相对复杂，为了解决以上问题，我们至少需要配置一位高级工程师，
长期熟悉该部分的业务逻辑，即便如此在面对产品日益繁多的需求和变动时也会显得力不从心，SQL越写越多，
长度越来越长，关联也越来越多，而性能和维护的难度也越来越大

## 我们的理想中一个系统方案应该具备的特点
1. 希望每一个新人理解好这个接口的定义后能在5分钟读懂这个接口的实现方式
1. 希望每一次需要修改接口的定义时，能够很容易的去完成修改，最重要的是绝对不影响其它的功能
1. 希望每一个新功能需要开发时，能够在最短的时间内完成开发，并且功能逻辑代码最好不要超过50行
1. 希望一个初级工程师就能胜任今后的需求变动和维护
1. 希望不管有多少个查询api，多少种观察难度，系统的复杂度始终不变，一切尽在掌握

## 先找个场景看看当前的实现

手机端我的未完列表，产品逻辑为提交人为我且未完成或者负责人为我且未完成的任务，
接下可能产品可能会改为提交人为我且状态为待审批或者负责人为我且未完成
业务逻辑使用到的java代码

```
@RequestMapping(value ="/task/un_finish_tasks", method = RequestMethod.GET)
    publicModelAndView unFinishTasks(HttpServletRequest request) {
        ModelAndView modelAndView =newModelAndView();
        RequestUtils req =newRequestUtils(request);
//        long client_version = req.getLong("client_version", 0l);
        User user = (User) request.getAttribute("user");
        String objUserId = user.getUuid();
        //完成的任务的统计
        Map hmap = req.getListParams();
        hmap.put("userId", user.getUuid());
        List users =newArrayList();
        //我是负责人 已完成的
        Map mgr =newHashMap();
        mgr.put("group_type",newint[]{
                GroupType.NORMAL.ordinal(),
                GroupType.CYCLE.ordinal(),
//                GroupType.CYCLE_CHILD.ordinal(),
                GroupType.MULTI_MGR.ordinal(),
                GroupType.MULTI_MGR_CHILD.ordinal(),
                GroupType.MULTI_MGR_CYCLE.ordinal(),
                GroupType.MULTI_MGR_CHILD_CYCLE.ordinal(),
//                GroupType.MULTI_MGR_CHILD_CYCLE_CHILD.ordinal()
        });
        mgr.put("id", objUserId);
        mgr.put("status", unFinish);
        mgr.put("user_type",1);
        users.add(mgr);

        //我是提交人 已完成的
        Map ctor =newHashMap();
        ctor.put("group_type",newint[]{
                GroupType.NORMAL.ordinal(),
                GroupType.CYCLE.ordinal(),
//                GroupType.CYCLE_CHILD.ordinal(),
                GroupType.MULTI_MGR.ordinal(),
//                GroupType.MULTI_MGR_CHILD.ordinal(),
                GroupType.MULTI_MGR_CYCLE.ordinal(),
//                GroupType.MULTI_MGR_CHILD_CYCLE.ordinal(),
//                GroupType.MULTI_MGR_CHILD_CYCLE_CHILD.ordinal()
        });
        ctor.put("id", objUserId);
        ctor.put("status", unFinish);
        ctor.put("user_type",0);
        users.add(ctor);

        hmap.put("users", users);
        //已完成任务 在该季度内的
        List sorters =newArrayList();
        Map sort1 = Maps.newHashMap();
        sort1.put("column","last_opt_date");
        sort1.put("direction","desc");
        Map sort2 = Maps.newHashMap();
        sort2.put("column","create_date");
        sort2.put("direction","desc");
        sorters.add(sort1);
        sorters.add(sort2);
        hmap.put("sorters", sorters);
        inttotal = taskService.count(hmap);
        List<Task> list = taskService.list(hmap);
        taskService.loadRelRes(list);
        modelAndView.addObject("result", ResultScheme.ACT_RESULT_SUCCESS);
        modelAndView.addObject("msg", LocaleUtils.getMessage("ftask.common_success"));
        modelAndView.addObject("total", total);
        TaskUnReadService taskUnReadService =newTaskUnReadServiceImpl();
        Map<String, Integer> statistics = taskUnReadService.unreadCount(user.getUuid());
        modelAndView.addObject("statistics", statistics);
        modelAndView.addObject(model, taskService.reduced(list));
        returnmodelAndView;
```

核心的统计SQL

```SQL
<selectid="count"parameterType="map"resultType="int">
        select count(1) from view_res_task t where t.is_delete = 0
        <iftest="users!=null">
            and exists(
            select * from view_res_user_rel vu where vu.res_id = t.uuid and
            <foreachitem="u"collection="users"open="("separator=" or "close=")">
                vu.user_id = #{u.id} and vu.rel_type = #{u.user_type}
                <iftest="u.user_type==2 or u.user_type == 3">
                    and not exists(
                    select vu2.user_id, vu2.res_id, vu2.rel_type from view_res_user_rel vu2
                    where vu2.user_id = #{u.id} and vu2.rel_type in (0, 1)
                    and vu2.res_id = vu.res_id and vu2.user_id = vu2.user_id
                    )
                </if>
                <iftest="u.status != null">
                    and status in
                    <foreachitem="i"collection="u.status"open="("separator=","close=")">#{i}</foreach>
                </if>
                <iftest="u.group_type != null">
                    and group_type in
                    <foreachitem="i"collection="u.group_type"open="("separator=","close=")">#{i}</foreach>
                </if>
            </foreach>
            <iftest="id != null">
                and t.id in
                <foreachcollection="id"item="i"open="("close=")"separator=",">
                    #{i}
                </foreach>
            </if>
            )
        </if>
        <iftest="uuid != null">
            and t.uuid in
            <foreachcollection="uuid"item="i"open="("close=")"separator=",">#{i}</foreach>
        </if>
        <iftest="parent_uuid != null and parent_uuid != ''">
            and t.parent_uuid = #{parent_uuid}
        </if>
        <iftest="plan_end_date!=null ">
            and t.plan_end_date between long_to_date(#{plan_end_date[0]}) and long_to_date(#{plan_end_date[1]})
        </if>
        <iftest="real_end_date!=null">
            and t.plan_end_date between long_to_date(#{real_end_date[0]}) and long_to_date(#{real_end_date[1]})
        </if>
        <iftest="last_sub_date!=null">
            and t.last_sub_date between long_to_date(#{last_sub_date[0]}) and long_to_date(#{last_sub_date[1]})
        </if>
        and (is_private = 0 or (is_private = 1 and creator_id = #{userId}))
    </select>
```
核心的查询SQL

``` SQL
<selectid="list"parameterType="map"resultMap="mapper">
        select * from view_res_task t where t.is_delete = 0
        <iftest="compId != null">
            and comp_id = #{compId}
        </if>
        <iftest="users!=null">
            and exists(
            select * from view_res_user_rel vu where vu.res_id = t.uuid and
            <foreachitem="u"collection="users"open="("separator=" or "close=")">
                vu.user_id = #{u.id} and vu.rel_type = #{u.user_type}
                <iftest="u.user_type==2">
                    and not exists(
                    select vu2.user_id, vu2.res_id, vu2.rel_type from view_res_user_rel vu2
                    where vu2.user_id = #{u.id} and vu2.rel_type in (0, 1)
                    and vu2.res_id = vu.res_id and vu2.user_id = vu2.user_id
                    )
                </if>
                <iftest="u.status != null">
                    and status in
                    <foreachitem="i"collection="u.status"open="("separator=","close=")">#{i}</foreach>
                </if>
                <iftest="u.group_type != null">
                    and group_type in
                    <foreachitem="i"collection="u.group_type"open="("separator=","close=")">#{i}</foreach>
                </if>
            </foreach>
            <iftest="id != null">
                and t.id in
                <foreachcollection="id"item="i"open="("close=")"separator=",">
                    #{i}
                </foreach>
            </if>
            )
        </if>
        <iftest="uuid != null">
            and t.uuid in
            <foreachcollection="uuid"item="i"open="("close=")"separator=",">#{i}</foreach>
        </if>
        <iftest="parent_uuid != null and parent_uuid != ''">
            and t.parent_uuid = #{parent_uuid}
        </if>
        <iftest="plan_end_date!=null ">
            and t.plan_end_date between long_to_date(#{plan_end_date[0]}) and long_to_date(#{plan_end_date[1]})
        </if>
        <iftest="real_end_date!=null">
            and t.real_end_date between long_to_date(#{real_end_date[0]}) and long_to_date(#{real_end_date[1]})
        </if>
        <iftest="last_sub_date!=null">
            and t.last_sub_date between long_to_date(#{last_sub_date[0]}) and long_to_date(#{last_sub_date[1]})
        </if>
        and (is_private = 0 or (is_private = 1 and creator_id = #{userId}))
        <iftest="sorters != null">
            order by
            <foreachcollection="sorters"index="index"item="it"open=""separator=","close="">
                <choose>
                    <whentest="it.column == 'creator_name' or it.column == 'manager_name'">
                        convert(${it.column} using gbk) ${it.direction}
                    </when>
                    <otherwise>
                        ${it.column} ${it.direction}
                    </otherwise>
                </choose>
            </foreach>
            ,create_date desc, uuid desc
        </if>
        <iftest="sorters == null">
            order by t.plan_end_date asc, t.priority desc, create_date desc, uuid desc
        </if>
        <iftest="limit > 0">
            LIMIT #{start}, #{limit}
        </if>
    </select>
```
这里面存在的问题

1. 可以看到SQL中为了实现各种不同逻辑的查询有很多的判断逻辑，但有时2个不同的查询逻辑需要的SQL从结构
上就会完全不同，这个时候只能重新写一个新的SQL没办法用动态SQL的方式来实现
1. 仅这一条SQL就如此复杂，如何保持性能，开发和维护的成本一个初级工程师或者是中级工程师能有自信保证业务的正确性么
1. 当有无数个这样的需求以后，代码的维护难度将成倍的增加，最好的可能就是分拆为每一个不同的业务写
一个service对应自己独立的SQL语句，即便是这样估计维护这些API的这个程序员估计不会有好的心情了

## mongo下的新选择

```java
//我提交未完成的或者是我负责未完成的
publicstaticvoidmain(String[] args) {
    MongoClient mongo = MongoDB.getDb();
    //定义查询的条件[我是创建人，并且状态为WAITING_AGREE，或者我是负责人并且状态为RUNNING]
    Bson query = or(
            and(
                    eq("rel.creator.uuid","3VnEQorNz1L5tqUJivaZa8")
                    , in("status","WAITING_AGREE")
            ),
            and(
                    eq("rel.manager.uuid","3VnEQorNz1L5tqUJivaZa8")
                    , in("status","WAITING","RUNNING")
            )
    );
    FindIterable<Document> result = mongo.getDatabase("ftask").getCollection("tasks")
            .find(query);
    for(Document doc : result) {
        //这里封装对象
        System.out.println(doc.get("show_id") +"\t"+ doc.get("name"));
    }
}
```

虽然上面的不是完全实现，但核心的代码已经体现了

1. 程序员每次只需要翻译产品的查询逻辑即可，不存在理解难度，可读性100%
1. 跟别的接口没有任何关系，修改调整安全性100%
1. 写这段代码只需要一个初级工程师简单培训下即可，不存在技术难度，复杂度几乎为零，易用性100%
1. 而且一百个一千个这样的接口，复杂度几乎没有变化，工程师也可以很优闲的应对，一切尽在掌握
1. 重新来定义这个开发场景,关注点的转变
1. 以前我们关注的重点是如何去写这些列表的SQL语句，有没有可能尽可能的重用

## 要实现上面这样的工作，还需要一个条件：我们需要保障所有的任务实时更新到mongodb中去
