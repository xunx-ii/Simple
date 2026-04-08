class_name UITexts
extends RefCounted

const CLOSE := "关闭"
const SETTINGS := "设置"
const INPUT_SETTINGS := "输入设置"

const MAIN_MENU_SUBTITLE := "主菜单"
const MAIN_MENU_START := "开始游戏"
const MAIN_MENU_ABOUT := "关于游戏"
const MAIN_MENU_NOTICE_TITLE := "健康游戏提示"
const MAIN_MENU_AGREEMENT_PREFIX := "我已阅读并同意"
const MAIN_MENU_AGREEMENT_CONNECTOR := "/"
const MAIN_MENU_SERVICE_AGREEMENT := "服务协议"
const MAIN_MENU_PRIVACY_AGREEMENT := "隐私协议"
const MAIN_MENU_AGREEMENT_TITLE := "提示"
const MAIN_MENU_AGREEMENT_PROMPT := "是否同意服务和隐私协议？"
const MAIN_MENU_CONFIRM_YES := "是"
const MAIN_MENU_CONFIRM_NO := "否"

const LOBBY_PLAYER_TITLE := "玩家名字"
const LOBBY_GOLD_TITLE := "金币"
const TASK_PANEL_TITLE := "任务列表"
const TASK_TOGGLE_COLLAPSE := "收起任务"
const TASK_TOGGLE_LIST := "任务列表"
const TASK_READY_TO_COMPLETE := "可提交"
const LOBBY_SETTINGS_BODY := "可在此打开移动端输入设置，调整战斗场景中的虚拟摇杆与瞄准按钮。"
const INPUT_SETTINGS_SUBTITLE := "战斗缩影会实时预览摇杆和瞄准按钮的布局。"
const INPUT_SETTINGS_PREVIEW_TITLE := "战斗缩影"
const INPUT_SETTINGS_JOYSTICK_SECTION := "虚拟摇杆"
const INPUT_SETTINGS_AIM_BUTTON_SECTION := "瞄准按钮"
const INPUT_SETTINGS_LEFT_MARGIN := "左边距"
const INPUT_SETTINGS_RIGHT_MARGIN := "右边距"
const INPUT_SETTINGS_BOTTOM_MARGIN := "底边距"
const INPUT_SETTINGS_SIZE := "尺寸"
const INPUT_SETTINGS_HINT := "拖动滑块后会立即保存，下次进入战斗场景会自动应用。"
const RESET_DEFAULT := "恢复默认"
const DONE := "完成"


static func main_menu_notice_text() -> String:
	return (
		"抵制不良游戏，拒绝盗版游戏。\n"
		+ "注意自我保护，谨防受骗上当。\n"
		+ "适度游戏益脑，沉迷游戏伤身。\n"
		+ "合理安排时间，享受健康生活。"
	)


static func main_menu_about_body() -> String:
	return (
		"《Simple》当前提供主菜单与大厅界面原型，\n"
		+ "后续可以继续接入战斗、商店和角色成长流程。"
	)


static func task_toggle_button_text(is_panel_visible: bool, ready_count: int, pending_count: int) -> String:
	var base_label := TASK_TOGGLE_COLLAPSE if is_panel_visible else TASK_TOGGLE_LIST
	if ready_count > 0:
		return "%s (%d %s)" % [base_label, ready_count, TASK_READY_TO_COMPLETE]
	if pending_count > 0:
		return "%s (%d)" % [base_label, pending_count]
	return base_label
