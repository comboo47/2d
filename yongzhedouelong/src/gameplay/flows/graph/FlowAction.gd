class_name FlowAction extends FlowNode
## 瞬时动作节点（第十三期）。两种形态：
##  - 数据 Action：action_name + opts，解释器分派到 FlowActions 静态库（deal_damage/fire_projectile/...）。
##  - 脚本叶子 Action：leaf 非空时优先，承载带计算的逻辑（FlowLeaf 子类）。

## 数据 Action：对应 FlowActions 的方法名（"deal_damage"/"fire_projectile"/"apply_buff"/
## "modify_attr"/"spawn_entity"/"play_vfx"/"finish"）。
@export var action_name: String = ""
## 数据 Action 的参数，原样喂给 FlowActions。
@export var opts: Dictionary = {}
## apply_buff 用：buff 资源引用（opts 里塞 Resource 不直观，单列）。
@export var buff_res: AttributeBuff = null
## 脚本叶子（非空时优先于 action_name）。
@export var leaf: FlowLeaf = null
