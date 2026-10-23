class_name GameOver
extends CanvasLayer

signal next_round_pressed
signal restart_pressed
signal menu_pressed

@onready var banner_label: Label = $Panel/VBox/BannerLabel
@onready var next_round_btn: Button = $Panel/VBox/NextRoundButton
@onready var restart_btn: Button = $Panel/VBox/RestartButton
@onready var menu_btn: Button = $Panel/VBox/MenuButton

func _ready() -> void:
	visible = false
	next_round_btn.pressed.connect(func(): next_round_pressed.emit())
	restart_btn.pressed.connect(func(): restart_pressed.emit())
	menu_btn.pressed.connect(func(): menu_pressed.emit())

func show_winner(winner_name: String, winner_color: Color, next_level: int = -1) -> void:
	banner_label.text = "%s WINS!" % winner_name.to_upper()
	banner_label.modulate = winner_color
	if next_level > 0:
		next_round_btn.text = "NEXT LEVEL (%d)" % next_level
	else:
		next_round_btn.text = "NEXT ROUND"
	visible = true
