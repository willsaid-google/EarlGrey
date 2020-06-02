//
// Copyright 2017 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "GREYFailureFormatter.h"

#import "GREYError+Private.h"
#import "GREYError.h"
#import "GREYObjectFormatter.h"
#import "XCTestCase+GREYTest.h"

@implementation GREYFailureFormatter

+ (NSString *)formatFailureForTestCase:(XCTestCase *)testCase
                           failureLabel:(NSString *)failureLabel
                            failureName:(NSString *)failureName
                               filePath:(NSString *)filePath
                             lineNumber:(NSUInteger)lineNumber
                           functionName:(NSString *)functionName
                             stackTrace:(NSArray *)stackTrace
                         appScreenshots:(NSDictionary *)appScreenshots
                              hierarchy:(NSString *)hierarchy
                       errorDescription:(NSString *)errorDescription {
  GREYError *error =
      I_GREYErrorMake(kGREYGenericErrorDomain, kGREYGenericErrorCode, nil, filePath, lineNumber,
                      functionName, stackTrace, hierarchy, appScreenshots);
  XCTestCase *currentTestCase = [XCTestCase grey_currentTestCase];
  error.testCaseClassName = [currentTestCase grey_testClassName];
  error.testCaseMethodName = [currentTestCase grey_testMethodName];

  NSArray *excluding = @[ kErrorFilePathKey, kErrorLineKey ];
  return [self formatFailureForError:error
                           excluding:excluding
                        failureLabel:failureLabel
                         failureName:failureName
                    errorDescription:errorDescription];
}

+ (NSString *)formatFailureForError:(GREYError *)error
                          excluding:(NSArray *)excluding
                       failureLabel:(NSString *)failureLabel
                        failureName:(NSString *)failureName
                   errorDescription:(NSString *)errorDescription {
  if (failureLabel.length == 0) {
    failureLabel = @"Failure";
  }

  NSMutableArray *logger = [[NSMutableArray alloc] init];
  [logger addObject:[NSString stringWithFormat:@"%@: %@\n", failureLabel, failureName]];

  if (![excluding containsObject:kErrorFilePathKey]) {
    [logger addObject:[NSString stringWithFormat:@"File: %@\n", error.filePath]];
  }
  if (![excluding containsObject:kErrorLineKey]) {
    [logger addObject:[NSString stringWithFormat:@"Line: %lu\n", (unsigned long)error.line]];
  }

  if (![excluding containsObject:kErrorFunctionNameKey]) {
    if (error.functionName) {
      [logger addObject:[NSString stringWithFormat:@"Function: %@\n", error.functionName]];
    }
  }

  if (![excluding containsObject:kErrorDescriptionKey]) {
    [logger addObject:errorDescription];
  }

  // additional info to format
  if (![excluding containsObject:kErrorStackTraceKey]) {
    [logger addObject:[NSString stringWithFormat:@"Stack Trace: %@\n", error.stackTrace]];
  }

  // Add screenshots.
  if (![excluding containsObject:kErrorAppScreenShotsKey]) {
    NSArray *keyOrder = @[
      kGREYAppScreenshotAtFailure, kGREYTestScreenshotAtFailure, kGREYScreenshotBeforeImage,
      kGREYScreenshotExpectedAfterImage, kGREYScreenshotActualAfterImage
    ];
    NSMutableDictionary *appScreenshots =
        error.appScreenshots ? [NSMutableDictionary dictionaryWithCapacity:keyOrder.count] : nil;
    NSEnumerator *keyEnumerator = [error.appScreenshots keyEnumerator];
    NSString *key;
    while (key = [keyEnumerator nextObject]) {
      appScreenshots[key] = error.appScreenshots[key];
    };
    NSString *screenshots = [GREYObjectFormatter formatDictionary:appScreenshots
                                                           indent:kGREYObjectFormatIndent
                                                        hideEmpty:YES
                                                         keyOrder:keyOrder];

    [logger addObject:[NSString stringWithFormat:@"Screenshots: %@\n", screenshots]];
  }

  // UI hierarchy and legend. Print windows from back to front.
  if (![excluding containsObject:kErrorAppUIHierarchyKey]) {
    [logger addObject:@"UI Hierarchy (ordered by window level, back to front):\n"];

    NSString *windowLegend = @"[Window 1]";
    NSString *axLegend = @"[AX]";
    NSString *uieLegend = @"[UIE]";

    NSDictionary *legendLabels = @{
      windowLegend : @"Back-Most Window",
      axLegend : @"Accessibility",
      uieLegend : @"User Interaction Enabled"
    };
    NSArray *keyOrder = @[ windowLegend, axLegend, uieLegend ];

    NSString *legendDescription = [GREYObjectFormatter formatDictionary:legendLabels
                                                                 indent:kGREYObjectFormatIndent
                                                              hideEmpty:NO
                                                               keyOrder:keyOrder];
    [logger addObject:[NSString stringWithFormat:@"%@: %@\n", @"Legend", legendDescription]];

    // If a user creates a custom simple error on the test side, then the hierarchy might not exist.
    if ([error respondsToSelector:@selector(appUIHierarchy)]) {
      NSString *appUIHierarchy = error.appUIHierarchy;
      if (appUIHierarchy) {
        [logger addObject:appUIHierarchy];
      }
    }
  }
  
  return [logger componentsJoinedByString:@"\n"];
}

@end
