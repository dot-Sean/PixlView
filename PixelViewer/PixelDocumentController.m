//
//  DocumentWindowController.m
//  PixelViewer
//
//  Created by Sveinbjorn Thordarson on 21/06/15.
//  Copyright (c) 2015 Sveinbjorn Thordarson. All rights reserved.
//

#import "PixelDocumentController.h"

@implementation PixelDocumentController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.doc = self.document;

//    [self loadResolutionsArray];

    int width = [[widthTextField stringValue] intValue];
    int height = [[heightTextField stringValue] intValue];
    CGFloat scale = 1.0f;

    // Create GL view and add to scroll view
    NSOpenGLPixelFormatAttribute pixelFormatAttributes[] = {
        0
    };
    NSRect glFrame = NSMakeRect(0, 0, width, height);
    glView = [[GLPixelView alloc] initWithFrame:glFrame
                                    pixelFormat:[[NSOpenGLPixelFormat alloc] initWithAttributes:pixelFormatAttributes]
                                          scale:scale];
    glView.autoresizingMask = NSViewNotSizable;
    [pixelScrollView setDocumentView:glView];

    // Populate pixel format popup
    [formatPopupButton removeAllItems];
    for (NSString *format in [PixelBuffer supportedFormats]) {
        [formatPopupButton addItemWithTitle:format];
    }

//    [self populatePresetPopupMenu];

    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:self.doc.filePath];
    [fileIconImageView setImage:icon];
    [filePathTextField setStringValue:self.doc.filePath];
//    [fileMD5TextField setStringValue:[self md5hashForFileAtPath:self.doc.filePath]];

    self.doc.pixelBuffer.pixelFormat = [formatPopupButton indexOfSelectedItem];
    glView.pixelData = [self.doc.pixelBuffer toRGBA];
    [glView setNeedsDisplay:YES];
    
    [offsetSlider setMaxValue:[self.doc.pixelBuffer length]];
    //    [self populatePresetPopupMenu];
    [self updateBufferInfo];
    
    
    
}

- (IBAction)pixelFormatChanged:(id)sender {
    self.doc.pixelBuffer.pixelFormat = [formatPopupButton indexOfSelectedItem];
    glView.pixelData = [self.doc.pixelBuffer toRGBA];
    [glView setNeedsDisplay:YES];
    [self updateBufferInfo];
}

//- (IBAction)presetSelected:(id)sender {
//    int index = (int)[presetPopupButton indexOfSelectedItem];
//
//    NSDictionary *res = [resolutions objectAtIndex:index];
//    int w = [[res objectForKey:@"width"] intValue];
//    int h = [[res objectForKey:@"height"] intValue];
//    PixelFormat pixFmt = [self pixelFormatMatchingResolution:res];
//
//    [widthTextField setStringValue:[NSString stringWithFormat:@"%d", w]];
//    [heightTextField setStringValue:[NSString stringWithFormat:@"%d", h]];
//
//    if (pixFmt != -1) {
//        [formatPopupButton selectItemAtIndex:pixFmt];
//        [self pixelFormatChanged:nil];
//    }
//
//
//    [self controlTextDidChange:nil];
//}

- (void)controlTextDidChange:(NSNotification *)notification {

    if ([notification object] == scaleTextField) {
        return;
    }

    int width = [[widthTextField stringValue] intValue];
    int height = [[heightTextField stringValue] intValue];
    int offset = [[offsetTextField stringValue] intValue];

    [widthSlider setIntValue:width];
    [heightSlider setIntValue:height];
    [offsetSlider setIntValue:offset];

    if ([notification object] == offsetTextField) {
        PixelDocument *doc = self.document;
        doc.pixelBuffer.offset = offset;
        glView.pixelData = [doc.pixelBuffer toRGBA];
    }

    glView.frame = NSMakeRect(0, 0, width, height);
    [glView setNeedsDisplay:YES];
    [self updateBufferInfo];
}

- (IBAction)scaleSliderValueChanged:(id)sender {
    int perc = ([scaleSlider intValue] * 5);
    glView.scale = (float)perc / 100;
    [scaleTextField setStringValue:[NSString stringWithFormat:@"%d%%", perc]];


    int width = [[widthTextField stringValue] intValue];
    int height = [[heightTextField stringValue] intValue];
    glView.frame = NSMakeRect(0, 0, width, height);
    [glView setNeedsDisplay:YES];
}

- (IBAction)widthSliderValueChanged:(id)sender {
    [widthTextField setStringValue:[NSString stringWithFormat:@"%d", [sender intValue]]];
    [self controlTextDidChange:nil];
}

