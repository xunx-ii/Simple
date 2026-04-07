# Godot 2D 游戏开发代码规范

## 1. 适用范围

本规范适用于当前项目的 Godot 2D 游戏开发工作，默认基于以下约定：

- 引擎版本：Godot 4.x
- 主要语言：GDScript
- 项目类型：2D 游戏
- 目标：提升可读性、可维护性、可协作性，降低功能迭代和问题排查成本

如无特殊说明，新增代码、场景、资源、目录结构均应遵循本规范。

## 2. 核心原则

### 2.1 单一职责

- 一个场景只解决一类问题。
- 一个脚本只负责一个明确职责。
- 一个函数只完成一个稳定目标。

### 2.2 优先组合，谨慎继承

- 优先通过子场景、组件节点、资源配置完成复用。
- 只有在行为模型稳定且抽象清晰时，才使用继承层级。
- 避免为了“通用”而过早抽象。

### 2.3 数据与表现分离

- 配置数据、运行逻辑、视觉表现尽量拆分。
- 可配置内容优先放入 `Resource`、导出变量或配置表中。
- 不将平衡参数、数值配置硬编码在业务逻辑里。

### 2.4 显式优于隐式

- 关键依赖要能从脚本声明、导出字段或固定节点结构中直接看出。
- 避免依赖隐藏路径、动态拼接名称和难以追踪的副作用。

### 2.5 可读性优先

- 代码先服务于团队理解，再服务于个人写法偏好。
- 当“更短”与“更清晰”冲突时，优先选择更清晰的写法。

## 3. 目录规范

推荐目录结构如下：

```text
res://
  scenes/
    actors/
    levels/
    ui/
    effects/
    systems/
  scripts/
    actors/
    components/
    systems/
    ui/
    utils/
  resources/
    configs/
    data/
  autoload/
  assets/
    textures/
    audio/
    fonts/
    shaders/
  tests/
  docs/
```

约束如下：

- `scenes/` 只放场景文件及其强相关资源。
- `scripts/` 只放脚本，避免与场景混放过深。
- `resources/` 放 `Resource` 配置、数值定义、静态数据。
- `autoload/` 只放全局单例脚本，不放业务杂项。
- `assets/` 按资源类型管理，不按“临时用途”命名。
- `docs/` 放设计文档、开发规范、流程说明。

## 4. 命名规范

### 4.1 文件与目录

- 文件名、目录名统一使用 `snake_case`。
- 禁止使用空格、拼音缩写、无语义编号。

示例：

- `player_controller.gd`
- `enemy_spawner.gd`
- `stage_01.tscn`
- `hit_flash_material.tres`

### 4.2 类名

- `class_name` 使用 `PascalCase`。
- 类名要体现职责，不使用过度泛化名称。

示例：

- `class_name PlayerController`
- `class_name EnemySpawner`
- `class_name HealthComponent`

### 4.3 节点名

- 节点名统一使用 `PascalCase`。
- 同类节点可带职责前缀，但要保持可读性。

示例：

- `Player`
- `CameraTarget`
- `Hitbox`
- `AnimationPlayer`

### 4.4 变量与函数

- 变量名、函数名统一使用 `snake_case`。
- 布尔变量使用可读前缀：`is_`、`has_`、`can_`、`should_`。
- 私有辅助函数以 `_` 开头。

示例：

- `move_speed`
- `is_dead`
- `can_attack`
- `_update_animation()`

### 4.5 常量、枚举、信号

- 常量使用 `UPPER_SNAKE_CASE`。
- 枚举类型名使用 `PascalCase`，枚举值使用 `UPPER_SNAKE_CASE`。
- 信号使用过去式或状态变化语义，统一 `snake_case`。

示例：

- `const MAX_SPEED := 240.0`
- `enum State { IDLE, MOVE, ATTACK }`
- `signal health_changed(current: int, max_value: int)`
- `signal died`

## 5. 场景设计规范

### 5.1 一个场景，一个核心职责

- `Player.tscn` 负责玩家实体。
- `EnemySlime.tscn` 负责单个敌人实体。
- `Stage01.tscn` 负责关卡布局与关卡逻辑。
- `MainHUD.tscn` 负责主界面显示。

不要让一个场景同时承担角色逻辑、UI 管理、关卡生成、音频控制等多个职责。

### 5.2 控制节点层级复杂度

- 节点层级深度应保持合理。
- 能独立复用的部分应拆成子场景。
- 不要为了“整理目录”而创建纯空壳节点。

### 5.3 根节点类型要合理

- 可移动角色优先使用 `CharacterBody2D`。
- 静态碰撞体优先使用 `StaticBody2D`。
- 区域检测优先使用 `Area2D`。
- 纯 UI 优先使用 `Control` 系列节点。

不要为了省事统一使用 `Node2D`。

### 5.4 场景依赖应稳定

