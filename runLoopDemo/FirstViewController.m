//
//  FirstViewController.m
//  runLoopDemo
//
//  Created by Cary on 2018/7/20.
//  Copyright © 2018年 Cary. All rights reserved.
//

#import "FirstViewController.h"
#import "MyThread.h"
@interface FirstViewController ()
@property (nonatomic,weak)MyThread *subThread;
@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
     NSLog(@"%@----开辟子线程",[NSThread currentThread]);
    MyThread *tmpThread = [[MyThread alloc]initWithTarget:self selector:@selector(subThreadTodo) object:nil];
    //subThread用weak声明，用weak声明，用weak声明
    self.subThread = tmpThread;
    self.subThread.name = @"subThread";
    [self.subThread start];
}

- (void)subThreadTodo {
    
    NSLog(@"%@----开始执行子线程任务",[NSThread currentThread]);
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
    [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    
    //runMode:(NSString *)mode beforeDate:(NSDate *)limitDate这种启动RunLoop的方式有一个特性,那就是这个接口在非Timer事件触发(此处是达成了这个条件)、显式的用CFRunLoopStop停止RunLoop或者到达limitDate后会退出。而例子当中也没有用while把RunLoop包围起来，所以RunLoop退出后子线程完成了任务最后退出了。
    
    NSLog(@"%@----执行子线程任务结束",[NSThread currentThread]);
}

//我们希望放在子线程中执行的任务
- (void)wantTodo{
    //断点2
    NSLog(@"当前线程:%@执行任务处理数据", [NSThread currentThread]);
    
}
//屏幕点击事件
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent *)event{
    //断点1
    //在子线程中去响应wantTodo方法
    [self performSelector:@selector(wantTodo) onThread:self.subThread withObject:nil waitUntilDone:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
