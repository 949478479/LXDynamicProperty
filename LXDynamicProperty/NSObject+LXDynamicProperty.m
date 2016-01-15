//
//  NSObject+LXDynamicProperty.m
//  LXDynamicProperty
//
//  Created by 从今以后 on 16/1/12.
//  Copyright © 2016年 从今以后. All rights reserved.
//

@import MapKit.MKGeometry;
@import ObjectiveC.runtime;
@import AVFoundation.AVTime;
@import SceneKit.SceneKitTypes;
#import "NSObject+LXDynamicProperty.h"

@interface __LXObjectWrapper : NSObject {
@public
    __weak id _weakObject;
    __unsafe_unretained id _assignObject;
}
@end
@implementation __LXObjectWrapper
@end

typedef struct {
    SEL setter;
    SEL getter;
} LXMethodSEL;

typedef struct {
    IMP setter;
    IMP getter;
} LXMethodIMP;

typedef NS_ENUM(NSUInteger, LXBaseType) {
    LXBaseTypeBOOL,
    LXBaseTypeCGFloat,
    LXBaseTypeNSInteger,
    LXBaseTypeNSUInteger,

    LXBaseTypeInt,
    LXBaseTypeBool,
    LXBaseTypeLong,
    LXBaseTypeFloat,
    LXBaseTypeDouble,
    LXBaseTypeLongLong,
    LXBaseTypeUnsignedInt,
    LXBaseTypeUnsignedLong,
    LXBaseTypeUnsignedLongLong,

    LXBaseTypeChar,
    LXBaseTypeShort,
    LXBaseTypeUnsignedChar,
    LXBaseTypeUnsignedShort,
};

static const char *const LXBaseTypeMapping[] = {
    [LXBaseTypeBOOL]             = @encode(BOOL),       // char 或 bool
    [LXBaseTypeCGFloat]          = @encode(CGFloat),    // float 或 double
    [LXBaseTypeNSInteger]        = @encode(NSInteger),  // int 或 long
    [LXBaseTypeNSUInteger]       = @encode(NSUInteger), // unsigned int 或 unsigned long

    [LXBaseTypeInt]              = @encode(int),
    [LXBaseTypeBool]             = @encode(bool),
    [LXBaseTypeLong]             = @encode(long),
    [LXBaseTypeFloat]            = @encode(float),
    [LXBaseTypeDouble]           = @encode(double),
    [LXBaseTypeLongLong]         = @encode(long long),
    [LXBaseTypeUnsignedInt]      = @encode(unsigned int),
    [LXBaseTypeUnsignedLong]     = @encode(unsigned long),
    [LXBaseTypeUnsignedLongLong] = @encode(unsigned long long),

    [LXBaseTypeChar]             = @encode(char),
    [LXBaseTypeShort]            = @encode(short),
    [LXBaseTypeUnsignedChar]     = @encode(unsigned char),
    [LXBaseTypeUnsignedShort]    = @encode(unsigned short),
};

typedef NS_ENUM(NSUInteger, LXStructType) {
    LXStructTypeNSRange,

    LXStructTypeCGRect,
    LXStructTypeCGSize,
    LXStructTypeCGPoint,
    LXStructTypeCGVector,
    LXStructTypeCGAffineTransform,

    LXStructTypeUIEdgeInsets,
    LXStructTypeUIOffset,

    LXStructTypeCATransform3D,

    LXStructTypeCMTime,
    LXStructTypeCMTimeRange,
    LXStructTypeCMTimeMapping,

    LXStructTypeMKCoordinateSpan,
    LXStructTypeCLLocationCoordinate2D,

    LXStructTypeSCNVector3,
    LXStructTypeSCNVector4,
    LXStructTypeSCNMatrix4,
};

