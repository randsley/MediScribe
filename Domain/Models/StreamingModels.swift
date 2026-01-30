//
//  StreamingModels.swift
//  MediScribe
//
//  Models for streaming generation updates
//

import Foundation

/// Represents a single token update during streaming generation
struct StreamingTokenUpdate {
    let token: String
    let tokenIndex: Int
    let timestamp: Date
    let accumulatedText: String

    init(token: String, index: Int, accumulated: String) {
        self.token = token
        self.tokenIndex = index
        self.timestamp = Date()
        self.accumulatedText = accumulated
    }
}

/// Streaming state for real-time generation progress
enum StreamingState: Equatable {
    case idle
    case generating
    case validating
    case complete
    case failed(String)

    var isGenerating: Bool {
        if case .generating = self {
            return true
        }
        return false
    }

    var isValidating: Bool {
        if case .validating = self {
            return true
        }
        return false
    }

    var isComplete: Bool {
        if case .complete = self {
            return true
        }
        return false
    }

    static func == (lhs: StreamingState, rhs: StreamingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.generating, .generating), (.validating, .validating), (.complete, .complete):
            return true
        case let (.failed(lMsg), .failed(rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}

/// Progress information for streaming generation
struct StreamingProgress {
    let tokensGenerated: Int
    let estimatedTokensTotal: Int
    let elapsedTime: TimeInterval
    let estimatedTimeRemaining: TimeInterval?

    var percentComplete: Double {
        guard estimatedTokensTotal > 0 else { return 0 }
        return Double(tokensGenerated) / Double(estimatedTokensTotal)
    }
}
