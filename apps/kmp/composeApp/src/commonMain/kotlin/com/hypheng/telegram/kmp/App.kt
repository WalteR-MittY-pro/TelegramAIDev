package com.hypheng.telegram.kmp

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Shapes
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.text.KeyboardOptions
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController

@Composable
internal fun TelegramDemoApp(
    startupRuntimeHook: StartupRuntimeHook = StartupRuntimeHook.None,
    sessionStore: DemoSessionStore = NoOpDemoSessionStore,
    chatListDebugState: ChatListDebugState = ChatListDebugState.Default,
) {
    var startupAssets by remember { mutableStateOf<StartupAssets?>(null) }
    val navController = rememberNavController()
    val colorScheme = startupAssets?.tokens?.toColorScheme() ?: lightColorScheme()
    val shapes = startupAssets?.tokens?.toShapes() ?: Shapes()

    MaterialTheme(
        colorScheme = colorScheme,
        shapes = shapes,
    ) {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.surface,
        ) {
            NavHost(
                navController = navController,
                startDestination = AppRoute.Bootstrap.route,
            ) {
                composable(AppRoute.Bootstrap.route) {
                    BootstrapRoute(
                        startupRuntimeHook = startupRuntimeHook,
                        sessionStore = sessionStore,
                        onLoaded = { assets, initialRoute ->
                            startupAssets = assets
                            navController.navigate(initialRoute.route) {
                                popUpTo(AppRoute.Bootstrap.route) { inclusive = true }
                                launchSingleTop = true
                            }
                        },
                    )
                }
                composable(AppRoute.Login.route) {
                    val assets = startupAssets
                    if (assets == null) {
                        BootstrapFallbackScreen()
                    } else {
                        LoginRoute(
                            assets = assets,
                            sessionStore = sessionStore,
                            onAuthenticated = { destination ->
                                navController.navigate(destination.route) {
                                    popUpTo(AppRoute.Login.route) { inclusive = true }
                                    launchSingleTop = true
                                }
                            },
                        )
                    }
                }
                composable(AppRoute.Home.route) {
                    val assets = startupAssets
                    if (assets == null) {
                        BootstrapFallbackScreen()
                    } else {
                        HomeShellRoute(
                            assets = assets,
                            chatListDebugState = chatListDebugState,
                        )
                    }
                }
                composable(AppRoute.AuthenticatedPlaceholder.route) {
                    val assets = startupAssets
                    if (assets == null) {
                        BootstrapFallbackScreen()
                    } else {
                        AuthenticatedPlaceholderScreen(assets)
                    }
                }
            }
        }
    }
}

@Composable
private fun BootstrapRoute(
    startupRuntimeHook: StartupRuntimeHook,
    sessionStore: DemoSessionStore,
    onLoaded: (StartupAssets, AppRoute) -> Unit,
) {
    var bootstrapCopy by remember { mutableStateOf<BootstrapCopy?>(null) }
    var failureMessage by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(startupRuntimeHook) {
        failureMessage = null
        val result = loadBootstrapRouteResult(
            startupRuntimeHook = startupRuntimeHook,
        )
        bootstrapCopy = result.bootstrapCopy
        when (val outcome = result.outcome) {
            is BootstrapLoadOutcome.Loaded -> onLoaded(
                outcome.assets,
                DemoSessionManager.determineInitialRoute(
                    sessionStore = sessionStore,
                    authenticatedRoute = authenticatedRouteForAssets(outcome.assets).route,
                ),
            )
            is BootstrapLoadOutcome.Failure -> failureMessage = outcome.notice
        }
    }

    when (val error = failureMessage) {
        null -> BootstrapLoadingScreen(copy = bootstrapCopy)
        else -> StartupFailureScreen(
            title = bootstrapCopy?.title,
            notice = bootstrapCopy?.failureNotice ?: error,
        )
    }
}

@Composable
private fun BootstrapLoadingScreen(copy: BootstrapCopy?) {
    CenteredScreen {
        CircularProgressIndicator(
            color = MaterialTheme.colorScheme.primary,
            strokeWidth = 3.dp,
        )
        Spacer(modifier = Modifier.height(24.dp))
        copy?.let {
            Text(
                text = it.title,
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold),
                color = MaterialTheme.colorScheme.onSurface,
                textAlign = TextAlign.Center,
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = it.body,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
            )
        }
    }
}

