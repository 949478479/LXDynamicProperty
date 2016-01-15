//
//  ViewController.m
//  LXDynamicProperty
//
//  Created by 从今以后 on 16/1/12.
//  Copyright © 2016年 从今以后. All rights reserved.
//

@import MapKit;
@import SceneKit;
@import ObjectiveC.runtime;
#import "NSObject+LXDynamicProperty.h"
#import "NSObject+LXIntrospection.h"
#import "ViewController.h"

@interface ViewController () <LXDynamicProperty>
@property (nonatomic) CGRect lx_rect;
@property (nonatomic) ViewController *lx_strongObject;
@property (nonatomic, weak) ViewController *lx_weakObjcet;
@end

@implementation ViewController
@dynamic lx_rect;
@dynamic lx_weakObjcet;
@dynamic lx_strongObject;

- (void)dealloc
{
    NSLog(@"delloc %@", self);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSLog(@"注册前的类：%@", object_getClass(self));
    [self addObserver:self forKeyPath:@"lx_rect" options:0 context:(__bridge void *)self];
    [self addObserver:self forKeyPath:@"lx_weakObjcet" options:0 context:(__bridge void *)self];
    [self addObserver:self forKeyPath:@"lx_strongObject" options:0 context:(__bridge void *)self];
    NSLog(@"注册后的类：%@", object_getClass(self));

    self.lx_rect = CGRectMake(1, 2, 3, 4);
    self.lx_strongObject = [ViewController new];
    self.lx_weakObjcet = self.lx_strongObject;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == (__bridge void *)self) {
        NSLog(@"KVO ====== %@", [self valueForKeyPath:keyPath]);
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"lx_rect: %@", NSStringFromCGRect(self.lx_rect));

    NSLog(@"lx_strongObject: %@", self.lx_strongObject);
    NSLog(@"lx_weakObjcet: %@", self.lx_weakObjcet);
    self.lx_strongObject = nil;
    NSLog(@"lx_strongObject 被设置为 nil: %@", self.lx_strongObject);
    NSLog(@"lx_weakObjcet 释放会延迟: %@", self.lx_weakObjcet);

    [[NSRunLoop currentRunLoop] performSelector:@selector(nextRunloop)
                                         target:self
                                       argument:nil
                                          order:0
                                          modes:@[NSDefaultRunLoopMode]];
}

- (void)nextRunloop
{
    NSLog(@"lx_weakObjcet 在下个 runloop 才被释放: %@", self.lx_weakObjcet);

    [self lx_removeAllObservers];

    NSLog(@"注销后的类：%@", object_getClass(self));

    NSLog(@"lx_rect: %@", NSStringFromCGRect(self.lx_rect));

    self.view.window.rootViewController = nil;
}

- (void)lx_removeAllObservers
{
    for (id observance in [(__bridge id)[self observationInfo] valueForKey:@"observances"]) {
        [self removeObserver:[observance valueForKey:@"observer"]
                  forKeyPath:[observance valueForKeyPath:@"property.keyPath"]];
    }
}

@end
