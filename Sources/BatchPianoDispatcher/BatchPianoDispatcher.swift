
import Batch
import Foundation
import PianoAnalytics

private enum Consts {
    /// Batch internal dispatcher information used for analytics
    static let DISPATCHER_NAME = "piano"
    static let DISPATCHER_VERSION = 1

    /// Piano event keys
    static let CAMPAIGN = "src_campaign"
    static let SOURCE = "src_source"
    static let SOURCE_FORCE = "src_force"
    static let MEDIUM = "src_medium"
    static let CONTENT = "src_content"

    static let EVENT_IMPRESSION = "publisher.impression"
    static let EVENT_CLICK = "publisher.click"
    static let ON_SITE_TYPE = "onsitead_type"
    static let ON_SITE_TYPE_PUBLISHER = "Publisher"
    static let ON_SITE_ADVERTISER = "onsitead_advertiser"
    static let ON_SITE_CAMPAIGN = "onsitead_campaign"
    static let ON_SITE_FORMAT = "onsitead_format"

    /// Custom event name used when logging on Piano
    static let NOTIFICATION_OPEN_NAME = "batch_notification_open"
    static let MESSAGING_SHOW_NAME = "batch_in_app_show"
    static let MESSAGING_CLOSE_NAME = "batch_in_app_close"
    static let MESSAGING_AUTO_CLOSE_NAME = "batch_in_app_auto_close"
    static let MESSAGING_CLOSE_ERROR_NAME = "batch_in_app_close_error"
    static let MESSAGING_CLICK_NAME = "batch_in_app_click"
    static let MESSAGING_WEBVIEW_CLICK_NAME = "batch_in_app_webview_click"
    static let BATCH_WEBVIEW_ANALYTICS_ID = "batch_webview_analytics_id"
    static let BATCH_TRACKING_ID = "batch_tracking_id"
    static let UNKNOWN_EVENT_NAME = "batch_unknown"

    /// Batch event values
    static let BATCH_SRC = "Batch"
    static let BATCH_FORMAT_IN_APP = "in-app"
    static let BATCH_FORMAT_PUSH = "push"
    static let BATCH_DEFAULT_CAMPAIGN = "batch-default-campaign"

    /// Third-party keys
    static let AT_MEDIUM = "at_medium"
    static let AT_CAMPAIGN = "at_campaign"
    static let UTM_SOURCE = "utm_source"
    static let UTM_MEDIUM = "utm_medium"
    static let UTM_CAMPAIGN = "utm_campaign"
    static let UTM_CONTENT = "utm_content"
}

/// Simple protocol to make test easier
protocol BatchPianoEventSenderDelegate {
    func sendEvent(_ event: Event)
}

/// Piano Event Dispatcher
///
/// Dispatch Batch events to the Piano Analytics SDK. By default events are dispatched as On-site Ads.
/// If you want to dispatch as custom event, please see ``BatchPianoDispatcher/BatchPianoDispatcher/enableCustomEvents``.
/// - Note: If you enable custom events, you need to declare them in your Piano Data Model.
@objc
public class BatchPianoDispatcher: NSObject, BatchEventDispatcherDelegate, BatchPianoEventSenderDelegate {
    /// Singleton instance
    public static let instance = BatchPianoDispatcher()

    /// Whether Batch should send custom events (default: false)
    ///
    /// - Note: Custom events must be defined in your Piano Data Model
    public var enableCustomEvents: Bool = false

    /// Whether Batch should send On-Site Ads events (default: true)
    public var enableOnSiteAdsEvents: Bool = true

    /// Whether Batch should handle UTM tags in campaign's deeplink and custom payload. (default = true)
    public var enableUTMTracking: Bool = true

    /// Sender delegate to make mock easier
    var pianoSenderDelegate: BatchPianoEventSenderDelegate?

    /// Private initializer
    override private init() {
        super.init()
        pianoSenderDelegate = self
    }

    /// Get the analytcis name of the dispatcher
    ///
    /// - Returns: The name of the dispatcher
    public func name() -> String {
        Consts.DISPATCHER_NAME
    }

    /// Get the analytcis version of the dispatcher
    ///
    /// - Returns: The version of the dispatcher
    public func version() -> UInt {
        UInt(Consts.DISPATCHER_VERSION)
    }

    /// Send event throught the Piano SDK
    func sendEvent(_ event: Event) {
        pa.sendEvent(event)
    }

