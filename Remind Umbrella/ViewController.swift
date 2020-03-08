//
//  ViewController.swift
//  Remind Umbrella
//
//  Created by 渡邊輝夢 on 2020/02/28.
//  Copyright © 2020 Terumu Watanabe. All rights reserved.
//

import UIKit
import UserNotifications
import SwiftyJSON
import CoreLocation

class ViewController: UIViewController, UNUserNotificationCenterDelegate, CLLocationManagerDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var hourPV: UIPickerView!
    @IBOutlet weak var minPV: UIPickerView!
    
    var locationManager: CLLocationManager!
    var latitude: CLLocationDegrees!
    var longitude: CLLocationDegrees!
    var location = ""
    var isWeathersContainsRain = false

    var message: String {
        get {
            if self.weaters == [] {
                return "天気情報が取得されていません"
            } else {
                if isWeathersContainsRain {
                    return "傘忘れんなよ！！"
                } else {
                    return "傘はいらないよ"
                }
            }
        }
    }
    let openWeatherBaseUrl = "https://api.openweathermap.org/data/2.5/weather?"
    let openWeatherApiKey = "06c2c12ef09f140ac6e2270864976fc4"
    let darkSkyBaseUrl = "https://api.darksky.net/forecast"
    let darkSkyApiKey = "c713b009d8f479f7caae865a785a5a60"
    var weaters: [String] = []
    var hour: Int!
    var min: Int!
    let hourList = [Int](0...23)
    let minList = [Int](0...59)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupLocationManager()
        
        hourPV.delegate = self
        hourPV.dataSource = self
        minPV.delegate = self
        minPV.dataSource = self
        
        self.locationLabel.text = "Location:"
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 0 {
            return hourList.count
        } else if pickerView.tag == 1 {
            return minList.count
        } else {
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        if pickerView.tag == 0 {
            return String(hourList[row])
        } else if pickerView.tag == 1 {
            return String(minList[row])
        } else {
            return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView,
                    didSelectRow row: Int,
                    inComponent component: Int) {
        if pickerView.tag == 0 {
            self.hour = hourList[row]
        } else if pickerView.tag == 1 {
            self.min = minList[row]
        }
        
        setNotification()
    }
    
    func setupLocationManager() {
        locationManager = CLLocationManager()
        guard let locationManager = locationManager else { return }
        locationManager.requestAlwaysAuthorization()
        
        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.delegate = self
            locationManager.distanceFilter = 100.0
            locationManager.startUpdatingLocation()
            locationManager.allowsBackgroundLocationUpdates = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        
        self.weaters = []
                
        let location = locations.first
        self.latitude = location?.coordinate.latitude
        self.longitude = location?.coordinate.longitude
        
        guard let lat = latitude, let lon = longitude else { return }
        print("lat: \(lat) lon: \(lon)")
        
        let dispatchGroup = DispatchGroup()
        let queue1 = DispatchQueue.main
        
        let locationJsonString = "\(self.openWeatherBaseUrl)lat=\(lat)&lon=\(lon)&appid=\(self.openWeatherApiKey)"
        let weatherJsonString = "\(self.darkSkyBaseUrl)/\(self.darkSkyApiKey)/\(lat),\(lon)?exclude=alerts,daily,flags"
        guard let locationUrl = URL(string: locationJsonString) else { return }
        guard let weatherUrl = URL(string: weatherJsonString) else { return }

        queue1.async(group: dispatchGroup) {
            dispatchGroup.enter()
            let locationTask: URLSessionTask =
                URLSession.shared.dataTask(with: locationUrl,
                                           completionHandler: {data, response, error in
                                            guard let data = data else { return }
                                            do {
                                                let json = try? JSON(data: data)
                                                self.location = json!["name"].stringValue
                                                print("name: \(self.location)")
                                                dispatchGroup.leave()
                                            } catch {
                                                print(error)
                                            }
                })
            locationTask.resume()
        }
        
        queue1.async(group: dispatchGroup) {
            dispatchGroup.enter()
            let weatherTask: URLSessionTask =
                URLSession.shared.dataTask(with: weatherUrl,
                                           completionHandler: {data, response, error in
                                            guard let data = data else { return }
                                            do {
                                                let json = try? JSON(data: data)
                                                let currentWeather = json!["currently"]["icon"].stringValue
                                                self.weaters.append(currentWeather)
                                                
                                                var hourlyData = json!["hourly"]["data"]
                                                let currentTime = json!["currently"]["time"].intValue
                                                var i = 0
                                                while self.weaters.count < 10 {
                                                    
                                                    if hourlyData[i]["time"].intValue >= currentTime {
                                                        self.weaters.append(hourlyData[i]["icon"].stringValue)
                                                        if hourlyData[i]["icon"].stringValue.contains("rain") {
                                                            self.isWeathersContainsRain = true
                                                        }
                                                    }
                                                    i += 1
                                                }
                                                dispatchGroup.leave()
                                            }
                })
            weatherTask.resume()
        }
        
        dispatchGroup.notify(queue: queue1) {
            print(self.weaters)
            self.setNotification()
        }
    }
    
    func setNotification() {
        
        let content = UNMutableNotificationContent()
        content.title = self.message
        content.body = self.location
        content.sound = UNNotificationSound.default
        
        var notificationTime = DateComponents()
        notificationTime.hour = self.hour
        notificationTime.minute = self.min
        
        let tirgger: UNNotificationTrigger
        tirgger = UNCalendarNotificationTrigger(dateMatching: notificationTime,
                                                repeats: false)
        
        let request = UNNotificationRequest(identifier: "Timer",
                                            content: content,
                                            trigger: tirgger)
        
        UNUserNotificationCenter.current().add(request,
                                               withCompletionHandler: nil)
        
        if let lat = self.latitude, let lon = self.longitude {
            print("lat: \(lat) lon: \(lon)")
        }
        if location == "" {
            self.locationLabel.text = "Location: 位置情報が取得できません"
        } else {
            self.locationLabel.text = "Location: \(location)"
        }
    }
    
}

