extends CharacterBody2D
class_name BattleActor

var State:BattleStats

func SetStats(state:BattleStats) -> void:
	State = state
	self.set_meta("State",state)

func GetStatus() -> BattleStats:
	if State != null:
		return State
	elif self.get_meta("State")!=null:
		return self.get_meta("State")
	else:
		return null
