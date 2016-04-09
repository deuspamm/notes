#最近写了一段时间前端的感受extjs react fis3


## 目前的情况
最近一段时间学习了react, fis3都很火, extjs是很早以前就开始接触了大概是2.2时代。我分别用extjs,react,fis3实现了大概类似的一些界面，主要是想选一个让自己满意的技术框架。三个方案最大的一个共同点都很好的实现了组件化，这也是我选型的基本要求，先说说整体感受吧。
1. 最早就是用的extjs，用着很舒服，上手也比较容易，模块化方案成熟，标准化组件丰富，模块按需加载，mvc分层结构，但是为什么这样一个好的框架我还经纠结呢。最主要的问题就是它实现的界面相对比较固定或者说死板，如果是用来做管理后台还是不错的，但如果说用来做一个开放的web服务就显示有些“落后”了。你说extjs支持XTemplate？关于XTemplate我一直有个误区，即模板要写在JS里，这是我最不愿意看到的，因为会破坏html的结构，只要用工具一格式化js，这段tpl就变成一行了。直接后来借鉴于于todomvc中的方案,将视图层替换为独立的tpl,用ajax加载，虽然解决了这个问题，但带来的视觉上的改变其实并不大，最终还是要写大量的css，html。一会儿可以看看效果图。

这是我处理的将模板文件独立出去的方案
```JavaScript
this.items = Ext.create('Ext.view.View', {
    store: this.store,
    itemSelector: 'div.item',
    tpl:new Ext.XTemplate(''),
    loader: {
        url: 'app/modules/project/tpl/tasks.tpl',
        autoLoad: true,
        renderer: function(loader, response, active) {
            var text = response.responseText;
            console.log(loader);
            loader.getTarget().tpl = new Ext.XTemplate(text);
            console.log(loader.getTarget());
            return true;
        }
    },
    templateConfig: {
        controller: me.getController()
    },
    overItemCls: 'x-item-over',
    emptyText: '<div style="text-align:center">没有任何数据</div>',
    multiSelect: true,
    trackOver: true,
    // itemSelector: 'div.thumb-wrap',
    plugins: [
        // Ext.create('Ext.ux.DataView.DragSelector', {})
    ]
});
```
1. 第二个选用的方案是react,我没有使用bootstrap，而是直接在react-ui的基础上开发的，这也是我学习react的第一个项目。主要是实现大部分的组件自定义，因为extjs上的问题，我觉得自己有点过度考虑UI的问题了，导致想完全在这一套方案上自定义自己的组件，tab,panel,menu，侧滑等。react给我的最大的感受也是强大的状态功能（开发者只需要维护好组件自身的状态变化和数据，渲染的事react都负责了。这个和我目前的思想比较认同，比如我们经常会有一些form表单，用户提交后需要清空，我看到过很多的程序员都是傻傻的拿着jquery一个一个字段的在那处理，代码糟心不说，稍不小心就错了，为什么不用模板+空数据的方式重新渲染一个呢）和组件化方案，只有真正着手去处理项目中的实现才会明白完全自定义一套UI有多么困难。目前针对React可用的UI库和组件都还是太少了，而我实际的需求是要一套稍时尚一点简洁一点的UI，必要的时候能够不用花太大的代价可以自定。如果继续用react会严重影响我今后的进度。

1. fis3说起来和上面两个其实是有区别的，前两者都框架，fis3其实只是一个前端项目管理方案。意思就是说fis3主要的功能是在管理，可能和webpack更接近，提供插件整合，预编译，打包，压缩，按需加载，fis3并不关心你究竟是用传统的jquery还是用现在的react，它提供的是让你能更好的管理你的项目。就像java中的maven，自身并不参与到业务代码中去。




## 实践效果图

* extjs
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201604/最近写了一段时间前端的感受extjs react fis3/ext-01.png)
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201604/最近写了一段时间前端的感受extjs react fis3/ext-02.png)
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201604/最近写了一段时间前端的感受extjs react fis3/ext-03.png)

* react
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201604/最近写了一段时间前端的感受extjs react fis3/react-01.png)
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201604/最近写了一段时间前端的感受extjs react fis3/react-02.png)
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201604/最近写了一段时间前端的感受extjs react fis3/react-03.png)

* fis3
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201604/最近写了一段时间前端的感受extjs react fis3/fis-01.png)
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201604/最近写了一段时间前端的感受extjs react fis3/fis-02.png)
![ls 效果图](https://github.com/lenxeon/notes/blob/master/前端/201604/最近写了一段时间前端的感受extjs react fis3/fis-03.png)
