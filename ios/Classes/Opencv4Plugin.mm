#import "Opencv4Plugin.h"
#import "ApplyColorMapFactory.h"
#import "CvtColorFactory.h"
#import "BilateralFilterFactory.h"
#import "BlurFactory.h"
#import "BoxFilterFactory.h"
#import "DilateFactory.h"
#import "ErodeFactory.h"
#import "Filter2DFactory.h"
#import "GaussianBlurFactory.h"
#import "LaplacianFactory.h"
#import "MedianBlurFactory.h"
#import "MorphologyExFactory.h"
#import "PyrMeanShiftFilteringFactory.h"
#import "ScharrFactory.h"
#import "SobelFactory.h"
#import "SqrBoxFilterFactory.h"
#import "AdaptiveThresholdFactory.h"
#import "DistanceTransformFactory.h"
#import "ThresholdFactory.h"

@implementation Opencv4Plugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"opencv_4"
            binaryMessenger:[registrar messenger]];
  Opencv4Plugin* instance = [[Opencv4Plugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {



  
  // Note: this method is invoked on the UI thread.
    if ([@"getVersion" isEqualToString:call.method]) {
        result([NSString stringWithFormat:@"%s", cv::getVersionString().c_str()]);
    }
    if ([@"cropAndScan" isEqualToString:call.method]) {
        NSString* pathString = call.arguments[@"pathString"];
        
        double tl_x = [call.arguments[@"tl_x"] doubleValue];
        double tl_y = [call.arguments[@"tl_y"] doubleValue];
        double tr_x = [call.arguments[@"tr_x"] doubleValue];
        double tr_y = [call.arguments[@"tr_y"] doubleValue];
        double bl_x = [call.arguments[@"bl_x"] doubleValue];
        double bl_y = [call.arguments[@"bl_y"] doubleValue];
        double br_x = [call.arguments[@"br_x"] doubleValue];
        double br_y = [call.arguments[@"br_y"] doubleValue];
        
        int bytesInFile;
        const char * command;

        command = [pathString cStringUsingEncoding:NSUTF8StringEncoding];
        
        FILE* file = fopen(command, "rb");
        fseek(file, 0, SEEK_END);
        bytesInFile = (int) ftell(file);
        fseek(file, 0, SEEK_SET);
        std::vector<uint8_t> file_data(bytesInFile);
        fread(file_data.data(), 1, bytesInFile, file);
        fclose(file);
        
        NSData *imgOriginal = [NSData dataWithBytes: file_data.data()
                                    length: bytesInFile];
        
        UIImage *img = [[UIImage alloc] initWithData:imgOriginal];
        
        CGColorSpaceRef colorSpace = CGImageGetColorSpace(img.CGImage);
         CGFloat cols = img.size.width;
         CGFloat rows = img.size.height;
         cv::Mat src(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
         CGContextRef contextRef = CGBitmapContextCreate(src.data,                 // Pointer to  data
                                                        cols,                       // Width of bitmap
                                                        rows,                       // Height of bitmap
                                                        8,                          // Bits per component
                                                         src.step[0],              // Bytes per row
                                                        colorSpace,                 // Colorspace
                                                        kCGImageAlphaNoneSkipLast |
                                                        kCGBitmapByteOrderDefault); // Bitmap info flags
         CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), img.CGImage);
         CGContextRelease(contextRef);
        
        cv::cvtColor(src, src, cv::COLOR_BGR2GRAY);
        cv::GaussianBlur(src, src, cv::Size(5.0, 5.0), 0.0);
        
        CGFloat w1 = sqrt( pow(br_x - bl_x , 2) + pow(br_x - bl_x, 2));
        CGFloat w2 = sqrt( pow(tr_x - tl_x , 2) + pow(tr_x - tl_x, 2));

        CGFloat h1 = sqrt( pow(tr_y - br_y , 2) + pow(tr_y - bl_y, 2));
        CGFloat h2 = sqrt( pow(tl_y - bl_y , 2) + pow(tl_y - bl_y, 2));

        CGFloat maxWidth = (w1 < w2) ? w1 : w2;
        CGFloat maxHeight = (h1 < h2) ? h1 : h2;
                
        cv::Point2f src_mat[4], dst_mat[4];
        src_mat[0].x = tl_x;
        src_mat[0].y = tl_y;
        src_mat[1].x = tr_x;
        src_mat[1].y = tr_y;
        src_mat[2].x = br_x;
        src_mat[2].y = br_y;
        src_mat[3].x = bl_x;
        src_mat[3].y = bl_y;

        dst_mat[0].x = 0;
        dst_mat[0].y = 0;
        dst_mat[1].x = maxWidth - 1;
        dst_mat[1].y = 0;
        dst_mat[2].x = maxWidth - 1;
        dst_mat[2].y = maxHeight - 1;
        dst_mat[3].x = 0;
        dst_mat[3].y = maxHeight - 1;
        
        cv::Mat perspectiveTransform =  cv::getPerspectiveTransform(src_mat, dst_mat);
        
        cv::warpPerspective(src, src, perspectiveTransform, cv::Size(maxWidth,maxHeight));
        
        cv::adaptiveThreshold(src, src, 255.0, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 401, 14.0);

        cv::Mat blurred = cv::Mat();
        cv::GaussianBlur(src, blurred, cv::Size(5.0, 5.0), 0.0);
        
        cv::Mat result1 = cv::Mat();
        
        cv::addWeighted(blurred, 0.5, src,0.5, 1.0, result1);
            
        NSData *data = [NSData dataWithBytes:result1.data length:result1.elemSize()*result1.total()];
        
        CGColorSpaceRef finalColorSpace;
        
         if (result1.elemSize() == 1) {
             finalColorSpace = CGColorSpaceCreateDeviceGray();
         } else {
             finalColorSpace = CGColorSpaceCreateDeviceRGB();
         }
         CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
         // Creating CGImage from cv::Mat
         CGImageRef imageRef = CGImageCreate(result1.cols,                                 //width
                                             result1.rows,                                 //height
                                            8,                                          //bits per component
                                            8 * result1.elemSize(),                       //bits per pixel
                                             result1.step[0],                            //bytesPerRow
                                             finalColorSpace,                                 //colorspace
                                            kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                            provider,                                   //CGDataProviderRef
                                            NULL,                                       //decode
                                            false,                                      //should interpolate
                                            kCGRenderingIntentDefault                   //intent
                                            );
         // Getting UIImage from CGImage
         UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
         CGImageRelease(imageRef);
         CGDataProviderRelease(provider);
         CGColorSpaceRelease(finalColorSpace);
        
        NSData* imgConvert = UIImageJPEGRepresentation(finalImage, 1);
        
        result([FlutterStandardTypedData typedDataWithBytes: imgConvert]);
        
//        [CropAndScanFactory pathString:pathString tl_x:tl_x tl_y:tl_y tr_x:tr_x tr_y:tr_y bl_x:bl_x bl_y:bl_y br_x:br_x br_y:br_y result:result];


    }
    //Module: Image Filtering
    else if ([@"bilateralFilter" isEqualToString:call.method]) {

        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        int diameter = [call.arguments[@"diameter"] intValue];
        double sigmaColor = [call.arguments[@"sigmaColor"] doubleValue];
        double sigmaSpace = [call.arguments[@"sigmaSpace"] doubleValue];
        int borderType = [call.arguments[@"borderType"] intValue];

        [BilateralFilterFactory processWhitPathType:pathType pathString:pathString data:data diameter:diameter sigmaColor:sigmaColor sigmaSpace:sigmaSpace borderType:borderType result:result];

    }
    else if ([@"blur" isEqualToString:call.method]) {

        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        NSArray* kernelSize = call.arguments[@"kernelSize"];
        NSArray* anchorPoint = call.arguments[@"anchorPoint"];
        int borderType = [call.arguments[@"borderType"] intValue];
        double p1 = [[anchorPoint objectAtIndex:0] doubleValue];
        double p2 = [[anchorPoint objectAtIndex:1] doubleValue];
        double x = [[kernelSize objectAtIndex:0] doubleValue];
        double y = [[kernelSize objectAtIndex:1] doubleValue];
        double kernelSizeDouble[2] = {x,y};
        double anchorPointDouble[2] = {p1,p2};

        [BlurFactory processWhitPathType:pathType pathString:pathString data:data kernelSize:kernelSizeDouble anchorPoint:anchorPointDouble borderType:borderType result:result];
    }
    else if ([@"boxFilter" isEqualToString:call.method]) {

        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        int outputDepth = [call.arguments[@"outputDepth"] intValue];
        NSArray* kernelSize = call.arguments[@"kernelSize"];
        NSArray* anchorPoint = call.arguments[@"anchorPoint"];
        bool normalize = [call.arguments[@"normalize"] boolValue];
        int borderType = [call.arguments[@"borderType"] intValue];
        double p1 = [[anchorPoint objectAtIndex:0] doubleValue];
        double p2 = [[anchorPoint objectAtIndex:1] doubleValue];
        double x = [[kernelSize objectAtIndex:0] doubleValue];
        double y = [[kernelSize objectAtIndex:1] doubleValue];
        double kernelSizeDouble[2] = {x,y};
        double anchorPointDouble[2] = {p1,p2};

        [BoxFilterFactory processWhitPathType:pathType pathString:pathString data:data outputDepth:outputDepth kernelSize:kernelSizeDouble anchorPoint:anchorPointDouble normalize:normalize borderType:borderType result:result];
    }
    else if ([@"dilate" isEqualToString:call.method]) {

        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        NSArray* kernelSize = call.arguments[@"kernelSize"];
        double x = [[kernelSize objectAtIndex:0] doubleValue];
        double y = [[kernelSize objectAtIndex:1] doubleValue];
        double kernelSizeDouble[2] = {x,y};


        [DilateFactory processWhitPathType:pathType pathString:pathString data:data kernelSize:kernelSizeDouble result:result];
    }
    else if ([@"erode" isEqualToString:call.method]) {

        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        NSArray* kernelSize = call.arguments[@"kernelSize"];
        double x = [[kernelSize objectAtIndex:0] doubleValue];
        double y = [[kernelSize objectAtIndex:1] doubleValue];
        double kernelSizeDouble[2] = {x,y};


        [ErodeFactory processWhitPathType:pathType pathString:pathString data:data kernelSize:kernelSizeDouble result:result];
    }
    else if ([@"filter2D" isEqualToString:call.method]) {

        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        int outputDepth = [call.arguments[@"outputDepth"] intValue];
        NSArray* kernelSize = call.arguments[@"kernelSize"];
        int x = [[kernelSize objectAtIndex:0] intValue];
        int y = [[kernelSize objectAtIndex:1] intValue];
        int kernelSizeInt[2] = {x,y};

        [Filter2DFactory processWhitPathType:pathType pathString:pathString data:data outputDepth:outputDepth kernelSize:kernelSizeInt result:result];
    }
    else if ([@"gaussianBlur" isEqualToString:call.method]) {

        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        NSArray* kernelSize = call.arguments[@"kernelSize"];
        double sigmaX = [call.arguments[@"sigmaX"] doubleValue];
        double x = [[kernelSize objectAtIndex:0] doubleValue];
        double y = [[kernelSize objectAtIndex:1] doubleValue];
        double kernelSizeDouble[2] = {x,y};

        [GaussianBlurFactory processWhitPathType:pathType pathString:pathString data:data kernelSize:kernelSizeDouble sigmaX:sigmaX result:result];
    }
    else if ([@"laplacian" isEqualToString:call.method]) {
    
        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        int depth = [call.arguments[@"depth"] intValue];

        [LaplacianFactory processWhitPathType:pathType pathString:pathString data:data depth:depth result:result];

    }
    else if ([@"medianBlur" isEqualToString:call.method]) {
    
        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        int kernelSize = [call.arguments[@"kernelSize"] intValue];

        [MedianBlurFactory processWhitPathType:pathType pathString:pathString data:data kernelSize:kernelSize result:result];

    }
    else if ([@"morphologyEx" isEqualToString:call.method]) {

        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        int operation = [call.arguments[@"operation"] intValue];
        NSArray* kernelSize = call.arguments[@"kernelSize"];
        int x = [[kernelSize objectAtIndex:0] intValue];
        int y = [[kernelSize objectAtIndex:1] intValue];
        int kernelSizeInt[2] = {x,y};

        [MorphologyExFactory processWhitPathType:pathType pathString:pathString data:data operation:operation kernelSize:kernelSizeInt result:result];
    }
    else if ([@"pyrMeanShiftFiltering" isEqualToString:call.method]) {

        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        double spatialWindowRadius = [call.arguments[@"spatialWindowRadius"] doubleValue];
        double colorWindowRadius = [call.arguments[@"colorWindowRadius"] doubleValue];

        [PyrMeanShiftFilteringFactory processWhitPathType:pathType pathString:pathString data:data spatialWindowRadius:spatialWindowRadius colorWindowRadius:colorWindowRadius result:result];
    }
    else if ([@"scharr" isEqualToString:call.method]) {

        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        int depth = [call.arguments[@"depth"] intValue];
        int dx = [call.arguments[@"dx"] intValue];
        int dy = [call.arguments[@"dy"] intValue];

        [ScharrFactory processWhitPathType:pathType pathString:pathString data:data depth:depth dx:dx dy:dy result:result];
    }
    else if ([@"sobel" isEqualToString:call.method]) {

        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        int depth = [call.arguments[@"depth"] intValue];
        int dx = [call.arguments[@"dx"] intValue];
        int dy = [call.arguments[@"dy"] intValue];

        [SobelFactory processWhitPathType:pathType pathString:pathString data:data depth:depth dx:dx dy:dy result:result];
    }
    else if ([@"sqrBoxFilter" isEqualToString:call.method]) {

        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        int outputDepth = [call.arguments[@"outputDepth"] intValue];
        NSArray* kernelSize = call.arguments[@"kernelSize"];
        double x = [[kernelSize objectAtIndex:0] doubleValue];
        double y = [[kernelSize objectAtIndex:1] doubleValue];
        double kernelSizeDouble[2] = {x,y};

        [SqrBoxFilterFactory processWhitPathType:pathType pathString:pathString data:data outputDepth:outputDepth kernelSize:kernelSizeDouble result:result];
    }
    //Module: Miscellaneous Image Transformations
    else if ([@"adaptiveThreshold" isEqualToString:call.method]) {

        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        double maxValue = [call.arguments[@"maxValue"] doubleValue];
        int adaptiveMethod = [call.arguments[@"adaptiveMethod"] intValue];
        int thresholdType = [call.arguments[@"thresholdType"] intValue];
        int blockSize = [call.arguments[@"blockSize"] intValue];
        double constantValue = [call.arguments[@"constantValue"] doubleValue];

        [AdaptiveThresholdFactory processWhitPathType:pathType pathString:pathString data:data maxValue:maxValue adaptiveMethod:adaptiveMethod thresholdType:thresholdType blockSize:blockSize constantValue:constantValue result:result];
    }
    else if ([@"distanceTransform" isEqualToString:call.method]) {

        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        int distanceType = [call.arguments[@"distanceType"] intValue];
        int maskSize = [call.arguments[@"maskSize"] intValue];

        [DistanceTransformFactory processWhitPathType:pathType pathString:pathString data:data distanceType:distanceType maskSize:maskSize result:result];
    }
    else if ([@"threshold" isEqualToString:call.method]) {

        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        double thresholdValue = [call.arguments[@"thresholdValue"] doubleValue];
        double maxThresholdValue = [call.arguments[@"maxThresholdValue"] doubleValue];
        int thresholdType = [call.arguments[@"thresholdType"] intValue];


        [ThresholdFactory processWhitPathType:pathType pathString:pathString data:data thresholdValue:thresholdValue maxThresholdValue:maxThresholdValue thresholdType:thresholdType result:result];
    }
    else if ([@"applyColorMap" isEqualToString:call.method]) {

        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        int colorMap = [call.arguments[@"colorMap"] intValue];

        [ApplyColorMapFactory processWhitPathType:pathType pathString:pathString data:data colorMap:colorMap result:result];

    }
    else if ([@"cvtColor" isEqualToString:call.method]) {
    
        int pathType = [call.arguments[@"pathType"] intValue];
        NSString* pathString = call.arguments[@"pathString"];
        FlutterStandardTypedData* data = call.arguments[@"data"];
        int outputType = [call.arguments[@"outputType"] intValue];

        [CvtColorFactory processWhitPathType:pathType pathString:pathString data:data outputType:outputType result:result];

    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

@end
