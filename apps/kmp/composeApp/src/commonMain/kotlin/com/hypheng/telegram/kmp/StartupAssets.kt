package com.hypheng.telegram.kmp

import com.hypheng.telegram.kmp.resources.Res
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import org.jetbrains.compose.resources.ExperimentalResourceApi

internal data class StartupAssets(
    val tokens: DesignTokens,
    val sharedCopy: SharedCopy,
    val sharedMockData: SharedMockData,
    val resourceManifest: ResourceManifest,
    val appMarkSvg: ByteArray,
)

internal object StartupAssetRepository {
    private val json = Json {
        ignoreUnknownKeys = true
    }

    @OptIn(ExperimentalResourceApi::class)
    suspend fun loadBootstrapCopy(): BootstrapCopy {
        val copyJson = Res.readBytes("files/shared-copy.json").decodeToString()
        return json.decodeFromString<SharedCopy>(copyJson).bootstrap
    }

    @OptIn(ExperimentalResourceApi::class)
    suspend fun loadAll(): StartupAssets {
        val tokens = json.decodeFromString<DesignTokens>(
            Res.readBytes("files/design-tokens.json").decodeToString(),
        )
        val sharedCopy = json.decodeFromString<SharedCopy>(
            Res.readBytes("files/shared-copy.json").decodeToString(),
        )
        val sharedMockData = json.decodeFromString<SharedMockData>(
            Res.readBytes("files/shared-mock-data.json").decodeToString(),
        )
        val resourceManifest = json.decodeFromString<ResourceManifest>(
            Res.readBytes("files/resource-manifest.json").decodeToString(),
        )
        val appMarkSvg = Res.readBytes("files/resources/app-mark.svg")

        require(resourceManifest.copyRule.copyIntoFrameworkApp) {
            "Shared asset copy rule is not enabled for framework app packaging."
        }
        require(resourceManifest.resources.any { it.id == "app-mark" }) {
            "Required startup asset app-mark is missing from the resource manifest."
        }

        return StartupAssets(
            tokens = tokens,
            sharedCopy = sharedCopy,
            sharedMockData = sharedMockData,
            resourceManifest = resourceManifest,
            appMarkSvg = appMarkSvg,
        )
    }
}

@Serializable
internal data class DesignTokens(
    val meta: MetaTokens,
    val color: ColorTokens,
    val typography: TypographyTokens,
    val spacing: SpacingTokens,
    val radius: RadiusTokens,
    val borderWidth: BorderWidthTokens,
    val elevation: ElevationTokens,
    val iconSize: IconSizeTokens,
    val avatarSize: AvatarSizeTokens,
)

@Serializable
internal data class MetaTokens(
    val name: String,
    val version: String,
)

@Serializable
internal data class ColorTokens(
    val surface: SurfaceColors,
    val text: TextColors,
    val accent: AccentColors,
    val status: StatusColors,
    val border: BorderColors,
    val badge: BadgeColors,
    val avatar: AvatarColors,
)

@Serializable
internal data class SurfaceColors(
    val appBackground: String,
    val screen: String,
    val subtle: String,
    val elevated: String,
)

@Serializable
internal data class TextColors(
    val primary: String,
    val secondary: String,
    val muted: String,
    val inverse: String,
)

@Serializable
internal data class AccentColors(
    val brand: String,
    val brandStrong: String,
    val brandSoft: String,
)

@Serializable
internal data class StatusColors(
    val success: String,
    val warning: String,
    val error: String,
)

@Serializable
internal data class BorderColors(
    val subtle: String,
    val strong: String,
)

@Serializable
internal data class BadgeColors(
    val unreadBackground: String,
    val unreadText: String,
)

@Serializable
internal data class AvatarColors(
    val blue: String,
    val green: String,
    val orange: String,
    val purple: String,
)

@Serializable
internal data class TypographyTokens(
    val family: TypographyFamilies,
    val size: TypographySizes,
    val lineHeight: TypographyLineHeights,
    val weight: TypographyWeights,
)

@Serializable
internal data class TypographyFamilies(
    val primary: String,
)

@Serializable
internal data class TypographySizes(
    val caption: Int,
    val body: Int,
    val bodyStrong: Int,
    val title: Int,
    val headline: Int,
)

@Serializable
internal data class TypographyLineHeights(
    val caption: Int,
    val body: Int,
    val bodyStrong: Int,
    val title: Int,
    val headline: Int,
)

@Serializable
internal data class TypographyWeights(
    val regular: Int,
    val medium: Int,
    val semibold: Int,
    val bold: Int,
)

