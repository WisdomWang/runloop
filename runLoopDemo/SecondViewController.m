//
//  SecondViewController.m
//  runLoopDemo
//
//  Created by Cary on 2018/7/20.
//  Copyright © 2018年 Cary. All rights reserved.
//

#import "SecondViewController.h"
#import "MyThread.h"
@interface SecondViewController ()<UITextViewDelegate>
@property (nonatomic, weak)NSThread *subThread;//子线程
@property (nonatomic, weak)NSRunLoopMode runLoopMode;//想设置的RunLoop的Mode
@property (nonatomic, assign)BOOL isNeedRunLoopStop;//控制是否需要停止RunLoop
@property (nonatomic,strong) UITextView *myTextView;//只要是Scrollview及其子类都行
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //子线程中模拟主线程DefaultMode与TrackingMode的切换
    self.myTextView = [[UITextView alloc]init];
    self.myTextView.frame = CGRectMake(50, 100, 200, 50);
    self.myTextView.text = @"当tableview的cell上有需要从网络获取的图片的时候，异步线程会去加载图片，加载完成后主线程就会设置cell的图片，有可能会造成卡顿。可以让设置图片的任务在CFRunLoopDefaultMode下进行，当滚动tableView的时候，RunLoop是在 UITrackingRunLoopMode 下进行，不去设置图片，而是当停止的时候，再去设置图片。（这个场景的核心还是利用不同Mode的切换的思想，可以拓展其他地方）";
    [self.view addSubview:self.myTextView];
    self.myTextView.delegate = self;
    
    self.isNeedRunLoopStop = NO;
    
    NSLog(@"%@----开辟子线程",[NSThread currentThread]);
    
    NSThread *tmpThread = [[MyThread alloc] initWithTarget:self selector:@selector(subThreadTodo) object:nil];
    self.subThread = tmpThread;
    self.subThread.name = @"subThread";
    [self.subThread start];
}

- (void)subThreadTodo
{
    NSLog(@"%@----开始执行子线程任务",[NSThread currentThread]);
    
    @autoreleasepool{
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        
        //NSDefaultRunLoopMode下暂时什么都不干，只是为了让RunLoop能在该模式下运行添加了一个source1
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:2 target:self selector:@selector(timerTodo) userInfo:nil repeats:YES];
        
        //给UITrackingRunLoopMode添加一个timer，为了等下切换到该模式的时候能看到效果。
        //提示：子线程RunLoop如果不给UITrackingRunLoopMode添加item就没有这个Mode，可以看前面初体验疑问的截图。
        //但是，NSDefaultRunLoopMode是无论如何都存在的，就算你不给他添加item，他也只是内容为空而已。
        [runLoop addTimer:timer forMode:UITrackingRunLoopMode];
        
        self.runLoopMode = NSDefaultRunLoopMode;
        
        //CFRunLoopAddCommonMode(CFRunLoopGetCurrent(), (CFStringRef)UITrackingRunLoopMode);
        
        while (!self.isNeedRunLoopStop) {//用while来控制RunLoop的运行与否
            //让RunLoop在我们希望的Mode下运行
            [runLoop runMode:self.runLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
}

- (void)changeSubThreadRunLoopMode:(NSRunLoopMode)mode{
    
    //改变我们希望RunLoop运行的Mode的方法
    //到时候用[performSelector:onThread:withObject:waitUntilDone:]来调用
    //结合[runMode:beforeDate:]触发非Timer的事件源会退出RunLoop的特性
    //再结合上面While的写法，就退出了之前的RunLoop并让RunLoop以我们希望的Mode重新Run。
    
    //断点3
    NSLog(@"当前线程:%@ RunLoop即将将Mode改变成:%@\n", [NSThread currentThread], mode);
    
    self.runLoopMode = mode;
}

- (void)timerTodo{
    //上面的Timer执行的函数，只是为了等下切换的mode后有打印好观察。
    NSLog(@"Timer启动啦，当前RunLoopMode:%@\n", [[NSRunLoop currentRunLoop] currentMode]);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (self.runLoopMode != UITrackingRunLoopMode) {
        //如果有滑动事件，并且RunLoop的Mode不为UITrackingRunLoopMode
        //就改变Mode并退出当前RunLoop然后让RunLoop以更改后的Mode重新Run
        //加if是为了避免重复操作，切换RunLoopMode只需要一次
        [self performSelector:@selector(changeSubThreadRunLoopMode:) onThread:self.subThread withObject:UITrackingRunLoopMode waitUntilDone:NO];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    //拖拽结束会调用这个方法，如果还有拖拽后的滑动动画就不做操作
    if (!decelerate) {
        //如果没有后续动画了就切换Mode为NSDefaultRunLoopMode
        if (self.runLoopMode != NSDefaultRunLoopMode) {
            //断点1
            [self performSelector:@selector(changeSubThreadRunLoopMode:) onThread:self.subThread withObject:NSDefaultRunLoopMode waitUntilDone:NO];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    //拖拽后的后续滑动动画结束（如果有才会到这，没有就不会到这个函数里面）
    //也就是说上面那个函数如果切换了Mode就不会走这里，否则说明需要在这里切换Mode
    //切换Mode为NSDefaultRunLoopMode
    if (self.runLoopMode != NSDefaultRunLoopMode) {
        //断点2
        [self performSelector:@selector(changeSubThreadRunLoopMode:) onThread:self.subThread withObject:NSDefaultRunLoopMode waitUntilDone:NO];
    }
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
