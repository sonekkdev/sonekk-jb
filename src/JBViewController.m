#import "JBViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <sys/sysctl.h>

// Visual language mirrors Dopamine (opa334/Dopamine, GPLv3): translucent menu rows,
// a full-width 60pt action button that expands into a full-screen log, 20pt white log
// lines with a leading indicator that completes to a checkmark.

static UIColor *JBAccent(void) { return [UIColor colorWithRed:0.30 green:0.95 blue:0.55 alpha:1.0]; }
static UIColor *JBMenuColor(void) { return [UIColor colorWithWhite:0.247 alpha:0.447]; }
static UIColor *JBDim(void) { return [UIColor colorWithWhite:1.0 alpha:0.60]; }

static const CGFloat kRowHeight = 44.0;
static const CGFloat kLogSpacing = 2.0;

@interface JBLogRow : UIView
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UIView *dot;
- (void)complete;
@end

@implementation JBLogRow

- (instancetype)initWithText:(NSString *)text color:(UIColor *)color {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _dot = [[UIView alloc] initWithFrame:CGRectMake(10, 18, 8, 8)];
        _dot.backgroundColor = color;
        _dot.layer.cornerRadius = 4;
        [self addSubview:_dot];

        _icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark"
                                                           withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightSemibold]]];
        _icon.tintColor = [UIColor whiteColor];
        _icon.contentMode = UIViewContentModeScaleAspectFit;
        _icon.frame = CGRectMake(0, 7, 30, 30);
        _icon.alpha = 0.0;
        [self addSubview:_icon];

        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.text = text;
        _label.textColor = [UIColor whiteColor];
        _label.font = [UIFont systemFontOfSize:20 weight:UIFontWeightRegular];
        _label.numberOfLines = 1;
        _label.adjustsFontSizeToFitWidth = YES;
        _label.minimumScaleFactor = 0.75;
        [self addSubview:_label];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = CGRectGetWidth(self.bounds);
    _label.frame = CGRectMake(45, 0, width - 45, CGRectGetHeight(self.bounds));
}

- (void)complete {
    if (_icon.alpha > 0.5) return;
    [UIView animateWithDuration:0.18 animations:^{
        self.dot.alpha = 0.0;
        self.icon.alpha = 1.0;
        self.label.alpha = 0.5;
        self.label.font = [UIFont systemFontOfSize:18 weight:UIFontWeightRegular];
    }];
}

@end

@interface JBViewController ()
@end

@implementation JBViewController {
    CAGradientLayer *_backdrop;
    CAGradientLayer *_highlight;

    UIImageView *_logo;
    UILabel *_titleLabel;
    UILabel *_deviceLabel;

    UIView *_menuCard;
    UILabel *_menuEnvironment;
    UILabel *_menuAbout;

    UIButton *_actionButton;
    UIView *_buttonContent;
    UIImageView *_buttonIcon;
    UILabel *_buttonTitle;

    UIView *_logContainer;
    NSMutableArray<JBLogRow *> *_rows;
    NSTimer *_timer;
    NSInteger _line;
    BOOL _running;
}

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    _rows = [NSMutableArray array];

    [self buildBackdrop];
    [self buildHeader];
    [self buildMenu];
    [self buildLog];
    [self buildButton];
}

#pragma mark - Backdrop

- (void)buildBackdrop {
    _backdrop = [CAGradientLayer layer];
    _backdrop.colors = @[
        (id)[UIColor colorWithRed:0.055 green:0.145 blue:0.105 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.024 green:0.055 blue:0.042 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.008 green:0.016 blue:0.013 alpha:1.0].CGColor,
    ];
    _backdrop.locations = @[@0.0, @0.55, @1.0];
    _backdrop.startPoint = CGPointMake(0.15, 0.0);
    _backdrop.endPoint = CGPointMake(0.85, 1.0);
    [self.view.layer addSublayer:_backdrop];

    _highlight = [CAGradientLayer layer];
    _highlight.type = kCAGradientLayerRadial;
    _highlight.colors = @[
        (id)[UIColor colorWithRed:0.20 green:0.75 blue:0.42 alpha:0.30].CGColor,
        (id)[UIColor clearColor].CGColor,
    ];
    _highlight.locations = @[@0.0, @1.0];
    _highlight.startPoint = CGPointMake(0.5, 0.5);
    _highlight.endPoint = CGPointMake(1.0, 1.0);
    [self.view.layer addSublayer:_highlight];
}

#pragma mark - Header

