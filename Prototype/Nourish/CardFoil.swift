import SwiftUI
import UIKit

// Inspired by efremidze/Shiny. UIKit moves a transparent optical layer while
// the nutrition gradient and the card's text stay anchored to the diary.
struct CardFoil: UIViewRepresentable {
    let active: Bool
    let silver: Bool

    func makeUIView(context: Context) -> FoilSurface { FoilSurface() }

    func updateUIView(_ view: FoilSurface, context: Context) {
        view.configure(active: active, silver: silver)
    }

    static func dismantleUIView(_ view: FoilSurface, coordinator: ()) {
        view.configure(active: false, silver: true)
    }
}

final class FoilSurface: UIView, UIGestureRecognizerDelegate {
    private let reflector = UIView()
    private let spectrum = CAGradientLayer()
    private var inputEnabled = false
    private var isSilver: Bool?
    private lazy var pan = UIPanGestureRecognizer(target: self, action: #selector(drag(_:)))

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        accessibilityElementsHidden = true
        isOpaque = false
        reflector.isUserInteractionEnabled = false
        reflector.layer.addSublayer(spectrum)
        addSubview(reflector)
        spectrum.startPoint = CGPoint(x: 0.20, y: 0.04)
        spectrum.endPoint = CGPoint(x: 0.83, y: 0.94)
        spectrum.locations = [0, 0.33, 0.40, 0.445, 0.485, 0.53, 0.59, 0.67, 1]
        pan.delegate = self
        pan.maximumNumberOfTouches = 1
        addGestureRecognizer(pan)
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        reflector.bounds = CGRect(origin: .zero, size: CGSize(width: bounds.width * 1.9, height: bounds.height * 2))
        reflector.center = CGPoint(x: bounds.width * 0.62, y: bounds.midY)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        spectrum.frame = reflector.bounds
        CATransaction.commit()
    }

    func configure(active: Bool, silver: Bool) {
        if isSilver != silver {
            isSilver = silver
            let pearl = UIColor.white
            let cool = silver ? pearl : UIColor(red: 0.65, green: 0.96, blue: 1, alpha: 1)
            let warm = silver ? pearl : UIColor(red: 1, green: 0.78, blue: 0.94, alpha: 1)
            let stops: [(UIColor, CGFloat)] = [
                (pearl, 0), (pearl, 0), (cool, 0.13), (cool, 0.34), (pearl, 0.64),
                (warm, 0.30), (pearl, 0.12), (pearl, 0), (pearl, 0)
            ]
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            spectrum.colors = stops.map { $0.0.withAlphaComponent($0.1).cgColor }
            CATransaction.commit()
        }
        isUserInteractionEnabled = active
        guard active != inputEnabled else { return }
        inputEnabled = active
        if active {
            let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
            horizontal.minimumRelativeValue = -125
            horizontal.maximumRelativeValue = 125
            let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
            vertical.minimumRelativeValue = -72
            vertical.maximumRelativeValue = 72
            let group = UIMotionEffectGroup()
            group.motionEffects = [horizontal, vertical]
            reflector.addMotionEffect(group)
        } else {
            for effect in reflector.motionEffects { reflector.removeMotionEffect(effect) }
            reflector.layer.removeAllAnimations()
            reflector.transform = .identity
        }
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let velocity = pan.velocity(in: self)
        return inputEnabled && abs(velocity.x) > abs(velocity.y)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        otherGestureRecognizer.view is UIScrollView
    }

    @objc private func drag(_ gesture: UIPanGestureRecognizer) {
        guard inputEnabled else { return }
        switch gesture.state {
        case .began, .changed:
            let dx = gesture.translation(in: self).x
            let limit = bounds.width * 0.4
            reflector.transform = CGAffineTransform(translationX: min(limit, max(-limit, dx)), y: 0)
        case .ended, .failed, .cancelled:
            UIView.animate(withDuration: 0.42, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseOut]) {
                self.reflector.transform = .identity
            }
        default:
            break
        }
    }
}
