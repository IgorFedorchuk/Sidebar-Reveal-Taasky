/**
 * Copyright (c) 2012 Muh Hon Cheng
 * Created by honcheng on 26/10/12.
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

#import "PaperFoldMenuController.h"

@interface PaperFoldMenuController ()

@property (nonatomic, assign) float menuWidth;
@property (nonatomic, strong) NSMutableArray *viewDidLoadBlocks;

@end

@implementation PaperFoldMenuController

- (NSMutableArray *)viewDidLoadBlocks
{
    if (_viewDidLoadBlocks == nil)
    {
        self.viewDidLoadBlocks = [[NSMutableArray alloc] init];
    }
    return _viewDidLoadBlocks;
}

- (UIViewController *)selectedViewController
{
    if (self.selectedIndex == NSNotFound)
    {
        return nil;
    }
    else
    {
        return self.viewControllers[self.selectedIndex];
    }
}

- (void)setSelectedViewController:(UIViewController *)theSelectedViewController
{
    NSUInteger theSelectedIndex = [self.viewControllers indexOfObject:theSelectedViewController];
    
    if (theSelectedIndex == NSNotFound)
    {
        [NSException raise:NSInternalInconsistencyException format:@"Could not selected view controller because it is not registered.\n%@", theSelectedViewController];
        return;
    }
    
    self.selectedIndex = theSelectedIndex;
}

- (void)setSelectedIndex:(NSUInteger)theSelectedIndex
{
    if (!self.isViewLoaded)
    {
        __weak __typeof(*&self) theWeakSelf = self;
        [self.viewDidLoadBlocks addObject:[^{
            __strong __typeof(*&self) theStrongSelf = theWeakSelf;
            if (theStrongSelf == nil) {
                return;
            }
            theStrongSelf.selectedIndex = theSelectedIndex;
        } copy]];
    }
    else
    {
        NSUInteger theOldSelectedIndex = self.selectedIndex;
        NSUInteger theNewSelectedIndex = theSelectedIndex;
        
        if (theOldSelectedIndex == theNewSelectedIndex) {
            return;
        }
        
        [self willChangeValueForKey:@"selectedIndex"];
        
        if (theOldSelectedIndex != NSNotFound)
        {
            UIViewController *theOldViewController = self.viewControllers[theOldSelectedIndex];
            [theOldViewController willMoveToParentViewController:nil];
            [theOldViewController.view removeFromSuperview];
            [theOldViewController removeFromParentViewController];
            
            [self.menuTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:theOldSelectedIndex inSection:0] animated:YES];
        }
        
        _selectedIndex = theNewSelectedIndex;
        
        if (theNewSelectedIndex != NSNotFound)
        {
            UIViewController *theNewViewController = self.viewControllers[theNewSelectedIndex];
            theNewViewController.view.frame = self.contentView.bounds;
            [self addChildViewController:theNewViewController];
            [self.contentView addSubview:theNewViewController.view];
            [theNewViewController didMoveToParentViewController:self];
            
            [self.menuTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:theNewSelectedIndex inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
        
        [self didChangeValueForKey:@"selectedIndex"];
        
        if (self.paperFoldView.state != PaperFoldStateLeftUnfolded)
        {
            [self reloadMenu];
        }
    }
}

- (void)commonInit
{
    _selectedIndex = NSNotFound;
}

- (id)initWithMenuWidth:(float)menuWidth
{
    if (self = [self initWithNibName:nil bundle:nil])
    {
        self.menuWidth = menuWidth;
    }
    return self;
}

- (id)initWithNibName:(NSString *)theNibNameOrNil bundle:(NSBundle *)theNibBundleOrNil
{
    if (self = [super initWithNibName:theNibNameOrNil bundle:theNibBundleOrNil])
    {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self commonInit];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    PaperFoldView *paperFoldView = [[PaperFoldView alloc] initWithFrame:CGRectMake(0, 0, [self.view bounds].size.width, [self.view bounds].size.height)];
    [paperFoldView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [paperFoldView setDelegate:self];
    [paperFoldView setUseOptimizedScreenshot:NO];
    [self.view addSubview:paperFoldView];
    self.paperFoldView = paperFoldView;
    
    UIView *contentView = [[UIView alloc] initWithFrame:_paperFoldView.frame];
    [contentView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [self.paperFoldView setCenterContentView:contentView];
    self.contentView = contentView;
    
    UITableView *menuTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.menuWidth, [self.view bounds].size.height)];
    [self.paperFoldView setLeftFoldContentView:menuTableView foldCount:1 pullFactor:0.9];
    [menuTableView setDelegate:self];
    [menuTableView setDataSource:self];
    menuTableView.scrollsToTop = !(self.paperFoldView.state == PaperFoldStateDefault);
    self.menuTableView = menuTableView;
    
    ShadowView *menuTableViewSideShadowView = [[ShadowView alloc] initWithFrame:CGRectMake(_menuTableView.frame.size.width-2,0,2,[self.view bounds].size.height)];
    [menuTableViewSideShadowView setColorArrays:@[[UIColor clearColor],[UIColor colorWithWhite:0 alpha:0.2]]];
    /**
     * added to the leftFoldView instead of leftFoldView.contentView bec
     * so that the shadow does not appear while folding
     */
    [self.paperFoldView.leftFoldView addSubview:menuTableViewSideShadowView];
    self.menuTableViewSideShadowView = menuTableViewSideShadowView;
    
    for (void (^theBlock)(void) in self.viewDidLoadBlocks)
    {
        theBlock();
    }
    self.viewDidLoadBlocks = nil;
}

