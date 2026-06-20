# 新增武器步骤（Flow 驱动模型）

> 本文档对应第三期重构后的武器系统：**武器 = 数据载体，开火逻辑写在 Flow 里**。
> 旧的 `weapon_base` + `WeaponBow/Bottle/Crossbow` 子类模型已废弃删除。

## 模型速览

一把武器由三部分组成：

| 部分 | 是什么 | 文件 |
|---|---|---|
| **数据** | `WeaponDefinition`（持有 input_mode + fire_flow + bullet_def + 数值） | `resources/gameplay/weapons/<id>.tres` |
| **逻辑** | 继承 `WeaponFireFlowBase` 的常驻 Flow（蓄力/连发/能量/发射都在此） | `src/gameplay/flows/scripts/Flow_*.gd` + `resources/gameplay/flows/*.tres` |
| **节点** | `WeaponDriver`（通用瘦节点，所有武器共用，不用改） | `src/gameplay/weapons/WeaponDriver.gd` |

运行时链路：装备武器 → `WeaponDriver` 把 `fire_flow` 交给 `FlowRuntime` 常驻 → 玩家开火输入经 `input_mode` 翻译成语义事件（PRESSED/RELEASED）→ 常驻 Flow 的 `on_event`/`on_tick` 决定发射 → `FE_FireProjectile` → `BulletManager`。

---

## 路径 A：复用现有开火逻辑，只换数据（最快，无需写码）

适合「换贴图/数值/子弹/散射数」这类变体。

1. 打开 Godot 左下 **Weapons** dock（weaponeditor 插件）。
2. 点 **模板▾** → 选弓/瓶/弩任一（会预挂好 input_mode + 对应 fire_flow）。
3. 选中新建的武器 → 点 **编辑** → 在主 Inspector 调 `display_name`、`base_speed`、`base_damage`、`bullet_def`、`extra_params` 等。
4. （可选）换子弹：点 **＋子弹** 或选现成 `BulletDefinition`，拖进武器的 `bullet_def`。
5. 把武器 `.tres` 挂到 `WeaponDriver` 节点的 `definition` 字段即可使用（见下方「挂载」）。

---

## 路径 B：全新开火逻辑（写一个 Flow 脚本）

适合「全新开火机制」——三连发、霰弹扇形、蓄力变形、边走边充能等现有逻辑无法表达的。

### 步骤 1：写开火 Flow 脚本

新建 `src/gameplay/flows/scripts/Flow_<名字>Fire.gd`，继承 `WeaponFireFlowBase`，重写需要的钩子：

```gdscript
extends WeaponFireFlowBase
## 示例：双发武器——按下立即打两发

func on_fire_pressed(ctx: GameplayFlowContext) -> void:
    if not has_energy(_energy_cost):
        return
    consume_energy(_energy_cost)
    fire_shot(ctx)                       # 第一发
    fire_shot(ctx, -1.0, 2, 0.15)        # 也可一次散射：count=2, spread=0.15 弧度
```

**基类已提供的能力**（无需自己实现）：
- 运行时状态：`_energy` / `_max_energy` / `charge_time` / `_is_pressed`（自动维护）
- `has_energy(cost)` / `consume_energy(cost)`：能量管理
- `charged_speed()`：base + 蓄力加成后的速度（封顶 max_charge_speed）
- `fire_shot(ctx, speed=-1, count=1, spread=0.0)`：发射（走 BulletManager），speed<0 用 base_speed
- `_def`：武器的 WeaponDefinition（读 `extra_params` 等）

**可重写的钩子**（默认空）：
- `_on_equip(ctx)`：装备时一次，读 `_def.extra_params` 初始化自定义参数
- `on_fire_pressed(ctx)` / `on_fire_released(ctx)`：开火键按下 / 松开
- `on_fire_tick(ctx, delta)`：每帧（连发节奏、蓄力判定）

参考现成实现：`Flow_BowFire`（蓄力增速单发）、`Flow_BottleFire`（蓄力满散射）、`Flow_CrossBowFire`（能量连发）、`Flow_PistolFire`（长按连发）。

### 步骤 2：建 fire_flow 资源

新建 `resources/gameplay/flows/<名字>FireFlow.tres`：

