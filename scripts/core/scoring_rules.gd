class_name ScoringRules
extends RefCounted


static func calculate_score(category: String, values: Array) -> int:
	match category:
		"Ones":
			return _sum_of_number(values, 1)
		"Twos":
			return _sum_of_number(values, 2)
		"Threes":
			return _sum_of_number(values, 3)
		"Fours":
			return _sum_of_number(values, 4)
		"Fives":
			return _sum_of_number(values, 5)
		"Sixes":
			return _sum_of_number(values, 6)
		"Three of a Kind":
			return _sum(values) if _has_n_of_a_kind(values, 3) else 0
		"Four of a Kind":
			return _sum(values) if _has_n_of_a_kind(values, 4) else 0
		"Full House":
			return 25 if _is_full_house(values) else 0
		"Small Straight":
			return 30 if _is_small_straight(values) else 0
		"Large Straight":
			return 40 if _is_large_straight(values) else 0
		"Yahtzee":
			return 50 if _has_n_of_a_kind(values, 5) else 0
		"Chance":
			return _sum(values)
		_:
			return 0


static func _sum(values: Array) -> int:
	var total := 0
	for v in values:
		total += int(v)
	return total


static func _sum_of_number(values: Array, target: int) -> int:
	var total := 0
	for v in values:
		if int(v) == target:
			total += int(v)
	return total


static func _build_counts(values: Array) -> Dictionary:
	var counts := {}
	for v in values:
		var value := int(v)
		if not counts.has(value):
			counts[value] = 0
		counts[value] += 1
	return counts


static func _has_n_of_a_kind(values: Array, n: int) -> bool:
	var counts := _build_counts(values)
	for key in counts.keys():
		if counts[key] >= n:
			return true
	return false


static func _is_full_house(values: Array) -> bool:
	var counts := _build_counts(values)
	if counts.size() != 2:
		return false
	var has_three := false
	var has_two := false
	for key in counts.keys():
		if counts[key] == 3:
			has_three = true
		elif counts[key] == 2:
			has_two = true
	return has_three and has_two


static func _is_small_straight(values: Array) -> bool:
	var uniques := {}
	for v in values:
		uniques[int(v)] = true
	var present := uniques.keys()
	return (
		(1 in present and 2 in present and 3 in present and 4 in present) or
		(2 in present and 3 in present and 4 in present and 5 in present) or
		(3 in present and 4 in present and 5 in present and 6 in present)
	)


static func _is_large_straight(values: Array) -> bool:
	var uniques := {}
	for v in values:
		uniques[int(v)] = true
	if uniques.size() != 5:
		return false
	var present := uniques.keys()
	return (
		(1 in present and 2 in present and 3 in present and 4 in present and 5 in present) or
		(2 in present and 3 in present and 4 in present and 5 in present and 6 in present)
	)
