#import "WeatherInfo.h"

#import <Cephei/HBPreferences.h>
#import <PeterDev/libpddokdo.h>

#define DegreesToRadians(degrees) (degrees * M_PI / 180)

static float const _1_HOUR = 60 * 60;

static int const WINDOW_WIDTH = 120;
static int const WINDOW_HEIGHT = 20;
static int const LABEL_WIDTH = 100;

static double screenWidth;
static double screenHeight;
static UIDeviceOrientation orientationOld;

__strong static id weatherInfoObject;

static HBPreferences *pref;
static BOOL enabled;
static BOOL showOnLockScreen;
static BOOL hideConditions;
static BOOL hideCityNameLabel;
static long weatherConditionsGlyphSize;
static long conditionsFontSize;
static BOOL conditionsFontBold;
static long cityNameFontSize;
static BOOL cityNameFontBold;
static double portraitX;
static double portraitY;
static double landscapeX;
static double landscapeY;
static BOOL followDeviceOrientation;

static void orientationChanged()
{
	if(followDeviceOrientation && weatherInfoObject) 
		[weatherInfoObject updateOrientation];
}

static void loadDeviceScreenDimensions()
{
	UIDeviceOrientation orientation = [[UIApplication sharedApplication] _frontMostAppOrientation];
	if(orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
	{
		screenWidth = [[UIScreen mainScreen] bounds].size.height;
		screenHeight = [[UIScreen mainScreen] bounds].size.width;
	}
	else
	{
		screenWidth = [[UIScreen mainScreen] bounds].size.width;
		screenHeight = [[UIScreen mainScreen] bounds].size.height;
	}
}

@implementation WeatherInfo

	- (id)init
	{
		self = [super init];
		if(self)
		{
			@try
			{
				weatherInfoWindow = [[UIWindow alloc] initWithFrame: CGRectMake(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)];
				[weatherInfoWindow setHidden: NO];
				[weatherInfoWindow setAlpha: 1];
				[weatherInfoWindow _setSecure: YES];
				[weatherInfoWindow setUserInteractionEnabled: YES];
				[[weatherInfoWindow layer] setAnchorPoint: CGPointZero];

				glyphImageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, WINDOW_HEIGHT / 2 - weatherConditionsGlyphSize / 2, weatherConditionsGlyphSize, weatherConditionsGlyphSize)];
				[glyphImageView setContentMode: UIViewContentModeScaleAspectFit];
				[glyphImageView setUserInteractionEnabled: YES];
				[weatherInfoWindow addSubview: glyphImageView];
				
				conditionsLabel = [[UILabel alloc] initWithFrame: CGRectMake(weatherConditionsGlyphSize + 3, 0, LABEL_WIDTH, WINDOW_HEIGHT / 2)];
				[conditionsLabel setNumberOfLines: 1];
				[conditionsLabel setTextAlignment: NSTextAlignmentLeft];
				[conditionsLabel setUserInteractionEnabled: YES];
				[weatherInfoWindow addSubview: conditionsLabel];

				cityNameLabel = [[UILabel alloc] initWithFrame: CGRectMake(weatherConditionsGlyphSize + 3, WINDOW_HEIGHT / 2, LABEL_WIDTH, WINDOW_HEIGHT / 2)];
				[cityNameLabel setNumberOfLines: 1];
				[cityNameLabel setTextAlignment: NSTextAlignmentLeft];
				[cityNameLabel setUserInteractionEnabled: YES];
				[weatherInfoWindow addSubview: cityNameLabel];

				useOriginalGlyph = YES;

				[self updateFrame];

				[NSTimer scheduledTimerWithTimeInterval: _1_HOUR target: self selector: @selector(updateText) userInfo: nil repeats: YES];

				CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)&orientationChanged, CFSTR("com.apple.springboard.screenchanged"), NULL, 0);
				CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), NULL, (CFNotificationCallback)&orientationChanged, CFSTR("UIWindowDidRotateNotification"), NULL, CFNotificationSuspensionBehaviorCoalesce);
			}
			@catch (NSException *e) {}
		}
		return self;
	}

	- (void)updateFrame
	{
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(_updateFrame) object: nil];
		[self performSelector: @selector(_updateFrame) withObject: nil afterDelay: 0.3];
	}

	- (void)_updateFrame
	{
		if(showOnLockScreen) [weatherInfoWindow setWindowLevel: 1051];
		else [weatherInfoWindow setWindowLevel: 1000];
		
		[self updateweatherConditionsGlyphSize];
		[self updateLabelsSize];

		[self updateLabelProperties];

		orientationOld = nil;
		[self updateOrientation];
	}

	- (void)updateLabelProperties
	{
		if(conditionsFontBold) [conditionsLabel setFont: [UIFont boldSystemFontOfSize: conditionsFontSize]];
		else [conditionsLabel setFont: [UIFont systemFontOfSize: conditionsFontSize]];
		
		if(!hideCityNameLabel)
		{
			if(cityNameFontBold) [cityNameLabel setFont: [UIFont boldSystemFontOfSize: cityNameFontSize]];
			else [cityNameLabel setFont: [UIFont systemFontOfSize: cityNameFontSize]];
		}
	}

	- (void)updateweatherConditionsGlyphSize
	{
		CGRect frame = [glyphImageView frame];
		frame.origin.y = WINDOW_HEIGHT / 2 - weatherConditionsGlyphSize / 2;
		frame.size.width = weatherConditionsGlyphSize;
		frame.size.height = weatherConditionsGlyphSize;
		[glyphImageView setFrame: frame];
	}

	- (void)updateGlyphSize
	{
		CGRect frame = [glyphImageView frame];
		frame.origin.y = WINDOW_HEIGHT / 2 - weatherConditionsGlyphSize / 2;
		frame.size.width = weatherConditionsGlyphSize;
		frame.size.height = weatherConditionsGlyphSize;
		[glyphImageView setFrame: frame];
	}

	- (void)updateLabelsSize
	{
		CGRect frame = [conditionsLabel frame];
		frame.origin.x = weatherConditionsGlyphSize + 3;
		frame.size.height = hideCityNameLabel ? WINDOW_HEIGHT : WINDOW_HEIGHT / 2;
		[conditionsLabel setFrame: frame];

		if(hideCityNameLabel) [cityNameLabel setHidden: YES];
		else
		{
			[cityNameLabel setHidden: NO];

			frame = [cityNameLabel frame];
			frame.origin.x = weatherConditionsGlyphSize + 3;
			[cityNameLabel setFrame: frame];
		}
	}

	- (void)updateOrientation
	{
		if(!followDeviceOrientation)
		{
			CGRect frame = [weatherInfoWindow frame];
			frame.origin.x = portraitX;
			frame.origin.y = portraitY;
			[weatherInfoWindow setFrame: frame];
		}
		else
		{
			UIDeviceOrientation deviceOrientation = [[UIApplication sharedApplication] _frontMostAppOrientation];
			if(deviceOrientation == orientationOld)
				return;
			
			CGAffineTransform newTransform;
			CGRect frame = [weatherInfoWindow frame];

			switch(deviceOrientation)
			{
				case UIDeviceOrientationLandscapeRight:
				{
					frame.origin.x = landscapeY;
					frame.origin.y = screenHeight - landscapeX;
					newTransform = CGAffineTransformMakeRotation(-DegreesToRadians(90));
					break;
				}
				case UIDeviceOrientationLandscapeLeft:
				{
					frame.origin.x = screenWidth - landscapeY;
					frame.origin.y = landscapeX;
					newTransform = CGAffineTransformMakeRotation(DegreesToRadians(90));
					break;
				}
				case UIDeviceOrientationPortraitUpsideDown:
				{
					frame.origin.x = screenWidth - portraitX;
					frame.origin.y = screenHeight - portraitY;
					newTransform = CGAffineTransformMakeRotation(DegreesToRadians(180));
					break;
				}
				case UIDeviceOrientationPortrait:
				default:
				{
					frame.origin.x = portraitX;
					frame.origin.y = portraitY;
					newTransform = CGAffineTransformMakeRotation(DegreesToRadians(0));
					break;
				}
			}

			[UIView animateWithDuration: 0.3f animations:
			^{
				[weatherInfoWindow setTransform: newTransform];
				[weatherInfoWindow setFrame: frame];
				orientationOld = deviceOrientation;
			} completion: nil];
		}
	}

	- (void)updateText
	{
		[[PDDokdo sharedInstance] refreshWeatherData];
		NSDictionary *weatherData = [[PDDokdo sharedInstance] weatherData];

		NSString *temperature = [weatherData objectForKey:@"temperature"];
		NSString *conditions = [weatherData objectForKey:@"conditions"];
		NSString *location = [weatherData objectForKey:@"location"];
		UIImage *conditionsImage = [weatherData objectForKey:@"conditionsImage"];

		if(hideConditions) [conditionsLabel setText: temperature];
		else [conditionsLabel setText: [NSString stringWithFormat: @"%@ %@", temperature, conditions]];
		[cityNameLabel setText: location];
		[glyphImageView setImage: conditionsImage];
	}

	- (void)updateTextColor: (UIColor*)color
	{
		CGFloat r;
    	[color getRed: &r green: nil blue: nil alpha: nil];
		if(r == 0 || r == 1)
		{
			if([glyphImageView image])
			{
				if(r == 0) 
				{
					useOriginalGlyph = NO;
					[glyphImageView setTintColor: [UIColor blackColor]];
				}
				else
				{
					useOriginalGlyph = YES;
					[glyphImageView setTintColor: [UIColor whiteColor]];
				} 
			}

			[cityNameLabel setTextColor: color];
			backupColor = color;

			[[conditionsLabel textColor] getRed: &r green: nil blue: nil alpha: nil];
			if(r == 0 || r == 1)
				[conditionsLabel setTextColor: color];
		}
	}

