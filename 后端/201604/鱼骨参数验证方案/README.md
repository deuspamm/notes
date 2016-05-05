#鱼骨参数验证方案

## 场景及问题
1. 参数验证是一个很常见的问题，为了保证系统的正常运行和给用户比较友好的提示，这些都是必不可少的工作

## 打算使用 hibernate.validator，在接口上进行注解（其实可以注解到实现上，这样可以保证接口的纯净，但注解在接口上也是有好处的，使用的人可以看到参数的验证要求）自定义aop调用hibernate的api进行验证，再适当的结合一下多国语言方案。

接口上的使用示例，全部采用注解的方式，较复杂的验证用正则表达式完成
```java
package com.lenxeon.apps.uc.user.api;

import com.lenxeon.apps.uc.user.pojo.User;
import com.lenxeon.apps.uc.user.pojo.em.Regexp;
import org.hibernate.validator.constraints.Email;
import org.hibernate.validator.constraints.Length;
import org.hibernate.validator.constraints.NotBlank;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;
import java.util.Date;


//
public interface UserService {

    /**
     * 通过手机号注册
     *
     * @param nickName 呢称
     * @param mobile   手机
     * @param password 密码
     * @return
     */
    @NotNull
    User signUpMobile(String nickName
            , @Pattern(regexp = Regexp.MOBILE, message = "uc.vail.mobile_format_error") String mobile
            , @Pattern(regexp = Regexp.PASSWORD, message = "uc.vail.password_format_error") String password);

    /**
     * 通过邮件注册
     *
     * @param nickName 呢称
     * @param email    邮箱
     * @param password 密码
     * @return
     */
    @NotNull
    User signUpEmail(String nickName
            , @Email(message = "uc.vail.email_format_error") String email
            , @Pattern(regexp = Regexp.PASSWORD, message = "uc.vail.password_format_error") String password);

    /**
     * 修改密码
     *
     * @param userId
     * @param oldPassword
     * @param password
     * @return
     */
    int changePassword(String userId
            , @NotNull(message = "uc.vail.password_required") String oldPassword
            , @Pattern(regexp = Regexp.PASSWORD, message = "uc.vail.password_format_error") String password);

    /**
     * 重置密码
     *
     * @param userId
     * @param password
     * @return
     */
    int resetPassword(String userId
            , @Pattern(regexp = Regexp.PASSWORD, message = "uc.vail.password_format_error") String password);


    /**
     * 用户修改个人头像
     *
     * @param userId
     * @param avatar
     * @return
     */
    int changeAvatar(String userId
            , @Pattern(regexp = Regexp.URL, message = "uc.vail.avatar_format_error") String avatar);

    /**
     * 设置唯一登陆用户名
     *
     * @param userId
     * @param loginName
     * @return
     */
    int setLoginName(String userId
            , @Pattern(regexp = Regexp.LOGIN_NAME, message = "uc.vail.login_name_format_error") String loginName);

    /**
     * 修改签名
     *
     * @param userId
     * @param sign
     * @return
     */
    int changeSign(String userId, String sign);

    /**
     * 修改用户状态
     *
     * @param userId
     * @param status
     * @return
     */
    int changeStatus(String userId, int status);


    /**
     * 修改个人基本信息
     *
     * @param userId
     * @param nickName
     * @param sex
     * @param birthday
     * @param summary
     * @return
     */
    int changeBasicInfo(String userId, String nickName, int sex, Date birthday, String summary);


    /**
     * 用户登陆
     *
     * @param identify
     * @param password
     * @return
     */
    @NotNull
    User login(@NotBlank(message = "uc.vail.identify_required")
               @Length(min = 6, max = 16, message = "用户名[${validatedValue}]长度必须在{min}到{max}之间")
               String identify,
               @NotBlank(message = "uc.vail.password_required")
               @Length(min = 6, max = 16, message = "{uc.vail.password_length_illegal}")
               String password);

    /**
     * 通过用户标签获取信息
     *
     * @param identify
     * @return
     */
    User findByIdentify(@NotBlank(message = "uc.vail.identify_required") String identify);

}

```

