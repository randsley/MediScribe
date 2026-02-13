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
