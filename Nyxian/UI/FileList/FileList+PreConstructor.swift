//
//  FileList+PreConstructor.swift
//  Nyxian
//
//  Created by fridakitten on 14.05.25.
//

func getFileContentForName(filename: String) -> String {
    var content: String = ""
    var authgen: Bool = false
    var headergate: Bool = false
    
    // validate if we have to do stuff
    switch URL(fileURLWithPath: filename).pathExtension {
    case "c", "cpp", "m", "mm":
        authgen = true
        break
    case "h":
        authgen = true
        headergate = true
        break
    default:
        break
    }
    
    // now generate author if needed
    if authgen { content.append(Author.shared.signatureForFile(filename)) }
    if headergate {
        // generate header lock name macro
        let macroname: String = filename.uppercased().replacingOccurrences(of: ".", with: "_").replacingOccurrences(of: " ", with: "_")
        
        // now append
        content.append("#ifndef \(macroname)\n#define \(macroname)\n\n#endif /* \(macroname) */")
    }
    
    return content
}
