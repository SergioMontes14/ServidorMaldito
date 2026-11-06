extends Control
# Portada (JUGAR / COMO JUGAR / SALIR) + evaluacion (trivia) inicial y final.

const TriviaData = preload("res://scripts/trivia_data.gd")
const PORTADA = preload("res://assets/ui/portada.jpg")
const CYAN = Color(0.0, 0.85, 0.95)
const YELLOW = Color(1.0, 0.85, 0.4)
const GRAY = Color(0.6, 0.65, 0.7)

# Botones dibujados en la imagen de portada (en pixeles de la imagen): x, y, ancho, alto
const BUTTON_RECTS = [
	Rect2(352, 293, 320, 52),
	Rect2(352, 360, 320, 51),
	Rect2(352, 426, 320, 51),
]

var phase = "title"
var question_index = 0
var answers = []
var options_order = []
var box = null
var portada = null
var title_ui = null
var play_button = null


func _ready():
	var bg = ColorRect.new()
	bg.color = Color(0.043, 0.071, 0.125)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	portada = TextureRect.new()
	portada.texture = PORTADA
	portada.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portada.stretch_mode = TextureRect.STRETCH_SCALE
	portada.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(portada)
	portada.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	title_ui = Control.new()
	add_child(title_ui)
	title_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_title_buttons()

	box = VBoxContainer.new()
	box.position = Vector2(30, 14)
	box.custom_minimum_size = Vector2(580, 0)
	box.add_theme_constant_override("separation", 5)
	add_child(box)

	Sound.play_music("menu")
	if Game.trivia_mode == "final":
		show_final_intro()
	else:
		Game.trivia_mode = ""
		show_title()


func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var enter = event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER
	if phase == "howto" and (enter or event.keycode == KEY_ESCAPE):
		show_title()
	elif phase == "initial_done" and enter:
		start_game()
	elif phase == "final_intro" and enter:
		begin_round()
	elif phase == "results" and enter:
		show_review()
	elif phase == "review" and enter:
		go_menu()
	elif phase == "question":
		var n = event.keycode - KEY_1
		if n >= 0 and n < 4:
			answer_chosen(n)


# ---------- utilidades de interfaz ----------
func clear_box():
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func set_title_visible(v):
	portada.visible = v
	title_ui.visible = v
	box.visible = not v


func add_label(text, size = 14, color = Color.WHITE, align = HORIZONTAL_ALIGNMENT_LEFT):
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(580, 0)
	l.horizontal_alignment = align
	box.add_child(l)
	return l


func add_spacer(height):
	var c = Control.new()
	c.custom_minimum_size = Vector2(0, height)
	box.add_child(c)


func add_button(text, callback):
	var b = Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 12)
	b.custom_minimum_size = Vector2(580, 30)
	b.pressed.connect(callback)
	box.add_child(b)
	return b


# ---------- portada ----------
func make_style(bg_color, border_color):
	var s = StyleBoxFlat.new()
	s.bg_color = bg_color
	s.set_border_width_all(2)
	s.border_color = border_color
	s.set_corner_radius_all(2)
	return s


func make_title_button(text, rect, callback):
	var tex_size = PORTADA.get_size()
	var sx = 640.0 / tex_size.x
	var sy = 352.0 / tex_size.y
	var b = Button.new()
	b.text = text
	b.position = Vector2((rect.position.x - 3) * sx, (rect.position.y - 3) * sy)
	b.size = Vector2((rect.size.x + 6) * sx, (rect.size.y + 6) * sy)
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", Color(0.82, 0.86, 0.93))
	b.add_theme_color_override("font_focus_color", Color(1.0, 0.95, 0.7))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.7))
	b.add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.7))
	var normal = make_style(Color(0.20, 0.22, 0.31), Color(0.55, 0.60, 0.75))
	var selected = make_style(Color(0.07, 0.06, 0.10), Color(1.0, 0.93, 0.65))
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", selected)
	b.add_theme_stylebox_override("focus", selected)
	b.add_theme_stylebox_override("pressed", selected)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_entered.connect(b.grab_focus)
	b.pressed.connect(callback)
	title_ui.add_child(b)
	return b


func build_title_buttons():
	play_button = make_title_button("JUGAR", BUTTON_RECTS[0], start_initial)
	make_title_button("CÓMO JUGAR", BUTTON_RECTS[1], show_howto)
	make_title_button("SALIR", BUTTON_RECTS[2], quit_game)


