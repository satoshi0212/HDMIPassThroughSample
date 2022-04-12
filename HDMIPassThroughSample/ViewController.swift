import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController {

    @IBOutlet private weak var arscnView: ARSCNView!
    
    private let defaultSize = CGSize(width: 1920, height: 1080)
    private let defalutPreferredFramesPerSecond = 30

    private var additionalWindows: [UIWindow] = []
    private var secondScreenView: UIView?
    private var sendImageView: UIImageView!
    private var displayTimer: CADisplayLink!

    override func viewDidLoad() {
        super.viewDidLoad()

        arscnView.scene = SCNScene()

        NotificationCenter.default.addObserver(forName: UIScreen.didConnectNotification, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            guard let newScreen = notification.object as? UIScreen else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                
                let matchingWindowScene = UIApplication.shared.connectedScenes.first {
                    guard let windowScene = $0 as? UIWindowScene else { return false }
                    return windowScene.screen == newScreen
                } as? UIWindowScene
                
                guard let connectedWindowScene = matchingWindowScene else {
                    fatalError("Connected windowScene was not found")
                }
                
                let newWindow = UIWindow(frame: CGRect(origin: .zero, size: self.defaultSize))
                newWindow.windowScene = connectedWindowScene
                newWindow.rootViewController = UIViewController()
                newWindow.isHidden = false
                newWindow.screen.overscanCompensation = .none
                
                self.initializeView()
                newWindow.addSubview(self.secondScreenView!)
                
                self.additionalWindows.append(newWindow)
                
                self.displayTimer = CADisplayLink(target: self, selector: #selector(self.updateView(_:)))
                self.displayTimer.preferredFramesPerSecond = self.defalutPreferredFramesPerSecond
                self.displayTimer.add(to: .main, forMode: .common)
            }
        }

        NotificationCenter.default.addObserver(forName: UIScreen.didDisconnectNotification, object: nil, queue: nil) { (notification) in
            let screen = notification.object as! UIScreen
            for window in self.additionalWindows {
                if window.screen == screen {
                    let index = self.additionalWindows.firstIndex(of: window)
                    self.additionalWindows.remove(at: index!)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportedVideoFormats.count > 2 {
            configuration.videoFormat = ARWorldTrackingConfiguration.supportedVideoFormats[1]
            
    //        (lldb) po ARWorldTrackingConfiguration.supportedVideoFormats
    //        ▿ 3 elements
    //          - 0 : <ARVideoFormat: 0x280846f80 imageResolution=(1920, 1440) framesPerSecond=(60) captureDeviceType=AVCaptureDeviceTypeBuiltInWideAngleCamera captureDevicePosition=(1)>
    //          - 1 : <ARVideoFormat: 0x280846f30 imageResolution=(1920, 1080) framesPerSecond=(60) captureDeviceType=AVCaptureDeviceTypeBuiltInWideAngleCamera captureDevicePosition=(1)>
    //          - 2 : <ARVideoFormat: 0x280846e40 imageResolution=(1280, 720) framesPerSecond=(60) captureDeviceType=AVCaptureDeviceTypeBuiltInWideAngleCamera captureDevicePosition=(1)>
        }
        arscnView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        arscnView.session.run(configuration, options: [.resetTracking])
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        arscnView.session.pause()
    }
    
    private func initializeView() {
        secondScreenView = UIView(frame: CGRect(origin: .zero, size: defaultSize))
        secondScreenView!.backgroundColor = .clear
        sendImageView = UIImageView(frame: CGRect(origin: .zero, size: defaultSize))
        secondScreenView!.addSubview(sendImageView)
    }

    @objc private func updateView(_ displayLink: CADisplayLink) {
        guard let currentFrame = arscnView.session.currentFrame else { return }
        let capturedImage = currentFrame.capturedImage
        sendImageView.image = UIImage(ciImage: CIImage(cvPixelBuffer: capturedImage))
    }
}
