//
//  LouncherViewController.swift
//  Remind Umbrella
//
//  Created by 渡邊輝夢 on 2020/02/28.
//  Copyright © 2020 Terumu Watanabe. All rights reserved.
//

import UIKit

class LouncherViewController: UIViewController {
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        indicator.startAnimating()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