- (IBAction)heightSliderValueChanged:(id)sender {
    [heightTextField setStringValue:[NSString stringWithFormat:@"%d", [sender intValue]]];
    [self controlTextDidChange:nil];
}

- (IBAction)offsetSliderValueChanged:(id)sender {
    [offsetTextField setStringValue:[NSString stringWithFormat:@"%d", [sender intValue]]];
    PixelDocument *doc = self.document;
    doc.pixelBuffer.offset = [sender intValue];
    glView.pixelData = [doc.pixelBuffer toRGBA];
    [glView setNeedsDisplay:YES];
    [self updateBufferInfo];

}

- (void)updateBufferInfo {
    int width = [[widthTextField stringValue] intValue];
    int height = [[heightTextField stringValue] intValue];

    PixelDocument *doc = self.document;
    int fileDataLength = [doc.pixelBuffer length];
    int bufferSize = [doc.pixelBuffer expectedBitLengthForImageSize:NSMakeSize(width, height)] / 8;

    NSString *bufferInfoString = [NSString stringWithFormat:
                                  @"Data in: %d    Buffer out: %d   Diff: %@%d   ",
                                  fileDataLength,
                                  bufferSize,
                                  fileDataLength-bufferSize > 0 ? @"+" : @"",
                                  fileDataLength-bufferSize
                                  ];

    NSString *msg = fileDataLength-bufferSize > 0 ? @"Source too large" : @"Source too small";
    NSColor *color = fileDataLength-bufferSize > 0 ? [NSColor greenColor] : [NSColor orangeColor];
    if (fileDataLength-bufferSize == 0) {
        msg = @"Source matches";
        color = [NSColor greenColor];
    }

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:msg];
    [string addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0,string.length)];


    NSMutableAttributedString *finalStr = [[NSMutableAttributedString alloc] initWithString:bufferInfoString attributes:nil];
    [finalStr appendAttributedString:string];


    [bufferInfoTextField setAttributedStringValue:finalStr];
}

- (IBAction)decreaseScale:(id)sender {
    [scaleSlider setIntValue:[scaleSlider intValue]-1 < 1 ? 1 : [scaleSlider intValue]-1];
    [self scaleSliderValueChanged:nil];
}

- (IBAction)increaseScale:(id)sender {
    [scaleSlider setIntValue:[scaleSlider intValue]+1];
    [self scaleSliderValueChanged:nil];
}

- (IBAction)decreaseWidth:(id)sender {
    int newWidth = [[widthTextField stringValue] intValue]-1 < 0 ? 0 : [[widthTextField stringValue] intValue]-1;
    [widthTextField setStringValue:[NSString stringWithFormat:@"%d", newWidth]];
    [self controlTextDidChange:nil];
}

- (IBAction)increaseWidth:(id)sender {
    [widthTextField setStringValue:[NSString stringWithFormat:@"%d", [[widthTextField stringValue] intValue]+1]];
    [self controlTextDidChange:nil];
}

- (IBAction)decreaseHeight:(id)sender {
    int newHeight = [[heightTextField stringValue] intValue]-1 < 0 ? 0 : [[heightTextField stringValue] intValue]-1;
    [heightTextField setStringValue:[NSString stringWithFormat:@"%d", newHeight]];
    [self controlTextDidChange:nil];
}

- (IBAction)increaseHeight:(id)sender {
    [heightTextField setStringValue:[NSString stringWithFormat:@"%d", [[heightTextField stringValue] intValue]+1]];
    [self controlTextDidChange:nil];

}


#pragma mark - File
//
//- (void)openFile:(NSString *)filePath {
//
//
//    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:filePath]];
//}


//- (NSString *)md5hashForFileAtPath:(NSString *)path
//{
//    BOOL isDir;
//
//    //make sure it exists and isn't folder
//    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory: &isDir] || isDir) {
//        return nil;
//    }
//
//    NSPipe *pipe = [NSPipe pipe];
//    NSTask *task = [[NSTask alloc] init];
//    [task setLaunchPath:@"/sbin/md5"];
//    [task setArguments:[NSArray arrayWithObject:path]];
//    [task setStandardOutput:pipe];
//    [task launch];
//
//    //read the output from the command
//    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
//
//    NSString *outputStr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
//    return [[outputStr componentsSeparatedByString:@" = "] objectAtIndex:1];
//}

#pragma mark - Resolution presets

