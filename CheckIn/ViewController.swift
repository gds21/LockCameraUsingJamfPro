//
//  ViewController.swift
//  CheckIn
//
//  Created by glee on 2020/9/6.
//  Copyright © 2020 aatp. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    var lockCamera = "true"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func onDuty() {
        lockCamera = "true"
        searchUser()
    }
    
    @IBAction func offDuty() {
        lockCamera = "false"
        searchUser()
    }
    
    func searchUser() {
        guard let username = usernameTextField.text else { return }
        if username.count == 0 {
            show(alertTitle: "找不到用戶", message: "請重新檢查")
        } else {
            search(fullname: username)
        }
    }
    
    func show(alertTitle: String, message: String) {
        let alertController = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "確認", style: .default, handler: nil)
        alertController.addAction(action)
        present(alertController, animated: false, completion: nil)
    }
    
    func search(fullname: String) {
        let reqCon = RequestController()
        let request = reqCon.request(userFullName: fullname)

        /* Start a new Task */
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                // Success
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("URL Session Task Succeeded: HTTP \(statusCode)")
                let root = try! JSONSerialization.jsonObject(with: data!, options: .fragmentsAllowed) as! [String:Any]
                let user = root["user"] as! [String:Any]
                let links = user["links"] as! [String:Any]
                let mobileDevices = links["mobile_devices"] as! [[String:Any]]
                for mobileDevice in mobileDevices {
                    let id = mobileDevice["id"] as! Int
                    self.update(deviceID: id)
                }
                DispatchQueue.main.async {
                    self.show(alertTitle: "作業已完成", message: "已更新")
                }
            }
            else {
                // Failure
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    func update(deviceID: Int) {
        let reqCon = RequestController()
        let request = reqCon.request(lockCamera: lockCamera, deviceID: deviceID)
        /* Start a new Task */
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                // Success
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("URL Session Task Succeeded: HTTP \(statusCode)")
            }
            else {
                // Failure
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
}


class RequestController {
    
    let apiEndpoint = Credential.url
    let authVaule = Credential.authValue
    
    func request(userFullName: String) -> URLRequest {
        let urlString = "\(apiEndpoint)/users/name/\(userFullName)"
        let url = URL(string: urlString)
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Basic \(authVaule)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    func request(lockCamera:String, deviceID: Int) -> URLRequest {
        let urlString = "\(apiEndpoint)/mobiledevices/id/\(deviceID)"
        let url = URL(string: urlString)
        var request = URLRequest(url: url!)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Basic \(authVaule)", forHTTPHeaderField: "Authorization")
        let bodyString = "<mobile_device><extension_attributes><extension_attribute><id>\(deviceID)</id><name>ShouldLockCamera</name><type>String</type> <multi_value>\(lockCamera)</multi_value><value>\(lockCamera)</value></extension_attribute></extension_attributes></mobile_device>"
        request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
        return request
    }
}
