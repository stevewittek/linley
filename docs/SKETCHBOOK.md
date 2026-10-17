# Private Sketchbook

Open **Home → My Sketchbook**, or **Image Maker → Draw in My Sketchbook**.

- Draw using a finger or Apple Pencil, with Pen, Marker and a stroke eraser.
- Choose from six ink colors and White, Blush or Sky paper. Undo and redo the current editing session; clearing the canvas asks first.
- Name a sketch and keep editing it later. Drafts autosave after an editing pause, on Done, and when the app moves out of the foreground. A blank new canvas isn't saved until it has drawing content.
- **Save picture to My Stuff** makes a separate JPEG and keeps the editable draft. Deleting a draft asks first and leaves exported pictures alone. Exported pictures can be deleted separately in My Stuff.
- All drawing tools are free. No coins, accounts, purchases, network, public posting or upload service are involved.

## Storage and recovery

Native PencilKit drawings and a preview are stored in one atomic `.sketch` JSON document per draft under Application Support/PrivateSketchbook. The directory is excluded from backup and each file uses complete file protection. The app never replaces a file that failed initial loading; readable drafts remain available, and an error explains preserved unreadable files. A failed save keeps the editor open when Done is tapped. Unsaved changes block swipe dismissal. Background saving can still fail if the device is locked or out of space; no claim of guaranteed recovery from a force quit before autosave.

Bounds: 100 drafts, 48-character titles, 25 MB drawing payload and 5 MB preview. The canonical drawing/export coordinate space is 768×768 so drafts can reopen on a different screen size without rescaling the stored strokes. Undo history is session-only; the strokes persist. The eraser removes whole strokes. Custom stamp layers, reference-photo tracing, music creation and cloud sync are outside this batch.

The underlying canvas allows finger and Pencil input using Apple's [PencilKit drawing policy](https://developer.apple.com/documentation/pencilkit/pkcanvasview/drawingpolicy). Physical Pencil input still needs a hand check; configuring an API isn't device proof.

See SKETCHBOOK_VALIDATION.md for exact verified and pending results, and reviews/2026-10-17-sketchbook.md for the separately labeled concept.