    /// Callback fired when a new Batch event is triggered.
    ///
    /// - Parameters:
    ///   - type:  The type of the event
    ///   - payload: The associated payload of the event
    public func dispatchEvent(with type: BatchEventDispatcherType, payload: BatchEventDispatcherPayload) {
        // Dispatch onSiteAds event
        if enableOnSiteAdsEvents && type.shouldBeDispatchedAsOnSiteAd {
            if let onSiteAdsEvent = buildPianoOnSiteAdsEvent(type: type, payload: payload) {
                pianoSenderDelegate?.sendEvent(onSiteAdsEvent)
            }
        }

        // Dispatch custom event if enabled
        if enableCustomEvents {
            let customEvent = buildPianoCustomEvent(type: type, payload: payload)
            pianoSenderDelegate?.sendEvent(customEvent)
        }
    }

    /// Build an On-Site Ads Piano Event from a Batch Event
    /// - Parameters:
    ///   - type: Batch event type
    ///   - payload: Batch event payload
    /// - Returns: The piano event to send
    private func buildPianoOnSiteAdsEvent(type: BatchEventDispatcherType, payload: BatchEventDispatcherPayload) -> Event? {
        guard let eventName = type.pianoOnSiteAdsEventName else {
            return nil
        }

        let eventData = [
            Consts.ON_SITE_TYPE: Consts.ON_SITE_TYPE_PUBLISHER,
            Consts.ON_SITE_ADVERTISER: getSource(payload: payload),
            Consts.ON_SITE_CAMPAIGN: getCampaign(payload: payload),
            Consts.ON_SITE_FORMAT: getMedium(payload: payload, type: type),
        ]

        return Event(eventName, data: eventData)
    }

    /// Build a Piano Custom Event from a Batch Event
    /// - Parameters:
    ///   - type: Batch event type
    ///   - payload: Batch event payload
    /// - Returns: The piano event to send
    private func buildPianoCustomEvent(type: BatchEventDispatcherType, payload: BatchEventDispatcherPayload) -> Event {
        let eventName = type.pianoCustomEventName
        var eventData = [
            Consts.CAMPAIGN: getCampaign(payload: payload),
            Consts.MEDIUM: getMedium(payload: payload, type: type),
            Consts.SOURCE: getSource(payload: payload),
            Consts.SOURCE_FORCE: true,
        ] as [String: Any]
        if let content = getContent(payload: payload) {
            eventData[Consts.CONTENT] = content
        }
        if let trackingId = payload.trackingId {
            eventData[Consts.BATCH_TRACKING_ID] = trackingId
        }
        if BatchEventDispatcher.isMessagingEvent(type) {
            if let webViewAnalyticsId = payload.webViewAnalyticsIdentifier {
                eventData[Consts.BATCH_WEBVIEW_ANALYTICS_ID] = webViewAnalyticsId
            }
        }
        return Event(eventName, data: eventData)
    }

    /// Get the campaign label
    ///
    /// - Parameter payload: Batch event payload
    /// - Returns: The campaign label
    private func getCampaign(payload: BatchEventDispatcherPayload) -> String {
        if let campaign = getTagFromPayload(payload: payload, tag: Consts.AT_CAMPAIGN) {
            return campaign
        } else if let campaign = getTagFromPayload(payload: payload, tag: Consts.UTM_CAMPAIGN), enableUTMTracking {
            return campaign
        } else if let campaign = payload.trackingId {
            return campaign
        }
        return Consts.BATCH_DEFAULT_CAMPAIGN
    }

    /// Get the campaign medium
    ///
    /// - Parameters:
    ///   - payload: Batch event payload
    ///   - type: Batch event type
    /// - Returns: The medium
    private func getMedium(payload: BatchEventDispatcherPayload, type: BatchEventDispatcherType) -> String {
        if let medium = getTagFromPayload(payload: payload, tag: Consts.AT_MEDIUM) {
            return medium
        } else if let medium = getTagFromPayload(payload: payload, tag: Consts.UTM_MEDIUM), enableUTMTracking {
            return medium
        } else if BatchEventDispatcher.isNotificationEvent(type) {
            return Consts.BATCH_FORMAT_PUSH
        }
        return Consts.BATCH_FORMAT_IN_APP
    }

    /// Get the campaign source (UTM tag only or default Batch)
    ///
    /// - Parameter payload: Batch event payload
    /// - Returns: The source
    private func getSource(payload: BatchEventDispatcherPayload) -> String {
        if let source = getTagFromPayload(payload: payload, tag: Consts.UTM_SOURCE), enableUTMTracking {
            return source
        }
        return Consts.BATCH_SRC
    }

