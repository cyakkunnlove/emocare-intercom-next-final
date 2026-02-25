package com.emocare.intercom.next.ui.theme

import androidx.compose.ui.graphics.Color

// Material 3 Light Theme Colors
val md_theme_light_primary = Color(0xFF1976D2)          // Blue 700
val md_theme_light_onPrimary = Color(0xFFFFFFFF)        // White
val md_theme_light_primaryContainer = Color(0xFFE3F2FD) // Blue 50
val md_theme_light_onPrimaryContainer = Color(0xFF0D47A1) // Blue 900
val md_theme_light_secondary = Color(0xFF4CAF50)        // Green 500
val md_theme_light_onSecondary = Color(0xFFFFFFFF)      // White
val md_theme_light_secondaryContainer = Color(0xFFE8F5E8) // Green 50
val md_theme_light_onSecondaryContainer = Color(0xFF1B5E20) // Green 900
val md_theme_light_tertiary = Color(0xFFFF9800)         // Orange 500
val md_theme_light_onTertiary = Color(0xFFFFFFFF)       // White
val md_theme_light_tertiaryContainer = Color(0xFFFFF3E0) // Orange 50
val md_theme_light_onTertiaryContainer = Color(0xFFE65100) // Orange 900
val md_theme_light_error = Color(0xFFD32F2F)            // Red 700
val md_theme_light_errorContainer = Color(0xFFFFEBEE)   // Red 50
val md_theme_light_onError = Color(0xFFFFFFFF)          // White
val md_theme_light_onErrorContainer = Color(0xFFB71C1C) // Red 900
val md_theme_light_background = Color(0xFFFAFAFA)       // Grey 50
val md_theme_light_onBackground = Color(0xFF212121)     // Grey 900
val md_theme_light_surface = Color(0xFFFFFFFF)          // White
val md_theme_light_onSurface = Color(0xFF212121)        // Grey 900
val md_theme_light_surfaceVariant = Color(0xFFF5F5F5)   // Grey 100
val md_theme_light_onSurfaceVariant = Color(0xFF616161) // Grey 700
val md_theme_light_outline = Color(0xFFBDBDBD)          // Grey 400
val md_theme_light_inverseOnSurface = Color(0xFFFAFAFA) // Grey 50
val md_theme_light_inverseSurface = Color(0xFF303030)   // Grey 850
val md_theme_light_inversePrimary = Color(0xFF90CAF9)   // Blue 200
val md_theme_light_surfaceTint = Color(0xFF1976D2)      // Blue 700
val md_theme_light_outlineVariant = Color(0xFFE0E0E0)   // Grey 300
val md_theme_light_scrim = Color(0xFF000000)            // Black

// Material 3 Dark Theme Colors
val md_theme_dark_primary = Color(0xFF90CAF9)           // Blue 200
val md_theme_dark_onPrimary = Color(0xFF0D47A1)         // Blue 900
val md_theme_dark_primaryContainer = Color(0xFF1565C0)  // Blue 800
val md_theme_dark_onPrimaryContainer = Color(0xFFE3F2FD) // Blue 50
val md_theme_dark_secondary = Color(0xFF81C784)         // Green 300
val md_theme_dark_onSecondary = Color(0xFF1B5E20)       // Green 900
val md_theme_dark_secondaryContainer = Color(0xFF388E3C) // Green 700
val md_theme_dark_onSecondaryContainer = Color(0xFFE8F5E8) // Green 50
val md_theme_dark_tertiary = Color(0xFFFFB74D)          // Orange 300
val md_theme_dark_onTertiary = Color(0xFFE65100)        // Orange 900
val md_theme_dark_tertiaryContainer = Color(0xFFF57C00) // Orange 800
val md_theme_dark_onTertiaryContainer = Color(0xFFFFF3E0) // Orange 50
val md_theme_dark_error = Color(0xFFEF5350)             // Red 400
val md_theme_dark_errorContainer = Color(0xFFD32F2F)    // Red 700
val md_theme_dark_onError = Color(0xFFB71C1C)           // Red 900
val md_theme_dark_onErrorContainer = Color(0xFFFFEBEE)  // Red 50
val md_theme_dark_background = Color(0xFF121212)        // Dark background
val md_theme_dark_onBackground = Color(0xFFE0E0E0)      // Light text
val md_theme_dark_surface = Color(0xFF1E1E1E)           // Dark surface
val md_theme_dark_onSurface = Color(0xFFE0E0E0)         // Light text
val md_theme_dark_surfaceVariant = Color(0xFF2C2C2C)    // Dark variant
val md_theme_dark_onSurfaceVariant = Color(0xFFBDBDBD)  // Medium text
val md_theme_dark_outline = Color(0xFF757575)           // Medium outline
val md_theme_dark_inverseOnSurface = Color(0xFF121212)  // Dark
val md_theme_dark_inverseSurface = Color(0xFFE0E0E0)    // Light
val md_theme_dark_inversePrimary = Color(0xFF1976D2)    // Blue 700
val md_theme_dark_surfaceTint = Color(0xFF90CAF9)       // Blue 200
val md_theme_dark_outlineVariant = Color(0xFF424242)    // Dark outline
val md_theme_dark_scrim = Color(0xFF000000)             // Black

