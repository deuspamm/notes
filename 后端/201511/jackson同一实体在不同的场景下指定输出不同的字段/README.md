#jackson同一实体在不同的场景下指定输出不同的字段


## 场景

我们经常会遇上这样的情况，比如有一个User实体对象，大大小小一共起码得有十几个字段，然后有一个Resource实体
对象，Resource上有一个属性是creator，类型是User。在用户注册，登陆，获取用户详情的时候这个用户对象的数据完全
输出到协议中，但在获取资源详情的时候我们并不关注用户的全部信息，而实际关注的大概也就是：用户（id, 呢称，头像）

这时底层有两种做法，
1. 用户表的这三个字段和资源表外链，在dao中一次性完成creator对象的三个属性映射
1. 先查资源对象，再查用户信息，这种方式在缓存做的比较好的时候性能并不会损耗多少

但无论采用上面哪种方式，输出到结果中时，用户对象中除了我们期望的（id, 呢称，头像）外
其它的属性依然会输出，会令我们的协议看起来不那么完美，也浪费了网络资源，因为追求完美，
所以我们要想办法实现我们的想法，在不同的场景下，我们需要对实体的输出字段进行量身定制。


我们先看看用户对象和它的父对象。
```java
package com.lenxeon.apps.user.pojo;

import com.fasterxml.jackson.annotation.JsonFilter;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.lenxeon.apps.plat.pojo.BaseBean;

import java.util.Date;

@JsonFilter("userFilter")
public class User extends BaseBean {

    protected String uuid;

    protected String loginName;

    private Boolean visited;

    protected String nickname;

    @JsonIgnore
    private String password;

    protected Integer sex;

    protected String avatarUrl;

    private String phone;

    private String sign;

    private String mobile;

    private String email;

    private Integer status;

    private Date birthday;

    private Date createDate;

    private Date lastLoginDate;

    private String summary;


    public String getUuid() {
        return uuid;
    }

    public void setUuid(String uuid) {
        this.uuid = uuid;
    }

    public String getLoginName() {
        return loginName;
    }

    public void setLoginName(String loginName) {
        this.loginName = loginName;
    }

    public Boolean getVisited() {
        return visited;
    }

    public void setVisited(Boolean visited) {
        this.visited = visited;
    }

    public String getNickname() {
        return nickname;
    }

    public void setNickname(String nickname) {
        this.nickname = nickname;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public Integer getSex() {
        return sex;
    }

    public void setSex(Integer sex) {
        this.sex = sex;
    }

    public String getAvatarUrl() {
        return avatarUrl;
    }

    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getMobile() {
        return mobile;
    }

    public void setMobile(String mobile) {
        this.mobile = mobile;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public Integer getStatus() {
        return status;
    }

    public void setStatus(Integer status) {
        this.status = status;
    }

    public Date getBirthday() {
        return birthday;
    }

    public void setBirthday(Date birthday) {
        this.birthday = birthday;
    }

    public Date getCreateDate() {
        return createDate;
    }

    public void setCreateDate(Date createDate) {
        this.createDate = createDate;
    }

    public Date getLastLoginDate() {
        return lastLoginDate;
    }

    public void setLastLoginDate(Date lastLoginDate) {
        this.lastLoginDate = lastLoginDate;
    }

    public String getSummary() {
        return summary;
    }

    public void setSummary(String summary) {
        this.summary = summary;
    }

    public String getSign() {
        return sign;
    }

    public void setSign(String sign) {
        this.sign = sign;
    }
}

```

```java
package com.lenxeon.apps.plat.pojo;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;


public class BaseBean implements Serializable, Cloneable {

    protected Map<String, Object> attributes = new HashMap<String, Object>();

    public Map<String, Object> getAttributes() {
        return attributes;
    }

    public void setAttributes(Map<String, Object> attributes) {
        this.attributes = attributes;
    }
}
```
