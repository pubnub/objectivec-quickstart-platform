//
//  TableViewController.m
//  pnqs_ios_objectivec
//
//  Created by pubnubcvconover on 5/11/20.
//  Copyright © 2020 PubNub. All rights reserved.
//

#import "TableViewController.h"
#import <PubNub/PubNub.h>

#pragma mark Statics

static NSString * const kUpdateCellIdentifier = @"cellIdentifier";
static NSString * const kUpdateEntryMessage = @"entryMessage";
static NSString * const kUpdateEntryType = @"entryType";
static NSString * const kChannelGuide = @"the_guide";
static NSString * const kEntryEarth = @"Earth";

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Private interface declaration

@interface TableViewController () <UITextFieldDelegate, PNObjectEventListener>

@property (nonatomic, strong) PubNub *pubnub;
@property (nonatomic, weak) IBOutlet UIView *updateInputHolderView;
@property (nonatomic, weak) IBOutlet UITextField *entryUpdateText;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *messages;

#pragma mark -

@end

NS_ASSUME_NONNULL_END

#pragma mark - Interface implementation

@implementation TableViewController

#pragma mark - Controller & view life cycle

- (void)awakeFromNib {
    [super awakeFromNib];

    // replace the key placeholders with your own PubNub publish and subscribe keys
    PNConfiguration *pnconfig = [PNConfiguration configurationWithPublishKey:@"myPublishKey"
                                                                subscribeKey:@"mySubscribeKey"];
    pnconfig.uuid = @"theClientUUID";
    self.pubnub = [PubNub clientWithConfiguration:pnconfig];

    [self.pubnub addListener:self];
    [self.pubnub subscribeToChannels: @[kChannelGuide] withPresence:YES];

    self.messages = [NSMutableArray new];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Adjust table view content inset under translucent status bar
    UIWindowScene *windowScene = UIApplication.sharedApplication.windows[0].windowScene;
    CGFloat statusBarHeight = windowScene.statusBarManager.statusBarFrame.size.height;
    self.tableView.contentInset = UIEdgeInsetsMake(-statusBarHeight, 0.0f, 0.0f, 0.0f);
}

#pragma mark - Updates sending

- (void)submitUpdate:(NSString *)update forEntry:(NSString *)entry toChannel:(NSString *)channel {
    [self.pubnub publish: @{ @"entry": entry, @"update": update } toChannel:kChannelGuide
          withCompletion:^(PNPublishStatus *status) {

        NSString *text = [@"timetoken: " stringByAppendingString:status.data.timetoken.stringValue];
        [self displayMessage:text asType:@"[PUBLISH: sent]"];
    }];
}

- (void)displayMessage:(NSString *)message asType:(NSString *)type {
    NSDictionary *updateEntry = @{ kUpdateEntryType: type, kUpdateEntryMessage: message };
    [self.messages insertObject:updateEntry atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];

    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationBottom];

    [self.tableView endUpdates];
}

- (IBAction)sendButtonTapped:(id)sender {
    NSLog(@"Button Pressed");

    if (self.entryUpdateText.text.length > 0) {
        [self submitUpdate:self.entryUpdateText.text forEntry:kEntryEarth toChannel:kChannelGuide];
        self.entryUpdateText.text = nil;
    }
    else {
        NSLog(@"Message field is empty.");
    }

    [self.entryUpdateText resignFirstResponder];
}

#pragma mark - PubNub event listeners

- (void)client:(PubNub *)pubnub didReceiveMessage:(PNMessageResult *)event {
    NSString *text = [NSString stringWithFormat:@"entry: %@, update: %@",
                      event.data.message[@"entry"],
                      event.data.message[@"update"]];

    [self displayMessage:text asType:@"[MESSAGE: received]"];
}

- (void)client:(PubNub *)pubnub didReceivePresenceEvent:(PNPresenceEventResult *)event {
    NSString *text = [NSString stringWithFormat:@"event uuid: %@, channel: %@",
                      event.data.presence.uuid,
                      event.data.channel];

    NSString *type = [NSString stringWithFormat:@"[PRESENCE: %@]", event.data.presenceEvent];
    [self displayMessage:text asType: type];
}

- (void)client:(PubNub *)pubnub didReceiveStatus:(PNStatus *)event {
    NSString *text = [NSString stringWithFormat:@"status: %@", event.stringifiedCategory];

    [self displayMessage:text asType:@"[STATUS: connection]"];
    [self submitUpdate:@"Harmless." forEntry:kEntryEarth toChannel:kChannelGuide];
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendButtonTapped:nil];
    return YES;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return self.updateInputHolderView.frame.size.height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return self.updateInputHolderView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *updateEntry = [self.messages objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = updateEntry[kUpdateEntryMessage];
    cell.textLabel.text = updateEntry[kUpdateEntryType];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:kUpdateCellIdentifier];
}

#pragma mark -

@end