static const char *const LXStructTypeMapping[] = {
    [LXStructTypeNSRange]                = @encode(NSRange),

    [LXStructTypeCGRect]                 = @encode(CGRect),
    [LXStructTypeCGSize]                 = @encode(CGSize),
    [LXStructTypeCGPoint]                = @encode(CGPoint),
    [LXStructTypeCGVector]               = @encode(CGVector),
    [LXStructTypeCGAffineTransform]      = @encode(CGAffineTransform),

    [LXStructTypeUIEdgeInsets]           = @encode(UIEdgeInsets),
    [LXStructTypeUIOffset]               = @encode(UIOffset),

    [LXStructTypeCATransform3D]          = @encode(CATransform3D),

    [LXStructTypeCMTime]                 = @encode(CMTime),
    [LXStructTypeCMTimeRange]            = @encode(CMTimeRange),
    [LXStructTypeCMTimeMapping]          = @encode(CMTimeMapping),

    [LXStructTypeMKCoordinateSpan]       = @encode(MKCoordinateSpan),
    [LXStructTypeCLLocationCoordinate2D] = @encode(CLLocationCoordinate2D),

    [LXStructTypeSCNVector3]             = @encode(SCNVector3),
    [LXStructTypeSCNVector4]             = @encode(SCNVector4),
    [LXStructTypeSCNMatrix4]             = @encode(SCNMatrix4),
};

@implementation NSObject (LXDynamicProperty)

static size_t kDynamicPropertyPrefixLength;

#pragma mark - 方法交换 -

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kDynamicPropertyPrefixLength = strlen(LXDynamicPropertyPrefix);
        method_exchangeImplementations(class_getClassMethod(self, @selector(resolveInstanceMethod:)),
                                       class_getClassMethod(self, @selector(__lx_resolveInstanceMethod:)));
    });
}

#pragma mark - 动态方法决议 -

+ (BOOL)__lx_resolveInstanceMethod:(SEL)sel
{
    if ([self conformsToProtocol:@protocol(LXDynamicProperty)]) {
        if ([self __lx_addDynamicPropertyIfNeed]) {
            return YES;
        }
    }
    return [self __lx_resolveInstanceMethod:sel];
}

+ (void)__lx_setDidAddDynamicProperty:(BOOL)added
{
    objc_setAssociatedObject(self, @selector(__lx_didAddDynamicProperty), @(added), 1);
}

+ (BOOL)__lx_didAddDynamicProperty
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

+ (CFMutableDictionaryRef)__lx_getSetterAndGetterSelMap
{
    CFMutableDictionaryRef setterAndGetterSelMap =
    (__bridge CFMutableDictionaryRef)objc_getAssociatedObject(self, _cmd);

    if (setterAndGetterSelMap == NULL) {

        // 当前类由于 KVO 而变成了原先类的子类
        if (!strncmp(class_getName(self), "NSKVONotifying_", 15)) {

            // 获取父类绑定的字典
            Class originalClass = class_getSuperclass(self);
            setterAndGetterSelMap = (__bridge CFMutableDictionaryRef)objc_getAssociatedObject(originalClass, _cmd);

            // 若父类字典也为空，说明尚未创建字典，创建并绑定到父类上，避免所有观察者移除而变回父类后没有字典
            if (setterAndGetterSelMap == NULL) {
                setterAndGetterSelMap = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
                objc_setAssociatedObject(originalClass, _cmd, (__bridge id)setterAndGetterSelMap, 0);
            }

            // 绑定字典到子类上，下次就有字典用了
            objc_setAssociatedObject(self, _cmd, (__bridge id)setterAndGetterSelMap, 0);

        } else {
            // 当前类是正常的类，此时字典若为空则创建字典并绑定
            setterAndGetterSelMap = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
            objc_setAssociatedObject(self, _cmd, (__bridge id)setterAndGetterSelMap, 0);
        }
    }

    return setterAndGetterSelMap;
}

+ (void)__lx_printSetterAndGetterSelMap
{
    CFMutableDictionaryRef dict = [self __lx_getSetterAndGetterSelMap];

    CFIndex count = CFDictionaryGetCount(dict);

    const void *keys[count];
    const void *values[count];

    CFDictionaryGetKeysAndValues(dict, keys, values);

    for (CFIndex i = 0; i < count; ++i) {
        printf("%s %s\n", keys[i], values[i]);
    }
}

+ (BOOL)__lx_addDynamicPropertyIfNeed
{
    if ([self __lx_didAddDynamicProperty]) {
        return NO;
    }
    [self __lx_setDidAddDynamicProperty:YES];

    uint outCount;
    objc_property_t *properties = class_copyPropertyList(self, &outCount);
    for (uint i = 0; i < outCount; ++i) {
        [self __lx_addIMPForProperty:properties[i]];
    }
    free(properties);

    return YES;
}

