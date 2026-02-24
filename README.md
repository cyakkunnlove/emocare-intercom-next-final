# EmoCare Intercom Next

**LINEレベル品質を目指す完全ゼロベースVoIPインターコムアプリ**

## 🎯 プロジェクト目標
- **品質**: LINEアプリレベルのスムーズ・ストレスフリー体験
- **信頼性**: 医療・介護現場での確実な通話・通信
- **パフォーマンス**: 瞬間起動・100ms以下PTT応答
- **ユーザビリティ**: 学習時間5分以内の直感操作

## 📱 対応プラットフォーム
- **iOS**: Swift + SwiftUI (iOS 15+)
- **Android**: Kotlin + Jetpack Compose (API 26+)

## 🏗️ アーキテクチャ
```
emocare-intercom-next/
├── ios/                 # iOSネイティブアプリ
├── android/             # Androidネイティブアプリ  
├── shared/              # 共通仕様・ドキュメント
├── docs/                # 設計ドキュメント
└── assets/              # 共通リソース
```

## 🔧 主要機能
### VoIP通話
- iOS CallKit + PushKit完全統合
- Android ConnectionService + Telecom Framework
- 150ms以下低遅延音声通話

### PTT (Push-to-Talk)
- 100ms以下高速応答
- リアルタイム音声配信
- バックグラウンド動作対応

### チャンネル制通信
- 施設内部屋・エリア別通信
- 権限管理・緊急モード
- 通話履歴・監査証跡

## 🚀 開発状況
- [x] Phase 1: プロジェクト初期設定・基盤構築
- [ ] Phase 2: iOS・Android基本アプリ作成
- [ ] Phase 3: VoIP通話機能実装
- [ ] Phase 4: PTT機能実装
- [ ] Phase 5: 統合・最適化・品質達成

## 📊 品質目標
- 起動時間: < 1秒
- PTT応答: < 100ms  
- 通話遅延: < 150ms
- 通知成功率: > 99.9%
- クラッシュ率: < 0.01%

## 🛠️ 技術スタック
- **音声**: LiveKit WebRTC
- **認証**: Supabase Auth
- **データベース**: Supabase PostgreSQL  
- **リアルタイム**: Supabase Realtime
- **通知**: FCM + APNs

---
**© 2026 EmoCare - 次世代介護施設向けIntercomアプリ**