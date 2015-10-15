#hr模块前端优化笔记


## 当前的状况

* 所有的联网信息，一共53个请求，800多k，css8个，图片4个，js30个，xhr9个 总体来看页面不算太大，但请求数偏多，其中js占了30个，另外可以看出xhr中有一条非常长的绿色线最后那个请求占用了太长的时间，需要优化后端
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201510/hr模块前端优化笔记/考勤优化分析.png)

* js部分
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201510/hr模块前端优化笔记/考勤js.png)

* css部分
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201510/hr模块前端优化笔记/考勤css.png)

* 图片部分
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201510/hr模块前端优化笔记/考勤img.png)

* xhr部分
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201510/hr模块前端优化笔记/考勤xhr.png)


## 最终期望的结果
* 需要对html/js/css文件进行压缩
* 需要对图片进行压缩处理
* 需要调整文件的结构，将所有的css引用放在头部,所有的js放在尾部
* 针对css/js进行请求合并，由于项目引用文件来自两部分，一部分是通用ui，一部分是业务本身，因此打算分别合并为两个文件如：
lib.css hr.css 和 lib.js hr.js
* 开发中的相对路径替换为绝对路径
* 对所有的引用添加文件hash用于资源的缓存及更新

#规划构想
## 开发结构
在开始之前我先进行了一些规划构想，假设今后的项目分为几个子项目独立管理，有通用ui框架，mod模块化框架，mod-*各类业务模块其中各类业务模块只有一个首页面，为单页面应用，目录结构如下
```shell
├── common-ui
│   ├── images
│   ├── index.html
│   ├── js
│   ├── less
│   ├── lib
│   ├── template
│   └── widget
├── lib
│   └── mod
├── mod-admin
│   ├── images
│   ├── index.html
│   ├── js
│   ├── less
│   ├── lib
│   └── template
├── mod-crm
│   ├── images
│   ├── index.html
│   ├── js
│   ├── less
│   ├── lib
│   └── template
└── mod-hr
    ├── images
    ├── index.html
    ├── js
    ├── less
    ├── lib
    └── template
```

## 发布结构
目录发布结构主要涉及了三个方面
* static目录：静态资源的存放，这部分资源将来可能会部署到静态资源服务器上，我们经常能看到一些网站的js域名为static.*
* map目录：map目录里主要存放的是该项目的资源依懒关系分析结果
* proj目录：这个目录主要是项目的入口
另外，整个项目支持版本发布的

```
├── map
│   ├── common-ui
│   │   └── 1.0.1.json
│   ├── mod-admin
│   │   └── 1.0.1.json
│   ├── mod-crm
│   │   └── 1.0.1.json
│   └── mod-hr
│       └── 1.0.1.json
├── proj
│   ├── common-ui
│   │   └── 1.0.1
│   │       ├── index.html
│   │       └── lib
│   ├── mod-admin
│   │   └── 1.0.1
│   │       ├── index.html
│   │       └── lib
│   ├── mod-crm
│   │   └── 1.0.1
│   │       ├── index.html
│   │       └── lib
│   └── mod-hr
│       └── 1.0.1
│           ├── index.html
│           └── lib
└── static
    ├── common-ui
    │   └── 1.0.1
    │       ├── js
    │       ├── less
    │       └── pic
    ├── mod-admin
    │   └── 1.0.1
    │       ├── js
    │       ├── less
    │       └── pic
    ├── mod-crm
    │   └── 1.0.1
    │       ├── js
    │       ├── less
    │       └── pic
    └── mod-hr
        └── 1.0.1
            ├── js
            ├── less
            └── pic
```

#组件化开发之路

* 借用 @fouber 的两张图来描述这个问题，我觉得组件化开发应该包括两个部分。

1. ui的组件化，如常用的button, tab, panel, 这个领域里extjs应该是目前划分的最全面，最细致的。
1. 业务的组件化，比如用户登陆窗口。在任何模块下都可能因为需要登陆而调用些模块，同样还有一些其它的业务模块
可能会跨模块或者子系统被调用。

* 模块化还有一个更大的作用就是，让开发者可以专注于模块自身功能的开发而不被干扰，通过参数配置和回调函数的作用，明确自己的职责范围，
同时为使用者提供优雅的使用体验，举个例子，一个简单的tip提示标签，使用者仅需要配置好要提示的信息，而不必去关心这个tip的样式，动画，弹出位置等问题，简化业务开发者的开发难度

##组件化前端开发
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201510/hr模块前端优化笔记/组件化前端开发.png)

##组件化开发分工
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201510/hr模块前端优化笔记/组件化开发分工.png)
