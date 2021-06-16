//
//
//  Created by matheuslperez
//
#ifdef __cplusplus
#undef NO
#import <opencv2/opencv.hpp>
#endif
#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface CropAndScanFactory : NSObject


+ (void) pathString: (NSString *) pathString tl_x:(double) tl_x tl_y:(double) tl_y tr_x:(double) tr_x tr_y:(double) tr_y bl_x:(double) bl_x bl_y:(double) bl_y br_x:(double) br_x br_y:(double) br_y result: (FlutterResult) result;


@end

NS_ASSUME_NONNULL_END
