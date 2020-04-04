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
    
    
    var
    locationManager: CLLocationManager!,
    currentLatitude: CLLocationDegrees!,
    currentLongitude: CLLocationDegrees!,
    currentLocation = "",
    
    weathers:[String] = [],
    isWeathersContainRain = false,
    
    noticeHour: Int!,
    noticeMin: Int!;
    let
    hourList = [Int](0...23),
    minList = [Int](0...59);
    
    var noticeMessage: String {
        get {
            if self.weathers == [] {
                return "天気情報が取得されていません"
            } else {
                if isWeathersContainRain {
                    return "傘忘れんなよ！！"
                } else {
                    return "傘はいらないよ"
                }
            }
        }
    }
    
    /* 最初は天気情報の取得にOpenWeatherのみを利用していたが、
    1時間刻みで天気情報を得るにはDarkSkyが適していたのでこちらを利用した。
    ただ、DarkSkyだけでは現在位置名称を得られなかったため併用している */
    
    let
    openWeatherBaseUrl = "https://api.openweathermap.org/data/2.5/weather?",
    openWeatherApiKey = "06c2c12ef09f140ac6e2270864976fc4",
    darkSkyBaseUrl = "https://api.darksky.net/forecast",
    darkSkyApiKey = "c713b009d8f479f7caae865a785a5a60"
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            self.noticeHour = hourList[row]
        } else if pickerView.tag == 1 {
            self.noticeMin = minList[row]
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
        //TODO:　許可されなかった場合の処理を実装
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        
        weathers = []
        isWeathersContainRain = false
                
        let location = locations.first
        currentLatitude = location?.coordinate.latitude
        currentLongitude = location?.coordinate.longitude
        
        guard let lat = currentLatitude, let lon = currentLongitude else { return }
        print("lat: \(lat) lon: \(lon)")
        
        let dispatchGroup = DispatchGroup()
        let queue1 = DispatchQueue.main
        
        
        let openWeatherUrlString =
        "\(self.openWeatherBaseUrl)lat=\(lat)&lon=\(lon)&appid=\(self.openWeatherApiKey)"
        let darkSkyUrlString =
        "\(self.darkSkyBaseUrl)/\(self.darkSkyApiKey)/\(lat),\(lon)?exclude=alerts,daily,flags"
        print(darkSkyUrlString)
    
        guard let openWeatherUrl = URL(string: openWeatherUrlString) else { return }
        guard let darkSkyUrl = URL(string: darkSkyUrlString) else { return }

        queue1.async(group: dispatchGroup) {
            dispatchGroup.enter()
            let locationTask: URLSessionTask =
                URLSession.shared.dataTask(with: openWeatherUrl,
                                           completionHandler: {data, response, error in
                                            guard let data = data else { return }
                                            do {
                                                let jsonData = try? JSON(data: data)
                                                self.currentLocation = jsonData!["name"].stringValue
                                                print("name: \(self.currentLocation)")
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
                URLSession.shared.dataTask(with: darkSkyUrl,
                                           completionHandler: {data, response, error in
                                            guard let data = data else { return }
                                            do {
                                                let jsonData = try? JSON(data: data)
                                                
                                                let currentWeather = jsonData!["currently"]["icon"].stringValue
                                                if currentWeather == "rain" {
                                                    self.isWeathersContainRain = true
                                                }
                                                self.weathers.append(currentWeather)
                                                
                                                var hourlyData = jsonData!["hourly"]["data"]
                                                let currentTime = jsonData!["currently"]["time"].intValue
                                                
                                                // 取得時刻より後の９時間分の天気を取得
                                                var i = 0
                                                while self.weathers.count < 10 {
                                                    
                                                    if hourlyData[i]["time"].intValue >= currentTime {
                                                        self.weathers.append(hourlyData[i]["icon"].stringValue)
                                                        if hourlyData[i]["icon"].stringValue.contains("rain") {
                                                            self.isWeathersContainRain = true
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
            print(self.weathers)
            self.setNotification()
            print("message: \(self.noticeMessage)")
        }
    }
    
    
    
    func setNotification() {
        
        let content = UNMutableNotificationContent()
        content.title = noticeMessage
        content.body = currentLocation
        content.sound = UNNotificationSound.default
        
        var notificationTime = DateComponents()
        notificationTime.hour = noticeHour
        notificationTime.minute = noticeMin
        
        let tirgger: UNNotificationTrigger
        tirgger = UNCalendarNotificationTrigger(dateMatching: notificationTime,
                                                repeats: false)
        
        let request = UNNotificationRequest(identifier: "Timer",
                                            content: content,
                                            trigger: tirgger)
        
        UNUserNotificationCenter.current().add(request,
                                               withCompletionHandler: nil)
        
        if let lat = currentLatitude, let lon = currentLongitude {
            print("lat: \(lat) lon: \(lon)")
        }
        if currentLocation == "" {
            self.locationLabel.text = "Location: 位置情報が取得できません"
        } else {
            self.locationLabel.text = "Location: \(currentLocation)"
        }
    }
    
}

