import Foundation
import Testing
@testable import KayucoCore

private let t0 = Date(timeIntervalSince1970: 1_793_000_000)
private let enc = KayucoWire.makeEncoder()
private let dec = KayucoWire.makeDecoder()

private func clientHello(_ v: Int, _ env: BuildEnvironment = .prod) -> ClientHello {
    ClientHello(protocolVersion: v, client: ClientInfo(id: "c1", kind: .iphone, appVersion: "1.0", environment: env))
}
private func hostHello(_ v: Int, min: Int, _ env: BuildEnvironment = .prod) -> HostHello {
    HostHello(protocolVersion: v, minClient: min, host: HostInfo(id: "h1", name: "Mac", appVersion: "1.0", environment: env))
}
private func json<T: Encodable>(_ v: T) throws -> String {
    String(decoding: try enc.encode(v), as: UTF8.self)
}
private func roundTrip<T: Codable & Equatable>(_ v: T) throws -> Bool {
    try dec.decode(T.self, from: enc.encode(v)) == v
}

private let session = Session(id: "s1", agent: "opencode", title: nil, workingDirectory: "/tmp",
                              state: .running, createdAt: t0, updatedAt: t0)
private let request = ToolApprovalRequest(
    id: "a1", sessionID: "s1", toolName: "bash", summary: "ls",
    options: [PermissionOption(id: "o1", name: "Allow", kind: .allowOnce),
              PermissionOption(id: "o2", name: "Reject", kind: .rejectAlways)],
    requestedAt: t0)

@Suite("Protocolo handshake")
struct ProtocoloHandshakeTests {
    @Test func compatibleNegotiatesMinimum() {
        #expect(Handshake.evaluate(client: clientHello(3), host: hostHello(2, min: 1)) == .compatible(negotiated: 2))
        #expect(Handshake.evaluate(client: clientHello(1), host: hostHello(2, min: 1)) == .compatible(negotiated: 1))
    }

    @Test func clientMustUpdate() {
        #expect(Handshake.evaluate(client: clientHello(1), host: hostHello(3, min: 2)) == .clientMustUpdate(minClient: 2))
    }

    @Test func environmentMismatchComesFirst() {
        #expect(Handshake.evaluate(client: clientHello(1, .dev), host: hostHello(3, min: 2, .prod))
            == .environmentMismatch(client: .dev, host: .prod))
    }

    @Test func goldenHostHello() throws {
        let raw = #"{"protocol":1,"minClient":1,"host":{"id":"h1","name":"Mac","appVersion":"1.0","environment":"dev"},"extra":true}"#
        let h = try dec.decode(HostHello.self, from: Data(raw.utf8))
        #expect(h == hostHello(1, min: 1, .dev))
        let out = try json(h)
        #expect(out.contains(#""protocol":1"#))
        #expect(!out.contains("protocolVersion"))
    }

    @Test func currentVersions() {
        #expect(KayucoProtocol.current == 1)
        #expect(KayucoProtocol.minClient == 1)
    }
}

