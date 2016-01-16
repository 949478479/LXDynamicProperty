//
//  NSObject+LXDynamicProperty.h
//  LXDynamicProperty
//
//  Created by 从今以后 on 16/1/12.
//  Copyright © 2016年 从今以后. All rights reserved.
//

@protocol LXDynamicProperty
@end

const char * _Nonnull LXGetDynamicPropertyPrefix();
void LXSetDynamicPropertyPrefix(const char * _Nonnull prefix);