//
//  DummyLinker.m
//  Runner
//
//  Created by einsitang on 2026/1/28.
//

#import <Foundation/Foundation.h>
#import "libsudoku.h"

@interface DummyLinker : NSObject
@end


@implementation DummyLinker
- (void)forceLink {
    // 随便调一个库里的函数，确保链接器必须去查找这个符号
    char* v = Version();
    NSLog(@"libsudoku.Version: %s",v);
}
@end

