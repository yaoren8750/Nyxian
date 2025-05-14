//
//  certblob.h
//  Nyxian
//
//  Created by fridakitten on 15.04.25.
//

#include "json.h"
#include <iostream>
#include <stdexcept>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>

struct CertBlob {
    std::vector<uint8_t> p12;
    std::vector<uint8_t> prov;
    std::string password;

    bool parseFromJson(const std::string& jsonString);
};
