# MARS Remake

Godot 4.7.2 Windows 单机重制版。当前为首轮火星硬科幻界面与内容重制版。

## 当前可玩内容

- F-47 任务档案式主菜单与乘员登记。
- 扩写后的最终下降、异常扫描与迫降序幕。
- 迫降后的 F-47 舱体探索，包含驾驶舱、医疗区、生命保障、货舱和气闸。
- 医疗舱 → 生命保障 → 黑匣 → 货舱 → EVA 前检的完整任务链。
- 火星日、时段、任务和氧气/电力/水资源 HUD。
- 逐字对话、长文本分页、表达选项和对话标记。
- 暂停、v2 检查点存档与继续任务。

本轮在气闸解锁、“准备进入火星地表”处结束，尚不包含第一次 EVA 的实际玩法。

## 操作

- 移动：WASD 或方向键
- 互动：E
- 对话：空格、Enter 或鼠标左键
- 选择：方向键/Tab 移动焦点，Enter 确认
- 暂停：Esc

## 启动

- 双击 `试玩初版.bat` 直接运行。
- 双击 `打开Godot编辑器.bat` 打开工程。
- 也可以使用 Godot 4.7.2 Standard 导入 `project.godot`。

## 内容与存档

- 序幕数据：`data/dialogue/prologue.json`
- 舱内互动：`data/dialogue/interactions.json`
- 新对话可选字段：`id`、`presentation`、`effect`、`choices`、`next`、`set_flags`。
- 存档使用 v2 格式。旧灰盒 v1 存档会保留，但不会载入新地图。

## 验证

```powershell
D:\5E\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path D:\AAA个人\galgame\mars_remake --script res://tests/smoke_test.gd
```

测试覆盖对话数据校验、角色命名、选项标记、任务顺序、资源变化、EVA 解锁和 v2 存档。

## 美术状态

界面、火星背景、舱体、设备和宇航员目前均为 Godot 程序化绘制，已可作为统一风格的可玩占位。正式立绘、像素角色、地表瓦片和 CG 可在之后分层替换，不阻塞当前流程。
