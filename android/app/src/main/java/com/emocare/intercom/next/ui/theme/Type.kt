package com.emocare.intercom.next.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.emocare.intercom.next.R

// カスタムフォントファミリーの定義
val NotoSansJP = FontFamily(
    Font(R.font.noto_sans_jp_light, FontWeight.Light),
    Font(R.font.noto_sans_jp_regular, FontWeight.Normal),
    Font(R.font.noto_sans_jp_medium, FontWeight.Medium),
    Font(R.font.noto_sans_jp_bold, FontWeight.Bold)
)

// Material 3 Typography with Japanese font support
val Typography = Typography(
    // Display styles - 大きなタイトルや重要な表示
    displayLarge = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Normal,
        fontSize = 57.sp,
        lineHeight = 64.sp,
        letterSpacing = (-0.25).sp,
    ),
    displayMedium = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Normal,
        fontSize = 45.sp,
        lineHeight = 52.sp,
        letterSpacing = 0.sp,
    ),
    displaySmall = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Normal,
        fontSize = 36.sp,
        lineHeight = 44.sp,
        letterSpacing = 0.sp,
    ),
    
    // Headline styles - セクションヘッダーやページタイトル
    headlineLarge = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Normal,
        fontSize = 32.sp,
        lineHeight = 40.sp,
        letterSpacing = 0.sp,
    ),
    headlineMedium = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Normal,
        fontSize = 28.sp,
        lineHeight = 36.sp,
        letterSpacing = 0.sp,
    ),
    headlineSmall = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Normal,
        fontSize = 24.sp,
        lineHeight = 32.sp,
        letterSpacing = 0.sp,
    ),
    
    // Title styles - カードタイトルやリストアイテムのメイン情報
    titleLarge = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Medium,
        fontSize = 22.sp,
        lineHeight = 28.sp,
        letterSpacing = 0.sp,
    ),
    titleMedium = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Medium,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.15.sp,
    ),
    titleSmall = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.1.sp,
    ),
    
    // Label styles - ボタンテキストやタブラベル
    labelLarge = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.1.sp,
    ),
    labelMedium = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.5.sp,
    ),
    labelSmall = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Medium,
        fontSize = 11.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.5.sp,
    ),
    
    // Body styles - 本文テキストや説明文
    bodyLarge = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.15.sp,
    ),
    bodyMedium = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.25.sp,
    ),
    bodySmall = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.4.sp,
    ),
)

// カスタムタイポグラフィ - アプリ固有のスタイル
object AppTypography {
    
    // 緊急時表示用 - 大きく目立つテキスト
    val emergencyTitle = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Bold,
        fontSize = 32.sp,
        lineHeight = 40.sp,
        letterSpacing = 0.sp,
    )
    
    val emergencyBody = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Medium,
        fontSize = 18.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.sp,
    )
    
    // 通話中表示用
    val callActiveTitle = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Bold,
        fontSize = 24.sp,
        lineHeight = 32.sp,
        letterSpacing = 0.sp,
    )
    
    val callDuration = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Normal,
        fontSize = 18.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.15.sp,
    )
    
    // PTT表示用
    val pttStatus = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Medium,
        fontSize = 16.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.1.sp,
    )
    
    val pttInstruction = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.4.sp,
    )
    
    // 数値表示用 - 統計情報やカウンタ
    val numberLarge = TextStyle(
        fontFamily = FontFamily.Monospace,
        fontWeight = FontWeight.Bold,
        fontSize = 28.sp,
        lineHeight = 36.sp,
        letterSpacing = 0.sp,
    )
    
    val numberMedium = TextStyle(
        fontFamily = FontFamily.Monospace,
        fontWeight = FontWeight.Medium,
        fontSize = 20.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.sp,
    )
    
    val numberSmall = TextStyle(
        fontFamily = FontFamily.Monospace,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.sp,
    )
    
    // ステータス表示用
    val statusActive = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.5.sp,
    )
    
    val statusInactive = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.5.sp,
    )
    
    // フォームラベル用
    val formLabel = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.1.sp,
    )
    
    val formHelper = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.4.sp,
    )
    
    val formError = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.4.sp,
    )
}

// アクセシビリティ対応のタイポグラフィ
object AccessibilityTypography {
    
    // 大きめのテキストサイズ（視覚障害者向け）
    val largeTitleAccessible = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Bold,
        fontSize = 32.sp,
        lineHeight = 40.sp,
        letterSpacing = 0.sp,
    )
    
    val largeBodyAccessible = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Normal,
        fontSize = 20.sp,
        lineHeight = 28.sp,
        letterSpacing = 0.15.sp,
    )
    
    // 高コントラスト用のテキストスタイル
    val highContrastTitle = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Bold,
        fontSize = 24.sp,
        lineHeight = 32.sp,
        letterSpacing = 0.sp,
    )
    
    val highContrastBody = TextStyle(
        fontFamily = NotoSansJP,
        fontWeight = FontWeight.Medium,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.15.sp,
    )
}