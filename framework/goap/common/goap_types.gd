class_name GoapTypes
extends RefCounted

enum ActionStatus {
	READY = 0,
	RUNNING = 1,
	COMPLETED = 2,
	FAILED = 3
}

enum ComparisonOperator {
	EQUALS = 0,
	NOT_EQUALS = 1,
	GREATER_THAN = 2,
	GREATER_THAN_OR_EQUAL = 3,
	LESS_THAN = 4,
	LESS_THAN_OR_EQUAL = 5,
	RANGE_INCLUSIVE = 6,
	HAS_BITMASK = 7
}

enum NumericEffectOp {
	ASSIGN = 0,
	ADD = 1,
	SUBTRACT = 2,
	MIN = 3,
	MAX = 4
}

enum SymbolicEffectOp {
	ASSIGN = 0,
	UNSET = 1
}
