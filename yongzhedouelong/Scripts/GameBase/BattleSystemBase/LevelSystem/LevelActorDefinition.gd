class_name LevelActorDefinition extends Resource

@export var actor_scene: PackedScene
@export var position: Vector2 = Vector2.ZERO
@export var initial_skills: Array[SkillBase] = []
@export var initial_buffs: Array[AttributeBuff] = []
