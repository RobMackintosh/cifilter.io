//
//  ImageChooserView.swift
//  CIFilter.io
//
//  Created by Noah Gilmore on 12/23/18.
//  Copyright © 2018 Noah Gilmore. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture

import UIKit

final class ImageChooserAddView: UIView {
    let didTap = PublishSubject<Void>()
    private let bag = DisposeBag()
    
    private var plusLabel: UILabel = {
        let view = UILabel()
        view.text = "Add"
        view.accessibilityLabel = "Add Image"
        view.font = UIFont.systemFont(ofSize: 30)
        view.textColor = ColorCompatibility.label
        view.setContentHuggingPriority(.required, for: .vertical)
        return view
    }()

    init() {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.widthAnchor <=> ImageChooserView.imageSize
        self.heightAnchor <=> ImageChooserView.imageSize
        self.backgroundColor = Colors.availabilityBlue.color

        addSubview(plusLabel)
        plusLabel.translatesAutoresizingMaskIntoConstraints = false
        plusLabel.centerXAnchor <=> self.centerXAnchor
        plusLabel.centerYAnchor <=> self.centerYAnchor
        self.rx.tapGesture().when(.ended).subscribe({ _ in
            self.didTap.onNext(())
        }).disposed(by: bag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private let artboardPadding: CGFloat = 20
private let artboardSpacing: CGFloat = 20
private let numImagePerArtboardRow = 3

final class ImageChooserView: UIView {
    static let artboardSize: CGFloat = 650
    private let bag = DisposeBag()
    fileprivate let chooseImageSubject = PublishSubject<UIImage>()
    lazy var didChooseImage = {
        return ControlEvent<UIImage>(events: chooseImageSubject)
    }()
    var didChooseAdd = PublishSubject<UIView>()

    static var imageSize: CGFloat {
        return (ImageChooserView.artboardSize - (artboardPadding * 2) - (artboardSpacing * 2)) / CGFloat(numImagePerArtboardRow)
    }

    private let verticalStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = artboardSpacing
        view.alignment = .leading
        return view
    }()

    private func newStackView() -> UIStackView {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = artboardSpacing
        return view
    }

    private let addView = ImageChooserAddView()
    private lazy var dropInteraction: UIDropInteraction = {
        return UIDropInteraction(delegate: self)
    }()

    init() {
        super.init(frame: .zero)
        self.backgroundColor = ColorCompatibility.quaternarySystemFill

        addSubview(verticalStackView)
        verticalStackView.edgesToSuperview(insets: UIEdgeInsets(all: artboardPadding))

        var currentStackView: UIStackView! = nil
        for (i, builtInImage) in BuiltInImage.all.enumerated() {
            if i % numImagePerArtboardRow == 0 {
                currentStackView = newStackView()
                verticalStackView.addArrangedSubview(currentStackView)
            }
            currentStackView.addArrangedSubview(self.newImageView(image: builtInImage))
        }

        if BuiltInImage.all.count % numImagePerArtboardRow == 0 {
            currentStackView = newStackView()
            verticalStackView.addArrangedSubview(currentStackView)
        }
        currentStackView.addArrangedSubview(addView)

        addView.didTap.subscribe(onNext: {
            self.didChooseAdd.onNext(self.addView)
        }).disposed(by: bag)

        self.addInteraction(self.dropInteraction)
        print("HOLAY")
    }

    private func newImageView(image: BuiltInImage) -> UIImageView {
        let imageView = UIImageView(image: image.imageForImageChooser)
        imageView.heightAnchor <=> ImageChooserView.imageSize
        imageView.widthAnchor <=> ImageChooserView.imageSize
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.layer.borderColor = UIColor(rgb: 0xdddddd).cgColor
        imageView.layer.borderWidth = 1
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.rx.tapGesture().when(.ended).subscribe({ tap in
            self.chooseImageSubject.onNext(image.image)
        }).disposed(by: self.bag)
        return imageView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ImageChooserView: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        // Ensure the drop session has an object of the appropriate type
        let result = session.canLoadObjects(ofClass: UIImage.self)
        print("Assking about handlinng items: \(result)")
        return result
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        // Propose to the system to copy the item from the source app
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        print("Enter!")
    }

    func dropInteraction(_ interaction: UIDropInteraction, concludeDrop session: UIDropSession) {
        print("Conclude")
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        print("Session exit")
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
        print("Session ennd")
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        // Consume drag items (in this example, of type UIImage).
        print("Loading objects")
        session.loadObjects(ofClass: UIImage.self) { imageItems in
            print("Loaded objects: \(imageItems)")
            let images = imageItems as! [UIImage]
            self.chooseImageSubject.onNext(images.first!)
        }
    }
}
