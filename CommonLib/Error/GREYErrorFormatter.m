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

#import "GREYErrorFormatter.h"

#import "GREYObjectFormatter.h"
#import "GREYInteraction.h"
#import "GREYErrorConstants.h"
#import "NSError+GREYCommon.h"
#import "GREYError+Private.h"
#import "GREYFatalAsserts.h"

#pragma mark - UI Hierarchy Keys

static NSString *const kHierarchyWindowLegendKey                 = @"[Window 1]";
static NSString *const kHierarchyAcessibilityLegendKey           = @"[AX]";
static NSString *const kHierarchyUserInteractionEnabledLegendKey = @"[UIE]";
static NSString *const kHierarchyBackWindowKey                   = @"Back-Most Window";
static NSString *const kHierarchyAccessibilityKey                = @"Accessibility";
static NSString *const kHierarchyUserInteractionEnabledKey       = @"User Interaction Enabled";
static NSString *const kHierarchyLegendKey                       = @"Legend";
static NSString *const kHierarchyHeaderKey                       = @"UI Hierarchy (ordered by wind"
                                                                   @"ow level, back to front):\n";

#pragma mark - GREYErrorFormatterFlag

/**
 * Keys used by GREYErrorFormatter to format a GREYError's userInfo properties.
 * These states are not mutually exclusive and can be combined together using Bitwise-OR to
 * represent multiple states.
 * If more than 32 options exists, change the bitshifted values to UL.
 */
typedef NS_OPTIONS(NSUInteger, GREYErrorFormatterFlag) {
  /** Empty Error Description  */
  GREYErrorFormatterNone = 0,
  /** Exception Reason */
  GREYErrorFormatterFlagExceptionReason = 1 << 0,
  /** Recovery Suggestion */
  GREYErrorFormatterFlagRecoverySuggestion = 1 << 1,
  /** Element Matcher */
  GREYErrorFormatterFlagElementMatcher = 1 << 2,
  /** Search API Info  */
  GREYErrorFormatterFlagSearchActionInfo = 1 << 3,
  /** Assertion Criteria, or Action Name */
  GREYErrorFormatterFlagCriteria = 1 << 4,
  /** Underlying ("Nested") Error */
  GREYErrorFormatterFlagUnderlyingError = 1 << 5,
  /** App UI Hierarchy */
  GREYErrorFormatterFlagUIHierarchy = 1 << 6,
  /** If Multiple Elements were Matched */
  GREYErrorFormatterFlagMultipleMatched = 1 << 7,
  /** Constraint(s) that Failed */
  GREYErrorFormatterFlagFailedConstraints = 1 << 8,
  /** Description of the Element Involved in the Error */
  GREYErrorFormatterFlagElementDescription = 1 << 9
};

#pragma mark - GREYErrorFormatter

@implementation GREYErrorFormatter

#pragma mark - Public Methods

+ (NSString *)formattedDescriptionForError:(GREYError *)error {
  if (GREYShouldUseErrorFormatterForError(error)) {
    return loggerDescription(error);
  }
  return [GREYObjectFormatter formatDictionary:[error grey_descriptionDictionary]
                                        indent:kGREYObjectFormatIndent
                                     hideEmpty:YES
                                      keyOrder:nil];
}

#pragma mark - Public Functions

BOOL GREYShouldUseErrorFormatterForError(GREYError *error) {
    return [error.domain isEqualToString:kGREYInteractionErrorDomain] &&
           (error.code == kGREYInteractionElementNotFoundErrorCode ||
            error.code == kGREYInteractionMultipleElementsMatchedErrorCode ||
            error.code == kGREYInteractionConstraintsFailedErrorCode);
}

BOOL GREYShouldUseErrorFormatterForExceptionReason(NSString *reason) {
  return [reason containsString:@"the desired element was not found"] ||
         [reason containsString:@"Multiple elements were matched"] ||
         [reason containsString:@"Cannot perform action due to constraint"];
}

#pragma mark - Static Functions

// The keys whose values should be supplied in the formatted error output.
static NSUInteger loggerKeys(GREYError *error) {
  if ([error.domain isEqualToString:kGREYInteractionErrorDomain] &&
       error.code == kGREYInteractionElementNotFoundErrorCode) {
     return GREYErrorFormatterFlagExceptionReason |
            GREYErrorFormatterFlagRecoverySuggestion |
            GREYErrorFormatterFlagElementMatcher |
            GREYErrorFormatterFlagCriteria |
            GREYErrorFormatterFlagSearchActionInfo |
            GREYErrorFormatterFlagUnderlyingError |
            GREYErrorFormatterFlagUIHierarchy;
  }
  if ([error.domain isEqualToString:kGREYInteractionErrorDomain] &&
       error.code == kGREYInteractionMultipleElementsMatchedErrorCode) {
    return GREYErrorFormatterFlagExceptionReason    |
           GREYErrorFormatterFlagRecoverySuggestion |
           GREYErrorFormatterFlagElementMatcher     |
           GREYErrorFormatterFlagMultipleMatched    |
           GREYErrorFormatterFlagUnderlyingError    |
           GREYErrorFormatterFlagUIHierarchy;
  }
  if ([error.domain isEqualToString:kGREYInteractionErrorDomain] &&
       error.code == kGREYInteractionConstraintsFailedErrorCode) {
    return GREYErrorFormatterFlagExceptionReason    |
           GREYErrorFormatterFlagCriteria           |
           GREYErrorFormatterFlagRecoverySuggestion |
           GREYErrorFormatterFlagFailedConstraints  |
           GREYErrorFormatterFlagElementDescription |
           GREYErrorFormatterFlagUnderlyingError    |
           GREYErrorFormatterFlagUIHierarchy;
  }
  GREYFatalAssertWithMessage(false, @"Error Domain and Code Not Yet Supported");
}

