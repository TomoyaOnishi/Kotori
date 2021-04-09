![kotori_3_2](https://user-images.githubusercontent.com/2742732/113466069-d4f66700-9473-11eb-9e06-660e2f4871d9.png)

# Kotori

A super lightweight and testable library for Twitter written in Swift using Combine.

# Futures

- [x] Support Twitter v1 API (OAuth1.0)
- [x] Login with Twitter
- [x] Multiple accounts management
- [x] Support making an authorized `URLRequest`
- [x] Support chunked media upload
- [ ] Support Twitter v2 API (OAuth2.0)

# Installation

Use swift package manager.

# Usage

## Login with Twitter

Use `ClientCredential`, `TwitterAuthorizationFlow` and `TwitterAccountStore`.

1. Prepare for login.
```swift
import Kotori

// Your credentials.
let clientCredential: ClientCredential = .init(consumerKey: "Your consumer key from https://developer.twitter.com",
                                               consumerSecret: "Your consumer secret from https://developer.twitter.com",
                                               callbackURL: URL(string: "Your app's url scheme. see https://developer.twitter.com")!)

// Login flow manager.
let twitterLoginFlow = TwitterAuthorizationFlow(clientCredential: clientCredential, urlSession: .shared)

// Account manager.
let accountStore = TwitterAccountStore(keychainAccessGroup: "Your keychain access group.")
```

2. Authorization handshake start.
```
twitterLoginFlow.authorize()
    .receive(on: RunLoop.main)
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { credentials in
            accountStore.add(credential) // Save to the keychain.
            self.credentials = accountStore.allCredentials() // Get all logged in accounts.
        })
     .store(in: &cancellables)
```

3. Open the Twitter login page in your app.

Kotori request you for open the twitter login page to authorize by the user.
So, add codes which open the twitter login page in your app.
```
NotificationCenter.default.publisher(for: TwitterAuthorizationFlow.resourceOwnerAuthorizationOpenURL)
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { output in
            guard let url = output.object as? URL else { fatalError() }            
            // Present WebView or SFSafariViewController in SwiftUI or UIKit for the user authentication.
        })
    .store(in: &cancellables)
```

4. Open your app from the Twitter login page. (URL Scheme)

After finished login in the Twitter login page, The Twitter login page redirects to the your app using url scheme including credential parameters.
So, add codes which handle the url scheme and pass it to the Kotori.
```swift

// SwiftUI
// Use View Modifier.
.onOpenURL(perform: { url in
    twitterLoginFlow.handleCallbackFromTwitter(url: url)
})

// UIKit
// Use AppDelegate method.
func application(_ app: UIApplication, 
                     open url: URL, 
                  options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    twitterLoginFlow.handleCallbackFromTwitter(url: url)
}
```

5. Handle login completion callback from the Kotori.

After call this, `twitterLoginFlow.authorize().sink()` will be called.

## Account management

Use `TwitterAccountStore`.

```
let accountStore = TwitterAccountStore(keychainAccessGroup: "your keychain access group")
accountStore.allCredentials()
```

## API call

Use `TwitterAPIRequest`.

Kotori does not provide the network layer, response parser.  Just only URLRequest.

```swift
let twitterRequest = TwitterAPIRequest(resourceURL: Endpoint.statusUpdate,
                                       httpMethod: .POST,
                                       parameters: tweet.asParameters(),
                                       credential: credentials,
                                       clientCredential: clientCredential)
let urlRequest = twitterRequest.makeURLRequest()
```

## Media upload

Use `TwitterMediaUploader`.

Kotori supports chunked upload. Chuneked upload is very fast upload method but has many steps and difficult. So, Kotori may help you.

Single image upload sample.
```swift
let uploader = TwitterMediaUploader(credential: credentials, data: imageData, mimeType: "image/png", clientCredential: clientCredential, index: index)
// uploader.publisher().sink()
```

Multiple image upload sample.
```swift
let mediaUploaders = medias.enumerated().map({ index, media -> AnyPublisher<MediaUploadOutput, TwitterMediaUploader.MediaUploadError> in
    let mediaUpload: TwitterMediaUploader = .init(credential: credentials, data: media.data, mimeType: media.mimeType, clientCredential: clientCredential, index: index)
    return mediaUpload.publisher()
})

Publishers.MergeMany(mediaUploaders)
.collect(mediaUploaders.count)
.sink(
    receiveCompletion: { _ in },
    receiveValue: { output in 
      // Get media IDs from output.
    }
).store(in: &cancellables)
```

# Contribution
PRs are welcome. Format is free!

# Naming

Kotori is `small bird` in English. 

Kotori is small and lightweight library for the Twitter.

Kotori may help you...
