/// SMN Marketplace – business rules (single source of truth).
class AppConstants {
  AppConstants._();

  // ─── Pricing ─────────────────────────────────────────────────────────────
  static const double minServicePriceInr = 10.0;
  static const double platformFeePercent = 6.0;
  static const double gatewayFeePercent = 2.0;
  static const double platformChargePerOrderInr = 49.0;
  static const double roleVerificationFeeInr = 15.0;

  // ─── Cart & Order ────────────────────────────────────────────────────────
  /// 1 cart = 1 creator (multiple services from same creator only).
  static const int deadlineMaxDays = 7;
  static const int counterProposalsMax = 2;
  /// Auto cancel if creator doesn't respond within 48 hours.
  static const int pendingResponseHours = 48;
  /// Price edits do not affect running orders (orders store snapshot).

  // ─── Delivery & Files ─────────────────────────────────────────────────────
  /// File upload unlocked only after creator clicks "Mark Ready for Delivery".
  /// Allowed: mp4 (200MB), mp3 (50MB), pdf (20MB).
  static const int maxFileSizeBytesMp4 = 200 * 1024 * 1024; // 200MB
  static const int maxFileSizeBytesMp3 = 50 * 1024 * 1024;  // 50MB
  static const int maxFileSizeBytesPdf = 20 * 1024 * 1024;  // 20MB
  static const List<String> allowedDeliveryExtensions = ['mp4', 'mp3', 'pdf'];

  // ─── Penalty (V2) ─────────────────────────────────────────────────────────
  /// 2% per day after deadline, max 10%, grace 6 hours.
  static const double penaltyPercentPerDay = 2.0;
  static const double penaltyMaxPercent = 10.0;
  static const int penaltyGraceHours = 6;

  // ─── Auto complete (V2) ───────────────────────────────────────────────────
  /// 48h after delivery if buyer silent → auto complete.
  static const int autoCompleteHoursAfterDelivery = 48;

  // ─── Revisions (V3) ───────────────────────────────────────────────────────
  static const int freeRevisionsPerOrder = 3;
  static const double revisionFeeAfterFreeInr = 50.0;
  static const int revisionReasonMinLength = 20;
  static const int revisionReasonMaxLength = 500;
  /// If unchanged file detected: refund buyer 50% + revision fees; creator payout 50% – platform.

  // ─── Fraud detection (V3) ─────────────────────────────────────────────────
  /// 90% similarity = unchanged (perceptual hash / frame sample / audio fingerprint).
  static const double fraudUnchangedSimilarityThreshold = 90.0;

  // ─── Chat (V3) ─────────────────────────────────────────────────────────────
  /// Block numbers, emails, links; whitelist basic punctuation; strike system.
  static const int chatMaxStrikesBeforeAction = 3;

  // ─── Order contract (smart hiring) ────────────────────────────────────────
  /// Contract uses 12% platform / 88% creator (distinct from listing platformFeePercent).
  static const double contractPlatformFeePercent = 12.0;
  static const double contractCreatorSharePercent = 88.0;
  static const int contractDisputeWindowHours = 48;
  static const String contractPendingPayment = 'pending_payment';
  static const String contractEscrowLocked = 'escrow_locked';
  static const String contractInProgress = 'in_progress';
  static const String contractDelivered = 'delivered';
  static const String contractRevisionRequested = 'revision_requested';
  static const String contractApproved = 'approved';
  static const String contractPayoutReleased = 'payout_released';
  static const String contractCompleted = 'completed';

  // ─── Payout & Dispute ─────────────────────────────────────────────────────
  static const int payoutHoldDays = 14;
  /// Dispute freezes payout until resolved.

  // ─── Roles ───────────────────────────────────────────────────────────────
  static const String roleBusinessOwner = 'business_owner';
  static const String roleCreator = 'creator';
  static const String roleVideographer = 'videographer';
  static const String roleFreelancer = 'freelancer';

  static const List<String> providerRoles = [roleCreator, roleVideographer, roleFreelancer];
  static const List<String> allRoles = [
    roleBusinessOwner,
    roleCreator,
    roleVideographer,
    roleFreelancer,
  ];

  // ─── Creator / Provider onboarding ───────────────────────────────────────
  static const int creatorMaxCategories = 4;
  static const int providerMaxServiceTypes = 4;
  static const int providerBioMinLength = 20;
  static const int providerBioMaxLength = 300;
  static const int analyticsPostsCount = 20;

  // ─── Search ranking (sum = 100) ──────────────────────────────────────────
  static const double rankPerformance = 40.0;
  static const double rankCompletion = 25.0;
  static const double rankRating = 15.0;
  static const double rankResponse = 10.0;
  static const double rankPrice = 10.0;

  // ─── Order statuses ───────────────────────────────────────────────────────
  static const String orderPendingPayment = 'pending_payment';
  static const String orderPending = 'pending';
  static const String orderInProgress = 'in_progress';
  static const String orderDelivered = 'delivered';
  static const String orderRevision = 'revision';
  static const String orderCompleted = 'completed';
  static const String orderFailed = 'failed';
  static const String orderDisputed = 'disputed';
  static const String orderCancelled = 'cancelled';
  static const String orderApproved = 'approved';

  /// Escrow state machine: pending_payment → escrow_locked → delivered → approved → payout_released → completed
  static const String financePendingPayment = 'pending_payment';
  static const String financeEscrowLocked = 'escrow_locked';
  static const String financeDelivered = 'delivered';
  static const String financeApproved = 'approved';
  static const String financePayoutReleased = 'payout_released';
  static const String financeCompleted = 'completed';

  static List<String> get orderStatuses => [
        orderPendingPayment,
        orderPending,
        orderInProgress,
        orderDelivered,
        orderApproved,
        orderRevision,
        orderCompleted,
        orderFailed,
        orderDisputed,
        orderCancelled,
      ];

  // ─── Dispute statuses ────────────────────────────────────────────────────
  static const String disputeOpen = 'open';
  static const String disputeUnderReview = 'under_review';
  static const String disputeResolved = 'resolved';
  static const String disputeClosed = 'closed';
}