- (UIImage *)logoImage {
    UIImage *image = [UIImage imageNamed:@"AppIcon60x60@3x"];
    if (!image) {
        image = [UIImage imageNamed:@"AppIcon60x60@2x"];
    }
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (void)buildHeader {
    _logo = [[UIImageView alloc] initWithImage:[self logoImage]];
    _logo.contentMode = UIViewContentModeScaleAspectFit;
    _logo.layer.cornerRadius = 9.0;
    _logo.layer.cornerCurve = kCACornerCurveContinuous;
    _logo.layer.masksToBounds = YES;
    _logo.tag = 100;
    [self.view addSubview:_logo];

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.text = @"Sonekk JB";
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.view addSubview:_titleLabel];

    _deviceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _deviceLabel.text = [NSString stringWithFormat:@"%@ · iOS %@", [self machineIdentifier], [UIDevice currentDevice].systemVersion];
    _deviceLabel.textColor = JBDim();
    _deviceLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    [self.view addSubview:_deviceLabel];
}

#pragma mark - Menu

- (void)buildMenu {
    _menuCard = [[UIView alloc] initWithFrame:CGRectZero];
    _menuCard.backgroundColor = JBMenuColor();
    _menuCard.layer.cornerRadius = 14.0;
    _menuCard.layer.cornerCurve = kCACornerCurveContinuous;
    _menuCard.layer.masksToBounds = YES;
    _menuCard.tag = 200;
    [self.view addSubview:_menuCard];

    [self addMenuRowWithTitle:@"Environment" symbol:@"lock.shield" tag:201 action:@selector(showEnvironment)];
    [self addMenuRowWithTitle:@"About" symbol:@"info.circle" tag:202 action:@selector(showAbout)];

    UIView *separator = [[UIView alloc] initWithFrame:CGRectZero];
    separator.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.10];
    separator.tag = 210;
    [_menuCard addSubview:separator];
}

- (void)addMenuRowWithTitle:(NSString *)title symbol:(NSString *)symbol tag:(NSInteger)tag action:(SEL)action {
    UIControl *row = [[UIControl alloc] initWithFrame:CGRectZero];
    row.tag = tag;
    [row addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [_menuCard addSubview:row];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:symbol
                                                                   withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightMedium]]];
    icon.tintColor = [UIColor whiteColor];
    icon.tag = 220;
    [row addSubview:icon];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = title;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    label.tag = 221;
    [row addSubview:label];

    UIImageView *chevron = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"
                                                                     withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightSemibold]]];
    chevron.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.35];
    chevron.tag = 222;
    [row addSubview:chevron];
}

#pragma mark - Button

- (void)buildButton {
    _actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _actionButton.backgroundColor = JBMenuColor();
    _actionButton.layer.cornerRadius = 14.0;
    _actionButton.layer.cornerCurve = kCACornerCurveContinuous;
    _actionButton.tag = 300;
    [_actionButton addTarget:self action:@selector(startFlow) forControlEvents:UIControlEventTouchUpInside];
    [_actionButton addTarget:self action:@selector(pressDown) forControlEvents:UIControlEventTouchDown];
    [_actionButton addTarget:self action:@selector(pressUp)
                   forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [self.view addSubview:_actionButton];

    _buttonContent = [[UIView alloc] initWithFrame:CGRectZero];
    _buttonContent.userInteractionEnabled = NO;
    [_actionButton addSubview:_buttonContent];

    _buttonIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.open"
                                                             withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightMedium]]];
    _buttonIcon.tintColor = [UIColor whiteColor];
    [_buttonContent addSubview:_buttonIcon];

    _buttonTitle = [[UILabel alloc] initWithFrame:CGRectZero];
    _buttonTitle.text = @"Jailbreak";
    _buttonTitle.textColor = [UIColor whiteColor];
    _buttonTitle.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    [_buttonContent addSubview:_buttonTitle];
}

#pragma mark - Log

- (void)buildLog {
    _logContainer = [[UIView alloc] initWithFrame:CGRectZero];
    _logContainer.backgroundColor = [UIColor clearColor];
    _logContainer.hidden = YES;
    _logContainer.tag = 400;
    [self.view insertSubview:_logContainer belowSubview:_actionButton];
}