    /// Get the campaign content (UTM tag only)
    /// - Parameter payload: Batch event payload
    /// - Returns: The content
    private func getContent(payload: BatchEventDispatcherPayload) -> String? {
        if let source = getTagFromPayload(payload: payload, tag: Consts.UTM_CONTENT), enableUTMTracking {
            return source
        }
        return nil
    }

    /// Get a tag value from a Batch event payload
    ///
    ///  First check in the custom payload of the event else check in the deeplink
    /// - Parameters:
    ///   - payload: Batch event payload
    ///   - tag: Tag to find
    /// - Returns: The value for the tag
    private func getTagFromPayload(payload: BatchEventDispatcherPayload, tag: String) -> String? {
        if let value = payload.customValue(forKey: tag) as? String {
            return value
        }
        return getTagFromDeeplink(payload: payload, tag: tag)
    }

    /// Get a tag value from the deeplink of a Batch event payload
    /// - Parameters:
    ///   - payload: Batch event payload
    ///   - tag: tag in the deeplink
    /// - Returns: The value for the tag
    private func getTagFromDeeplink(payload: BatchEventDispatcherPayload, tag: String) -> String? {
        if let deeplink = payload.deeplink {
            if let url = URL(string: deeplink.trimmingCharacters(in: .whitespacesAndNewlines)),
               let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            {
                // Get values from URL query parameters
                if let value = valueFromComponent(from: components, key: tag) {
                    return value
                }

                // Get values from URL fragment parameters
                if let fragments = dictionaryForURLFragment(components.fragment) {
                    if let value = fragments[tag] {
                        return value
                    }
                }
            }
        }
        return nil
    }

    /// Convert URL fragment to dictionnay
    ///
    /// - Parameter fragment: The URL fragment
    /// - Returns: The dictionnary
    private func dictionaryForURLFragment(_ fragment: String?) -> [String: String]? {
        guard let fragment = fragment else { return nil }

        return fragment.components(separatedBy: "&").reduce(into: [String: String]()) { out, keyValuePair in
            let pairComponents = keyValuePair.components(separatedBy: "=")
            let key = pairComponents.first?.removingPercentEncoding?.lowercased()
            let value = pairComponents.last?.removingPercentEncoding

            if let key = key, let value = value {
                out[key] = value
            }
        }
    }

    /// Helper method to get value from query parameter in an URLComponents
    ///
    /// - Parameters:
    ///   - from: The URLComponents
    ///   - key: key of the value to get
    /// - Returns: The value or nill
    private func valueFromComponent(from: URLComponents, key: String) -> String? {
        return from.queryItems?.first(where: { key.caseInsensitiveCompare($0.name) == .orderedSame })?.value
    }
}

private extension BatchEventDispatcherType {
    /// Get  the Piano event name according to the batch event type
    var pianoCustomEventName: String {
        switch self {
        case .notificationOpen:
            return Consts.NOTIFICATION_OPEN_NAME
        case .messagingShow:
            return Consts.MESSAGING_SHOW_NAME
        case .messagingClose:
            return Consts.MESSAGING_CLOSE_NAME
        case .messagingAutoClose:
            return Consts.MESSAGING_AUTO_CLOSE_NAME
        case .messagingCloseError:
            return Consts.MESSAGING_CLOSE_ERROR_NAME
        case .messagingWebViewClick:
            return Consts.MESSAGING_WEBVIEW_CLICK_NAME
        case .messagingClick:
            return Consts.MESSAGING_CLICK_NAME
        @unknown default:
            return Consts.UNKNOWN_EVENT_NAME
        }
    }

    /// Get the piano event name for an On-site Ad event
    var pianoOnSiteAdsEventName: String? {
        if isPianoImpression {
            return Consts.EVENT_IMPRESSION
        } else if isPianoClick {
            return Consts.EVENT_CLICK
        } else {
            return nil
        }
    }

    /// Indicate if an event type should be dispatched as On-site Ads
    var shouldBeDispatchedAsOnSiteAd: Bool {
        return isPianoImpression || isPianoClick
    }

    /// Whether this kind of Batch event corresponds to a Piano publisher impression event
    var isPianoImpression: Bool {
        switch self {
        case .messagingShow:
            return true
        default:
            return false
        }
    }

    /// Whether this kind of Batch event corresponds to a Piano publisher click event
    var isPianoClick: Bool {
        switch self {
        case .notificationOpen, .messagingClick, .messagingWebViewClick:
            return true
        default:
            return false
        }
    }
}
