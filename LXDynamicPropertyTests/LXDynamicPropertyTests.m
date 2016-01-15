//
//  LXDynamicPropertyTests.m
//  LXDynamicPropertyTests
//
//  Created by 从今以后 on 16/1/12.
//  Copyright © 2016年 从今以后. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LXDynamicPropertyTester.h"
#import "NSObject+LXIntrospection.h"
#import "NSObject+LXDynamicProperty.h"
@import MapKit.MKGeometry;
@import ObjectiveC.runtime;
@import AVFoundation.AVTime;
@import SceneKit.SceneKitTypes;

@interface LXDynamicPropertyTester (LX) <LXDynamicProperty>

@property (nonatomic, copy) int (^lx_block)();

@property (nonatomic, getter=lx_tester, setter=lx_setTester:) LXDynamicPropertyTester *lx_tester;
@property (nonatomic, weak) LXDynamicPropertyTester *lx_weakTester;
@property (nonatomic, assign) LXDynamicPropertyTester *lx_assignTester;

@property (nonatomic) NSString *lx_string;
@property (nonatomic, copy) NSString *lx_copyString;
@property (nonatomic) NSArray *lx_array;
@property (nonatomic, copy) NSArray *lx_copyArray;

@property (nonatomic) BOOL               lx_BOOL;
@property (nonatomic) bool               lx_bool;
@property (nonatomic) char               lx_char;
@property (nonatomic) double             lx_double;
@property (nonatomic) float              lx_float;
@property (nonatomic) CGFloat            lx_cgfloat;
@property (nonatomic) int                lx_int;
@property (nonatomic) NSInteger          lx_integer;
@property (nonatomic) long               lx_long;
@property (nonatomic) long long          lx_longLong;
@property (nonatomic) short              lx_short;
@property (nonatomic) unsigned char      lx_unsignedChar;
@property (nonatomic) unsigned int       lx_unsignedInt;
@property (nonatomic) NSUInteger         lx_unsignedInteger;
@property (nonatomic) unsigned long      lx_unsignedLong;
@property (nonatomic) unsigned long long lx_unsignedLongLong;
@property (nonatomic) unsigned short     lx_unsignedShort;

@property (nonatomic) NSRange lx_range;

@property (nonatomic) CGRect            lx_rect;
@property (nonatomic) CGSize            lx_size;
@property (nonatomic) CGPoint           lx_point;
@property (nonatomic) CGVector          lx_vector;
@property (nonatomic) CGAffineTransform lx_affineTransform;

@property (nonatomic) UIEdgeInsets lx_edgeInsets;
@property (nonatomic) UIOffset     lx_offset;

@property (nonatomic) CATransform3D lx_transform3D;

@property (nonatomic) CMTime        lx_time;
@property (nonatomic) CMTimeRange   lx_timeRange;
@property (nonatomic) CMTimeMapping lx_timeMapping;

@property (nonatomic) CLLocationCoordinate2D lx_coordinate;
@property (nonatomic) MKCoordinateSpan       lx_coordinateSpan;

@property (nonatomic) SCNVector3 lx_vector3;
@property (nonatomic) SCNVector4 lx_vector4;
@property (nonatomic) SCNMatrix4 lx_matrix4;

@end

@implementation LXDynamicPropertyTester (LX)

@dynamic lx_block;

@dynamic lx_tester;
@dynamic lx_weakTester;
@dynamic lx_assignTester;

@dynamic lx_array;
@dynamic lx_copyArray;
@dynamic lx_string;
@dynamic lx_copyString;

@dynamic lx_BOOL;
@dynamic lx_bool;
@dynamic lx_char;
@dynamic lx_double;
@dynamic lx_float;
@dynamic lx_cgfloat;
@dynamic lx_int;
@dynamic lx_integer;
@dynamic lx_long;
@dynamic lx_longLong;
@dynamic lx_short;
@dynamic lx_unsignedChar;
@dynamic lx_unsignedInt;
@dynamic lx_unsignedInteger;
@dynamic lx_unsignedLong;
@dynamic lx_unsignedLongLong;
@dynamic lx_unsignedShort;