- (void)appendLine:(NSString *)line color:(UIColor *)color {
    JBLogRow *row = [[JBLogRow alloc] initWithText:line color:color];
    row.alpha = 0.0;
    row.transform = CGAffineTransformMakeTranslation(0, 8);
    [_logContainer addSubview:row];
    [_rows addObject:row];

    if (_rows.count > 1) {
        [_rows[_rows.count - 2] complete];
    }

    while (_rows.count > 24) {
        [_rows.firstObject removeFromSuperview];
        [_rows removeObjectAtIndex:0];
    }

    [UIView animateWithDuration:0.2 animations:^{
        row.alpha = 1.0;
        row.transform = CGAffineTransformIdentity;
        [self layoutLogRows];
    }];
}

- (void)layoutLogRows {
    CGFloat width = CGRectGetWidth(_logContainer.bounds);
    CGFloat bottom = CGRectGetHeight(_logContainer.bounds) - 36.0;
    NSInteger count = (NSInteger)_rows.count;
    for (NSInteger i = count - 1; i >= 0; i--) {
        NSInteger slot = count - 1 - i;
        CGFloat y = bottom - (slot + 1) * (kRowHeight + kLogSpacing);
        _rows[i].frame = CGRectMake(25, y, width - 50, kRowHeight);
    }
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGRect bounds = self.view.bounds;
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);
    CGFloat top = self.view.safeAreaInsets.top;
    CGFloat bottom = self.view.safeAreaInsets.bottom;

    _backdrop.frame = bounds;
    _highlight.frame = CGRectMake(-width * 0.4, -height * 0.35, width * 1.8, height * 1.1);

    if (_running) {
        _logContainer.frame = bounds;
    }

    if (_actionButton.frame.size.height <= 0) {
        CGFloat actionHeight = 60.0;
        _actionButton.frame = CGRectMake(25, height - bottom - 40.0 - actionHeight, width - 50, actionHeight);
    }

    CGFloat contentWidth = 44 + 10 + 90;
    _buttonContent.frame = CGRectMake((CGRectGetWidth(_actionButton.bounds) - contentWidth) * 0.5, 0, contentWidth, 60);
    _buttonIcon.frame = CGRectMake(0, 22, 16, 16);
    _buttonTitle.frame = CGRectMake(26, 0, 90, 60);

    _logo.frame = CGRectMake(25, top + 22, 40, 40);
    _titleLabel.frame = CGRectMake(73, top + 26, width - 100, 18);
    _deviceLabel.frame = CGRectMake(73, top + 46, width - 100, 18);

    CGFloat menuTop = top + 92;
    _menuCard.frame = CGRectMake(25, menuTop, width - 50, 100);
    NSArray<NSNumber *> *rowTags = @[@201, @202];
    for (NSInteger i = 0; i < rowTags.count; i++) {
        UIControl *row = (UIControl *)[_menuCard viewWithTag:rowTags[i].integerValue];
        row.frame = CGRectMake(0, i * 50, CGRectGetWidth(_menuCard.bounds), 50);
        [[row viewWithTag:220] setFrame:CGRectMake(15, 18, 14, 14)];
        [[row viewWithTag:221] setFrame:CGRectMake(39, 0, CGRectGetWidth(_menuCard.bounds) - 80, 50)];
        [[row viewWithTag:222] setFrame:CGRectMake(CGRectGetWidth(_menuCard.bounds) - 27, 19, 12, 12)];
    }
    [[_menuCard viewWithTag:210] setFrame:CGRectMake(15, 50, CGRectGetWidth(_menuCard.bounds) - 30, 0.5)];

    [self layoutLogRows];
}

#pragma mark - Actions

- (void)pressDown {
    [UIView animateWithDuration:0.12 animations:^{
        self->_actionButton.transform = CGAffineTransformMakeScale(0.99, 0.99);
        self->_actionButton.backgroundColor = [UIColor colorWithWhite:0.247 alpha:0.65];
    }];
}

- (void)pressUp {
    [UIView animateWithDuration:0.16 animations:^{
        self->_actionButton.transform = CGAffineTransformIdentity;
        self->_actionButton.backgroundColor = JBMenuColor();
    }];
}

- (void)showEnvironment {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Environment"
                                                                   message:[self environmentDescription]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAbout {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sonekk JB 1.0"
                                                                   message:@"Launcher that prepares this session and opens Nyxian Clean."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSString *)environmentDescription {
    BOOL hasNyxian = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"livecontainer://"]];
    return [NSString stringWithFormat:@"Device: %@\niOS: %@\nRuntime: %@",
            [self machineIdentifier],
            [UIDevice currentDevice].systemVersion,
            hasNyxian ? @"ready" : @"missing"];
}

