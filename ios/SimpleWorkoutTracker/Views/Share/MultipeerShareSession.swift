import Foundation
import MultipeerConnectivity

enum ShareState: Equatable {
    case idle
    case selectingTemplates
    case browsing
    case advertising
    case connecting(peerName: String)
    case transferring(progress: Float)
    case reviewingImport(json: String)
    case complete(message: String)
    case error(message: String)
}

enum ShareRole {
    case send, receive
}

@MainActor
final class MultipeerShareSession: NSObject, ObservableObject {
    @Published var state: ShareState = .idle
    @Published var importSummary: ImportSummary?

    private let serviceType = "owt-share"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession?
    private var browser: MCNearbyServiceBrowser?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var role: ShareRole?
    private var pendingJson: String?

    func promptSend() {
        state = .selectingTemplates
    }

    func startSending(selectedTemplateIds: Set<Int64>) {
        role = .send
        let fullJson = SwtBridge.shared.exportToJson()
        pendingJson = filterExportJson(fullJson, selectedTemplateIds: selectedTemplateIds)
        state = .browsing
        startBrowsing()
    }

    func startReceiving() {
        role = .receive
        state = .advertising
        startAdvertising()
    }

    func confirmImport(_ json: String) {
        let result = SwtBridge.shared.importFromJson(json: json)
        state = .complete(message: result)
    }

    func cancel() {
        cleanup()
        state = .idle
        importSummary = nil
    }

    func reset() {
        state = .idle
        importSummary = nil
    }

    // MARK: - Multipeer

    private func makeSession() -> MCSession {
        let s = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        s.delegate = self
        session = s
        return s
    }

    private func startBrowsing() {
        let s = makeSession()
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        _ = s
    }

    private func startAdvertising() {
        let s = makeSession()
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        _ = s
    }

    private func sendData(to peer: MCPeerID) {
        guard let json = pendingJson, let session else {
            state = .error(message: "No data to send")
            return
        }

        state = .transferring(progress: 0)

        guard let data = json.data(using: .utf8) else {
            state = .error(message: "Could not encode data")
            return
        }

        do {
            try session.send(data, toPeers: [peer], with: .reliable)
            state = .complete(message: "Data sent successfully")
        } catch {
            state = .error(message: "Send failed: \(error.localizedDescription)")
        }

        cleanup()
    }

    private func cleanup() {
        browser?.stopBrowsingForPeers()
        browser = nil
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        session?.disconnect()
        session = nil
        role = nil
        pendingJson = nil
    }

    // MARK: - JSON Filtering

    private func filterExportJson(_ fullJson: String, selectedTemplateIds: Set<Int64>) -> String {
        guard let data = fullJson.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let templates = root["templates"] as? [[String: Any]],
              let exercises = root["exercises"] as? [[String: Any]] else {
            return fullJson
        }

        var referencedExerciseIds = Set<Int64>()
        let filteredTemplates = templates.filter { t in
            guard let id = t["id"] as? Int64, selectedTemplateIds.contains(id) else { return false }
            if let sets = t["sets"] as? [[String: Any]] {
                for s in sets {
                    if let eid = s["exerciseId"] as? Int64 {
                        referencedExerciseIds.insert(eid)
                    }
                }
            }
            return true
        }

        let filteredExercises = exercises.filter { e in
            guard let id = e["id"] as? Int64 else { return false }
            return referencedExerciseIds.contains(id)
        }

        var result: [String: Any] = [:]
        result["exercises"] = filteredExercises
        result["templates"] = filteredTemplates

        guard let jsonData = try? JSONSerialization.data(withJSONObject: result),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return fullJson
        }
        return jsonString
    }
}

// MARK: - MCSessionDelegate

extension MultipeerShareSession: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                if self.role == .send {
                    self.sendData(to: peerID)
                }
            case .notConnected:
                if case .transferring = self.state {
                    self.state = .error(message: "Peer disconnected during transfer")
                }
            case .connecting:
                self.state = .connecting(peerName: peerID.displayName)
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            guard let json = String(data: data, encoding: .utf8) else {
                self.state = .error(message: "Could not decode received data")
                return
            }

            if let summary = SwtBridge.shared.previewImport(json: json) {
                self.importSummary = summary
                self.state = .reviewingImport(json: json)
            } else {
                self.state = .error(message: "Could not parse received data")
            }
            self.cleanup()
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerShareSession: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            guard let session = self.session else { return }
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            self.state = .error(message: "Could not search for devices: \(error.localizedDescription)")
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerShareSession: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            invitationHandler(true, self.session)
            self.state = .connecting(peerName: peerID.displayName)
        }
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in
            self.state = .error(message: "Could not advertise: \(error.localizedDescription)")
        }
    }
}
