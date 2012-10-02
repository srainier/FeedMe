//
// ViewController.m
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

#import "ViewController.h"
#import "FMParser.h"

@interface ViewController ()

@end

@implementation ViewController

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  
  FMParser* parser = [[FMParser alloc] init];
  NSString* rssPath = [[NSBundle mainBundle] pathForResource:@"5by5" ofType:@"xml"];
  [parser parseRssAtPath:rssPath error:nil];
  
  NSLog(@"Channel: %@, %@, %@",
        parser.channel[@"title"][@"value"],
        parser.channel[@"link"][@"value"],
        parser.channel[@"description"][@"value"]);
  for (NSDictionary* item in parser.channel[@"item"]) {
    NSLog(@"Item: %@, %@, %@, Enclosure %@, %@, %@",
          item[@"title"][@"value"],
          item[@"link"][@"value"],
          item[@"descriptions"][@"value"],
          item[@"enclosure"][@"url"],
          item[@"enclosure"][@"length"],
          item[@"enclosure"][@"type"]);
  }
}

@end
