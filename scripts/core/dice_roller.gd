class_name DiceRoller
extends RefCounted


static func roll_die() -> int:
	return randi_range(1, 6)


static func roll_indices(current_values: Array, indices_to_roll: Array) -> Array:
	var new_values: Array = current_values.duplicate()
	for index in indices_to_roll:
		new_values[int(index)] = roll_die()
	return new_values
