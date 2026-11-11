//
//  DOLyricsLogView.h
//  Dopamine
//
//  Created by tomt000 on 13/01/2024.
//

#import <UIKit/UIKit.h>
#import "DOLogViewProtocol.h"
#import "DOLoadingIndicator.h"
#import "DOLyricsLogItemView.h"

NS_ASSUME_NONNULL_BEGIN

/// They're just called lyrics log view because they remind me of apple music lyrics 🤫
@interface DOLyricsLogView : UIView<DOLogViewProtocol>
{
    UIImage *_checkmarkImage;
    UIImage *_exclamationMarkImage;
    UIImage *_unlockedImage;
}

@property (nonatomic, strong) UIStackView *stackView;

/// Marks every visible line as completed and appends a final success line.
- (void)finishWithText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
