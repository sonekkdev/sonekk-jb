#import "JBJailbreakButton.h"
#import "DOActionMenuButton.h"
#import "DODoubleHelixIndicator.h"
#import "DOGlobalAppearance.h"
#import "DOThemeManager.h"
#import "DOLyricsLogView.h"
#import <pthread.h>

// Mirrors DOJailbreakButton from Dopamine, with DOUIManager replaced by a direct log view.

@implementation JBJailbreakButton {
    pthread_mutex_t _canStartJailbreak;
}

- (instancetype)initWithAction:(UIAction *)action {
    self = [super init];
    if (self) {
        self.backgroundColor = [DOThemeManager menuColorWithAlpha:1.0];
        self.layer.cornerRadius = 14;
        self.layer.masksToBounds = YES;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.translatesAutoresizingMaskIntoConstraints = NO;

        _button = [DOActionMenuButton buttonWithAction:action chevron:NO];
        [_button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        _button.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_button];

        [NSLayoutConstraint activateConstraints:@[
            [_button.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_button.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_button.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_button.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        ]];
    }
    return self;
}

- (void)expandButton:(NSArray<NSLayoutConstraint *> *)constraints {
    if (_didExpand) return;
    [self lockMutex];
    _didExpand = YES;

    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    float topPadding = (window.frame.size.height * (1 - 0.74)) + 35;

    [self setupLog:topPadding];

    [NSLayoutConstraint deactivateConstraints:constraints];
    [NSLayoutConstraint activateConstraints:@[
        [self.leadingAnchor constraintEqualToAnchor:window.leadingAnchor],
        [self.trailingAnchor constraintEqualToAnchor:window.trailingAnchor],
        [self.topAnchor constraintEqualToAnchor:window.topAnchor constant:topPadding],
        [self.bottomAnchor constraintEqualToAnchor:window.bottomAnchor constant:100],
    ]];

    [_button setUserInteractionEnabled:NO];

    [UIView animateWithDuration:0.2 animations:^{
        [self.button setAlpha:0.0];
    }];
    [UIView animateWithDuration:0.75 delay:0.0 usingSpringWithDamping:0.9 initialSpringVelocity:2.0
                        options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [window layoutIfNeeded];
    } completion:nil];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self setupTitle];
    });

    [self unlockMutex];
}

- (void)setupLog:(float)topPadding {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];

    _logView = [[DOLyricsLogView alloc] init];
    _logView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_logView];

    [NSLayoutConstraint activateConstraints:@[
        [_logView.leadingAnchor constraintEqualToAnchor:window.leadingAnchor],
        [_logView.trailingAnchor constraintEqualToAnchor:window.trailingAnchor],
        [_logView.topAnchor constraintEqualToAnchor:window.topAnchor constant:topPadding],
        [_logView.bottomAnchor constraintEqualToAnchor:window.bottomAnchor],
    ]];

    [window layoutIfNeeded];
}

- (void)setupTitle {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"Jailbreaking";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightRegular];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.alpha = 0.0;
    [self addSubview:titleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.centerXAnchor constraintEqualToAnchor:window.centerXAnchor constant:20],
        [titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:20],
    ]];

    [UIView animateWithDuration:0.2 animations:^{
        titleLabel.alpha = 1.0;
    }];

    DODoubleHelixIndicator *indicator = [[DODoubleHelixIndicator alloc] init];
    indicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:indicator];

    [NSLayoutConstraint activateConstraints:@[
        [indicator.trailingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor constant:-10],
        [indicator.centerYAnchor constraintEqualToAnchor:titleLabel.centerYAnchor],
        [indicator.widthAnchor constraintEqualToConstant:30],
        [indicator.heightAnchor constraintEqualToConstant:12],
    ]];
}

- (void)setEnabled:(BOOL)enabled {
    _button.userInteractionEnabled = enabled;
    self.alpha = enabled ? 1.0 : 0.7;
}

- (BOOL)isEnabled {
    return _button.userInteractionEnabled;
}

#pragma mark - Mutex

- (void)lockMutex {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pthread_mutex_init(&self->_canStartJailbreak, NULL);
    });
    pthread_mutex_lock(&self->_canStartJailbreak);
}

- (void)unlockMutex {
    pthread_mutex_unlock(&self->_canStartJailbreak);
}

@end