+ (void)__lx_addIMPForProperty:(objc_property_t)property
{
    if (!__LXValidateDynamicProperty(property)) {
        return;
    }

    char *typeEncode = property_copyAttributeValue(property, "T");

    if (typeEncode[0] == '{') {
        size_t count = sizeof(LXStructTypeMapping) / sizeof(char *);
        for (size_t i = 0; i < count; ++i) {
            if (!strcmp(LXStructTypeMapping[i], typeEncode)) { 

                char *setterType, *getterType;
                __LXCopyMethodTypeForTypeEncode(typeEncode, &setterType, &getterType);

                LXMethodSEL sel = [self __lx_registerSelForProperty:property];
                LXMethodIMP imp = LXStructTypeAndIMPMap[i];

                class_addMethod(self, sel.setter, imp.setter, setterType);
                class_addMethod(self, sel.getter, imp.getter, getterType);

                free(setterType);
                free(getterType);

                goto end;
            }
        }
    } else if (typeEncode[0] == '@') {

        LXMethodSEL sel = [self __lx_registerSelForProperty:property];

        // strong
        char *retainPolicy = property_copyAttributeValue(property, "&");
        if (retainPolicy) {
            free(retainPolicy);
            class_addMethod(self, sel.setter, (IMP)__lx_id_retain_dynamicSetterIMP, "v@:@");
            class_addMethod(self, sel.getter, (IMP)__lx_id_retain_dynamicGetterIMP, "@@:");
            goto end;
        }

        // copy
        char *copyPolicy = property_copyAttributeValue(property, "C");
        if (copyPolicy) {
            free(copyPolicy);
            class_addMethod(self, sel.setter, (IMP)__lx_id_copy_dynamicSetterIMP, "v@:@");
            class_addMethod(self, sel.getter, (IMP)__lx_id_copy_dynamicGetterIMP, "@@:");
            goto end;
        }

        // weak
        char *weakPolicy = property_copyAttributeValue(property, "W");
        if (weakPolicy) {
            free(weakPolicy);
            class_addMethod(self, sel.setter, (IMP)__lx_id_weak_dynamicSetterIMP, "v@:@");
            class_addMethod(self, sel.getter, (IMP)__lx_id_weak_dynamicGetterIMP, "@@:");
            goto end;
        }

        // unsafe_unretained
        class_addMethod(self, sel.setter, (IMP)__lx_id_assign_dynamicSetterIMP, "v@:@");
        class_addMethod(self, sel.getter, (IMP)__lx_id_assign_dynamicGetterIMP, "@@:");

    } else if (strlen(typeEncode) == 1) {
        size_t count = sizeof(LXBaseTypeMapping) / sizeof(char *);
        for (size_t i = 0; i < count; ++i) {
            if (LXBaseTypeMapping[i][0] == typeEncode[0]) {

                char *setterType, *getterType;
                __LXCopyMethodTypeForTypeEncode(typeEncode, &setterType, &getterType);

                LXMethodSEL sel = [self __lx_registerSelForProperty:property];
                LXMethodIMP imp = LXBaseTypeAndIMPMap[i];

                class_addMethod(self, sel.setter, imp.setter, setterType);
                class_addMethod(self, sel.getter, imp.getter, getterType);

                free(setterType);
                free(getterType);

                goto end;
            }
        }
    }

end:;
    free(typeEncode);
}

+ (LXMethodSEL)__lx_registerSelForProperty:(objc_property_t)property
{
    char *propertyName = (char *)property_getName(property);
    char *setterName   = __LXCopySetterNameForProperty(property);
    char *getterName   = property_copyAttributeValue(property, "G") ?: propertyName;

    SEL setter = sel_registerName(setterName);
    SEL getter = sel_registerName(getterName);

    CFDictionarySetValue([self __lx_getSetterAndGetterSelMap], setter, getter);

    free(setterName);
    if (getterName != propertyName) {
        free(getterName);
    }

    return (LXMethodSEL){ setter, getter };
}

#pragma mark - 工具函数 -

