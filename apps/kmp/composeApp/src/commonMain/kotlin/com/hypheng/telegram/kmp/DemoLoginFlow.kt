package com.hypheng.telegram.kmp

internal enum class DemoLoginStep {
    PhoneEntry,
    Verification,
}

internal data class DemoLoginFlowState(
    val rawPhoneNumber: String = "",
    val normalizedPhoneNumber: String = "",
    val currentStep: DemoLoginStep = DemoLoginStep.PhoneEntry,
    val errorMessage: String? = null,
)

internal data class DemoLoginSubmissionResult(
    val state: DemoLoginFlowState,
    val nextRoute: String? = null,
)

internal object DemoLoginFlow {
    fun onPhoneChanged(
        state: DemoLoginFlowState,
        rawPhoneNumber: String,
    ) = state.copy(
        rawPhoneNumber = rawPhoneNumber,
        errorMessage = null,
    )

    fun submitPhoneNumber(
        state: DemoLoginFlowState,
        invalidInputNotice: String,
    ): DemoLoginSubmissionResult {
        if (state.currentStep != DemoLoginStep.PhoneEntry) {
            return DemoLoginSubmissionResult(state = state)
        }

        val normalizedPhoneNumber = normalizePhoneNumber(state.rawPhoneNumber)
        if (!isValidPhoneNumber(normalizedPhoneNumber)) {
            return DemoLoginSubmissionResult(
                state = state.copy(
                    normalizedPhoneNumber = "",
                    errorMessage = invalidInputNotice,
                ),
            )
        }

        return DemoLoginSubmissionResult(
            state = state.copy(
                normalizedPhoneNumber = normalizedPhoneNumber,
                currentStep = DemoLoginStep.Verification,
                errorMessage = null,
            ),
        )
    }

    fun submitVerification(
        state: DemoLoginFlowState,
        authenticatedRoute: String,
    ): DemoLoginSubmissionResult {
        if (state.currentStep != DemoLoginStep.Verification || state.normalizedPhoneNumber.isBlank()) {
            return DemoLoginSubmissionResult(state = state)
        }

        return DemoLoginSubmissionResult(
            state = state.copy(errorMessage = null),
            nextRoute = authenticatedRoute,
        )
    }

    fun normalizePhoneNumber(rawPhoneNumber: String): String {
        val digitsOnly = rawPhoneNumber.filter(Char::isDigit)
        if (digitsOnly.isEmpty()) {
            return ""
        }
        return "+$digitsOnly"
    }

    fun isValidPhoneNumber(normalizedPhoneNumber: String): Boolean {
        if (!normalizedPhoneNumber.startsWith("+")) {
            return false
        }

        val digitCount = normalizedPhoneNumber.removePrefix("+").length
        return digitCount in 7..15
    }
}
