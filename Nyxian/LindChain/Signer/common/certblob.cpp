//
//  certblob.cpp
//  Nyxian
//
//  Created by fridakitten on 15.04.25.
//

#include "certblob.h"
#include "base64.h"

///
/// Function to decode base64
///
std::vector<uint8_t> base64Decode(const std::string &in) {
    static constexpr unsigned char kDecodingTable[] = {
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 64, 64, 63,
        52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 64, 64, 64,  0, 64, 64,
        64,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
        15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 64,
        64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
        41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51
    };

    std::vector<uint8_t> out;
    int val = 0, valb = -8;
    for (uint8_t c : in) {
        if (c > 127 || kDecodingTable[c] == 64) break;
        val = (val << 6) + kDecodingTable[c];
        valb += 6;
        if (valb >= 0) {
            out.push_back((val >> valb) & 0xFF);
            valb -= 8;
        }
    }
    return out;
}

///
/// Function to parse the `.certblob` file
///
bool CertBlob::parseFromJson(const std::string& jsonPath) {
    FILE *file = std::fopen(jsonPath.c_str(), "r");
    
    // MARK: Bugfix -> fixes that it proceeds to load a none existent certblob
    if(!file)
        return false;
    
    int fd = fileno(file);
    struct stat stat;
    fstat(fd, &stat);
    
    char *buffer = (char*)std::malloc(stat.st_size);
    
    read(fd, buffer, stat.st_size);
    
    JValue root;
    if (!root.read(buffer)) {
        return false;
    }

    if (!root.has("p12") || !root.has("prov") || !root.has("password")) {
        return false;
    }

    std::string p12Str = root["p12"].asString();
    std::string provStr = root["prov"].asString();
    this->password = root["password"].asString();

    this->p12 = base64Decode(p12Str);
    this->prov = base64Decode(provStr);

    return true;
}