// Emergency Theme Colors (High Contrast Red-based)
val md_theme_emergency_primary = Color(0xFFD32F2F)      // Red 700 - Emergency primary
val md_theme_emergency_primaryContainer = Color(0xFFFFCDD2) // Red 100 - Emergency container
val md_theme_emergency_onPrimaryContainer = Color(0xFFB71C1C) // Red 900 - On container
val md_theme_emergency_secondary = Color(0xFFFF5722)    // Deep Orange 500 - Emergency secondary
val md_theme_emergency_error = Color(0xFFD50000)        // Red A700 - Critical error

// Custom App Colors
object AppColors {
    // VoIP Call Colors
    val voipCallActive = Color(0xFF4CAF50)      // Green 500
    val voipCallIncoming = Color(0xFF2196F3)    // Blue 500
    val voipCallEnding = Color(0xFFFF5722)      // Deep Orange 500
    val voipCallFailed = Color(0xFFD32F2F)      // Red 700
    
    // PTT Colors
    val pttIdle = Color(0xFF9E9E9E)             // Grey 500
    val pttActive = Color(0xFFD32F2F)           // Red 700 - Recording
    val pttReady = Color(0xFF4CAF50)            // Green 500 - Ready to record
    val pttDisabled = Color(0xFFBDBDBD)         // Grey 400
    
    // Channel Status Colors
    val channelOnline = Color(0xFF4CAF50)       // Green 500
    val channelOffline = Color(0xFF9E9E9E)      // Grey 500
    val channelEmergency = Color(0xFFD32F2F)    // Red 700
    val channelMaintenance = Color(0xFFFF9800)  // Orange 500
    
    // Audio Level Indicators
    val audioLevelLow = Color(0xFF4CAF50)       // Green 500
    val audioLevelMedium = Color(0xFFFF9800)    // Orange 500
    val audioLevelHigh = Color(0xFFD32F2F)      // Red 700
    val audioLevelPeak = Color(0xFFD50000)      // Red A700
    
    // Connection Status
    val connectionStrong = Color(0xFF4CAF50)    // Green 500
    val connectionWeak = Color(0xFFFF9800)      // Orange 500
    val connectionNone = Color(0xFF9E9E9E)      // Grey 500
    val connectionError = Color(0xFFD32F2F)     // Red 700
    
    // Role-based Colors
    val roleAdmin = Color(0xFFD32F2F)           // Red 700 - Administrator
    val roleManager = Color(0xFFFF9800)         // Orange 500 - Manager  
    val roleStaff = Color(0xFF2196F3)           // Blue 500 - Staff
    val roleGuest = Color(0xFF9E9E9E)           // Grey 500 - Guest
    
    // Background Gradients
    val gradientStart = Color(0xFFE3F2FD)       // Blue 50
    val gradientEnd = Color(0xFFFFFFFF)         // White
    val emergencyGradientStart = Color(0xFFFFCDD2) // Red 100
    val emergencyGradientEnd = Color(0xFFF8BBD9)   // Pink 100
}

// Semantic Colors for specific use cases
object SemanticColors {
    // Success states
    val success = AppColors.voipCallActive
    val successContainer = Color(0xFFE8F5E8)
    val onSuccessContainer = Color(0xFF1B5E20)
    
    // Warning states
    val warning = AppColors.audioLevelMedium
    val warningContainer = Color(0xFFFFF3E0)
    val onWarningContainer = Color(0xFFE65100)
    
    // Information states
    val info = Color(0xFF2196F3)                // Blue 500
    val infoContainer = Color(0xFFE3F2FD)       // Blue 50
    val onInfoContainer = Color(0xFF0D47A1)     // Blue 900
    
    // Disabled states
    val disabled = Color(0xFFBDBDBD)            // Grey 400
    val onDisabled = Color(0xFF757575)          // Grey 600
}