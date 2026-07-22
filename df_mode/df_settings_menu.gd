extends Control
class_name DFSettingsMenu

var panel: Panel
var title_lbl: Label
var controls_lbl: Label
var tutorial_btn: Button
var close_btn: Button

signal tutorial_requested
signal close_requested

func _init() -> void:
	name = "SettingsMenu"
	visible = false
	
	panel = Panel.new()
	panel.anchor_left = 0.2
	panel.anchor_top = 0.2
	panel.anchor_right = 0.8
	panel.anchor_bottom = 0.8
	add_child(panel)
	
	title_lbl = Label.new()
	title_lbl.text = "Ajustes y Controles"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.position = Vector2(0, 20)
	title_lbl.anchor_right = 1.0
	panel.add_child(title_lbl)
	
	controls_lbl = Label.new()
	controls_lbl.text = """
Controles:
  Flechas: Mover Cámara (Modo Dios)
  W, A, S, D: Mover al aldeano poseído
  F: Seguir al aldeano (30 segs = Poseer)
  L: Salir de posesión / Volver a poseer
  1: Excavar / 2: Talar / 3: Muro / 4: Suelo
  5: Escalera Arriba / 6: Escalera Abajo
  ESPACIO: Pausar/Reanudar
"""
	controls_lbl.position = Vector2(40, 60)
	controls_lbl.anchor_right = 1.0
	panel.add_child(controls_lbl)
	
	tutorial_btn = Button.new()
	tutorial_btn.text = "Jugar Tutorial"
	tutorial_btn.position = Vector2(40, 250)
	tutorial_btn.size = Vector2(200, 40)
	tutorial_btn.pressed.connect(func(): tutorial_requested.emit())
	panel.add_child(tutorial_btn)
	
	close_btn = Button.new()
	close_btn.text = "Cerrar"
	close_btn.position = Vector2(260, 250)
	close_btn.size = Vector2(200, 40)
	close_btn.pressed.connect(func(): close_requested.emit())
	panel.add_child(close_btn)
