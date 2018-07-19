//
//  ViewController.m
//  runLoopDemo
//
//  Created by Cary on 2018/6/21.
//  Copyright © 2018年 Cary. All rights reserved.
//

#import "ViewController.h"
#import "MyThread.h"
@interface ViewController ()
@property (nonatomic,strong)MyThread *subThread2;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //使用场景
    //1.保持线程的存活，而不是线性的执行完任务就退出了
    //2.保持线程的存活后，让线程在我们需要的时候响应消息。
    //3.让线程定时执行某任务(Timer)
    //4.监听Observer达到一些目的
    
  /*  iOS 系统中，提供了两种RunLoop：NSRunLoop 和 CFRunLoopRef。
    CFRunLoopRef 是在 CoreFoundation 框架内的，它提供了纯 C 函数的 API，所有这些 API 都是线程安全的。
    NSRunLoop 是基于 CFRunLoopRef 的封装，提供了面向对象的 API，但是这些 API 不是线程安全的。*/
    
    ///<>不开启RunLoop的线程
    NSLog(@"%@----开辟子线程",[NSThread currentThread]);
    MyThread *subThread1 = [[MyThread alloc]initWithTarget:self selector:@selector(subThreadTodo) object:nil];
    subThread1.name = @"subThread1";
    [subThread1 start];
    // 结果：就像一开始所说的一样，子线程执行完操作就自动退出了。
    
    ///<2>开启RunLoop的线程
    
    //（1）实验用self来持有子线程
    self.subThread2 = [[MyThread alloc] initWithTarget:self selector:@selector(subThreadTodo) object:nil];
    self.subThread2.name = @"subThread2";
    [self.subThread2 start];
   // [self.subThread2 start];
    //结果：子线程内部操作完成后并没有被释放，看样子我们成功持有了子线程。那么按照刚才的设想，我们就可以在任何需要的时候开启子线程完成线程里面的操作。此时我们在[self.subThread start];后面再添加上一句[self.subThread start];的话就崩溃了。 因为执行完任务后，虽然Thread没有被释放，还处于内存中，但是它处于死亡状态（当线程的任务结束后就会进入这种状态）。打个比方，人死不能复生，线程死了也不能复生（重新开启），苹果不允许在线程死亡后再次开启。所以会报错attempt to start the thread again(尝试重新开启线程)
    
    //（2）尝试使用RunLoop
    MyThread *subThread3 = [[MyThread alloc] initWithTarget:self selector:@selector(subThreadTodo3) object:nil];
    subThread3.name = @"subThread3";
    [subThread3 start];
    //RunLoop本质就是个Event Loop的do while循环，所以运行到这一行以后子线程就一直在进行接受消息->等待->处理的循环。所以不会运行[runLoop run];之后的代码(这点需要注意，在使用RunLoop的时候如果要进行一些数据处理之类的要放在这个函数之前否则写的代码不会被执行)，也就不会因为任务结束导致线程死亡进而销毁。这也就是我们最常使用RunLoop的场景之一，就如小节标题保持线程的存活，而不是线性的执行完任务就退出了。
    
    /* 为什么总是要把RunLoop和线程放在一起来讲？
      总的来讲就是：RunLoop是保证线程不会退出，并且能在不处理消息的时候让线程休眠，节约资源，在接收到消息的时候唤醒线程做出对应处理的消息循环机制。它是寄生于线程的，所以提到RunLoop必然会涉及到线程。*/
    
    //    苹果不允许直接创建 RunLoop，它只提供了四个自动获取的函数
    //    [NSRunLoop currentRunLoop];//获取当前线程的RunLoop
    //    [NSRunLoop mainRunLoop];
    //    CFRunLoopGetMain();
    //    CFRunLoopGetCurrent();

   /* 线程默认不开启RunLoop，为什么我们的App或者说主线程却可以一直运行而不会结束？
    主线程是唯一一个例外，当App启动以后主线程会自动开启一个RunLoop来保证主线程的存活并处理各种事件。而且从上面的源代码来看，任意一个子线程的RunLoop都会保证主线程的RunLoop的存在。*/
    
    //一般我们常用的Mode有三种
    /*
    1.kCFRunLoopDefaultMode（CFRunLoop）/NSDefaultRunLoopMode（NSRunLoop）
    默认模式，在RunLoop没有指定Mode的时候，默认就跑在DefaultMode下。一般情况下App都是运行在这个mode下的
    
    2.(CFStringRef)UITrackingRunLoopMode(CFRunLoop)/UITrackingRunLoopMode(NSRunLoop)
    一般作用于ScrollView滚动的时候的模式，保证滑动的时候不受其他事件影响。
    
    3.kCFRunLoopCommonModes（CFRunLoop）/NSRunLoopCommonModes（NSRunLoop）
    这个并不是某种具体的Mode，而是一种模式组合，在主线程中默认包含了NSDefaultRunLoopMode和 UITrackingRunLoopMode。子线程中只包含NSDefaultRunLoopMode。
    注意：
    ①在选择RunLoop的runMode时不可以填这种模式否则会导致RunLoop运行不成功。
    ②在添加事件源的时候填写这个模式就相当于向组合中所有包含的Mode中注册了这个事件源。
    ③你也可以通过调用CFRunLoopAddCommonMode()方法将自定义Mode放到 kCFRunLoopCommonModes组合。*/
    
   /* Source是什么？
    source就是输入源事件，分为source0和source1这两种。
    1.source0：诸如UIEvent（触摸，滑动等），performSelector这种需要手动触发的操作。
    2.source1：处理系统内核的mach_msg事件（系统内部的端口事件）。诸如唤醒RunLoop或者让RunLoop进入休眠节省资源等。
    一般来说日常开发中我们需要关注的是source0，source1只需要了解。
    之所以说source0更重要是因为日常开发中，我们需要对常驻线程进行操作的事件大多都是source0，稍后的实验会讲到。*/

   /* Timer是什么？
    Timer即为定时源事件。通俗来讲就是我们很熟悉的NSTimer，其实NSTimer定时器的触发正是基于RunLoop运行的，所以使用NSTimer之前必须注册到RunLoop，但是RunLoop为了节省资源并不会在非常准确的时间点调用定时器，如果一个任务执行时间较长，那么当错过一个时间点后只能等到下一个时间点执行，并不会延后执行（NSTimer提供了一个tolerance属性用于设置宽容度，如果确实想要使用NSTimer并且希望尽可能的准确，则可以设置此属性）。*/
    
   /* Observer是什么？
    它相当于消息循环中的一个监听器，随时通知外部当前RunLoop的运行状态。NSRunLoop没有相关方法，只能通过CFRunLoop相关方法创建 */
    // 创建observer
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(CFAllocatorGetDefault(), kCFRunLoopAllActivities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        NSLog(@"----监听到RunLoop状态发生改变---%zd", activity);
    });
    // 添加观察者：监听RunLoop的状态
    CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopDefaultMode);

    /*RunLoop能正常运行的条件就是，至少要包含一个Mode（RunLoop默认就包含DefaultMode），并且该Mode下需要有至少一个的事件源（Timer/Source）。事实上经过NSRunLoop封装后，只可以往mode中添加两类事件源：NSPort（对应的是source1）和NSTimer。*/
   // RunLoop正常运行的条件是：1.有Mode。2.Mode有事件源。3.运行在有事件源的Mode下。
    
    
    
    /*体验结论
    ①.RunLoop是寄生于线程的消息循环机制，它能保证线程存活，而不是线性执行完任务就消亡。
    
    ②.RunLoop与线程是一一对应的，每个线程只有唯一与之对应的一个RunLoop。我们不能创建RunLoop，只能在当前线程当中获取线程对应的RunLoop（主线程RunLoop除外）。
    
    ③.子线程默认没有RunLoop，需要我们去主动开启，但是主线程是自动开启了RunLoop的。
    
    ④.RunLoop想要正常启用需要运行在添加了事件源的Mode下。
    
    ⑤.RunLoop有三种启动方式run、runUntilDate:(NSDate *)limitDate、runMode:(NSString *)mode beforeDate:(NSDate *)limitDate。第一种无条件永远运行RunLoop并且无法停止，线程永远存在。第二种会在时间到后退出RunLoop，同样无法主动停止RunLoop。前两种都是在NSDefaultRunLoopMode模式下运行。第三种可以选定运行模式，并且在时间到后或者触发了非Timer的事件后退出。*/
    
    
    //在进行Scrollview的滚动操作时Timer不进行响应，滑动结束后timer又恢复正常了。
    
   /* 在之前讲Mode的时候提到过，RunLoop每次只能运行在一个Mode下，其意义是让不同Mode中的item互不影响。
    NSTimer是一个Timer源（item），在上面哪个例子中不管是`[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];`还是`scheduedTimerWith`我们都是把Timer加到了主线程RunLoop的NSDefaultRunLoopMode中。一般情况下主线程RunLoop就运行在NSDefaultRunLoopMode下，所以定时器正常运行。
    当Scrollview开始滑动时，主线程RunLoop自动切换了当前运行的Mode（currentMode），变成了UITrackingRunLoopMode。所以现在RunLoop要处理的就是UITrackingRunLoopMode中item。
    我们的timer是添加在NSDefaultRunLoopMode中的，并没有添加到UITrackingRunLoopMode中。即我们的timer不是UITrackingRunLoopMode中的item。
    本着不同Mode中的item互不影响的原则，RunLoop也就不会处理非当前Mode的item,所以定时器就不会响应。
    当Scrollview滑动结束，主线程RunLoop自动切换了当前运行的Mode（currentMode），变成了NSDefaultRunLoopMode。我们的Timer是NSDefaultRunLoopMode的item，所以RunLoop会处理它，所以又正常响应了。
    如果想Timer在两种Mode中都得到响应怎么办？前面提到过，一个item可以被同时加入多个mode。让Timer同时成为两种Mode的item就可以了(分别添加或者直接加到commonMode中)，这样不管RunLoop处于什么Mode，timer都是当前Mode的item，都会得到处理。*/
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(wantTodo) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}
- (void)subThreadTodo {
    
    NSLog(@"%@----执行子线程任务",[NSThread currentThread]);
}

- (void)subThreadTodo3 {
    
    NSLog(@"%@----开始执行子线程任务",[NSThread currentThread]);
    //获取当前子线程的RunLoop
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    //关于这里的[NSMachPort port]我的理解是，给RunLoop添加了一个占位事件源，告诉RunLoop有事可做，让RunLoop运行起来。
    //但是暂时这个事件源不会有具体的动作，而是要等RunLoop跑起来过后等有消息传递了才会有具体动作。
    [runLoop addPort:[NSMachPort port] forMode:NSRunLoopCommonModes];
    //让RunLoop跑起来
    [runLoop run];
    NSLog(@"%@----执行子线程任务结束",[NSThread currentThread]);
}

- (void)wantTodo {
    
   
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
