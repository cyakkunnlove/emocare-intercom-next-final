# EmoCare Intercom Next 引き継ぎメモ (2026-02-25)

## 目的
iOS 実機で発生している UI 重なり・余白問題の修正を継続するための状況共有。

## 現在の主訴
- 画面要素が重なって見える（特にタブバー付近とフローティング `+` ボタン）
- 画面全体を使えていないように見える（上部/下部の有効領域不足）
- 画面によってヘッダー表示が不統一だった

## 直近で実施済み
- `ChannelsView`, `CallHistoryView`, `SettingsView` の上部を共通方針へ変更
  - ナビゲーションバーを隠し、画面内ヘッダー (`ScreenHeader`) を採用
- `ChannelsView` の `+` ボタンを通常レイアウトからオーバーレイ配置へ変更
  - `overlay(alignment: .bottomTrailing)` に移行
  - 下部オフセットを `padding(.bottom, 96)` に設定
- `ChannelsView`, `CallHistoryView`, `SettingsView` に下部 `safeAreaInset` を追加
  - タブバーとの重なり回避のため `Color.clear.frame(height: 96)`
- iOS 実機へのビルド/インストール/起動は成功

## 変更主要ファイル
- `ios/EmoCareIntercomNext/Features/Channels/ChannelsView.swift`
- `ios/EmoCareIntercomNext/Features/CallHistory/CallHistoryView.swift`
- `ios/EmoCareIntercomNext/Features/Settings/SettingsView.swift`
- そのほか認証・連携系の修正が複数ファイルに存在（`git status` 参照）

## 未解決または要確認ポイント
1. 実機での最終見え方検証
- 端末個体/OS/UIスケール差でまだ重なりが残る可能性あり
- 特に以下を要チェック
  - チャンネルカード下端とタブバーの距離
  - `+` ボタンとカード/タブバーの干渉
  - 設定 `List` 最下部項目の視認性

2. レイアウト方針の恒久化
- 現在は固定値 (`96`) ベースで回避
- 将来的には以下のいずれかで安定化推奨
  - `safeAreaInsets` を使った動的オフセット
  - カスタムタブバー高さを一元管理
  - iOS 16+ なら `NavigationStack` への移行

3. ビルド警告の整理（機能に直結しないが品質観点で残課題）
- 全方向サポート/Launch storyboard 警告
- `allowBluetooth` deprecation
- 一部未使用変数警告

## 直近の実機情報
- Device: iPhone 15 (`iPhone15,4`)
- Identifier: `00008120-001C35D834E3601E`
- Bundle ID: `com.emocare.intercom.next`

## 再現/確認手順（iOS）
```bash
cd ios
xcodebuild -project EmoCareIntercomNext.xcodeproj -scheme EmoCareIntercomNext -configuration Debug -destination 'platform=iOS,id=00008120-001C35D834E3601E' build
xcrun devicectl device install app --device E6E444C5-5ED3-5BB0-AD79-9652B11577F3 ~/Library/Developer/Xcode/DerivedData/EmoCareIntercomNext-*/Build/Products/Debug-iphoneos/EmoCareIntercomNext.app
xcrun devicectl device process launch --device E6E444C5-5ED3-5BB0-AD79-9652B11577F3 com.emocare.intercom.next
```

## 備考
- 変更量が大きいため、次担当はまず `git diff` で UI 関連差分を絞って確認推奨。