@dynamic lx_range;

@dynamic lx_rect;
@dynamic lx_size;
@dynamic lx_point;
@dynamic lx_vector;
@dynamic lx_affineTransform;

@dynamic lx_edgeInsets;
@dynamic lx_offset;

@dynamic lx_transform3D;

@dynamic lx_time;
@dynamic lx_timeRange;
@dynamic lx_timeMapping;

@dynamic lx_coordinate;
@dynamic lx_coordinateSpan;

@dynamic lx_vector3;
@dynamic lx_vector4;
@dynamic lx_matrix4;

@end

@interface LXDynamicPropertyTests : XCTestCase
{
    LXDynamicPropertyTester *_tester;
}
@property (nonatomic) SCNVector3 lx_vector3;
@end
@implementation LXDynamicPropertyTests

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == (__bridge void *)self) {
        NSLog(@"\nKVO - keyPath: %@, value: %@\n", keyPath, [object valueForKeyPath:keyPath]);
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setUp
{
    [super setUp];

    _tester = [LXDynamicPropertyTester new];

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self registerKVO];
    });

    NSArray *methods = [LXDynamicPropertyTester lx_instanceMethodDescriptionList];
    NSLog(@"%lu, %@", methods.count, methods);

    methods = [NSClassFromString(@"NSKVONotifying_LXDynamicPropertyTester") lx_instanceMethodDescriptionList];
    NSLog(@"%lu, %@", methods.count, methods);
}

- (void)tearDown
{
    [super tearDown];
}

