//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Segment.h"

#pragma mark - Functions

@interface Segment ()

@property (nonatomic) CMTimeRange timeRange;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, getter=isBlocked) BOOL blocked;
@property (nonatomic, getter=isHidden) BOOL hidden;
@property (nonatomic, nullable) NSDictionary *userInfo;

@end

@implementation Segment

#pragma mark Object lifecycle

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        self.name = dictionary[@"name"];
        self.identifier = dictionary[@"identifier"];
        self.blocked = [dictionary[@"blocked"] boolValue];
        self.hidden = [dictionary[@"hidden"] boolValue];
        self.userInfo = dictionary[@"userInfo"];
        
        NSTimeInterval startTime = [dictionary[@"startTime"] doubleValue] / 1000.;
        NSTimeInterval duration = [dictionary[@"duration"] doubleValue] / 1000.;
        
        self.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, NSEC_PER_SEC),
                                         CMTimeMakeWithSeconds(duration, NSEC_PER_SEC));
    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier name:(NSString *)name timeRange:(CMTimeRange)timeRange
{
    NSDictionary *dictionnary = @{@"name":name, @"startTime": @(CMTimeGetSeconds(self.timeRange.start)), @"duration": @(CMTimeGetSeconds(self.timeRange.duration))};
    self = [self initWithDictionary:dictionnary];
    return self;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithDictionary:@{}];
}

#pragma mark Getters and setters

- (NSURL *)thumbnailURL
{
    NSString *imageFilePath = [[NSBundle mainBundle] pathForResource:@"thumbnail-placeholder" ofType:@"png"];
    return [NSURL fileURLWithPath:imageFilePath];
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; start: %@; duration: %@; name: %@; blocked: %@; hidden: %@>",
            [self class],
            self,
            @(CMTimeGetSeconds(self.timeRange.start)),
            @(CMTimeGetSeconds(self.timeRange.duration)),
            self.name,
            self.blocked ? @"YES" : @"NO",
            self.hidden ? @"YES" : @"NO"];
}

@end
