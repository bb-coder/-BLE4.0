//
//  BleFourCommunication.m
//  蓝牙BLE4.0通讯
//
//  Created by 毕洪博 on 14-12-30.
//  Copyright (c) 2014年 毕洪博. All rights reserved.
//

#import "BleFourCommunication.h"

@interface BleFourCommunication ()

@end

@implementation BleFourCommunication

BHBSingletonM(BleFourCommunication)

#pragma mark - 初始化
- (instancetype)init
{
    self = [super init];
    if (self) {
        _cbReady = false;
    }
    return self;
}
#pragma mark - 懒加载
-(NSMutableArray *)nDevices
{
    if (!_nDevices) {
        _nDevices = [[NSMutableArray alloc]init];
    }
    return _nDevices;
}

-(NSMutableArray *)nServices
{
    if(!_nServices){
        _nServices = [[NSMutableArray alloc]init];
    }
    return _nServices;
}

-(NSMutableArray *)nCharacteristics
{
    if(!_nCharacteristics){
        _nCharacteristics = [[NSMutableArray alloc]init];
    }
    return _nCharacteristics;
}

-(CBCentralManager *)manager
{
    if (!_manager) {
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return _manager;
}

#pragma mark - 开始扫描
- (void)startScanningWithOutTime:(double) time
{
    [self.manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    double delayInSeconds = time;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.manager stopScan];
        if (self.delegate && [self.delegate respondsToSelector:@selector(bleFourCommunicationDidScanningTimeOut)]) {
            [self.delegate bleFourCommunicationDidScanningTimeOut];
        }
    });

}

#pragma mark - 连接与断开
- (void)connect
{
    if (self.peripheral) {
        [self.manager connectPeripheral:self.peripheral options:nil];
        self.cbReady = true;
    }
}
- (void)cancel
{
    if (self.peripheral) {
        [self.manager cancelPeripheralConnection:self.peripheral];
        self.cbReady = false;
    }
}

#pragma mark - 发送信息
- (void)sendMsgWithData:(NSData *)data AndType:(CBCharacteristicWriteType)type
{
    [self.peripheral writeValue:data forCharacteristic:self.writeCharacteristic type:type];
}

#pragma mark - 开始查看服务，蓝牙开启
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            if (self.delegate && [self.delegate respondsToSelector:@selector(bleFourCommunicationDidReady)]) {
                [self.delegate bleFourCommunicationDidReady];
            }
            break;
        default:
            break;
    }
}

#pragma mark - 查到外设后，停止扫描，连接设备
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    self.peripheral = peripheral;
    [self.manager stopScan];
    BOOL replace = NO;
    // Match if we have this device from before
    for (int i=0; i < self.nDevices.count; i++) {
        CBPeripheral *p = [self.nDevices objectAtIndex:i];
        if ([p isEqual:peripheral]) {
            [self.nDevices replaceObjectAtIndex:i withObject:peripheral];
            replace = YES;
        }
    }
    if (!replace) {
        [self.nDevices addObject:peripheral];
        if (self.delegate && [self.delegate respondsToSelector:@selector(bleFourCommunication:didDiscoverPeripheral:advertisementData:RSSI:)]) {
            [self.delegate bleFourCommunication:self didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
        }
    }
}
#pragma mark - 连接外设成功，开始发现服务
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self.peripheral setDelegate:self];
    [self.peripheral discoverServices:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(bleFourCommunication:didConnectPeripheral:)]) {
        [self.delegate bleFourCommunication:self didConnectPeripheral:peripheral];
    }
}

#pragma mark - 连接外设失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bleFourCommunicationConnectFaild:)]) {
        [self.delegate bleFourCommunicationConnectFaild:error];
    }
}
#pragma mark - 发现热点
-(void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bleFourCommunicationDidUpdateRSSI:error:)]) {
        [self.delegate bleFourCommunicationDidUpdateRSSI:peripheral error:error];
    }
}

#pragma mark - 发现服务
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *s in peripheral.services) {
        [self.nServices addObject:s];
    }

    for (CBService *s in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:s];
        if (self.delegate && [self.delegate respondsToSelector:@selector(bleFourCommunication:didDiscoverServices:service:)]) {
            [self.delegate bleFourCommunication:peripheral didDiscoverServices:error service:s];
        }
    }

}

#pragma mark -已搜索到Characteristics
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
    for (CBCharacteristic *c in service.characteristics) {
        
        NSLog(@"%@",c.UUID);
        if ([c.UUID isEqual:[CBUUID UUIDWithString:self.writeString]]) {
            self.writeCharacteristic = c;
        }
        if ([c.UUID isEqual:[CBUUID UUIDWithString:self.readString]]) {
            [self.peripheral readValueForCharacteristic:c];
            [self.peripheral setNotifyValue:YES forCharacteristic:c];
        }
        [self.nCharacteristics addObject:c];
    }
}

#pragma mark -获取数据
//获取外设发来的数据，不论是read和notify,获取数据都是从这个方法中读取。
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // BOOL isSaveSuccess;
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:self.readString]]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(bleFourCommunication:didUpdateValueForCharacteristic:error:)]) {
            [self.delegate bleFourCommunication:peripheral didUpdateValueForCharacteristic:characteristic error:error];
        }
    }
}


//中心读取外设实时数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    // Notification has started
    if (characteristic.isNotifying) {
        [peripheral readValueForCharacteristic:characteristic];
        
    } else { // Notification has stopped
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.manager cancelPeripheralConnection:self.peripheral];
    }
}
//用于检测中心向外设写数据是否成功
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"发送错误%@",error.userInfo);
    }else{
        NSLog(@"发送数据成功");
    }
}
@end
