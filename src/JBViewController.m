#import "JBViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <sys/sysctl.h>

static UIColor *JBGreen(void) { return [UIColor colorWithRed:0.32 green:0.96 blue:0.56 alpha:1.0]; }
static UIColor *JBGray(void) { return [UIColor colorWithWhite:1.0 alpha:0.55]; }

@interface JBViewController ()
@end

@implementation JBViewController {
    CAGradientLayer *_glow;
    UIView *_logoView;
    UIButton *_jailbreakButton;
    UILabel *_deviceLabel;
    UIView *_terminal;
    UIView *_terminalHeader;
    CALayer *_progressTrack;
    CALayer *_progressBar;
    UITextView *_logView;
    UILabel *_successLabel;
    UIImageView *_successIcon;
    NSTimer *_timer;
    NSInteger _line;
    BOOL _running;
}

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.018 green:0.026 blue:0.022 alpha:1.0];

    [self buildGlow];
    [self buildHeader];
    [self buildButton];
    [self buildTerminal];
    [self buildFooter];
}

- (UIFont *)roundedFontOfSize:(CGFloat)size weight:(UIFontWeight)weight {
    UIFont *base = [UIFont systemFontOfSize:size weight:weight];
    UIFontDescriptor *descriptor = [base.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
    return descriptor ? [UIFont fontWithDescriptor:descriptor size:size] : base;
}

#pragma mark - Build

- (void)buildGlow {
    _glow = [CAGradientLayer layer];
    _glow.type = kCAGradientLayerRadial;
    _glow.colors = @[
        (id)[JBGreen() colorWithAlphaComponent:0.20].CGColor,
        (id)[JBGreen() colorWithAlphaComponent:0.0].CGColor,
    ];
    _glow.locations = @[@0.0, @1.0];
    _glow.startPoint = CGPointMake(0.5, 0.5);
    _glow.endPoint = CGPointMake(1.0, 1.0);
    [self.view.layer insertSublayer:_glow atIndex:0];
}

- (void)buildHeader {
    _logoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 56, 56)];
    _logoView.tag = 100;
    _logoView.layer.cornerRadius = 17.0;
    _logoView.layer.cornerCurve = kCACornerCurveContinuous;
    _logoView.layer.masksToBounds = YES;

    CAGradientLayer *mark = [CAGradientLayer layer];
    mark.frame = CGRectMake(0, 0, 56, 56);
    mark.colors = @[
        (id)JBGreen().CGColor,
        (id)[UIColor colorWithRed:0.16 green:0.70 blue:0.86 alpha:1.0].CGColor,
    ];
    mark.startPoint = CGPointMake(0.1, 0.0);
    mark.endPoint = CGPointMake(0.9, 1.0);
    [_logoView.layer addSublayer:mark];

    UILabel *letter = [UILabel new];
    letter.text = @"S";
    letter.font = [self roundedFontOfSize:28 weight:UIFontWeightBold];
    letter.textColor = [UIColor colorWithWhite:0.04 alpha:1.0];
    letter.textAlignment = NSTextAlignmentCenter;
    letter.frame = CGRectMake(0, 0, 56, 56);
    [_logoView addSubview:letter];
    [self.view addSubview:_logoView];

    UILabel *title = [UILabel new];
    title.text = @"Sonekk JB";
    title.font = [self roundedFontOfSize:30 weight:UIFontWeightBold];
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.tag = 101;
    [self.view addSubview:title];

    _deviceLabel = [UILabel new];
    _deviceLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightMedium];
    _deviceLabel.textColor = JBGray();
    _deviceLabel.textAlignment = NSTextAlignmentCenter;
    _deviceLabel.tag = 102;
    [self.view addSubview:_deviceLabel];

    UIDevice *device = [UIDevice currentDevice];
    _deviceLabel.text = [NSString stringWithFormat:@"%@  ·  iOS %@", [self machineIdentifier], device.systemVersion];
}

