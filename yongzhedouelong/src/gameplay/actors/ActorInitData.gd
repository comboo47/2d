class_name ActorInitData extends Resource
## Actor 初始化数据（第十一期）。一份独立的「实例初始化」资源，与 ActorDefinition（GPManager
## 编辑的配置层）分开。运行时由生成方（LevelRunner）在实例化 actor 后经 setup_init_data 注入。
##
## 本期只承载两个生命周期 flow（FlowGraph 节点树引用，非 string id）：
##   spawn_flow — actor 出生时启动的 flow（出生逻辑）。
##   death_flow — actor 死亡时启动的 flow；actor 的最终销毁推迟到它 finish。
## 第十三期：从 GameplayFlowBase 改为 FlowGraph（解释器驱动）。
## 未来扩展点：可在此收编 attributes / skills / buffs 等实例初始化数据。

## 出生 flow（可空）。
@export var spawn_flow: FlowGraph

## 死亡 flow（可空）。跑完需以 finish action 通知 actor 可销毁（死亡延迟门控）。
@export var death_flow: FlowGraph
