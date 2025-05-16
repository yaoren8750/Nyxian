/*
 Copyright (C) 2025 SeanIsTethered
 Copyright (C) 2025 Lindsey

 This file is part of Nyxian.

 FridaCodeManager is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 FridaCodeManager is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with FridaCodeManager. If not, see <https://www.gnu.org/licenses/>.
*/

import Foundation
import UIKit

///
/// Certblob structure that holds the coded values of a `.certblob`
///
struct CertBlob: Codable, Identifiable {
    let id: UUID
    let name: String
    let p12: Data
    let prov: Data
    let password: String
    
    static var signer: zsign? = nil
    static var isReady: Bool = false
    static var firstBoot: Bool = false
    
    static func startSigner() {
        if CertBlob.getSelectedCertBlobID().0 {
            signer = zsign()
            CertBlob.isReady = signer?.prepsign(CertBlob.getSelectedCertBlobPath()) ?? false
            
            if CertBlob.firstBoot {
                if CertBlob.isReady {
                    NotificationServer.NotifyUser(level: .note, notification: "ZSign server runs!", delay: 1.0)
                } else {
                    NotificationServer.NotifyUser(level: .error, notification: "ZSign server start failed! Please import a valid certificate, including the correct password.", delay: 1.0)
                }
            } else {
                CertBlob.firstBoot = true
            }
        }
    }
    
    init(atPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        self = try decoder.decode(CertBlob.self, from: data)
    }
    
    init(id: UUID, name: String, p12: Data, prov: Data, password: String) {
        self.id = id
        self.name = name
        self.p12 = p12
        self.prov = prov
        self.password = password
    }
    
    static func createCertBlob(p12Path: String, mpPath: String, password: String, name: String) {
        do {
            // gather data
            let p12Data: Data = try Data(contentsOf: URL(fileURLWithPath: p12Path))
            let mpData: Data = try Data(contentsOf: URL(fileURLWithPath: mpPath))
            
            // now we forge the .certblob file
            let blob: CertBlob = CertBlob(id: UUID(), name: name, p12: p12Data, prov: mpData, password: password)
            
            // now we encode the blob
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let jsonData = try? encoder.encode(blob) {
                try jsonData.write(to: URL(fileURLWithPath: "\(NSHomeDirectory())/tmp/.cert/\(blob.id).certblob"))
            }
            
            // now we set the selected blob
            UserDefaults.standard.set("\(blob.id)", forKey: "CurrentCertBlob")
            
            CertBlob.startSigner()
        } catch {
            print(error)
        }
    }
    
    static func getSelectedCertBlobID() -> (Bool, UUID) {
        if let data = UserDefaults.standard.string(forKey: "CurrentCertBlob") {
            if let uuid = UUID(uuidString: data) {
                return (true, uuid)
            }
        }
        return (false, UUID())
    }
    
    static func getSelectedCertBlobPath() -> String {
        let certBlobID = CertBlob.getSelectedCertBlobID()
        
        return "\(NSHomeDirectory())/tmp/.cert/\(certBlobID.1).certblob"
    }
    
    static func setCurrentBlob(blob: CertBlob) {
        UserDefaults.standard.set("\(blob.id)", forKey: "CurrentCertBlob")
    }
    
    static func setSelectedCertBlobID(id: UUID) {
        UserDefaults.standard.set("\(id)", forKey: "CurrentCertBlob")
    }
}