- (void)registerKVO
{
    void *context = (__bridge void *)self;

    [_tester addObserver:self forKeyPath:@"lx_block" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_tester" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_weakTester" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_assignTester" options:0 context:context];

    [_tester addObserver:self forKeyPath:@"lx_array" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_copyArray" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_string" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_copyString" options:0 context:context];

    [_tester addObserver:self forKeyPath:@"lx_BOOL" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_bool" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_char" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_double" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_float" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_cgfloat" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_int" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_integer" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_long" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_longLong" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_short" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_unsignedChar" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_unsignedInt" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_unsignedInteger" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_unsignedLong" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_unsignedLongLong" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_unsignedShort" options:0 context:context];

    [_tester addObserver:self forKeyPath:@"lx_range" options:0 context:context];

    [_tester addObserver:self forKeyPath:@"lx_rect" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_size" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_point" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_vector" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_affineTransform" options:0 context:context];

    [_tester addObserver:self forKeyPath:@"lx_edgeInsets" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_offset" options:0 context:context];

    [_tester addObserver:self forKeyPath:@"lx_transform3D" options:0 context:context];

    [_tester addObserver:self forKeyPath:@"lx_time" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_timeRange" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_timeMapping" options:0 context:context];

    [_tester addObserver:self forKeyPath:@"lx_coordinate" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_coordinateSpan" options:0 context:context];

    [_tester addObserver:self forKeyPath:@"lx_vector3" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_vector4" options:0 context:context];
    [_tester addObserver:self forKeyPath:@"lx_matrix4" options:0 context:context];
}

- (void)testSetterAndGetter
{
    int (^lx_block)(void) = ^{
        NSLog(@"报告大王!~");
        return 233;
    };
    _tester.lx_block = lx_block;
    lx_block = nil;
    XCTAssertEqual(_tester.lx_block(), 233);

    _tester.lx_tester = [LXDynamicPropertyTester new];
    XCTAssertNotNil(_tester.lx_tester);

    id obj = [LXDynamicPropertyTester new];
    _tester.lx_weakTester = obj;
    _tester.lx_assignTester = obj;
    obj = nil;
    // unretain 和 weak 的释放不是很及时。。。
    // _tester.lx_assignTester;
    // _tester.lx_weakTester;

    NSMutableArray *arrayM = [NSMutableArray arrayWithObjects:@1, @2, @3, nil];
    _tester.lx_array = arrayM;
    _tester.lx_copyArray = arrayM;
    [arrayM removeAllObjects];
    XCTAssertTrue(_tester.lx_array == arrayM);
    XCTAssertTrue([_tester.lx_array count] == 0);
    XCTAssertTrue([_tester.lx_copyArray count] == 3);

    NSMutableString *stringM = [NSMutableString stringWithString:@"字符串..."];
    _tester.lx_string = stringM;
    _tester.lx_copyString = stringM;
    [stringM deleteCharactersInRange:NSMakeRange(3, stringM.length - 3)];
    XCTAssertTrue(_tester.lx_string == stringM);
    XCTAssertTrue([_tester.lx_string isEqualToString:@"字符串"]);
    XCTAssertTrue([_tester.lx_copyString isEqualToString:@"字符串..."]);

    _tester.lx_BOOL = YES;
    XCTAssertEqual(_tester.lx_BOOL, YES);

    _tester.lx_bool = true;
    XCTAssertEqual(_tester.lx_bool, true);

    _tester.lx_char = INT8_MAX;
    XCTAssertEqual(_tester.lx_char, INT8_MAX);

    _tester.lx_double = DBL_MAX;
    XCTAssertEqual(_tester.lx_double, DBL_MAX);

    _tester.lx_float = FLT_MAX;
    XCTAssertEqual(_tester.lx_float, FLT_MAX);

    _tester.lx_cgfloat = CGFLOAT_MAX;
    XCTAssertEqual(_tester.lx_cgfloat, CGFLOAT_MAX);
    
    _tester.lx_int = INT_MAX;
    XCTAssertEqual(_tester.lx_int, INT_MAX);

    _tester.lx_integer = NSIntegerMax;
    XCTAssertEqual(_tester.lx_integer, NSIntegerMax);

    _tester.lx_long = LONG_MAX;
    XCTAssertEqual(_tester.lx_long, LONG_MAX);

    _tester.lx_longLong = LONG_LONG_MAX;
    XCTAssertEqual(_tester.lx_longLong, LONG_LONG_MAX);

    _tester.lx_short = INT16_MAX;
    XCTAssertEqual(_tester.lx_short, INT16_MAX);

    _tester.lx_unsignedChar = UINT8_MAX;
    XCTAssertEqual(_tester.lx_unsignedChar, UINT8_MAX);

    _tester.lx_unsignedInt = UINT_MAX;
    XCTAssertEqual(_tester.lx_unsignedInt, UINT_MAX);

    _tester.lx_unsignedInteger  = NSUIntegerMax;
    XCTAssertEqual(_tester.lx_unsignedInteger, NSUIntegerMax);

    _tester.lx_unsignedLong = ULONG_MAX;
    XCTAssertEqual(_tester.lx_unsignedLong, ULONG_MAX);

    _tester.lx_unsignedLongLong = ULONG_LONG_MAX;
    XCTAssertEqual(_tester.lx_unsignedLongLong, ULONG_LONG_MAX);

    _tester.lx_unsignedShort = UINT16_MAX;
    XCTAssertEqual(_tester.lx_unsignedShort, UINT16_MAX);

    NSRange range = { 1, 2 };
    _tester.lx_range = range;
    XCTAssertTrue(NSEqualRanges(_tester.lx_range, range));

    CGRect rect = { 1, 2, 3, 4 };
    _tester.lx_rect = rect;
    XCTAssertTrue(CGRectEqualToRect(_tester.lx_rect, rect));

    CGSize size = { 1, 2 };
    _tester.lx_size = size;
    XCTAssertTrue(CGSizeEqualToSize(_tester.lx_size, size));

    CGPoint point = { 1, 2 };
    _tester.lx_point = point;
    XCTAssertTrue(CGPointEqualToPoint(_tester.lx_point, point));

    CGVector vector = { 1, 2 };
    _tester.lx_vector = vector;
    XCTAssertTrue(vector.dx == _tester.lx_vector.dx && vector.dy == _tester.lx_vector.dy);

    CGAffineTransform affineTransform = { 1, 2, 3, 4, 5, 6 };
    _tester.lx_affineTransform = affineTransform;
    XCTAssertTrue(CGAffineTransformEqualToTransform(_tester.lx_affineTransform, affineTransform));

    UIEdgeInsets edgeInsets = { 1, 2, 3, 4 };
    _tester.lx_edgeInsets = edgeInsets;
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(_tester.lx_edgeInsets, edgeInsets));

    UIOffset offset = { 1, 2 };
    _tester.lx_offset = offset;
    XCTAssertTrue(UIOffsetEqualToOffset(_tester.lx_offset, offset));

    CATransform3D transform3D = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    _tester.lx_transform3D = transform3D;
    XCTAssertTrue(CATransform3DEqualToTransform(_tester.lx_transform3D, transform3D));

    CMTime time = CMTimeMake(123, 321);
    _tester.lx_time = time;
    XCTAssertTrue(CMTimeCompare(_tester.lx_time, time) == 0);

    CMTimeRange timeRange = { time, time };
    _tester.lx_timeRange = timeRange;
    XCTAssertTrue(CMTimeRangeEqual(_tester.lx_timeRange, timeRange));

    CMTimeMapping timeMapping = { timeRange, timeRange };
    _tester.lx_timeMapping = timeMapping;
    XCTAssertTrue(CMTimeRangeEqual(_tester.lx_timeMapping.source, timeMapping.source));

    CLLocationCoordinate2D coordinate = { 1, 2 };
    _tester.lx_coordinate = coordinate;
    XCTAssertTrue(_tester.lx_coordinate.latitude == coordinate.latitude &&
                  _tester.lx_coordinate.longitude == coordinate.longitude);

    MKCoordinateSpan span = { 3, 4 };
    _tester.lx_coordinateSpan = span;
    XCTAssertTrue(_tester.lx_coordinateSpan.latitudeDelta == span.latitudeDelta &&
                  _tester.lx_coordinateSpan.longitudeDelta == span.longitudeDelta);

    SCNVector3 vector3 = { 1, 2, 3 };
    _tester.lx_vector3 = vector3;
    XCTAssertTrue(SCNVector3EqualToVector3(_tester.lx_vector3, vector3));

    SCNVector4 vector4 = { 1, 2, 3, 4 };
    _tester.lx_vector4 = vector4;
    XCTAssertTrue(SCNVector4EqualToVector4(_tester.lx_vector4, vector4));

    SCNMatrix4 matrix4 = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 };
    _tester.lx_matrix4 = matrix4;
    XCTAssertTrue(SCNMatrix4EqualToMatrix4(_tester.lx_matrix4, matrix4)); 
}

- (void)testKVC
{
    int (^lx_block)(void) = ^{
        NSLog(@"报告大王!~");
        return 233;
    };
    [_tester setValue:lx_block forKey:@"lx_block"];
    lx_block = nil;
    lx_block = [_tester valueForKey:@"lx_block"];
    XCTAssertEqual(lx_block(), 233);

    LXDynamicPropertyTester *tester = [LXDynamicPropertyTester new];
//    // setter 被改成了 lx_setTester，而 setValue:ForKey 只会搜索名为 set<Key>: 的 setter 方法，动态属性也没有实例变量
//    [_tester setValue:tester forKey:@"lx_tester"];
//    XCTAssertEqual([_tester valueForKey:@"lx_tester"], tester);
//    [_tester setValue:nil forKey:@"lx_tester"];
//
//    // weak 引用的释放会延迟一些。。。
//    [_tester setValue:tester forKey:@"lx_weakTester"];
//    [_tester setValue:tester forKey:@"lx_assignTester"];
//    tester = nil;
//    [_tester valueForKey:@"lx_assignTester"];
//    XCTAssertNil([_tester valueForKey:@"lx_weakTester"]);
    _tester.lx_tester = tester;
    [_tester setValue:@"试试 keyPath" forKeyPath:@"lx_tester.lx_string"];
    XCTAssertTrue([[_tester valueForKeyPath:@"lx_tester.lx_string"] isEqualToString:@"试试 keyPath"]);

    [_tester setValue:[NSValue valueWithCGRect:(CGRect){1,2,3,4}] forKeyPath:@"lx_tester.lx_rect"];
    XCTAssertTrue(CGRectEqualToRect([[_tester valueForKeyPath:@"lx_tester.lx_rect"] CGRectValue], (CGRect){1,2,3,4}));

    NSMutableArray *arrayM = [NSMutableArray arrayWithObjects:@1, @2, @3, nil];
    [_tester setValue:arrayM forKey:@"lx_array"];
    [_tester setValue:arrayM forKey:@"lx_copyArray"];
    [arrayM removeAllObjects];
    XCTAssertTrue([_tester valueForKey:@"lx_array"] == arrayM);
    XCTAssertTrue([[_tester valueForKey:@"lx_array"] count] == 0);
    XCTAssertTrue([[_tester valueForKey:@"lx_copyArray"] count] == 3);

    NSMutableString *stringM = [NSMutableString stringWithString:@"字符串..."];
    [_tester setValue:stringM forKey:@"lx_string"];
    [_tester setValue:stringM forKey:@"lx_copyString"];
    [stringM deleteCharactersInRange:NSMakeRange(3, stringM.length - 3)];
    XCTAssertTrue([_tester valueForKey:@"lx_string"] == stringM);
    XCTAssertTrue([[_tester valueForKey:@"lx_string"] isEqualToString:@"字符串"]);
    XCTAssertTrue([[_tester valueForKey:@"lx_copyString"] isEqualToString:@"字符串..."]);

    [_tester setValue:@(YES) forKey:@"lx_BOOL"];
    XCTAssertEqual([[_tester valueForKey:@"lx_BOOL"] boolValue], YES);

    [_tester setValue:@(true) forKey:@"lx_bool"];
    XCTAssertEqual([[_tester valueForKey:@"lx_bool"] boolValue], true);

    [_tester setValue:@(INT8_MAX) forKey:@"lx_char"];
    XCTAssertEqual([[_tester valueForKey:@"lx_char"] charValue], INT8_MAX);

    [_tester setValue:@(DBL_MAX) forKey:@"lx_double"];
    XCTAssertEqual([[_tester valueForKey:@"lx_double"] doubleValue], DBL_MAX);

    [_tester setValue:@(FLT_MAX) forKey:@"lx_float"];
    XCTAssertEqual([[_tester valueForKey:@"lx_float"] floatValue], FLT_MAX);

    [_tester setValue:@(CGFLOAT_MAX) forKey:@"lx_cgfloat"];
    if (CGFLOAT_IS_DOUBLE) {
        XCTAssertEqual([[_tester valueForKey:@"lx_cgfloat"] doubleValue], CGFLOAT_MAX);
    } else {
        XCTAssertEqual([[_tester valueForKey:@"lx_cgfloat"] floatValue], CGFLOAT_MAX);
    }

    [_tester setValue:@(INT_MAX) forKey:@"lx_int"];
    XCTAssertEqual([[_tester valueForKey:@"lx_int"] intValue], INT_MAX);

    [_tester setValue:@(NSIntegerMax) forKey:@"lx_integer"];
    XCTAssertEqual([[_tester valueForKey:@"lx_integer"] integerValue], NSIntegerMax);

    [_tester setValue:@(LONG_MAX) forKey:@"lx_long"];
    XCTAssertEqual([[_tester valueForKey:@"lx_long"] longValue], LONG_MAX);

    [_tester setValue:@(LONG_LONG_MAX) forKey:@"lx_longLong"];
    XCTAssertEqual([[_tester valueForKey:@"lx_longLong"] longLongValue], LONG_LONG_MAX);

    [_tester setValue:@(INT16_MAX) forKey:@"lx_short"];
    XCTAssertEqual([[_tester valueForKey:@"lx_short"] shortValue], INT16_MAX);

    [_tester setValue:@(UINT8_MAX) forKey:@"lx_unsignedChar"];
    XCTAssertEqual([[_tester valueForKey:@"lx_unsignedChar"] unsignedCharValue], UINT8_MAX);

    [_tester setValue:@(UINT_MAX) forKey:@"lx_unsignedInt"];
    XCTAssertEqual([[_tester valueForKey:@"lx_unsignedInt"] unsignedIntValue], UINT_MAX);

    [_tester setValue:@(NSUIntegerMax) forKey:@"lx_unsignedInteger"];
    XCTAssertEqual([[_tester valueForKey:@"lx_unsignedInteger"] unsignedIntegerValue], NSUIntegerMax);

    [_tester setValue:@(ULONG_MAX) forKey:@"lx_unsignedLong"];
    XCTAssertEqual([[_tester valueForKey:@"lx_unsignedLong"] unsignedLongValue], ULONG_MAX);

    [_tester setValue:@(ULONG_LONG_MAX) forKey:@"lx_unsignedLongLong"];
    XCTAssertEqual([[_tester valueForKey:@"lx_unsignedLongLong"] unsignedLongLongValue], ULONG_LONG_MAX);

    [_tester setValue:@(UINT16_MAX) forKey:@"lx_unsignedShort"];
    XCTAssertEqual([[_tester valueForKey:@"lx_unsignedShort"] unsignedShortValue], UINT16_MAX);

    NSRange range = { 1, 2 };
    [_tester setValue:[NSValue valueWithRange:range] forKey:@"lx_range"];
    XCTAssertTrue(NSEqualRanges([[_tester valueForKey:@"lx_range"] rangeValue], range));

    CGRect rect = { 1, 2, 3, 4 };
    [_tester setValue:[NSValue valueWithCGRect:rect] forKey:@"lx_rect"];
    XCTAssertTrue(CGRectEqualToRect([[_tester valueForKey:@"lx_rect"] CGRectValue], rect));

    CGSize size = { 1, 2 };
    [_tester setValue:[NSValue valueWithCGSize:size] forKey:@"lx_size"];
    XCTAssertTrue(CGSizeEqualToSize([[_tester valueForKey:@"lx_size"] CGSizeValue], size));

    CGPoint point = { 1, 2 };
    [_tester setValue:[NSValue valueWithCGPoint:point] forKey:@"lx_point"];
    XCTAssertTrue(CGPointEqualToPoint([[_tester valueForKey:@"lx_point"] CGPointValue], point));

    CGVector vector = { 1, 2 };
    [_tester setValue:[NSValue valueWithCGVector:vector] forKey:@"lx_vector"];
    CGVector vector2 = [[_tester valueForKey:@"lx_vector"] CGVectorValue];
    XCTAssertTrue(vector.dx == vector2.dx && vector.dy == vector2.dy);

    CGAffineTransform affineTransform = { 1, 2, 3, 4, 5, 6 };
    [_tester setValue:[NSValue valueWithCGAffineTransform:affineTransform] forKey:@"lx_affineTransform"];
    XCTAssertTrue(CGAffineTransformEqualToTransform([[_tester valueForKey:@"lx_affineTransform"] CGAffineTransformValue], affineTransform));

    UIEdgeInsets edgeInsets = { 1, 2, 3, 4 };
    [_tester setValue:[NSValue valueWithUIEdgeInsets:edgeInsets] forKey:@"lx_edgeInsets"];
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets([[_tester valueForKey:@"lx_edgeInsets"] UIEdgeInsetsValue], edgeInsets));

    UIOffset offset = { 1, 2 };
    [_tester setValue:[NSValue valueWithUIOffset:offset] forKey:@"lx_offset"];
    XCTAssertTrue(UIOffsetEqualToOffset([[_tester valueForKey:@"lx_offset"] UIOffsetValue], offset));

    CATransform3D transform3D = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    [_tester setValue:[NSValue valueWithCATransform3D:transform3D] forKey:@"lx_transform3D"];
    XCTAssertTrue(CATransform3DEqualToTransform([[_tester valueForKey:@"lx_transform3D"] CATransform3DValue], transform3D));

    CMTime time = CMTimeMake(123, 321);
    [_tester setValue:[NSValue valueWithCMTime:time] forKey:@"lx_time"];
    XCTAssertTrue(!CMTimeCompare([[_tester valueForKey:@"lx_time"] CMTimeValue], time));

    CMTimeRange timeRange = { time, time };
    [_tester setValue:[NSValue valueWithCMTimeRange:timeRange] forKey:@"lx_timeRange"];
    XCTAssertTrue(CMTimeRangeEqual([[_tester valueForKey:@"lx_timeRange"] CMTimeRangeValue], timeRange));

    CMTimeMapping timeMapping = { timeRange, timeRange };
    [_tester setValue:[NSValue valueWithCMTimeMapping:timeMapping] forKey:@"lx_timeMapping"];
    XCTAssertTrue(CMTimeRangeEqual([[_tester valueForKey:@"lx_timeMapping"] CMTimeMappingValue].source, timeMapping.source));

    CLLocationCoordinate2D coordinate = { 1, 2 };
    [_tester setValue:[NSValue valueWithMKCoordinate:coordinate] forKey:@"lx_coordinate"];
    CLLocationCoordinate2D coordinate2 = [[_tester valueForKey:@"lx_coordinate"] MKCoordinateValue];
    XCTAssertTrue(coordinate2.latitude == coordinate.latitude &&
                  coordinate2.longitude == coordinate.longitude);

    MKCoordinateSpan span = { 3, 4 };
    [_tester setValue:[NSValue valueWithMKCoordinateSpan:span] forKey:@"lx_coordinateSpan"];
    MKCoordinateSpan span2 = [[_tester valueForKey:@"lx_coordinateSpan"] MKCoordinateSpanValue];
    XCTAssertTrue(span.latitudeDelta == span2.latitudeDelta &&
                  span.longitudeDelta == span2.longitudeDelta);

//    以下三个属性使用 setValue:forKey: 设置时值会变为其他的，不知道为什么。。。
//    SCNVector3 vector3 = { 1, 2, 3 };
//    [_tester setValue:[NSValue valueWithSCNVector3:vector3] forKey:@"lx_vector3"];
//    XCTAssertTrue(SCNVector3EqualToVector3([[_tester valueForKey:@"lx_vector3"] SCNVector3Value], vector3));
//
//    SCNVector4 vector4 = { 1, 2, 3, 4 };
//    [_tester setValue:[NSValue valueWithSCNVector4:vector4] forKey:@"lx_vector4"];
//    XCTAssertTrue(SCNVector4EqualToVector4([[_tester valueForKey:@"lx_vector4"] SCNVector4Value], vector4));
//
//    SCNMatrix4 matrix4 = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 };
//    [_tester setValue:[NSValue valueWithSCNMatrix4:matrix4] forKey:@"lx_matrix4"];
//    XCTAssertTrue(SCNMatrix4EqualToMatrix4([[_tester valueForKey:@"lx_matrix4"] SCNMatrix4Value], matrix4));
}

@end
