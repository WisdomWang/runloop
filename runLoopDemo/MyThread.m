//
//  MyThread.m
//  runLoopDemo
//
//  Created by Cary on 2018/7/19.
//  Copyright © 2018年 Cary. All rights reserved.
//

#import "MyThread.h"

@implementation MyThread

- (void)dealloc {
    
    NSLog(@"%@----线程被释放了",self.name);
}

@end
