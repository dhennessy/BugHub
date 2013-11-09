
/*
 Pulled from SSToolkit
 http://github.com/samsoffes/sstoolkit/
 */
extern CGGradientRef SSCreateGradientWithColorsAndLocations(NSArray *colors, NSArray *locations);
extern void SSDrawGradientInRect(CGContextRef context, CGGradientRef gradient, CGRect rect);
extern void SSDrawRoundedRect(CGContextRef context, CGRect rect, CGFloat cornerRadius);
