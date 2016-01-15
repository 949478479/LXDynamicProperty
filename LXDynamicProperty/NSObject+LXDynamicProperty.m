//
//  NSObject+LXDynamicProperty.m
//  LXDynamicProperty
//
//  Created by 从今以后 on 16/1/12.
//  Copyright © 2016年 从今以后. All rights reserved.
//

@import UIKit.UIGeometry;
@import MapKit.MKGeometry;
@import ObjectiveC.runtime;
@import AVFoundation.AVTime;
@import SceneKit.SceneKitTypes;
#import "NSObject+LXDynamicProperty.h"

@implementation NSNumber (LXCGLoatSupport)

- (CGFloat)CGFloatValue
{
    return CGFLOAT_IS_DOUBLE ? [self doubleValue] : [self floatValue];
}

@end

@interface __LXObjectWrapper : NSObject {
@public
    __weak id _weakObject;
    __unsafe_unretained id _assignObject;
}
@end
@implementation __LXObjectWrapper
@end

// CLLocationCoordinate2D 和 MKCoordinateSpan 均为此种类型，@encode() 编码均为 {?=dd}，无法分辨，
// 因此无法针对性地使用 valueWith... 方法，所以统一使用自定义的同类型结构体进行处理。
typedef struct {
    double x;
    double y;
} LXCoordinate2D;

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
    LXBaseTypeLong,
    LXBaseTypeFloat,
    LXBaseTypeDouble,
    LXBaseTypeLongLong,
    LXBaseTypeUnsignedInt,
    LXBaseTypeUnsignedLong,
    LXBaseTypeUnsignedLongLong,

    LXBaseTypeBool,
    LXBaseTypeChar,
    LXBaseTypeShort,
    LXBaseTypeUnsignedChar,
    LXBaseTypeUnsignedShort,
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

static const char * const LXBaseTypeMap[] = {
    [LXBaseTypeBOOL]             = @encode(BOOL),       // char 或 bool
    [LXBaseTypeCGFloat]          = @encode(CGFloat),    // float 或 double
    [LXBaseTypeNSInteger]        = @encode(NSInteger),  // int 或 long
    [LXBaseTypeNSUInteger]       = @encode(NSUInteger), // unsigned int 或 unsigned long

    [LXBaseTypeInt]              = @encode(int),
    [LXBaseTypeLong]             = @encode(long),
    [LXBaseTypeFloat]            = @encode(float),
    [LXBaseTypeDouble]           = @encode(double),
    [LXBaseTypeLongLong]         = @encode(long long),
    [LXBaseTypeUnsignedInt]      = @encode(unsigned int),
    [LXBaseTypeUnsignedLong]     = @encode(unsigned long),
    [LXBaseTypeUnsignedLongLong] = @encode(unsigned long long),

    [LXBaseTypeBool]             = @encode(bool),
    [LXBaseTypeChar]             = @encode(char),
    [LXBaseTypeShort]            = @encode(short),
    [LXBaseTypeUnsignedChar]     = @encode(unsigned char),
    [LXBaseTypeUnsignedShort]    = @encode(unsigned short),
};

