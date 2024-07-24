//
//  Matcha.swift
//  Matcha
//
//  Created by Kyohei Ito on 2018/05/07.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import Foundation

public struct Matcha: Equatable {
    /// value of key
    /// - Parameter key: key of the value you want to retrieve.
    /// - Returns: value of key
    public subscript(_ key: String) -> String? {
        value(of: key)
    }

    /// value of index
    /// - Parameter key: index of the value you want to retrieve.
    /// - Returns: value of index
    public subscript(_ index: Int) -> String? {
        value(at: index)
    }

    private let values: [String: String]
    private let list: [String]
    /// url that is set
    public let url: URL

    /// value of key
    /// - Parameter key: key of the value you want to retrieve.
    /// - Returns: value of key
    public func value(of key: String) -> String? {
        values[key]
    }

    /// value of index
    /// - Parameter key: index of the value you want to retrieve.
    /// - Returns: value of index
    public func value(at index: Int) -> String? {
        list[safe: index]
    }

    public func matched(_ pattern: String) -> Matcha? {
        Matcha(url: url, pattern: pattern)
    }

    /// initialize the matcher
    /// - Parameter url: target url
    public init(url: URL) {
        self.url = url
        self.values = [:]
        self.list = []
    }

    /// initialize the matcher
    /// - Parameter url: target url
    /// - Parameter pattern: url path pattern using `{` and `}`
    ///
    /// e.g.
    /// let url = URL(string: "https://example.com/path/to/glory")!
    /// Matcha(url: url, pattern: "https://example.com/")               // is `nil`
    /// Matcha(url: url, pattern: "https://example.com/path/to/glory")  // is not `nil`
    /// Matcha(url: url, pattern: "/path/to/glory")                     // is not `nil`
    /// Matcha(url: url, pattern: "/{A}/{B}/{C}/")                      // is not `nil`, can access to value
    /// Matcha(url: url, pattern: "/{A}/{B}/{C}/")?.value(at: 1)        // is `to`
    /// Matcha(url: url, pattern: "/{A}/{B}/{C}/")?.value(of: "C")      // is `glory`
    public init?(url: URL, pattern: String) {
        guard let url = url.trailingSlashed else { return nil }
        let isPatternPath = pattern.first == "/"

        guard let patternComponents = URLComponents(string: pattern) else { return nil }

        guard url.host == patternComponents.host || isPatternPath else {
            return nil
        }

        let pathComponents = patternComponents.url?.pathComponents.dropFirst() ?? []

        var regexComponents: [String] = []
        var parameterNames: [String] = []
        for pathComponent in pathComponents {
            if pathComponent.first == "{" && pathComponent.last == "}" {
                let parameterName = String(pathComponent.dropFirst().dropLast())
                regexComponents.append("(?<\(parameterName)>.+)")
                parameterNames.append(parameterName)
            }
            else {
                regexComponents.append(pathComponent)
            }
        }

        let regexPattern = regexComponents.joined(separator: "/")
        let urlPath = url.path

        guard let regex = try? NSRegularExpression(pattern: "/\(regexPattern)$"),
              let match = regex.firstMatch(in: urlPath) else { return nil }

        var values: [String: String] = [:]
        var list: [String] = []
        for parameterName in parameterNames {
            guard let range = match.range(withName: parameterName, in: urlPath) else { continue }
            let value = String(urlPath[range])
            values[parameterName] = value
            list.append(value)
        }

        self.url = url
        self.values = values
        self.list = list
    }
}

private extension NSTextCheckingResult {
    func range(withName name: String, in string: String) -> Range<String.Index>? {
        Range(range(withName: name), in: string)
    }
}

private extension URL {
    var trailingSlashed: URL? {
        absoluteString.hasSuffix("/") ? self : URL(string: absoluteString + "/")
    }
}
