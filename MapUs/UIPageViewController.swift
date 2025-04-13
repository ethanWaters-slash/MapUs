//
//  UIPageViewController.swift
//  MapUs
//
//  Created by Ethan Waters on 3/8/24.
//
import UIKit
import CoreImage
class ImageReviewViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var images: [UIImage] = []
    private var pageViewController: UIPageViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the page view controller and its initial content
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self

        if let startingViewController = viewControllerAtIndex(index: 0) {
            pageViewController.setViewControllers([startingViewController], direction: .forward, animated: true, completion: nil)
        }

        // Add the page view controller as a child view controller
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        let closeButton = UIButton(type: .system)
            closeButton.setTitle("Close", for: .normal)
            closeButton.setTitleColor(.white, for: .normal)
            closeButton.layer.cornerRadius = 40
            closeButton.backgroundColor = .systemBlue
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
                
            view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 80),
            closeButton.heightAnchor.constraint(equalToConstant: 80)
        ])

        // Set the page view controller's frame as needed
        pageViewController.view.frame = view.bounds

        pageViewController.didMove(toParent: self)
        let saveButton = UIButton(type: .system)
            saveButton.setTitle("Save", for: .normal)
            saveButton.backgroundColor = .systemBlue
            saveButton.setTitleColor(.white, for: .normal)
            saveButton.layer.cornerRadius = 40
            saveButton.translatesAutoresizingMaskIntoConstraints = false
            saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
            
            //view.addSubview(saveButton)
        
        let shareButton = UIButton(type: .system)
            shareButton.setTitle("Share", for: .normal)
            shareButton.backgroundColor = .systemBlue
            shareButton.setTitleColor(.white, for: .normal)
            shareButton.layer.cornerRadius = 40
            shareButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(shareButton)
            
            NSLayoutConstraint.activate([
                shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                shareButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant:20),
                shareButton.widthAnchor.constraint(equalToConstant: 80),
                shareButton.heightAnchor.constraint(equalToConstant: 80)
            ])
            
            shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
    }
    @objc func saveButtonTapped() {
        // Determine the current page index
        if let currentViewController = pageViewController.viewControllers?.first as? ImageContentViewController,
           let imageToSave = currentViewController.imageView.image {
            // Save the image to the camera roll
            UIImageWriteToSavedPhotosAlbum(imageToSave, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    @objc func shareButtonTapped() {
        // Assume that the currently viewed image can be accessed via a property or method. For example:
        guard let currentImage = getCurrentImage() else {
            print("No image available for sharing.")
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [currentImage], applicationActivities: nil)
        
        // For iPads, configure the presentation controller for the activity view controller.
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true, completion: nil)
    }

    func getCurrentImage() -> UIImage? {
        // Implementation depends on how images are being displayed/stored.
        // For example, if you're using a UIPageViewController, determine the currently displayed view controller.
        if let currentViewController = pageViewController.viewControllers?.first as? ImageContentViewController {
            return currentViewController.imageView.image
        }
        return nil
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // We got back an error!
            showAlertWith(title: "Save error", message: error.localizedDescription)
        } else {
            //showAlertWith(title: "Saved!", message: "Your image has been saved to your photos.")
        }
    }

    func showAlertWith(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    @objc func closeButtonTapped() {
        pageViewController.dismiss(animated: true)
        }
    func viewControllerAtIndex(index: Int) -> ImageContentViewController? {
        if index >= images.count || images.count == 0 {
            return nil
        }

        // Instantiate and configure the content view controller for the given index
        let contentViewController = ImageContentViewController()
        contentViewController.image = images[index]
        contentViewController.pageIndex = index
        return contentViewController
    }

    // MARK: - UIPageViewControllerDataSource methods
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let viewController = viewController as? ImageContentViewController, let index = viewController.pageIndex, index > 0 {
            return viewControllerAtIndex(index: index - 1)
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let viewController = viewController as? ImageContentViewController, let index = viewController.pageIndex, index < images.count - 1 {
            return viewControllerAtIndex(index: index + 1)
        }
        return nil
    }
    func enhanceImageQuality(image: UIImage) -> UIImage? {
        let context = CIContext(options: nil)
        if let filter = CIFilter(name: "CISharpenLuminance", parameters: [kCIInputImageKey: CIImage(image: image)!, "inputSharpness": 0.5]),
           let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}
class ImageContentViewController: UIViewController {
    var imageView: UIImageView!
    var image: UIImage?
    var pageIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView = UIImageView(frame: view.bounds)
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        view.addSubview(imageView)
    }
}