@end

%hook SpringBoard

- (void)applicationDidFinishLaunching: (id)application
{
	%orig;

	loadDeviceScreenDimensions();
	if(!weatherInfoObject) 
	{
		weatherInfoObject = [[WeatherInfo alloc] init];
		[weatherInfoObject updateText];
	}
}

%end

%hook _UIStatusBar

-(void)setForegroundColor: (UIColor*)color
{
	%orig;
	
	if(weatherInfoObject && [self styleAttributes] && [[self styleAttributes] imageTintColor]) 
		[weatherInfoObject updateTextColor: [[self styleAttributes] imageTintColor]];
}

%end

static void settingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	if(!pref) pref = [[HBPreferences alloc] initWithIdentifier: @"com.johnzaro.weatherinfoprefs"];
	enabled = [pref boolForKey: @"enabled"];
	showOnLockScreen = [pref boolForKey: @"showOnLockScreen"];
	hideConditions = [pref boolForKey: @"hideConditions"];
	hideCityNameLabel = [pref boolForKey: @"hideCityNameLabel"];
	weatherConditionsGlyphSize = [pref integerForKey: @"weatherConditionsGlyphSize"];
	conditionsFontSize = [pref integerForKey: @"conditionsFontSize"];
	conditionsFontBold = [pref boolForKey: @"conditionsFontBold"];
	cityNameFontSize = [pref integerForKey: @"cityNameFontSize"];
	cityNameFontBold = [pref boolForKey: @"cityNameFontBold"];
	portraitX = [pref floatForKey: @"portraitX"];
	portraitY = [pref floatForKey: @"portraitY"];
	landscapeX = [pref floatForKey: @"landscapeX"];
	landscapeY = [pref floatForKey: @"landscapeY"];
	followDeviceOrientation = [pref boolForKey: @"followDeviceOrientation"];

	if(weatherInfoObject)
	{
		[weatherInfoObject updateFrame];
		[weatherInfoObject updateText];
	}
}

%ctor
{
	@autoreleasepool
	{
		pref = [[HBPreferences alloc] initWithIdentifier: @"com.johnzaro.weatherinfoprefs"];
		[pref registerDefaults:
		@{
			@"enabled": @NO,
			@"showOnLockScreen": @NO,
			@"hideConditions": @NO,
			@"hideCityNameLabel": @NO,
			@"weatherConditionsGlyphSize": @20,
			@"conditionsFontSize": @10,
			@"conditionsFontBold": @NO,
			@"cityNameFontSize": @8,
			@"cityNameFontBold": @NO,
			@"portraitX": @165,
			@"portraitY": @32,
			@"landscapeX": @735,
			@"landscapeY": @32,
			@"followDeviceOrientation": @NO,
    	}];

		settingsChanged(NULL, NULL, NULL, NULL, NULL);

		if(enabled)
		{
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, settingsChanged, CFSTR("com.johnzaro.weatherinfoprefs/reloadprefs"), NULL, CFNotificationSuspensionBehaviorCoalesce);

			%init;
		}
	}
}