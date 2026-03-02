import SwiftUI
import AVFoundation
import UIKit

/// Wrapper UIViewControllerRepresentable para câmera AVFoundation.
struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: CameraViewControllerDelegate {
        let parent: CameraView
        init(parent: CameraView) { self.parent = parent }

        func didCapture(image: UIImage) {
            parent.capturedImage = image
            parent.dismiss()
        }

        func didCancel() {
            parent.dismiss()
        }
    }
}

// MARK: – Protocol

protocol CameraViewControllerDelegate: AnyObject {
    func didCapture(image: UIImage)
    func didCancel()
}

// MARK: – UIViewController

final class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let output = AVCapturePhotoOutput()
    private var flashMode: AVCaptureDevice.FlashMode = .auto

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSession()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }

    // MARK: – Session

    private func setupSession() {
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input  = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input),
              session.canAddOutput(output) else { return }
        session.addInput(input)
        session.addOutput(output)

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)
        previewLayer = preview
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    // MARK: – UI

    private func setupUI() {
        // Botão fechar
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.addTarget(self, action: #selector(closeCamera), for: .touchUpInside)
        view.addSubview(closeBtn)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false

        // Botão captura
        let captureBtn = UIButton(type: .custom)
        captureBtn.backgroundColor = .white
        captureBtn.layer.cornerRadius = 36
        captureBtn.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        captureBtn.layer.borderWidth = 4
        captureBtn.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureBtn)
        captureBtn.translatesAutoresizingMaskIntoConstraints = false

        // Botão flash
        let flashBtn = UIButton(type: .system)
        flashBtn.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
        flashBtn.tintColor = .white
        flashBtn.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        view.addSubview(flashBtn)
        flashBtn.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            closeBtn.widthAnchor.constraint(equalToConstant: 44),
            closeBtn.heightAnchor.constraint(equalToConstant: 44),

            flashBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            flashBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            flashBtn.widthAnchor.constraint(equalToConstant: 44),
            flashBtn.heightAnchor.constraint(equalToConstant: 44),

            captureBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            captureBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureBtn.widthAnchor.constraint(equalToConstant: 72),
            captureBtn.heightAnchor.constraint(equalToConstant: 72),
        ])
    }

    // MARK: – Actions

    @objc private func closeCamera() {
        delegate?.didCancel()
    }

    @objc private func capturePhoto() {
        #if targetEnvironment(simulator)
        // Simulator has no camera — return a placeholder so the app doesn't crash
        if let placeholder = UIImage(systemName: "photo.on.rectangle") {
            delegate?.didCapture(image: placeholder)
        }
        return
        #endif
        guard output.connections.first != nil else { return }
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        output.capturePhoto(with: settings, delegate: self)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    @objc private func toggleFlash() {
        flashMode = flashMode == .off ? .auto : .off
    }
}

// MARK: – Photo capture delegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        delegate?.didCapture(image: image)
    }
}
