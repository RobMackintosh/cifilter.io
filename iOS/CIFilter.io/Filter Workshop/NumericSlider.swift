//
//  NumericSlider.swift
//  CIFilter.io
//
//  Created by Noah Gilmore on 12/24/18.
//  Copyright © 2018 Noah Gilmore. All rights reserved.
//

import UIKit

final class NumericSlider: UIControl, ControlValueReporting {
    private(set) var value: Float = 0

    private let slider = UISlider()
    private let minimumLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.monospacedBodyFont()
        return view
    }()
    private let maximumLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.monospacedBodyFont()
        return view
    }()
    private let valueLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.monospacedBodyFont()
        return view
    }()

    private let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 10
        return view
    }()

    init(min: Float, max: Float, defaultValue: Float? = nil) {
        super.init(frame: .zero)
        addSubview(stackView)
        stackView.addArrangedSubview(minimumLabel)
        stackView.addArrangedSubview(slider)
        stackView.addArrangedSubview(maximumLabel)

        addSubview(valueLabel)

        minimumLabel.text = "\(min)"
        maximumLabel.text = "\(max)"
        stackView.edgesToSuperview()

        slider.minimumValue = min
        slider.maximumValue = max

        let initialValue: Float = defaultValue ?? min
        slider.value = initialValue
        valueLabel.text = "\(initialValue)"

        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)

        // TODO: this is incredibly hacky
        for recognizer in slider.gestureRecognizers ?? [] {
            if recognizer is UIPanGestureRecognizer {
                FilterWorkshopView.globalPanGestureRecognizer.require(toFail: recognizer)
            }
        }
    }

    @objc private func sliderValueChanged() {
        let thumbRect = slider.thumbRect(forBounds: slider.frame, trackRect: slider.trackRect(forBounds: slider.frame), value: slider.value)
        valueLabel.text = String(format: "%.2f", slider.value)
        valueLabel.frame = CGRect(
            x: thumbRect.minX - (valueLabel.intrinsicContentSize.width - thumbRect.width) / 2,
            y: thumbRect.maxY + 10,
            width: valueLabel.intrinsicContentSize.width,
            height: valueLabel.intrinsicContentSize.height
        )

        valueLabel.isHidden = slider.value == slider.maximumValue || slider.value == slider.minimumValue

        value = slider.value
        self.sendActions(for: .valueChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
