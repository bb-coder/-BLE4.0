//
//  BleFourCommunication.h
//  蓝牙BLE4.0通讯
//
//  Created by 毕洪博 on 14-12-30.
//  Copyright (c) 2014年 毕洪博. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BHBSingleton.h"

@protocol BleFourCommunicationDelegate;

@interface BleFourCommunication : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>


BHBSingletonH(BleFourCommunication)

@property (weak, nonatomic) id<BleFourCommunicationDelegate> delegate;
//设备是否连接
@property BOOL cbReady;
@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (strong ,nonatomic) CBCharacteristic *writeCharacteristic;
/**
 *  读写协议
 */
@property (copy, nonatomic) NSString * writeString;
@property (copy, nonatomic) NSString * readString;

@property (strong,nonatomic) NSMutableArray *nDevices;
@property (strong,nonatomic) NSMutableArray *nServices;
@property (strong,nonatomic) NSMutableArray *nCharacteristics;
/**
 *  开始扫描
 *
 *  @param time 超时时间
 */
- (void)startScanningWithOutTime:(double) time;

/**
 *  连接与断开
 */
- (void)connect;
- (void)cancel;

/**
 *  发送信息
 *
 *  @param data 二进制数据
 */
- (void)sendMsgWithData:(NSData *)data AndType:(CBCharacteristicWriteType)type;


@end

@protocol BleFourCommunicationDelegate<NSObject>

@optional
/**超时*/
- (void)bleFourCommunicationDidScanningTimeOut;
/**蓝牙已打开*/
- (void)bleFourCommunicationDidReady;
/**查找到外设以后*/
- (void)bleFourCommunication:(BleFourCommunication *)ble didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
/**连接成功扫描服务*/
- (void)bleFourCommunication:(BleFourCommunication *) ble didConnectPeripheral:(CBPeripheral *)peripheral;
/**连接错误*/
- (void)bleFourCommunicationConnectFaild:(NSError *)error;
/**发现热点*/
- (void)bleFourCommunicationDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error;
/**发现服务*/
- (void)bleFourCommunication:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error service:(CBService *)service;

/**获取到数据*/
- (void)bleFourCommunication:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;
@end
