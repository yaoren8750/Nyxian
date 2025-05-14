/*
 Copyright (C) 2025 SeanIsTethered

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

#include "zsign.h"
#import "openssl.h"
#import "bundle.h"
#import "common/certblob.h"

///
/// Extend zsign interface
///
@interface zsign ()

@property (nonatomic,readwrite) ZSignAsset zSignAsset;

@end

///
/// Implementation of our zsign interface
///
@implementation zsign

///
/// This function prepares to sign a application bundle
///
/// I made the function to pre-determine if we even can sign the application in the first place
///
/// It also uses my own file type `.certblob` which is solely created for a cleaner file structure and because... no one else did this yet??
///
- (bool)prepsign:(NSString*)certBlobFile
{
    CertBlob blob;
    blob.parseFromJson([certBlobFile UTF8String]);
    
    _zSignAsset.m_strProvisionData = std::string(blob.prov.begin(), blob.prov.end());
    _zSignAsset.m_strCertData = std::string(blob.p12.begin(), blob.p12.end());
    _zSignAsset.m_passData = blob.password;
    
    return _zSignAsset.Init();
}

///
/// This function signs the application bundle at the givven path
///
- (bool)sign:(NSString*)strFolder
{
    return ZAppBundle().SignFolder(&_zSignAsset,
                                   strFolder.UTF8String,
                                   "",
                                   "",
                                   "",
                                   "",
                                   false,
                                   "",
                                   false);
}

@end
