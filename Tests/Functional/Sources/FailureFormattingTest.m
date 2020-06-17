//
// Copyright 2020 Google Inc.
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

#import "BaseIntegrationTest.h"

#import "GREYError.h"
#import "EarlGrey.h"
#import "FailureHandler.h"

# pragma mark - GREYFailureFormatTestingFailureHandler

/**
 * Failure handler used for testing the console output of failures
 */
@interface FailureFormatTestingFailureHandler : NSObject <GREYFailureHandler>
@property NSString *fileName;
@property(assign) NSUInteger lineNumber;
@property GREYFrameworkException *exception;
@property NSString *details;
@end

@implementation FailureFormatTestingFailureHandler

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  self.exception = exception;
  self.details = details;
}

- (void)setInvocationFile:(NSString *)fileName andInvocationLine:(NSUInteger)lineNumber {
  self.fileName = fileName;
  self.lineNumber = lineNumber;
}

@end

# pragma mark - FailureFormattingTest

/**
 * Tests that the user-facing console output follows expectations.
 */
@interface FailureFormattingTest : BaseIntegrationTest
@property(readonly, nonatomic) FailureFormatTestingFailureHandler *handler;
@end

@implementation FailureFormattingTest

- (void)setUp {
  [super setUp];
  _handler = [[FailureFormatTestingFailureHandler alloc] init];
  [NSThread mainThread].threadDictionary[GREYFailureHandlerKey] = _handler;
}

/// Tests the Element Not Found formatting for kGREYInteractionElementNotFoundErrorCode
/// that does not originate from a search action failure
- (void)testNotFoundAssertionErrorDescription {
  id<GREYMatcher> matcher =
      [[GREYHostApplicationDistantObject sharedInstance] matcherForFirstElement];
  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_kindOfClass([UITableViewCell class]),
                                                 matcher, nil)]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")]
                    assertWithMatcher:grey_notNil()
                                error:nil];
  
  NSString *expectedDetails = @"Interaction cannot continue because the desired element was not "
                              @"found.\n"
                              @"\n"
                              @"Check if the element exists in the UI hierarchy printed below. If "
                              @"it exists, adjust the matcher so that it accurately matches "
                              @"the element.\n"
                              @"\n"
                              @"Element Matcher:\n"
                              @"((kindOfClass('UILabel') || kindOfClass('UITextField') || "
                              @"kindOfClass('UITextView')) && hasText('Basic Views'))\n"
                              @"\n"
                              @"Assertion Criteria: assertWithMatcher:isNotNil";
  XCTAssertTrue([_handler.details containsString:expectedDetails]);
}

/// Tests the Element Not Found formatting for kGREYInteractionElementNotFoundErrorCode
/// that originates from a search action failure
- (void)testSearchNotFoundAssertionErrorDescription {
  [self openTestViewNamed:@"Scroll Views"];
  id<GREYMatcher> matcher = grey_allOf(grey_accessibilityLabel(@"Label 2"), grey_interactable(),
                                       grey_sufficientlyVisible(), nil);
  [[[EarlGrey selectElementWithMatcher:matcher]
                     usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
                  onElementWithMatcher:grey_accessibilityLabel(@"Invalid Scroll View")]
                     assertWithMatcher:grey_sufficientlyVisible()
                                 error:nil];

  NSString *expectedDetails = @"Search action failed: Interaction cannot continue because the "
                              @"desired element was not found.\n"
                              @"\n"
                              @"Check if the element exists in the UI hierarchy printed below. If "
                              @"it exists, adjust the matcher so that it accurately matches "
                              @"the element.\n"
                              @"\n"
                              @"Element Matcher:\n"
                              @"(((respondsToSelector(isAccessibilityElement) && "
                              @"isAccessibilityElement) && accessibilityLabel('Label 2')) && "
                              @"interactable Point:{nan, nan} && sufficientlyVisible(Expected: "
                              @"0.750000, Actual: 0.000000))\n"
                              @"\n"
                              @"Assertion Criteria: assertWithMatcher:sufficientlyVisible(Expe"
                              @"cted: 0.750000, Actual: 0.000000)\n"
                              @"\n"
                              @"Search API Info\n"
                              @"Search Action: ";
  XCTAssertTrue([_handler.details containsString:expectedDetails]);
}

/// Tests the Element Not Found formatting for an Action failure
- (void)testNotFoundActionErrorDescription {
  CFTimeInterval originalInteractionTimeout =
      GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  [[GREYConfiguration sharedConfiguration] setValue:@(1)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  NSString *jsStringAboveTimeout =
      @"start = new Date().getTime(); while (new Date().getTime() < start + 3000);";
  // JS action timeout greater than the threshold.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TestWKWebView")]
      performAction:grey_javaScriptExecution(jsStringAboveTimeout, nil)
              error:nil];
  [[GREYConfiguration sharedConfiguration] setValue:@(originalInteractionTimeout)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  NSString *expectedDetails = @"Interaction cannot continue because the "
                              @"desired element was not found.\n"
                              @"\n"
                              @"Check if the element exists in the UI hierarchy printed below. If "
                              @"it exists, adjust the matcher so that it accurately matches "
                              @"the element.\n"
                              @"\n"
                              @"Element Matcher:\n"
                              @"(respondsToSelector(accessibilityIdentifier) && "
                              @"accessibilityID('TestWKWebView'))\n"
                              @"\n"
                              @"Action Name: Execute JavaScript";
  XCTAssertTrue([_handler.details containsString:expectedDetails]);
}

- (void)testMultipleMatchedErrorDescription {
  [[EarlGrey selectElementWithMatcher:grey_kindOfClass([UITableViewCell class])]
                        performAction:grey_tap()
                                error:nil];

  NSString *expectedDetails = @"Multiple elements were matched. Please use selection matchers "
                               @"to narrow the selection down to a single element.\n"
                               @"\n"
                               @"Create a more specific matcher to uniquely match the element.\n"
                               @"In general, prefer using accessibility ID before accessibility "
                               @"label or other attributes.\n"
                               @"Use atIndex: to select from one of the matched elements.\n"
                               @"Keep in mind when using atIndex: that the order in which "
                               @"elements are arranged may change, making your test brittle.\n"
                               @"\n"
                               @"Element Matcher:\n"
                               @"kindOfClass('UITableViewCell')\n"
                               @"\n"
                               @"Elements Matched:\n"
                               @"\n"
                               @"1.";
  XCTAssertTrue([_handler.details containsString:expectedDetails]);
  XCTAssertTrue([_handler.details containsString:@"UI Hierarchy"]);
}

- (void)testConstraintsFailureErrorDescription {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Disabled")]
      performAction:grey_scrollInDirection(kGREYDirectionUp, 20)
              error:nil];
  NSString *expectedDetails1 = @"Cannot perform action due to constraint(s) failure.\n"
                               @"\n"
                               @"Adjust element properties so that it matches the failed "
                               @"constraint(s).\n"
                               @"\n"
                               @"Failed Constraint(s):\n"
                               @"kindOfClass('UIScrollView')kindOfClass('WKWebView'), \n"
                               @"\n"
                               @"Element Description:\n"
                               @"<UIButton:";
  NSString *expectedDetails2 = @"Action Name: Scroll Up for 20\n"
                               @"\n"
                               @"UI Hierarchy";
  XCTAssertTrue([_handler.details containsString:expectedDetails1]);
  XCTAssertTrue([_handler.details containsString:expectedDetails2]);
}

@end