- 子节点结构变化频繁时，不要在多个脚本中硬编码完整节点路径。
- 优先使用唯一名称节点、导出引用或封装访问函数。
- 禁止跨多层级频繁使用 `get_parent().get_parent()` 读取逻辑依赖。

## 6. GDScript 编码规范

### 6.1 脚本结构顺序

建议统一为以下顺序：

```gdscript
class_name PlayerController
extends CharacterBody2D

signal moved

enum State { IDLE, MOVE }

const MAX_SPEED := 240.0

@export var move_speed: float = 240.0

var state: State = State.IDLE

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    pass

func _physics_process(delta: float) -> void:
    pass

func move(input_vector: Vector2) -> void:
    pass

func _update_animation() -> void:
    pass
```

推荐顺序：

1. `class_name`
2. `extends`
3. `signal`
4. `enum`
5. `const`
6. `@export` 变量
7. 普通成员变量
8. `@onready` 变量
9. 生命周期函数
10. 公共方法
11. 私有方法

### 6.2 类型标注

- 公共方法参数和返回值必须显式标注类型。
- 导出变量必须标注类型。
- 关键成员变量必须标注类型。
- 只有在确实需要动态类型时才使用未标注变量。

示例：

```gdscript
@export var max_health: int = 100
var move_input: Vector2 = Vector2.ZERO

func take_damage(amount: int) -> void:
    current_health -= amount
```

### 6.3 函数长度与复杂度

- 单个函数建议不超过 40 行。
- 嵌套层级建议不超过 3 层。
- 条件分支过多时，拆成小函数或状态处理函数。

### 6.4 避免魔法数字

- 重复出现或具备业务意义的数值必须提取为常量或导出参数。
- 便于策划调参与测试验证。

反例：

```gdscript
velocity.x = direction * 237.5
```

正例：

```gdscript
const RUN_SPEED := 240.0
velocity.x = direction * RUN_SPEED
```

### 6.5 注释规范

- 注释解释“为什么”，不是重复“做了什么”。
- 复杂规则、边界条件、临时兼容逻辑必须加注释。
- 过期注释要及时删除。

### 6.6 空值与依赖检查

- 初始化阶段对关键依赖进行校验。
- 对可能为空的对象进行明确判断。
- 开发期可使用 `assert()` 提前暴露问题。

示例：

```gdscript
func _ready() -> void:
    assert(animation_player != null, "AnimationPlayer is required")
```

## 7. 节点引用规范

### 7.1 优先使用稳定引用方式

推荐顺序：

1. `@onready` 获取固定子节点
2. 唯一名称节点
3. `@export` 注入外部依赖
4. 明确封装的查找函数

### 7.2 禁止滥用动态查找

- 避免在 `_process()` 或 `_physics_process()` 中频繁 `get_node()`。
- 避免依赖字符串拼接路径查找节点。
- 避免跨场景直接操作深层子节点。

## 8. 信号与通信规范

### 8.1 子节点向外通知优先使用信号

- 攻击命中、血量变化、状态切换等事件优先通过信号抛出。
- 不要让子节点直接修改父节点的核心状态。

### 8.2 降低双向耦合

- A 不应同时直接控制 B，B 又直接控制 A。
- 如果双方都需要知道事件，优先通过信号或协调层中转。

### 8.3 谨慎使用全局事件总线

- 只有跨系统、跨场景的全局事件才适合放入 `autoload`。
- 禁止把普通局部通信都塞进全局单例。

适合全局事件的场景：

- 游戏暂停
- 关卡切换
- 全局音量变化
- 存档读档完成

## 9. 输入规范

### 9.1 所有输入必须走 Input Map

- 禁止在脚本中硬编码物理按键名称作为业务逻辑入口。
- 输入动作统一在项目设置中配置。

示例：

- `move_left`
- `move_right`
- `jump`
- `attack`
- `pause`

### 9.2 输入采集与行为执行分离

- 输入层负责“收集玩家意图”。
- 角色逻辑层负责“根据意图执行动作”。
- AI、回放、网络同步时可复用同一行为接口。

## 10. 物理与移动规范

### 10.1 物理逻辑写在 `_physics_process()`

- 移动、碰撞、速度修正、重力更新统一放在 `_physics_process()`。
- 纯视觉插值、界面刷新可放在 `_process()`。

### 10.2 统一速度语义

- `velocity` 表示当前速度。
- 加速度、摩擦力、击退力等额外因素要命名明确。
- 不要在多个函数中无约束地重复覆盖 `velocity`。

### 10.3 碰撞层规范

- 项目开始阶段就定义碰撞层与掩码表。
- 玩家、敌人、子弹、可交互物、地形、触发区分别规划。
- 不允许开发过程中随意复用未知层位。

## 11. 状态机规范

### 11.1 角色行为复杂时必须引入状态管理

以下场景建议使用状态机：

