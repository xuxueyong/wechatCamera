//
//  CameraViewController.swift
//  CameraDemo01
//
//  Created by 徐雪勇 on 2023/7/11.
//

import UIKit
import AVFoundation

extension CameraViewController {
    enum Constants {
        static let preViewImageFrame: CGRect = CGRect(origin: .zero, size: CGSize(width: UIScreen.main.bounds.width, height:UIScreen.main.bounds.height - Constants.bottomViewHeigth))
        static let bottomViewHeigth: CGFloat = 164
    }
}

class CameraViewController: UIViewController {
    // 拍摄最大视频时长
    var videoMaxDuration: TimeInterval = 10
    // 当前拍摄视频时长
    var currentVideoDuration: TimeInterval = 0
    var timer: Timer?
    
    var flashMode: AVCaptureDevice.FlashMode = .off
    
    override var prefersStatusBarHidden: Bool {
        true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var photoOutPut: AVCapturePhotoOutput?
    var videoOutPut: AVCaptureMovieFileOutput?
    var currentCamera: AVCaptureDevice?
    var currentImageData: Data?
    var currentImage: UIImage?
    var currentImagePath: String?
    typealias ImageResult = (_ info: [String: Any]?) -> Void
    var currentImageClosure: ImageResult?
    var videoPlayer: CameraAVPlayer?
    var videoPlayerLayer: AVPlayerLayer?
    var currentZoomFactor: CGFloat = 1.0
    
    lazy var backGestureView: UIView = {
        let view = UIView(frame: Constants.preViewImageFrame)
        return view
    }()
    
    lazy var closeButton: CameraBaseButton = {
        let button = CameraBaseButton()
        button.hitSize = CGSize(width: 50, height: 50)
        button.imageView?.contentMode = .scaleAspectFit
        button.setImage(UIImage(named: "camera_close"), for: .normal)
        button.addTarget(self, action: #selector(closeButtonTapped(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var bottomView: CameraBottomContainerView = {
        let viewHeight = Constants.bottomViewHeigth
        let view = CameraBottomContainerView(frame: CGRect(x: 0, y: self.view.frame.height - viewHeight, width: self.view.frame.width, height: viewHeight))
        view.delegate = self
        return view
    }()
    
    lazy var previewPhotoScrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: Constants.preViewImageFrame)
        scrollView.isHidden = true
        scrollView.backgroundColor = .black
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    lazy var autoFocusView: UIView = {
        let view = CameraAotoFocusView(frame: CGRect(origin: .zero, size: CGSize(width: 60, height: 60)))
        return view
    }()
    
    lazy var tipsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.layer.cornerRadius = 20
        label.clipsToBounds = true
        let labelWidth: CGFloat = 200
        label.frame = CGRect(x: UIScreen.main.bounds.width * 0.5 - labelWidth * 0.5, y: UIScreen.main.bounds.height -  Constants.bottomViewHeigth - 50, width: labelWidth, height: 40)
        label.backgroundColor = UIColor(white: 0, alpha: 0.4)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "轻触拍照，按住摄像"
        label.alpha = 0
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        // 设置捕获会话
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        // 默认获取后置摄像头
        currentCamera = CameraTool.backCamera()
        
        // 创建摄像头输入流
        CameraTool.createCamerInput(camera: currentCamera, captureSession: captureSession)
        
        // 创建音频输入流
        CameraTool.createAudioInput(captureSession: captureSession)
        
        // 创建照片输出对象
        photoOutPut = CameraTool.createPhotoOutPutAndAddSession(captureSession)
        
        // 创建视频输出对象
        videoOutPut = CameraTool.createVideoOutPutAndAddSession(captureSession)
        
        // 启动会话
        captureSession?.startRunning()
        
        setupViews()
    }
    
    private func setupViews() {
        // 添加手势接收视图
        view.addSubview(backGestureView)
        addCustomGestures()
        
        // 创建预览层
        videoPreviewLayer = AVCaptureVideoPreviewLayer()
        videoPreviewLayer?.session = captureSession
        videoPreviewLayer?.frame = Constants.preViewImageFrame
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(videoPreviewLayer!)
        
        // 添加底部视图
        view.addSubview(bottomView)
        
        // 添加关闭按钮
        view.addSubview(closeButton)
        let safeTop = (UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0) + 10
        closeButton.frame = CGRect(x: 16, y: safeTop, width: 24, height: 24)
        
        // 添加图片预览视图
        view.addSubview(previewPhotoScrollView)
        previewPhotoScrollView.delegate = self
        previewPhotoScrollView.addSubview(previewImageView)
        previewImageView.frame = previewPhotoScrollView.bounds
        
        // 添加 tips
        view.addSubview(tipsLabel)
    }
    
