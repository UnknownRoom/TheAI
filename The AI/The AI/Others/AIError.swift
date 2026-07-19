//
//  AIError.swift
//  The AI
//
//  Created by 梓墨 on 2026/3/19.
//

import SwiftUI

enum AIError: Error{
    case invalidURL
    case networkError(Error)
    case authenticationFailed
    case rateLimitReached
    case decodingError
}
