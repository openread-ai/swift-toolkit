//
//  Copyright 2026 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import Foundation
import PDFKit
import UIKit

/// Since iOS 13, the way to add a properly functioning tap gesture recognizer on a `PDFView`
/// significantly changed. This class handles the setup depending on the current iOS version.
final class PDFTapGestureController: NSObject {
    private let pdfView: PDFView
    private let tapAction: TargetAction
    private var tapRecognizer: UITapGestureRecognizer!

    init(
        pdfView: PDFView,
        touchTypes: [UITouch.TouchType],
        target: AnyObject,
        action: Selector
    ) {
        assert(pdfView.superview != nil, "The PDFView must be in the view hierarchy")

        self.pdfView = pdfView
        tapAction = TargetAction(target: target, action: action)

        super.init()

        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
        tapRecognizer.allowedTouchTypes = touchTypes.map { NSNumber(value: $0.rawValue) }
        tapRecognizer.requiresExclusiveTouchType = true

        // PDFKit recognizes single taps even on blank content. Waiting for its
        // recognizer to fail prevents navigator input; filter annotations instead.
        tapRecognizer.delegate = self
        pdfView.addGestureRecognizer(tapRecognizer)
    }

    @objc private func didTap(_ gesture: UITapGestureRecognizer) {
        // On iOS 13, the tap to clear text selection is broken by adding the
        // tap recognizer, so we clear it manually.
        guard pdfView.currentSelection == nil else {
            pdfView.clearSelection()
            return
        }

        tapAction.invoke(from: gesture)
    }
}

extension PDFTapGestureController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Check before PDFKit can clear selection while recognizing the same tap.
        guard pdfView.currentSelection == nil else { return false }
        let point = touch.location(in: pdfView)
        guard let page = pdfView.page(for: point, nearest: false) else { return true }
        return page.annotation(at: pdfView.convert(point, to: page)) == nil
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let tap = otherGestureRecognizer as? UITapGestureRecognizer else { return false }
        return tap.numberOfTouchesRequired == 1 && tap.numberOfTapsRequired > 1
    }
}
