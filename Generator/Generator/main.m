//
//  main.m
//  Generator
//
//  Created by Jean-Pierre Mouilleseaux on 20 Dec 13.
//  Copyright (c) 2013-2014 Chorded Constructions. All rights reserved.
//

@import Foundation;
@import ApplicationServices;
@import CoreText;
@import AppKit.NSFont;
@import AppKit.NSAttributedString;

#import "NSString+Emojize.h"

const size_t kImageWidth = 256;
const size_t kImageHeight = 256;

void draw(NSString* string, NSURL* destination) {
    // create context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, kImageWidth, kImageHeight, 8, kImageWidth * 4, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);

    // draw into context
    static NSDictionary* attributes = nil;
    static CGFloat size = 144.0;
    if (!attributes) {
        NSFont* font = [NSFont systemFontOfSize:size];
        attributes = @{NSFontAttributeName: font};
    }
    NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:string attributes:attributes];

    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attributedString);
//    CGFloat ascent, descent, leading, width;
//    width = CTLineGetTypographicBounds(line, &ascent,  &descent, &leading);
//    CGContextSetTextPosition(bitmapContext, (kImageWidth - size) / 2.0f, (kImageHeight - size + descent) / 2.0f);
    CGContextSetTextPosition(bitmapContext, (kImageWidth - size) / 2.0f, (kImageHeight - size) / 2.0f);
    CTLineDraw(line, bitmapContext);

    // pull an image out
    CGImageRef image = CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease(bitmapContext);

    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((__bridge CFURLRef)destination, kUTTypePNG, 1, NULL);

    // write it to disk
    CGImageDestinationAddImage(imageDestination, image, 0);
    CGImageDestinationFinalize(imageDestination);
    CFRelease(imageDestination);

    CGImageRelease(image);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSURL* destinationFolderURL = [[NSURL alloc] initFileURLWithPath:[@"~/Desktop/emoji-imgs" stringByExpandingTildeInPath]];
        if (![destinationFolderURL checkResourceIsReachableAndReturnError:nil]) {
            NSError* error;
            BOOL status = [[NSFileManager defaultManager] createDirectoryAtURL:destinationFolderURL withIntermediateDirectories:YES attributes:nil error:&error];
            if (!status) {
                NSLog(@"ERROR - failed to create destination folder '%@' - %@", [destinationFolderURL absoluteString], [error localizedDescription]);
                exit(1);
            }
        }

        [[NSString reverseEmojiAliases] enumerateKeysAndObjectsUsingBlock:^(NSString* emoji, NSString* code, BOOL* stop) {
            // trim leading and trailing code markers
            code = [code substringWithRange:NSMakeRange(1, [code length] - 2)];
            NSURL* url = [destinationFolderURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", code]];
            NSLog(@"creating image for %@", emoji);
            draw(emoji, url);
        }];
        NSLog(@"\n😎👍");
    }

    return 0;
}
