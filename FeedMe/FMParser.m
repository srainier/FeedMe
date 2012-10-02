//
// FMParser.m
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

#import "FMParser.h"

@interface FMParser ()

- (NSDate*) rssDateForString:(NSString*)dateString;

@end


@interface FMParser (XmlParse) <NSXMLParserDelegate>
@end

@implementation FMParser

@synthesize channel = channel_;
@synthesize items = items_;

- (id) init {
  self = [super init];
  if (nil != self) {
  }
  return self;
}

- (BOOL) runXmlParser:(NSXMLParser*)parser error:(NSError**)error {
  
  // reset state data containers
  // data stack starts with an empty dictionary, rss should be only key in the root when done
  stateStack_ = [NSMutableArray array];
  dataStack_ = [NSMutableArray arrayWithObject:[NSMutableDictionary dictionary]];
  
  // clear channel and items
  channel_ = nil;
  items_ = [NSMutableArray array];
  
  // Setup the parser
  [parser setDelegate:self];
  [parser setShouldProcessNamespaces:YES];
  [parser setShouldReportNamespacePrefixes:NO];
  [parser setShouldResolveExternalEntities:NO];
  
  // Parse
  stopped_ = NO;
  BOOL success = [parser parse];
  if (!success && !stopped_) {
    NSError* error = [parser parserError];
    NSLog(@"%@", [error localizedDescription]);
    return NO;
  } 
  
  // Clear the error - successful parse
  if (nil != error) {
    *error = nil;
  }
  return YES;
}

- (BOOL) parseRssAtPath:(NSString*)rssFilePath error:(NSError**)error {
  NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL fileURLWithPath:rssFilePath]];
  return [self runXmlParser:parser error:error];
}

- (BOOL) parseRssWithData:(NSData*)rssData error:(NSError *__autoreleasing *)error {
  NSXMLParser* parser = [[NSXMLParser alloc] initWithData:rssData];
  return [self runXmlParser:parser error:error];
}

// Convert an RFC 822-compliant (in theory) date string to NSDate
- (NSDate*) rssDateForString:(NSString*)dateString {

  // with day, with seconds
  NSString* format1 = @"E, d M y H:m:s z";
  
  // with day, no seconds
  NSString* format2 = @"E, d M y H:m z";
  
  // no day, with seconds
  NSString* format3 = @"d M y H:m:s z";
  
  // no day, no seconds
  NSString* format4 = @"d M y H:m z";
  
  __block NSDate* parsedDate = nil;
  NSArray* formatStrings = [NSArray arrayWithObjects:format1, format2, format3, format4, nil];
  [formatStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL* stop) {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setDateFormat:obj];
    parsedDate = [dateFormatter dateFromString:dateString];
    if (nil != parsedDate) {
      *stop = YES;
    }
  }];
  
  return parsedDate;
}

@end


@implementation FMParser (XmlParse)

// sent when the parser finds an element start tag.
// In the case of the cvslog tag, the following is what the delegate receives:
//   elementName == cvslog, namespaceURI == http://xml.apple.com/cvslog, qualifiedName == cvslog
// In the case of the radar tag, the following is what's passed in:
//    elementName == radar, namespaceURI == http://xml.apple.com/radar, qualifiedName == radar:radar
// If namespace processing >isn't< on, the xmlns:radar="http://xml.apple.com/radar" is returned as an attribute pair, the elementName is 'radar:radar' and there is no qualifiedName.
- (void)parser:(NSXMLParser *)parser 
didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict {
  
  //NSLog(@"Start element: %@, namespace: %@, qname: %@", elementName, namespaceURI, qName);

  // get the current data context (before adding new data context)
  NSMutableDictionary* currentData = [dataStack_ lastObject];
  
  // push a new data context (dictionary) onto the data stack, including element attributes (if any)
  [dataStack_ addObject:(nil == attributeDict) ? [NSMutableDictionary dictionary] : [NSMutableDictionary dictionaryWithDictionary:attributeDict]];

  // map the new data context to the qualified element name in the current data context
  id existingObject = [currentData objectForKey:qName];
  if (nil == existingObject) {
    [currentData setObject:[dataStack_ lastObject] forKey:qName];
  } else {
    // If an object already exists for the key, create an array
    NSMutableArray* arrayOfObjects = nil;
    if ([existingObject isKindOfClass:[NSArray class]]) {
      [existingObject addObject:[dataStack_ lastObject]];
      arrayOfObjects = existingObject;
    } else {
      arrayOfObjects = [NSMutableArray arrayWithObjects:existingObject, [dataStack_ lastObject], nil];
    }
    
    [currentData setObject:arrayOfObjects forKey:qName];
  }
  
  // push the qualified element name onto the state stack
  [stateStack_ addObject:qName];

  // Clear the text array for any text 
  text_ = [NSMutableArray array];
}

// sent when an end tag is encountered. The various parameters are supplied as above.
- (void)parser:(NSXMLParser *)parser 
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
  
  //NSLog(@"End element: %@, namespace: %@, qname: %@", elementName, namespaceURI, qName);

  // The key for the most recent element should be the same as qualified name of the element ending here
  id currentStateKey = [stateStack_ lastObject];
  if (![qName isEqual:currentStateKey]) {
    @throw @"shouldn't happen - corrupted xml parse stack";
  }
  
  // pop the most recent state
  [stateStack_ removeLastObject];
  
  // similarly, get the data object (dictionary) for this element, then pop it from the stack
  NSMutableDictionary* currentStateObject = [dataStack_ lastObject];
  [dataStack_ removeLastObject];

  // if we got any text data, store it here
  if (nil != text_ && 0 < text_.count) {
    [currentStateObject setObject:[text_ componentsJoinedByString:@""] forKey:@"value"];
  }
  
  if ([@"channel" isEqualToString:qName]) {
    channel_ = currentStateObject;
  }

  text_ = nil;
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
  // ...and this reports a fatal error to the delegate. The parser will stop parsing.
  NSLog(@"parse error");
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
  // This returns the string of the characters encountered thus far. 
  // You may not necessarily get the longest character run. The parser 
  // reserves the right to hand these to the delegate as potentially many 
  // calls in a row to -parser:foundCharacters:
  [text_ addObject:string];
}

- (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString {
  // The parser reports ignorable whitespace in the same way as characters it's found.
  // NOTE: not sure if this 'ignorable whitespace' should be preserved.  Should
  // probably be a parser setting.
  [text_ addObject:whitespaceString]; 
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
  NSString* cdataString = [[NSString alloc] initWithData:CDATABlock
                                                encoding:NSUTF8StringEncoding]; // encoding should be doc-specific
  [text_ addObject:cdataString];
}

@end