static BOOL __LXValidateDynamicProperty(objc_property_t property)
{
    char *dynamic = property_copyAttributeValue(property, "D");
    if (dynamic == NULL) {
        return NO;
    }
    free(dynamic);

    const char *propertyName = property_getName(property);
    return !strncmp(LXDynamicPropertyPrefix, propertyName, kDynamicPropertyPrefixLength);
}

static char *__LXCopySetterNameForProperty(objc_property_t property)
{
    char *setterName = property_copyAttributeValue(property, "S");

    if (setterName) {
        return setterName;
    }

    const char *propertyName = property_getName(property);

    // lx_xxx => setLx_xxx:
    size_t length = strlen(propertyName) + 5;
    setterName = calloc(length, sizeof(char));
    strcpy(setterName, "set");
    strcat(setterName, propertyName);
    setterName[3] = toupper(propertyName[0]);
    setterName[length - 2] = ':';

    return setterName;
}

static void __LXCopyMethodTypeForTypeEncode(const char *typeEncode, char **setterType, char **getterType)
{
    size_t setterLength = strlen(typeEncode) + 4;
    size_t getterLength = strlen(typeEncode) + 3;

    // 格式形如 v@:i
    *setterType = calloc(setterLength, sizeof(char));
    strcpy(*setterType, "v@:");
    strcat(*setterType, typeEncode);

    // 格式形如 i@:
    *getterType = calloc(getterLength, sizeof(char));
    strcpy(*getterType, typeEncode);
    strcat(*getterType, "@:");
}

#pragma mark - 动态方法实现 -

