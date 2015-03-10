//
//  CBCenterViewController.m
//  BluetoothTest
//
//  Created by Pro on 14-4-6.
//  Copyright (c) 2014年 Pro. All rights reserved.
//

#import "CBCenterViewController.h"

/**
 glslp\n   //血糖仪休眠
 gliap\n   //插入试纸
 glsai\n   //请取血测量
 glwsb\n   //正在检测，请等待
 glesb\n   //电极损坏或提前进样
 glbne\n   //电量不足
 glerr\n   //检测出错
 glbhu\n   //血糖值高于测量上限
 glbul\n   //血糖值低于测量下限
 检测出的血糖值返回格式为：glnXX\n
 glnXXtr\n   //数组第3、4个元素储存血糖值
 glnXXtr[3]=Cmx10/256;   Cmx10 是血糖值结果
 glnXXtr[4]=Cmx10%256;
 */

//NSString * str = @"glplk";
//[self updateLog:[NSString stringWithFormat:@"%@:%@",@"发送数据",str]];
//NSData * data = [str dataUsingEncoding:NSUTF8StringEncoding];
//[self.ble sendMsgWithData:data];

//if([value hasPrefix:@"gln"])
//{
//    const unsigned char * hexBytesLight = [characteristic.value bytes];
//    float sugarValue = (hexBytesLight[3] * 256 + hexBytesLight[4])/10.0;
//    [self updateLog:[NSString stringWithFormat:@"接收血糖数据:%.1f",sugarValue]];
//}


#define kDeviceHeight [UIScreen mainScreen].bounds.size.height
#define kDeviceWidth  [UIScreen mainScreen].bounds.size.width
//#define kWriteString @"2AF1"
//#define kReadString @"2AF0"

#define kWriteString @"FFF2"
#define kReadString @"FFF1"



@interface CBCenterViewController ()
@end

@implementation CBCenterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"蓝牙连接";
    }
    return self;
}

- (void) addAllViews
{
    UIButton *scan = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [scan setTitle:@"扫描" forState:UIControlStateNormal];
    scan.frame = CGRectMake(20, 210, 60, 30);
    [scan addTarget:self action:@selector(scanClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:scan];
    
    _connect = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_connect setTitle:@"连接" forState:UIControlStateNormal];
    _connect.frame = CGRectMake(90, 210, 60, 30);
    [_connect addTarget:self action:@selector(connectClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_connect];
    
    UIButton *send = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [send setTitle:@"开始测量" forState:UIControlStateNormal];
    send.frame = CGRectMake(160, 210, 60, 30);
    [send addTarget:self action:@selector(sendClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:send];
    
    _textView = [[UITextView alloc]initWithFrame:CGRectMake(10, 250, 300, 200)];
    [self.view addSubview:_textView];
    _deviceTable = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, kDeviceWidth, 190) style:UITableViewStyleGrouped];
    _deviceTable.delegate = self;
    _deviceTable.dataSource = self;
    [self.view addSubview:_deviceTable];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.ble = [BleFourCommunication sharedBleFourCommunication];
    self.ble.writeString = kWriteString;
    self.ble.readString = kReadString;
    self.ble.delegate = self;
    
    [self addAllViews];
}


#pragma mark - Table view data source
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.ble.nDevices count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identified = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identified];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identified];
    }
    CBPeripheral *p = [self.ble.nDevices objectAtIndex:indexPath.row];
    cell.textLabel.text = p.name;
    
    //cell.textLabel.text = [_nDevices objectAtIndex:indexPath.row];
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"已扫描到的设备:";
}

//textView更新
-(void)updateLog:(NSString *)s
{
    static unsigned int count = 0;
    [_textView setText:[NSString stringWithFormat:@"[ %d ]  %@\r\n%@",count,s,_textView.text]];
    count++;
}
//扫描
-(void)scanClick
{
    [self updateLog:@"正在扫描外设..."];
    [self.ble startScanningWithOutTime:30.0];
}

#pragma mark 按钮
//连接

