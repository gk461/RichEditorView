//
//  RichEditorToolbar.swift
//
//  Created by Caesar Wirth on 4/2/15.
//  Copyright (c) 2015 Caesar Wirth. All rights reserved.
//
import UIKit

/// RichEditorToolbarDelegate is a protocol for the RichEditorToolbar.
/// Used to receive actions that need extra work to perform (eg. display some UI)
@MainActor
@objc public protocol RichEditorToolbarDelegate {

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
        layer.masksToBounds = false

        toolbarScroll.translatesAutoresizingMaskIntoConstraints = false
        toolbarScroll.showsHorizontalScrollIndicator = false
        toolbarScroll.showsVerticalScrollIndicator = false
        toolbarScroll.backgroundColor = .clear
        toolbarScroll.clipsToBounds = false
        toolbarScroll.layer.masksToBounds = false
        
        toolbar.autoresizingMask = .flexibleWidth
        toolbar.backgroundColor = .clear
        toolbar.clipsToBounds = false
        toolbar.layer.masksToBounds = false
        
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
        
        // Size toolbar by asking it to fit its items, then update frames in layoutSubviews
        toolbar.sizeToFit()
        setNeedsLayout()
        
        let doneOption = RichEditorDefaultOption.done
       
        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(btnDoneAction), for: .touchUpInside)
        doneButton.setTitleColor(tintColor, for: .normal)
        
    }
    
    @objc func btnDoneAction() {
        RichEditorDefaultOption.done.action(self)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()

        // Ensure the toolbar sizes to its content and then adjust frames accordingly
        toolbar.sizeToFit()

        let barButtonItemMargin: CGFloat = 12
        let contentWidth = (toolbar.items ?? []).reduce(0) { sofar, item in
            // Try to use the item's view if available; otherwise fallback to a reasonable width
            if let view = item.value(forKey: "view") as? UIView, view.bounds.width > 0 {
                return sofar + view.bounds.width + barButtonItemMargin
            } else {
                // Use the toolbar's average item width if possible, otherwise default
                let defaultIconWidth: CGFloat = 28
                return sofar + defaultIconWidth + barButtonItemMargin
            }
        }

        // Place the toolbar at origin within the scroll view
        let height: CGFloat = 44
        let widthToUse = max(bounds.width, contentWidth + barButtonItemMargin)

        toolbar.frame = CGRect(x: 0, y: 0, width: widthToUse, height: height)
        toolbarScroll.contentSize = CGSize(width: widthToUse, height: height)
        let horizontalInset: CGFloat = 16
        toolbarScroll.contentInset = UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)
        toolbarScroll.clipsToBounds = false
        
        clipsToBounds = false
    }
    
}
