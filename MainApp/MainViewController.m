#import "MainViewController.h"
#import <sys/utsname.h>
#import <sys/stat.h>
#import <dlfcn.h>
#import <mach/mach.h>

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *infoData;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"iOS Internals & Info";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    [self loadDeviceInfo];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}

- (void)loadDeviceInfo {
    self.infoData = [NSMutableArray array];
    
    // 1. OS Version
    NSString *iosVersion = [[UIDevice currentDevice] systemVersion];
    NSString *sysName = [[UIDevice currentDevice] systemName];
    [self.infoData addObject:@{@"title": @"OS Version", @"value": [NSString stringWithFormat:@"%@ %@", sysName, iosVersion]}];
    
    // 2. Device Model
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *internalModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSString *marketingName = [self marketingNameForIdentifier:internalModel];
    [self.infoData addObject:@{@"title": @"Device Model", @"value": [NSString stringWithFormat:@"%@ (%@)", marketingName, internalModel]}];
    
    // 3. Jailbroken Status
    BOOL isJB = [self checkIsJailbroken];
    [self.infoData addObject:@{@"title": @"Jailbroken", @"value": isJB ? @"Yes (Jailbroken)" : @"No (Jailed)"}];
    
    // 4. Hardware UDID (IOPlatformUUID)
    NSString *realUDID = [self fetchHardwareUDID];
    [self.infoData addObject:@{@"title": @"Hardware UDID", @"value": realUDID}];
    
    // 5. Common UDID (Legacy / Classic format style)
    NSString *commonUDID = [self fetchCommonUDID];
    [self.infoData addObject:@{@"title": @"Common UDID", @"value": commonUDID}];
    
    // 6. Vendor ID (IDFV)
    NSUUID *vendorID = [[UIDevice currentDevice] identifierForVendor];
    NSString *idfvStr = vendorID ? [vendorID UUIDString] : @"Unavailable";
    [self.infoData addObject:@{@"title": @"Vendor ID (IDFV)", @"value": idfvStr}];
    
    // 7. JIT Status
    BOOL jitAvailable = [self checkJITAvailability];
    [self.infoData addObject:@{@"title": @"JIT Status", @"value": jitAvailable ? @"Available / Supported" : @"Not Available"}];
}

