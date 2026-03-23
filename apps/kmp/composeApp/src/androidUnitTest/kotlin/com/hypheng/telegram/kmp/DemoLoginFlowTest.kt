package com.hypheng.telegram.kmp

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DemoLoginFlowTest {
    @Test
    fun normalizesPhoneNumbersByKeepingDigitsAndLeadingPlus() {
        assertEquals("+14155550199", DemoLoginFlow.normalizePhoneNumber("+1 (415) 555-0199"))
        assertEquals("+8613800138000", DemoLoginFlow.normalizePhoneNumber("86 138 0013 8000"))
    }

    @Test
    fun invalidPhoneNumberShowsClearFeedbackAndStaysOnPhoneEntry() {
        val result = DemoLoginFlow.submitPhoneNumber(
            state = DemoLoginFlowState(rawPhoneNumber = "123"),
            invalidInputNotice = "Enter a valid demo phone number to continue.",
        )

        assertEquals(DemoLoginStep.PhoneEntry, result.state.currentStep)
        assertEquals("Enter a valid demo phone number to continue.", result.state.errorMessage)
        assertEquals("", result.state.normalizedPhoneNumber)
        assertNull(result.nextRoute)
    }

    @Test
    fun validPhoneNumberAdvancesIntoVerificationStep() {
        val result = DemoLoginFlow.submitPhoneNumber(
            state = DemoLoginFlowState(rawPhoneNumber = "+1 415 555 0199"),
            invalidInputNotice = "Enter a valid demo phone number to continue.",
        )

        assertEquals(DemoLoginStep.Verification, result.state.currentStep)
        assertEquals("+14155550199", result.state.normalizedPhoneNumber)
        assertNull(result.state.errorMessage)
        assertNull(result.nextRoute)
    }

    @Test
    fun verificationStepHandsOffToAuthenticatedPlaceholder() {
        val result = DemoLoginFlow.submitVerification(
            state = DemoLoginFlowState(
                rawPhoneNumber = "+1 415 555 0199",
                normalizedPhoneNumber = "+14155550199",
                currentStep = DemoLoginStep.Verification,
            ),
            authenticatedRoute = "authenticated-placeholder",
        )

        assertEquals("authenticated-placeholder", result.nextRoute)
        assertTrue(result.state.errorMessage == null)
    }
}
