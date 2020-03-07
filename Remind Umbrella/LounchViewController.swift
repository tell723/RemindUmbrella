//
//  LounchViewController.swift
//  Remind Umbrella
//
//  Created by 渡邊輝夢 on 2020/03/06.
//  Copyright © 2020 Terumu Watanabe. All rights reserved.
//

import UIKit


class LounchViewController: UIViewController {
    
    var umbrellaImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.white
        
        let image: UIImage = UIImage(named: "umbrellaImage")!
        self.umbrellaImageView = UIImageView(image: image)
        
        let screenWidth:CGFloat = view.frame.size.width
        let screenHeight:CGFloat = view.frame.size.height
        
        umbrellaImageView.frame = CGRect(x: 0,
                                 y: 0,
                                 width: 200,
                                 height: 200)
        umbrellaImageView.center = CGPoint(x: screenWidth / 2,
                                   y: screenHeight / 2)
        
        self.view.addSubview(umbrellaImageView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let storyboad: UIStoryboard = self.storyboard!
        let nextView = storyboard?.instantiateViewController(withIdentifier: "MainVC") as! ViewController

        UIView.animate(withDuration: 0.3,
                       delay: 1.0,
                       animations: {
                        self.umbrellaImageView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        })
        
        UIView.animate(withDuration: 0.3,
                       delay: 1.3,
                       animations: {
                        self.umbrellaImageView.transform =
                            CGAffineTransform(scaleX: 1.2,
                                              y: 1.2)
                        self.umbrellaImageView.alpha = 0
//                          self.umbrellaImageView.removeFromSuperview()
//                        self.present(nextView, animated: false, completion: nil)
        })
//        self.umbrellaImageView.removeFromSuperview()
//        self.performSegue(withIdentifier: "toMain", sender: nil)
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