-(void)connectClick:(id)sender
{
    if (!self.ble.cbReady) {
        [self.ble connect];
        [_connect setTitle:@"断开" forState:UIControlStateNormal];
    }else {
        [self.ble cancel];
        [_connect setTitle:@"连接" forState:UIControlStateNormal];
    }
}




//发送信息
-(void)sendClick:(UIButton *)bu
{
    
    static int i = 0;
    
    unsigned char command[512] = {0};
    unsigned char *pTmp;
//    unsigned char ucCrc[3] = {0};
    
    pTmp = command;
    
    
    *pTmp = 0xCC;//start
    printf("%x",*pTmp);
    pTmp++;
    *pTmp = 0x80;
    printf("%x",*pTmp);
    pTmp++;
    *pTmp = 0x02;//version
    printf("%x",*pTmp);
    pTmp++;
    *pTmp = 0x03;//length
    printf("%x",*pTmp);
    pTmp++;
    *pTmp = 0x01;//command
    printf("%x",*pTmp);
    pTmp++;
    *pTmp = 0x01 + i;//subcommand
    i++;
    printf("%x",*pTmp);
    pTmp++;
    *pTmp = 0x00;//data
    printf("%x",*pTmp);
    pTmp++;
    *pTmp = command[2]^command[3]^command[4]^command[5]^command[6];//Xor
    printf("%x",*pTmp);
    pTmp++;

    NSData *data = [[NSData alloc] initWithBytes:&command length:7];
    [self.ble sendMsgWithData:data AndType:CBCharacteristicWriteWithResponse];
}

#pragma mark - ble delegate
-(void)bleFourCommunicationDidScanningTimeOut
{
    [_activity stopAnimating];
    [self updateLog:@"扫描超时,停止扫描"];
}

//开始查看服务，蓝牙开启
-(void)bleFourCommunicationDidReady
{
    [self updateLog:@"蓝牙已打开,请扫描外设"];
}

//查到外设后，停止扫描，连接设备
-(void)bleFourCommunication:(BleFourCommunication *)ble didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    [self updateLog:[NSString stringWithFormat:@"已发现 peripheral: %@ rssi: %@, UUID: %@ advertisementData: %@ ", peripheral, RSSI, peripheral.UUID, advertisementData]];
    [_deviceTable reloadData];
}

//连接外设成功，开始发现服务
-(void)bleFourCommunication:(BleFourCommunication *)ble didConnectPeripheral:(CBPeripheral *)peripheral
{
    [self updateLog:[NSString stringWithFormat:@"成功连接 peripheral: %@ with UUID: %@",peripheral,peripheral.UUID]];
    [self updateLog:@"扫描服务"];
    
}
//连接外设失败
-(void)bleFourCommunicationConnectFaild:(NSError *)error
{
    NSLog(@"%@",error);
}

-(void)bleFourCommunicationDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    int rssi = abs([peripheral.RSSI intValue]);
    CGFloat ci = (rssi - 49) / (10 * 4.);
    NSString *length = [NSString stringWithFormat:@"发现BLT4.0热点:%@,距离:%.1fm",peripheral,pow(10,ci)];
    NSLog(@"距离：%@",length);
}

-(void)bleFourCommunication:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error service:(CBService *)service
{
    static int i = 0;
    [self updateLog:@"发现服务."];
    [self updateLog:[NSString stringWithFormat:@"%d :服务 UUID: %@(%@)",i++,service.UUID.data,service.UUID]];
    [self updateLog:[NSString stringWithFormat:@"发现特征的服务:%@ (%@)",service.UUID.data ,service.UUID]];
    for (CBCharacteristic *c in service.characteristics) {
        [self updateLog:[NSString stringWithFormat:@"特征 UUID: %@ (%@)",c.UUID.data,c.UUID]];
    }
}

//获取外设发来的数据，不论是read和notify,获取数据都是从这个方法中读取。
- (void)bleFourCommunication:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    // BOOL isSaveSuccess;
    
        NSLog(@"原始数据%@",characteristic.value);
        
        NSString *value = [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"接收数据:%@",value);
        [self updateLog:[NSString stringWithFormat:@"接收数据:%@",value]];
}


@end
