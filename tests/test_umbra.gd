extends GutTest

const UMBRA := preload("res://scenes/Umbra.tscn")


func _spawn(field: LightField, cell: Vector2i) -> Umbra:
	var umbra: Umbra = UMBRA.instantiate()
	add_child_autofree(umbra)
	umbra.bind_field(field, 16)
	umbra.global_position = umbra.cell_to_world(cell)
	umbra.input_enabled = false
	return umbra


func test_reports_the_cell_it_stands_in() -> void:
	var field := LightField.new(20, 20)
	var umbra := _spawn(field, Vector2i(4, 6))
	assert_eq(umbra.current_cell(), Vector2i(4, 6))


func test_reads_glare_from_the_field() -> void:
	var field := LightField.new(20, 20)
	field.emit("lamp", Vector2i(4, 6), 4.0, 1.0)
	var umbra := _spawn(field, Vector2i(4, 6))
	assert_almost_eq(umbra.glare(), 1.0, 0.001)
	umbra.global_position = umbra.cell_to_world(Vector2i(15, 15))
	assert_eq(umbra.glare(), 0.0)
	assert_true(umbra.in_deep_shade())


func test_standing_in_a_beam_scatters_her() -> void:
	var field := LightField.new(20, 20)
	field.emit("lamp", Vector2i(4, 6), 4.0, 1.0)
	var umbra := _spawn(field, Vector2i(4, 6))
	watch_signals(umbra)
	for i in 40:
		umbra._physics_process(0.1)
	assert_signal_emitted(umbra, "scattered_at")


func test_scattering_reforms_her_in_reachable_shade() -> void:
	var field := LightField.new(20, 20)
	field.set_ambient(1.0)
	field.set_ambient_at(Vector2i(9, 6), 0.0)
	var umbra := _spawn(field, Vector2i(4, 6))
	for i in 60:
		umbra._physics_process(0.1)
	assert_false(umbra.state.is_scattered, "she comes back")
	assert_eq(umbra.current_cell(), Vector2i(9, 6), "at the only shade in the room")


func test_casting_announces_a_cell_and_spends_ink() -> void:
	var field := LightField.new(20, 20)
	var umbra := _spawn(field, Vector2i(3, 3))
	watch_signals(umbra)
	assert_true(umbra.try_cast())
	assert_signal_emitted_with_parameters(umbra, "cast_requested", [Vector2i(3, 3)])
	assert_eq(umbra.state.ink_charges(), 2)


func test_casting_fails_when_out_of_ink() -> void:
	var field := LightField.new(20, 20)
	var umbra := _spawn(field, Vector2i(3, 3))
	for i in 3:
		umbra.try_cast()
	assert_false(umbra.try_cast(), "no ink, no puff")


func test_scattered_umbra_stops_dead() -> void:
	var field := LightField.new(20, 20)
	var umbra := _spawn(field, Vector2i(3, 3))
	umbra.velocity = Vector2(50, 50)
	umbra.state.scatter()
	umbra._physics_process(0.1)
	assert_eq(umbra.velocity, Vector2.ZERO)