@Suite("Protocolo cable")
struct ProtocoloWireTests {
    @Test func hostMessagesRoundTrip() throws {
        let decision = ToolApprovalDecision(requestID: "a1", outcome: .selected(optionID: "o1"), decidedBy: "c1", decidedAt: t0)
        let msgs: [HostMessage] = [
            .hello(hostHello(1, min: 1)),
            .sessionUpdated(session),
            .message(Message(id: "m1", sessionID: "s1", role: .agent, text: "hola", createdAt: t0)),
            .approvalRequested(request),
            .approvalResolved(decision),
            .unknown(type: "futuro"),
        ]
        for m in msgs { #expect(try roundTrip(m), "\(m)") }
    }

    @Test func clientMessagesRoundTrip() throws {
        let msgs: [ClientMessage] = [
            .hello(clientHello(1)),
            .sendPrompt(PromptRequest(sessionID: "s1", text: "hola")),
            .decideApproval(ToolApprovalDecision(requestID: "a1", outcome: .cancelled, decidedBy: "c1", decidedAt: t0)),
            .unknown(type: "futuro"),
        ]
        for m in msgs { #expect(try roundTrip(m), "\(m)") }
    }

    @Test func envelopeShape() throws {
        let s = try json(ClientMessage.sendPrompt(PromptRequest(sessionID: "s1", text: "x")))
        #expect(s == #"{"payload":{"sessionID":"s1","text":"x"},"type":"sendPrompt"}"#)
    }

    @Test func unknownTypeIgnoresPayload() throws {
        let raw = #"{"type":"nuevo","payload":{"cualquier":["cosa"]}}"#
        #expect(try dec.decode(HostMessage.self, from: Data(raw.utf8)) == .unknown(type: "nuevo"))
        #expect(try dec.decode(ClientMessage.self, from: Data(raw.utf8)) == .unknown(type: "nuevo"))
        #expect(try json(HostMessage.unknown(type: "nuevo")) == #"{"type":"nuevo"}"#)
    }

    @Test func extraFieldsAreIgnored() throws {
        let raw = #"{"type":"sessionUpdated","extra":1,"payload":{"id":"s1","agent":"opencode","workingDirectory":"/tmp","state":"running","createdAt":"2026-10-25T21:33:20Z","updatedAt":"2026-10-25T21:33:20Z","nuevo":{"a":1}}}"#
        let m = try dec.decode(HostMessage.self, from: Data(raw.utf8))
        guard case .sessionUpdated(let s) = m else { Issue.record("tipo incorrecto"); return }
        #expect(s.id == "s1" && s.title == nil)
    }

    @Test func idsEncodeAsPlainStrings() throws {
        #expect(try json(SessionID(rawValue: "s1")) == #""s1""#)
        #expect(try json(MessageID(rawValue: "m1")) == #""m1""#)
        #expect(try json(ApprovalID(rawValue: "a1")) == #""a1""#)
        #expect(try dec.decode(SessionID.self, from: Data(#""zz""#.utf8)).rawValue == "zz")
    }
}

@Suite("Protocolo enums abiertos")
struct ProtocoloOpenEnumTests {
    private func check<T: OpenStringEnum>(_ type: T.Type, raw: String, known: T) throws {
        let value = try dec.decode(T.self, from: Data("\"\(raw)\"".utf8))
        #expect(value == known)
        #expect(try json(value) == "\"\(raw)\"")
    }

    private func unknown<T: OpenStringEnum>(_ type: T.Type) throws {
        let value = try dec.decode(T.self, from: Data(#""algo_nuevo""#.utf8))
        #expect(value.rawValue == "algo_nuevo")
        #expect(try json(value) == #""algo_nuevo""#)
        #expect(value == T(rawValue: "algo_nuevo"))
    }

    @Test func knownValues() throws {
        try check(DeviceKind.self, raw: "watch", known: .watch)
        try check(SessionState.self, raw: "awaitingApproval", known: .awaitingApproval)
        try check(MessageRole.self, raw: "system", known: .system)
        try check(PermissionOptionKind.self, raw: "allow_once", known: .allowOnce)
        try check(PermissionOptionKind.self, raw: "allow_always", known: .allowAlways)
        try check(PermissionOptionKind.self, raw: "reject_once", known: .rejectOnce)
        try check(PermissionOptionKind.self, raw: "reject_always", known: .rejectAlways)
    }

    @Test func unknownValuesSurvive() throws {
        try unknown(DeviceKind.self)
        try unknown(SessionState.self)
        try unknown(MessageRole.self)
        try unknown(PermissionOptionKind.self)
    }

    @Test func unknownStateInsideSession() throws {
        let raw = #"{"id":"s1","agent":"x","workingDirectory":"/","state":"paused","createdAt":"2026-10-25T21:33:20Z","updatedAt":"2026-10-25T21:33:20Z"}"#
        let s = try dec.decode(Session.self, from: Data(raw.utf8))
        #expect(s.state == .unknown("paused"))
        #expect(try json(s).contains(#""state":"paused""#))
    }
}

@Suite("Protocolo aprobaciones")
struct ProtocoloApprovalTests {
    @Test func decideValidOption() throws {
        let d = try request.decide(optionID: "o1", by: "c1", at: t0)
        #expect(d == ToolApprovalDecision(requestID: "a1", outcome: .selected(optionID: "o1"), decidedBy: "c1", decidedAt: t0))
    }

    @Test func decideInvalidOption() {
        #expect(throws: ProtocolError.unknownOption("zzz")) {
            try request.decide(optionID: "zzz", by: "c1", at: t0)
        }
    }

    @Test func cancel() {
        let d = request.cancel(by: "c2", at: t0)
        #expect(d.outcome == .cancelled && d.requestID == "a1" && d.decidedBy == "c2")
    }

    @Test func outcomeJSON() throws {
        #expect(try json(ToolApprovalOutcome.selected(optionID: "o1")) == #"{"optionID":"o1","outcome":"selected"}"#)
        #expect(try json(ToolApprovalOutcome.cancelled) == #"{"outcome":"cancelled"}"#)
        #expect(try roundTrip(ToolApprovalOutcome.selected(optionID: "o1")))
        #expect(try roundTrip(ToolApprovalOutcome.cancelled))
    }

    @Test func unknownOutcomeThrows() {
        #expect(throws: DecodingError.self) {
            try dec.decode(ToolApprovalOutcome.self, from: Data(#"{"outcome":"timeout"}"#.utf8))
        }
    }
}
