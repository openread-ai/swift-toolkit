import PDFKit
import UIKit
import XCTest
@testable import ReadiumNavigator

final class PDFTapGestureControllerTests: XCTestCase {
    @MainActor
    func testSingleTapDoesNotWaitForPDFKitSingleTapButDefersToDoubleTapZoom() throws {
        let container = UIView()
        let pdf = PDFView()
        container.addSubview(pdf)
        let target = TapTarget()
        let controller = PDFTapGestureController(pdfView: pdf, touchTypes: [.direct],
                                                 target: target, action: #selector(TapTarget.tap))
        let recognizer = try XCTUnwrap(pdf.gestureRecognizers?.last as? UITapGestureRecognizer)
        let nativeTap = UITapGestureRecognizer()
        XCTAssertFalse(controller.gestureRecognizer(recognizer, shouldRequireFailureOf: nativeTap))
        XCTAssertTrue(controller.gestureRecognizer(recognizer, shouldRecognizeSimultaneouslyWith: nativeTap))
        nativeTap.numberOfTapsRequired = 2
        XCTAssertTrue(controller.gestureRecognizer(recognizer, shouldRequireFailureOf: nativeTap))
        XCTAssertFalse(controller.gestureRecognizer(recognizer, shouldRequireFailureOf: UIPanGestureRecognizer()))
    }
}

private final class TapTarget: NSObject {
    @objc func tap() {}
}
