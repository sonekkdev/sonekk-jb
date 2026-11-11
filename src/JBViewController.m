#import "JBViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <sys/sysctl.h>

static UIColor *SonekkGreen(void) { return [UIColor colorWithRed:0.20 green:0.95 blue:0.50 alpha:1.0]; }
static UIColor *SonekkCyan(void) { return [UIColor colorWithRed:0.22 green:0.80 blue:0.98 alpha:1.0]; }

@interface JBViewController ()
@property (nonatomic, strong) UILabel *deviceValue;
@property (nonatomic, strong) UILabel *systemValue;
@property (nonatomic, strong) UILabel *nyxianValue;
@end

@implementation JBViewController {
    CAGradientLayer *_topGlow;
    CAGradientLayer *_bottomGlow;
    CAShapeLayer *_haloLayer;
    CAShapeLayer *_trackLayer;
    CAShapeLayer *_ringLayer;
    UILabel *_ringLabel;
    UILabel *_captionLabel;
    BOOL _running;
}

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.030 green:0.040 blue:0.035 alpha:1.0];

    [self buildGlows];
    [self buildHeader];
    [self buildCard];
    [self buildRing];
    [self buildFootnote];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshStatus)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [self refreshStatus];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Build

- (void)buildGlows {
    _topGlow = [CAGradientLayer layer];
    _topGlow.type = kCAGradientLayerRadial;
    _topGlow.colors = @[
        (id)[SonekkGreen() colorWithAlphaComponent:0.34].CGColor,
        (id)[SonekkGreen() colorWithAlphaComponent:0.0].CGColor,
    ];
    _topGlow.locations = @[@0.0, @1.0];
    _topGlow.startPoint = CGPointMake(0.5, 0.5);
    _topGlow.endPoint = CGPointMake(1.0, 1.0);
    [self.view.layer insertSublayer:_topGlow atIndex:0];

    _bottomGlow = [CAGradientLayer layer];
    _bottomGlow.type = kCAGradientLayerRadial;
    _bottomGlow.colors = @[
        (id)[SonekkCyan() colorWithAlphaComponent:0.22].CGColor,
        (id)[SonekkCyan() colorWithAlphaComponent:0.0].CGColor,
    ];
    _bottomGlow.locations = @[@0.0, @1.0];
    _bottomGlow.startPoint = CGPointMake(0.5, 0.5);
    _bottomGlow.endPoint = CGPointMake(1.0, 1.0);
    [self.view.layer insertSublayer:_bottomGlow atIndex:1];
}

- (void)buildHeader {
    UILabel *title = [UILabel new];
    title.text = @"Sonekk JB";
    title.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBold];
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.tag = 101;
    [self.view addSubview:title];

    UILabel *subtitle = [UILabel new];
    subtitle.text = @"środowisko uruchomieniowe";
    subtitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    subtitle.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.45];
    subtitle.textAlignment = NSTextAlignmentCenter;
    subtitle.tag = 102;
    [self.view addSubview:subtitle];
}

- (void)buildCard {
    UIView *card = [UIView new];
    card.tag = 200;
    card.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.055];
    card.layer.cornerRadius = 24.0;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.09].CGColor;
    [self.view addSubview:card];

    _deviceValue = [self rowInCard:card title:@"Urządzenie" offset:22 index:0];
    _systemValue = [self rowInCard:card title:@"System" offset:70 index:1];
    _nyxianValue = [self rowInCard:card title:@"Nyxian Clean" offset:118 index:2];

    for (NSInteger i = 1; i < 3; i++) {
        UIView *separator = [UIView new];
        separator.tag = 300 + i;
        separator.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.07];
        [card addSubview:separator];
    }
}

- (UILabel *)rowInCard:(UIView *)card title:(NSString *)title offset:(CGFloat)offset index:(NSInteger)index {
    UILabel *name = [UILabel new];
    name.text = title;
    name.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    name.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.55];
    name.frame = CGRectMake(20, offset, 120, 22);
    name.tag = 210 + index;
    [card addSubview:name];

    UILabel *value = [UILabel new];
    value.text = @"—";
    value.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightSemibold];
    value.textColor = [UIColor whiteColor];
    value.textAlignment = NSTextAlignmentRight;
    value.tag = 220 + index;
    [card addSubview:value];
    return value;
}

