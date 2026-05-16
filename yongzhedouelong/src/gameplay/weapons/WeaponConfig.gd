class_name WeaponConfig
## 武器配置常量
## 定义武器类型、子弹类型等枚举

## 武器类型枚举
enum WeaponType {
	BOW,        # 弓箭（蓄力增加速度）
	BOTTLE,     # 瓶子（蓄力散射）
	CROSSBOW,   # 弩枪（蓄力连射）
	ENEMY,      # 敌人武器
}

## 子弹类型枚举（传递给 BulletManager）
enum BulletType {
	NORMAL,     # 普通子弹（受重力影响）
	STRAIGHT,   # 直射子弹（无重力）
	HOMING,     # 追踪子弹
	EXPLOSIVE,  # 爆炸子弹
}

## 武器状态枚举
enum WeaponState {
	IDLE,       # 待机
	CHARGING,   # 蓄力中
	FIRING,     # 发射中
	COOLDOWN,   # 冷却中
	EMPTY,      # 能量耗尽（弩枪）
}

## 默认参数配置
const DEFAULT_PARAMS := {
	WeaponType.BOW: {
		"base_speed": 250.0,
		"max_charge_speed": 650.0,
		"charge_rate": 5.0,
		"bullet_type": BulletType.NORMAL,
	},
	WeaponType.BOTTLE: {
		"base_speed": 300.0,
		"spread_angle": 0.25,
		"charge_time": 0.7,
		"bullet_type": BulletType.NORMAL,
	},
	WeaponType.CROSSBOW: {
		"base_speed": 250.0,
		"max_energy": 100.0,
		"energy_cost": 10.0,
		"energy_regen": 3.0,
		"fire_interval": 0.1,
		"charge_time": 0.7,
		"bullet_type": BulletType.STRAIGHT,
	},
}

## 获取武器类型名称（调试用）
static func get_weapon_type_name(weapon_type: WeaponType) -> String:
	match weapon_type:
		WeaponType.BOW: return "BOW"
		WeaponType.BOTTLE: return "BOTTLE"
		WeaponType.CROSSBOW: return "CROSSBOW"
		WeaponType.ENEMY: return "ENEMY"
		_: return "UNKNOWN"

## 获取子弹类型名称（调试用）
static func get_bullet_type_name(bullet_type: BulletType) -> String:
	match bullet_type:
		BulletType.NORMAL: return "NORMAL"
		BulletType.STRAIGHT: return "STRAIGHT"
		BulletType.HOMING: return "HOMING"
		BulletType.EXPLOSIVE: return "EXPLOSIVE"
		_: return "UNKNOWN"