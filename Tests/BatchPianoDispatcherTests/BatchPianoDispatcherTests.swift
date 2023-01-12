import Batch
import InstantMock
import PianoAnalytics
import XCTest

@testable import BatchPianoDispatcher

final class BatchPianoDispatcherTests: XCTestCase {
    var dispatcher: BatchPianoDispatcher!
    var pianoEventSenderMock: PianoEventSenderMock!

    override func setUp() {
        super.setUp()
        pianoEventSenderMock = PianoEventSenderMock()
        dispatcher = BatchPianoDispatcher.instance
        dispatcher.enableUTMTracking = true
        dispatcher.pianoSenderDelegate = pianoEventSenderMock
    }

    override func tearDown() {
        pianoEventSenderMock = nil
        dispatcher = nil
    }

    func testPushNoDataWithtoutCustomEvent() {
        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "Batch",
            "onsitead_campaign": "batch-default-campaign",
            "onsitead_format": "push",
        ])
        expectSend(event: expected)
        dispatcher.dispatchEvent(with: .notificationOpen, payload: PayloadMock())
        verify()
    }

    func testPushNoDataWithtCustomEvent() {
        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "Batch",
            "onsitead_campaign": "batch-default-campaign",
            "onsitead_format": "push",
        ])
        let expected2 = Event("batch_notification_open", data: [
            "src_campaign": "batch-default-campaign",
            "src_medium": "push",
            "src_source": "Batch",
            "src_force": true,
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .notificationOpen, payload: PayloadMock())
        verify()
    }

    func testNotificationDeeplinkQueryVars() {
        let testPayload = PayloadMock()
        testPayload.deeplink = "https://batch.com?utm_source=batchsdk&utm_medium=push-batch&utm_campaign=something&utm_content=button1"

        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "batchsdk",
            "onsitead_campaign": "something",
            "onsitead_format": "push-batch",
        ])
        let expected2 = Event("batch_notification_open", data: [
            "src_campaign": "something",
            "src_medium": "push-batch",
            "src_source": "batchsdk",
            "src_force": true,
            "src_content": "button1",
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .notificationOpen, payload: testPayload)
        verify()
    }

    func testNotificationDeeplinkQueryVarsEncode() {
        let testPayload = PayloadMock()
        testPayload.deeplink = "https://batch.com?utm_source=%5Bbatchsdk%5D&utm_medium=push-batch&utm_campaign=something&utm_content=button1"

        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "[batchsdk]",
            "onsitead_campaign": "something",
            "onsitead_format": "push-batch",
        ])
        let expected2 = Event("batch_notification_open", data: [
            "src_campaign": "something",
            "src_medium": "push-batch",
            "src_source": "[batchsdk]",
            "src_force": true,
            "src_content": "button1",
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .notificationOpen, payload: testPayload)
        verify()
    }

    func testNotificationDeeplinkFragmentVars() {
        let testPayload = PayloadMock()
        testPayload.deeplink = "https://batch.com#utm_source=batch-sdk&utm_medium=pushbatch01&utm_campaign=154879548754&utm_content=notif001"

        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "batch-sdk",
            "onsitead_campaign": "154879548754",
            "onsitead_format": "pushbatch01",
        ])
        let expected2 = Event("batch_notification_open", data: [
            "src_campaign": "154879548754",
            "src_medium": "pushbatch01",
            "src_source": "batch-sdk",
            "src_force": true,
            "src_content": "notif001",
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .notificationOpen, payload: testPayload)
        verify()
    }

    func testNotificationDeeplinkFragmentVarsWithoutUTMTracking() {
        let testPayload = PayloadMock()
        testPayload.deeplink = "https://batch.com#utm_source=batch-sdk&utm_medium=pushbatch01&utm_campaign=154879548754&utm_content=notif001"

        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "Batch",
            "onsitead_campaign": "batch-default-campaign",
            "onsitead_format": "push",
        ])
        let expected2 = Event("batch_notification_open", data: [
            "src_campaign": "batch-default-campaign",
            "src_medium": "push",
            "src_source": "Batch",
            "src_force": true,
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.enableUTMTracking = false
        dispatcher.dispatchEvent(with: .notificationOpen, payload: testPayload)
        verify()
    }

    func testNotificationDeeplinkNonTrimmed() {
        let testPayload = PayloadMock()
        testPayload.deeplink = "    \n     https://batch.com#utm_source=batch-sdk&utm_medium=pushbatch01&utm_campaign=154879548754&utm_content=notif001     \n    "

        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "batch-sdk",
            "onsitead_campaign": "154879548754",
            "onsitead_format": "pushbatch01",
        ])
        let expected2 = Event("batch_notification_open", data: [
            "src_campaign": "154879548754",
            "src_medium": "pushbatch01",
            "src_source": "batch-sdk",
            "src_force": true,
            "src_content": "notif001",
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .notificationOpen, payload: testPayload)
        verify()
    }

    func testNotificationDeeplinkFragmentVarsEncode() {
        let testPayload = PayloadMock()
        testPayload.deeplink = "https://batch.com/test#utm_source=%5Bbatch-sdk%5D&utm_medium=pushbatch01&utm_campaign=154879548754&utm_content=notif001"

        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "[batch-sdk]",
            "onsitead_campaign": "154879548754",
            "onsitead_format": "pushbatch01",
        ])
        let expected2 = Event("batch_notification_open", data: [
            "src_campaign": "154879548754",
            "src_medium": "pushbatch01",
            "src_source": "[batch-sdk]",
            "src_force": true,
            "src_content": "notif001",
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .notificationOpen, payload: testPayload)
        verify()
    }

    func testNotificationCustomPayload() {
        let testPayload = PayloadMock()
        testPayload.deeplink = "https://batch.com#utm_source=batch-sdk&utm_medium=pushbatch01&utm_campaign=154879548754&utm_content=notif001"
        testPayload.customPayload = [
            "utm_medium": "654987",
            "utm_source": "jesuisuntest",
            "utm_campaign": "testest",
            "utm_content": "allo118218",
        ] as [AnyHashable: AnyObject]

        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "jesuisuntest",
            "onsitead_campaign": "testest",
            "onsitead_format": "654987",
        ])
        let expected2 = Event("batch_notification_open", data: [
            "src_campaign": "testest",
            "src_medium": "654987",
            "src_source": "jesuisuntest",
            "src_force": true,
            "src_content": "allo118218",
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .notificationOpen, payload: testPayload)
        verify()
    }

    func testNotificationDeeplinkPriority() {
        let testPayload = PayloadMock()
        testPayload.deeplink = "https://batch.com?utm_source=batchsdk&utm_campaign=something#utm_source=batch-sdk&utm_medium=pushbatch01&utm_campaign=154879548754&utm_content=notif001"
        testPayload.customPayload = [
            "utm_medium": "654987",
        ] as [AnyHashable: AnyObject]

        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "batchsdk",
            "onsitead_campaign": "something",
            "onsitead_format": "654987",
        ])
        let expected2 = Event("batch_notification_open", data: [
            "src_campaign": "something",
            "src_medium": "654987",
            "src_source": "batchsdk",
            "src_force": true,
            "src_content": "notif001",
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .notificationOpen, payload: testPayload)
        verify()
    }

    func testInAppNoDataWithtoutCustomEvent() {
        let expected = Event("publisher.impression", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "Batch",
            "onsitead_campaign": "batch-default-campaign",
            "onsitead_format": "in-app",
        ])
        expectSend(event: expected)
        dispatcher.dispatchEvent(with: .messagingShow, payload: PayloadMock())
        verify()
    }

    func testInAppNoDataWithtCustomEvent() {
        let expected = Event("publisher.impression", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "Batch",
            "onsitead_campaign": "batch-default-campaign",
            "onsitead_format": "in-app",
        ])
        let expected2 = Event("batch_in_app_show", data: [
            "src_campaign": "batch-default-campaign",
            "src_medium": "in-app",
            "src_source": "Batch",
            "src_force": true,
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .messagingShow, payload: PayloadMock())
        verify()
    }

    func testInAppTrackingID() {
        let testPayload = PayloadMock()
        testPayload.trackingId = "jesuisuntrackingid"

        let expected = Event("publisher.impression", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "Batch",
            "onsitead_campaign": "jesuisuntrackingid",
            "onsitead_format": "in-app",
        ])
        let expected2 = Event("batch_in_app_show", data: [
            "src_campaign": "jesuisuntrackingid",
            "src_medium": "in-app",
            "src_source": "Batch",
            "src_force": true,
            "batch_tracking_id": "jesuisuntrackingid",
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .messagingShow, payload: testPayload)
        verify()
    }

    func testInAppDeeplinkContentQueryVars() {
        let testPayload = PayloadMock()
        testPayload.deeplink = "https://batch.com/test-ios?utm_content=something"

        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "Batch",
            "onsitead_campaign": "batch-default-campaign",
            "onsitead_format": "in-app",
        ])
        let expected2 = Event("batch_in_app_click", data: [
            "src_campaign": "batch-default-campaign",
            "src_medium": "in-app",
            "src_source": "Batch",
            "src_force": true,
            "src_content": "something",
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .messagingClick, payload: testPayload)
        verify()
    }

    func testInAppDeeplinkContentQueryVarsUppercase() {
        let testPayload = PayloadMock()
        testPayload.deeplink = "https://batch.com/test-ios?UtM_coNTEnt=something"

        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "Batch",
            "onsitead_campaign": "batch-default-campaign",
            "onsitead_format": "in-app",
        ])
        let expected2 = Event("batch_in_app_click", data: [
            "src_campaign": "batch-default-campaign",
            "src_medium": "in-app",
            "src_source": "Batch",
            "src_force": true,
            "src_content": "something",
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .messagingClick, payload: testPayload)
        verify()
    }

    func testInAppDeeplinkFragmentQueryVars() {
        let testPayload = PayloadMock()
        testPayload.deeplink = "https://batch.com/test-ios#utm_content=something"

        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "Batch",
            "onsitead_campaign": "batch-default-campaign",
            "onsitead_format": "in-app",
        ])
        let expected2 = Event("batch_in_app_click", data: [
            "src_campaign": "batch-default-campaign",
            "src_medium": "in-app",
            "src_source": "Batch",
            "src_force": true,
            "src_content": "something",
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .messagingClick, payload: testPayload)
        verify()
    }

    func testInAppDeeplinkFragmentQueryVarsUppercase() {
        let testPayload = PayloadMock()
        testPayload.deeplink = "https://batch.com/test-ios#uTm_CoNtEnT=something"

        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "Batch",
            "onsitead_campaign": "batch-default-campaign",
            "onsitead_format": "in-app",
        ])
        let expected2 = Event("batch_in_app_click", data: [
            "src_campaign": "batch-default-campaign",
            "src_medium": "in-app",
            "src_source": "Batch",
            "src_force": true,
            "src_content": "something",
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .messagingClick, payload: testPayload)
        verify()
    }

    func testInAppDeeplinkContentPriority() {
        let testPayload = PayloadMock()
        testPayload.deeplink = "https://batch.com/test-ios?utm_content=testprio#utm_content=something"

        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "Batch",
            "onsitead_campaign": "batch-default-campaign",
            "onsitead_format": "in-app",
        ])
        let expected2 = Event("batch_in_app_click", data: [
            "src_campaign": "batch-default-campaign",
            "src_medium": "in-app",
            "src_source": "Batch",
            "src_force": true,
            "src_content": "testprio",
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .messagingClick, payload: testPayload)
        verify()
    }

    func testInAppWebViewClickAnalyticsIdentifier() {
        let testPayload = PayloadMock()
        testPayload.webViewAnalyticsIdentifier = "test1234"

        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "Batch",
            "onsitead_campaign": "batch-default-campaign",
            "onsitead_format": "in-app",
        ])
        let expected2 = Event("batch_in_app_webview_click", data: [
            "src_campaign": "batch-default-campaign",
            "src_medium": "in-app",
            "src_source": "Batch",
            "src_force": true,
            "batch_webview_analytics_id": "test1234",
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .messagingWebViewClick, payload: testPayload)
        verify()
    }

    func testInAppDeeplinkAT() {
        let testPayload = PayloadMock()
        testPayload.deeplink = "https://batch.com/test-ios?at_campaign=campaign-label&at_medium=email"

        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "Batch",
            "onsitead_campaign": "campaign-label",
            "onsitead_format": "email",
        ])
        let expected2 = Event("batch_in_app_click", data: [
            "src_campaign": "campaign-label",
            "src_medium": "email",
            "src_source": "Batch",
            "src_force": true,
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .messagingClick, payload: testPayload)
        verify()
    }

    func testInAppPayloadAT() {
        let testPayload = PayloadMock()
        testPayload.trackingId = "batchTrackingId"
        testPayload.customPayload = [
            "at_medium": "654987",
            "at_campaign": "testest",
        ] as [AnyHashable: AnyObject]

        let expected = Event("publisher.click", data: [
            "onsitead_type": "Publisher",
            "onsitead_advertiser": "Batch",
            "onsitead_campaign": "testest",
            "onsitead_format": "654987",
        ])
        let expected2 = Event("batch_in_app_click", data: [
            "src_campaign": "testest",
            "src_medium": "654987",
            "src_source": "Batch",
            "src_force": true,
            "batch_tracking_id": "batchTrackingId",
        ])
        expectSend(event: expected)
        expectSend(event: expected2)
        dispatcher.enableCustomEvents = true
        dispatcher.dispatchEvent(with: .messagingClick, payload: testPayload)
        verify()
    }

    func expectSend(event: Event) {
        pianoEventSenderMock.expect().call(
            pianoEventSenderMock.sendEvent(Arg.eq(event))
        )
    }

    func verify() {
        pianoEventSenderMock.verify()
    }
}

class PianoEventSenderMock: Mock, BatchPianoEventSenderDelegate {
    func sendEvent(_ event: Event) {
        super.call(event)
    }
}

extension Event: MockUsable {
    private static let any = Event("test", data: [:])

    public static var anyValue: InstantMock.MockUsable {
        return Event.any
    }

    public func equal(to: InstantMock.MockUsable?) -> Bool {
        guard let value = to as? Event else {
            return false
        }
        return name == value.name && NSDictionary(dictionary: data).isEqual(to: value.data)
    }
}

class PayloadMock: BatchEventDispatcherPayload {
    var webViewAnalyticsIdentifier: String?

    var trackingId: String?

    var deeplink: String?

    var isPositiveAction: Bool = false

    var sourceMessage: BatchMessage?

    var notificationUserInfo: [AnyHashable: Any]?

    var customPayload: [AnyHashable: AnyObject]?

    func customValue(forKey key: String) -> NSObject? {
        return customPayload?[key] as? NSObject
    }
}
