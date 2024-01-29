//
//  ViewController.swift
//  CameraDemo01
//
//  Created by 徐雪勇 on 2023/7/10.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
       let progressBarView = CircularProgressBarView(frame: CGRect(x: 50, y: 50, width: 200, height: 200))
                view.addSubview(progressBarView)
                
//                // 模拟进度增加动画
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    progressBarView.progress = 0.2
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    progressBarView.progress = 0.5
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    progressBarView.progress = 0.8
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    progressBarView.progress = 1.0
                }
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        let vc = CameraViewController()
        vc.currentImageClosure = { info in
            print(info)
        }
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}



//{
//    "height": 700,
//    "name": "img_20230630_135118.jpg",
//    "path": "/storage/emulated/0/Android/data/com.acoinfo.edgerapp.dev/files/Pictures/IMG_20230711173830803.jpeg",
//    "size": 92601,
//    "type": "image",
//    "duration": "10000", // 视频的时长
//    "url": "https://gy7ocz-uixjii.qddo1m-2oo83d.edgeros.vip:1000/resource?path=/storage/emulated/0/Android/data/com.acoinfo.edgerapp.dev/files/Pictures/IMG_20230711173830803.jpeg",
//    "width": 530
//}
