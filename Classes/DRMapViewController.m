//
//  DRMapViewController.m
//  DragonRador
//
//  Created by mootoh on 5/24/09.
//  Copyright 2009 deadbeaf.org. All rights reserved.
//
#import <MapKit/MapKit.h>
#import "DRMapViewController.h"
#import "UICUserLocation.h"
#import "SettingViewController.h"
#import "DragonRador.h"
#import "FriendsPickViewController.h"
#import "AppDelegate.h"
#import "MySelf.h"

@interface DRMapViewController (Private)
- (void) setupNetwork;
- (void) setupDummies;
@end

@implementation DRMapViewController
@synthesize map_view;

- (void) dealloc
{
   [location_manager dealloc];
   [super dealloc];
}

- (void) viewDidLoad
{
   [super viewDidLoad];

   const MKCoordinateRegion initial_region = {
#ifdef TARGET_IPHONE_SIMULATOR
      {35.697944f, 139.414398f},
#else // TARGET_IPHONE_SIMULATOR
      {map_view.userLocation.location.coordinate.latitude, map_view.userLocation.location.coordinate.longitude},
#endif // TARGET_IPHONE_SIMULATOR
      {0.1f, 0.1f}};
   map_view.region = initial_region;

   [self setupNetwork];

#if 0
   // friends
   NSArray *saved_friends = [[NSUserDefaults standardUserDefaults] arrayForKey:DR_FRIENDS];
   NSArray *friends_names = saved_friends ? saved_friends : [NSMutableArray array];

   friends = [[NSMutableArray array] retain];

   for (NSString *friend_name in friends_names) {
      CLLocation *loc = [[CLLocation alloc] initWithLatitude:35.697944f longitude:139.414398f];
      UICUserLocation *ul = [[UICUserLocation alloc] initWithFrame:CGRectMake(32, 32, 16, 16) location:loc];
      ul.user_name = friend_name;
      [self.view addSubview:ul];
      [friends addObject:ul];
      [ul release];
   }
#endif // 0

   location_manager = [[CLLocationManager alloc] init];
   location_manager.delegate = self;
}

- (void) updateAll
{
   [UIView beginAnimations:nil context:NULL]; {
      [UIView setAnimationDuration:0.20f];
      [UIView setAnimationDelegate:self];

#if 0
      for (UICUserLocation *ul in friends) {
         CGPoint pt = [map_view convertCoordinate:ul.location.coordinate toPointToView:nil];
         ul.center = pt;
      }
#endif // 0
   } [UIView commitAnimations];
}

#pragma mark MapKit delegates

- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView
{
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
   //NSLog(@"mapView:mapView regionWillChangeAnimated: region = {lat => %f, long => %f}, span = {lat => %f, long => %f}, animated=%d", mapView.region.center.latitude, mapView.region.center.longitude, mapView.region.span.latitudeDelta, mapView.region.span.longitudeDelta, animated);

   //CGPoint pt = [mapView convertCoordinate:other_user_location.coordinate toPointToView:nil];
   //other_user_location.center = pt;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
   [self updateAll];
}

#pragma mark IBActions

- (IBAction) goHome
{
   const MKCoordinateRegion my_home = {{35.697944f, 139.414398f}, {0.017914f, 0.018021f}};
   [self.map_view setRegion:my_home];
}

- (IBAction) moveOther
{
   /*
   CLLocation *cur = other_user_location.location;
   CLLocation *nxt = [[CLLocation alloc] initWithLatitude:cur.coordinate.latitude + 0.1f longitude:cur.coordinate.longitude + 0.1f];
   [other_user_location updateLocation:nxt];
   [nxt release];

   [self updateAll];
   */
}

- (IBAction) openSettings
{
   SettingViewController *svc = [[SettingViewController alloc] initWithNibName:nil bundle:nil];
   UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:svc];
   [self presentModalViewController:nc animated:YES];
   [nc release];
   [svc release];
}

- (IBAction) pickFriends
{
   FriendsPickViewController *fpvc = [[FriendsPickViewController alloc] initWithNibName:nil bundle:nil];
   UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:fpvc];
   [self presentModalViewController:nc animated:YES];
   [nc release];
   [fpvc release];
}

#pragma mark Network

- (void) setupNetwork
{
}

- (void) updateMyLocation
{
   NSDictionary *current_my_info = [[NSUserDefaults standardUserDefaults] dictionaryForKey:DR_MY_LOCATION];
   // Timestamp
   NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
   [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
   [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
   NSDate *timestamp_date = [current_my_info objectForKey:@"timestamp"];
   NSString *timestamp = [dateFormatter stringFromDate:timestamp_date];

   NSLog(@"lat=%f, long=%f, timestamp=%@",
      [[current_my_info objectForKey:@"latitude"] floatValue],
      [[current_my_info objectForKey:@"longitude"] floatValue],
      timestamp);

   NSString *post_str = [NSString stringWithFormat:@"name=%@&location=(%f,%f)&timestamp=%@",
      [[NSUserDefaults standardUserDefaults] stringForKey:DR_TWITTER_USER],
      [[current_my_info objectForKey:@"latitude"] floatValue],
      [[current_my_info objectForKey:@"longitude"] floatValue],
      timestamp];

   NSData *post_data = [post_str dataUsingEncoding:NSASCIIStringEncoding];

   NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/update", LOCATION_SERVER]]];
   [req setHTTPMethod:@"POST"];
   [req setHTTPBody:post_data];

   NSURLResponse *res = nil;
   NSError *err = nil;
   [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
   if (err) {
      NSLog(@"error: %@", [err localizedDescription]);
   }
}

#pragma CLLocationManager

- (IBAction) showCurrentLocation
{
   [location_manager startUpdatingLocation];
}

// Called when the location is updated
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
   AppDelegate *app = [[UIApplication sharedApplication] delegate];
   [app.my_self sendCurrentLocation:newLocation];
}

/*
// Called when there is an error getting the location
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
}
*/
@end
