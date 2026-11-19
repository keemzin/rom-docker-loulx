PaymentManagers = {}

autoImport("json")

function PaymentManagers:StartPayment(userId, productId, callback)
    if callback then
        callback("failed")
    end
end

function PaymentManagers:GeneratePaymentLink(userId, productId)
    return ""
end

function PaymentManagers:CheckLatestPaymentStatus(userId, productId, callback)
    if callback then
        callback("failed")
    end
end

function PaymentManagers:CancelCheckStatus()
    self.isChecking = false
end