func show_title():
	phase = "title"
	clear_box()
	set_title_visible(true)
	play_button.grab_focus()


func quit_game():
	Sound.play("ui_select")
	get_tree().quit()


func show_howto():
	Sound.play("ui_select")
	phase = "howto"
	set_title_visible(false)
	clear_box()
	add_label("CÓMO JUGAR", 22, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	add_spacer(2)
	add_label("CONTROLES", 13, YELLOW)
	add_label("Mover: W A S D o flechas        Disparar: J, Espacio o clic izquierdo\nUsar vial de código: E o Q        Reiniciar nivel: R        Música: M", 12)
	add_spacer(2)
	add_label("OBJETIVO", 13, YELLOW)
	add_label("En cada nivel derrota al virus élite (más grande que los demás) para obtener la llave criptográfica y abre el terminal brillante. En el nivel 4 enfrenta al Glitch Final.", 12)
	add_spacer(2)
	add_label("OBJETOS", 13, YELLOW)
	add_label("Corazón: cura 1 vida.   Vial verde: se guarda (máx. 3) y cura 2 vidas con E.\nLlave USB: abre el terminal.   Disquete: disco de respaldo (hay 1 en los niveles 1 a 3); con los 3 se ensambla el Antivirus Definitivo y tus disparos hacen doble daño.   CD: Overclock, disparo rápido 10 s.", 12)
	add_spacer(2)
	add_label("CONSEJOS", 13, YELLOW)
	add_label("Los bloques del mapa sirven para cubrirte de los disparos. Presta atención a los virus que encuentres: al terminar los 4 niveles responderás de nuevo la evaluación.", 12)
	add_spacer(6)
	add_button("Volver  (ENTER o ESC)", show_title)


# ---------- evaluacion ----------
func start_initial():
	Sound.play("ui_select")
	Game.trivia_mode = "initial"
	begin_round()


func begin_round():
	Sound.play("ui_select")
	question_index = 0
	answers = []
	show_question()


func show_question():
	phase = "question"
	set_title_visible(false)
	clear_box()
	var q = TriviaData.QUESTIONS[question_index]
	var title = "EVALUACIÓN INICIAL"
	if Game.trivia_mode == "final":
		title = "EVALUACIÓN FINAL"
	add_label("%s  -  Pregunta %d de %d" % [title, question_index + 1, TriviaData.QUESTIONS.size()], 12, CYAN)
	add_spacer(6)
	add_label(q["q"], 16)
	add_spacer(10)
	options_order = []
	for i in range(q["options"].size()):
		options_order.append(i)
	options_order.shuffle()
	for i in range(options_order.size()):
		add_button("%d)  %s" % [i + 1, q["options"][options_order[i]]], answer_chosen.bind(i))
	add_spacer(4)
	add_label("Responde con el mouse o con las teclas 1 a 4", 11, GRAY)


func answer_chosen(i):
	if phase != "question":
		return
	var q = TriviaData.QUESTIONS[question_index]
	answers.append(options_order[i] == q["answer"])
	Sound.play("ui_select")
	question_index += 1
	if question_index >= TriviaData.QUESTIONS.size():
		finish_round()
	else:
		show_question()


func finish_round():
	if Game.trivia_mode == "initial":
		Game.pre_answers = answers.duplicate()
		show_initial_done()
	else:
		Game.post_answers = answers.duplicate()
		save_results()
		show_results()


func show_initial_done():
	phase = "initial_done"
	clear_box()
	add_spacer(6)
	add_label("EVALUACIÓN INICIAL COMPLETADA", 20, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	add_spacer(6)
	add_label("Tus respuestas quedaron registradas. Al terminar los 4 niveles volverás a responder la evaluación y compararemos los resultados.", 13)
	add_spacer(6)
	add_label("CONTROLES", 13, YELLOW)
	add_label("Mover: W A S D o flechas     Disparar: J, Espacio o clic izquierdo\nUsar vial: E o Q     Reiniciar nivel: R     Música: M", 12)
	add_spacer(4)
	add_label("OBJETIVO", 13, YELLOW)
	add_label("En cada nivel derrota al virus élite para obtener la llave criptográfica y abre el terminal. Recoge los 3 discos de respaldo para ensamblar el Antivirus Definitivo. En el nivel 4 enfrenta al Glitch Final.", 12)
	add_spacer(8)
	add_button("¡A jugar!  (ENTER)", start_game)


func start_game():
	Sound.play("ui_select")
	Game.trivia_mode = "playing"
	Game.new_game()


func show_final_intro():
	phase = "final_intro"
	set_title_visible(false)
	clear_box()
	add_spacer(20)
	add_label("¡FELICIDADES!", 30, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	add_label("Has limpiado el servidor y derrotado al Glitch Final.", 14, Color(0.7, 0.8, 0.9), HORIZONTAL_ALIGNMENT_CENTER)
	add_spacer(12)
	add_label("Ahora responde de nuevo la evaluación de 7 preguntas. Si prestaste atención a los virus que enfrentaste, te será más fácil.", 14, YELLOW)
	add_spacer(12)
	add_button("Comenzar evaluación final  (ENTER)", begin_round)


func count_true(arr):
	var n = 0
	for a in arr:
		if a:
			n += 1
	return n


func show_results():
	phase = "results"
	Sound.play("victory")
	clear_box()
	var total = TriviaData.QUESTIONS.size()
	var pre = count_true(Game.pre_answers)
	var post = count_true(Game.post_answers)
	var diff = post - pre
	add_spacer(10)
	add_label("RESULTADOS DE LA EVALUACIÓN", 22, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	add_spacer(12)
	add_label("Evaluación inicial:   %d / %d" % [pre, total], 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	add_label("Evaluación final:   %d / %d" % [post, total], 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	add_spacer(8)
	var msg = "Tu resultado bajó. Revisa el repaso de respuestas."
	if diff > 0:
		msg = "¡Mejoraste %d respuesta(s)! Jugar te ayudó a aprender." % diff
	elif diff == 0 and post == total:
		msg = "¡Resultado perfecto! Ya dominabas el tema."
	elif diff == 0:
		msg = "Mantuviste tu resultado. Revisa el repaso de respuestas."
	add_label(msg, 15, YELLOW, HORIZONTAL_ALIGNMENT_CENTER)
	add_spacer(14)
	add_button("Ver repaso de respuestas  (ENTER)", show_review)
	add_spacer(4)
	add_label("Resultados guardados en: " + OS.get_user_data_dir() + "/resultados_trivia.csv", 9, GRAY)


func show_review():
	phase = "review"
	Sound.play("ui_select")
	clear_box()
	add_label("REPASO DE RESPUESTAS", 16, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(TriviaData.QUESTIONS.size()):
		var q = TriviaData.QUESTIONS[i]
		var pre_ok = "NO"
		var post_ok = "NO"
		if i < Game.pre_answers.size() and Game.pre_answers[i]:
			pre_ok = "SÍ"
		if i < Game.post_answers.size() and Game.post_answers[i]:
			post_ok = "SÍ"
		add_label("%d) %s   [inicial: %s | final: %s]\n     %s" % [i + 1, q["short"], pre_ok, post_ok, q["review"]], 11)
	add_spacer(6)
	add_button("Volver al menú  (ENTER)", go_menu)


func go_menu():
	Sound.play("ui_select")
	Game.reset_to_menu()


func save_results():
	var path = "user://resultados_trivia.csv"
	var exists = FileAccess.file_exists(path)
	var mode = FileAccess.WRITE
	if exists:
		mode = FileAccess.READ_WRITE
	var f = FileAccess.open(path, mode)
	if f == null:
		return
	f.seek_end()
	var total = TriviaData.QUESTIONS.size()
	if not exists:
		var header = "fecha,inicial,final,mejora"
		for i in range(total):
			header += ",ini_p%d" % (i + 1)
		for i in range(total):
			header += ",fin_p%d" % (i + 1)
		f.store_line(header)
	var pre = count_true(Game.pre_answers)
	var post = count_true(Game.post_answers)
	var line = "%s,%d,%d,%d" % [Time.get_datetime_string_from_system(), pre, post, post - pre]
	for i in range(total):
		line += ",%d" % (1 if i < Game.pre_answers.size() and Game.pre_answers[i] else 0)
	for i in range(total):
		line += ",%d" % (1 if i < Game.post_answers.size() and Game.post_answers[i] else 0)
	f.store_line(line)
	f.close()