- (void)buildRing {
    CGFloat size = 212.0;
    UIView *container = [UIView new];
    container.tag = 400;
    container.frame = CGRectMake(0, 0, size, size);
    [self.view addSubview:container];

    _haloLayer = [CAShapeLayer layer];
    _haloLayer.frame = container.bounds;
    _haloLayer.path = [self circlePathRadius:size * 0.5 inRect:container.bounds].CGPath;
    _haloLayer.fillColor = [SonekkGreen() colorWithAlphaComponent:0.12].CGColor;
    _haloLayer.strokeColor = [UIColor clearColor].CGColor;
    [container.layer addSublayer:_haloLayer];

    _trackLayer = [CAShapeLayer layer];
    _trackLayer.frame = container.bounds;
    _trackLayer.path = [self circlePathRadius:size * 0.5 - 26 inRect:container.bounds].CGPath;
    _trackLayer.fillColor = [UIColor clearColor].CGColor;
    _trackLayer.strokeColor = [[UIColor whiteColor] colorWithAlphaComponent:0.10].CGColor;
    _trackLayer.lineWidth = 7.0;
    _trackLayer.lineCap = kCALineCapRound;
    [container.layer addSublayer:_trackLayer];

    _ringLayer = [CAShapeLayer layer];
    _ringLayer.frame = container.bounds;
    _ringLayer.path = _trackLayer.path;
    _ringLayer.fillColor = [UIColor clearColor].CGColor;
    _ringLayer.strokeColor = SonekkGreen().CGColor;
    _ringLayer.lineWidth = 7.0;
    _ringLayer.lineCap = kCALineCapRound;
    _ringLayer.strokeEnd = 0.0;
    _ringLayer.shadowColor = SonekkGreen().CGColor;
    _ringLayer.shadowRadius = 10.0;
    _ringLayer.shadowOpacity = 0.8;
    _ringLayer.shadowOffset = CGSizeZero;
    _ringLayer.transform = CATransform3DMakeRotation(-M_PI_2, 0, 0, 1);
    [container.layer addSublayer:_ringLayer];

    _ringLabel = [UILabel new];
    _ringLabel.text = @"Jailbreak";
    _ringLabel.font = [UIFont systemFontOfSize:21 weight:UIFontWeightBold];
    _ringLabel.textColor = [UIColor whiteColor];
    _ringLabel.textAlignment = NSTextAlignmentCenter;
    _ringLabel.frame = container.bounds;
    [container addSubview:_ringLabel];

    UIControl *tap = [[UIControl alloc] initWithFrame:container.bounds];
    tap.tag = 401;
    [tap addTarget:self action:@selector(startFlow) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:tap];

    _captionLabel = [UILabel new];
    _captionLabel.text = @"Uruchamia Nyxian Clean";
    _captionLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    _captionLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.40];
    _captionLabel.textAlignment = NSTextAlignmentCenter;
    _captionLabel.tag = 402;
    [self.view addSubview:_captionLabel];
}

- (UIBezierPath *)circlePathRadius:(CGFloat)radius inRect:(CGRect)rect {
    return [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))
                                          radius:radius - 10.0
                                      startAngle:0
                                        endAngle:(CGFloat)(2.0 * M_PI)
                                       clockwise:YES];
}

