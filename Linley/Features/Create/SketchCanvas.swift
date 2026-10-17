import SwiftUI
import PencilKit

struct SketchCanvasAction: Identifiable {
    enum Kind { case undo, redo, clear }
    let id = UUID()
    let kind: Kind
}

struct SketchCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var canUndo: Bool
    @Binding var canRedo: Bool
    let tool: Int
    let color: UIColor
    let action: SketchCanvasAction?

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear; canvas.isOpaque = false
        canvas.isScrollEnabled = false
        canvas.drawing = drawing
        canvas.delegate = context.coordinator
        canvas.accessibilityIdentifier = "sketchCanvas"
        canvas.isAccessibilityElement = true
        canvas.accessibilityLabel = "Drawing canvas"
        canvas.accessibilityHint = "Draw with your finger or Apple Pencil."
        canvas.accessibilityTraits = [.allowsDirectInteraction]
        return canvas
    }
    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        switch tool {
        case 1: canvas.tool = PKInkingTool(.marker, color: color, width: 20)
        case 2: canvas.tool = PKEraserTool(.vector)
        default: canvas.tool = PKInkingTool(.pen, color: color, width: 5)
        }
        if canvas.drawing.dataRepresentation() != drawing.dataRepresentation() {
            context.coordinator.applying = true
            canvas.drawing = drawing
            context.coordinator.applying = false
        }
        if let action, context.coordinator.lastAction != action.id {
            context.coordinator.lastAction = action.id
            switch action.kind {
            case .undo: canvas.undoManager?.undo()
            case .redo: canvas.undoManager?.redo()
            case .clear: canvas.drawing = PKDrawing()
            }
            context.coordinator.synchronize(canvas)
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: SketchCanvas
        var lastAction: UUID?
        var applying = false
        init(_ parent: SketchCanvas) { self.parent = parent }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !applying else { return }
            synchronize(canvasView)
        }
        func synchronize(_ canvas: PKCanvasView) {
            // UIKit can call this while SwiftUI is updating a tool or restoring a drawing.
            let snapshot = canvas.drawing
            DispatchQueue.main.async { [weak self, weak canvas] in
                guard let self, let canvas else { return }
                self.parent.drawing = snapshot
                self.parent.canUndo = canvas.undoManager?.canUndo ?? false
                self.parent.canRedo = canvas.undoManager?.canRedo ?? false
            }
        }
    }
}
