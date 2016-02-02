# LXDynamicProperty

启发自 [NathanLi/iOSCategoryPropertyDynamicSupport](https://github.com/NathanLi/iOSCategoryPropertyDynamicSupport) 这个项目。

支持 `KVC` 和 `KVO`，支持各种基本类型以及 `NSValue` 支持的结构体。

```objective-c
// 为分类声明动态属性，并采纳 <LXDynamicProperty> 协议，表明应为该类的动态属性添加实现
@interface SomeClass (LXDynamicProperty) <LXDynamicProperty> 
@property (nonatomic) int lx_int;
@property (nonatomic) CGRect lx_rect;
@property (nonatomic, weak) id lx_weakObjcet;
@end
```

```objective-c
// 将属性声明为动态的
@implementation (LXDynamicProperty)
@dynamic lx_int;
@dynamic lx_rect;
@dynamic lx_weakObjcet
@end
```

```objective-c
// 可以设置自定义的动态属性前缀，设置为 "" 则表示无前缀，不过可能会和系统提供的动态属性冲突
int main(int argc, char * argv[]) {
    @autoreleasepool {
        LXSetDynamicPropertyPrefix("lx_");
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
```
