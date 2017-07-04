基于dobbo做服务开发后通常会遇上这样一些问题，举个例子：用户的笔记，涉及到CRUD 4个接口，是每一个接口中都要把用户传进去么?
比如：删除接口
定义为  noteService.deleteById(Long noteId)
还是     noteService.deleteById(Long userId, Long noteId)
如果是前者，这个时候如果不验证用户对资源是否有权限直接删除是否合理，尤其是这种可能被用户猜到的ID很容易被恶意调用。如果选第二种的话，那么有很多接口都要这样定义，感觉不够美观，而且也不够严谨。

先说说我的想法：假定所有的服务调用都要通过filter，这个filter能够将sessionId以隐性的方式传参，这样就不用每一个接口去增加userId这个参数，同时由于sessionID是由场门的服务生成的无意义的随机字符，一般类似UUID，当服务端收到这个sessionID后，通过调用session远程服务去获取当前用户的信息，这样服务端就可以知道当前用户是谁,这也避免了消费端的失误造成了用户数据的篡改的可能。

根据设想，将shiro设计成两个模块:ucenter-session-api和ucenter-session-provider，其它的服务端都需要对ucenter-session-api依赖，用于授权web服务对ucenter-session-provider依赖。

# ucenter-session-api 的结构和涉及的主要代码
![dubbo和shiro的整合，在服务端做权限验证]( https://img.pmowner.com/wp/2017-07-04/session-api.png)

RemoteSessionService
```
package com.lenxeon.ucenter.session.api;

import com.lenxeon.ucenter.session.pojo.PermissionContext;
import org.apache.shiro.session.Session;

import java.io.Serializable;


public interface RemoteSessionService {

    /**
     * 获取session
     * @param sessionId
     * @return
     */
    Session getSession(Serializable sessionId);

    /**
     * 创建session
     * @param session
     * @return
     */
    Serializable createSession(Session session);

    /**
     * 更新session
     * @param session
     */
    void updateSession(Session session);

    /**
     * 删除session
     * @param session
     */
    void deleteSession(Session session);

    /**
     * 查询用户的角色和权限信息
     * @param identify
     * @return
     */
    PermissionContext getPermissions(String identify);
}
```

ShiroCustomFilter，主要是追加x-session-id
```
package com.lenxeon.ucenter.session.dubbo;

import com.alibaba.dubbo.rpc.*;
import com.lenxeon.ucenter.session.api.RemoteSessionService;
import com.lenxeon.utils.io.JsonUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.shiro.SecurityUtils;
import org.apache.shiro.subject.Subject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class ShiroCustomFilter implements Filter {

    final static Logger logger = LoggerFactory.getLogger(ShiroCustomFilter.class);

    public Result invoke(Invoker<?> invoker, Invocation invocation) throws RpcException {
        if(invoker.getInterface().equals(RemoteSessionService.class)){
            //去获取信息
        }else{
            //追加补充信息
            String sessionId = "";
            Subject subject = SecurityUtils.getSubject();
            if (subject.isAuthenticated()) {
                //判断是否登陆过
            }
            sessionId = subject.getSession().getId().toString();
            invocation.getAttachments().put("x-session-id", StringUtils.defaultString(sessionId));
        }
        logger.info("CustomFilter.login[{}]", JsonUtils.toJson(invocation.getAttachments()));
        Result result = invoker.invoke(invocation);
        return result;
    }
}
```
MyResult
```
package com.lenxeon.ucenter.session.dubbo;

import com.alibaba.dubbo.rpc.Invocation;
import com.alibaba.dubbo.rpc.Invoker;
import com.alibaba.dubbo.rpc.Result;

import java.util.concurrent.Callable;

class MyResult implements Callable<Result> {

    private Invoker<?> invoker;

    private Invocation invocation;

    public MyResult(Invoker<?> invoker, Invocation invocation) {
        this.invocation = invocation;
        this.invoker = invoker;
    }

    @Override
    public Result call() throws Exception {
        Result result = invoker.invoke(invocation);
        return result;
    }
}
```

spring-client-shiro.xml
```
<?xml version="1.0" encoding="UTF-8"?>

<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:aop="http://www.springframework.org/schema/aop"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
    http://www.springframework.org/schema/beans/spring-beans.xsd
    http://www.springframework.org/schema/aop
    http://www.springframework.org/schema/aop/spring-aop-3.0.xsd">

    <aop:config proxy-target-class="true"/>


    <!-- 会话ID生成器 -->
    <bean id="sessionIdGenerator" class="org.apache.shiro.session.mgt.eis.JavaUuidSessionIdGenerator"/>

    <bean id="myRealm" class="com.lenxeon.ucenter.session.shiro.client.ClientRealm">
        <property name="cachingEnabled" value="false"/>
        <property name="remoteSessionService" ref="remoteSessionService"></property>
    </bean>

    <!-- 会话Cookie模板 -->
    <bean id="sessionIdCookie" class="org.apache.shiro.web.servlet.SimpleCookie">
        <constructor-arg value="${client.session.id}"/>
        <property name="httpOnly" value="true"/>
        <property name="maxAge" value="-1"/>
        <property name="domain" value="${client.cookie.domain}"/>
        <property name="path" value="${client.cookie.path}"/>
    </bean>

    <bean id="rememberMeCookie" class="org.apache.shiro.web.servlet.SimpleCookie">
        <constructor-arg value="${client.rememberMe.id}"/>
        <property name="httpOnly" value="true"/>
        <property name="maxAge" value="2592000"/><!-- 30天 -->
        <property name="domain" value="${client.cookie.domain}"/>
        <property name="path" value="${client.cookie.path}"/>
    </bean>

    <!-- 会话DAO -->
    <bean id="sessionDAO" class="com.lenxeon.ucenter.session.shiro.client.ClientSessionDAO">
        <property name="sessionIdGenerator" ref="sessionIdGenerator"/>
        <property name="remoteSessionService" ref="remoteSessionService"/>
    </bean>

    <!-- 会话管理器 -->
    <bean id="sessionManager" class="org.apache.shiro.web.session.mgt.DefaultWebSessionManager">
        <property name="deleteInvalidSessions" value="false"/>
        <property name="sessionValidationSchedulerEnabled" value="false"/>
        <property name="sessionDAO" ref="sessionDAO"/>
        <property name="sessionIdCookieEnabled" value="false"/>
        <!--<property name="sessionIdCookie" ref="sessionIdCookie"/>-->
    </bean>

    <bean id="securityManager" class="org.apache.shiro.web.mgt.DefaultWebSecurityManager">
    <!--<bean id="securityManager" class="org.apache.shiro.mgt.DefaultSecurityManager">-->
        <property name="realms" ref="myRealm"/>
        <property name="sessionManager" ref="sessionManager"/>
    </bean>

    <!-- Shiro生命周期处理器-->
    <bean id="lifecycleBeanPostProcessor" class="org.apache.shiro.spring.LifecycleBeanPostProcessor"/>


    <bean class="org.apache.shiro.spring.security.interceptor.AuthorizationAttributeSourceAdvisor">
        <property name="securityManager" ref="securityManager"/>
    </bean>

    <!-- 相当于调用SecurityUtils.setSecurityManager(securityManager) -->
    <bean class="org.springframework.beans.factory.config.MethodInvokingFactoryBean">
        <property name="staticMethod" value="org.apache.shiro.SecurityUtils.setSecurityManager"/>
        <property name="arguments" ref="securityManager"/>
    </bean>

</beans>
```
# ucenter-session-provider 的结构和涉及的主要代码

RemoteSessionServiceImpl
```
package com.lenxeon.ucenter.session.api.impl;


import com.alibaba.dubbo.config.annotation.Reference;
import com.google.common.collect.Sets;
import com.lenxeon.apps.commons.api.IdService;
import com.lenxeon.ucenter.session.api.RemoteSessionService;
import com.lenxeon.ucenter.session.pojo.PermissionContext;
import com.lenxeon.ucenter.user.api.SecurityService;
import org.apache.shiro.session.Session;
import org.apache.shiro.session.mgt.eis.SessionDAO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.Serializable;


@Service
public class RemoteSessionServiceImpl implements RemoteSessionService {

    @Autowired
    private SessionDAO sessionDAO;

    @Reference(version = "1.0.0")
    private IdService idService;

    @Reference(version = "1.0.0")
    private SecurityService securityService;

    private static final Logger logger = LoggerFactory.getLogger(RemoteSessionServiceImpl.class);


    @Override
    public Session getSession(Serializable sessionId) {
        return sessionDAO.readSession(sessionId);
    }

    @Override
    public Serializable createSession(Session session) {
        return sessionDAO.create(session);
    }

    @Override
    public void updateSession(Session session) {
        sessionDAO.update(session);
    }

    @Override
    public void deleteSession(Session session) {
        sessionDAO.delete(session);
    }

    @Override
    public PermissionContext getPermissions(String identify) {
        PermissionContext permissionContext = new PermissionContext();
        permissionContext.setRoles(Sets.newHashSet("po", "sm", "team"));
        permissionContext.setPermissions(Sets.newHashSet("system:delete_department", "system:user:create", "system:user:delete"));
        return permissionContext;
    }
}

```

spring-local-shiro.xml
```
<?xml version="1.0" encoding="UTF-8"?>

<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:aop="http://www.springframework.org/schema/aop"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:dubbo="http://code.alibabatech.com/schema/dubbo"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
    http://www.springframework.org/schema/beans/spring-beans.xsd
    http://www.springframework.org/schema/aop
    http://www.springframework.org/schema/aop/spring-aop-3.0.xsd
    http://code.alibabatech.com/schema/dubbo
    http://code.alibabatech.com/schema/dubbo/dubbo.xsd">

    <aop:config proxy-target-class="true"/>

    <!-- 会话ID生成器 -->
    <bean id="sessionIdGenerator" class="org.apache.shiro.session.mgt.eis.JavaUuidSessionIdGenerator"/>

    <bean id="limitRetryHashedMatcher" class="com.lenxeon.ucenter.session.shiro.local.LimitRetryHashedMatcher">
        <!--这个配置要和PassWordUtils里一致-->
        <property name="hashAlgorithmName" value="md5"></property>
        <property name="hashIterations" value="2"></property>
        <property name="storedCredentialsHexEncoded" value="true"></property>
    </bean>

    <!-- Shiro默认会使用Servlet容器的Session,可通过sessionMode属性来指定使用Shiro原生Session -->
    <!-- 即<property name="sessionMode" value="native"/>,详细说明见官方文档 -->
    <!-- 这里主要是设置自定义的单Realm应用,若有多个Realm,可使用'realms'属性代替 -->

    <!-- 会话DAO -->
    <bean id="sessionDAO" class="com.lenxeon.ucenter.session.shiro.local.RedisSessionDAO">
        <property name="sessionIdGenerator" ref="sessionIdGenerator"/>
        <property name="expire" value="1800000"/>
    </bean>

    <!--<!– 会话验证调度器 –>-->
    <!--<bean id="sessionValidationScheduler"-->
          <!--class="com.lenxeon.ucenter.user.shiro.shiro.QuartzSessionValidationScheduler">-->
        <!--<property name="sessionValidationInterval" value="1800000"/>-->
        <!--<property name="sessionManager" ref="sessionManager"/>-->
    <!--</bean>-->

    <!-- 会话ID生成器 -->
    <bean id="sessionFactory" class="com.lenxeon.ucenter.session.shiro.local.UserSessionFactory"/>

    <!-- 会话管理器 -->
    <bean id="sessionManager" class="org.apache.shiro.web.session.mgt.DefaultWebSessionManager">
    <!--<bean id="sessionManager" class="org.apache.shiro.session.mgt.DefaultSessionManager">-->
        <property name="globalSessionTimeout" value="1800000"/>
        <property name="deleteInvalidSessions" value="true"/>
        <property name="sessionValidationSchedulerEnabled" value="true"/>
        <!--<property name="sessionValidationScheduler" ref="sessionValidationScheduler"/>-->
        <property name="sessionDAO" ref="sessionDAO"/>
        <property name="sessionFactory" ref="sessionFactory"/>
        <property name="sessionIdCookie.path" value="/"/>
    </bean>

    <dubbo:reference id="userService" interface="com.lenxeon.ucenter.user.api.UserService" version="1.0.0"/>

    <!-- 继承自AuthorizingRealm的自定义Realm,即指定Shiro验证用户登录的类为自定义的ShiroDbRealm.java -->
    <bean id="myRealm" class="com.lenxeon.ucenter.session.shiro.local.UserRealm">
        <property name="userService" ref="userService"></property>
        <property name="credentialsMatcher" ref="limitRetryHashedMatcher"></property>
    </bean>

    <bean id="cacheManger" class="com.lenxeon.ucenter.session.shiro.local.RedisCacheManager"/>

    <!--<bean id="securityManager" class="com.lenxeon.ucenter.user.shiro.MyDefaultSecurityManager">-->
    <bean id="securityManager" class="org.apache.shiro.web.mgt.DefaultWebSecurityManager">
        <property name="realms">
            <list>
                <ref bean="myRealm"/>
            </list>
        </property>
        <property name="cacheManager" ref="cacheManger"/>
        <property name="sessionManager" ref="sessionManager"/>
    </bean>

    <!-- 保证实现了Shiro内部lifecycle函数的bean执行 -->
    <bean id="lifecycleBeanPostProcessor" class="org.apache.shiro.spring.LifecycleBeanPostProcessor"/>

    <!-- 开启Shiro的注解(如@RequiresRoles,@RequiresPermissions),需借助SpringAOP扫描使用Shiro注解的类,并在必要时进行安全逻辑验证 -->
    <!-- 配置以下两个bean即可实现此功能 -->
    <!-- Enable Shiro Annotations for Spring-configured beans. Only run after the lifecycleBeanProcessor has run -->
    <!-- 由于本例中并未使用Shiro注解,故注释掉这两个bean(个人觉得将权限通过注解的方式硬编码在程序中,查看起来不是很方便,没必要使用) -->

    <!-- Support Shiro Annotation -->
    <!--<bean class="org.springframework.web.servlet.handler.SimpleMappingExceptionResolver">-->
    <!--<property name="exceptionMappings">-->
    <!--<props>-->
    <!--<prop key="org.apache.shiro.authz.UnauthorizedException">shiro-test/refuse</prop>-->
    <!--</props>-->
    <!--</property>-->
    <!--</bean>-->

    <!--<bean class="org.springframework.aop.framework.autoproxy.DefaultAdvisorAutoProxyCreator"-->
    <!--depends-on="lifecycleBeanPostProcessor"/>-->
    <!-- -->

    <bean class="org.apache.shiro.spring.security.interceptor.AuthorizationAttributeSourceAdvisor">
        <property name="securityManager" ref="securityManager"/>
    </bean>

    <!-- 相当于调用SecurityUtils.setSecurityManager(securityManager) -->
    <bean class="org.springframework.beans.factory.config.MethodInvokingFactoryBean">
        <property name="staticMethod" value="org.apache.shiro.SecurityUtils.setSecurityManager"/>
        <property name="arguments" ref="securityManager"/>
    </bean>


</beans>
```

# 在其它服务端中使用时
需要依赖：ucenter-session-api
需要配置：shiroCustomFilter
需要引用： spring-client-shiro.xml

所有细节参考下图
![dubbo和shiro的整合，在服务端做权限验证]( https://img.pmowner.com/wp/2017-07-04/shiro-in-provider.png)


# web服务中关于shiro的配置
```
<import resource="classpath*:META-INF/spring/spring-local-shiro.xml"/>

    <bean class="org.apache.shiro.spring.security.interceptor.AuthorizationAttributeSourceAdvisor">
        <property name="securityManager" ref="securityManager"/>
    </bean>

    <!--我应该考虑自己实现一个dobbo的filter-->
    <!-- Shiro主过滤器本身功能十分强大,其强大之处就在于它支持任何基于URL路径表达式的、自定义的过滤器的执行 -->
    <!-- Web应用中,Shiro可控制的Web请求必须经过Shiro主过滤器的拦截,Shiro对基于Spring的Web应用提供了完美的支持 -->
    <bean id="shiroFilter" class="org.apache.shiro.spring.web.ShiroFilterFactoryBean">
        <!-- Shiro的核心安全接口,这个属性是必须的 -->
        <property name="securityManager" ref="securityManager"/>
        <!-- 要求登录时的链接(可根据项目的URL进行替换),非必须的属性,默认会自动寻找Web工程根目录下的"/login.jsp"页面 -->
        <property name="loginUrl" value="http://localhost:8092/users/login"/>
        <!-- 登录成功后要跳转的连接(本例中此属性用不到,因为登录成功后的处理逻辑在LoginController里硬编码为main.jsp了) -->
        <!-- <property name="successUrl" value="/system/main"/> -->
        <!-- 用户访问未对其授权的资源时,所显示的连接 -->
        <!-- 若想更明显的测试此属性可以修改它的值,如unauthor.jsp,然后用[玄玉]登录后访问/admin/listUser.jsp就看见浏览器会显示unauthor.jsp -->
        <property name="unauthorizedUrl" value="/"/>
        <!-- Shiro连接约束配置,即过滤链的定义 -->
        <!-- 此处可配合我的这篇文章来理解各个过滤连的作用http://blog.csdn.net/jadyer/article/details/12172839 -->
        <!-- 下面value值的第一个'/'代表的路径是相对于HttpServletRequest.getContextPath()的值来的 -->
        <!-- anon：它对应的过滤器里面是空的,什么都没做,这里.do和.jsp后面的*表示参数,比方说login.jsp?main这种 -->
        <!-- authc：该过滤器下的页面必须验证后才能访问,它是Shiro内置的一个拦截器org.apache.shiro.web.filter.authc.FormAuthenticationFilter -->
        <property name="successUrl" value="/welcome/index"/>
        <property name="filterChainDefinitions">
            <value>
                *.js = anon
                *.css=anon
                /modules/**=anon
                /static/**=anon
                /weixin/**=anon
                /users/forget.html=anon
                /users/reset.html=anon
                /users/login.html=anon
                /users/**=anon
                /oauth2/**==anon
                /test/**==anon
                <!--/api/**=anon-->

                /api/v1/users/random=anon
                /api/v1/users/sign_in=anon
                /api/v1/users/login=anon
                /api/v1/users/session=anon
                /api/v1/users/mobile/check=anon
                /api/v1/users/password/forgot=anon
                /api/v1/users/password/reset=anon
                /api/v1/users/email/check=anon
                /api/v1/security/captcha/**=anon
                /api/ids**=anon
                /api/ids/**=anon
                /**=authc

                <!--/admin/**=authc-->
                <!--/apps-web/admin/**=authc-->
                <!--/mydemo/getVerifyCodeImage=anon-->
                <!--/main**=authc-->
                <!--/user/info**=authc-->
                <!--/admin/listUser**=authc,perms[admin:manage]-->
            </value>
        </property>
    </bean>
```