@Composable
private fun StartupFailureScreen(
    title: String?,
    notice: String,
) {
    CenteredScreen {
        Text(
            text = title ?: "",
            style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold),
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center,
        )
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            text = notice,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.error,
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun BootstrapFallbackScreen() {
    CenteredScreen {
        CircularProgressIndicator()
    }
}

@Composable
private fun LoginRoute(
    assets: StartupAssets,
    sessionStore: DemoSessionStore,
    onAuthenticated: (AppRoute) -> Unit,
) {
    val authenticatedRoute = authenticatedRouteForAssets(assets)
    val loginCopy = assets.sharedCopy.login
    var loginState by remember { mutableStateOf(DemoLoginFlowState()) }
    val continueSubmission = {
        val result = when (loginState.currentStep) {
            DemoLoginStep.PhoneEntry -> DemoLoginFlow.submitPhoneNumber(
                state = loginState,
                invalidInputNotice = loginCopy.invalidInputNotice,
            )

            DemoLoginStep.Verification -> DemoLoginFlow.submitVerification(
                state = loginState,
                authenticatedRoute = authenticatedRoute.route,
            )
        }
        loginState = result.state
        if (result.nextRoute == authenticatedRoute.route) {
            DemoSessionManager.persistAuthenticatedSession(
                sessionStore = sessionStore,
                normalizedPhoneNumber = result.state.normalizedPhoneNumber.ifBlank {
                    DemoLoginFlow.normalizePhoneNumber(result.state.rawPhoneNumber)
                },
            )
            onAuthenticated(authenticatedRoute)
        }
    }
    val verificationPhoneNumber = loginState.normalizedPhoneNumber.ifBlank {
        DemoLoginFlow.normalizePhoneNumber(loginState.rawPhoneNumber)
    }
    LoginRoute(
        assets = assets,
        loginState = loginState,
        verificationPhoneNumber = verificationPhoneNumber,
        onPhoneChanged = { updatedPhoneNumber ->
            loginState = DemoLoginFlow.onPhoneChanged(loginState, updatedPhoneNumber)
        },
        onContinue = continueSubmission,
    )
}

@Composable
private fun LoginRoute(
    assets: StartupAssets,
    loginState: DemoLoginFlowState,
    verificationPhoneNumber: String,
    onPhoneChanged: (String) -> Unit,
    onContinue: () -> Unit,
) {
    val loginCopy = assets.sharedCopy.login
    Scaffold(
        snackbarHost = { SnackbarHost(remember { androidx.compose.material3.SnackbarHostState() }) },
        containerColor = MaterialTheme.colorScheme.surface,
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(padding)
                .padding(horizontal = assets.tokens.spacing.xl.dp, vertical = assets.tokens.spacing.xxl.dp),
            verticalArrangement = Arrangement.Center,
        ) {
            AppMark(
                svgBytes = assets.appMarkSvg,
                modifier = Modifier
                    .align(Alignment.CenterHorizontally)
                    .size(72.dp),
            )
            Spacer(modifier = Modifier.height(24.dp))
            Text(
                text = loginCopy.brandTitle,
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold),
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.align(Alignment.CenterHorizontally),
            )
            Spacer(modifier = Modifier.height(16.dp))
            Surface(
                modifier = Modifier.fillMaxWidth(),
                color = MaterialTheme.colorScheme.background,
                tonalElevation = 2.dp,
                shape = RoundedCornerShape(assets.tokens.radius.card.dp),
            ) {
                Column(
                    modifier = Modifier.padding(assets.tokens.spacing.xl.dp),
                ) {
                    if (loginState.currentStep == DemoLoginStep.PhoneEntry) {
                        PhoneEntryContent(
                            assets = assets,
                            loginCopy = loginCopy,
                            phoneNumber = loginState.rawPhoneNumber,
                            errorMessage = loginState.errorMessage,
                            onPhoneChanged = onPhoneChanged,
                            onContinue = onContinue,
                        )
                    } else {
                        VerificationContent(
                            assets = assets,
                            loginCopy = loginCopy,
                            verificationPhoneNumber = verificationPhoneNumber,
                            onContinue = onContinue,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun PhoneEntryContent(
    assets: StartupAssets,
    loginCopy: LoginCopy,
    phoneNumber: String,
    errorMessage: String?,
    onPhoneChanged: (String) -> Unit,
    onContinue: () -> Unit,
) {
    Text(
        text = loginCopy.headline,
        style = MaterialTheme.typography.headlineSmall.copy(
            fontSize = assets.tokens.typography.size.headline.sp,
            lineHeight = assets.tokens.typography.lineHeight.headline.sp,
            fontWeight = FontWeight.Bold,
        ),
        color = MaterialTheme.colorScheme.onSurface,
    )
    Spacer(modifier = Modifier.height(12.dp))
    Text(
        text = loginCopy.body,
        style = MaterialTheme.typography.bodyLarge.copy(
            fontSize = assets.tokens.typography.size.bodyStrong.sp,
            lineHeight = assets.tokens.typography.lineHeight.bodyStrong.sp,
        ),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
    Spacer(modifier = Modifier.height(20.dp))
    OutlinedTextField(
        value = phoneNumber,
        onValueChange = onPhoneChanged,
        modifier = Modifier.fillMaxWidth(),
        label = {
            Text(text = loginCopy.phoneLabel)
        },
        placeholder = {
            Text(text = loginCopy.phoneHint)
        },
        singleLine = true,
        isError = errorMessage != null,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
        shape = RoundedCornerShape(assets.tokens.radius.field.dp),
    )
    if (errorMessage != null) {
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            text = errorMessage,
            style = MaterialTheme.typography.bodySmall.copy(
                fontSize = assets.tokens.typography.size.body.sp,
                lineHeight = assets.tokens.typography.lineHeight.body.sp,
            ),
            color = MaterialTheme.colorScheme.error,
        )
    }
    Spacer(modifier = Modifier.height(24.dp))
    ContinueButton(
        label = loginCopy.continueLabel,
        onContinue = onContinue,
    )
    Spacer(modifier = Modifier.height(16.dp))
    Text(
        text = loginCopy.footer,
        style = MaterialTheme.typography.bodySmall.copy(
            fontSize = assets.tokens.typography.size.body.sp,
            lineHeight = assets.tokens.typography.lineHeight.body.sp,
        ),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

@Composable
private fun VerificationContent(
    assets: StartupAssets,
    loginCopy: LoginCopy,
    verificationPhoneNumber: String,
    onContinue: () -> Unit,
) {
    Text(
        text = loginCopy.headline,
        style = MaterialTheme.typography.headlineSmall.copy(
            fontSize = assets.tokens.typography.size.headline.sp,
            lineHeight = assets.tokens.typography.lineHeight.headline.sp,
            fontWeight = FontWeight.Bold,
        ),
        color = MaterialTheme.colorScheme.onSurface,
    )
    Spacer(modifier = Modifier.height(12.dp))
    Text(
        text = loginCopy.footer,
        style = MaterialTheme.typography.bodyLarge.copy(
            fontSize = assets.tokens.typography.size.bodyStrong.sp,
            lineHeight = assets.tokens.typography.lineHeight.bodyStrong.sp,
        ),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
    Spacer(modifier = Modifier.height(20.dp))
    PhonePreviewCard(
        label = loginCopy.phoneLabel,
        value = verificationPhoneNumber,
        contentPadding = PaddingValues(assets.tokens.spacing.lg.dp),
    )
    Spacer(modifier = Modifier.height(24.dp))
    ContinueButton(
        label = loginCopy.continueLabel,
        onContinue = onContinue,
    )
}

@Composable
private fun ContinueButton(
    label: String,
    onContinue: () -> Unit,
) {
    Button(
        onClick = onContinue,
        modifier = Modifier.fillMaxWidth(),
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.primary,
            contentColor = MaterialTheme.colorScheme.onPrimary,
        ),
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.SemiBold),
        )
    }
}

@Composable
private fun PhonePreviewCard(
    label: String,
    value: String,
    contentPadding: PaddingValues,
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = RoundedCornerShape(14.dp),
    ) {
        Column(
            modifier = Modifier.padding(contentPadding),
        ) {
            Text(
                text = label,
                style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Medium),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = value,
                style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Medium),
                color = MaterialTheme.colorScheme.onSurface,
            )
        }
    }
}

@Composable
private fun AuthenticatedPlaceholderScreen(assets: StartupAssets) {
    CenteredScreen {
        Text(
            text = assets.sharedMockData.startup.defaultAuthenticatedDestination,
            style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold),
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center,
        )
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            text = assets.sharedCopy.homeShell.placeholderNotice,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun CenteredScreen(
    content: @Composable ColumnScope.() -> Unit,
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.surface),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            content = content,
        )
    }
}

@Composable
private fun AppMark(
    svgBytes: ByteArray,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .background(
                color = MaterialTheme.colorScheme.primary.copy(alpha = if (svgBytes.isNotEmpty()) 1f else 0.5f),
                shape = RoundedCornerShape(20.dp),
            ),
    )
}

