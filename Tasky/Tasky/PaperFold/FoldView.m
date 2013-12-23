/**
 * Copyright (c) 2012 Muh Hon Cheng
 * Created by honcheng on 6/2/12.
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject
 * to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
 * WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT
 * SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 * IN CONNECTION WITH THE SOFTWARE OR
 * THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * @author 		Muh Hon Cheng <honcheng@gmail.com>
 * @copyright	2012	Muh Hon Cheng
 * @version
 *
 */


#import "FoldView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+Screenshot.h"
#import "ShadowView.h"
#import "PaperFoldConstants.h"

@interface FoldView ()

@property (nonatomic, strong) UIView *contentView;

@end

@implementation FoldView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        // content view holds a subview which is the actual displayed content
        // contentView is required as a wrapper of the original content because it is better to take a screenshot of the wrapper view layer
        // taking a screenshot of a tableview layer directly for example, may end up with blank view because of recycled cells
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0,0,frame.size.width,frame.size.height)];
        [_contentView setBackgroundColor:[UIColor clearColor]];
        [self addSubview:_contentView];
                
        _rightView = [[FacingView alloc] initWithFrame:CGRectMake(-1*frame.size.width/2,0,frame.size.width, frame.size.height)];
        [_rightView setBackgroundColor:[UIColor colorWithWhite:0.99 alpha:1]];
        [_rightView.layer setAnchorPoint:CGPointMake(1.0, 0.5)];
        [self addSubview:_rightView];
        [_rightView.shadowView setColorArrays:[NSArray arrayWithObjects:[UIColor colorWithWhite:0 alpha:0.9],[UIColor colorWithWhite:0 alpha:0.55], nil]];
        
        // set perspective of the transformation
        CATransform3D transform = CATransform3DIdentity;
        transform.m34 = -1/500.0;
        [self.layer setSublayerTransform:transform];
        
        // make sure the views are closed properly when initialized
        [_rightView.layer setTransform:CATransform3DMakeRotation((M_PI / 2), 0, 1, 0)];
        
        [self setAutoresizesSubviews:YES];
        [_contentView setAutoresizesSubviews:YES];
        [_contentView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    }
    return self;
}

- (void)unfoldViewToFraction:(CGFloat)fraction offset:(float)offset
{
    float delta = asinf(fraction);

    // rotate rightView on the right edge of the view
    // translate rotated view to the left to join to the edge of the leftView
    CATransform3D transform1 = CATransform3DMakeTranslation(2*offset, 0, 0);
    CATransform3D transform2 = CATransform3DMakeRotation((M_PI / 2) - delta, 0, -1, 0);
    CATransform3D transform = CATransform3DConcat(transform2, transform1);
    [self.rightView.layer setTransform:transform];

    [self.rightView.shadowView setAlpha:1-fraction];
}

- (void)setImage:(UIImage*)image
{
    CGImageRef imageRef2 = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, 0, image.size.width*image.scale, image.size.height*image.scale));
    [self.rightView.layer setContents:(__bridge id)imageRef2];
    CFRelease(imageRef2);
}


@end
