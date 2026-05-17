class_name CampaignOutline extends Resource

@export var campaign_id: String = ""
@export var campaign_name: String = ""
@export var genre_notes: PackedStringArray = []
@export var reincarnation_hook: String = ""
@export var acts: Array[Resource] = []

func get_act_by_id(act_id: String) -> Resource:
	for act in acts:
		if act and act.act_id == act_id:
			return act
	return null

func get_room_clear_acts() -> Array[Resource]:
	var routed_acts: Array[Resource] = []
	for act in acts:
		if act and act.uses_room_clear_routes:
			routed_acts.append(act)
	return routed_acts
