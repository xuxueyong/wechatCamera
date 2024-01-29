//
//  CameraTool.swift
//  CameraDemo01
//
//  Created by 徐雪勇 on 2023/7/12.
//

import Foundation
import AVFoundation

struct CameraTool {
    /// 获取后置摄像头
    static func backCamera() -> AVCaptureDevice? {
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("无法获取后置摄像头")
            return nil
        }
        return backCamera
    }
    
    /// 创建摄像头输入流
    static func createCamerInput(camera: AVCaptureDevice?, captureSession: AVCaptureSession?) {
        guard let camera = camera else { return }
        guard let captureSession = captureSession else { return }
        do {
            // 创建输入流
            let input = try AVCaptureDeviceInput(device: camera)
            // 将输入流添加进会话
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                print("无法添加摄像头输入到会话")
            }
        } catch {
            print("创建摄像头输入流错误 = \(error.localizedDescription)")
        }
    }
    
    /// 创建音频输入流
    static func createAudioInput(captureSession: AVCaptureSession?) {
        guard let audioDevice = audioDevice() else { return }
        guard let captureSession = captureSession else { return }
        do {
           let audioInput = try AVCaptureDeviceInput(device: audioDevice)

           if captureSession.canAddInput(audioInput) {
               captureSession.addInput(audioInput)
           } else {
               print("无法添加音频输入到会话")
           }
        } catch {
            print("创建音频输入流时出错：\(error.localizedDescription)")
        }
    }
    
    /// 获取音频设备
    static func audioDevice() -> AVCaptureDevice? {
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            print("无法访问麦克风")
            return nil
        }
        return audioDevice
    }
    
    /// 创建图片输出， 并添加到会话中
    static func createPhotoOutPutAndAddSession(_ captureSession: AVCaptureSession?) -> AVCapturePhotoOutput {
        let photoOutPut = AVCapturePhotoOutput()
        guard let captureSession = captureSession else {
            return photoOutPut
        }
        // 将照片输出对象添加到会话
        if captureSession.canAddOutput(photoOutPut) {
            captureSession.addOutput(photoOutPut)
        } else {
            print("无法添加-photo-输出设备到会话")
        }
        return photoOutPut
    }
    
    /// 创建视频输出， 并添加到会话中
    static func createVideoOutPutAndAddSession(_ captureSession: AVCaptureSession?) -> AVCaptureMovieFileOutput {
        // 创建视频输出对象
        let videoOutPut = AVCaptureMovieFileOutput()
        guard let captureSession = captureSession else {
            return videoOutPut
        }

        if captureSession.canAddOutput(videoOutPut) {
            captureSession.addOutput(videoOutPut)
        } else {
            print("无法添加-video-输出设备到会话")
        }
        videoOutPut.movieFragmentInterval = .invalid
        return videoOutPut
    }
    
    ///  摄像头聚焦到某个点
    static func focusAtPoint(localPoint: CGPoint, videoPreviewLayer: AVCaptureVideoPreviewLayer?, captureDevice: AVCaptureDevice?) {
        guard let cameraPoint = videoPreviewLayer?.captureDevicePointConverted(fromLayerPoint: localPoint) else { return }
        guard let captureDevice = captureDevice else { return }
        do {
            try captureDevice.lockForConfiguration()
            if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
                if captureDevice.isFocusPointOfInterestSupported {
                    captureDevice.focusPointOfInterest = cameraPoint
                }
                captureDevice.focusMode = .continuousAutoFocus
            }
            if captureDevice.isExposureModeSupported(.continuousAutoExposure) {
                if captureDevice.isExposurePointOfInterestSupported {
                    captureDevice.exposurePointOfInterest = cameraPoint
                }
                captureDevice.exposureMode = .continuousAutoExposure
            }
            captureDevice.unlockForConfiguration()
        } catch {
            print("设置聚焦点错误：\(error.localizedDescription)")
        }
    }
    
    /// 调节焦距
    static func setVideoZoomFactor(_ currentZoomFactor: CGFloat, captureDevice: AVCaptureDevice?) {
        if currentZoomFactor <= maxZoomFactor(captureDevice) && currentZoomFactor >= minZoomFactor(captureDevice) {
            try? captureDevice?.lockForConfiguration()
            captureDevice?.videoZoomFactor = currentZoomFactor
            captureDevice?.unlockForConfiguration()
        }
    }
    
    private static func minZoomFactor(_ captureDevice: AVCaptureDevice?) -> CGFloat {
        captureDevice?.minAvailableVideoZoomFactor ?? 1.0
    }
    
    private static func maxZoomFactor(_ captureDevice: AVCaptureDevice?) -> CGFloat {
        var factor = captureDevice?.maxAvailableVideoZoomFactor ?? 1.0
        if factor > 6.0 {
            factor = 6.0
        }
        return factor
    }
    
    /// 转换前后置摄像头
    static func rotateCameraBackOrFront(_ captureSession: AVCaptureSession?) -> AVCaptureDevice? {
        captureSession?.beginConfiguration()

        guard let currentInput = captureSession?.inputs.first as? AVCaptureDeviceInput else {
            return nil
        }

        captureSession?.removeInput(currentInput)

        let newPosition: AVCaptureDevice.Position = (currentInput.device.position == .back) ? .front : .back

        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else { return nil }

        guard let newInput = try? AVCaptureDeviceInput(device: newDevice) else { return nil }

        if captureSession?.canAddInput(newInput) ?? false {
            captureSession?.addInput(newInput)
        }
        
        captureSession?.commitConfiguration()
        
        return newDevice
    }
}