    private func addCustomGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(sender:)))
        backGestureView.addGestureRecognizer(tap)
        
        let pinGesture = UIPinchGestureRecognizer(target: self, action: #selector(pin(pinGes:)))
        backGestureView.addGestureRecognizer(pinGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleAutoFocusView()
    }
    
    private func handleAutoFocusView() {
        showAutoFoucusView(point: backGestureView.center)
        CameraTool.focusAtPoint(localPoint: backGestureView.center, videoPreviewLayer: videoPreviewLayer, captureDevice: currentCamera)
        UIView.animate(withDuration: 0.5) {
            self.tipsLabel.alpha = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            UIView.animate(withDuration: 0.5) {
                self.tipsLabel.alpha = 0
            }
        }
    }
    
    private func showAutoFoucusView(point: CGPoint) {
        autoFocusView.removeFromSuperview()
        view.addSubview(autoFocusView)
        autoFocusView.center = point
        autoFocusView.transform = CGAffineTransformMakeScale(1.3, 1.3)
        UIView.animate(withDuration: 0.5) {
            self.autoFocusView.transform = CGAffineTransformIdentity
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.autoFocusView.removeFromSuperview()
        }
    }
}

@objc
extension CameraViewController {
    
    fileprivate func closeButtonTapped(sender: UIButton) {
        dismiss(animated: true)
    }
    
    fileprivate func tap(sender: UITapGestureRecognizer) {
        let point = sender.location(in: backGestureView)
        showAutoFoucusView(point: point)
        CameraTool.focusAtPoint(localPoint: backGestureView.center, videoPreviewLayer: videoPreviewLayer, captureDevice: currentCamera)
    }
    
    fileprivate func pin(pinGes: UIPinchGestureRecognizer) {
        switch pinGes.state {
        case .began:
            currentZoomFactor = currentCamera?.videoZoomFactor ?? 1.0
        case .changed:
            currentZoomFactor = currentZoomFactor * pinGes.scale
            CameraTool.setVideoZoomFactor(currentZoomFactor, captureDevice: currentCamera)
        default:
            break
        }
    }
}

// MARK: - CameraBottomContainerViewDelegate
extension CameraViewController: CameraBottomContainerViewDelegate {
    func flashButtonDidClick(button: UIButton) {
        button.isSelected = !button.isSelected
        flashMode = flashMode == .auto ? .off : .auto
    }
    
    func rotateButtonDidClick(button: UIButton) {
        let newDevice = CameraTool.rotateCameraBackOrFront(captureSession)
        if newDevice == nil {
            print("转换摄像头失败")
        }
        currentCamera = newDevice
    }
    
    /// 开始拍照
    func takePhotoDidClick(tap: UITapGestureRecognizer) {
        guard let photoOutPut = photoOutPut else { return }
        // 设置照片输出的格式
        let settings = AVCapturePhotoSettings()
        if photoOutPut.availablePhotoCodecTypes.contains(.jpeg) {
            settings.photoQualityPrioritization = .balanced
        }
        
        if currentCamera?.hasTorch ?? false {
            try? currentCamera?.lockForConfiguration()
            currentCamera?.torchMode = flashMode == .auto ? .on : .off
            currentCamera?.unlockForConfiguration()
        }
        
        // 拍照并将输出委托给自身
        photoOutPut.capturePhoto(with: settings, delegate: self)
    }
    
    func enterButtonClick(button: UIButton) {
        if bottomView.currentOperate == .photo {
            savePhotoData()
        } else {
            // 视频返回地址
            dismiss(animated: true)
        }
    }
    
    func cancelButtonClick(button: UIButton) {
        if bottomView.currentOperate == .photo {
            previewPhotoScrollView.isHidden = true
            previewPhotoScrollView.zoomScale = 1.0
        } else {
            // 是否删除已经录制的视频？
            videoPlayerLayer?.isHidden = true
        }
        bottomView.resetUIState(true)
        handleAutoFocusView()
    }
    
    /// 开始录制视频
    func startRecordVideo() {
        closeButton.isHidden = true
        
        startTimer()
        
        // 创建一个保存录制的视频文件名
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destPath = documentDirectory.appendingPathComponent("EOS_Camera")
        
        if (!FileManager.default.fileExists(atPath: destPath.path)) {
            do {
                try FileManager.default.createDirectory(atPath: destPath.path, withIntermediateDirectories: true)
            } catch  {
                print("创建相机拍摄存储目录错误 -video - %@", error.localizedDescription)
                return
            }
        }
        
        let outputFileName = String(format: "%ld.mp4", Int(Date().timeIntervalSince1970 * 1000))
        let outputFileURL = destPath.appendingPathComponent(outputFileName)
        videoOutPut?.startRecording(to: outputFileURL, recordingDelegate: self)
    }
    
