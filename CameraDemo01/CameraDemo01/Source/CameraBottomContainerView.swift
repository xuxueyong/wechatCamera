//
//  CameraBottomContainerView.swift
//  CameraDemo01
//
//  Created by 徐雪勇 on 2023/7/11.
//

import UIKit

protocol CameraBottomContainerViewDelegate: AnyObject {
    func flashButtonDidClick(button: UIButton)
    func rotateButtonDidClick(button: UIButton)
    func takePhotoDidClick(tap: UITapGestureRecognizer)
    func enterButtonClick(button: UIButton)
    func cancelButtonClick(button: UIButton)
    func startRecordVideo()
    func endRecordVideo()
}

extension CameraBottomContainerView {
    enum CurrentOperate {
        case photo
        case video
    }
}

class CameraBottomContainerView: UIView {
    
    var currentOperate: CurrentOperate = .photo
    
    weak var delegate: CameraBottomContainerViewDelegate?
    
    lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        return stackView
    }()
    
    // 闪光灯
    lazy var flashButton: CameraBaseButton = {
        let button = CameraBaseButton()
        button.hitSize = CGSize(width: 50, height: 50)
        button.imageView?.contentMode = .scaleAspectFit
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "flash_close"), for: .normal)
        button.setImage(UIImage(named: "flash_open"), for: .selected)
        button.addTarget(self, action: #selector(flashButtonTapped(sender:)), for: .touchUpInside)
        return button
    }()
    
    // 摄像头反转
    lazy var rotateButton: CameraBaseButton = {
        let button = CameraBaseButton()
        button.hitSize = CGSize(width: 50, height: 50)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageView?.contentMode = .scaleAspectFit
        button.setImage(UIImage(named: "camera_rotate"), for: .normal)
        button.addTarget(self, action: #selector(rotateButtonTapped(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var circleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        view.layer.cornerRadius = 37
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        return view
    }()
    
    lazy var centerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 29
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var enterButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        button.setTitle("确定", for: .normal)
        button.addTarget(self, action: #selector(enterButtonTapped(sender:)), for: .touchUpInside)
        button.imageView?.contentMode = .scaleAspectFit
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var cancelButton: CameraBaseButton = {
        let button = CameraBaseButton()
        button.isHidden = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        button.setTitle("取消", for: .normal)
        button.addTarget(self, action: #selector(cancelButtonTapped(sender:)), for: .touchUpInside)
        button.imageView?.contentMode = .scaleAspectFit
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var circleProgressView: CircularProgressBarView = {
        let progressView = CircularProgressBarView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        return progressView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        addCustomGestures()
    }
    
    func setupViews() {
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 34),
            containerStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -34),
            containerStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 24),
            containerStackView.heightAnchor.constraint(equalToConstant: 74),
            
            circleView.widthAnchor.constraint(equalToConstant: 74),
            circleView.heightAnchor.constraint(equalToConstant: 74),
            
            flashButton.widthAnchor.constraint(equalToConstant: 28),
            flashButton.heightAnchor.constraint(equalToConstant: 28),
            
            rotateButton.widthAnchor.constraint(equalToConstant: 28),
            rotateButton.heightAnchor.constraint(equalToConstant: 28),
            
            enterButton.widthAnchor.constraint(equalToConstant: 72),
            enterButton.heightAnchor.constraint(equalToConstant: 72),
            
            cancelButton.widthAnchor.constraint(equalToConstant: 72),
            cancelButton.heightAnchor.constraint(equalToConstant: 72),
        ])
        
        circleView.addSubview(centerView)
        NSLayoutConstraint.activate([
            centerView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            centerView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
            centerView.widthAnchor.constraint(equalToConstant: 58),
            centerView.heightAnchor.constraint(equalToConstant: 58),
        ])
        
        containerStackView.addArrangedSubview(cancelButton)
        containerStackView.addArrangedSubview(enterButton)
        containerStackView.addArrangedSubview(flashButton)
        containerStackView.addArrangedSubview(circleView)
        containerStackView.addArrangedSubview(rotateButton)
    }
    
    /// flag 为 true 代表拍照状态， false 代表 preview image 状态
    func resetUIState(_ flag: Bool) {
        flashButton.isHidden = !flag
        circleView.isHidden = !flag
        rotateButton.isHidden = !flag
        enterButton.isHidden = flag
        cancelButton.isHidden = flag
    }
    
    func addCustomGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(takePhoto(tap:)))
        circleView.addGestureRecognizer(tap)
        
        let longPregress = UILongPressGestureRecognizer(target: self, action: #selector(longPregress(pregress:)))
        // 先注释视频录制功能
        circleView.addGestureRecognizer(longPregress)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@objc
extension CameraBottomContainerView {
    
    func flashButtonTapped(sender: UIButton) {
        delegate?.flashButtonDidClick(button: sender)
    }
    
    func rotateButtonTapped(sender: UIButton) {
        delegate?.rotateButtonDidClick(button: sender)
    }
    
    func takePhoto(tap: UITapGestureRecognizer) {
        currentOperate = .photo
        delegate?.takePhotoDidClick(tap: tap)
    }
    
    func enterButtonTapped(sender: UIButton) {
        delegate?.enterButtonClick(button: sender)
    }
    
    func cancelButtonTapped(sender: UIButton) {
        delegate?.cancelButtonClick(button: sender)
    }
    
    func longPregress(pregress: UILongPressGestureRecognizer) {
        let state = pregress.state
        switch state {
        case .began:
            currentOperate = .video
            recordVideoStateUpdateUIState()
            delegate?.startRecordVideo()
        case .ended:
            endRecordVideo()
            delegate?.endRecordVideo()
        default:
            break
        }
    }
    
    func recordVideoStateUpdateUIState() {
        circleProgressView.center = circleView.center
        circleView.addSubview(circleProgressView)
        centerView.transform = CGAffineTransformMakeScale(0.5, 0.5)
        flashButton.isHidden = true
        circleView.layer.borderWidth = 0
        rotateButton.isHidden = true
    }
    
    func endRecordVideo() {
        circleProgressView.removeFromSuperview()
        centerView.transform = CGAffineTransformIdentity
        circleView.layer.borderWidth = 2
        resetUIState(false)
    }
}
