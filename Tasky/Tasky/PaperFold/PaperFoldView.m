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


#import "PaperFoldView.h"
#import <QuartzCore/QuartzCore.h>


@interface PaperFoldView ()

@property (nonatomic, copy) CompletionBlock completionBlock;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

// indicate if the divider line should be visible
@property (nonatomic, assign) BOOL showDividerLines;

- (void)onContentViewPannedHorizontally:(UIPanGestureRecognizer*)gesture;
@end

@implementation PaperFoldView

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		[self initialize];
	}
	return self;
}

- (void)awakeFromNib
{
	[self initialize];
}

- (void)initialize
{
    _useOptimizedScreenshot = YES;
    
    [self setBackgroundColor:[UIColor darkGrayColor]];
    [self setAutoresizesSubviews:YES];
    [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    
    _contentView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.frame.size.width,self.frame.size.height)];
    [_contentView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self addSubview:_contentView];
    [_contentView setBackgroundColor:[UIColor whiteColor]];
    [_contentView setAutoresizesSubviews:YES];
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onContentViewPanned:)];
	panGestureRecognizer.delegate = self;
    [_contentView addGestureRecognizer:panGestureRecognizer];
    [panGestureRecognizer setDelegate:self];
    
    _state = PaperFoldStateDefault;
    _lastState = _state;
    _enableRightFoldDragging = NO;
    _enableLeftFoldDragging = NO;
    _enableBottomFoldDragging = NO;
    _enableTopFoldDragging = NO;
	_restrictedDraggingRect = CGRectNull;
	_showDividerLines = NO;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    CGRect leftFoldViewFrame = self.leftFoldView.frame;
    leftFoldViewFrame.size.height = frame.size.height;
    [self.leftFoldView setFrame:leftFoldViewFrame];
    
    CGRect rightFoldViewFrame = self.rightFoldView.frame;
    rightFoldViewFrame.size.height = frame.size.height;
    [self.rightFoldView setFrame:rightFoldViewFrame];
}

