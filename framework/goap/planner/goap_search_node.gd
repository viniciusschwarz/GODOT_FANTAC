class_name GoapSearchNode
extends RefCounted

var snapshot: GoapStateSnapshot
var parent: GoapSearchNode = null
var binding: GoapActionBinding = null
var g_cost: float = 0.0
var h_cost: float = 0.0
var depth: int = 0

func f_cost() -> float:
	return g_cost + h_cost
