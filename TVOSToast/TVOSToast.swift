//
//  TVOSToast.swift
//  TVOSToast
//
//  Created by Cem Olcay on 17/02/16.
//  Copyright © 2016 MovieLaLa. All rights reserved.
//

import UIKit
import ManualLayout

// MARK: - UIViewController Extension

public extension UIViewController {

    public func presentToast(_ toast: TVOSToast) {
        toast.presentOnView(self.view)
    }
}

// MARK: - NSAttributedString

public extension NSAttributedString {

    public convenience init(text: String, fontName: String, fontSize: CGFloat, color: UIColor) {
        let font = UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        self.init(text: text, font: font, color: color)
    }

    public convenience init(text: String, font: UIFont, color: UIColor) {
        let attributes = [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: color
        ]
        self.init(string: text, attributes: attributes)
    }

    public convenience init(imageName: String, bounds: CGRect?, bundle: Bundle) {
        let textAttachment = NSTextAttachment()
        textAttachment.image = UIImage(named: imageName, in: bundle, compatibleWith: nil)
        if let bounds = bounds {
            textAttachment.bounds = bounds
        }
        self.init(attachment: textAttachment)
    }

    public convenience init(attributedStrings: NSAttributedString...) {
        let mutableAttributedString = NSMutableAttributedString()
        for attributedString in attributedStrings {
            mutableAttributedString.append(attributedString)
        }
        self.init(attributedString: mutableAttributedString)
    }
}

// MARK: - TVOSToastButtonType

public enum TVOSToastRemoteButtonType: String {
    case MenuBlack
    case MenuWhite
    case ScreenBlack
    case ScreenWhite
    case PlayPauseBlack
    case PlayPauseWhite
    case SiriBlack
    case SiriWhite
    case VolumeWhite
    case VolumeBlack

    fileprivate func getImageName() -> String {
        return "tvosToast\(rawValue).png"
    }

    public func getAttributedString(bounds: CGRect? = nil) -> NSAttributedString {
        let bundlePath = Bundle(for: TVOSToast.self).bundlePath
        let bundle = Bundle(path: bundlePath + "/TVOSToastResourceBundle.bundle") ?? Bundle(for: TVOSToast.self)
        return  NSAttributedString(imageName: self.getImageName(), bounds: bounds, bundle: bundle)
    }
}

public enum ToastElement {
    case stringType(String)
    case remoteButtonType(TVOSToastRemoteButtonType)
}


public func +(lhs: String, rhs: TVOSToastRemoteButtonType) -> [ToastElement] {
    return [.stringType(lhs), .remoteButtonType(rhs)]
}

public func +(lhs: TVOSToastRemoteButtonType, rhs: String) -> [ToastElement] {
    return [.remoteButtonType(lhs), .stringType(rhs)]
}

public func +(lhs: [ToastElement], rhs: String) -> [ToastElement] {
    return lhs + [.stringType(rhs)]
}

public func +(lhs: String, rhs: [ToastElement]) -> [ToastElement] {
    return [.stringType(lhs)] + rhs
}


// MARK: - TVOSToastHintText

open class TVOSToastHintText {

    open var elements: [ToastElement]

    public init(element: [ToastElement]) {
        self.elements = element
    }

    open func buildAttributedString(_ font: UIFont, textColor: UIColor) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString()

        for element in elements {

            switch element {
            case .stringType(let asString):
                mutableAttributedString.append(NSAttributedString(text: asString, font: font, color: textColor))

            case .remoteButtonType(let asRemoteButtonType):
                let size = font.pointSize + 30
                mutableAttributedString.append(asRemoteButtonType.getAttributedString(bounds: CGRect(x: 0, y: -size/4, width: size, height: size)))
            }
        }
        return mutableAttributedString.mutableCopy() as! NSAttributedString
    }
}

// MARK: - Position

public enum TVOSToastPosition {
    case top(insets: CGFloat)
    case topLeft(insets: CGFloat)
    case topRight(insets: CGFloat)
    case bottom(insets: CGFloat)
    case bottomLeft(insets: CGFloat)
    case bottomRight(insets: CGFloat)
}

// MARK: - Style

public struct TVOSToastStyle {
    // presentation
    public var position: TVOSToastPosition?
    public var duration: TimeInterval?
    // appearance
    public var backgroundColor: UIColor?
    public var cornerRadius: CGFloat?
    // text style
    public var font: UIFont?
    public var textColor: UIColor?

    public init() {
        position = nil
        duration = nil
        backgroundColor = nil
        cornerRadius = nil
        font = nil
        textColor = nil
    }
}

// MARK: - Toast

open class TVOSToast: UIView {

    // MARK: Properties

    open var style: TVOSToastStyle

    open var customContent: UIView?
    open var text: String?
    open var attributedText: NSAttributedString?
    open var hintText: TVOSToastHintText?

    fileprivate let customContentView = UIView()
    fileprivate let textLabel = UILabel()

    // MARK: Init



    public init(frame: CGRect, style: TVOSToastStyle? = nil) {
        self.style = style ?? TVOSToastStyle()
        super.init(frame: frame)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        self.style = TVOSToastStyle()
        super.init(coder: aDecoder)
        setup()
    }

    fileprivate func setup() {
        customContentView.frame = bounds
        textLabel.frame = bounds
        addSubview(customContentView)
        // text
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
        addSubview(textLabel)
    }

    // MARK: Present

