//
//  RichEditorToolbar.swift
//
//  Created by Caesar Wirth on 4/2/15.
//  Copyright (c) 2015 Caesar Wirth. All rights reserved.
//
import UIKit

/// RichEditorToolbarDelegate is a protocol for the RichEditorToolbar.
/// Used to receive actions that need extra work to perform (eg. display some UI)
@objc public protocol RichEditorToolbarDelegate: class {

    /// Called when the Text Color toolbar item is pressed.
    @objc optional func richEditorToolbarChangeTextColor(_ toolbar: RichEditorToolbar)

    /// Called when the Background Color toolbar item is pressed.
    @objc optional func richEditorToolbarChangeBackgroundColor(_ toolbar: RichEditorToolbar)

    /// Called when the Insert Image toolbar item is pressed.
    @objc optional func richEditorToolbarInsertImage(_ toolbar: RichEditorToolbar)

    /// Called when the Insert Video toolbar item is pressed
    @objc optional func richEditorToolbarInsertVideo(_ toolbar: RichEditorToolbar)

    /// Called when the Insert Link toolbar item is pressed.
    @objc optional func richEditorToolbarInsertLink(_ toolbar: RichEditorToolbar)
    
    /// Called when the Insert Table toolbar item is pressed
    @objc optional func richEditorToolbarInsertTable(_ toolbar: RichEditorToolbar)
    
    /// Called when the done toolbar item is pressed
    @objc optional func richEditorToolbarDoneAction(_ toolbar: RichEditorToolbar)
}

/// RichBarButtonItem is a subclass of UIBarButtonItem that takes a callback as opposed to the target-action pattern
@objcMembers open class RichBarButtonItem: UIBarButtonItem {
    open var actionHandler: (() -> Void)?
    
    public convenience init(image: UIImage? = nil, handler: (() -> Void)? = nil) {
        self.init(image: image, style: .plain, target: nil, action: nil)
        target = self
        action = #selector(RichBarButtonItem.buttonWasTapped)
        actionHandler = handler
    }
    
    public convenience init(title: String = "", handler: (() -> Void)? = nil) {
        self.init(title: title, style: .plain, target: nil, action: nil)
        target = self
        action = #selector(RichBarButtonItem.buttonWasTapped)
        actionHandler = handler
    }
    
    @objc func buttonWasTapped() {
        actionHandler?()
    }
}

/// RichEditorToolbar is UIView that contains the toolbar for actions that can be performed on a RichEditorView
@objcMembers open class RichEditorToolbar: UIView {

    /// The delegate to receive events that cannot be automatically completed
    open weak var delegate: RichEditorToolbarDelegate?

    /// A reference to the RichEditorView that it should be performing actions on
    open weak var editor: RichEditorView?
    
    /// The list of options to be displayed on the toolbar
    open var options: [RichEditorOption] = [] {
        didSet {
            updateToolbar()
        }
    }

    open var isDoneButtonHidden: Bool = true {
        didSet {
            doneButton.isHidden = isDoneButtonHidden
        }
    }
    
    /// The tint color to apply to the toolbar background.
    open var barTintColor: UIColor? {
        get { return backgroundColor }
        set { backgroundColor = newValue }
    }

    private var toolbarScroll: UIScrollView
    private var doneButton: UIButton
    private var toolbar: UIToolbar
    
    public override init(frame: CGRect) {
        toolbarScroll = UIScrollView()
        doneButton = UIButton()
        toolbar = UIToolbar()
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        toolbarScroll = UIScrollView()
        doneButton = UIButton()
        toolbar = UIToolbar()
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        autoresizingMask = .flexibleWidth
        backgroundColor = .clear

        toolbarScroll.translatesAutoresizingMaskIntoConstraints = false
        toolbarScroll.showsHorizontalScrollIndicator = false
        toolbarScroll.showsVerticalScrollIndicator = false
        toolbarScroll.backgroundColor = .clear
        
        toolbar.autoresizingMask = .flexibleWidth
        toolbar.backgroundColor = .clear
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(doneButton)
        addSubview(toolbarScroll)
        addSubview(stackView)
        toolbarScroll.addSubview(toolbar)
        
        NSLayoutConstraint.activate([
            toolbarScroll.topAnchor.constraint(equalTo: topAnchor),
            toolbarScroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbarScroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: toolbarScroll.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            doneButton.widthAnchor.constraint(equalToConstant: 70)
        ])
        
        doneButton.isHidden = isDoneButtonHidden
        updateToolbar()
    }
    
    private func updateToolbar() {
        
        var buttons = [UIBarButtonItem]()
        
        for option in options {
            let handler = { [weak self] in
                if let strongSelf = self {
                    option.action(strongSelf)
                }
            }
            
            if let image = option.image {
                let button = RichBarButtonItem(image: image, handler: handler)
                buttons.append(button)
            } else {
                let title = option.title
                let button = RichBarButtonItem(title: title, handler: handler)
                buttons.append(button)
            }
        }
        
        toolbar.items = buttons
        
        let defaultIconWidth: CGFloat = 28
        let barButtonItemMargin: CGFloat = 12
        let width: CGFloat = buttons.reduce(0) {sofar, new in
            if let view = new.value(forKey: "view") as? UIView {
                return sofar + view.frame.size.width + barButtonItemMargin
            } else {
                return sofar + (defaultIconWidth + barButtonItemMargin)
            }
        }
        
        if width < frame.size.width {
            toolbar.frame.size.width = frame.size.width + barButtonItemMargin
        } else {
            toolbar.frame.size.width = width + barButtonItemMargin
        }
        toolbar.frame.size.height = 44
        toolbarScroll.contentSize.width = width
        
        let doneOption = RichEditorDefaultOption.done
       
        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(btnDoneAction), for: .touchUpInside)
        doneButton.setTitleColor(tintColor, for: .normal)
        
    }
    
    @objc func btnDoneAction() {
        RichEditorDefaultOption.done.action(self)
    }
    
}