static NSString *formattedHierarchy(NSString *hierarchy) {
  if (!hierarchy) {
    return nil;
  }
  NSMutableArray<NSString*> *logger = [[NSMutableArray alloc] init];
  [logger addObject:kHierarchyHeaderKey];
  NSString *windowLegend = kHierarchyWindowLegendKey;
  NSString *axLegend = kHierarchyAcessibilityLegendKey;
  NSString *uieLegend = kHierarchyUserInteractionEnabledLegendKey;
  NSDictionary<NSString *, NSString *> *legendLabels = @{
    windowLegend : kHierarchyBackWindowKey,
    axLegend : kHierarchyAccessibilityKey,
    uieLegend : kHierarchyUserInteractionEnabledKey
  };
  NSArray<NSString *> *keyOrder = @[ windowLegend, axLegend, uieLegend ];
  NSString *legendDescription = [GREYObjectFormatter formatDictionary:legendLabels
                                                               indent:kGREYObjectFormatIndent
                                                            hideEmpty:NO
                                                             keyOrder:keyOrder];
  [logger addObject:[NSString stringWithFormat:@"%@: %@\n", kHierarchyLegendKey,
                     legendDescription]];
  [logger addObject:hierarchy];
  return [logger componentsJoinedByString:@"\n"];
}

static NSString *loggerDescription(GREYError *error) {
  NSUInteger keys = loggerKeys(error);
  
  NSMutableArray<NSString *> *logger = [[NSMutableArray alloc] init];
  
  if (keys & GREYErrorFormatterFlagExceptionReason) {
    NSString *exceptionReason = error.localizedDescription;
    [logger addObject:[NSString stringWithFormat:@"\n%@", exceptionReason]];
  }
  
  if (keys & GREYErrorFormatterFlagRecoverySuggestion) {
    NSString *recoverySuggestion = error.userInfo[kErrorDetailRecoverySuggestionKey];
    if (recoverySuggestion) {
      [logger addObject:recoverySuggestion];
    }
  }
  
  if (keys & GREYErrorFormatterFlagElementMatcher) {
    NSString *elementMatcher = error.userInfo[kErrorDetailElementMatcherKey];
    if (elementMatcher) {
      [logger addObject:[NSString stringWithFormat:@"%@:\n%@", kErrorDetailElementMatcherKey,
                         elementMatcher]];
    }
  }
  
  if (keys & GREYErrorFormatterFlagFailedConstraints) {
    NSString *failedConstraints = error.userInfo[kErrorDetailConstraintRequirementKey];
    if (failedConstraints) {
      [logger addObject:[NSString stringWithFormat:@"%@:\n%@", kErrorDetailConstraintRequirementKey,
                         failedConstraints]];
    }
  }
  
  if (keys & GREYErrorFormatterFlagElementDescription) {
    NSString *element = error.userInfo[kErrorDetailElementDescriptionKey];
    if (element) {
      [logger addObject:[NSString stringWithFormat:@"%@:\n%@", kErrorDetailElementDescriptionKey,
                         element]];
    }
  }
  
  if (keys & GREYErrorFormatterFlagCriteria) {
    NSString *assertionCriteria = error.userInfo[kErrorDetailAssertCriteriaKey];
    if (assertionCriteria) {
      [logger addObject:[NSString stringWithFormat:@"%@: %@", kErrorDetailAssertCriteriaKey,
                         assertionCriteria]];
    }
    NSString *actionCriteria = error.userInfo[kErrorDetailActionNameKey];
    if (actionCriteria) {
      [logger addObject:[NSString stringWithFormat:@"%@: %@", kErrorDetailActionNameKey,
                         actionCriteria]];
    }
  }
  
  if (keys & GREYErrorFormatterFlagMultipleMatched) {
    NSArray<NSString *> *multipleElementsMatched = error.multipleElementsMatched;
    if (multipleElementsMatched) {
      [logger addObject:[NSString stringWithFormat:@"%@:", kErrorDetailElementsMatchedKey]];
      [multipleElementsMatched enumerateObjectsUsingBlock: ^(NSString *element,
                                                             NSUInteger index, BOOL *stop) {
        // Numbered list of all elements that were matched, starting at 1.
        [logger addObject:[NSString stringWithFormat:@"%lu. %@",
                           (unsigned long)index + 1, element]];
      }];
      [logger addObject:@"\n"];
    }
  }
  
  if (keys & GREYErrorFormatterFlagSearchActionInfo) {
    NSString *searchActionInfo = error.userInfo[kErrorDetailSearchActionInfoKey];
    if (searchActionInfo) {
      [logger addObject:[NSString stringWithFormat:@"%@\n%@", kErrorDetailSearchActionInfoKey,
                         searchActionInfo]];
    }
  }
  
  if (keys & GREYErrorFormatterFlagUnderlyingError) {
    NSString *nestedError = error.nestedError.description;
    if (nestedError) {
      [logger addObject:[NSString stringWithFormat:@"Underlying Error:\n%@", nestedError]];
    }
  }
  
  if (keys & GREYErrorFormatterFlagUIHierarchy) {
    NSString *UIHierarchy = formattedHierarchy(error.appUIHierarchy);
    if (UIHierarchy) {
      [logger addObject:UIHierarchy];
    }
  }
  
  return [NSString stringWithFormat:@"%@\n", [logger componentsJoinedByString:@"\n\n"]];
}

@end