#define LXBaseTypeDynamicIMP(TypeName, BaseType) \
static void __lx_##TypeName##_dynamicSetterIMP(id self, SEL _cmd, BaseType newValue) \
{ \
    CFMutableDictionaryRef selMap = [object_getClass(self) __lx_getSetterAndGetterSelMap]; \
    const char *getterSel = CFDictionaryGetValue(selMap, _cmd); \
    objc_setAssociatedObject(self, getterSel, @(newValue), OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
} \
static BaseType __lx_##TypeName##_dynamicGetterIMP(id self, SEL _cmd) \
{ \
    return [objc_getAssociatedObject(self, _cmd) TypeName##Value]; \
}

#define LXStructTypeDynamicIMP(StructType) \
static void __lx_##StructType##_dynamicSetterIMP(id self, SEL _cmd, StructType newValue) \
{ \
    CFMutableDictionaryRef selMap = [object_getClass(self) __lx_getSetterAndGetterSelMap]; \
\
    const char *getterSel = CFDictionaryGetValue(selMap, _cmd); \
\
    /* 若因 KVO 而生成了子类，很多结构体的 setter 会被加上 _original_ 前缀 */ \
    if (getterSel == NULL) { \
        const char *setterName = sel_getName(_cmd); \
        char originalSetterName[strlen(setterName) - 9]; \
        strcpy(originalSetterName, setterName + 10); \
        getterSel = CFDictionaryGetValue(selMap, sel_getUid(originalSetterName)); \
    } \
\
    NSValue *value = [NSValue valueWith##StructType:newValue]; \
    objc_setAssociatedObject(self, getterSel, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
} \
static StructType __lx_##StructType##_dynamicGetterIMP(id self, SEL _cmd) \
{ \
    return [objc_getAssociatedObject(self, _cmd) StructType##Value]; \
}

LXBaseTypeDynamicIMP(int, int)
LXBaseTypeDynamicIMP(bool, bool)
LXBaseTypeDynamicIMP(char, char)
LXBaseTypeDynamicIMP(long, long)
LXBaseTypeDynamicIMP(short, short)
LXBaseTypeDynamicIMP(float, float)
LXBaseTypeDynamicIMP(double, double)
LXBaseTypeDynamicIMP(integer, NSInteger)
LXBaseTypeDynamicIMP(longLong, long long)
LXBaseTypeDynamicIMP(unsignedInt, unsigned int)
LXBaseTypeDynamicIMP(unsignedInteger, NSUInteger)
LXBaseTypeDynamicIMP(unsignedChar, unsigned char)
LXBaseTypeDynamicIMP(unsignedLong, unsigned long)
LXBaseTypeDynamicIMP(unsignedShort, unsigned short)
LXBaseTypeDynamicIMP(unsignedLongLong, unsigned long long)

LXStructTypeDynamicIMP(CGRect)
LXStructTypeDynamicIMP(CGSize)
LXStructTypeDynamicIMP(CGPoint)
LXStructTypeDynamicIMP(CGVector)
LXStructTypeDynamicIMP(CGAffineTransform)
LXStructTypeDynamicIMP(UIEdgeInsets)
LXStructTypeDynamicIMP(UIOffset)
LXStructTypeDynamicIMP(CATransform3D)
LXStructTypeDynamicIMP(CMTime)
LXStructTypeDynamicIMP(CMTimeRange)
LXStructTypeDynamicIMP(CMTimeMapping)
LXStructTypeDynamicIMP(SCNVector3)
LXStructTypeDynamicIMP(SCNVector4)
LXStructTypeDynamicIMP(SCNMatrix4)

//static void __lx_SCNVector3_dynamicSetterIMP(id self, SEL _cmd, SCNVector3 newValue)
//{
//    CFMutableDictionaryRef selMap = [object_getClass(self) __lx_getSetterAndGetterSelMap];
//
//    const char *getterSel = CFDictionaryGetValue(selMap, _cmd);
//
//    /* 若因 KVO 而生成了子类，很多结构体的 setter 会被加上 _original_ 前缀 */
//    if (getterSel == NULL) { 
//        const char *setterName = sel_getName(_cmd);
//        char originalSetterName[strlen(setterName) - 9];
//        strcpy(originalSetterName, setterName + 10);
//        getterSel = CFDictionaryGetValue(selMap, sel_getUid(originalSetterName));
//    }
//
//    NSValue *value = [NSValue valueWithSCNVector3:newValue];
//    objc_setAssociatedObject(self, getterSel, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//}
//static SCNVector3 __lx_SCNVector3_dynamicGetterIMP(id self, SEL _cmd)
//{
//    return [objc_getAssociatedObject(self, _cmd) SCNVector3Value];
//}

// NSRange 格式比较特殊。。。
static void __lx_NSRange_dynamicSetterIMP(id self, SEL _cmd, NSRange newValue)
{
    CFMutableDictionaryRef selMap = [object_getClass(self) __lx_getSetterAndGetterSelMap];
    const char *getterSel = CFDictionaryGetValue(selMap, _cmd);
    NSValue *value = [NSValue valueWithRange:newValue];
    objc_setAssociatedObject(self, getterSel, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static NSRange __lx_NSRange_dynamicGetterIMP(id self, SEL _cmd)
{
    return [objc_getAssociatedObject(self, _cmd) rangeValue];
}

// CLLocationCoordinate2D 和 MKCoordinateSpan 均为此种类型，@encode() 编码均为 {?=dd}，无法分辨，
// 因此无法针对性地使用 valueWith... 方法，所以统一使用自定义的同类型结构体进行处理。
typedef struct {
    double x;
    double y;
} LXCoordinate2D;

static void __lx_LXCoordinate2D_dynamicSetterIMP(id self, SEL _cmd, LXCoordinate2D newValue)
{
    CFMutableDictionaryRef selMap = [object_getClass(self) __lx_getSetterAndGetterSelMap];

    const char *getterSel = CFDictionaryGetValue(selMap, _cmd);

    if (getterSel == NULL) {
        const char *setterName = sel_getName(_cmd);
        char originalSetterName[strlen(setterName) - 9];
        strcpy(originalSetterName, setterName + 10);
        getterSel = CFDictionaryGetValue(selMap, sel_getUid(originalSetterName));
    }

    NSValue *value = [NSValue value:&newValue withObjCType:@encode(LXCoordinate2D)];
    
    objc_setAssociatedObject(self, getterSel, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static LXCoordinate2D __lx_LXCoordinate2D_dynamicGetterIMP(id self, SEL _cmd)
{
    LXCoordinate2D value;
    [objc_getAssociatedObject(self, _cmd) getValue:&value];
    return value;
}

static void __lx_id_retain_dynamicSetterIMP(id self, SEL _cmd, id newValue)
{
    const char *getterSel = CFDictionaryGetValue([object_getClass(self) __lx_getSetterAndGetterSelMap], _cmd);
    objc_setAssociatedObject(self, getterSel, newValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static id __lx_id_retain_dynamicGetterIMP(id self, SEL _cmd)
{
    return objc_getAssociatedObject(self, _cmd);
}

static void __lx_id_copy_dynamicSetterIMP(id self, SEL _cmd, id newValue)
{
    const char *getterSel = CFDictionaryGetValue([object_getClass(self) __lx_getSetterAndGetterSelMap], _cmd);
    objc_setAssociatedObject(self, getterSel, newValue, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

static id __lx_id_copy_dynamicGetterIMP(id self, SEL _cmd)
{
    return objc_getAssociatedObject(self, _cmd);
}

static void __lx_id_weak_dynamicSetterIMP(id self, SEL _cmd, id newValue)
{
    const char *getterSel = CFDictionaryGetValue([object_getClass(self) __lx_getSetterAndGetterSelMap], _cmd);
    __LXObjectWrapper *wrapper = objc_getAssociatedObject(self, getterSel);
    if (!wrapper) {
        wrapper = [__LXObjectWrapper new];
        objc_setAssociatedObject(self, getterSel, wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    wrapper->_weakObject = newValue;
}

static id __lx_id_weak_dynamicGetterIMP(id self, SEL _cmd)
{
    return ((__LXObjectWrapper *)objc_getAssociatedObject(self, _cmd))->_weakObject;
}

static void __lx_id_assign_dynamicSetterIMP(id self, SEL _cmd, id newValue)
{
    const char *getterSel = CFDictionaryGetValue([object_getClass(self) __lx_getSetterAndGetterSelMap], _cmd);
    __LXObjectWrapper *wrapper = objc_getAssociatedObject(self, getterSel);
    if (!wrapper) {
        wrapper = [__LXObjectWrapper new];
        objc_setAssociatedObject(self, getterSel, wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    wrapper->_assignObject = newValue;
}

static id __lx_id_assign_dynamicGetterIMP(id self, SEL _cmd)
{
    return ((__LXObjectWrapper *)objc_getAssociatedObject(self, _cmd))->_assignObject;
}

static const LXMethodIMP LXBaseTypeAndIMPMap[] = {
    [LXBaseTypeBOOL]             = { (IMP)__lx_bool_dynamicSetterIMP, (IMP)__lx_bool_dynamicGetterIMP },
    [LXBaseTypeCGFloat]          = { CGFLOAT_IS_DOUBLE ? (IMP)__lx_double_dynamicSetterIMP : (IMP)__lx_float_dynamicSetterIMP,
                                     CGFLOAT_IS_DOUBLE ? (IMP)__lx_double_dynamicGetterIMP : (IMP)__lx_float_dynamicGetterIMP, },
    [LXBaseTypeNSInteger]        = { (IMP)__lx_integer_dynamicSetterIMP, (IMP)__lx_integer_dynamicGetterIMP },
    [LXBaseTypeNSUInteger]       = { (IMP)__lx_unsignedInteger_dynamicSetterIMP, (IMP)__lx_unsignedInteger_dynamicGetterIMP },

    [LXBaseTypeInt]              = { (IMP)__lx_int_dynamicSetterIMP, (IMP)__lx_int_dynamicGetterIMP },
    [LXBaseTypeBool]             = { (IMP)__lx_bool_dynamicSetterIMP, (IMP)__lx_bool_dynamicGetterIMP, },
    [LXBaseTypeLong]             = { (IMP)__lx_long_dynamicSetterIMP, (IMP)__lx_long_dynamicGetterIMP },
    [LXBaseTypeFloat]            = { (IMP)__lx_float_dynamicSetterIMP, (IMP)__lx_float_dynamicGetterIMP, },
    [LXBaseTypeDouble]           = { (IMP)__lx_double_dynamicSetterIMP, (IMP)__lx_double_dynamicGetterIMP },
    [LXBaseTypeLongLong]         = { (IMP)__lx_longLong_dynamicSetterIMP, (IMP)__lx_longLong_dynamicGetterIMP },
    [LXBaseTypeUnsignedInt]      = { (IMP)__lx_unsignedInt_dynamicSetterIMP, (IMP)__lx_unsignedInt_dynamicGetterIMP },
    [LXBaseTypeUnsignedLong]     = { (IMP)__lx_unsignedLong_dynamicSetterIMP, (IMP)__lx_unsignedLong_dynamicGetterIMP },
    [LXBaseTypeUnsignedLongLong] = { (IMP)__lx_unsignedLongLong_dynamicSetterIMP, (IMP)__lx_unsignedLongLong_dynamicGetterIMP },

    [LXBaseTypeChar]             = { (IMP)__lx_char_dynamicSetterIMP, (IMP)__lx_char_dynamicGetterIMP },
    [LXBaseTypeShort]            = { (IMP)__lx_short_dynamicSetterIMP, (IMP)__lx_short_dynamicGetterIMP },
    [LXBaseTypeUnsignedChar]     = { (IMP)__lx_unsignedChar_dynamicSetterIMP, (IMP)__lx_unsignedChar_dynamicGetterIMP },
    [LXBaseTypeUnsignedShort]    = { (IMP)__lx_unsignedShort_dynamicSetterIMP, (IMP)__lx_unsignedShort_dynamicGetterIMP },
};

static const LXMethodIMP LXStructTypeAndIMPMap[] = {
    [LXStructTypeNSRange]                = { (IMP)__lx_NSRange_dynamicSetterIMP, (IMP)__lx_NSRange_dynamicGetterIMP },

    [LXStructTypeCGRect]                 = { (IMP)__lx_CGRect_dynamicSetterIMP, (IMP)__lx_CGRect_dynamicGetterIMP },
    [LXStructTypeCGSize]                 = { (IMP)__lx_CGSize_dynamicSetterIMP, (IMP)__lx_CGSize_dynamicGetterIMP },
    [LXStructTypeCGPoint]                = { (IMP)__lx_CGPoint_dynamicSetterIMP, (IMP)__lx_CGPoint_dynamicGetterIMP },
    [LXStructTypeCGVector]               = { (IMP)__lx_CGVector_dynamicSetterIMP, (IMP)__lx_CGVector_dynamicGetterIMP },
    [LXStructTypeCGAffineTransform]      = { (IMP)__lx_CGAffineTransform_dynamicSetterIMP, (IMP)__lx_CGAffineTransform_dynamicGetterIMP },

    [LXStructTypeUIEdgeInsets]           = { (IMP)__lx_UIEdgeInsets_dynamicSetterIMP, (IMP)__lx_UIEdgeInsets_dynamicGetterIMP },
    [LXStructTypeUIOffset]               = { (IMP)__lx_UIOffset_dynamicSetterIMP, (IMP)__lx_UIOffset_dynamicGetterIMP },

    [LXStructTypeCATransform3D]          = { (IMP)__lx_CATransform3D_dynamicSetterIMP, (IMP)__lx_CATransform3D_dynamicGetterIMP },

    [LXStructTypeCMTime]                 = { (IMP)__lx_CMTime_dynamicSetterIMP, (IMP)__lx_CMTime_dynamicGetterIMP },
    [LXStructTypeCMTimeRange]            = { (IMP)__lx_CMTimeRange_dynamicSetterIMP, (IMP)__lx_CMTimeRange_dynamicGetterIMP },
    [LXStructTypeCMTimeMapping]          = { (IMP)__lx_CMTimeMapping_dynamicSetterIMP, (IMP)__lx_CMTimeMapping_dynamicGetterIMP },

    [LXStructTypeMKCoordinateSpan]       = { (IMP)__lx_LXCoordinate2D_dynamicSetterIMP, (IMP)__lx_LXCoordinate2D_dynamicGetterIMP },
    [LXStructTypeCLLocationCoordinate2D] = { (IMP)__lx_LXCoordinate2D_dynamicSetterIMP, (IMP)__lx_LXCoordinate2D_dynamicGetterIMP },

    [LXStructTypeSCNVector3]             = { (IMP)__lx_SCNVector3_dynamicSetterIMP, (IMP)__lx_SCNVector3_dynamicGetterIMP },
    [LXStructTypeSCNVector4]             = { (IMP)__lx_SCNVector4_dynamicSetterIMP, (IMP)__lx_SCNVector4_dynamicGetterIMP },
    [LXStructTypeSCNMatrix4]             = { (IMP)__lx_SCNMatrix4_dynamicSetterIMP, (IMP)__lx_SCNMatrix4_dynamicGetterIMP },
};

@end
