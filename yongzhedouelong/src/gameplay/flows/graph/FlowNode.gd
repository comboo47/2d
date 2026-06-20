class_name FlowNode extends Resource
## Flow 节点树的抽象基类（第十三期）。所有节点（Duration/Trigger/Action）的类型根。
## 极薄——行为在 FlowInterpreter 里按节点类型分派，节点本身只持数据。
## 预留 Control（判断/循环/分支）扩展位：未来 Control 节点也 extends FlowNode。

## 调试名（可选）。
@export var node_name: String = ""