```
[gd_resource type="Resource" script_class="GameplayFlowBase" load_steps=2 format=3]
[ext_resource type="Script" path="res://src/gameplay/flows/scripts/Flow_<名字>Fire.gd" id="1_f"]
[resource]
script = ExtResource("1_f")
flow_id = "Flow_<名字>Fire"
flow_name = "<名字>·开火Flow"
is_persistent = true
listen_events = [13, 15]   # 13=WEAPON_FIRE_PRESSED, 15=WEAPON_FIRE_RELEASED（长按连发可加 14=HELD）
```

> `is_persistent = true` 必填——常驻 Flow 才会被 FlowRuntime 持有并 tick。
> `listen_events` 是 `GameplayEvent.EventType` 的 int 值，决定哪些事件触发 `on_event`。

### 步骤 3：建 WeaponDefinition

用 weaponeditor **＋武器** 新建，或手写 `.tres`，关键字段：
- `input_mode`：内联一个 `WeaponInputMode`（`mode`: 0=CLICK 点击 / 1=HOLD 长按连发 / 2=CHARGE 蓄力）
- `fire_flow`：指向步骤 2 的 `.tres`
- `bullet_def`：子弹定义
- `min_fire_interval`：射速上限（秒），见下方「射速门控」
- 数值：`base_speed` / `base_damage` / 能量三件套 / `charge_time` / `extra_params`

---

## 射速门控（min_fire_interval）

`WeaponDefinition.min_fire_interval` 是**射速上限**——两次发射的最短间隔（秒）。狂点鼠标也不会超过它，避免「点得越快射得越快」。

- **0（默认）= 不限制**：每次 `fire_shot` 都发，手速即射速（旧行为）。
- **>0**：开一枪后进入冷却，冷却内的 `fire_shot` **不丢弃**而是缓冲一发，冷却结束瞬间自动补发（手感跟手）。

实现位置在基类 `WeaponFireFlowBase.fire_shot()`，**所有武器自动生效，写 Flow 时无需关心**——你照常调 `fire_shot(ctx)`，门控与缓冲是透明的。`on_tick` 负责冷却倒计时与补发。

> 注意：HOLD 连发武器若 `min_fire_interval` 比连发间隔大，则以射速门控为准（取更慢者）。缓冲只缓 1 发，狂点不会攒一堆在冷却后爆发。

现役参考值：弓 0.3 / 瓶 0.4 / 弩 0.1 / 手枪 0.12（在 weaponeditor Inspector 里可直接调）。

---

## 挂载到游戏里

武器是 `WeaponRoot`（`scenes/components/Weapon_Component.tscn`）下的子节点。每个子节点是一个挂 `WeaponDriver.gd` 的场景，其 `definition` 字段指向武器 `.tres`：

- **替换现有武器**：选中 `Weapon_Component.tscn` 里某个武器节点，把新武器 `.tres` 拖到 `definition`。
- **新增武器槽**：复制一个现有武器场景（如 `scenes/weapons/Bow/weapon_Bow.tscn`），换 `definition`，加进 `WeaponComponent`（注意 `WeaponRoot.currentWeapon` 的 `@export_range(0,2)` 和 `Player._test_input` 的切换上限，超过 3 把需放宽）。

游戏内：**Q** 切武器，**按住鼠标左键**开火。

---

## 验证

- 解析检查：`godot --headless --editor --path . --quit`（EXIT=0）
- 回归：`tests/WeaponSystemTest.gd`、`tests/FlowRuntimeTest.gd`
- 手测：进关卡，Q 切到新武器，开火确认弹道/伤害/特性正确

## 扩展点速查

| 想加 | 做什么 |
|---|---|
| 新武器变体（换数值/子弹） | 新建 WeaponDefinition `.tres`（路径 A） |
| 调武器射速上限 | 改 WeaponDefinition 的 `min_fire_interval`（0=不限制） |
| 新开火逻辑 | 写 `WeaponFireFlowBase` 子类 + fire_flow `.tres`（路径 B） |
| 新子弹外观/属性 | 新建 BulletDefinition `.tres` |
| 新弹道运动 | 新建 `BulletMotionBase` 子类 + 在 `BulletMotionRegistry.TABLE` 注册 + BulletDefinition 选 motion_key |