- (void)startFlow {
    if (_running) return;
    _running = YES;
    [self pressUp];

    NSURL *url = [NSURL URLWithString:@"livecontainer://"];
    if (![[UIApplication sharedApplication] canOpenURL:url]) {
        _running = NO;
        [self alertWithMessage:@"Nyxian not found. Install it with the same certificate."];
        return;
    }

    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];

    _logContainer.frame = self.view.bounds;
    _logContainer.hidden = NO;
    _logContainer.alpha = 0.0;

    CGFloat height = CGRectGetHeight(self.view.bounds);
    CGRect expanded = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), height);

    _actionButton.layer.cornerRadius = 0.0;
    _buttonContent.alpha = 1.0;
    [UIView animateWithDuration:0.2 animations:^{
        self->_buttonContent.alpha = 0.0;
        self->_menuCard.alpha = 0.0;
        self->_logo.transform = CGAffineTransformMakeTranslation(0, -25);
        self->_titleLabel.transform = CGAffineTransformMakeTranslation(0, -25);
        self->_deviceLabel.transform = CGAffineTransformMakeTranslation(0, -25);
    }];

    [UIView animateWithDuration:0.6 delay:0.0 usingSpringWithDamping:0.9 initialSpringVelocity:1.6
                        options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self->_actionButton.frame = expanded;
        self->_actionButton.backgroundColor = [UIColor clearColor];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 animations:^{
            self->_logContainer.alpha = 1.0;
        }];
        [self->_actionButton setHidden:YES];
    }];

    _line = 0;
    _timer = [NSTimer timerWithTimeInterval:0.08 target:self selector:@selector(tick) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self finishFlow];
    });
}

- (void)tick {
    [self appendLine:[self logLineForIndex:_line++] color:JBDim()];
    if (_line > 2000) _line = 0;
}

- (void)finishFlow {
    [_timer invalidate];
    _timer = nil;

    for (JBLogRow *row in _rows) [row complete];

    JBLogRow *success = [[JBLogRow alloc] initWithText:@"Success" color:JBAccent()];
    success.alpha = 0.0;
    success.transform = CGAffineTransformMakeTranslation(0, 8);
    [_logContainer addSubview:success];
    [_rows addObject:success];

    [UIView animateWithDuration:0.25 animations:^{
        success.alpha = 1.0;
        success.transform = CGAffineTransformIdentity;
        [self layoutLogRows];
    }];

    [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeSuccess];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self openEnvironment];
    });
}

- (void)openEnvironment {
    NSURL *url = [NSURL URLWithString:@"livecontainer://"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!success) {
                [self alertWithMessage:@"Nyxian did not respond. Try again."];
            }
            [self resetFlow];
        });
    }];
}

- (void)resetFlow {
    _running = NO;
    for (JBLogRow *row in _rows) [row removeFromSuperview];
    [_rows removeAllObjects];

    _logContainer.hidden = YES;
    _logContainer.alpha = 0.0;

    _actionButton.hidden = NO;
    _actionButton.layer.cornerRadius = 14.0;
    _actionButton.backgroundColor = JBMenuColor();
    _actionButton.frame = CGRectZero;
    _menuCard.alpha = 1.0;
    _buttonContent.alpha = 1.0;

    [UIView animateWithDuration:0.3 animations:^{
        self->_logo.transform = CGAffineTransformIdentity;
        self->_titleLabel.transform = CGAffineTransformIdentity;
        self->_deviceLabel.transform = CGAffineTransformIdentity;
    }];
    [self.view setNeedsLayout];
}

- (void)alertWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Log content

- (NSString *)logLineForIndex:(NSInteger)index {
    static NSArray<NSString *> *templates;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        templates = @[
            @"Preparing session",
            @"Reading device information",
            @"Resolving runtime environment",
            @"Mapping shared cache",
            @"Validating trust cache",
            @"Mounting sandbox overlay",
            @"Linking runtime libraries",
            @"Checking signing policy",
            @"Warming kernel surface",
            @"Starting bootstrap service",
            @"Linking application container",
            @"Verifying entitlements",
            @"Loading framework bundle",
            @"Applying patch set",
            @"Flushing page tables",
            @"Synchronizing with environment",
            @"Finalizing launch",
            @"Handshake accepted",
        ];
    });
    return templates[index % templates.count];
}

#pragma mark - Device

- (NSString *)machineIdentifier {
    char buffer[64];
    size_t size = sizeof(buffer);
    if (sysctlbyname("hw.machine", buffer, &size, NULL, 0) != 0) return @"iPhone";
    return [NSString stringWithUTF8String:buffer];
}

@end