//- (void)populatePresetPopupMenu {
//
//    [presetPopupButton removeAllItems];
//
//    NSArray *matches = [self matchingResolutionPresets];
//
//    for (NSDictionary *res in resolutions) {
//        int w = [[res objectForKey:@"width"] intValue];
//        int h = [[res objectForKey:@"height"] intValue];
//
//        NSString *presetName = [NSString stringWithFormat:@"%d x %d", w, h];
//        [presetPopupButton addItemWithTitle:presetName];
//    }
//
//
//
//    NSArray *menuItems = [presetPopupButton itemArray];
//    for (NSMenuItem *menuItem in menuItems) {
//
//        int index = (int)[presetPopupButton indexOfItem:menuItem];
//        NSDictionary *resInfoDict = [resolutions objectAtIndex:index];
//
//        NSColor *resColor = [NSColor clearColor];
//        NSString *title = menuItem.title;
//
//        // Check if match
//        PixelFormat pixFmt = [self pixelFormatMatchingResolution:resInfoDict];
//        if (pixFmt != -1) {
//            resColor = [NSColor greenColor];
//            NSString *pixFmtStr = [[PixelBuffer supportedFormats] objectAtIndex:pixFmt];
//            title = [NSString stringWithFormat:@"%@ (%@)", menuItem.title, pixFmtStr];
//        }
//        NSDictionary *textAttr = [NSDictionary dictionaryWithObjectsAndKeys:
//                                  resColor, NSBackgroundColorAttributeName,
//                                  [NSFont systemFontOfSize: [NSFont systemFontSize]], NSFontAttributeName, nil];
//
//
//        NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:title attributes:textAttr];
//
//        [menuItem setAttributedTitle:attrTitle];
//    }
//}
//
//- (PixelFormat)pixelFormatMatchingResolution:(NSDictionary *)resInfoDict {
//    int pixelCount = [[resInfoDict objectForKey:@"pixels"] intValue];
//
//    if (pixelCount * 4 == pixelBuffer.length) {
//        return PIXEL_FORMAT_RGBA;
//    } else if (pixelCount * 3 == pixelBuffer.length) {
//        return PIXEL_FORMAT_RGB24;
//    } else if (pixelCount * 1 == pixelBuffer.length) {
//        return PIXEL_FORMAT_RGB8;
//    }
//    return -1;
//}
//
//- (NSArray *)matchingResolutionPresets {
//    NSMutableArray *matches = [NSMutableArray array];
//    if (pixelBuffer.data == nil || [pixelBuffer.data length] == 0) {
//        return matches;
//    }
//
//    for (NSDictionary *res in resolutions) {
////        int w = [[res objectForKey:@"width"] intValue];
////        int h = [[res objectForKey:@"height"] intValue];
//        int pixCount = [[res objectForKey:@"pixels"] intValue];
//
//        BOOL match = NO;
//        if (pixCount * 4 == [pixelBuffer.data length]) {
//            match = YES;
//        } else if (pixCount * 3 == [pixelBuffer.data length]) {
//            match = YES;
//        } else if (pixCount * 1 == [pixelBuffer.data length]) {
//            match = YES;
//        }
//        if (match) {
//            [matches addObject:res];
//        }
//    }
//    return matches;
//}
//
////- (BOOL)guessResolution:(NSSize *)outSize pixelFormat:(PixelFormat *)format {
////    NSString *resFilePath = [[NSBundle mainBundle] pathForResource:@"resolutions" ofType:@"plist"];
////    NSArray *resolutions = [NSArray arrayWithContentsOfFile:resFilePath];
////
////    for (NSDictionary *res in resolutions) {
////        int w = [[res objectForKey:@"width"] intValue];
////        int h = [[res objectForKey:@"height"] intValue];
////        int pixCount = [[res objectForKey:@"pixels"] intValue];
////
////                if (pixCount * 4 == self.data.length) {
////                    *format = PIXEL_FORMAT_RGBA;
////                } else if (pixCount * 3 == self.data.length) {
////                    *format = PIXEL_FORMAT_RGB24;
////                } else if (pixCount * 1 == self.data.length) {
////                    *format = PIXEL_FORMAT_RGB8;
////                } else {
////                    continue;
////                }
////
////        //        NSString *fmtName = [[PixelBuffer supportedFormats] objectAtIndex:*format];
////        //        NSLog(@"Data length %d matches %d x %d format: %@", self.data.length, w, h, fmtName);
////
////    }
////
////    return TRUE;
////}
//
//- (void)loadResolutionsArray {
//    NSString *resFilePath = [[NSBundle mainBundle] pathForResource:@"resolutions" ofType:@"plist"];
//    resolutions = [NSArray arrayWithContentsOfFile:resFilePath];
//}


@end
