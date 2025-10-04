import Flutter
import UIKit
import FoundationModels

public class FlutterAppleLlmPlugin: NSObject, FlutterPlugin, FlutterAppleLlmApi {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let binaryMessenger = registrar.messenger()
        let instance = FlutterAppleLlmPlugin()
        FlutterAppleLlmApiSetup.setUp(binaryMessenger: binaryMessenger, api: instance)
        OnResponseStreamHandler.register(with: binaryMessenger, streamHandler: instance.streamHandler)
    }

    private var sessions = [String: LanguageModelSession]()

    private var streamHandler = OnResponseStreamHandlerImpl()

    func isAvailable() throws -> Bool {
        return SystemLanguageModel.default.isAvailable
    }

    func createSession(instructions: String?) throws -> String {
        let session = LanguageModelSession(instructions: instructions)
        let id = UUID().uuidString
        self.sessions[id] = session
        return id
    }

    func respond(modelId: String, content: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let session = self.sessions[modelId] else {
            completion(.failure(PigeonError(code: "-1", message: "Session not found", details: nil)))
            return
        }
        
        Task {
            do {
                try await self.response(session, modelId, content)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func response(_ session: LanguageModelSession, _ modelId: String, _ content: String) async throws {
        let stream = session.streamResponse(to: content)
        for try await message in stream {
            if Task.isCancelled { break }

            let content = message.content
            await MainActor.run {
                self.streamHandler.sink?.success(Message(modelId: modelId, content: content))
            }
        }
    }

    func deleteSession(sessionId: String) throws {
        self.sessions.removeValue(forKey: sessionId)
    }
}

class OnResponseStreamHandlerImpl: OnResponseStreamHandler {
    var sink: PigeonEventSink<Message>?
    
    override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<Message>) {
        self.sink = sink
    }
}