- (NSString *)marketingNameForIdentifier:(NSString *)identifier {
    NSDictionary *mapping = @{
    // iPhone SE Series
    @"iPhone12,8": @"iPhone SE (2nd gen)",
    @"iPhone14,6": @"iPhone SE (3rd gen)",
    
    // iPhone 12 Series
    @"iPhone13,1": @"iPhone 12 mini",
    @"iPhone13,2": @"iPhone 12",
    @"iPhone13,3": @"iPhone 12 Pro",
    @"iPhone13,4": @"iPhone 12 Pro Max",
    
    // iPhone 13 Series
    @"iPhone14,4": @"iPhone 13 mini",
    @"iPhone14,5": @"iPhone 13",
    @"iPhone14,2": @"iPhone 13 Pro",
    @"iPhone14,3": @"iPhone 13 Pro Max",
    
    // iPhone 14 Series
    @"iPhone14,7": @"iPhone 14",
    @"iPhone14,8": @"iPhone 14 Plus",
    @"iPhone15,2": @"iPhone 14 Pro",
    @"iPhone15,3": @"iPhone 14 Pro Max",
    
    // iPhone 15 Series
    @"iPhone15,4": @"iPhone 15",
    @"iPhone15,5": @"iPhone 15 Plus",
    @"iPhone16,1": @"iPhone 15 Pro",
    @"iPhone16,2": @"iPhone 15 Pro Max",
    
    // iPhone 16 Series
    @"iPhone17,3": @"iPhone 16",
    @"iPhone17,4": @"iPhone 16 Plus",
    @"iPhone17,1": @"iPhone 16 Pro",
    @"iPhone17,2": @"iPhone 16 Pro Max",
    @"iPhone17,5": @"iPhone 16e",
    
    // iPhone 17 Series
    @"iPhone18,3": @"iPhone 17",
    @"iPhone18,5": @"iPhone 17e",
    @"iPhone18,4": @"iPhone Air",
    @"iPhone18,1": @"iPhone 17 Pro",
    @"iPhone18,2": @"iPhone 17 Pro Max",

    // iPad Series
    @"iPad11,6": @"iPad (8th gen) Wi-Fi",
    @"iPad11,7": @"iPad (8th gen) Cellular",
    @"iPad12,1": @"iPad (9th gen) Wi-Fi",
    @"iPad12,2": @"iPad (9th gen) Cellular",
    @"iPad13,18": @"iPad (10th gen) Wi-Fi",
    @"iPad13,19": @"iPad (10th gen) Cellular",

    // iPad mini Series
    @"iPad11,1": @"iPad mini (5th gen) Wi-Fi",
    @"iPad11,2": @"iPad mini (5th gen) Cellular",
    @"iPad14,1": @"iPad mini (6th gen) Wi-Fi",
    @"iPad14,2": @"iPad mini (6th gen) Cellular",
    @"iPad16,1": @"iPad mini (7th gen) Wi-Fi",
    @"iPad16,2": @"iPad mini (7th gen) Cellular",

    // iPad Air Series
    @"iPad11,3": @"iPad Air (3rd gen) Wi-Fi",
    @"iPad11,4": @"iPad Air (3rd gen) Cellular",
    @"iPad13,1": @"iPad Air (4th gen) Wi-Fi",
    @"iPad13,2": @"iPad Air (4th gen) Cellular",
    @"iPad13,16": @"iPad Air (5th gen) Wi-Fi",
    @"iPad13,17": @"iPad Air (5th gen) Cellular",
    @"iPad14,8": @"iPad Air 11-inch (M2) Wi-Fi",
    @"iPad14,9": @"iPad Air 11-inch (M2) Cellular",
    @"iPad14,10": @"iPad Air 13-inch (M2) Wi-Fi",
    @"iPad14,11": @"iPad Air 13-inch (M2) Cellular",

    // iPad Pro Series
    @"iPad8,1": @"iPad Pro 11-inch (1st gen) Wi-Fi",
    @"iPad8,2": @"iPad Pro 11-inch (1st gen) Wi-Fi (1TB)",
    @"iPad8,3": @"iPad Pro 11-inch (1st gen) Cellular",
    @"iPad8,4": @"iPad Pro 11-inch (1st gen) Cellular (1TB)",
    @"iPad8,5": @"iPad Pro 12.9-inch (3rd gen) Wi-Fi",
    @"iPad8,6": @"iPad Pro 12.9-inch (3rd gen) Wi-Fi (1TB)",
    @"iPad8,7": @"iPad Pro 12.9-inch (3rd gen) Cellular",
    @"iPad8,8": @"iPad Pro 12.9-inch (3rd gen) Cellular (1TB)",
    @"iPad8,9": @"iPad Pro 11-inch (2nd gen) Wi-Fi",
    @"iPad8,10": @"iPad Pro 11-inch (2nd gen) Cellular",
    @"iPad8,11": @"iPad Pro 12.9-inch (4th gen) Wi-Fi",
    @"iPad8,12": @"iPad Pro 12.9-inch (4th gen) Cellular",
    @"iPad13,4": @"iPad Pro 11-inch (3rd gen) Wi-Fi",
    @"iPad13,5": @"iPad Pro 11-inch (3rd gen) Wi-Fi (16GB RAM)",
    @"iPad13,6": @"iPad Pro 11-inch (3rd gen) Cellular",
    @"iPad13,7": @"iPad Pro 11-inch (3rd gen) Cellular (16GB RAM)",
    @"iPad13,8": @"iPad Pro 12.9-inch (5th gen) Wi-Fi",
    @"iPad13,9": @"iPad Pro 12.9-inch (5th gen) Wi-Fi (16GB RAM)",
    @"iPad13,10": @"iPad Pro 12.9-inch (5th gen) Cellular",
    @"iPad13,11": @"iPad Pro 12.9-inch (5th gen) Cellular (16GB RAM)",
    @"iPad14,3": @"iPad Pro 11-inch (4th gen) Wi-Fi",
    @"iPad14,4": @"iPad Pro 11-inch (4th gen) Cellular",
    @"iPad14,5": @"iPad Pro 12.9-inch (6th gen) Wi-Fi",
    @"iPad14,6": @"iPad Pro 12.9-inch (6th gen) Cellular",
    @"iPad16,3": @"iPad Pro 11-inch (M4) Wi-Fi",
    @"iPad16,4": @"iPad Pro 11-inch (M4) Cellular",
    @"iPad16,5": @"iPad Pro 13-inch (M4) Wi-Fi",
    @"iPad16,6": @"iPad Pro 13-inch (M4) Cellular",

    // Simulator Enviroments
    @"x86_64":     @"iOS Simulator",
    @"arm64":      @"iOS Simulator"
};

return mapping[identifier] ?: identifier;
}

