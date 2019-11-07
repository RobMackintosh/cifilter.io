//
//  FilterWorkshopView.swift
//  CIFilter.io
//
//  Created by Noah Gilmore on 12/10/18.
//  Copyright © 2018 Noah Gilmore. All rights reserved.
//

import UIKit
import RxSwift
import Combine

final class FilterWorkshopView: UIView {
    // TODO: this is a VERY ugly hack
    static var globalPanGestureRecognizer: UIPanGestureRecognizer!
    private var needsZoomScaleUpdate: Bool = false
    private let scrollView = UIScrollView()
    private let applicator: AsyncFilterApplicator
    private let bag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    private lazy var contentView: FilterWorkshopContentView = {
        return FilterWorkshopContentView(applicator: self.applicator)
    }()
    private let consoleView = ImageWorkshopConsoleView()

    var didChooseAddImage: PassthroughSubject<(String, CGRect), Never> { return contentView.didChooseAddImage }
    var didChooseSaveImage: PassthroughSubject<Void, Never> {
        return contentView.didChooseSaveImage
    }

    init(applicator: AsyncFilterApplicator) {
        self.applicator = applicator
        super.init(frame: .zero)
        self.backgroundColor = ColorCompatibility.systemBackground
        self.addSubview(scrollView)

        scrollView.maximumZoomScale = 20
        scrollView.minimumZoomScale = 0.1
        scrollView.delegate = self

        scrollView.edgesToSuperview()
        scrollView.addSubview(contentView)
        // scroll view content size constraint:
        contentView.edgesToSuperview()

        consoleView.disableTranslatesAutoresizingMaskIntoConstraints()
        addSubview(consoleView)
        consoleView.leadingAnchor <=> self.leadingAnchor ++ 20
        consoleView.topAnchor <=> self.topAnchor ++ 20

        FilterWorkshopView.globalPanGestureRecognizer = scrollView.panGestureRecognizer

        applicator.events.observeOn(MainScheduler.instance).subscribe(onNext: { event in
            switch event {
            case .generationStarted:
                self.consoleView.update(for: .showActivity)
            case let .generationCompleted(_, totalTime, _):
                self.consoleView.update(for: .hideActivity)

                // Only show a success message if the generation took more than 4 seconds, so as
                // not to be intrusive for filters that don't take much time to apply
                if totalTime > 4 {
                    self.consoleView.update(for: .success(message: "Generation completed in \(String(format: "%.2f", totalTime)) seconds", animated: true))
                }
            case let .generationErrored(error):
                self.consoleView.update(for: .hideActivity)

                if case .needsMoreParameters = error {
                    return
                }

                self.consoleView.update(for: .error(message: "Generation errored. Please submit an issue on github. Error: \(error)", animated: true))
            }
        }).disposed(by: bag)

        scrollView.addTapHandler(numberOfTapsRequired: 2).sink { recognizer in
            if self.scrollView.zoomScale > self.scrollView.minimumZoomScale {
                self.scrollView.setZoomScale(self.scrollView.minimumZoomScale, animated: true)
            } else {
                let location = recognizer.location(in: self.contentView)
                let width: CGFloat = ImageChooserView.artboardSize * 1.6
                let height: CGFloat = ImageChooserView.artboardSize * 1.6
                let rect = CGRect(x: location.x - width / 2, y: location.y - height / 2, width: width, height: height)
                self.scrollView.zoom(to: rect, animated: true)
            }
        }.store(in: &self.cancellables)

        needsZoomScaleUpdate = true // we need to update the zoom scale on first layout
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.layoutIfNeeded()

        let widthScale = scrollView.bounds.width / contentView.bounds.width
        let heightScale = scrollView.bounds.height / contentView.bounds.height
        let minScale = min(widthScale, heightScale)

        if !minScale.isInfinite {
            scrollView.minimumZoomScale = minScale
        }

        if needsZoomScaleUpdate && !minScale.isInfinite {
            scrollView.zoomScale = minScale
            needsZoomScaleUpdate = false
        }
    }

    func set(filter: FilterInfo) {
        contentView.set(filter: filter)
    }

    func setImage(_ image: UIImage, forParameterNamed name: String) {
        contentView.setImage(image, forParameterNamed: name)
    }
}

extension FilterWorkshopView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
}
