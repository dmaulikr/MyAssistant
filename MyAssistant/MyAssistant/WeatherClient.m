//
//  WeatherClient.m
//  MyAssistant
//
//  Created by Jiaxiang Li on 11/5/15.
//  Copyright © 2015 Jiaxiang Li. All rights reserved.
//

#import "WeatherClient.h"
#import "WeatherCondition.h"
#import "WeatherDailyForcast.h"
#import "WeatherManager.h"
#import "OWMWeatherAPI.h"
#import "WeatherManagerDelegate.h"
#import <CoreLocation/CoreLocation.h>

@interface WeatherClient() {
    CLLocationCoordinate2D currentCoordinate;
    OWMWeatherAPI *weatherAPI;
    NSMutableArray *arrayHourly;
    NSMutableArray *arrayDaily;
}

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) WeatherCondition  *currentCondition;
@property (nonatomic,strong) WeatherManager *manager;


@end

@implementation WeatherClient


-(void)passLocationToClient:(CLLocation *)location {
    currentCoordinate = location.coordinate;
    
    
    [self configureData];
    [self getWeatherByCoordinate:currentCoordinate];
    NSLog(@"%@",location);
    
}

-(void) passCityNameToClient:(NSString *)cityName {
    [self configureData];
    
    CLGeocoder *gecoder = [[CLGeocoder alloc] init];
    
    [gecoder geocodeAddressString:cityName completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (placemarks.count > 0) {
            CLPlacemark *placemark = [placemarks firstObject];
            CLLocationCoordinate2D coordinate = placemark.location.coordinate;
            [self getWeatherByCoordinate:coordinate];
        }else {
            NSLog(@"Gecoder Error:%@",[error localizedDescription]);
        }
    }];
    
}

-(void) configureData {
    weatherAPI = [[OWMWeatherAPI alloc] initWithAPIKey:@"e40fd6f9191b29b575b0f77a9ce44bf6"];
    [weatherAPI setTemperatureFormat:kOWMTempCelcius];
    self.manager = [[WeatherManager alloc] init];
    self.manager.delegate = self;
    
    self.currentCondition = [[WeatherCondition alloc] init];
    arrayDaily = [[NSMutableArray alloc] initWithCapacity:10];
    arrayHourly = [[NSMutableArray alloc] initWithCapacity:10];
    
}






-(void) getWeatherByCoordinate:(CLLocationCoordinate2D) coordinate {
    
    
    [weatherAPI currentWeatherByCoordinate:coordinate withCallback:^(NSError *error, NSDictionary *result) {
        self.currentCondition.locationName = result[@"name"];
        self.currentCondition.temperature = result[@"main"][@"temp"];
        NSString *key = result[@"weather"][0][@"icon"];
        self.currentCondition.icon = [self.currentCondition imageName:key];
        self.currentCondition.condition = result[@"weather"][0][@"description"];
        self.currentCondition.tempHigh = result[@"main"][@"temp_max"];
        self.currentCondition.tempLow = result[@"main"][@"temp_min"];
        self.currentCondition.humidity = result[@"main"][@"humidity"];
        [self.delegate passWeatherConditonToViewController:self.currentCondition];
        NSLog(@"CityName:%@",self.currentCondition.locationName);
    }];
    
    [weatherAPI dailyForecastWeatherByCoordinate:coordinate withCount:6 andCallback:^(NSError *error, NSDictionary *result) {
        for (int i = 0; i< 6; i++) {
            WeatherCondition *condition = [[WeatherCondition alloc] init];
            condition.tempHigh = result[@"list"][i][@"temp"][@"max"];
            condition.tempLow = result[@"list"][i][@"temp"][@"min"];
            condition.date = result[@"list"][i][@"dt"];
            condition.condition = result[@"list"][i][@"weather"][0][@"description"];
            NSString *key = result[@"list"][i][@"weather"][0][@"icon"];
            condition.icon = [condition imageName:key];
            [arrayDaily addObject:condition];
        }
        
        [self.delegate passDailyForcastToViewController:arrayDaily];
        [arrayDaily removeAllObjects];
    }];
    
    
    [weatherAPI forecastWeatherByCoordinate:coordinate withCallback:^(NSError *error, NSDictionary *result) {
        //NSLog(@"%@",result);
        for (int i = 0; i < 6 ;i++) {
            WeatherCondition *condition = [[WeatherCondition alloc] init];
            condition.date = result[@"list"][i][@"dt"];
            condition.temperature = result[@"list"][i][@"main"][@"temp"];
            NSString *key = result[@"list"][i][@"weather"][0][@"icon"];
            condition.icon = [condition imageName:key];
            [arrayHourly addObject:condition];
        }
        
        [self.delegate passHourlyForcastToViewController:arrayHourly];
        [arrayHourly removeAllObjects];
    }];
}



@end
