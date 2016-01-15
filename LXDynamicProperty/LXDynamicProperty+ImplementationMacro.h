//
//  LXDynamicProperty+ImplementationMacro.h
//  LXDynamicProperty
//
//  Created by 从今以后 on 16/1/15.
//  Copyright © 2016年 从今以后. All rights reserved.
//

#ifndef LXDynamicProperty_ImplementationMacro_h
#define LXDynamicProperty_ImplementationMacro_h

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

#define LXStructTypeDynamicIMP(type) \
static void __lx_##type##_dynamicSetterIMP(id self, SEL _cmd, typeof(type) newValue) \
{ \
    SEL getterSel = __LXGetGetterSelForSetterSel(self, _cmd); \
    NSValue *value = [NSValue value:&newValue withObjCType:@encode(typeof(type))]; \
    objc_setAssociatedObject(self, getterSel, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
} \
\
static typeof(type) __lx_##type##_dynamicGetterIMP(id self, SEL _cmd) \
{ \
    typeof(type) value; \
    [objc_getAssociatedObject(self, _cmd) getValue:&value]; \
    return value; \
}

#endif