- (void)buildButton {
    _jailbreakButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _jailbreakButton.tag = 200;
    [_jailbreakButton setTitle:@"Jailbreak" forState:UIControlStateNormal];
    [_jailbreakButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_jailbreakButton setImage:[UIImage systemImageNamed:@"bolt.fill"] forState:UIControlStateNormal];
    _jailbreakButton.tintColor = JBGreen();
    _jailbreakButton.imageEdgeInsets = UIEdgeInsetsMake(0, -6, 0, 0);
    _jailbreakButton.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 0);
    _jailbreakButton.titleLabel.font = [self roundedFontOfSize:18 weight:UIFontWeightSemibold];
    _jailbreakButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.06];
    _jailbreakButton.layer.cornerRadius = 32.0;
    _jailbreakButton.layer.cornerCurve = kCACornerCurveContinuous;
    _jailbreakButton.layer.borderWidth = 1.0;
    _jailbreakButton.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.14].CGColor;
    _jailbreakButton.layer.shadowColor = JBGreen().CGColor;
    _jailbreakButton.layer.shadowOpacity = 0.28;
    _jailbreakButton.layer.shadowRadius = 22.0;
    _jailbreakButton.layer.shadowOffset = CGSizeMake(0, 8);
    [_jailbreakButton addTarget:self action:@selector(startFlow) forControlEvents:UIControlEventTouchUpInside];
    [_jailbreakButton addTarget:self action:@selector(pressDown) forControlEvents:UIControlEventTouchDown];
    [_jailbreakButton addTarget:self action:@selector(pressUp)
                       forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [self.view addSubview:_jailbreakButton];

    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    pulse.fromValue = @0.16;
    pulse.toValue = @0.42;
    pulse.duration = 1.9;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    pulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_jailbreakButton.layer addAnimation:pulse forKey:@"pulse"];
}

- (void)buildTerminal {
    _terminal = [UIView new];
    _terminal.tag = 300;
    _terminal.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.94];
    _terminal.layer.cornerRadius = 20.0;
    _terminal.layer.cornerCurve = kCACornerCurveContinuous;
    _terminal.layer.borderWidth = 1.0;
    _terminal.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08].CGColor;
    _terminal.hidden = YES;
    [self.view addSubview:_terminal];

    _terminalHeader = [UIView new];
    _terminalHeader.frame = CGRectMake(0, 0, 0, 34);
    _terminalHeader.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.04];
    [_terminal addSubview:_terminalHeader];

    UILabel *path = [UILabel new];
    path.text = @"sonekk-jb — session";
    path.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightMedium];
    path.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.35];
    path.tag = 301;
    [_terminalHeader addSubview:path];

    _logView = [UITextView new];
    _logView.backgroundColor = [UIColor clearColor];
    _logView.editable = NO;
    _logView.selectable = NO;
    _logView.textContainerInset = UIEdgeInsetsMake(10, 0, 10, 0);
    _logView.layoutManager.allowsNonContiguousLayout = YES;
    _logView.tag = 302;
    [_terminal addSubview:_logView];

    _successLabel = [UILabel new];
    _successLabel.text = @"Success";
    _successLabel.font = [self roundedFontOfSize:32 weight:UIFontWeightBold];
    _successLabel.textColor = JBGreen();
    _successLabel.textAlignment = NSTextAlignmentCenter;
    _successLabel.alpha = 0.0;
    _successLabel.tag = 303;
    [_terminal addSubview:_successLabel];

    _successIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.circle.fill"]];
    _successIcon.tintColor = JBGreen();
    _successIcon.contentMode = UIViewContentModeScaleAspectFit;
    _successIcon.alpha = 0.0;
    _successIcon.tag = 304;
    [_terminal addSubview:_successIcon];

    _progressTrack = [CALayer layer];
    _progressTrack.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.06].CGColor;
    [_terminal.layer addSublayer:_progressTrack];

    _progressBar = [CALayer layer];
    _progressBar.backgroundColor = JBGreen().CGColor;
    _progressBar.anchorPoint = CGPointMake(0.0, 0.5);
    _progressBar.bounds = CGRectMake(0, 0, 0, 2);
    _progressBar.opacity = 0.0;
    [_terminal.layer addSublayer:_progressBar];
}

