//
//  Session.swift
//  AuroraEditorModules/GitAccounts
//
//  Created by Nanashi Li on 2022/03/31.
//
// This file should be strictly just be used for Accounts since it's not
// built for any other networking except those of git accounts

import Foundation

// TODO: DOCS (Nanashi Li)
public protocol GitURLSession {

    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTaskProtocol

    func uploadTask(
        with request: URLRequest,
        fromData bodyData: Data?,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol

#if !canImport(FoundationNetworking)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func data(for request: URLRequest,
              delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func upload(for request: URLRequest,
                from bodyData: Data,
                delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
#endif
}

public protocol URLSessionDataTaskProtocol {
    func resume()
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

extension URLSession: GitURLSession {

    public func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTaskProtocol {
            (dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask)
        }

    public func uploadTask(
        with request: URLRequest,
        fromData bodyData: Data?,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
            uploadTask(with: request, from: bodyData, completionHandler: completionHandler)
        }
}
