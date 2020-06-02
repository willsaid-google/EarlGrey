//
//  GREYErrorFormatter.m
//  CommonLib
//
//  Created by Will Said on 6/1/20.
//

#import "GREYErrorFormatter.h"

#import "GREYObjectFormatter.h"
#import "GREYInteraction.h"
#import "GREYFatalAsserts.h"
#import "GREYErrorConstants.h"

@interface GREYErrorFormatter ()

@property(readonly, nonatomic) GREYError *error;

@end

@implementation GREYErrorFormatter

#pragma mark - Init

- (instancetype)initWithError:(GREYError *)error {
  self = [super init];
  if (self) {
    _error = error;
  }
  return self;
}

#pragma mark - Public Methods

- (NSString *)humanReadableDescription {
  if (_error.domain == kGREYInteractionErrorDomain &&
      _error.code == kGREYInteractionElementNotFoundErrorCode) {
    return [self _elementNotFoundDescription];
  }
  GREYFatalAssertWithMessage(false, @"Exception type not supported for formatting");
}

<<<<<<< HEAD
// called from handleException
+ (NSString *)appendScreenshots:(NSDictionary *)screenshots
                   andHierarchy:(NSString *)hierarchy
                      toDetails:(NSString *)details {
  return nil;
}

#pragma mark - Private Methods

- (NSString *)_formattedHierarchy:(nonnull NSString *)hierarchy {
    NSMutableArray *logger = [[NSMutableArray alloc] init];
    
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
    [logger addObject:_error.appUIHierarchy];
    return [logger componentsJoinedByString:@"\n"];
=======
#pragma mark - Private Methods

- (NSString *)_appUIHierarchy {
  NSMutableArray *logger = [[NSMutableArray alloc] init];
  
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
  if ([self respondsToSelector:@selector(appUIHierarchy)]) {
    NSString *appUIHierarchy = _error.appUIHierarchy;
    if (appUIHierarchy) {
      [logger addObject:appUIHierarchy];
    }
  }
  
  return [logger componentsJoinedByString:@"\n"];
>>>>>>> 6191072... [WIP] elementNotFound
}

- (NSString *)_elementNotFoundDescription {
  NSMutableArray *logger = [[NSMutableArray alloc] init];
  
  // exception reason
  [logger addObject:[NSString stringWithFormat:@"\n%@\n", _error.localizedDescription]];

  // recovery suggestion
<<<<<<< HEAD
  if (_error.userInfo[kErrorDetailRecoverySuggestionKey]) {
    [logger addObject:[NSString stringWithFormat:@"%@\n",
                       _error.userInfo[kErrorDetailRecoverySuggestionKey]]];
  }
  
  // element matcher
  if (_error.userInfo[kErrorDetailElementMatcherKey]) {
    [logger addObject:[NSString stringWithFormat:@"Element Matcher: \n%@\n",
                       _error.userInfo[kErrorDetailElementMatcherKey]]];
  }

  // search api info, pretty printed (if it was a search)
  if (_error.userInfo[kErrorDetailSearchActionInfoKey]) {
    [logger addObject:[NSString stringWithFormat:@"Search Action Info \n%@\n",
                       _error.userInfo[kErrorDetailSearchActionInfoKey]]];
  }
  
  // screenshots
  for (NSString *key in _error.appScreenshots.allKeys) {
    [logger addObject:[NSString stringWithFormat:@"%@: %@\n", key, _error.appScreenshots[key]]];
=======
  if (_error.userInfo[@"Recovery Suggestion"]) {
    [logger addObject:[NSString stringWithFormat:@"%@\n",
                       _error.userInfo[@"Recovery Suggestion"]]]; // use constants!!!
  }
  
  // element matcher
  if (_error.userInfo[@"Element Matcher:"]) {
    [logger addObject:[NSString stringWithFormat:@"Element Matcher: \n%@\n",
                       _error.userInfo[@"Element Matcher"]]];
  }

  // search api info, pretty printed (if it was a search)
  if (_error.userInfo[@"Search API Info"]) {
    [logger addObject:[NSString stringWithFormat:@"Search API Info \n%@\n",
                       _error.userInfo[@"Search API Info"]]];
>>>>>>> 6191072... [WIP] elementNotFound
  }
  
  // nested error
  if (_error.nestedError) {
    [logger addObject:[NSString stringWithFormat:@"Underlying Error: \n%@\n",
                       _error.nestedError.description]];
  }
  
<<<<<<< HEAD
  // UI hierarchy
  if (_error.appUIHierarchy) {
    [logger addObject:[self _formattedHierarchy:_error.appUIHierarchy]];
  }

  // stack trace
  if (_error.stackTrace) {
    [logger addObject:[NSString stringWithFormat:@"Stack Trace: %@\n", _error.stackTrace]];
  }
=======
  // screenshots
  for (NSString *key in _error.appScreenshots.allKeys) {
    [logger addObject:[NSString stringWithFormat:@"%@: %@\n", key, _error.appScreenshots[key]]];
  }
  
  // UI hierarchy
  [logger addObject:[self _appUIHierarchy]];

  // stack trace
  [logger addObject:[NSString stringWithFormat:@"Stack Trace: %@\n", _error.stackTrace]];
>>>>>>> 6191072... [WIP] elementNotFound
  
  return [logger componentsJoinedByString:@"\n"];
}

@end