- (void)buildFooter {
    UILabel *footer = [UILabel new];
    footer.text = @"v1.0";
    footer.font = [UIFont monospacedSystemFontOfSize:9 weight:UIFontWeightMedium];
    footer.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18];
    footer.textAlignment = NSTextAlignmentCenter;
    footer.tag = 400;
    [self.view addSubview:footer];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGRect bounds = self.view.bounds;
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);
    CGFloat top = self.view.safeAreaInsets.top;
    CGFloat bottom = self.view.safeAreaInsets.bottom;

    _glow.frame = CGRectMake(width * 0.5 - 300, -260, 600, 600);

    _logoView.frame = CGRectMake((width - 56.0) * 0.5, top + 54, 56, 56);

    UILabel *title = [self.view viewWithTag:101];
    title.frame = CGRectMake(24, CGRectGetMaxY(_logoView.frame) + 14, width - 48, 38);

    _deviceLabel.frame = CGRectMake(24, CGRectGetMaxY(title.frame) + 4, width - 48, 18);

    CGFloat buttonWidth = MIN(300.0, width - 80.0);
    _jailbreakButton.frame = CGRectMake((width - buttonWidth) * 0.5,
                                        CGRectGetMidY(bounds) + 46.0,
                                        buttonWidth, 64.0);

    UILabel *footer = [self.view viewWithTag:400];
    footer.frame = CGRectMake(24, height - bottom - 24, width - 48, 14);

    _terminal.frame = CGRectMake(16, top + 16, width - 32, height - top - bottom - 32);
    CGFloat terminalWidth = CGRectGetWidth(_terminal.bounds);
    _terminalHeader.frame = CGRectMake(0, 0, terminalWidth, 34);
    [[_terminalHeader viewWithTag:301] setFrame:CGRectMake(16, 0, terminalWidth - 32, 34)];

    _progressTrack.frame = CGRectMake(0, 34, terminalWidth, 2);
    _progressBar.position = CGPointMake(0, 35);
    _progressBar.bounds = CGRectMake(0, 0, MAX(0, _progressBar.bounds.size.width), 2);

    _logView.frame = CGRectMake(16, 38, terminalWidth - 32, CGRectGetHeight(_terminal.bounds) - 38);

    _successIcon.frame = CGRectMake(CGRectGetMidX(_terminal.bounds) - 22,
                                    CGRectGetMidY(_terminal.bounds) - 66,
                                    44, 44);
    _successLabel.frame = CGRectMake(16, CGRectGetMidY(_terminal.bounds) - 14, terminalWidth - 32, 44);
}

#pragma mark - Actions

- (void)pressDown {
    [UIView animateWithDuration:0.12 animations:^{
        self->_jailbreakButton.transform = CGAffineTransformMakeScale(0.97, 0.97);
        self->_jailbreakButton.layer.borderColor = JBGreen().CGColor;
    }];
}

- (void)pressUp {
    [UIView animateWithDuration:0.18 animations:^{
        self->_jailbreakButton.transform = CGAffineTransformIdentity;
        self->_jailbreakButton.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.14].CGColor;
    }];
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

    _terminal.alpha = 0.0;
    _terminal.hidden = NO;
    [UIView animateWithDuration:0.25 animations:^{
        self->_terminal.alpha = 1.0;
        self->_jailbreakButton.alpha = 0.0;
    }];

    _line = 0;
    _logView.text = @"";
    _logView.alpha = 1.0;
    _successLabel.alpha = 0.0;
    _successIcon.alpha = 0.0;

    _progressBar.opacity = 1.0;
    _progressBar.bounds = CGRectMake(0, 0, 0, 2);
    CGFloat target = CGRectGetWidth(_terminal.bounds);
    _progressBar.bounds = CGRectMake(0, 0, target, 2);
    CABasicAnimation *grow = [CABasicAnimation animationWithKeyPath:@"bounds.size.width"];
    grow.fromValue = @0.0;
    grow.toValue = @(target);
    grow.duration = 4.0;
    grow.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_progressBar addAnimation:grow forKey:@"grow"];

    _timer = [NSTimer scheduledTimerWithTimeInterval:0.042
                                              target:self
                                            selector:@selector(tick)
                                            userInfo:nil
                                             repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self finishFlow];
    });
}

- (void)tick {
    [self appendLine:[self logLineForIndex:_line++]];
    [self appendLine:[self logLineForIndex:_line++]];

    if (_logView.text.length > 1) {
        [_logView scrollRangeToVisible:NSMakeRange(_logView.text.length - 1, 1)];
    }
}

- (void)appendLine:(NSString *)line {
    NSString *tag = [line substringToIndex:3];
    UIColor *color = JBGray();
    if ([tag isEqualToString:@"[+]"]) color = JBGreen();
    else if ([tag isEqualToString:@"[!]"]) color = [UIColor colorWithRed:1.0 green:0.78 blue:0.30 alpha:1.0];
    else if ([tag isEqualToString:@"[i]"]) color = [UIColor colorWithRed:0.45 green:0.82 blue:1.0 alpha:1.0];

    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithAttributedString:_logView.attributedText ?: [[NSAttributedString alloc] initWithString:@""]];
    NSDictionary *attributes = @{
        NSFontAttributeName : [UIFont monospacedSystemFontOfSize:10.5 weight:UIFontWeightMedium],
        NSForegroundColorAttributeName : color,
    };
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:[line stringByAppendingString:@"\n"]
                                                                 attributes:attributes]];
    _logView.attributedText = text;
}

