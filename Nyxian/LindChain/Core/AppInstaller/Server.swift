//
//  Server.swift
//  feather
//
//  Created by samara on 22.08.2024.
//  Copyright © 2024 Lakr Aream. All Rights Reserved.
//  ORIGINALLY LICENSED UNDER GPL-3.0, MODIFIED FOR USE FOR FEATHER
//

import Foundation
import Vapor
import NIOSSL
import NIOTLS
import UIKit

struct AppData {
    public var id: String
    public var version: Int
    public var name: String
}

class Installer: Identifiable, ObservableObject {
    let id: UUID
    let app: Application
    var package: URL
    let port = Int.random(in: 4000 ... 8000)
    let metadata: AppData
    let image: UIImage?
    
    var onCompletion: () -> Void = {}
    
    enum Status: Equatable {
        case ready
        case sendingManifest
        case sendingPayload
        case completed
    }
    
    var status: Status = .ready

    var needsShutdown = false
    
    init(
        path packagePath: URL?,
        metadata: AppData,
        image: UIImage?
    ) throws {
        let id: UUID = .init()
        self.id = id
        self.metadata = metadata
        self.package = packagePath ?? URL(fileURLWithPath: "")
        self.image = image
        
        app = try Self.setupApp(port: port)

        app.get("*") { [weak self] req in
            guard let self else { return Response(status: .badGateway) }

            switch req.url.path {
            case plistEndpoint.path:
                DispatchQueue.main.async { self.status = .sendingManifest }
                return Response(status: .ok, version: req.version, headers: [
                    "Content-Type": "text/xml",
                ], body: .init(data: installManifestData))
            case displayImageSmallEndpoint.path:
                DispatchQueue.main.async { self.status = .sendingManifest }
                return Response(status: .ok, version: req.version, headers: [
                    "Content-Type": "image/png",
                ], body: .init(data: displayImageSmallData))
            case displayImageLargeEndpoint.path:
                DispatchQueue.main.async { self.status = .sendingManifest }
                return Response(status: .ok, version: req.version, headers: [
                    "Content-Type": "image/png",
                ], body: .init(data: displayImageLargeData))
            case payloadEndpoint.path:
                DispatchQueue.main.async {
                    self.status = .sendingPayload
                }
                return req.fileio.streamFile(
                    at: self.package.path
                ) { result in
                    DispatchQueue.main.async {
                        self.status = .completed
                        self.onCompletion()
                    }
                }
            default:
                return Response(status: .notFound)
            }
        }

        try app.server.start()
        needsShutdown = true
    }
    
    deinit {
        shutdownServer()
    }

    func shutdownServer() {
        if needsShutdown {
            needsShutdown = false
            app.server.shutdown()
            app.shutdown()
        }
    }
    
    func installCompletionHandler(handler: @escaping () -> Void) {
        self.onCompletion = handler
    }
}

extension Installer {
    private static let env: Environment = {
        var env = try! Environment.detect()
        try! LoggingSystem.bootstrap(from: &env)
        return env
    }()

    static func setupApp(port: Int) throws -> Application {
        let app = Application(env)

        app.threadPool = .init(numberOfThreads: 1)
        app.http.server.configuration.tlsConfiguration = try Self.setupTLS()
        app.http.server.configuration.hostname = Self.sni
        app.http.server.configuration.tcpNoDelay = true
        app.http.server.configuration.address = .hostname("0.0.0.0", port: port)
        app.http.server.configuration.port = port
        app.routes.defaultMaxBodySize = "128mb"
        app.routes.caseInsensitive = false

        return app
    }
}
