class_name UIController
extends CanvasLayer

signal quit_requested
signal return_to_lobby_requested
signal shop_purchase_requested(item_id: String)
signal shop_sell_requested(item_id: String)
signal shop_closed

const DASH_READY_TEXT := "冲刺就绪"
const ACTIVE_STATE_TEMPLATE := "Tab 背包  Esc 菜单"
const GAME_OVER_TEXT := "作战失败"
const GAME_OVER_HINT_TEXT := "任务进度与背包物资已丢失，正在返回大厅..."
const DEFAULT_EMPTY_INVENTORY_TEXT := "空"
const DEFAULT_EMPTY_INVENTORY_HINT := ""

var game_over: bool = false
var player: Node2D = null
var current_hud_state: Dictionary = {}
var current_shop_state: Dictionary = {}
var return_to_lobby_button: Button = null

@onready var fog_overlay: ColorRect = $FogOverlay
@onready var score_label: Label = $ScoreLabel
@onready var state_label: Label = $StateLabel
@onready var restart_label: Label = $RestartLabel
@onready var wave_label: Label = $WaveLabel
@onready var dash_label: Label = $DashLabel
@onready var dash_bar_fill: ColorRect = $DashBarFill
@onready var banner_label: Label = $BannerLabel
@onready var gold_label: Label = $GoldLabel
@onready var inventory_label: Label = $InventoryLabel
@onready var inventory_overlay: Control = $InventoryOverlay
@onready var inventory_summary_label: Label = $InventoryOverlay/InventoryPanel/InventoryLayout/InventorySummaryLabel
@onready var inventory_items_container: VBoxContainer = $InventoryOverlay/InventoryPanel/InventoryLayout/InventoryScroll/InventoryItems
@onready var interaction_label: Label = $InteractionLabel
@onready var shop_overlay: Control = $ShopOverlay
@onready var shop_title_label: Label = $ShopOverlay/ShopPanel/ShopLayout/ShopTitleLabel
@onready var shop_info_label: Label = $ShopOverlay/ShopPanel/ShopLayout/ShopInfoLabel
@onready var shop_bag_items_container: VBoxContainer = $ShopOverlay/ShopPanel/ShopLayout/ShopColumns/BagSection/BagScroll/BagItems
@onready var shop_stock_items_container: VBoxContainer = $ShopOverlay/ShopPanel/ShopLayout/ShopColumns/StockSection/StockScroll/StockItems
@onready var shop_close_button: Button = $ShopOverlay/ShopPanel/ShopLayout/ShopCloseButton
@onready var pause_overlay: Control = $PauseOverlay
@onready var pause_panel: Panel = $PauseOverlay/PausePanel
@onready var pause_buttons: VBoxContainer = $PauseOverlay/PausePanel/PauseButtons
@onready var continue_button: Button = $PauseOverlay/PausePanel/PauseButtons/ContinueButton
@onready var quit_button: Button = $PauseOverlay/PausePanel/PauseButtons/QuitButton
@onready var damage_indicators: Node2D = $DamageIndicators
@onready var crosshair: Node2D = $Crosshair
@onready var mobile_controls = $MobileControls


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_process_modes()
	_setup_pause_menu_buttons()
	continue_button.pressed.connect(_on_continue_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	shop_close_button.pressed.connect(_on_shop_close_button_pressed)

	if mobile_controls.has_signal("move_vector_changed"):
		mobile_controls.move_vector_changed.connect(_on_mobile_move_vector_changed)
	if mobile_controls.has_signal("shoot_requested"):
		mobile_controls.shoot_requested.connect(_on_mobile_shoot_requested)
	if mobile_controls.has_signal("aim_mode_toggled"):
		mobile_controls.aim_mode_toggled.connect(_on_mobile_aim_mode_toggled)

	set_pause_menu_visible(false)
	set_inventory_visible(false)
	_set_shop_menu_visible_state(false)
	inventory_summary_label.visible = false
	_rebuild_inventory_list(inventory_items_container, [])
	_rebuild_shop_bag_list([])
	_rebuild_shop_stock_list([])
	_refresh_mobile_controls_state()


func _process(_delta: float) -> void:
	if game_over:
		return

	if shop_overlay.visible:
		if Input.is_action_just_pressed("ui_cancel"):
			close_shop_menu()
		return

	if Input.is_action_just_pressed("inventory") and not pause_overlay.visible:
		set_inventory_visible(not inventory_overlay.visible)
		return

	if Input.is_action_just_pressed("ui_cancel"):
		if inventory_overlay.visible:
			set_inventory_visible(false)
			return

		set_pause_menu_visible(not pause_overlay.visible)


func setup(player_node: Node2D) -> void:
	player = player_node

	if fog_overlay != null and fog_overlay.has_method("setup"):
		fog_overlay.setup(player)

	if damage_indicators != null and damage_indicators.has_method("setup"):
		damage_indicators.setup(player)

	if crosshair != null and crosshair.has_method("setup"):
		crosshair.setup(player)

	_refresh_mobile_controls_state()


func apply_hud(state: Dictionary) -> void:
	var normalized_state := {
		"health": int(state.get("health", 0)),
		"score": int(state.get("score", 0)),
		"gold": int(state.get("gold", 0)),
		"wave": int(state.get("wave", 0)),
		"dash_ready": bool(state.get("dash_ready", false)),
		"dash_cooldown": float(state.get("dash_cooldown", 0.0)),
		"dash_ratio": float(state.get("dash_ratio", 0.0)),
		"weapon_name": str(state.get("weapon_name", "徒手")),
		"inventory_summary_text": str(state.get("inventory_summary_text", "背包 0/0")),
		"inventory_items": _sanitize_entry_list(state.get("inventory_items", [])),
		"interaction_text": str(state.get("interaction_text", "")),
		"banner_text": str(state.get("banner_text", "")),
		"game_over": bool(state.get("game_over", false))
	}

	if current_hud_state == normalized_state:
		return

	current_hud_state = normalized_state
	var next_game_over: bool = normalized_state["game_over"]
	if next_game_over and not game_over:
		set_pause_menu_visible(false)
		if shop_overlay.visible:
			_set_shop_menu_visible_state(false)
			current_shop_state.clear()

	game_over = next_game_over
	score_label.text = "生命 %d  积分 %d" % [normalized_state["health"], normalized_state["score"]]
	gold_label.text = "金币 %d" % normalized_state["gold"]
	wave_label.text = "第 %d 波" % normalized_state["wave"]
	banner_label.text = normalized_state["banner_text"]
	inventory_label.text = normalized_state["inventory_summary_text"]
	inventory_summary_label.text = normalized_state["inventory_summary_text"]
	_rebuild_inventory_list(inventory_items_container, normalized_state["inventory_items"])
	_refresh_interaction_prompt()

	var dash_ready: bool = normalized_state["dash_ready"]
	var dash_ratio: float = normalized_state["dash_ratio"]
	dash_label.text = DASH_READY_TEXT if dash_ready else "冲刺 %.1f" % normalized_state["dash_cooldown"]
	dash_bar_fill.size.x = 72.0 * dash_ratio
	dash_bar_fill.color = Color(0.35, 0.87, 1.0, 1.0) if dash_ready else Color(0.31, 0.67, 0.96, 1.0)

	restart_label.visible = game_over
	if game_over:
		set_inventory_visible(false)
		interaction_label.visible = false
		state_label.text = GAME_OVER_TEXT
		_refresh_mobile_controls_state()
		return

	state_label.text = ACTIVE_STATE_TEMPLATE
	_refresh_mobile_controls_state()


func open_shop(shop_state: Dictionary) -> void:
	set_inventory_visible(false)
	apply_shop_state(shop_state)
	_set_shop_menu_visible_state(true)


func apply_shop_state(shop_state: Dictionary) -> void:
	current_shop_state = {
		"title": str(shop_state.get("title", "商店")),
		"gold": int(shop_state.get("gold", 0)),
		"bag_summary": str(shop_state.get("bag_summary", "背包 0/0")),
		"items": _sanitize_entry_list(shop_state.get("items", [])),
		"inventory_items": _sanitize_entry_list(shop_state.get("inventory_items", []))
	}
	shop_title_label.text = str(current_shop_state.get("title", "商店"))
	shop_info_label.text = "金币：%d" % int(current_shop_state.get("gold", 0))
	var inventory_items: Array = current_shop_state.get("inventory_items", [])
	var stock_items: Array = current_shop_state.get("items", [])
	_rebuild_shop_bag_list(inventory_items)
	_rebuild_shop_stock_list(stock_items)


func is_shop_open() -> bool:
	return shop_overlay.visible


func close_shop_menu() -> void:
	if not shop_overlay.visible:
		return

	_set_shop_menu_visible_state(false)
	current_shop_state.clear()
	shop_closed.emit()


func set_pause_menu_visible(menu_open: bool) -> void:
	if menu_open:
		set_inventory_visible(false)
		if shop_overlay.visible:
			close_shop_menu()

	pause_overlay.visible = menu_open
	_refresh_modal_state()
	_refresh_interaction_prompt()


func set_inventory_visible(menu_open: bool) -> void:
	if menu_open and shop_overlay.visible:
		close_shop_menu()

	inventory_overlay.visible = menu_open
	_refresh_interaction_prompt()
	_refresh_mobile_controls_state()


func close_pause_menu() -> void:
	set_pause_menu_visible(false)


func _configure_process_modes() -> void:
	fog_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	damage_indicators.process_mode = Node.PROCESS_MODE_ALWAYS
	crosshair.process_mode = Node.PROCESS_MODE_ALWAYS
	mobile_controls.process_mode = Node.PROCESS_MODE_ALWAYS
	inventory_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	inventory_items_container.process_mode = Node.PROCESS_MODE_ALWAYS
	shop_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	shop_bag_items_container.process_mode = Node.PROCESS_MODE_ALWAYS
	shop_stock_items_container.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	shop_close_button.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_buttons.process_mode = Node.PROCESS_MODE_ALWAYS
	continue_button.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_button.process_mode = Node.PROCESS_MODE_ALWAYS


func _set_shop_menu_visible_state(menu_open: bool) -> void:
	shop_overlay.visible = menu_open
	_refresh_modal_state()
	_refresh_interaction_prompt()


func _refresh_modal_state() -> void:
	var modal_open: bool = pause_overlay.visible or shop_overlay.visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if modal_open else Input.MOUSE_MODE_CONFINED_HIDDEN
	var tree := get_tree()
	if tree != null:
		tree.paused = modal_open
	_refresh_mobile_controls_state()


func _on_continue_button_pressed() -> void:
	set_pause_menu_visible(false)


func _on_return_to_lobby_button_pressed() -> void:
	set_pause_menu_visible(false)
	return_to_lobby_requested.emit()


func _on_quit_button_pressed() -> void:
	quit_requested.emit()


func _on_shop_buy_button_pressed(item_id: String) -> void:
	shop_purchase_requested.emit(item_id)


func _on_shop_sell_button_pressed(item_id: String) -> void:
	shop_sell_requested.emit(item_id)


func _on_shop_close_button_pressed() -> void:
	close_shop_menu()


func _sanitize_entry_list(entries_variant: Variant) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if entries_variant is Array:
		for entry_variant in entries_variant:
			if entry_variant is Dictionary:
				var entry: Dictionary = entry_variant
				entries.append(entry.duplicate(true))

	return entries


func _rebuild_inventory_list(container: VBoxContainer, items: Array) -> void:
	_clear_container(container)
	if items.is_empty():
		_add_empty_list_label(container, DEFAULT_EMPTY_INVENTORY_TEXT, DEFAULT_EMPTY_INVENTORY_HINT)
		return

	for item in items:
		var quantity: int = int(item.get("quantity", 0))
		_add_list_row(container, "%s  x%d" % [item.get("display_name", "物品"), quantity])


func _rebuild_shop_bag_list(items: Array) -> void:
	_clear_container(shop_bag_items_container)
	if items.is_empty():
		_add_empty_list_label(shop_bag_items_container, "背包为空", "")
		return

	for item in items:
		var item_id: String = str(item.get("id", ""))
		var quantity: int = int(item.get("quantity", 0))
		var sell_value: int = int(item.get("sell_value", 0))
		_add_list_row(
			shop_bag_items_container,
			"%s  x%d  %d金币" % [item.get("display_name", "物品"), quantity, sell_value],
			"卖出",
			item_id,
			_on_shop_sell_button_pressed,
			not item_id.is_empty() and quantity > 0
		)


func _rebuild_shop_stock_list(items: Array) -> void:
	_clear_container(shop_stock_items_container)
	if items.is_empty():
		_add_empty_list_label(shop_stock_items_container, "暂无商品", "")
		return

	for item in items:
		var item_id: String = str(item.get("id", ""))
		var price: int = int(item.get("price", 0))
		_add_list_row(
			shop_stock_items_container,
			"%s  %d金币" % [item.get("display_name", "物品"), price],
			"购买",
			item_id,
			_on_shop_buy_button_pressed,
			bool(item.get("can_afford", false)),
			str(item.get("description", ""))
		)


func _clear_container(container: VBoxContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _add_empty_list_label(container: VBoxContainer, message: String, detail: String) -> void:
	var label := Label.new()
	label.text = message if detail.is_empty() else "%s\n%s" % [message, detail]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_text_style(label)
	container.add_child(label)


func _add_list_row(
	container: VBoxContainer,
	label_text: String,
	button_text: String = "",
	item_id: String = "",
	callback: Callable = Callable(),
	is_enabled: bool = false,
	tooltip_text: String = ""
) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	container.add_child(row)

	var item_label := Label.new()
	item_label.text = label_text
	item_label.clip_text = true
	item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_text_style(item_label)
	row.add_child(item_label)

	if button_text.is_empty():
		return

	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(56.0, 24.0)
	button.disabled = not is_enabled
	button.tooltip_text = tooltip_text
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_text_style(button)
	if callback.is_valid() and not item_id.is_empty():
		button.pressed.connect(callback.bind(item_id))
	row.add_child(button)


func _apply_text_style(control: Control, font_size: int = 12) -> void:
	var ui_font: Font = score_label.get_theme_font("font")
	if ui_font != null:
		control.add_theme_font_override("font", ui_font)
	control.add_theme_font_size_override("font_size", font_size)


func _refresh_interaction_prompt() -> void:
	var interaction_text: String = str(current_hud_state.get("interaction_text", ""))
	interaction_label.text = interaction_text
	interaction_label.visible = (
		not interaction_text.is_empty()
		and not game_over
		and not inventory_overlay.visible
		and not shop_overlay.visible
		and not pause_overlay.visible
	)


func _on_mobile_move_vector_changed(move_vector: Vector2) -> void:
	if player != null and player.has_method("set_mobile_move_vector"):
		player.set_mobile_move_vector(move_vector)


func _on_mobile_shoot_requested(screen_position: Vector2) -> void:
	if player != null and player.has_method("request_mobile_shot"):
		player.request_mobile_shot(screen_position)


func _on_mobile_aim_mode_toggled(is_enabled: bool) -> void:
	if player != null and player.has_method("set_mobile_aim_enabled"):
		player.set_mobile_aim_enabled(is_enabled)


func _refresh_mobile_controls_state() -> void:
	if mobile_controls == null or not mobile_controls.has_method("set_controls_enabled"):
		return

	var should_enable := (
		not game_over
		and not pause_overlay.visible
		and not inventory_overlay.visible
		and not shop_overlay.visible
	)
	mobile_controls.set_controls_enabled(should_enable)


func _setup_pause_menu_buttons() -> void:
	pause_panel.offset_left = -96.0
	pause_panel.offset_top = -58.0
	pause_panel.offset_right = 96.0
	pause_panel.offset_bottom = 58.0
	continue_button.text = "继续"
	quit_button.text = "退出游戏"
	restart_label.text = GAME_OVER_HINT_TEXT

	if return_to_lobby_button == null:
		return_to_lobby_button = Button.new()
		return_to_lobby_button.name = "ReturnToLobbyButton"
		return_to_lobby_button.custom_minimum_size = Vector2(0.0, 24.0)
		return_to_lobby_button.flat = true
		return_to_lobby_button.process_mode = Node.PROCESS_MODE_ALWAYS
		pause_buttons.add_child(return_to_lobby_button)
		pause_buttons.move_child(return_to_lobby_button, 1)
		return_to_lobby_button.pressed.connect(_on_return_to_lobby_button_pressed)

	return_to_lobby_button.text = "返回大厅"
	_apply_text_style(return_to_lobby_button)
