import AVFoundation
import AVKit
import Flutter
import Foundation
import Security
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    OfflineDownloadCoordinator.shared.configure()
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "ekeflicks/offline",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        let arguments = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "download":
          OfflineDownloadCoordinator.shared.enqueue(arguments, result: result)
        case "list":
          result(OfflineDownloadCoordinator.shared.list())
        case "remove":
          OfflineDownloadCoordinator.shared.remove(
            assetId: arguments["assetId"] as? String ?? "",
            result: result
          )
        case "pause":
          OfflineDownloadCoordinator.shared.pauseAll()
          result(nil)
        case "resume":
          OfflineDownloadCoordinator.shared.resumeAll()
          result(nil)
        case "play":
          OfflineDownloadCoordinator.shared.play(
            assetId: arguments["assetId"] as? String ?? "",
            result: result
          )
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
  ) {
    OfflineDownloadCoordinator.shared.handleBackgroundEvents(
      identifier: identifier,
      completionHandler: completionHandler
    )
  }
}

/// Owns HLS downloads, FairPlay persistable keys and native AVPlayer playback.
final class OfflineDownloadCoordinator: NSObject,
    AVAssetDownloadDelegate,
    AVContentKeySessionDelegate,
    AVPlayerViewControllerDelegate {
  static let shared = OfflineDownloadCoordinator()

  private let metadataKey = "eke.offline.downloads.v1"
  private let keychainService = "com.ekeflicks.offline.fairplay"
  private let entitlementService = "com.ekeflicks.offline.entitlement"
  private let queue = DispatchQueue(label: "com.ekeflicks.offline.content-keys")
  private var metadata: [String: [String: Any]] = [:]
  private var session: AVAssetDownloadURLSession!
  private var tasks: [String: AVAssetDownloadTask] = [:]
  private var keySessions: [String: AVContentKeySession] = [:]
  private var sessionAssetIds: [ObjectIdentifier: String] = [:]
  private var entitlements: [String: String] = [:]
  private var warmingPlayers: [String: AVPlayer] = [:]
  private var playbackIds = Set<String>()
  private var backgroundCompletionHandler: (() -> Void)?
  private weak var presentedPlayer: AVPlayerViewController?

  private override init() {
    super.init()
    if let saved = UserDefaults.standard.dictionary(forKey: metadataKey) as? [String: [String: Any]] {
      metadata = saved
    }
    let configuration = URLSessionConfiguration.background(
      withIdentifier: (Bundle.main.bundleIdentifier ?? "com.ekeflicks.app") + ".offline-downloads"
    )
    configuration.sessionSendsLaunchEvents = true
    session = AVAssetDownloadURLSession(
      configuration: configuration,
      assetDownloadDelegate: self,
      delegateQueue: OperationQueue.main
    )
  }

  func configure() {
    session.getAllTasks { [weak self] allTasks in
      guard let self else { return }
      for task in allTasks {
        guard let downloadTask = task as? AVAssetDownloadTask,
              let assetId = downloadTask.taskDescription else { continue }
        self.tasks[assetId] = downloadTask
        if let values = self.metadata[assetId],
           values["drmRequired"] as? Bool == true {
          let asset = downloadTask.urlAsset
          self.attachContentKeySession(assetId: assetId, asset: asset)
          self.entitlements[assetId] = self.loadSecretString(
            service: self.entitlementService,
            account: assetId
          )
        }
      }
      self.resumePendingLicenseRequests()
    }
  }

  func handleBackgroundEvents(identifier: String, completionHandler: @escaping () -> Void) {
    backgroundCompletionHandler = completionHandler
    configure()
  }

  func enqueue(_ arguments: [String: Any], result: @escaping FlutterResult) {
    guard let assetId = arguments["assetId"] as? String,
          let manifestUrl = arguments["manifestUrl"] as? String,
          URL(string: manifestUrl)?.scheme == "https" else {
      result(FlutterError(code: "OFFLINE_DOWNLOAD_INVALID", message: "A signed HTTPS manifest is required.", details: nil))
      return
    }
    guard metadata[assetId]?["status"] as? String != "completed" else {
      result(FlutterError(code: "OFFLINE_EXISTS", message: "This video is already downloaded.", details: nil))
      return
    }

    var values = arguments
    values.removeValue(forKey: "entitlementToken")
    values["status"] = (arguments["drmRequired"] as? Bool == true) ? "waiting_for_license" : "queued"
    values["progress"] = 0.0
    values["localPath"] = ""
    values["keyIdentifiers"] = [String]()
    metadata[assetId] = values
    saveMetadata()

    let asset = AVURLAsset(url: URL(string: manifestUrl)!)
    if arguments["drmRequired"] as? Bool == true {
      guard arguments["drmSystem"] as? String == "fairplay",
            let licenseUrl = arguments["licenseUrl"] as? String,
            URL(string: licenseUrl)?.scheme == "https",
            let entitlement = arguments["entitlementToken"] as? String,
            !entitlement.isEmpty,
            let certificateUrl = arguments["certificateUrl"] as? String,
            URL(string: certificateUrl)?.scheme == "https" else {
        metadata[assetId]?["status"] = "failed"
        saveMetadata()
        result(FlutterError(code: "OFFLINE_LICENSE_INVALID", message: "FairPlay offline configuration is incomplete.", details: nil))
        return
      }
      entitlements[assetId] = entitlement
      saveSecret(entitlement, service: entitlementService, account: assetId)
      attachContentKeySession(assetId: assetId, asset: asset)
      let warmPlayer = AVPlayer(playerItem: AVPlayerItem(asset: asset))
      warmingPlayers[assetId] = warmPlayer
      warmPlayer.play()
      result(nil)
    } else {
      guard arguments["drmRequired"] as? Bool != true else {
        metadata[assetId]?["status"] = "failed"
        saveMetadata()
        result(FlutterError(code: "OFFLINE_DRM_UNSUPPORTED", message: "This iOS download requires FairPlay.", details: nil))
        return
      }
      startAssetDownload(assetId: assetId, asset: asset)
      result(nil)
    }
  }

  func list() -> [[String: Any]] {
    return metadata.map { assetId, values in
      var row = values
      row["assetId"] = assetId
      return row
    }.sorted {
      ($0["title"] as? String ?? "").localizedCaseInsensitiveCompare(
        $1["title"] as? String ?? ""
      ) == .orderedAscending
    }
  }

  func pauseAll() {
    session.getAllTasks { tasks in tasks.forEach { $0.suspend() } }
    for assetId in metadata.keys {
      if metadata[assetId]?["status"] as? String == "downloading" {
        metadata[assetId]?["status"] = "paused"
      }
    }
    saveMetadata()
  }

  func resumeAll() {
    session.getAllTasks { tasks in tasks.forEach { $0.resume() } }
    for assetId in metadata.keys {
      if metadata[assetId]?["status"] as? String == "paused" {
        metadata[assetId]?["status"] = "downloading"
      }
    }
    saveMetadata()
  }

  func remove(assetId: String, result: @escaping FlutterResult) {
    guard !assetId.isEmpty else {
      result(FlutterError(code: "OFFLINE_REMOVE_INVALID", message: "Missing video identifier.", details: nil))
      return
    }
    session.getAllTasks { [weak self] allTasks in
      guard let self else { return }
      allTasks.filter { $0.taskDescription == assetId }.forEach { $0.cancel() }
      self.tasks.removeValue(forKey: assetId)
      self.warmingPlayers.removeValue(forKey: assetId)?.pause()
      if let localPath = self.metadata[assetId]?["localPath"] as? String,
         !localPath.isEmpty {
        try? FileManager.default.removeItem(at: URL(fileURLWithPath: localPath))
      }
      let identifiers = self.metadata[assetId]?["keyIdentifiers"] as? [String] ?? []
      identifiers.forEach {
        self.deleteSecret(service: self.keychainService, account: self.keyAccount(assetId, $0))
      }
      self.deleteSecret(service: self.entitlementService, account: assetId)
      self.entitlements.removeValue(forKey: assetId)
      self.keySessions.removeValue(forKey: assetId)
      self.metadata.removeValue(forKey: assetId)
      self.saveMetadata()
      result(nil)
    }
  }

  func play(assetId: String, result: @escaping FlutterResult) {
    guard let values = metadata[assetId],
          values["status"] as? String == "completed",
          let localPath = values["localPath"] as? String,
          !localPath.isEmpty,
          FileManager.default.fileExists(atPath: localPath) else {
      result(FlutterError(code: "OFFLINE_NOT_READY", message: "This video is not fully downloaded.", details: nil))
      return
    }
    if isExpired(values["expiresAt"] as? String) {
      result(FlutterError(code: "OFFLINE_LICENSE_EXPIRED", message: "The offline license has expired.", details: nil))
      return
    }
    guard let root = UIApplication.shared.keyWindowRootViewController else {
      result(FlutterError(code: "OFFLINE_PLAYER_UNAVAILABLE", message: "The native player is unavailable.", details: nil))
      return
    }

    let asset = AVURLAsset(url: URL(fileURLWithPath: localPath))
    if values["drmRequired"] as? Bool == true {
      attachContentKeySession(assetId: assetId, asset: asset)
      playbackIds.insert(assetId)
    }
    let playerController = AVPlayerViewController()
    playerController.delegate = self
    playerController.modalPresentationStyle = .fullScreen
    playerController.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
    presentedPlayer = playerController
    root.present(playerController, animated: true) {
      playerController.player?.play()
    }
    result(nil)
  }

  private func resumePendingLicenseRequests() {
    for (assetId, values) in metadata where values["status"] as? String == "waiting_for_license" {
      guard let manifestUrl = values["manifestUrl"] as? String,
            let url = URL(string: manifestUrl),
            let token = entitlements[assetId] ?? loadSecretString(service: entitlementService, account: assetId) else {
        continue
      }
      entitlements[assetId] = token
      let asset = AVURLAsset(url: url)
      attachContentKeySession(assetId: assetId, asset: asset)
      let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
      warmingPlayers[assetId] = player
      player.play()
    }
  }

  private func attachContentKeySession(assetId: String, asset: AVURLAsset) {
    let keySession: AVContentKeySession
    if let existing = keySessions[assetId] {
      keySession = existing
    } else {
      keySession = AVContentKeySession(keySystem: .fairPlayStreaming)
      keySession.setDelegate(self, queue: queue)
      keySessions[assetId] = keySession
      sessionAssetIds[ObjectIdentifier(keySession)] = assetId
    }
    keySession.addContentKeyRecipient(asset)
  }

  private func startAssetDownload(assetId: String, asset: AVURLAsset) {
    guard tasks[assetId] == nil else { return }
    if metadata[assetId]?["drmRequired"] as? Bool == true {
      attachContentKeySession(assetId: assetId, asset: asset)
    }
    let title = metadata[assetId]?["title"] as? String ?? "EkeFlicks"
    guard let task = session.makeAssetDownloadTask(
      asset: asset,
      assetTitle: title,
      assetArtworkData: nil,
      options: nil
    ) else {
      metadata[assetId]?["status"] = "failed"
      metadata[assetId]?["error"] = "task_creation_failed"
      saveMetadata()
      return
    }
    task.taskDescription = assetId
    tasks[assetId] = task
    metadata[assetId]?["status"] = "downloading"
    saveMetadata()
    task.resume()
  }

  // MARK: AVContentKeySessionDelegate

  func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) {
    guard let assetId = sessionAssetIds[ObjectIdentifier(session)] else {
      keyRequest.processContentKeyResponseError(
        NSError(domain: "EkeFlicksOffline", code: 1, userInfo: nil)
      )
      return
    }
    do {
      try keyRequest.respondByRequestingPersistableContentKeyRequestAndReturnError()
    } catch {
      // FairPlay does not allow persistence in some external playback contexts.
      keyRequest.processContentKeyResponseError(error)
    }
  }

  func contentKeySession(
    _ session: AVContentKeySession,
    didProvideRenewingContentKeyRequest keyRequest: AVContentKeyRequest
  ) {
    contentKeySession(session, didProvide: keyRequest)
  }

  func contentKeySession(
    _ session: AVContentKeySession,
    didProvide keyRequest: AVPersistableContentKeyRequest
  ) {
    guard let assetId = sessionAssetIds[ObjectIdentifier(session)],
          let identifier = keyRequest.identifier as? String else {
      keyRequest.processContentKeyResponseError(
        NSError(domain: "EkeFlicksOffline", code: 2, userInfo: nil)
      )
      return
    }

    if let storedKey = loadSecretData(
      service: keychainService,
      account: keyAccount(assetId, identifier)
    ), playbackIds.contains(assetId) || metadata[assetId]?["status"] as? String == "downloading" {
      keyRequest.processContentKeyResponse(
        AVContentKeyResponse(fairPlayStreamingKeyResponseData: storedKey)
      )
      return
    }

    guard let entitlement = entitlements[assetId] ?? loadSecretString(
      service: entitlementService,
      account: assetId
    ), let certificateUrl = metadata[assetId]?["certificateUrl"] as? String,
       let certificateURL = URL(string: certificateUrl),
       let licenseUrl = metadata[assetId]?["licenseUrl"] as? String,
       let licenseURL = URL(string: licenseUrl) else {
      keyRequest.processContentKeyResponseError(
        NSError(domain: "EkeFlicksOffline", code: 3, userInfo: nil)
      )
      return
    }

    let contentIdentifier = identifier.replacingOccurrences(of: "skd://", with: "")
    guard let contentIdentifierData = contentIdentifier.data(using: .utf8) else {
      keyRequest.processContentKeyResponseError(
        NSError(domain: "EkeFlicksOffline", code: 4, userInfo: nil)
      )
      return
    }

    URLSession.shared.dataTask(with: certificateURL) { [weak self] certificate, response, error in
      guard let self,
            error == nil,
            let certificate,
            let http = response as? HTTPURLResponse,
            (200..<300).contains(http.statusCode) else {
        keyRequest.processContentKeyResponseError(
          error ?? NSError(domain: "EkeFlicksOffline", code: 5, userInfo: nil)
        )
        return
      }

      keyRequest.makeStreamingContentKeyRequestData(
        forApp: certificate,
        contentIdentifier: contentIdentifierData,
        options: [AVContentKeyRequestProtocolVersionsKey: [1]]
      ) { spc, spcError in
        guard let spc, spcError == nil else {
          keyRequest.processContentKeyResponseError(
            spcError ?? NSError(domain: "EkeFlicksOffline", code: 6, userInfo: nil)
          )
          return
        }
        var request = URLRequest(url: licenseURL)
        request.httpMethod = "POST"
        request.setValue(entitlement, forHTTPHeaderField: "X-AxDRM-Message")
        request.httpBody = spc
        URLSession.shared.dataTask(with: request) { ckc, licenseResponse, licenseError in
          guard let ckc,
                licenseError == nil,
                let http = licenseResponse as? HTTPURLResponse,
                (200..<300).contains(http.statusCode) else {
            keyRequest.processContentKeyResponseError(
              licenseError ?? NSError(domain: "EkeFlicksOffline", code: 7, userInfo: nil)
            )
            return
          }
          do {
            let persistableKey = try keyRequest.persistableContentKey(
              fromKeyVendorResponse: ckc,
              options: nil
            )
            self.saveSecret(
              persistableKey,
              service: self.keychainService,
              account: self.keyAccount(assetId, identifier)
            )
            DispatchQueue.main.async {
              self.rememberKeyIdentifier(identifier, assetId: assetId)
              keyRequest.processContentKeyResponse(
                AVContentKeyResponse(fairPlayStreamingKeyResponseData: persistableKey)
              )
              if !self.playbackIds.contains(assetId),
                 let values = self.metadata[assetId],
                 let manifestUrl = values["manifestUrl"] as? String,
                 let assetUrl = URL(string: manifestUrl) {
                self.startAssetDownload(assetId: assetId, asset: AVURLAsset(url: assetUrl))
              }
              self.warmingPlayers.removeValue(forKey: assetId)?.pause()
            }
          } catch {
            keyRequest.processContentKeyResponseError(error)
          }
        }.resume()
      }
    }.resume()
  }

  func contentKeySession(
    _ session: AVContentKeySession,
    contentKeyRequest keyRequest: AVContentKeyRequest,
    didFailWithError error: Error
  ) {
    guard let assetId = sessionAssetIds[ObjectIdentifier(session)] else { return }
    metadata[assetId]?["status"] = "failed"
    metadata[assetId]?["error"] = "fairplay_license_failed"
    saveMetadata()
  }

  // MARK: AVAssetDownloadDelegate

  func urlSession(
    _ session: URLSession,
    assetDownloadTask: AVAssetDownloadTask,
    willDownloadTo location: URL
  ) {
    guard let assetId = assetDownloadTask.taskDescription else { return }
    metadata[assetId]?["localPath"] = location.path
    metadata[assetId]?["status"] = "downloading"
    saveMetadata()
  }

  func urlSession(
    _ session: URLSession,
    assetDownloadTask: AVAssetDownloadTask,
    didLoad timeRange: CMTimeRange,
    totalTimeRangesLoaded: [NSValue],
    timeRangeExpectedToLoad: CMTimeRange
  ) {
    guard let assetId = assetDownloadTask.taskDescription else { return }
    let expected = CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
    let loaded = totalTimeRangesLoaded.reduce(0.0) {
      $0 + CMTimeGetSeconds($1.timeRangeValue.duration)
    }
    let progress = expected > 0 ? min(max(loaded / expected, 0), 1) : 0
    metadata[assetId]?["progress"] = progress * 100
    metadata[assetId]?["status"] = "downloading"
    saveMetadata()
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let assetId = task.taskDescription else { return }
    tasks.removeValue(forKey: assetId)
    if let error {
      metadata[assetId]?["status"] = "failed"
      metadata[assetId]?["error"] = error.localizedDescription
    } else {
      metadata[assetId]?["status"] = "completed"
      metadata[assetId]?["progress"] = 100.0
      deleteSecret(service: entitlementService, account: assetId)
      entitlements.removeValue(forKey: assetId)
    }
    warmingPlayers.removeValue(forKey: assetId)?.pause()
    saveMetadata()
  }

  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    DispatchQueue.main.async {
      self.backgroundCompletionHandler?()
      self.backgroundCompletionHandler = nil
    }
  }

  // MARK: AVPlayerViewControllerDelegate

  func playerViewController(
    _ playerViewController: AVPlayerViewController,
    willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
  ) {
    guard let assetId = playbackIds.first else { return }
    coordinator.animate(alongsideTransition: nil) { [weak self] _ in
      guard let self else { return }
      playerViewController.player?.pause()
      self.playbackIds.remove(assetId)
      self.keySessions.removeValue(forKey: assetId)
      self.presentedPlayer = nil
    }
  }

  private func rememberKeyIdentifier(_ identifier: String, assetId: String) {
    var identifiers = metadata[assetId]?["keyIdentifiers"] as? [String] ?? []
    if !identifiers.contains(identifier) {
      identifiers.append(identifier)
      metadata[assetId]?["keyIdentifiers"] = identifiers
      saveMetadata()
    }
  }

  private func keyAccount(_ assetId: String, _ identifier: String) -> String {
    let encoded = Data(identifier.utf8).base64EncodedString()
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "=", with: "")
    return assetId + "." + encoded
  }

  private func saveSecret(_ string: String, service: String, account: String) {
    saveSecret(Data(string.utf8), service: service, account: account)
  }

  private func saveSecret(_ data: Data, service: String, account: String) {
    deleteSecret(service: service, account: account)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
      kSecValueData as String: data
    ]
    SecItemAdd(query as CFDictionary, nil)
  }

  private func loadSecretData(service: String, account: String) -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return nil }
    return item as? Data
  }

  private func loadSecretString(service: String, account: String) -> String? {
    guard let data = loadSecretData(service: service, account: account) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  private func deleteSecret(service: String, account: String) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]
    SecItemDelete(query as CFDictionary)
  }

  private func isExpired(_ value: String?) -> Bool {
    guard let value, !value.isEmpty else { return false }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let date = formatter.date(from: value) ?? {
      formatter.formatOptions = [.withInternetDateTime]
      return formatter.date(from: value)
    }()
    return date.map { $0 <= Date() } ?? true
  }

  private func saveMetadata() {
    UserDefaults.standard.set(metadata, forKey: metadataKey)
  }
}

private extension UIApplication {
  var keyWindowRootViewController: UIViewController? {
    return windows.first(where: \.isKeyWindow)?.rootViewController
  }
}