- (void)setCenterContentView:(UIView*)view
{
	[view setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
	[self.contentView addSubview:view];
}

- (void)setLeftFoldContentView:(UIView*)view foldCount:(int)leftViewFoldCount pullFactor:(float)leftViewPullFactor
{
    if (self.leftFoldView) [self.leftFoldView removeFromSuperview];
    self.leftFoldView = [[MultiFoldView alloc] initWithFrame:CGRectMake(0,0,view.frame.size.width,self.frame.size.height) foldDirection:FoldDirectionHorizontalLeftToRight folds:leftViewFoldCount pullFactor:leftViewPullFactor];
    [self.leftFoldView setDelegate:self];
    [self.leftFoldView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [self insertSubview:self.leftFoldView belowSubview:self.contentView];
    [self.leftFoldView setContent:view];
    [self.leftFoldView setHidden:YES];
    //[self.leftFoldView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleHeight];
    //[view setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [view setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(-1,0,1,self.frame.size.height)];
    [line setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [self.contentView addSubview:line];
    [line setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:0.5]];
	line.alpha = 0;
	self.leftDividerLine = line;
    
    self.enableLeftFoldDragging = YES;
}

- (void)onContentViewPanned:(UIPanGestureRecognizer*)gesture
{
    // cancel gesture if another animation has not finished yet
    if ([self.animationTimer isValid]) return;

    if ([gesture state]==UIGestureRecognizerStateBegan)
    {
		// show the divider while dragging
		[self setShowDividerLines:YES animated:YES];

		CGPoint velocity = [gesture velocityInView:self];
        if ( abs(velocity.x) > abs(velocity.y))
        {
            if (self.state==PaperFoldStateDefault)
            {
                if (self.enableHorizontalEdgeDragging)
                {
                    CGPoint location = [gesture locationInView:self.contentView];
                    if (location.x < kEdgeScrollWidth || location.x > (self.contentView.frame.size.width-kEdgeScrollWidth))
                    {
                        self.paperFoldInitialPanDirection = PaperFoldInitialPanDirectionHorizontal;
                    }
                }
                else self.paperFoldInitialPanDirection = PaperFoldInitialPanDirectionHorizontal;
            }
        }
    }
    else
    {
        if (self.paperFoldInitialPanDirection==PaperFoldInitialPanDirectionHorizontal)
        {
            [self onContentViewPannedHorizontally:gesture];
        }
        
		if (gesture.state != UIGestureRecognizerStateChanged)
        {
			// hide the divider line
			[self setShowDividerLines:NO animated:YES];
		}
    }
}

- (void)onContentViewPannedHorizontally:(UIPanGestureRecognizer*)gesture
{
    [self.rightFoldView setHidden:NO];
    [self.leftFoldView setHidden:NO];

    CGPoint point = [gesture translationInView:self];
    if ([gesture state]==UIGestureRecognizerStateChanged)
    {
        if (_state==PaperFoldStateDefault)
        {
            // animate folding when panned
            [self animateWithContentOffset:point panned:YES];
        }
        else if (_state==PaperFoldStateLeftUnfolded)
        {
            CGPoint adjustedPoint = CGPointMake(point.x + self.leftFoldView.frame.size.width, point.y);
            [self animateWithContentOffset:adjustedPoint panned:YES];
        }
        else if (_state==PaperFoldStateRightUnfolded)
        {
            CGPoint adjustedPoint = CGPointMake(point.x - self.rightFoldView.frame.size.width, point.y);
            [self animateWithContentOffset:adjustedPoint panned:YES];
        }
    }
    else if ([gesture state]==UIGestureRecognizerStateEnded || [gesture state]==UIGestureRecognizerStateCancelled)
    {
        float x = point.x;
        if (x>=0.0) // offset to the right
        {
            if ( (x>=kLeftViewUnfoldThreshold*self.leftFoldView.frame.size.width && _state==PaperFoldStateDefault) || [self.contentView frame].origin.x==self.leftFoldView.frame.size.width)
            {
                if (self.enableLeftFoldDragging)
                {
                    // if offset more than threshold, open fully
                    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(unfoldLeftView:) userInfo:nil repeats:YES];
                    return;
                }
            }
        }
        else if (x<0)
        {
            if ((x<=-kRightViewUnfoldThreshold*self.rightFoldView.frame.size.width && _state==PaperFoldStateDefault) || [self.contentView frame].origin.x==-self.rightFoldView.frame.size.width)
            {
                if (self.enableRightFoldDragging)
                {
                    // if offset more than threshold, open fully
                    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(unfoldRightView:) userInfo:nil repeats:YES];
                    return;
                }
            }
        }
        
        // after panning completes
        // if offset does not exceed threshold
        // use NSTimer to create manual animation to restore view
        self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(restoreView:) userInfo:nil repeats:YES];
        
        //self.paperFoldInitialPanDirection = PaperFoldInitialPanDirectionNone;
    }
}

- (void)animateWithContentOffset:(CGPoint)point panned:(BOOL)panned
{
    if (self.paperFoldInitialPanDirection==PaperFoldInitialPanDirectionHorizontal)
    {
        float x = point.x;
        // if offset to the right, show the left view
        // if offset to the left, show the right multi-fold view
        
        if (self.state!=self.lastState) self.lastState = self.state;
        
        if (x>0.0)
        {
            if (self.enableLeftFoldDragging || !panned)
            {
                // set the limit of the right offset
                if (x>=self.leftFoldView.frame.size.width)
                {
                    if (self.lastState != PaperFoldStateLeftUnfolded) {
						[self finishForState:PaperFoldStateLeftUnfolded];
					}
                    self.lastState = self.state;
                    self.state = PaperFoldStateLeftUnfolded;
                    x = self.leftFoldView.frame.size.width;
                }
                [self.contentView setTransform:CGAffineTransformMakeTranslation(x, 0)];
                //[self.leftFoldView unfoldWithParentOffset:-1*x];
                [self.leftFoldView unfoldWithParentOffset:x];
                
                if ([self.delegate respondsToSelector:@selector(paperFoldView:viewDidOffset:)])
                {
                    [self.delegate paperFoldView:self viewDidOffset:CGPointMake(x,0)];
                }
            }
        }
        else if (x<0.0)
        {
            if (self.enableRightFoldDragging || !panned)
            {
                // set the limit of the left offset
                // original x value not changed, to be sent to multi-fold view
                float x1 = x;
                if (x1<=-self.rightFoldView.frame.size.width)
                {
					if (self.lastState != PaperFoldStateRightUnfolded) {
						[self finishForState:PaperFoldStateRightUnfolded];
					}
                    self.lastState = self.state;
                    self.state = PaperFoldStateRightUnfolded;
                    x1 = -self.rightFoldView.frame.size.width;
                }
                [self.contentView setTransform:CGAffineTransformMakeTranslation(x1, 0)];
                [self.rightFoldView unfoldWithParentOffset:x];
                
                if ([self.delegate respondsToSelector:@selector(paperFoldView:viewDidOffset:)])
                {
                    [self.delegate paperFoldView:self viewDidOffset:CGPointMake(x,0)];
                }
            }
        }
        else
        {
            [self.contentView setTransform:CGAffineTransformMakeTranslation(0, 0)];
            [self.leftFoldView unfoldWithParentOffset:-1*x];
            [self.rightFoldView unfoldWithParentOffset:x];
            self.state = PaperFoldStateDefault;
            
            if ([self.delegate respondsToSelector:@selector(paperFoldView:viewDidOffset:)])
            {
                [self.delegate paperFoldView:self viewDidOffset:CGPointMake(x,0)];
            }
        }
    }
}