- (void)buildFootnote {
    UILabel *note = [UILabel new];
    note.text = @"To nie jest jailbreak systemu — iOS 27 nie ma publicznego jailbreaka.\nSonekk JB przygotowuje środowisko i otwiera Nyxian Clean.";
    note.numberOfLines = 0;
    note.font = [UIFont systemFontOfSize:10 weight:UIFontWeightRegular];
    note.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.28];
    note.textAlignment = NSTextAlignmentCenter;
    note.tag = 500;
    [self.view addSubview:note];

    UILabel *version = [UILabel new];
    version.text = @"1.0";
    version.font = [UIFont monospacedSystemFontOfSize:9 weight:UIFontWeightMedium];
    version.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.20];
    version.textAlignment = NSTextAlignmentCenter;
    version.tag = 501;
    [self.view addSubview:version];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGRect bounds = self.view.bounds;
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);
    CGFloat top = self.view.safeAreaInsets.top;
    CGFloat bottom = self.view.safeAreaInsets.bottom;

    _topGlow.frame = CGRectMake(-140, -180, 460, 460);
    _bottomGlow.frame = CGRectMake(width - 260, height - 300, 420, 420);

    UILabel *title = [self.view viewWithTag:101];
    title.frame = CGRectMake(24, top + 26, width - 48, 42);

    UILabel *subtitle = [self.view viewWithTag:102];
    subtitle.frame = CGRectMake(24, top + 66, width - 48, 20);

    UIView *card = [self.view viewWithTag:200];
    CGFloat cardTop = top + 108;
    card.frame = CGRectMake(24, cardTop, width - 48, 158);

    CGFloat cardWidth = CGRectGetWidth(card.bounds);
    for (NSInteger i = 0; i < 3; i++) {
        UILabel *value = [card viewWithTag:220 + i];
        value.frame = CGRectMake(cardWidth - 20 - 180, 22 + i * 48, 180, 22);
        UIView *separator = [card viewWithTag:301 + i];
        separator.frame = CGRectMake(20, 62 + i * 48, cardWidth - 40, 0.5);
    }

    UIView *container = [self.view viewWithTag:400];
    CGFloat size = 212;
    CGFloat centerY = cardTop + 158 + 40 + size * 0.5;
    container.frame = CGRectMake((width - size) * 0.5, centerY - size * 0.5, size, size);

    _captionLabel.frame = CGRectMake(24, CGRectGetMaxY(container.frame) + 10, width - 48, 18);

    UILabel *version = [self.view viewWithTag:501];
    version.frame = CGRectMake(24, height - bottom - 26, width - 48, 14);

    UILabel *note = [self.view viewWithTag:500];
    note.frame = CGRectMake(28, CGRectGetMinY(version.frame) - 46, width - 56, 40);
}

#pragma mark - Status

- (void)refreshStatus {
    UIDevice *device = [UIDevice currentDevice];
    _deviceValue.text = [self machineIdentifier];
    _systemValue.text = [NSString stringWithFormat:@"iOS %@", device.systemVersion];

    BOOL hasNyxian = [self canOpen:@"livecontainer://"];
    _nyxianValue.text = hasNyxian ? @"gotowy" : @"brak";
    _nyxianValue.textColor = hasNyxian ? SonekkGreen() : [UIColor colorWithRed:1.0 green:0.45 blue:0.40 alpha:1.0];
}

- (NSString *)machineIdentifier {
    char buffer[64];
    size_t size = sizeof(buffer);
    if (sysctlbyname("hw.machine", buffer, &size, NULL, 0) != 0) return @"iPhone";
    return [NSString stringWithUTF8String:buffer];
}

- (BOOL)canOpen:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    return [[UIApplication sharedApplication] canOpenURL:url];
}

#pragma mark - Flow

- (void)startFlow {
    if (_running) return;
    _running = YES;

    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    _ringLabel.text = @"Sprawdzam";

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _ringLayer.strokeEnd = 1.0;
    [CATransaction commit];

    CABasicAnimation *fill = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    fill.fromValue = @0.0;
    fill.toValue = @1.0;
    fill.duration = 1.35;
    fill.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_ringLayer addAnimation:fill forKey:@"fill"];

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf->_ringLabel.text = @"Łączę";
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.95 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf->_ringLabel.text = @"Gotowe";
        [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeSuccess];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf openEnvironment];
    });
}

- (void)openEnvironment {
    NSURL *url = [NSURL URLWithString:@"livecontainer://"];
    if (![[UIApplication sharedApplication] canOpenURL:url]) {
        [self failedWithMessage:@"Nie znaleziono Nyxian Clean. Zainstaluj go tym samym certyfikatem."];
        return;
    }
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self resetFlow];
            if (!success) {
                [self failedWithMessage:@"Nyxian nie odpowiedział. Spróbuj ponownie."];
            } else {
                [self refreshStatus];
            }
        });
    }];
}

- (void)failedWithMessage:(NSString *)message {
    [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeError];
    [self resetFlow];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Nie udało się"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetFlow {
    _running = NO;
    _ringLabel.text = @"Jailbreak";

    CABasicAnimation *drain = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    drain.fromValue = @1.0;
    drain.toValue = @0.0;
    drain.duration = 0.35;
    drain.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [_ringLayer addAnimation:drain forKey:@"drain"];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _ringLayer.strokeEnd = 0.0;
    [CATransaction commit];
}

@end
