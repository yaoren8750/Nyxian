//
//  GiveCerts.swift
//  Nyxian
//
//  Created by fridakitten on 14.04.25.
//

///
/// This is needed to initially get the certificates to authenticate at backloop.dev that presumably loops back to our localhost
///
import Foundation

func getCertificates() {
    ///
    /// basically a structure of helper functions that make it easier to get something like a certificate
    ///
    let sourceGET = SourceGET()
    let dispatchGroup = DispatchGroup()
    let uri = URL(string: "https://backloop.dev/pack.json")!
    
    ///
    /// Another helper function, i think this is to then initially write out the backloop.dev certificate
    ///
    func writeToFile(content: String, filename: String) throws {
        let path = URL(fileURLWithPath: Bootstrap.shared.bootstrapPath("/Certificates")).appendingPathComponent(filename)
        try content.write(to: path, atomically: true, encoding: .utf8)
    }
    
    
    ///
    /// presumably entering a dispatch group to not block the main thread, maybe to load the certificate while the apps UI already shows up, presumably not a big thing on first launch of the app, also because the app needs to offer a good user experience
    ///
    dispatchGroup.enter()
    
    
    ///
    /// probably to leave the group automatically when the function is done running
    ///
    defer {
        dispatchGroup.leave()
    }
    
    sourceGET.downloadURL(from: uri) { result in
        switch result {
        case .success(let (data, _)):
            switch sourceGET.parseCert(data: data) {
            case .success(let serverPack):
                do {
                    ///
                    /// Yep here we are writing out the server certificates
                    ///
                    try writeToFile(content: serverPack.key, filename: "server.pem")
                    try writeToFile(content: serverPack.cert, filename: "server.crt")
                    try writeToFile(content: serverPack.info.domains.commonName, filename: "commonName.txt")
                } catch {
                    print("Error writing files: \(error.localizedDescription)")
                }
            case .failure(let error):
                print("Error parsing certificate: \(error.localizedDescription)")
                break
            }
        case .failure(let error):
            print("Error fetching data from \(uri): \(error.localizedDescription)")
            break
        }
    }
}

///
/// These are the helper functions to get the certificates and stuff
///
class SourceGET {
    func downloadURL(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse?), Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "InvalidResponse", code: -1, userInfo: nil)))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorDescription = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                completion(.failure(NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorDescription])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "DataError", code: -1, userInfo: nil)))
                return
            }
            
            completion(.success((data, httpResponse)))
        }
        task.resume()
    }
    
    func parseCert(data: Data) -> Result<ServerPack, Error> {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let source = try decoder.decode(ServerPack.self, from: data)
            return .success(source)
        } catch {
            return .failure(error)
        }
    }
}

///
/// ServerPack
///
struct ServerPack: Decodable {
    var cert: String
    var ca: String
    var key: String
    var info: ServerPackInfo
    
    private enum CodingKeys: String, CodingKey {
        case cert, ca, key1, key2, info
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cert = try container.decode(String.self, forKey: .cert)
        ca = try container.decode(String.self, forKey: .ca)
        let key1 = try container.decode(String.self, forKey: .key1)
        let key2 = try container.decode(String.self, forKey: .key2)
        key = key1 + key2
        info = try container.decode(ServerPackInfo.self, forKey: .info)
    }
}

struct ServerPackInfo: Decodable {
    var domains: Domains
}

struct Domains: Decodable {
    var commonName: String
    
    private enum CodingKeys: String, CodingKey {
        case commonName = "commonName"
    }
}