// unfold the left view
- (void)unfoldLeftView:(NSTimer*)timer
{
    [self.leftFoldView setHidden:NO];
    [self.rightFoldView setHidden:NO];
    
    CGAffineTransform transform = [self.contentView transform];
    float x = transform.tx + (self.leftFoldView.frame.size.width-transform.tx)/4;
    transform = CGAffineTransformMakeTranslation(x, 0);
    [self.contentView setTransform:transform];
    if (x>=self.leftFoldView.frame.size.width-2)
    {
        [timer invalidate];
        transform = CGAffineTransformMakeTranslation(self.leftFoldView.frame.size.width, 0);
        [self.contentView setTransform:transform];
        
        //        if (self.lastState!=PaperFoldStateLeftUnfolded && [self.delegate respondsToSelector:@selector(paperFoldView:didFoldAutomatically:toState:)])
        //        {
        //            [self.delegate paperFoldView:self didFoldAutomatically:self.isAutomatedFolding toState:PaperFoldStateLeftUnfolded];
        //        }
        //        [self setIsAutomatedFolding:NO];
    }
    
    // use the x value to animate folding
    [self animateWithContentOffset:CGPointMake(self.contentView.frame.origin.x, 0) panned:NO];
}

// unfold the right view
- (void)unfoldRightView:(NSTimer*)timer
{
    [self.leftFoldView setHidden:NO];
    [self.rightFoldView setHidden:NO];
    
    CGAffineTransform transform = [self.contentView transform];
    float x = transform.tx - (transform.tx+self.rightFoldView.frame.size.width)/8;
    transform = CGAffineTransformMakeTranslation(x, 0);
    [self.contentView setTransform:transform];

    if (x<=-self.rightFoldView.frame.size.width+5)
    {
        [timer invalidate];
        transform = CGAffineTransformMakeTranslation(-self.rightFoldView.frame.size.width, 0);
        [self.contentView setTransform:transform];
    }
    
    // use the x value to animate folding
    [self animateWithContentOffset:CGPointMake(self.contentView.frame.origin.x, 0) panned:NO];
}

// restore contentView back to original position
- (void)restoreView:(NSTimer*)timer
{
    if (self.paperFoldInitialPanDirection==PaperFoldInitialPanDirectionHorizontal)
    {
        CGAffineTransform transform = [self.contentView transform];
        // restoring the x position 3/4 of the last x translation
        float x = transform.tx/4*3;
        transform = CGAffineTransformMakeTranslation(x, 0);
        [self.contentView setTransform:transform];
        
        // if -5<x<5, stop timer animation
        if ((x>=0 && x<5) || (x<=0 && x>-5))
        {
            [timer invalidate];
            transform = CGAffineTransformMakeTranslation(0, 0);
            [self.contentView setTransform:transform];
            [self animateWithContentOffset:CGPointMake(0, 0) panned:NO];
            
			if (self.lastState != PaperFoldStateDefault) {
				[self finishForState:PaperFoldStateDefault];
			}
			self.state = PaperFoldStateDefault;
        }
        else
        {
            // use the x value to animate folding
            [self animateWithContentOffset:CGPointMake(self.contentView.frame.origin.x, 0) panned:NO];
        }
    }
}

