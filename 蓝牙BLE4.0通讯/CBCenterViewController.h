//
//  CBCenterViewController.h
//  BluetoothTest
//
//  Created by Pro on 14-4-6.
//  Copyright (c) 2014年 Pro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BleFourCommunication.h"

@interface CBCenterViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UIScrollViewDelegate,BleFourCommunicationDelegate>

@property (nonatomic,strong) BleFourCommunication * ble;
@property (nonatomic,strong) UITextView *textView;
@property (nonatomic,strong) UIButton *connect;
@property (nonatomic,strong) UITableView *deviceTable;
@property (nonatomic,strong) UIActivityIndicatorView *activity;
@end
