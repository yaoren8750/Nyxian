//
//  Server+TLS.swift
//  feather
//
//  Created by samara on 22.08.2024.
//  Copyright © 2024 Lakr Aream. All Rights Reserved.
//  ORIGINALLY LICENSED UNDER GPL-3.0, MODIFIED FOR USE FOR FEATHER
//

import Foundation
import NIOSSL

///
/// AHA the Installer uses server.pem and server.cert and commonName.txt
///
extension Installer {
    ///
    /// Getting the SNI to tell later on to what we wanna connect
    ///
    static let sni: String = (try? String(contentsOfFile: URL(fileURLWithPath: "\(NSHomeDirectory())/tmp/.cert/commonName.txt").path, encoding: .utf8)) ?? ""
    static let documentsKeyURL = URL(fileURLWithPath: "\(NSHomeDirectory())/tmp/.cert/server.pem")
    static let documentsCrtURL = URL(fileURLWithPath: "\(NSHomeDirectory())/tmp/.cert/server.crt")

    ///
    /// here we go setting up TLS
    ///
    static func setupTLS() throws -> TLSConfiguration {
        let keyURL = documentsKeyURL
        let crtURL = documentsCrtURL
        
        return try TLSConfiguration.makeServerConfiguration(
            certificateChain: NIOSSLCertificate
                .fromPEMFile(crtURL.path)
                .map { NIOSSLCertificateSource.certificate($0) },
            privateKey: .privateKey(try NIOSSLPrivateKey(file: keyURL.path, format: .pem)))
    }
}