- (void)setPaperFoldState:(PaperFoldState)state animated:(BOOL)animated
{
    if (animated)
    {
        [self setPaperFoldState:state];
    }
    else
    {
        [self.leftFoldView setHidden:YES];
        [self.rightFoldView setHidden:YES];
        
        if (state==PaperFoldStateDefault)
        {
            CGAffineTransform transform = transform = CGAffineTransformMakeTranslation(0, 0);
            [self.contentView setTransform:transform];
            
			if (self.lastState != PaperFoldStateDefault) {
				[self finishForState:PaperFoldStateDefault];
			}
        }
        else if (state==PaperFoldStateLeftUnfolded)
        {
            [self.leftFoldView setHidden:NO];
            
            CGAffineTransform transform = CGAffineTransformMakeTranslation(self.leftFoldView.frame.size.width, 0);
            [self.contentView setTransform:transform];
            [self.leftFoldView unfoldWithoutAnimation];
            
			if (self.lastState != PaperFoldStateLeftUnfolded) {
				[self finishForState:PaperFoldStateLeftUnfolded];
			}
        }
        else if (state==PaperFoldStateRightUnfolded)
        {
            [self.rightFoldView setHidden:NO];
            
            CGAffineTransform transform = CGAffineTransformMakeTranslation(-self.rightFoldView.frame.size.width, 0);
            [self.contentView setTransform:transform];
            [self.rightFoldView unfoldWithoutAnimation];
            
			if (self.lastState != PaperFoldStateRightUnfolded) {
				[self finishForState:PaperFoldStateRightUnfolded];
			}
        }
        self.state = state;
    }
}

- (void)setPaperFoldState:(PaperFoldState)state
{
    [self setIsAutomatedFolding:YES];
    if (state==PaperFoldStateDefault)
    {
        self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(restoreView:) userInfo:nil repeats:YES];
    }
    else if (state==PaperFoldStateLeftUnfolded)
    {
        self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(unfoldLeftView:) userInfo:nil repeats:YES];
    }
    else if (state==PaperFoldStateRightUnfolded)
    {
        self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(unfoldRightView:) userInfo:nil repeats:YES];
    }
}

- (void)setPaperFoldState:(PaperFoldState)state
								 animated:(BOOL)animated
							 completion:(void (^)())completion
{
	self.completionBlock = completion;
	[self setPaperFoldState:state animated:animated];
}


- (void)unfoldLeftView
{
	[self setPaperFoldState:PaperFoldStateLeftUnfolded];
}

- (void)unfoldRightView
{
	[self setPaperFoldState:PaperFoldStateRightUnfolded];
}

- (void)finishForState:(PaperFoldState)state
{
    [self setShowDividerLines:NO animated:YES];
	
    // we prefer executing the completion block, otherwise we notify the delegate
    if (self.completionBlock != nil) {
        self.completionBlock();
        self.completionBlock = nil;
		
    } else if ([self.delegate respondsToSelector:@selector(paperFoldView:didFoldAutomatically:toState:)]) {
        [self.delegate paperFoldView:self
				didFoldAutomatically:self.isAutomatedFolding
							 toState:state];
    }
	
    // no more animations
    [self setIsAutomatedFolding:NO];
}

- (void)setShowDividerLines:(BOOL)showDividerLines animated:(BOOL)animated
{
    if (_showDividerLines == showDividerLines)
        return;

    _showDividerLines = showDividerLines;
	CGFloat alpha = showDividerLines ? 1 : 0;
    [UIView animateWithDuration:animated ? 0.25 : 0
                                     animations:
     ^{
         self.leftDividerLine.alpha = alpha;
         self.topDividerLine.alpha = alpha;
         self.rightDividerLine.alpha = alpha;
         self.bottomDividerLine.alpha = alpha;
     }];
}

#pragma mark - MultiFoldView delegate

- (CGFloat)displacementOfMultiFoldView:(id)multiFoldView
{
    if (multiFoldView==self.rightFoldView)
    {
        return [self.contentView frame].origin.x;
    }
    else if (multiFoldView==self.leftFoldView)
    {
        return -1*[self.contentView frame].origin.x;
    }
    
    return 0.0;
}

#pragma mark - Gesture recogniser delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (self.enableHorizontalEdgeDragging)
    {
        CGPoint location = [gestureRecognizer locationInView:self.contentView];
        if (location.x < kEdgeScrollWidth || location.x > (self.contentView.frame.size.width-kEdgeScrollWidth))
        {
            
            return NO;
        }
        else return YES;
    }
    else return NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	// only allow panning if we didn't restrict it to start at a certain rect
	if (NO == CGRectIsNull(self.restrictedDraggingRect)
		&& NO == CGRectContainsPoint(self.restrictedDraggingRect, [gestureRecognizer locationInView:self])) {
		return NO;
	} else {
		return YES;
	}
}

@end