- (NSString *)logLineForIndex:(NSInteger)index {
    static NSArray<NSString *> *templates;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        templates = @[
            @"[*] sonekk-jb 1.0 (arm64)",
            @"[*] resolving device %@",
            @"[+] device tree matched",
            @"[*] reading dyld shared cache header",
            @"[i] cache slide 0x%08x",
            @"[*] mapping shared cache segments",
            @"[+] 0x%08x bytes mapped",
            @"[*] scanning trust cache",
            @"[+] trust cache valid (%d entries)",
            @"[*] preparing sandbox overlay",
            @"[+] overlay mounted at /private/preboot",
            @"[*] linking runtime libraries",
            @"[i] dyld image count %d",
            @"[*] checking code signing policy",
            @"[+] policy relaxed for session",
            @"[*] probing %@",
            @"[i] probe latency %d ms",
            @"[*] warming kernel surface",
            @"[+] surface ready",
            @"[*] starting bootstrap daemon",
            @"[i] pid %d spawned",
            @"[*] mounting app container",
            @"[+] container linked",
            @"[*] verifying entitlements",
            @"[+] entitlements accepted",
            @"[*] loading framework bundle",
            @"[i] 0x%08x symbols resolved",
            @"[*] applying patch set",
            @"[+] patch %d/%d applied",
            @"[*] flushing page tables",
            @"[+] tlb invalidated",
            @"[*] handshake with environment",
            @"[+] handshake ok",
            @"[*] preparing launch",
            @"[i] launch target org.emexlabs.nyxian",
            @"[*] finalizing",
        ];
    });

    NSString *template = templates[index % templates.count];
    NSInteger r1 = (NSInteger)(arc4random() % 0x7fffffff);
    NSInteger r2 = (NSInteger)(arc4random() % 4096);

    NSString *line = template;
    for (NSInteger i = 0; i < 2; i++) {
        NSRange hex = [line rangeOfString:@"%08x"];
        if (hex.location != NSNotFound) {
            line = [line stringByReplacingCharactersInRange:hex withString:[NSString stringWithFormat:@"%08lx", (long)r1]];
            continue;
        }
        NSRange dec = [line rangeOfString:@"%d"];
        if (dec.location != NSNotFound) {
            line = [line stringByReplacingCharactersInRange:dec withString:[NSString stringWithFormat:@"%ld", (long)(r2 % 900 + 12)]];
            continue;
        }
        NSRange str = [line rangeOfString:@"%@"];
        if (str.location != NSNotFound) {
            line = [line stringByReplacingCharactersInRange:str withString:[self machineIdentifier]];
        }
    }
    return line;
}

- (void)finishFlow {
    [_timer invalidate];
    _timer = nil;

    [self appendLine:@"[+] Success"];
    [_logView scrollRangeToVisible:NSMakeRange(_logView.text.length - 1, 1)];

    [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeSuccess];

    _successLabel.transform = CGAffineTransformMakeScale(0.85, 0.85);
    _successIcon.transform = CGAffineTransformMakeScale(0.6, 0.6);
    [UIView animateWithDuration:0.22
                          delay:0.05
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self->_successLabel.alpha = 1.0;
        self->_successLabel.transform = CGAffineTransformIdentity;
        self->_successIcon.alpha = 1.0;
        self->_successIcon.transform = CGAffineTransformIdentity;
        self->_logView.alpha = 0.25;
    } completion:nil];

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
    [UIView animateWithDuration:0.2 animations:^{
        self->_terminal.alpha = 0.0;
        self->_jailbreakButton.alpha = 1.0;
    } completion:^(BOOL finished) {
        self->_terminal.hidden = YES;
        self->_successLabel.alpha = 0.0;
        self->_successIcon.alpha = 0.0;
        self->_progressBar.opacity = 0.0;
        self->_logView.alpha = 1.0;
        self->_logView.text = @"";
    }];
}

- (void)alertWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Device

- (NSString *)machineIdentifier {
    char buffer[64];
    size_t size = sizeof(buffer);
    if (sysctlbyname("hw.machine", buffer, &size, NULL, 0) != 0) return @"iPhone";
    return [NSString stringWithUTF8String:buffer];
}

@end
