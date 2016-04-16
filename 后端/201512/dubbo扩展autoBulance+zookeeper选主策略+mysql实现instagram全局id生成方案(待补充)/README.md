#dubbo扩展autoBulance+zookeeper选主策略+mysql实现instagram全局id生成方案


## 场景

>先做一个计划，准备中，初步想法写一个集群id生成服务，部署多个生产者，通过自定义的autoBulance
和zookeeper的选主策略判断当前哪个节点是主，由主节点提供ID生成，当主节点发生变化时，先清除新主
的缓冲部分id，从数据库上生成新的缓冲id.这样即保证了不用每次从数据库取，又防止了新主中有上次未使
用的记录导致id时间顺序混乱的问题。