static const char * const LXStructTypeMap[] = {
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

static size_t LXDynamicPropertyPrefixLength;
static const char * const kLXKVOSetterPrefix = "_original_";
static const char * const kLXKVOClassPrefix  = "NSKVONotifying_";

@implementation NSObject (LXDynamicProperty)

+ (void)load
{
    LXDynamicPropertyPrefixLength = strlen(LXDynamicPropertyPrefix);
}

#pragma mark - 动态方法决议 -

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
+ (BOOL)resolveInstanceMethod:(SEL)sel
{
    if (!class_isMetaClass(self) &&
        class_conformsToProtocol(self, @protocol(LXDynamicProperty)) &&
        [self __lx_addDynamicPropertyIfNeed]) {
        return YES;
    }
    return NO; // NSObject 的实现就是直接返回 NO 而已
}
#pragma clang diagnostic pop

+ (BOOL)__lx_addDynamicPropertyIfNeed
{
    if ([self __lx_didAddDynamicProperty]) {
        return NO;
    }

    uint outCount;
    objc_property_t *properties = class_copyPropertyList(self, &outCount);
    for (uint i = 0; i < outCount; ++i) {
        if (__LXValidateDynamicProperty(properties[i])) {
            [self __lx_addIMPForProperty:properties[i]];
        }
    }
    free(properties);

    return YES;
}

+ (BOOL)__lx_didAddDynamicProperty
{
    BOOL didAdd = [objc_getAssociatedObject(self, _cmd) boolValue];
    if (!didAdd) {
        printf("__AddDynamicProperty =========== %p %s %s\n",
               self, class_isMetaClass(self) ? "isMetaClass" : "",
               class_getName(self));
        objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return didAdd;
}

static BOOL __LXValidateDynamicProperty(objc_property_t property)
{
    char *dynamic = property_copyAttributeValue(property, "D");
    if (!dynamic) {
        return NO;
    }
    free(dynamic);

    const char *propertyName = property_getName(property);
    return !strncmp(LXDynamicPropertyPrefix, propertyName, LXDynamicPropertyPrefixLength);
}

+ (void)__lx_addIMPForProperty:(objc_property_t)property
{
    char *typeEncode = property_copyAttributeValue(property, "T");

    if (typeEncode[0] == '@') {
        [self __lx_addIMPForObjectTypeProperty:property];
    } else if (strlen(typeEncode) == 1) {
        [self __lx_addIMPForBaseTypeProperty:property typeEncode:typeEncode];
    } else if (typeEncode[0] == '{') {
        [self __lx_addIMPForStructTypeProperty:property typeEncode:typeEncode];
    }

    free(typeEncode);
}

+ (void)__lx_addIMPForObjectTypeProperty:(objc_property_t)property
{
    const char *setterType = "v@:@"; // void id SEL id
    const char *getterType = "@@:";  // id id SEL

    LXMethodSEL sel = [self __lx_registerSelForProperty:property];

    void (^_addMethodIMP)(IMP, IMP) = ^(IMP setter, IMP getter) {
        class_addMethod(self, sel.setter, setter, setterType);
        class_addMethod(self, sel.getter, getter, getterType);
    };

    uint outCount;
    objc_property_attribute_t *attributeList = property_copyAttributeList(property, &outCount);
    for (uint i = 0; i < outCount; ++i) {
        switch (attributeList[i].name[0]) {
            case '&':
                _addMethodIMP((IMP)__lx_id_retain_dynamicSetterIMP, (IMP)__lx_id_retain_dynamicGetterIMP);
                goto done;
            case 'C':
                _addMethodIMP((IMP)__lx_id_copy_dynamicSetterIMP, (IMP)__lx_id_copy_dynamicGetterIMP);
                goto done;
            case 'W':
                _addMethodIMP((IMP)__lx_id_weak_dynamicSetterIMP, (IMP)__lx_id_weak_dynamicGetterIMP);
                goto done;
        }
    }
    _addMethodIMP((IMP)__lx_id_assign_dynamicSetterIMP, (IMP)__lx_id_assign_dynamicGetterIMP);
done:
    free(attributeList);
}

+ (void)__lx_addIMPForBaseTypeProperty:(objc_property_t)property typeEncode:(const char *)typeEncode
{
    size_t count = sizeof(LXBaseTypeMap) / sizeof(char *);

    for (size_t i = 0; i < count; ++i) {

        if (LXBaseTypeMap[i][0] == typeEncode[0]) {

            char *setterType, *getterType;
            __LXCopyMethodTypeForTypeEncode(typeEncode, &setterType, &getterType);

            LXMethodSEL sel = [self __lx_registerSelForProperty:property];
            LXMethodIMP imp = LXBaseTypeAndIMPMap[i];

            class_addMethod(self, sel.setter, imp.setter, setterType);
            class_addMethod(self, sel.getter, imp.getter, getterType);

            free(setterType);
            free(getterType);

            return;
        }
    }
}

+ (void)__lx_addIMPForStructTypeProperty:(objc_property_t)property typeEncode:(const char *)typeEncode
{
    size_t count = sizeof(LXStructTypeMap) / sizeof(char *);

    for (size_t i = 0; i < count; ++i) {

        if (!strcmp(LXStructTypeMap[i], typeEncode)) {

            char *setterType, *getterType;
            __LXCopyMethodTypeForTypeEncode(typeEncode, &setterType, &getterType);

            LXMethodSEL sel = [self __lx_registerSelForProperty:property];
            LXMethodIMP imp = LXStructTypeAndIMPMap[i];

            class_addMethod(self, sel.setter, imp.setter, setterType);
            class_addMethod(self, sel.getter, imp.getter, getterType);

            free(setterType);
            free(getterType);

            return;
        }
    }
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

static SEL __LXGetGetterSelForSetterSel(id self, SEL _cmd)
{
    CFMutableDictionaryRef selMap = [object_getClass(self) __lx_getSetterAndGetterSelMap];

    SEL getterSel = (SEL)CFDictionaryGetValue(selMap, _cmd);

    /* 若因 KVO 而生成了子类，有的结构体的 setter 会被加上 _original_ 前缀 */
    if (getterSel == NULL) {
        const char *setterName = sel_getName(_cmd);
        size_t length = strlen(kLXKVOSetterPrefix);
        if (!strncmp(setterName, kLXKVOSetterPrefix, length)) {
            getterSel = (SEL)CFDictionaryGetValue(selMap, sel_getUid(setterName + length));
        }
    }

    return getterSel;
}

+ (CFMutableDictionaryRef)__lx_getSetterAndGetterSelMap
{
    CFMutableDictionaryRef setterAndGetterSelMap =
    (__bridge CFMutableDictionaryRef)objc_getAssociatedObject(self, _cmd);

    if (setterAndGetterSelMap) {
        return setterAndGetterSelMap;
    }

    if (!strncmp(class_getName(self), kLXKVOClassPrefix, strlen(kLXKVOClassPrefix))) {

        Class originalClass = class_getSuperclass(self);
        setterAndGetterSelMap = (__bridge CFMutableDictionaryRef)objc_getAssociatedObject(originalClass, _cmd);

        if (!setterAndGetterSelMap) {
            setterAndGetterSelMap = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
            objc_setAssociatedObject(originalClass, _cmd, (__bridge id)setterAndGetterSelMap, 0);
        }

        objc_setAssociatedObject(self, _cmd, (__bridge id)setterAndGetterSelMap, 0);

    } else {
        setterAndGetterSelMap = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
        objc_setAssociatedObject(self, _cmd, (__bridge id)setterAndGetterSelMap, 0);
    }
    
    return setterAndGetterSelMap;
}

#pragma mark - 动态方法实现 -

#define LXBaseTypeDynamicIMP(typeName, baseType) \
static void __lx_##typeName##_dynamicSetterIMP(id self, SEL _cmd, baseType newValue) \
{ \
    SEL getterSel = __LXGetGetterSelForSetterSel(self, _cmd); \
    objc_setAssociatedObject(self, getterSel, @(newValue), OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
} \
\
static baseType __lx_##typeName##_dynamicGetterIMP(id self, SEL _cmd) \
{ \
    return [objc_getAssociatedObject(self, _cmd) typeName##Value]; \
}

LXBaseTypeDynamicIMP(int, int)
LXBaseTypeDynamicIMP(bool, bool)
LXBaseTypeDynamicIMP(char, char)
LXBaseTypeDynamicIMP(long, long)
LXBaseTypeDynamicIMP(short, short)
LXBaseTypeDynamicIMP(float, float)
LXBaseTypeDynamicIMP(double, double)
LXBaseTypeDynamicIMP(CGFloat, CGFloat)
LXBaseTypeDynamicIMP(integer, NSInteger)
LXBaseTypeDynamicIMP(longLong, long long)
LXBaseTypeDynamicIMP(unsignedInt, unsigned int)
LXBaseTypeDynamicIMP(unsignedInteger, NSUInteger)
LXBaseTypeDynamicIMP(unsignedChar, unsigned char)
LXBaseTypeDynamicIMP(unsignedLong, unsigned long)
LXBaseTypeDynamicIMP(unsignedShort, unsigned short)
LXBaseTypeDynamicIMP(unsignedLongLong, unsigned long long)

#define LXStructTypeDynamicIMP(type) \
static void __lx_##type##_dynamicSetterIMP(id self, SEL _cmd, type newValue) \
{ \
    SEL getterSel = __LXGetGetterSelForSetterSel(self, _cmd); \
    NSValue *value = [NSValue value:&newValue withObjCType:@encode(type)]; \
    objc_setAssociatedObject(self, getterSel, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
} \
\
static type __lx_##type##_dynamicGetterIMP(id self, SEL _cmd) \
{ \
    type value; \
    [objc_getAssociatedObject(self, _cmd) getValue:&value]; \
    return value; \
}

LXStructTypeDynamicIMP(NSRange)
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
LXStructTypeDynamicIMP(LXCoordinate2D)

#define LXObjectTypeDynamicIMP_A(typeName, policy) \
static void __lx_##typeName##_dynamicSetterIMP(id self, SEL _cmd, id newValue) \
{ \
    SEL getterSel = __LXGetGetterSelForSetterSel(self, _cmd); \
    __LXObjectWrapper *wrapper = objc_getAssociatedObject(self, getterSel); \
    if (!wrapper) { \
        wrapper = [__LXObjectWrapper new]; \
        objc_setAssociatedObject(self, getterSel, wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
    } \
    wrapper->_##policy##Object = newValue; \
} \
\
static id __lx_##typeName##_dynamicGetterIMP(id self, SEL _cmd) \
{ \
    return ((__LXObjectWrapper *)objc_getAssociatedObject(self, _cmd))->_##policy##Object; \
}

#define LXObjectTypeDynamicIMP_B(typeName, policy) \
static void __lx_##typeName##_dynamicSetterIMP(id self, SEL _cmd, id newValue) \
{ \
    objc_setAssociatedObject(self, __LXGetGetterSelForSetterSel(self, _cmd), newValue, policy); \
} \
\
static id __lx_##typeName##_dynamicGetterIMP(id self, SEL _cmd) \
{ \
    return objc_getAssociatedObject(self, _cmd); \
}

LXObjectTypeDynamicIMP_A(id_weak, weak)
LXObjectTypeDynamicIMP_A(id_assign, assign)
LXObjectTypeDynamicIMP_B(id_copy, OBJC_ASSOCIATION_COPY_NONATOMIC)
LXObjectTypeDynamicIMP_B(id_retain, OBJC_ASSOCIATION_RETAIN_NONATOMIC)

#define LXMethodIMP(typeName) { \
    (IMP)__lx_##typeName##_dynamicSetterIMP, \
    (IMP)__lx_##typeName##_dynamicGetterIMP, \
}

static const LXMethodIMP LXBaseTypeAndIMPMap[] = {
    [LXBaseTypeBOOL]             = LXMethodIMP(bool),
    [LXBaseTypeCGFloat]          = LXMethodIMP(CGFloat),
    [LXBaseTypeNSInteger]        = LXMethodIMP(integer),
    [LXBaseTypeNSUInteger]       = LXMethodIMP(unsignedInteger),

    [LXBaseTypeInt]              = LXMethodIMP(int),
    [LXBaseTypeLong]             = LXMethodIMP(long),
    [LXBaseTypeFloat]            = LXMethodIMP(float),
    [LXBaseTypeDouble]           = LXMethodIMP(double),
    [LXBaseTypeLongLong]         = LXMethodIMP(longLong),
    [LXBaseTypeUnsignedInt]      = LXMethodIMP(unsignedInt),
    [LXBaseTypeUnsignedLong]     = LXMethodIMP(unsignedLong),
    [LXBaseTypeUnsignedLongLong] = LXMethodIMP(unsignedLongLong),

    [LXBaseTypeBool]             = LXMethodIMP(bool),
    [LXBaseTypeChar]             = LXMethodIMP(char),
    [LXBaseTypeShort]            = LXMethodIMP(short),
    [LXBaseTypeUnsignedChar]     = LXMethodIMP(unsignedChar),
    [LXBaseTypeUnsignedShort]    = LXMethodIMP(unsignedShort),
};

static const LXMethodIMP LXStructTypeAndIMPMap[] = {
    [LXStructTypeNSRange]                = LXMethodIMP(NSRange),

    [LXStructTypeCGRect]                 = LXMethodIMP(CGRect),

    [LXStructTypeCGSize]                 = LXMethodIMP(CGSize),
    [LXStructTypeCGPoint]                = LXMethodIMP(CGPoint),
    [LXStructTypeCGVector]               = LXMethodIMP(CGVector),
    [LXStructTypeCGAffineTransform]      = LXMethodIMP(CGAffineTransform),

    [LXStructTypeUIEdgeInsets]           = LXMethodIMP(UIEdgeInsets),
    [LXStructTypeUIOffset]               = LXMethodIMP(UIOffset),

    [LXStructTypeCATransform3D]          = LXMethodIMP(CATransform3D),

    [LXStructTypeCMTime]                 = LXMethodIMP(CMTime),
    [LXStructTypeCMTimeRange]            = LXMethodIMP(CMTimeRange),
    [LXStructTypeCMTimeMapping]          = LXMethodIMP(CMTimeMapping),

    [LXStructTypeMKCoordinateSpan]       = LXMethodIMP(LXCoordinate2D),
    [LXStructTypeCLLocationCoordinate2D] = LXMethodIMP(LXCoordinate2D),

    [LXStructTypeSCNVector3]             = LXMethodIMP(SCNVector3),
    [LXStructTypeSCNVector4]             = LXMethodIMP(SCNVector4),
    [LXStructTypeSCNMatrix4]             = LXMethodIMP(SCNMatrix4),
};

@end
