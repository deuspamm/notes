#hr模块前端优化日记


### 当前的状况

* 所有的联网信息，一共53个请求，800多k，css8个，图片4个，js30个，xhr9个 总体来看页面不算太大，但请求数偏多，其中js占了30个，另外可以看出xhr中有一条非常长的绿色线最后那个请求占用了太长的时间，需要优化后端
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201510/hr模块前端优化日记/考勤优化分析.png)

* js部分
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201510/hr模块前端优化日记/考勤js.png)

* css部分
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201510/hr模块前端优化日记/考勤css.png)

* 图片部分
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201510/hr模块前端优化日记/考勤img.png)

* xhr部分
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201510/hr模块前端优化日记/考勤xhr.png)

