#前端组件间交互


*我们都提倡前端组件化，好处多多：代码复用，减少重复劳动；统一规范，不至于一个系统中同样是按钮，长的五花八门。

## 下面还是先看图

![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201510/前端组件间交互/前端组件间交互.png)

* 根据这张图，产品要求如下：
1. 上方保存或者修改后下方的数据需要同步更新。
1. 选中下方某一条的时候，上方需要显示该条数据的内容。

假定我们定义这个页面有两个组件 form list

```
var form = {
    init: function(){

    },
    render: function(){

    },
    saveHandler: function(){

    },
    updateHandler: function(){

    },
}

var list = {
    init: function(){

    },
    render: function(){

    },
    refreshHandler: function(){

    },
    deleteHandler: function(){

    }
}

```