这里并没有完全采用hibernate的方案，而是自己实现了基于aop的验证器，方案应该是没有问题的，后续应该还有一些使用中的调整

```
package com.lenxeon.apps.plat.aop;

import com.lenxeon.apps.plat.utils.LocaleUtils;
import com.lenxeon.utils.io.JsonUtils;
import com.lenxeon.utils.str.FastStringBuilder;
import org.apache.commons.lang.StringUtils;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.reflect.MethodSignature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;

import javax.validation.*;
import javax.validation.executable.ExecutableValidator;
import javax.validation.metadata.ConstraintDescriptor;
import java.util.Arrays;
import java.util.Map;
import java.util.Set;

public class ServiceAspect {

    private static Logger logger = LoggerFactory.getLogger(ServiceAspect.class);

    @Autowired
    private LocaleUtils localeUtils;


    public void doAfter(JoinPoint jp) {

    }

    public void doAfterReturn(Object val) {
        System.out.println(JsonUtils.toJson(val));
    }

    public Object doAround(ProceedingJoinPoint pjp) throws Throwable {
        long time = System.currentTimeMillis();
        Object retVal = pjp.proceed();

//        MethodSignature methodSignature = (MethodSignature) pjp.getSignature();
//        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
//        ExecutableValidator validator = factory.getValidator().forExecutables();
//        Set<? extends ConstraintViolation<?>> violations = validator.validateReturnValue(pjp.getTarget(), methodSignature.getMethod(), retVal);
//        if (!violations.isEmpty()) {
//            throw buildValidationException(violations);
//        }

        time = System.currentTimeMillis() - time;
        String method = pjp.getTarget().getClass().getName() + "." + pjp.getSignature().getName();
        logger.info("ServiceAspect-method:[{}]-cost:[{}]ms", method, time);
        return retVal;
    }

    public void doBefore(JoinPoint jp) {
        try {
            ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
            ExecutableValidator validator = factory.getValidator().forExecutables();
            MethodSignature methodSignature = (MethodSignature) jp.getSignature();
            logger.info("Validating call: {} with args {}", methodSignature.getMethod(), Arrays.toString(jp.getArgs()));
            Set<? extends ConstraintViolation<?>> violations = validator.validateParameters(jp.getTarget(), methodSignature.getMethod(), jp.getArgs());
            if (!violations.isEmpty()) {
                throw buildValidationException(violations);
            }
        } catch (Exception ex) {
            if (StringUtils.contains(ex.getMessage(), "doesn't belong to class")) {
                System.out.println(ex.getMessage());
            } else {
                throw new RuntimeException(ex);
            }
        }
    }

    public void doThrowing(JoinPoint jp, Throwable ex) {
        System.out.println(ex.getMessage());
    }

    private RuntimeException buildValidationException(Set<? extends ConstraintViolation<?>> validationErrors) {
        StringBuilder sb = new StringBuilder();
        for (ConstraintViolation<?> cv : validationErrors) {
            Path path = cv.getPropertyPath();
            ConstraintDescriptor<?> cd = cv.getConstraintDescriptor();
            Map<String, Object> attr = cd.getAttributes();
            FastStringBuilder builder = new FastStringBuilder();


            System.out.println(cv.getMessage());
            System.out.println(cv.getMessageTemplate());
            System.out.println(cv.getInvalidValue());
            System.out.println(JsonUtils.toJson(cv.getExecutableParameters()));
            System.out.println(JsonUtils.toJson(cv.getConstraintDescriptor()));
            String msg = localeUtils.getMessage(cv.getMessage(), cv.getInvalidValue(), path);
            sb.append(msg).append(",");
        }
        return new ValidationException(StringUtils.substringBeforeLast(sb.toString(), ","));
    }
}
```
