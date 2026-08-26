class_name CashLedgerAppendResult
extends RefCounted

var ledger: CashLedgerState
var errors: Array[String] = []


func succeeded() -> bool:
	return ledger != null and errors.is_empty()


func add_error(message: String) -> void:
	errors.append(message)


func format_errors() -> String:
	return "\n".join(errors)