- (void)setViewControllers:(NSMutableArray *)viewControllers
{
    self.selectedIndex = NSNotFound; // Forces any child view controller to be removed.
    _viewControllers = viewControllers;
    if ([_viewControllers count]>0) [self setSelectedIndex:0];
    [self reloadMenu];
}

- (void)addViewController:(UIViewController*)viewController;
{
    if (!_viewControllers) _viewControllers = [NSMutableArray array];
    [self.viewControllers addObject:viewController];
    [self reloadMenu];
}

- (void)reloadMenu
{
    [self.menuTableView reloadData];
    [self.paperFoldView.leftFoldView.contentViewHolder setHidden:NO];
    [self.paperFoldView.leftFoldView drawScreenshotOnFolds];
    [self.paperFoldView.leftFoldView.contentViewHolder setHidden:YES];
}

#pragma mark table view delegates and datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView==self.menuTableView) return [self.viewControllers count];
    else return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView==self.menuTableView)
    {
        static NSString *identifier = @"identifier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        }
        
        UIViewController *viewController = self.viewControllers[indexPath.row];
        [cell.textLabel setText:viewController.title];
        
        if (indexPath.row==self.selectedIndex)
        {
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        
        return cell;
    }
    else return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView==self.menuTableView)
    {
        CGRect startFrame = self.paperFoldView.contentView.frame;
        CGRect endFrame = startFrame;
        CGFloat animateDuration = 0.2;
        startFrame.origin.x = [[UIScreen mainScreen] bounds].size.width;
        [UIView animateWithDuration:animateDuration animations:^
        {
             self.paperFoldView.contentView.frame = startFrame;
        } completion:^(BOOL finished)
        {
             self.paperFoldView.contentView.frame = startFrame;
             [self setSelectedIndex:indexPath.row];
            
             [UIView animateWithDuration:animateDuration animations:^
             {
                 self.paperFoldView.contentView.frame = endFrame;
             } completion:^(BOOL finished)
             {
                 self.paperFoldView.contentView.frame = endFrame;
                 [self showMenu:NO animated:YES];
             }];
        }];
    }
}

- (void)showMenu:(BOOL)show animated:(BOOL)animated
{
    if (show)
    {
        [self.paperFoldView setPaperFoldState:PaperFoldStateLeftUnfolded animated:animated];
    }
    else
    {
        [self.paperFoldView setPaperFoldState:PaperFoldStateDefault animated:animated];
    }
}

- (void)setOnlyAllowEdgeDrag:(BOOL)onlyAllowEdgeDrag
{
    [self.paperFoldView setEnableHorizontalEdgeDragging:onlyAllowEdgeDrag];
}

#pragma mark - PaperFoldViewDelegate methods

- (void)paperFoldView:(id)thePaperFoldView didFoldAutomatically:(BOOL)theAutomated toState:(PaperFoldState)thePaperFoldState {
    BOOL thePaperFoldViewDidFold = (thePaperFoldState == PaperFoldStateDefault);
    self.menuTableView.scrollsToTop = !thePaperFoldViewDidFold;
}

@end
