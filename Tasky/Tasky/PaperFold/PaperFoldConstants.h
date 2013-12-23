//
//  PaperFoldConstants.h
//  PaperFold
//
//  Created by honcheng on 25/8/12.
//  Copyright (c) 2012 honcheng@gmail.com. All rights reserved.
//

#ifndef PaperFold_PaperFoldConstants_h
#define PaperFold_PaperFoldConstants_h

#define FOLDVIEW_TAG 1000
#define kLeftViewUnfoldThreshold 0.3
#define kRightViewUnfoldThreshold 0.3
#define kTopViewUnfoldThreshold 0.3
#define kBottomViewUnfoldThreshold 0.3
#define kEdgeScrollWidth 40.0

typedef enum
{
    FoldStateClosed = 0,
    FoldStateOpened = 1,
    FoldStateTransition = 2
} FoldState;


typedef enum
{
    PaperFoldStateDefault = 0,
    PaperFoldStateLeftUnfolded = 1,
} PaperFoldState;

#endif
