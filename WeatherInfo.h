@interface WeatherInfo: NSObject
{
    UIWindow *weatherInfoWindow;
    UIImageView *glyphImageView;
    UILabel *conditionsLabel;
    UILabel *cityNameLabel;
    BOOL useOriginalGlyph;
    UIColor *backupColor;
}
- (id)init;
- (void)updateLabelsSize;
- (void)updateGlyphSize;
- (void)updateLabelProperties;
- (void)updateOrientation;
- (void)updateFrame;
- (void)updateTextColor: (UIColor*)color;
@end

@interface UIImageAsset ()
@property(nonatomic, assign) NSString *assetName;
@end

@interface UIWindow ()
- (void)_setSecure:(BOOL)arg1;
@end

@interface UIApplication ()
- (UIDeviceOrientation)_frontMostAppOrientation;
@end

@interface _UIStatusBarStyleAttributes: NSObject
@property(nonatomic, copy) UIColor *imageTintColor;
@end

@interface _UIStatusBar: UIView
@property(nonatomic, retain) _UIStatusBarStyleAttributes *styleAttributes;
@end

@interface UIImage ()
@property(nonatomic, assign) CGSize pixelSize;
- (UIImage *)sbf_resizeImageToSize:(CGSize)size;
@end

@interface _UIAssetManager
+ (id)assetManagerForBundle:(NSBundle *)bundle;
- (UIImage *)imageNamed:(NSString *)name;
@end

@interface UIStatusBarItem
@property(nonatomic, assign) NSString *indicatorName;
@property(nonatomic, assign) Class viewClass;
@end

@interface UIStatusBarItemView
@property(nonatomic, assign) UIStatusBarItem *item;
@end

@interface UIStatusBarIndicatorItemView : UIStatusBarItemView
@end
