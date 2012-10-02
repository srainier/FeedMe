//
// FMParser.h
//
// Copyright (c) 2012 Shane Arney (srainier@gmail.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

@interface FMParser : NSObject {
 @private
  // The main data returned - the root channel and all of its items
  NSMutableDictionary* channel_;
  NSMutableArray* items_;
  // State data used while parsing
  NSMutableArray* stateStack_; // stack of keys (for xml path)
  NSMutableArray* dataStack_; // stack of dictionaries for each key in the state stack
  // storage for (partial) text found in element content.
  NSMutableArray* text_;
  // Currently unused flag that can allow parsing to stop before the end of the document.
  BOOL stopped_;
}

@property (nonatomic, strong, readonly) NSDictionary* channel;
@property (nonatomic, strong, readonly) NSArray* items;

- (BOOL) parseRssAtPath:(NSString*)rssFilePath error:(NSError**)error;
- (BOOL) parseRssWithData:(NSData*)rssData error:(NSError**)error;

@end