    open func presentOnView(_ view: UIView, callback: (() -> Void)? = nil) {

        // get style
        let position = style.position ?? .bottom(insets: 20)
        let duration = style.duration ?? 3
        let backgroundColor = style.backgroundColor ?? UIColor.gray
        let cornerRadius = style.cornerRadius ?? 10
        let font = style.font ?? UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        let textColor = style.textColor ?? UIColor.white

        // setup style
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = cornerRadius
        self.alpha = 0
        view.addSubview(self)

        // setup text
        if let hintText = hintText {
            textLabel.attributedText = hintText.buildAttributedString(font, textColor: textColor)
        } else if let attributedText = attributedText {
            textLabel.attributedText = attributedText
        } else if let text = text {
            textLabel.text = text
            textLabel.textColor = textColor
            textLabel.font = font
        }

        // setup custom content
        if let customContent = customContent {
            customContentView.addSubview(customContent)
        }

        // setup position
        switch position {
        case .top(let insets):
            top = insets
            centerX = view.width / 2
        case .topLeft(let insets):
            top = insets
            left = insets
        case .topRight(let insets):
            top = insets
            right = view.right - insets
        case .bottom(let insets):
            bottom = view.bottom - insets
            centerX = view.width / 2
        case .bottomLeft(let insets):
            bottom = view.bottom - insets
            left = insets
        case .bottomRight(let insets):
            bottom = view.bottom - insets
            right = view.right - insets
        }

        // animate toast
        UIView.animate(withDuration: 0.3,
                                   delay: 0,
                                   usingSpringWithDamping: 1,
                                   initialSpringVelocity: 0,
                                   options: .allowAnimatedContent,
                                   animations: {
                                    self.alpha = 1
            },
                                   completion: { finished in
                                    UIView.animate(withDuration: 0.3,
                                        delay: duration,
                                        usingSpringWithDamping: 1,
                                        initialSpringVelocity: 0,
                                        options: .allowAnimatedContent,
                                        animations: {
                                            self.alpha = 0
                                        },
                                        completion: { finished in
                                            self.removeFromSuperview()
                                            callback?()
                                    })
        })
    }

    open func presentOnWindow(relatedToView view: UIView?, callback: (() -> Void)? = nil) {
        guard let _window = UIApplication.shared.delegate?.window, let window = _window else {
            return
        }

        // get style
        let position = style.position ?? .bottom(insets: 20)
        let duration = style.duration ?? 3
        let backgroundColor = style.backgroundColor ?? UIColor.gray
        let cornerRadius = style.cornerRadius ?? 10
        let font = style.font ?? UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        let textColor = style.textColor ?? UIColor.white

        // setup style
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = cornerRadius
        self.alpha = 0

        let superViewOriginToWindow: CGPoint
        let viewWidth: CGFloat
        let viewHeight: CGFloat

        if let view = view {
            superViewOriginToWindow = view.convert(view.bounds.origin, to: window)
            viewWidth = view.width
            viewHeight = view.height
        } else {
            superViewOriginToWindow = CGPoint(x: 0, y: 0)
            viewWidth = window.width
            viewHeight = window.height
        }

        window.addSubview(self)

        // setup text
        if let hintText = hintText {
            textLabel.attributedText = hintText.buildAttributedString(font, textColor: textColor)
        } else if let attributedText = attributedText {
            textLabel.attributedText = attributedText
        } else if let text = text {
            textLabel.text = text
            textLabel.textColor = textColor
            textLabel.font = font
        }

        // setup position
        switch position {
        case .top(let insets):
            center = CGPoint(x: superViewOriginToWindow.x + viewWidth/2, y: superViewOriginToWindow.y + insets + height/2)
        case .topLeft(let insets):
            center = CGPoint(x: superViewOriginToWindow.x + insets + width/2, y: superViewOriginToWindow.y + insets + height/2)
        case .topRight(let insets):
            center = CGPoint(x: superViewOriginToWindow.x + viewWidth - insets - width/2, y: superViewOriginToWindow.y + insets + height/2)
        case .bottom(let insets):
            center = CGPoint(x: superViewOriginToWindow.x + viewWidth/2, y: superViewOriginToWindow.y + viewHeight - insets - height/2)
        case .bottomLeft(let insets):
            center = CGPoint(x: superViewOriginToWindow.x + insets + width/2, y: superViewOriginToWindow.y + viewHeight - insets - height/2)
        case .bottomRight(let insets):
            center = CGPoint(x: superViewOriginToWindow.x + viewWidth - insets - width/2, y: superViewOriginToWindow.y + viewHeight - insets - height/2)
        }

        // animate toast
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: .allowAnimatedContent,
            animations: {
                self.alpha = 1
            },
            completion: { finished in
                UIView.animate(withDuration: 0.3,
                    delay: duration,
                    usingSpringWithDamping: 1,
                    initialSpringVelocity: 0,
                    options: .allowAnimatedContent,
                    animations: {
                        self.alpha = 0
                    },
                    completion: { finished in
                        self.removeFromSuperview()
                        callback?()
                })
        })

    }

    open func hide(_ callback: (() -> Void)? = nil) {
        layer.removeAllAnimations()

        UIView.animate(withDuration: 0.3,
                                   delay: 0,
                                   usingSpringWithDamping: 1,
                                   initialSpringVelocity: 0,
                                   options: .allowAnimatedContent,
                                   animations: {
                                    self.alpha = 0
            },
                                   completion: { finished in
                                    self.removeFromSuperview()
                                    callback?()
        })
    }
}
