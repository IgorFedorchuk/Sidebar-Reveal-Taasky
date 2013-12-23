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


#import "MultiFoldView.h"
#import "UIView+Screenshot.h"
#import <MapKit/MapKit.h>

@implementation MultiFoldView

#define FOLDVIEW_TAG 1000

- (id)initWithFrame:(CGRect)frame folds:(int)folds pullFactor:(float)factor
{
    if (self = [super initWithFrame:frame])
    {
        _numberOfFolds = folds;
        if (_numberOfFolds==1)
        {
            _pullFactor = 0;
        }
        else _pullFactor = factor;

        // create multiple FoldView next to each other
        for (int i=0; i<_numberOfFolds; i++)
        {
            float foldWidth = frame.size.width/self.numberOfFolds;
            FoldView *foldView = [[FoldView alloc] initWithFrame:CGRectMake(foldWidth*i,0,foldWidth,frame.size.height)];
            [foldView setTag:FOLDVIEW_TAG+i];
            [self addSubview:foldView];
        }
        [self setAutoresizesSubviews:YES];
    }
    return self;
}

- (void)setContent:(UIView *)contentView
{
    if ([contentView isKindOfClass:NSClassFromString(@"MKMapView")])
        _shouldTakeScreenshotBeforeUnfolding = YES;
    
    // set the content view
    self.contentViewHolder = [[UIView alloc] initWithFrame:CGRectMake(0,0,contentView.frame.size.width,contentView.frame.size.height)];
    [self.contentViewHolder setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleWidth];
    // place content view below folds
    [self insertSubview:self.contentViewHolder atIndex:0];
    [self.contentViewHolder addSubview:contentView];
    // immediately take a screenshot of the content view to overlay in fold
    // if content view is a map view, screenshot will be a blank grid
    [self drawScreenshotOnFolds];
    [self.contentViewHolder setHidden:YES];
}

- (void)drawScreenshotOnFolds
{
    UIImage *image = [self.contentViewHolder screenshotWithOptimization:YES];
    [self setScreenshotImage:image];
}

- (void)setScreenshotImage:(UIImage*)image
{
    float foldWidth = image.size.width/self.numberOfFolds;
    
    for (int i=0; i<self.numberOfFolds; i++)
    {
        CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(foldWidth*i*image.scale, 0, foldWidth*image.scale, image.size.height*image.scale));
        if (imageRef)
        {
            UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
            CFRelease(imageRef);
            FoldView *foldView = (FoldView*)[self viewWithTag:FOLDVIEW_TAG + (self.numberOfFolds - 1) - i];
            [foldView setImage:croppedImage];
        }
        
    }
}

// set fold states based on offset value
- (void)calculateFoldStateFromOffset:(float)offset
{
    CGFloat fraction = 0.0;
    if (offset < 0)
        fraction = -1*offset/self.frame.size.width;
    else
        fraction = offset/self.frame.size.width;

    if (_state==FoldStateClosed && fraction>0)
    {
        _state = FoldStateTransition;
        [self foldWillOpen];
    }
    else if (_state==FoldStateOpened && fraction<1)
    {
        _state = FoldStateTransition;
        [self foldWillClose];
    }
    else if (_state==FoldStateTransition)
    {
        if (fraction==0)
        {
            _state = FoldStateClosed;
            [self foldDidClosed];
        }
        else if (fraction>=1)
        {
            _state = FoldStateOpened;
            [self foldDidOpened];
        }
    }
}

// use the parent offset to calculate fraction
- (void)unfoldWithParentOffset:(float)offset
{
    [self calculateFoldStateFromOffset:offset];
    
    float foldWidth = self.frame.size.width/self.numberOfFolds;
    CGFloat fraction;
    
    if (offset > (foldWidth+self.pullFactor*foldWidth))
    {
        offset = (foldWidth+self.pullFactor*foldWidth);
    }
    fraction = offset /(foldWidth+self.pullFactor*foldWidth);
    
    if (fraction < 0) fraction  = -1*fraction;//0;
    if (fraction > 1) fraction = 1;
    [self unfoldViewToFraction:fraction];
}

