//
//  SSCollectionViewExchangeController.h
//
// Created by Murray Sagal on 1/9/2014.
// Copyright (c) 2014 Signature Software and Murray Sagal
// SSCollectionViewExchangeController: https://github.com/murraysagal/SSCollectionViewExchangeController
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//



#import <UIKit/UIKit.h>

typedef void (^PostReleaseCompletionBlock) (NSTimeInterval animationDuration);

@class SSCollectionViewExchangeController;

@protocol SSCollectionViewExchangeControllerDelegate <NSObject>

@required

- (void)    exchangeController:(SSCollectionViewExchangeController *)exchangeController
   didExchangeItemAtIndexPath1:(NSIndexPath *)indexPath1
          withItemAtIndexPath2:(NSIndexPath *)indexPath2;


- (void)exchangeControllerDidFinishExchangeEvent:(SSCollectionViewExchangeController *)exchangeController;


- (void)exchangeControllerDidFinishExchangeTransaction:(SSCollectionViewExchangeController *)exchangeController
                                        withIndexPath1:(NSIndexPath *)indexPath1
                                            indexPath2:(NSIndexPath *)indexPath2;


- (void)exchangeControllerDidCancelExchangeTransaction:(SSCollectionViewExchangeController *)exchangeController;


@optional

- (BOOL)exchangeControllerCanBeginExchangeTransaction:(SSCollectionViewExchangeController *)exchangeController
                                  withItemAtIndexPath:(NSIndexPath *)indexPath;


- (BOOL)          exchangeController:(SSCollectionViewExchangeController *)exchangeController
          canDisplaceItemAtIndexPath:(NSIndexPath *)indexPathOfItemToDisplace
   withItemBeingDraggedFromIndexPath:(NSIndexPath *)indexPathOfItemBeingDragged;


- (UIView *)           exchangeController:(SSCollectionViewExchangeController *)exchangeController
  viewForCatchRectangleForItemAtIndexPath:(NSIndexPath *)indexPath;


- (UIView *)exchangeController:(SSCollectionViewExchangeController *)exchangeController
               snapshotForCell:(UICollectionViewCell *)cell;



- (void)animateCatchForExchangeController:(SSCollectionViewExchangeController *)exchangeController
                             withSnapshot:(UIView *)snapshot;

- (void)animateReleaseForExchangeController:(SSCollectionViewExchangeController *)exchangeController
                               withSnapshot:(UIView *)snapshot
                                    toPoint:(CGPoint)centerOfCell
            originalIndexPathForDraggedItem:(NSIndexPath *)originalIndexPathForDraggedItem
                            completionBlock:(PostReleaseCompletionBlock)completionBlock;

@end


@interface SSCollectionViewExchangeController : NSObject

- (instancetype)initWithDelegate:(id<SSCollectionViewExchangeControllerDelegate>)delegate
                  collectionView:(UICollectionView *)collectionView;

- (UICollectionViewFlowLayout *)layout;


@property (weak, nonatomic, readonly)   UILongPressGestureRecognizer    *longPressGestureRecognizer;

@property (nonatomic)                   CGFloat                         alphaForDisplacedItem;

@property (nonatomic)                   NSTimeInterval                  animationDuration;
@property (nonatomic)                   CGFloat                         blinkToScaleForCatch;
@property (nonatomic)                   CGFloat                         blinkToScaleForRelease;
@property (nonatomic)                   CGFloat                         snapshotAlpha;
@property (strong, nonatomic)           UIColor                         *snapshotBackgroundColor;

@property (nonatomic, assign, readonly) BOOL                            exchangeTransactionInProgress;

@property (nonatomic)                   double                          animationBacklogDelay;

@end
