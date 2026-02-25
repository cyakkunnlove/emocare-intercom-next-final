package com.emocare.intercom.next.ui.components

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.emocare.intercom.next.R
import com.emocare.intercom.next.ui.features.auth.LoginScreen
import com.emocare.intercom.next.ui.features.auth.AuthViewModel
import com.emocare.intercom.next.ui.features.channels.ChannelsScreen
import com.emocare.intercom.next.ui.features.callhistory.CallHistoryScreen
import com.emocare.intercom.next.ui.features.settings.SettingsScreen
import com.emocare.intercom.next.ui.theme.EmoCareIntercomTheme

/**
 * EmoCare Intercom Next メインアプリコンポーネント
 * 
 * LINEレベルの品質を目指すメインUI構成：
 * - Material 3 デザイン
 * - スムーズなナビゲーション
 * - 60FPS アニメーション
 */
@Composable
fun EmoCareIntercomApp() {
    val authViewModel: AuthViewModel = hiltViewModel()
    
    EmoCareIntercomTheme {
        if (authViewModel.isAuthenticated.value) {
            MainApp()
        } else {
            LoginScreen()
        }
    }
}

@Composable
private fun MainApp() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination
    
    Scaffold(
        modifier = Modifier.fillMaxSize(),
        bottomBar = {
            NavigationBar {
                bottomNavItems.forEach { item ->
                    NavigationBarItem(
                        icon = {
                            Icon(
                                painter = painterResource(id = item.icon),
                                contentDescription = null
                            )
                        },
                        label = {
                            Text(text = stringResource(id = item.label))
                        },
                        selected = currentDestination?.hierarchy?.any { 
                            it.route == item.route 
                        } == true,
                        onClick = {
                            navController.navigate(item.route) {
                                // ポップアップしてスタックをクリア
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                // 既に選択されている場合は重複を避ける
                                launchSingleTop = true
                                // 状態を復元
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { paddingValues ->
        NavHost(
            navController = navController,
            startDestination = BottomNavItem.Channels.route,
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            enterTransition = {
                fadeIn(animationSpec = tween(300)) + 
                slideIntoContainer(
                    towards = AnimatedContentTransitionScope.SlideDirection.Left,
                    animationSpec = tween(300)
                )
            },
            exitTransition = {
                fadeOut(animationSpec = tween(300)) +
                slideOutOfContainer(
                    towards = AnimatedContentTransitionScope.SlideDirection.Left,
                    animationSpec = tween(300)
                )
            }
        ) {
            // チャンネル一覧画面
            composable(BottomNavItem.Channels.route) {
                ChannelsScreen(navController = navController)
            }
            
            // 通話履歴画面
            composable(BottomNavItem.CallHistory.route) {
                CallHistoryScreen(navController = navController)
            }
            
            // 設定画面
            composable(BottomNavItem.Settings.route) {
                SettingsScreen(navController = navController)
            }
            
            // 個別チャンネル詳細画面
            composable(
                route = "channel_detail/{channelId}",
                enterTransition = {
                    slideIntoContainer(
                        towards = AnimatedContentTransitionScope.SlideDirection.Up,
                        animationSpec = tween(400)
                    )
                },
                exitTransition = {
                    slideOutOfContainer(
                        towards = AnimatedContentTransitionScope.SlideDirection.Down,
                        animationSpec = tween(400)
                    )
                }
            ) { backStackEntry ->
                val channelId = backStackEntry.arguments?.getString("channelId") ?: ""
                ChannelDetailScreen(
                    channelId = channelId,
                    navController = navController
                )
            }
            
            // 通話画面 (フルスクリーン)
            composable(
                route = "call/{channelId}/{callType}",
                enterTransition = {
                    fadeIn(animationSpec = tween(200))
                },
                exitTransition = {
                    fadeOut(animationSpec = tween(200))
                }
            ) { backStackEntry ->
                val channelId = backStackEntry.arguments?.getString("channelId") ?: ""
                val callType = backStackEntry.arguments?.getString("callType") ?: "voip"
                CallScreen(
                    channelId = channelId,
                    callType = callType,
                    onCallEnd = {
                        navController.popBackStack()
                    }
                )
            }
        }
    }
}

/**
 * ボトムナビゲーションアイテム定義
 */
sealed class BottomNavItem(
    val route: String,
    val icon: Int,
    val label: Int
) {
    object Channels : BottomNavItem(
        route = "channels",
        icon = R.drawable.ic_channels,
        label = R.string.nav_channels
    )
    
    object CallHistory : BottomNavItem(
        route = "call_history", 
        icon = R.drawable.ic_history,
        label = R.string.nav_call_history
    )
    
    object Settings : BottomNavItem(
        route = "settings",
        icon = R.drawable.ic_settings,
        label = R.string.nav_settings
    )
}

private val bottomNavItems = listOf(
    BottomNavItem.Channels,
    BottomNavItem.CallHistory,
    BottomNavItem.Settings
)

/**
 * チャンネル詳細画面のプレースホルダー
 */
@Composable
private fun ChannelDetailScreen(
    channelId: String,
    navController: androidx.navigation.NavController
) {
    // TODO: 実装予定
    androidx.compose.foundation.layout.Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = androidx.compose.ui.Alignment.Center
    ) {
        androidx.compose.material3.Text(
            text = "チャンネル詳細: $channelId\n実装予定",
            style = androidx.compose.material3.MaterialTheme.typography.titleLarge
        )
    }
}

/**
 * 通話画面のプレースホルダー
 */
@Composable  
private fun CallScreen(
    channelId: String,
    callType: String,
    onCallEnd: () -> Unit
) {
    // TODO: 実装予定
    androidx.compose.foundation.layout.Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally,
        verticalArrangement = androidx.compose.foundation.layout.Arrangement.Center
    ) {
        androidx.compose.material3.Text(
            text = "通話中: $channelId\n種類: $callType",
            style = androidx.compose.material3.MaterialTheme.typography.titleLarge
        )
        
        androidx.compose.foundation.layout.Spacer(
            modifier = Modifier.height(32.dp)
        )
        
        androidx.compose.material3.Button(
            onClick = onCallEnd
        ) {
            androidx.compose.material3.Text("通話終了")
        }
    }
}