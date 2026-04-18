extends CanvasLayer

var menu_ui
var options_ui
var game_panel


func _ready():
	menu_ui = $Menu
	options_ui = $Options
	game_panel = $GamePanel


func clear_ui():
	hide_menu()
	hide_options()
	hide_game_panel()
	
	
func hide_menu():
	menu_ui.visible = false
	
func hide_options():
	options_ui.visible = false
	
func hide_game_panel():
	game_panel.visible = false

func show_menu():
	menu_ui.visible = true
	
func show_options():
	options_ui.visible = true
	
func show_game_panel():
	game_panel.visible = true
