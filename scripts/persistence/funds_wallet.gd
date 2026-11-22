class_name FundsWallet
extends RefCounted

const CAP := 9999999

static func quote(held: int, change: int) -> Dictionary:
	var credited := clampi(change, 0, CAP - held)
	var deducted := -clampi(change, -held, 0)
	return {
		"balance": held + credited - deducted,
		"credited": credited,
		"deducted": deducted,
		"discarded": maxi(0, change - credited),
	}

static func apply(profile: Dictionary, change: int) -> Dictionary:
	var result := quote(profile.funds, change)
	profile.funds = result.balance
	return result