- (NSString *)fetchHardwareUDID {
#if TARGET_IPHONE_SIMULATOR
    return @"Simulator UDID";
#else
    // Query IOKit registry for the unique device ID
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
    if (!platformExpert) {
        return @"Unavailable";
    }
    
    CFStringRef serialNumberAsCFString = (CFStringRef)IORegistryEntryCreateCFProperty(platformExpert, CFSTR("IOPlatformUUID"), kCFAllocatorDefault, 0);
    IOObjectRelease(platformExpert);
    
    if (!serialNumberAsCFString) {
        return @"Unavailable";
    }
    
    NSString *udid = (__bridge NSString *)serialNumberAsCFString;
    CFRelease(serialNumberAsCFString);
    return udid;
#endif
}

- (NSString *)fetchCommonUDID {
#if TARGET_IPHONE_SIMULATOR
    return "Simulator-UDID";
#else
    // Call MobileGestalt with the UniqueDeviceID key
    CFStringRef udidRef = (CFStringRef)MGCopyAnswer(CFSTR("UniqueDeviceID"));
    if (udidRef) {
        NSString *udid = (__bridge NSString *)udidRef;
        // Depending on ARC and CoreFoundation rules, make a copy and release the ref
        NSString *result = [udid copy];
        CFRelease(udidRef);
        return result;
    }
    return @"Unavailable";
#endif
}

- (BOOL)checkIsJailbroken {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    // 1. Check for rootless bootstrap symlink / indicator
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/jb"]) {
        return YES;
    }
    
    // 2. Legacy jailbreak paths fallback
    NSArray *jailbreakFiles = @[
        @"/Applications/Sileo.app",
        @"/Applications/Zebra.app",
        @"/usr/bin/sileo",
        @"/usr/bin/apt",
        @"/jb/lzma"
    ]; // idk i know this is useless but idk lol 
    
    for (NSString *path in jailbreakFiles) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            return YES;
        }
    }
    
    // 3. Check if app can query or open URL schemes typical of jailbreak managers
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"sileo://"]]) {
        return YES;
    }
    
    return NO;
#endif
}

- (BOOL)checkJITAvailability {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    vm_address_t address = 0;
    vm_size_t size = vm_page_size;
    
    kern_return_t kr = vm_allocate(mach_task_self(), &address, size, VM_FLAGS_ANYWHERE);
    if (kr != KERN_SUCCESS) {
        return NO;
    }
    
    // test permission
    kr = vm_protect(mach_task_self(), address, size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
    
    // astra vista
    vm_deallocate(mach_task_self(), address, size);
    
    return (kr == KERN_SUCCESS);
#endif
}

// old shit
/*
- (NSString *)fetchUDIDEquivalent {
    // Apple strictly sandboxes hardware UDID on modern iOS. 
    // UIDevice identifierForVendor is the standard proxy for app-specific unique hardware representation.
    NSUUID *vendorID = [[UIDevice currentDevice] identifierForVendor];
    return vendorID ? [vendorID UUIDString] : @"Unavailable";
}
*/

#pragma mark - UITableViewDelegate

- (nullable UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    return nil;
}

// Enable long-press context menu on rows
- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
    NSDictionary *dict = self.infoData[indexPath.row];
    NSString *valueToCopy = dict[@"value"];
    
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        
        UIAction *copyAction = [UIAction actionWithTitle:@"Copy Value" 
                                                   image:[UIImage systemImageNamed:@"doc.on.doc"] 
                                              identifier:nil 
                                                 handler:^(__kindof UIAction * _Nonnull action) {
            // Copy the text to the iOS Clipboard
            [UIPasteboard generalPasteboard].string = valueToCopy;
            
            // Optional: Show a quick feedback toast or haptic
            UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
            [generator impactOccurred];
        }];
        
        return [UIMenu menuWithTitle:@"" children:@[copyAction]];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.infoData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *dict = self.infoData[indexPath.row];
    cell.textLabel.text = dict[@"title"];
    cell.detailTextLabel.text = dict[@"value"];
    cell.selectionStyle = UITableViewCellSelectionStyleGray; // Gives visual feedback when tapped/held
    
    return cell;
}

@end
