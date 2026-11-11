#import "JBViewController.h"
#import <sys/sysctl.h>
#import "DOHeaderView.h"
#import "DOActionMenuView.h"
#import "DOGlobalAppearance.h"
#import "DOThemeManager.h"
#import "JBJailbreakButton.h"
#import "DOLyricsLogView.h"

// Layout ported 1:1 from Dopamine's DOMainViewController (opa334/Dopamine, GPLv3).

@interface JBViewController () <DOActionMenuDelegate>

@property (nonatomic, strong) DOHeaderView *headerView;
@property (nonatomic, strong) DOActionMenuView *actionView;
@property (nonatomic, strong) JBJailbreakButton *jailbreakBtn;
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *jailbreakButtonConstraints;
@property (nonatomic, strong) NSTimer *logTimer;
@property (nonatomic) NSInteger logIndex;
@property (nonatomic) BOOL running;
@property (nonatomic) BOOL launched;

@end

@implementation JBViewController

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationBecameActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [self buildInterface];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationBecameActive {
    if (!_launched) return;
    _launched = NO;
    [_logTimer invalidate];
    _logTimer = nil;
    _running = NO;
    [self buildInterface];
}

#pragma mark - Interface

- (void)buildInterface {
    for (UIView *view in [self.view.subviews copy]) {
        [view removeFromSuperview];
    }

    DOTheme *theme = [[DOThemeManager sharedInstance] enabledTheme];
    UIImageView *background = [[UIImageView alloc] initWithImage:[theme image]];
    background.contentMode = UIViewContentModeScaleAspectFill;
    background.clipsToBounds = YES;
    background.userInteractionEnabled = NO;
    background.layer.zPosition = -1;
    background.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:background atIndex:0];
    [NSLayoutConstraint activateConstraints:@[
        [background.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [background.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [background.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:-100],
        [background.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:100],
    ]];

    [self setupStack];
}

- (void)setupStack {
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentTrailing;
    stackView.distribution = UIStackViewDistributionEqualSpacing;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stackView];

    CGFloat statusBarHeight = fmax(15, [[UIApplication sharedApplication] keyWindow].safeAreaInsets.top - 20);

    [NSLayoutConstraint activateConstraints:@[
        [stackView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:statusBarHeight],
        [stackView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor
                                             multiplier:[DOGlobalAppearance isHomeButtonDevice] ? 0.78 : 0.73],
        [stackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:UI_PADDING],
        [stackView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-UI_PADDING],
    ]];

    _headerView = [[DOHeaderView alloc] initWithImage:[self wordmarkImage]
                                            subtitles:@[
        [DOGlobalAppearance mainSubtitleString:[NSString stringWithFormat:@"%@ · iOS %@",
                                                [self machineIdentifier], [UIDevice currentDevice].systemVersion]],
        [DOGlobalAppearance secondarySubtitleString:@"Sonekk 1.0"],
    ]];
    [stackView addArrangedSubview:_headerView];
    [NSLayoutConstraint activateConstraints:@[
        [_headerView.leadingAnchor constraintEqualToAnchor:stackView.leadingAnchor constant:5],
        [_headerView.trailingAnchor constraintEqualToAnchor:stackView.trailingAnchor],
    ]];

    NSArray<UIAction *> *actions = @[
        [UIAction actionWithTitle:@"Environment"
                            image:[UIImage systemImageNamed:@"gearshape"
                                           withConfiguration:[DOGlobalAppearance smallIconImageConfiguration]]
                       identifier:@"environment"
                          handler:^(__kindof UIAction * _Nonnull action) {
            [self showEnvironment];
        }],
        [UIAction actionWithTitle:@"Restart Session"
                            image:[UIImage systemImageNamed:@"arrow.clockwise"
                                           withConfiguration:[DOGlobalAppearance smallIconImageConfiguration]]
                       identifier:@"restart"
                          handler:^(__kindof UIAction * _Nonnull action) {
            [self restartSession];
        }],
        [UIAction actionWithTitle:@"About"
                            image:[UIImage systemImageNamed:@"info.circle"
                                           withConfiguration:[DOGlobalAppearance smallIconImageConfiguration]]
                       identifier:@"about"
                          handler:^(__kindof UIAction * _Nonnull action) {
            [self showAbout];
        }],
        [UIAction actionWithTitle:@"Quit"
                            image:[UIImage systemImageNamed:@"xmark.circle"
                                           withConfiguration:[DOGlobalAppearance smallIconImageConfiguration]]
                       identifier:@"quit"
                          handler:^(__kindof UIAction * _Nonnull action) {
            exit(0);
        }],
    ];

    _actionView = [[DOActionMenuView alloc] initWithActions:actions delegate:self];
    [stackView addArrangedSubview:_actionView];
    [NSLayoutConstraint activateConstraints:@[
        [_actionView.leadingAnchor constraintEqualToAnchor:stackView.leadingAnchor],
        [_actionView.trailingAnchor constraintEqualToAnchor:stackView.trailingAnchor],
    ]];

    UIView *buttonPlaceHolder = [[UIView alloc] init];
    buttonPlaceHolder.translatesAutoresizingMaskIntoConstraints = NO;
    [stackView addArrangedSubview:buttonPlaceHolder];
    [NSLayoutConstraint activateConstraints:@[
        [buttonPlaceHolder.heightAnchor constraintEqualToConstant:60],
    ]];

    _jailbreakBtn = [[JBJailbreakButton alloc] initWithAction:
        [UIAction actionWithTitle:@"Jailbreak"
                            image:[UIImage systemImageNamed:@"lock.open"
                                           withConfiguration:[DOGlobalAppearance smallIconImageConfiguration]]
                       identifier:@"jailbreak"
                          handler:^(__kindof UIAction * _Nonnull action) {
            [self startJailbreak];
        }]];
    [_jailbreakBtn setEnabled:YES];
    [self.view addSubview:_jailbreakBtn];

    _jailbreakButtonConstraints = @[
        [_jailbreakBtn.leadingAnchor constraintEqualToAnchor:stackView.leadingAnchor],
        [_jailbreakBtn.trailingAnchor constraintEqualToAnchor:stackView.trailingAnchor],
        [_jailbreakBtn.heightAnchor constraintEqualToAnchor:buttonPlaceHolder.heightAnchor],
        [_jailbreakBtn.centerYAnchor constraintEqualToAnchor:buttonPlaceHolder.centerYAnchor],
    ];
    [NSLayoutConstraint activateConstraints:_jailbreakButtonConstraints];
}

