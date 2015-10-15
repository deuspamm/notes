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
