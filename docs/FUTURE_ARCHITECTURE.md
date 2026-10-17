# Private by default: Phase 1 and future services

## Current enforced boundary
There is no network client, analytics/advertising SDK, backend, cloud container entitlement, public profile or sharing surface in the active app flow. Media, profile JPEG and the JSON index live under Application Support/PrivateCreations, excluded from backup and protected using complete file protection. Capture/import copies selected media from temporary URLs; picture re-encoding removes source metadata. Video metadata is kept locally and must be sanitized before any future export. No automatic camera-roll write. PhotosUI grants selected-item access without requesting full-library authorization. A user can deliberately select an iCloud-backed item in Apple's picker, which may cause the OS to download that existing item; Linley never uploads it.

Temporary drafts are app-private and removed on cancel/save/discard. Interrupted operations can leave temporary files for the OS to clean; production should add bounded orphan reconciliation and storage quota/background streaming for very large imports. Current JPEG import decodes a selected image in memory. Test high-resolution and long-video input on real devices before wider use. An unreadable index fails closed and is preserved rather than overwritten.

Parent Center uses Apple's device-owner authentication, fails closed when unavailable, and locks on navigation exit/background. The OS device passcode can be known by a child. This is a prototype access boundary, not proof of age, adult identity or legally sufficient verifiable parental consent. Connected permissions are immutable false, not toggles. No online identity or consent is collected in Phase 1.

## Later service design — not provisioned
- ASP.NET Core API validates identity and authorization for every action. Separate adult principals and child profiles; a child token cannot grant consent, link strangers or access adult records. Use least privilege, short sessions, rate limits and auditable server authorization.
- SQL Server/Azure SQL stores relational metadata, relationships, policy versions, adult authorization, scoped approval records and audit/deletion state. Store object keys and media properties, never media bytes in SQL tables.
- Private Azure Blob Storage stores encrypted objects with no anonymous access. Upload/download capabilities are short lived and server-authorized for a single object. Remove location/device metadata before approved publication. Quarantine objects until validated/scanned and moderated; fail closed if any stage is unavailable.
- Consent records include verified adult identity reference, verification method/provider result, policy version, purpose, scopes, timestamp and revocation. Obtain legal review to choose a compliant verification method and retention policy before collecting child information or enabling uploads. A local PIN, device passcode or toggle is never a substitute.
- Revocation immediately disables future processing and access, invalidates capabilities, removes published derivatives and queues deletion of originals, thumbnails, metadata and provider copies. Track deletion completion and limited lawful audit retention; surface status to the adult. Define backup expiry and restore suppression so deleted content cannot reappear.
- Moderation uses a quarantine/review/approved/rejected state machine, adult approval, abuse reporting and escalation. No messaging, public discovery or open comments until separately designed and reviewed. Record actor, resource, policy, decision and timestamp without copying child media into logs.
- Android can implement the same media kind, local manifest and policy contracts with native Kotlin or a future shared client. Retain the working SwiftUI iOS client. Backend contracts are independent of UI framework.

## Official implementation references
- [Apple required-reason privacy manifest](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest)
- [Apple selected-media picker](https://developer.apple.com/documentation/photosui/phpickerviewcontroller)
- [Apple device-owner authentication](https://developer.apple.com/documentation/localauthentication/lapolicy/deviceownerauthentication)

This is a technical design, not a finding of legal compliance. Legal review and verified consent systems remain release requirements.