@Serializable
internal data class SpacingTokens(
    val xs: Int,
    val sm: Int,
    val md: Int,
    val lg: Int,
    val xl: Int,
    val xxl: Int,
)

@Serializable
internal data class RadiusTokens(
    val card: Int,
    val field: Int,
    val pill: Int,
    val bubble: Int,
)

@Serializable
internal data class BorderWidthTokens(
    val hairline: Int,
    val strong: Int,
)

@Serializable
internal data class ElevationTokens(
    val none: Int,
    val card: Int,
    val overlay: Int,
)

@Serializable
internal data class IconSizeTokens(
    val sm: Int,
    val md: Int,
    val lg: Int,
    val xl: Int,
)

@Serializable
internal data class AvatarSizeTokens(
    val list: Int,
    val detail: Int,
)

@Serializable
internal data class SharedCopy(
    val bootstrap: BootstrapCopy,
    val login: LoginCopy,
    val homeShell: HomeShellCopy,
    val chatList: ChatListCopy,
    val chatDetail: ChatDetailCopy,
)

@Serializable
internal data class BootstrapCopy(
    val title: String,
    val body: String,
    val failureNotice: String,
)

@Serializable
internal data class LoginCopy(
    val brandTitle: String,
    val headline: String,
    val body: String,
    val phoneLabel: String,
    val phoneHint: String,
    val continueLabel: String,
    val footer: String,
    val invalidInputNotice: String,
)

@Serializable
internal data class HomeShellCopy(
    val tabs: HomeShellTabsCopy,
    val placeholderNotice: String,
)

@Serializable
internal data class HomeShellTabsCopy(
    val chats: String,
    val contacts: String,
    val settings: String,
)

@Serializable
internal data class ChatListCopy(
    val title: String,
    val loading: String,
    val emptyTitle: String,
    val emptyBody: String,
    val errorTitle: String,
    val errorBody: String,
)

@Serializable
internal data class ChatDetailCopy(
    val titleFallback: String,
    val composerPlaceholder: String,
    val sendLabel: String,
    val sendFailureNotice: String,
)

@Serializable
internal data class SharedMockData(
    val startup: StartupMockData,
    val homeShell: HomeShellMockData,
    val chatList: ChatListMockData,
    val chatDetail: ChatDetailMockData,
)

@Serializable
internal data class StartupMockData(
    val defaultAuthenticatedDestination: String,
)

@Serializable
internal data class HomeShellMockData(
    val defaultTab: String,
    val tabs: List<HomeShellTabMock>,
)

@Serializable
internal data class HomeShellTabMock(
    val id: String,
    val labelKey: String,
    val iconId: String,
    val implementedInSlice: Int,
    val placeholderDestination: Boolean = false,
)

@Serializable
internal data class ChatListMockData(
    val conversations: List<ConversationMockData>,
)

@Serializable
internal data class ConversationMockData(
    val id: String,
    val title: String,
    val snippet: String,
    val timestamp: String,
    val unreadCount: Int,
    val pinned: Boolean,
    val muted: Boolean,
    val avatarResource: String,
    val avatarTint: String,
)

@Serializable
internal data class ChatDetailMockData(
    val placeholderConversationId: String,
    val subtitle: String? = null,
    val typingSubtitle: String? = null,
    val dateLabel: String? = null,
    val messages: List<SeedMessage>,
    val composer: ComposerMockData? = null,
    val localSend: LocalSendMockData,
)

@Serializable
internal data class SeedMessage(
    val id: String,
    val direction: String,
    val text: String,
    val deliveryState: String? = null,
    val timeLabel: String? = null,
    val deliveryLabel: String? = null,
)

@Serializable
internal data class LocalSendMockData(
    val initialDeliveryState: String,
    val settledDeliveryState: String,
    val failureDeliveryState: String,
    val clearComposerOnSuccess: Boolean,
)

@Serializable
internal data class ComposerMockData(
    val placeholder: String,
)

@Serializable
internal data class ResourceManifest(
    val sourceRoot: String,
    val resources: List<ResourceEntry>,
    val copyRule: CopyRule,
)

@Serializable
internal data class ResourceEntry(
    val id: String,
    val source: String,
    val requiredBySlices: List<Int>,
)

@Serializable
internal data class CopyRule(
    val copyIntoFrameworkApp: Boolean,
    val preserveFilenames: Boolean,
    val allowDirectRuntimeReadFromSharedSource: Boolean,
)
