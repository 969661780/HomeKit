//
//  RoomViewController.swift
//  HomeKitTest
//
//  Created by mt y on 2017/10/23.
//  Copyright © 2017年 mt y. All rights reserved.
//

import UIKit
import HomeKit

class RoomViewController: UIViewController {
    
    @IBOutlet weak var myTableView: UITableView!
    
    @IBOutlet weak var cuentLab: UILabel!
    @IBOutlet weak var myCuentTableView: UITableView!
    var myRoom : HMRoom!
    var myHome : HMHome!
    var arressBrowser:HMAccessoryBrowser!
    var arressoryCuen : HMAccessory!
    var readCha : HMCharacteristic!
    var writeCha : HMCharacteristic!
    
    
    //viewCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
         Accessories封装了物理配件的状态，因此它不能被用户创建，也就是说我们不能去创建智能硬件对象，只能通过去搜寻它，然后添加。想要允许用户给家添加新的配件，我们可以使HMAccessoryBrowser对象在后台搜寻一个与home没有关联的配件，当它找到配件的时候，系统会调用委托方法来通知你的应用程序。
         */
        self.title = myRoom.name
        self.myTableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "cell")
        self.myCuentTableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "myCell")
        
        self.arressBrowser = HMAccessoryBrowser.init()
        self.arressBrowser.delegate = self
        
      
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.arressBrowser.stopSearchingForNewAccessories()
    }
    //touchs
    @IBAction func getAllDevice(_ sender: UIButton) {
        print("开始搜索配件")
        self.arressBrowser.startSearchingForNewAccessories()
    }
    
    @IBAction func changNameBtn(_ sender: UIButton) {
        if self.arressoryCuen != nil {
            self.arressoryCuen.updateName(("新\(self.arressoryCuen.name)"), completionHandler: { (error) in
                if error != nil{
                    print("更改名字失败")
                }else{
                    print("更改名字成功")
                    self.cuentLab.text  = self.arressoryCuen.name
                    for accessory in self.myRoom.accessories {
                        self.myAccessoryArr.append(accessory)
                    }
                    self.myCuentTableView.reloadData()
                    
                }
            })
        }
    }
    @IBAction func removeBtn(_ sender: UIButton) {
        if self.arressoryCuen != nil {
            self.myHome.removeAccessory(self.arressoryCuen, completionHandler: { (error) in
                if error != nil{
                    print("移除失败")
                }else{
                    self.cuentLab.text = "为选中设备"
                    print("移除成功")
                    for accessory in self.myRoom.accessories {
                        self.myAccessoryArr.append(accessory)
                    }
                    self.myCuentTableView.reloadData()
                }
            })
        }
    }
    @IBAction func getAllMyAccessory(_ sender: UIButton) {
        for accessory in self.myRoom.accessories {
            self.myAccessoryArr.append(accessory)
        }
        self.myCuentTableView.reloadData()
    }
    @IBAction func openAccessoryBtn(_ sender: UIButton) {
        for i in 0..<self.arressoryCuen.services.count {
            let mySeverce = self.arressoryCuen.services[i]
            print("服务的名字为\(mySeverce.name)")
            for j in 0..<mySeverce.characteristics.count{
                print("服务的特征为\(mySeverce.characteristics[j].properties)")
                let myCharactwristics = mySeverce.characteristics[j]
                if myCharactwristics.properties[0] == HMCharacteristicPropertyReadable{
                    self.readCha = myCharactwristics
                    self.readCha.enableNotification(true, completionHandler: { (error) in
                      //接收外设的通知
                    })
                }else{
                    self.writeCha = myCharactwristics
                    self.writeCha.enableNotification(true, completionHandler: { (error) in
                        if error == nil{
                            let myValue = self.writeCha.value as! Int
                            print("特征的状态\(myValue)")
                            if myValue == 0{
                                [self.writeCha .writeValue(1, completionHandler: { (error) in
                                    if error == nil {
                                        print("写入成功")
                                    }else{
                                        print("写入失败")
                                    }
                                })]
                            }else{
                                [self.writeCha .writeValue(0, completionHandler: { (error) in
                                    if error == nil {
                                        print("写入成功")
                                    }else{
                                        print("写入失败")
                                    }
                                })]
                            }
                        }else{
                            print("读取特征失败")
                        }
                    })
                }
            }
        }
    }
    //lazy
    lazy var accessoryArr : [HMAccessory] = {
        return [HMAccessory]()
    }()
    lazy var myAccessoryArr : [HMAccessory] = {
       return [HMAccessory]()
    }()
}



// MARK: - <#UITableViewDelegate,UITableViewDataSource,HMAccessoryBrowserDelegate#>
extension RoomViewController:UITableViewDelegate,UITableViewDataSource,HMAccessoryBrowserDelegate,HMAccessoryDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 100{
             return self.accessoryArr.count
        }
       return self.myAccessoryArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 100 {
            let myTable = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            myTable.textLabel?.text  = self.accessoryArr[indexPath.row].name
           return myTable
        }else{
            let  myTable = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
            myTable.textLabel?.text = self.myAccessoryArr[indexPath.row].name
            return myTable
        }
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag == 100 {
            let accessoryName = self.accessoryArr[indexPath.row]
            self.myHome.addAccessory(accessoryName) { (error) in
                if error == nil{
                    if accessoryName.room != self.myRoom{
                        self.myHome.assignAccessory(accessoryName, to: self.myRoom, completionHandler: { (error1) in
                            if error1 == nil{
                                print("已经将设备添加到了房间")
                            }else{
                                print("指定的设备添加失败")
                            }
                        })
                    }else{
                        print("该设备已经存在于房间")
                    }
                }else{
                    print("添加设备到家失败")
                }
            }
        }else{
            self.cuentLab.text = self.myAccessoryArr[indexPath.row].name
            self.arressoryCuen = self.myAccessoryArr[indexPath.row]
            self.arressoryCuen.delegate = self
        }
       
    }
    
    
    
    func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
        self.accessoryArr.append(accessory)
        self.myTableView.reloadData()
    }
    func accessoryBrowser(_ browser: HMAccessoryBrowser, didRemoveNewAccessory accessory: HMAccessory) {
        print("硬件已经移除了")
    }
    
    
    
    func accessory(_ accessory: HMAccessory, didUpdateAssociatedServiceTypeFor service: HMService) {
        print("特征发生了改变")
    }
    
}

