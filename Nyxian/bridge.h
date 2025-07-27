//
//  bridge.h
//  LindDE
//
//  Created by fridakitten on 06.05.25.
//

#import <Compiler/Compiler.h>
//#import <Signer/zsign.h>
#import <Private/LSApplicationWorkspace.h>
#import <Synpush/Synpush.h>
#import <LogService/LogService.h>
#import <Private/Restart.h>
#import <Downloader/fdownload.h>
#import <Linker/linker.h>
#import <LiveContainer/LCAppInfo.h>
#import <LiveContainer/LCUtils.h>
#import <LiveContainer/ZSign/zsigner.h>

void Dylibify(NSString* ExecutablePath);
NSString* invokeBinaryMain(NSString *bundlePath, int argc, char *argv[]);
