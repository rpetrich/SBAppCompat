#import <UIKit/UIKit.h>

#include <execinfo.h>
#include <dlfcn.h>

// Headers

extern UIApplication *UIApp;

@interface SBApplication : NSObject
- (NSString *)bundleIdentifier;
@end

@interface SBApplicationController : NSObject
- (SBApplication *)applicationWithBundleIdentifier:(NSString *)bundleIdentifier;
@end

// Alerting/Logging

@implementation NSObject (SBAppCompat)

static BOOL hasAlreadyHappened;

+ (void)_invalidOperationWithCulpritDictionary:(NSDictionary *)culpritDictionary
{
	if (UIApp && !hasAlreadyHappened) {
		hasAlreadyHappened = YES;
		UIAlertView *av = [[UIAlertView alloc] init];
		av.title = @"Invalid Operation";
		NSString *culprit = [culpritDictionary objectForKey:@"culprit"];
		NSString *selector = [culpritDictionary objectForKey:@"selector"];
		av.message = [NSString stringWithFormat:@"%@ has called -[%@ %@] without checking the iOS version, and this doesn't exist on iOS 8 anymore!\nContact %@'s developer.", culprit, self, selector, culprit];
		[av addButtonWithTitle:@"OK"];
		[av show];
		[av release];
	}
}

+ (void)_invalidSBAppOperationWithSelector:(SEL)selector
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	void *symbols[20];
	size_t size = backtrace(symbols, 20);
	NSString *culprit = nil;
	if (size) {
		char **strings = backtrace_symbols(symbols, size);
		for (int i = 0; i < size; i++) {
			NSString *description = [NSString stringWithUTF8String:strings[i]];
			culprit = [[[description componentsSeparatedByString:@" "] objectAtIndex:3] stringByDeletingPathExtension];
			if (![culprit isEqualToString:@"SBAppCompat"])
				break;
		}
		free(strings);
	}
	NSDictionary *culpritDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithUTF8String:(void *)selector], @"selector",
		culprit, @"culprit",
		nil];
	[self performSelector:@selector(_invalidOperationWithCulpritDictionary:) withObject:culpritDictionary afterDelay:0.0];
	NSLog(@"SBAppCompat: %@ called -[%@ %s] without checking the iOS version, and this doesn't exist on iOS 8 anymore!", culprit, self, (void *)selector);
	[pool drain];
}

@end

// Compatibility shims

%hook SBApplicationController

+ (BOOL)instancesRespondToSelector:(SEL)selector
{
	return selector == @selector(applicationWithDisplayIdentifier:) ? NO : %orig();
}

- (BOOL)respondsToSelector:(SEL)selector
{
	return selector == @selector(applicationWithDisplayIdentifier:) ? NO : %orig();
}

%new
- (SBApplication *)applicationWithDisplayIdentifier:(NSString *)displayIdentifier
{
	[[self class] _invalidSBAppOperationWithSelector:_cmd];
	return [self applicationWithBundleIdentifier:displayIdentifier];
}

%end

%hook SBApplication

+ (BOOL)instancesRespondToSelector:(SEL)selector
{
	return selector == @selector(displayIdentifier) ? NO : %orig();
}

- (BOOL)respondsToSelector:(SEL)selector
{
	return selector == @selector(displayIdentifier) ? NO : %orig();
}

%new
- (NSString *)displayIdentifier
{
	return [self bundleIdentifier];
}

%end

%ctor {
	dlopen("/Library/MobileSubstrate/DynamicLibraries/AppList.dylib", RTLD_LAZY);
	%init();
}
