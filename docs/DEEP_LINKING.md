This document provides example Android and iOS configuration snippets for handling deep-links and universal links for the VanishVault app.

These examples are safe to apply but must be adapted to your app's package ID, team/entitlements, and hosting for universal links.

Android (AndroidManifest.xml)

- Add an intent-filter to the `<activity android:name=".MainActivity">` in `android/app/src/main/AndroidManifest.xml`:

<manifest ...>
  <application ...>
    <activity android:name=".MainActivity" ...>
      <!-- Deep link custom scheme (vanishvault://) -->
      <intent-filter android:autoVerify="false">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="vanishvault" android:host="signed_tx_callback" />
      </intent-filter>

      <!-- Example universal link for Phantom/Slush domain -->
      <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <!-- Accept https links for the wallet provider domain(s) -->
        <data android:scheme="https" android:host="phantom.app" android:pathPrefix="/ul/" />
        <data android:scheme="https" android:host="my.slush.app" android:pathPrefix="/sui/" />
      </intent-filter>
    </activity>
  </application>
</manifest>

Notes:
- Replace `.MainActivity` path if your activity class is in a different package.
- `android:autoVerify` can be enabled and verified by uploading an assetlinks.json to the provider domain if you control it; otherwise set to `false`.


iOS (Info.plist)

- Add URL scheme entry to `ios/Runner/Info.plist` to handle the `vanishvault://` callback:

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>com.example.vanishvault</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>vanishvault</string>
    </array>
  </dict>
</array>

- To support universal links (recommended for Phantom/Slush), enable Associated Domains in your Xcode project and add entries like:

<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:phantom.app</string>
  <string>applinks:my.slush.app</string>
</array>

Notes:
- For universal links to work you must host an `apple-app-site-association` file at the root of the domain (https://phantom.app/apple-app-site-association).
- Replace `com.example.vanishvault` with your actual app bundle identifier.

Callback handling expectations

- The app listens for incoming URIs (e.g. via `uni_links`), and expects either:
  - `vanishvault://signed_tx_callback?payload=<base64-or-json>`
  - `vanishvault://signed_tx_callback?signed_tx=<base64-or-json>`
  - Universal link redirect examples: `https://phantom.app/ul/?payload=<...>&redirect_link=vanishvault://signed_tx_callback`

- Wallets may instead POST or redirect users through intermediate pages. The important part is that after the wallet signs, it redirects the user to your app using the configured callback scheme or universal link.

Security & Production notes

- Use `android:autoVerify="true"` and Associated Domains in production to reduce phishing risk and improve UX.
- Ensure you test on-device; emulators may behave differently for universal links.
- Some wallets may return signed payloads as base64; `DeepLinkHandler` already attempts base64 decoding and JSON unwrap heuristics.

Applying changes

- To apply Android changes, edit `android/app/src/main/AndroidManifest.xml` and add the `intent-filter` entries under your main activity.
- To apply iOS changes, edit `ios/Runner/Info.plist` and add the `CFBundleURLTypes` and `com.apple.developer.associated-domains` keys; enable Associated Domains capability in Xcode.
