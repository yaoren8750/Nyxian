//
//  ErrorHandler.h
//  Nyxian
//
//  Created by fridakitten on 29.04.25.
//

#ifdef __cplusplus

extern "C" {

#endif

void updateErrorOfPath(const char* filePath,
                       const char* content);

void removeErrorOfPath(const char *filePath);

#ifdef __cplusplus

}

#endif
