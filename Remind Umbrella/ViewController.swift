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

class ViewController: UIViewController, UNUserNotificationCenterDelegate, CLLocationManagerDelegate {
    
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var hourPV: UIPickerView!
    @IBOutlet weak var minPV: UIPickerView!
    
    
    private var
    locationManager: CLLocationManager!,
    currentLatitude: CLLocationDegrees!,
    currentLongitude: CLLocationDegrees!,
    currentLocation = "",
    
    weathers: [String] = [],
    isWeathersContainRain = false,
    
    noticeHour: Int!,
    noticeMin: Int!;
    private let
    hourList = [Int](0...23),
    minList = [Int](0...59);
    
    private var noticeMessage: String {
        get {
            if self.weathers == [] {
                return "天気情報が取得されていません"
            } else {
                return isWeathersContainRain ? "傘忘れんなよ！！" : "傘はいらないよ"
            }
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLocationManager()
        
        hourPV.delegate = self
        hourPV.dataSource = self
        minPV.delegate = self
        minPV.dataSource = self

        self.locationLabel.text = "Location:"
    }
    
    
    
   private func setupLocationManager() {
    
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
        
        let location = locations.first
        currentLatitude = location?.coordinate.latitude
        currentLongitude = location?.coordinate.longitude
        
        guard let lat = currentLatitude, let lon = currentLongitude else { return }
        print("lat: \(lat) lon: \(lon)")
        
       resetWeather(latitude: lat, longitude: lon)
    }
    
    
    
    private func resetWeather(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        
        weathers = []
        isWeathersContainRain = false
        
        /* 最初は天気情報の取得にOpenWeatherのみを利用していたが、
         1時間刻みで天気情報を得るにはDarkSkyが適していたのでこちらを利用した。
         ただ、DarkSkyだけでは現在位置名称を得られなかったため併用している */
        let
        openWeatherBaseUrl = "https://api.openweathermap.org/data/2.5/weather?",
        openWeatherApiKey = "06c2c12ef09f140ac6e2270864976fc4",
        darkSkyBaseUrl = "https://api.darksky.net/forecast",
        darkSkyApiKey = "c713b009d8f479f7caae865a785a5a60";
        
        let openWeatherUrlString =
        "\(openWeatherBaseUrl)lat=\(latitude)&lon=\(longitude)&appid=\(openWeatherApiKey)"
        let darkSkyUrlString =
        "\(darkSkyBaseUrl)/\(darkSkyApiKey)/\(latitude),\(longitude)?exclude=alerts,daily,flags"
        
        guard let openWeatherUrl = URL(string: openWeatherUrlString) else { return }
        guard let darkSkyUrl = URL(string: darkSkyUrlString) else { return }
        
        let
        dispatchGroup = DispatchGroup(),
        queue1 = DispatchQueue.main
        
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
                                                
                                                let
                                                hourlyData = jsonData!["hourly"]["data"],
                                                currentTime = jsonData!["currently"]["time"].intValue
                                                
                                                // 取得時刻より後の約９時間分の天気だけを抜粋
                                                var i = 0
                                                while self.weathers.count < 10 {
                                                    
                                                    let
                                                    hourlyTime = hourlyData[i]["time"].intValue,
                                                    hourlyWeather = hourlyData[i]["icon"].stringValue
                                                    
                                                    if hourlyTime < currentTime {
                                                        i += 1
                                                        continue
                                                    }
                                                    
                                                    self.weathers.append(hourlyWeather)
                                                    
                                                    if hourlyWeather.contains("rain") {
                                                        self.isWeathersContainRain = true
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
    
    private func selectNecessaryWeather(jsonData: JSON!) {
        
        
    }
    
    
    private func setNotification() {
        
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

        locationLabel.text =
            currentLocation == "" ? "Location: 位置情報が取得できません" : "Location: \(currentLocation)"
    }
    
}




extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int {

        switch pickerView.tag {
        case 0:
            return hourList.count
        case 1:
            return minList.count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        
        switch pickerView.tag {
        case 0:
            return String(hourList[row])
        case 1:
            return String(minList[row])
        default:
            return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView,
                    didSelectRow row: Int,
                    inComponent component: Int) {
        
        switch pickerView.tag {
        case 0:
            noticeHour = hourList[row]
        case 1:
            noticeMin = minList[row]
        default:
            break
        }
        
        setNotification()
    }
   
}