- 玩家存在待机、移动、跳跃、受击、攻击等多状态切换
- 敌人存在巡逻、追击、攻击、返回、死亡等逻辑
- Boss 存在阶段切换与技能循环

### 11.2 状态切换要集中管理

- 状态切换入口应统一。
- 禁止在多个脚本中随意直接改状态变量。
- 状态切换时要明确进入、更新、退出行为。

## 12. 数据与配置规范

### 12.1 配置优先资源化

以下内容优先使用 `Resource` 或配置表：

- 角色基础属性
- 武器参数
- 技能冷却
- 敌人掉落
- 关卡波次数据

### 12.2 存档数据与运行时状态分离

- 存档对象只保存需要持久化的数据。
- 运行时缓存、节点引用、临时状态不写入存档结构。

## 13. UI 开发规范

### 13.1 UI 与游戏实体逻辑分离

- UI 只负责显示与交互反馈。
- 不在 UI 脚本里直接编排核心战斗逻辑。
- UI 通过信号、接口或数据绑定读取状态。

### 13.2 文本与样式集中管理

- 可复用文本优先国际化。
- UI 主题、字体、颜色、间距应集中管理。
- 禁止在多个界面脚本中散落重复样式参数。

## 14. 资源规范

### 14.1 资源命名清晰

- 纹理、音频、动画、材质、配置资源统一使用语义化命名。
- 临时文件在提交前必须清理或重命名。

示例：

- `player_idle.png`
- `slime_attack.anim`
- `ui_button_click.wav`
- `enemy_stats_slime.tres`

### 14.2 不提交无效资源

- 未使用的测试图、旧版本资源、重复导出文件不要保留在主分支。
- 大体积资源变更要说明来源和用途。

## 15. Autoload 规范

### 15.1 Autoload 只做全局职责

适合放入 Autoload 的内容：

- `GameManager`
- `AudioManager`
- `SceneLoader`
- `SaveManager`
- `InputManager`

不适合放入 Autoload 的内容：

- 单个敌人的业务逻辑
- 具体 UI 页面控制
- 某一关卡独有逻辑

### 15.2 避免超级单例

- 不要把所有功能堆到一个 `Global.gd`。
- 单例职责必须明确、可维护、可替换。

## 16. 性能规范

### 16.1 避免每帧分配不必要对象

- 不在高频循环中创建临时数组、字典和字符串。
- 可复用的数据结构应提前缓存。

### 16.2 高频对象优先池化

以下对象建议对象池化：

- 子弹
- 飘字
- 命中特效
- 高频生成的小怪

### 16.3 优先事件驱动，减少轮询

- 能用信号触发的逻辑不要每帧检查。
- 能用 `Timer` 的延迟逻辑不要自己累加时间分支。

## 17. 调试与日志规范

### 17.1 日志要有上下文

- 输出日志时说明对象、行为、关键参数。
- 避免只打印 `error`、`failed` 这类无上下文信息。

### 17.2 错误分级处理

- 可恢复问题使用 `push_warning()`。
- 关键异常使用 `push_error()` 或断言。
- 发布前应清理调试噪声日志。

## 18. 提交前检查清单

每次提交前至少确认以下事项：

- 场景和脚本命名符合规范
- 未新增无意义目录层级
- 公共方法和关键变量已补类型
- 未出现魔法数字泛滥
- 输入动作未硬编码
- 跨节点通信未形成强耦合
- 可配置参数已导出或资源化
- 调试日志已清理
- 无废弃资源与临时文件
- 关键功能已完成自测

## 19. 推荐脚本模板

```gdscript
class_name HealthComponent
extends Node

signal health_changed(current: int, max_value: int)
signal died

@export var max_health: int = 100

var current_health: int = 0

func _ready() -> void:
    current_health = max_health

func reset() -> void:
    current_health = max_health
    health_changed.emit(current_health, max_health)

func take_damage(amount: int) -> void:
    if amount <= 0:
        return

    current_health = max(current_health - amount, 0)
    health_changed.emit(current_health, max_health)

    if current_health == 0:
        died.emit()
```

## 20. 禁止事项

以下写法原则上禁止进入主分支：

- 在脚本中硬编码输入按键
- 大量依赖 `get_parent()` 进行业务通信
- 在 `_process()` 中反复 `get_node()`
- 把关卡逻辑、角色逻辑、UI 逻辑塞进同一脚本
- 使用意义不明的变量名，如 `tmp`、`data2`、`aaa`
- 不做类型标注的核心业务代码
- 在多个脚本中复制粘贴相同逻辑而不抽取
- 将临时测试资源直接提交为正式资源

## 21. 结语

规范的目的不是限制开发速度，而是减少返工、降低沟通成本，并让项目在迭代变复杂之后仍然可维护。

当规范与实际需求冲突时，优先保证：

1. 功能正确
2. 结构清晰
3. 易于协作
4. 便于后续扩展

如需偏离本规范，应在代码评审或文档中说明原因。