- (void)unfoldViewToFraction:(CGFloat)fraction
{
    // start the cascading effect of unfolding
    // with the first foldView with index FOLDVIEW_TAG+0
    FoldView *firstFoldView = (FoldView*)[self viewWithTag:FOLDVIEW_TAG];
    
    float offset = 0.0;
    if ([self.delegate respondsToSelector:@selector(displacementOfMultiFoldView:)])
    {
        offset = [self.delegate displacementOfMultiFoldView:self];
    }
    else
    {
        offset = self.superview.frame.origin.x;
    }
    if (offset<0) offset = -1*offset;
    [self unfoldView:firstFoldView toFraction:fraction withOffset:offset];
}

- (void)unfoldView:(FoldView*)foldView toFraction:(CGFloat)fraction withOffset:(float)offset
{
    [foldView unfoldViewToFraction:fraction offset:offset];
    
    [foldView setFrame:CGRectMake(offset - 2*foldView.rightView.frame.size.width, 0, foldView.frame.size.width, foldView.frame.size.height)];
    
    // check if there is another subfold beside this fold
    int index = [foldView tag] - FOLDVIEW_TAG;
    if (index < self.numberOfFolds-1)
    {
        FoldView *nextFoldView = (FoldView*)[self viewWithTag:FOLDVIEW_TAG+index+1];
        // set the origin of the next foldView
        // set the origin of the next foldView
        [nextFoldView setFrame:CGRectMake(foldView.frame.origin.x - 2*nextFoldView.rightView.frame.size.width,0,nextFoldView.frame.size.width,nextFoldView.frame.size.height)];
        
        float foldWidth = self.frame.size.width/self.numberOfFolds;
        // calculate the offset between the right edge of the last subfold, and the edge of the screen
        // use this offset to readjust the fraction
        float displacement = 0.0;
        if ([self.delegate respondsToSelector:@selector(displacementOfMultiFoldView:)])
        {
            displacement = [self.delegate displacementOfMultiFoldView:self];
        }
        else
        {
            displacement = self.superview.frame.origin.x;
        }
        
        float x;
            x =  (foldView.frame.origin.x + (fraction * foldView.frame.size.width)) - 2*foldView.rightView.frame.size.width;
        
        CGFloat adjustedFraction = 0;
        x = -x;
        if (index+1==self.numberOfFolds-1)
        {
            // if this is the last fold, do not use the pull factor
            // so that the right edge of this subfold aligns with the right edge of the screen
            adjustedFraction = (-1*x)/(foldWidth);
        }
        else
        {
            // if this is not the last fold, use the pull factor
            adjustedFraction = (-1*x)/(foldWidth+self.pullFactor*foldWidth);
        }
        if (adjustedFraction < 0) adjustedFraction = 0;
        if (adjustedFraction > 1) adjustedFraction = 1;
      
        [self unfoldView:nextFoldView toFraction:adjustedFraction withOffset:foldView.frame.origin.x];
    }
}

// hide fold (when content view is visible) and show fold (when content view is hidden
- (void)showFolds:(BOOL)show
{
    for (int i=0; i<self.numberOfFolds; i++)
    {
        FoldView *foldView = (FoldView*)[self viewWithTag:FOLDVIEW_TAG+i];
        [foldView setHidden:!show];
    }
}

- (void)unfoldWithoutAnimation
{
    [self unfoldWithParentOffset:self.frame.size.width];
    [self foldDidOpened];
}

#pragma mark states

// when fold is completely opened, hide fold and show content view
- (void)foldDidOpened
{
    [self.contentViewHolder setHidden:NO];
    [self showFolds:NO];
}

// when fold is completely closed, hide content view and folds
- (void)foldDidClosed
{
    [self.contentViewHolder setHidden:YES];
    [self showFolds:YES];
}

// when fold is about to be opened, make sure content view is hidden, and show fold
- (void)foldWillOpen
{
    if (self.shouldTakeScreenshotBeforeUnfolding)
    {
        [self.contentViewHolder setHidden:NO];
        [self drawScreenshotOnFolds];
    }
    [self.contentViewHolder setHidden:YES];
    [self showFolds:YES];
}

// when fold is about to be closed, take a screenshot of the content view, hide it, and make sure fold is visible.
- (void)foldWillClose
{
    [self drawScreenshotOnFolds];
    [self.contentViewHolder setHidden:YES];
    [self showFolds:YES];
}

@end