internal enum class AppRoute(val route: String) {
    Bootstrap("bootstrap"),
    Login("login"),
    Home("home"),
    AuthenticatedPlaceholder("authenticated-placeholder"),
}

internal fun authenticatedRouteForAssets(assets: StartupAssets): AppRoute {
    val homeShell = assets.sharedMockData.homeShell
    val homeTabReady = homeShell.defaultTab == "chats" &&
        homeShell.tabs.any { it.id == "chats" && it.implementedInSlice <= 4 }
    return if (homeTabReady) AppRoute.Home else AppRoute.AuthenticatedPlaceholder
}

internal fun DesignTokens.toColorScheme() = lightColorScheme(
    primary = color.accent.brand.asColor(),
    onPrimary = color.text.inverse.asColor(),
    background = color.surface.appBackground.asColor(),
    onBackground = color.text.primary.asColor(),
    surface = color.surface.screen.asColor(),
    onSurface = color.text.primary.asColor(),
    surfaceVariant = color.surface.subtle.asColor(),
    onSurfaceVariant = color.text.secondary.asColor(),
    outline = color.border.subtle.asColor(),
    error = color.status.error.asColor(),
    tertiary = color.accent.brandSoft.asColor(),
)

internal fun DesignTokens.toShapes() = Shapes(
    large = RoundedCornerShape(radius.card.dp),
    medium = RoundedCornerShape(radius.field.dp),
    small = RoundedCornerShape(radius.field.dp),
)

internal fun String.asColor(): Color {
    val sanitized = removePrefix("#")
    val (alpha, red, green, blue) = when (sanitized.length) {
        6 -> listOf("FF") + sanitized.chunked(2)
        8 -> sanitized.chunked(2)
        else -> error("Unsupported color token: $this")
    }
    return Color(
        red = red.toInt(16),
        green = green.toInt(16),
        blue = blue.toInt(16),
        alpha = alpha.toInt(16),
    )
}
