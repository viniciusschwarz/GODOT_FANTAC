extends SceneTree

func _assert_true(condition: bool, test_name: String) -> void:
	if not condition:
		printerr("[FAIL] " + test_name)
		quit(1)
	else:
		print("[PASS] " + test_name)

func _init() -> void:
	print("--- RUNNING GOAP PHASE 1 UNIT TESTS ---")
	_test_numeric_rules()
	_test_numeric_effects()
	_test_symbolic_rules_and_effects()
	_test_state_snapshot_hashing()
	_test_memory_isolation()
	print("[PASS] All GOAP Phase 1 unit tests passed successfully.")
	quit(0)

func _test_numeric_rules() -> void:
	var snapshot = GoapStateSnapshot.new()
	snapshot.set_number(&"health", 15.0)
	snapshot.set_number(&"stamina", 0.0)
	snapshot.set_number(&"flags", 5.0) # 0b0101

	var r_eq = GoapNumericRule.new(&"health", GoapTypes.ComparisonOperator.EQUALS, 15.0)
	_assert_true(r_eq.evaluates(snapshot), "numeric rule EQUALS")

	var r_neq = GoapNumericRule.new(&"health", GoapTypes.ComparisonOperator.NOT_EQUALS, 10.0)
	_assert_true(r_neq.evaluates(snapshot), "numeric rule NOT_EQUALS")

	var r_gte = GoapNumericRule.new(&"health", GoapTypes.ComparisonOperator.GREATER_THAN_OR_EQUAL, 15.0)
	_assert_true(r_gte.evaluates(snapshot), "numeric rule GREATER_THAN_OR_EQUAL")

	var r_lt = GoapNumericRule.new(&"health", GoapTypes.ComparisonOperator.LESS_THAN, 20.0)
	_assert_true(r_lt.evaluates(snapshot), "numeric rule LESS_THAN")

	var r_range = GoapNumericRule.new(&"health", GoapTypes.ComparisonOperator.RANGE_INCLUSIVE, 10.0, 20.0)
	_assert_true(r_range.evaluates(snapshot), "numeric rule RANGE_INCLUSIVE")

	var r_bit = GoapNumericRule.new(&"flags", GoapTypes.ComparisonOperator.HAS_BITMASK, 1.0) # 0b0001
	_assert_true(r_bit.evaluates(snapshot), "numeric rule HAS_BITMASK")

	# Missing key check
	var r_missing = GoapNumericRule.new(&"missing", GoapTypes.ComparisonOperator.NOT_EQUALS, 10.0)
	_assert_true(r_missing.evaluates(snapshot) == false, "numeric rule missing key NOT_EQUALS returns false")

func _test_numeric_effects() -> void:
	var snapshot = GoapStateSnapshot.new()

	var e_assign = GoapNumericEffect.new(&"mana", GoapTypes.NumericEffectOp.ASSIGN, 10.0)
	e_assign.apply_to(snapshot)
	_assert_true(snapshot.get_number(&"mana") == 10.0, "numeric effect ASSIGN")

	var e_add = GoapNumericEffect.new(&"mana", GoapTypes.NumericEffectOp.ADD, 5.0)
	e_add.apply_to(snapshot)
	_assert_true(snapshot.get_number(&"mana") == 15.0, "numeric effect ADD")

	var e_sub = GoapNumericEffect.new(&"mana", GoapTypes.NumericEffectOp.SUBTRACT, 3.0)
	e_sub.apply_to(snapshot)
	_assert_true(snapshot.get_number(&"mana") == 12.0, "numeric effect SUBTRACT")

	var e_min = GoapNumericEffect.new(&"mana", GoapTypes.NumericEffectOp.MIN, 10.0)
	e_min.apply_to(snapshot)
	_assert_true(snapshot.get_number(&"mana") == 10.0, "numeric effect MIN")

func _test_symbolic_rules_and_effects() -> void:
	var snapshot = GoapStateSnapshot.new()

	var e_assign = GoapSymbolicEffect.new(&"state", GoapTypes.SymbolicEffectOp.ASSIGN, &"idle")
	e_assign.apply_to(snapshot)
	_assert_true(snapshot.get_symbol(&"state") == &"idle", "symbolic effect ASSIGN")

	var r_eq = GoapSymbolicRule.new(&"state", &"idle")
	_assert_true(r_eq.evaluates(snapshot), "symbolic rule EQUALS")

	var r_neq = GoapSymbolicRule.new(&"state", &"moving", true) # negate = true
	_assert_true(r_neq.evaluates(snapshot), "symbolic rule NOT_EQUALS via negate")

	var e_unset = GoapSymbolicEffect.new(&"state", GoapTypes.SymbolicEffectOp.UNSET)
	e_unset.apply_to(snapshot)
	_assert_true(not snapshot.has_symbol(&"state"), "symbolic effect UNSET")

	var r_missing = GoapSymbolicRule.new(&"state", null)
	_assert_true(r_missing.evaluates(snapshot), "symbolic rule evaluates missing key as null")

func _test_state_snapshot_hashing() -> void:
	var snap1 = GoapStateSnapshot.new()
	snap1.set_symbol(&"is_active", true)
	snap1.set_symbol(&"id", 100)
	snap1.set_number(&"health", 50.5)
	snap1.set_number(&"stamina", 10.0)

	var snap2 = GoapStateSnapshot.new()
	# Insert in different order
	snap2.set_number(&"stamina", 10.0)
	snap2.set_symbol(&"id", 100)
	snap2.set_number(&"health", 50.5)
	snap2.set_symbol(&"is_active", true)

	var hash1 = snap1.compute_hash()
	var hash2 = snap2.compute_hash()

	_assert_true(hash1 == hash2, "deterministic state hashing regardless of insertion order")

	# Verify format structure
	var expected = "s:[id=i:100;is_active=b:true]|n:[health=50.5000;stamina=10.0000]"
	_assert_true(hash1 == expected, "hash formatted precisely as required")

func _test_memory_isolation() -> void:
	var snap1 = GoapStateSnapshot.new()
	snap1.set_symbol(&"name", "agent_1")
	snap1.set_number(&"hp", 10.0)

	var snap2 = snap1.duplicate_snapshot()
	snap2.set_symbol(&"name", "agent_2")
	snap2.set_number(&"hp", 5.0)

	_assert_true(snap1.get_symbol(&"name") == "agent_1", "duplicate isolated symbol modification")
	_assert_true(snap1.get_number(&"hp") == 10.0, "duplicate isolated number modification")