- (UIImage *)wordmarkImage {
    NSString *text = @"Sonekk";
    UIFont *font = [UIFont systemFontOfSize:36 weight:UIFontWeightHeavy];
    NSDictionary *attributes = @{
        NSFontAttributeName : font,
        NSForegroundColorAttributeName : [UIColor whiteColor],
    };
    CGSize textSize = [text sizeWithAttributes:attributes];
    CGSize canvas = CGSizeMake(ceil(textSize.width) + 2, ceil(textSize.height) + 6);

    UIGraphicsBeginImageContextWithOptions(canvas, NO, 0);
    [text drawAtPoint:CGPointMake(1, 3) withAttributes:attributes];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - Menu delegate

- (BOOL)actionMenuShowsChevronForAction:(UIAction *)action {
    return [action.identifier isEqualToString:@"environment"] || [action.identifier isEqualToString:@"about"];
}

- (BOOL)actionMenuActionIsEnabled:(UIAction *)action {
    return !_running;
}

#pragma mark - Menu actions

- (void)showEnvironment {
    BOOL ready = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"livecontainer://"]];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Environment"
                                                                   message:[NSString stringWithFormat:
                                                                            @"Device: %@\niOS: %@\nRuntime: %@",
                                                                            [self machineIdentifier],
                                                                            [UIDevice currentDevice].systemVersion,
                                                                            ready ? @"ready" : @"missing"]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAbout {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sonekk 1.0"
                                                                   message:@"Prepares the session and opens Nyxian Clean."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)restartSession {
    [_logTimer invalidate];
    _logTimer = nil;
    _running = NO;
    [self buildInterface];
}

#pragma mark - Flow

- (void)startJailbreak {
    if (_running) return;

    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"livecontainer://"]]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                       message:@"Nyxian not found. Install it with the same certificate."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    _running = YES;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];

    [_actionView hide];
    [_jailbreakBtn expandButton:_jailbreakButtonConstraints];

    [UIView animateWithDuration:0.75 delay:0
         usingSpringWithDamping:0.9 initialSpringVelocity:2.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.headerView.transform = CGAffineTransformMakeTranslation(0, -25);
    } completion:nil];

    _logIndex = 0;
    _logTimer = [NSTimer timerWithTimeInterval:0.09 target:self selector:@selector(pushLogLine) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_logTimer forMode:NSRunLoopCommonModes];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self finishFlow];
    });
}

- (void)pushLogLine {
    NSString *line = [self logLines][_logIndex % [self logLines].count];
    _logIndex++;
    [_jailbreakBtn.logView showLog:line];
}

- (void)finishFlow {
    [_logTimer invalidate];
    _logTimer = nil;

    [_jailbreakBtn.logView finishWithText:@"Success"];
    [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeSuccess];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self openEnvironment];
    });
}

- (void)openEnvironment {
    _launched = YES;
    NSURL *url = [NSURL URLWithString:@"livecontainer://"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
        if (!success) {
            self.launched = NO;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:@"Nyxian did not respond. Try again."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (NSArray<NSString *> *)logLines {
    static NSArray<NSString *> *lines;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        lines = @[
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
            @"Handshake accepted",
            @"Finalizing launch",
        ];
    });
    return lines;
}

#pragma mark - Device

- (NSString *)machineIdentifier {
    char buffer[64];
    size_t size = sizeof(buffer);
    if (sysctlbyname("hw.machine", buffer, &size, NULL, 0) != 0) return @"iPhone";
    return [NSString stringWithUTF8String:buffer];
}

@end