    /// 结束视频录制
    func endRecordVideo() {
        self.timer?.invalidate()
        self.timer = nil
        closeButton.isHidden = false
        videoOutPut?.stopRecording()
    }
}


// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // 关闭闪光灯
        closeFlashMode()
        
        if let imageData = photo.fileDataRepresentation() {
            currentImageData = imageData
            let image = UIImage(data: imageData)
            currentImage = image
            previewPhotoScrollView.isHidden = false
            previewImageView.image = image
            bottomView.resetUIState(false)
        }
    }
    
    func closeFlashMode() {
        if currentCamera?.hasTorch ?? false {
            try? currentCamera?.lockForConfiguration()
            currentCamera?.torchMode = .off
            currentCamera?.unlockForConfiguration()
        }
    }
    
    func savePhotoData() {
        guard let imageData = currentImageData else { return }
        // 将照片数据保存到沙盒
        let fileManager = FileManager.default
        
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let destPath = documentDirectory.appendingPathComponent("EOS_Camera")
        if (!FileManager.default.fileExists(atPath: destPath.path)) {
            do {
                try FileManager.default.createDirectory(atPath: destPath.path, withIntermediateDirectories: true)
            } catch  {
                print("创建相机拍摄存储目录错误 - photo - %@", error.localizedDescription)
                return
            }
        }
        
        let timerInterval = Date().timeIntervalSince1970
        let fileName = String(format: "%ld.jpg", Int(timerInterval * 1000))
        let filePath = destPath.appendingPathComponent(fileName)
        currentImagePath = filePath.path

        do {
            try imageData.write(to: filePath)
            print("照片已保存到沙盒：\(filePath)")
            let imageInfo = formatImageInfo(fileName: fileName, image: currentImage, data: currentImageData, path: currentImagePath)
            currentImageClosure?(imageInfo)
        } catch {
            print(error.localizedDescription)
        }
        closeButtonTapped(sender: UIButton())
    }
    
    private func formatImageInfo(
        fileName: String?,
        image: UIImage?,
        data: Data?,
        path: String?
    ) -> [String: Any] {
        let name: String = fileName ?? ""
        let size: Int = data?.count ?? 0
        let width: CGFloat = image?.size.width ?? 0.0
        let height: CGFloat = image?.size.height ?? 0.0
        let type = "image"
        let wrapPath = path ?? ""
        let url:String = "http://www.baidu.com:1000?path=" + wrapPath
        
        let info: [String: Any] = [
            "name": name,
            "size": size,
            "width": width,
            "height": height,
            "type": type,
            "path": wrapPath,
            "url": url
        ]
        return info
    }
}


// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error != nil {
            print("录制视频错误-- \(String(describing: error?.localizedDescription))")
        } else {
            if videoPlayer == nil {
                videoPlayer = CameraAVPlayer(url: outputFileURL)
                guard let playerLayer = videoPlayer?.playerLayer else { return }
                playerLayer.videoGravity = .resizeAspectFill
                playerLayer.frame = Constants.preViewImageFrame
                videoPlayerLayer = playerLayer
                view.layer.addSublayer(playerLayer)
            } else {
                videoPlayerLayer?.isHidden = false
                videoPlayer?.replaceVideo(url: outputFileURL)
            }
        }
        print(outputFileURL.absoluteString)
        
    }
    
    func startTimer() {
        currentVideoDuration = 0
        let timeInterVal: TimeInterval = 0.1
        timer = Timer.scheduledTimer(withTimeInterval: timeInterVal, repeats: true, block: { timer in
            self.currentVideoDuration += timeInterVal
            self.bottomView.circleProgressView.progress = self.currentVideoDuration / self.videoMaxDuration
            
            if self.currentVideoDuration > self.videoMaxDuration {
                self.timer?.invalidate()
                self.timer = nil
                self.endRecordVideo()
                self.bottomView.endRecordVideo()
            }
        })
    }
}

// MARK: - UIScrollViewDelegate
extension CameraViewController: UIScrollViewDelegate {
    
    func centerOfScrollViewContent(scrollView: UIScrollView) -> CGPoint {
        let offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ?
            (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0
        
        let offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ?
            (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0
        
        let actualCenter = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX,
                                   y: scrollView.contentSize.height * 0.5 + offsetY)
        return actualCenter
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        previewImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        previewImageView.center = centerOfScrollViewContent(scrollView: scrollView)
    }
}
