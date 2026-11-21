function alloc = calc_external_creditor_loss(ExtDebt, PayFrac)
alloc = ExtDebt .* max(1 - PayFrac, 0);