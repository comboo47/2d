class_name VfxConfig
## 特效配置常量
## 定义特效类型、路径和池大小

## 特效类型枚举
enum VfxType {
	JUMP_PARTICLE,      # 跳跃粒子
	HIT_IMPACT,         # 受击特效
	DEATH_EFFECT,       # 死亡特效
	BULLET_HIT,         # 弹道命中
	SKILL_EFFECT,       # 技能特效
	BUFF_APPLY,         # Buff 应用特效
	BUFF_REMOVE,        # Buff 移除特效
	SPAWN_EFFECT,       # 生成特效
}

## 特效场景路径映射
const VFX_PATHS := {
	VfxType.JUMP_PARTICLE: "res://art/GameplayArtResource/Fx/fx_jump_particle.tscn",
	VfxType.HIT_IMPACT: "res://art/GameplayArtResource/Fx/fx_hit_impact.tscn",
	VfxType.DEATH_EFFECT: "res://art/GameplayArtResource/Fx/fx_death.tscn",
	VfxType.BULLET_HIT: "res://art/GameplayArtResource/Fx/fx_bullet_hit.tscn",
	VfxType.SKILL_EFFECT: "res://art/GameplayArtResource/Fx/fx_skill.tscn",
	VfxType.BUFF_APPLY: "res://art/GameplayArtResource/Fx/fx_buff_apply.tscn",
	VfxType.BUFF_REMOVE: "res://art/GameplayArtResource/Fx/fx_buff_remove.tscn",
	VfxType.SPAWN_EFFECT: "res://art/GameplayArtResource/Fx/fx_spawn.tscn",
}

## 特效池大小配置
const POOL_SIZES := {
	VfxType.JUMP_PARTICLE: 5,
	VfxType.HIT_IMPACT: 10,
	VfxType.DEATH_EFFECT: 5,
	VfxType.BULLET_HIT: 15,
	VfxType.SKILL_EFFECT: 8,
	VfxType.BUFF_APPLY: 5,
	VfxType.BUFF_REMOVE: 5,
	VfxType.SPAWN_EFFECT: 5,
}

## 默认特效持续时间（秒）
const DEFAULT_DURATION := {
	VfxType.JUMP_PARTICLE: 0.5,
	VfxType.HIT_IMPACT: 0.3,
	VfxType.DEATH_EFFECT: 0.5,
	VfxType.BULLET_HIT: 0.2,
	VfxType.SKILL_EFFECT: 0.5,
	VfxType.BUFF_APPLY: 0.3,
	VfxType.BUFF_REMOVE: 0.3,
	VfxType.SPAWN_EFFECT: 0.5,
}

## 获取特效场景路径（重命名避免与 GDScript.get_path() 冲突）
static func get_vfx_scene_path(vfx_type: VfxType) -> String:
	return VFX_PATHS.get(vfx_type, "")

## 获取池大小
static func get_pool_size(vfx_type: VfxType) -> int:
	return POOL_SIZES.get(vfx_type, 5)

## 获取默认持续时间
static func get_duration(vfx_type: VfxType) -> float:
	return DEFAULT_DURATION.get(vfx_type, 0.5)

## 检查特效路径是否存在
static func has_vfx_path(vfx_type: VfxType) -> bool:
	var path = get_vfx_scene_path(vfx_type)
	return path != "" and ResourceLoader.exists(path)

## 获取特效类型名称（调试用）
static func get_type_name(vfx_type: VfxType) -> String:
	match vfx_type:
		VfxType.JUMP_PARTICLE: return "JUMP_PARTICLE"
		VfxType.HIT_IMPACT: return "HIT_IMPACT"
		VfxType.DEATH_EFFECT: return "DEATH_EFFECT"
		VfxType.BULLET_HIT: return "BULLET_HIT"
		VfxType.SKILL_EFFECT: return "SKILL_EFFECT"
		VfxType.BUFF_APPLY: return "BUFF_APPLY"
		VfxType.BUFF_REMOVE: return "BUFF_REMOVE"
		VfxType.SPAWN_EFFECT: return "SPAWN_EFFECT"
		_: return "UNKNOWN"