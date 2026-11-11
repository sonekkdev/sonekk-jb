#import <UIKit/UIKit.h>

@class DOActionMenuButton;
@class DOLyricsLogView;

@interface JBJailbreakButton : UIView

@property (nonatomic, strong) DOActionMenuButton *button;
@property (nonatomic, strong) DOLyricsLogView *logView;
@property (nonatomic) BOOL didExpand;

- (instancetype)initWithAction:(UIAction *)action;
- (void)expandButton:(NSArray<NSLayoutConstraint *> *)constraints;
- (void)setEnabled:(BOOL)enabled;
- (BOOL)isEnabled;

@end
