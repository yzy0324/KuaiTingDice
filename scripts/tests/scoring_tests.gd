class_name ScoringTests
extends RefCounted


static func run() -> void:
	print("=== Scoring Tests Start ===")
	var pass_count := 0
	var fail_count := 0

	if _run_single_scoring_test("All ones yahtzee", "Yahtzee", [1, 1, 1, 1, 1], 50):
		pass_count += 1
	else:
		fail_count += 1
	if _run_single_scoring_test("All ones chance", "Chance", [1, 1, 1, 1, 1], 5):
		pass_count += 1
	else:
		fail_count += 1

	if _run_single_scoring_test("Three kind valid", "Three of a Kind", [2, 2, 2, 5, 6], 17):
		pass_count += 1
	else:
		fail_count += 1
	if _run_single_scoring_test("Four kind invalid", "Four of a Kind", [2, 2, 2, 5, 6], 0):
		pass_count += 1
	else:
		fail_count += 1

	if _run_single_scoring_test("Four kind valid", "Four of a Kind", [2, 2, 2, 2, 6], 14):
		pass_count += 1
	else:
		fail_count += 1
	if _run_single_scoring_test("Three kind with four", "Three of a Kind", [2, 2, 2, 2, 6], 14):
		pass_count += 1
	else:
		fail_count += 1

	if _run_single_scoring_test("Full house", "Full House", [3, 3, 3, 5, 5], 25):
		pass_count += 1
	else:
		fail_count += 1

	if _run_single_scoring_test("Small straight only", "Small Straight", [1, 2, 3, 4, 6], 30):
		pass_count += 1
	else:
		fail_count += 1
	if _run_single_scoring_test("Large straight miss", "Large Straight", [1, 2, 3, 4, 6], 0):
		pass_count += 1
	else:
		fail_count += 1

	if _run_single_scoring_test("Large straight hit", "Large Straight", [2, 3, 4, 5, 6], 40):
		pass_count += 1
	else:
		fail_count += 1
	if _run_single_scoring_test("Small straight in large", "Small Straight", [2, 3, 4, 5, 6], 30):
		pass_count += 1
	else:
		fail_count += 1

	if _run_single_scoring_test("Chance mixed", "Chance", [1, 3, 3, 4, 6], 17):
		pass_count += 1
	else:
		fail_count += 1

	print("=== Scoring Tests End | PASS=%d FAIL=%d ===" % [pass_count, fail_count])


static func _run_single_scoring_test(label: String, category: String, values: Array, expected: int) -> bool:
	var actual: int = ScoringRules.calculate_score(category, values)
	if actual == expected:
		print("PASS | %s | %s | dice=%s | expected=%d actual=%d" % [label, category, str(values), expected, actual])
		return true
	push_error("FAIL | %s | %s | dice=%s | expected=%d actual=%d" % [label, category, str(values), expected, actual])
	return false
