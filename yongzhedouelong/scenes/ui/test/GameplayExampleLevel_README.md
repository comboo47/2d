# Gameplay Example Level

入口场景：

```text
res://scenes/ui/test/GameplayExampleLevel.tscn
```

直接在 Godot 中打开并运行这个场景即可。场景启动时会通过 `LevelRunner.start_level()` 加载 `example_test_level`，生成一个主角和一个敌人，然后让主角自动施放 `example_firebolt`。

资源链路：

```text
GameplayExampleLevel.tscn
-> resources/gameplay/levels/example_test_level.tres
-> resources/gameplay/skills/example_firebolt_skill.tres
-> resources/gameplay/flows/example_skill_damage_flow.tres
-> resources/gameplay/buffs/example_burn_buff.tres
-> resources/gameplay/flows/example_burn_tick_flow.tres
```

验证命令：

```powershell
godot --headless --path . -s res://tests/GameplayExampleLevelSmokeTest.gd
```
