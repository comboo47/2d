class_name LevelDefinition extends Resource

@export var level_id: String = ""
@export var level_name: String = ""
## 通关后解锁的下一关 id（空=无后续，本关是末关）。
@export var next_level_id: String = ""
## 选关界面排序用（升序）。
@export var level_order: int = 0
## 是否在选关界面展示（关卡内容关卡=true；测试/示例夹具关卡设 false 不进选关列表）。
@export var show_in_select: bool = true
@export var initial_actors: Array[LevelActorDefinition] = []
@export var initial_buffs: Array[LevelBuffDefinition] = []
@export var event_flows: Dictionary = {}

func get_event_flows(event_type: GameplayEvent.EventType) -> Array:
	return event_flows.get(event_type, [])
