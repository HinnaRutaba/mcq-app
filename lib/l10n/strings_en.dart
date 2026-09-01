/// English strings. Keys are dotted, grouped by screen.
///
/// Only app chrome lives here — every enum label, validation message and
/// domain refusal comes from the server already translated (it is sent
/// `Accept-Language`), so those are never duplicated in this file.
/// See [stringsUr] for the Urdu table; both must carry the same keys.
const Map<String, String> stringsEn = {
  // --- Common ---------------------------------------------------------
  'app.name': 'MCQ Magistrate',
  'app.corporation': 'Metropolitan Corporation Quetta',
  'common.cancel': 'Cancel',
  'common.confirm': 'Confirm',
  'common.close': 'Close',
  'common.submit': 'Submit',
  'common.save': 'Save',
  'common.retry': 'Try again',
  'common.refresh': 'Refresh',
  'common.seeAll': 'See all',
  'common.search': 'Search',
  'common.call': 'Call',
  'common.optional': 'Optional',
  'common.required': 'Required',
  'common.loading': 'Loading…',
  'common.notRecorded': 'Not recorded',
  'common.none': 'None',
  'common.remarks': 'Remarks',
  'common.rupees': 'Rs',
  'common.lastUpdated': 'Last updated {time}',
  'common.offlineCached': 'Offline — showing data saved {time}. Figures are not live.',
  'common.offline': 'No connection',
  'common.dismiss': 'Dismiss',

  'common.and': 'and',
  'common.of': 'of',
  'common.recordedBy': 'Recorded by {name}',
  'common.offlineRecord': 'Recorded offline',
  'common.tapToView': 'View',

  // --- Enum labels the API does not send options for -------------------
  // The API validates these values with an enum rule but exposes no
  // options endpoint, so the app carries its own labels. Everything else
  // that arrives as {value,label,tone} uses the server's label.
  'fineType.non_payment': 'Non-payment of rent',
  'fineType.seal_violation': 'Breaking a seal',
  'fineType.unauthorised_use': 'Unauthorised use',
  'fineType.encroachment': 'Encroachment',
  'fineType.other': 'Other offence',
  // The build brief's action-sheet table is the first document to write
  // these values down. There is still no options endpoint returning
  // {value,label}, so these labels are a second source of truth — see
  // QUESTIONS.md §2. Anything the server sends that is not listed here
  // falls back to the raw value rather than asserting.
  'actionType.site_visit': 'Visit',
  'actionType.verbal_warning': 'Verbal warning',
  'actionType.final_warning': 'Final warning',
  'actionType.payment_promised': 'Promise to pay',
  'actionType.reminder_visit_set': 'Reminder to revisit',
  'actionType.notice_served': 'Notice served',
  'actionType.seal': 'Shop sealed',
  'actionType.unseal': 'Seal released',
  'actionType.other': 'Other',
  'inspectionType.routine': 'Routine',
  'inspectionType.complaint': 'Complaint',
  'inspectionType.enforcement': 'Enforcement',

  // --- Errors ---------------------------------------------------------
  'error.network': 'No connection to the server. Check your signal and try again.',
  'error.timeout': 'The server did not answer in time. Try again.',
  'error.server': 'The server reported a problem. Nothing was saved. Report this if it keeps happening.',
  'error.unexpected': 'Something did not work. Nothing was saved.',
  'error.sessionExpired': 'Your session has ended. Sign in again to continue.',
  'error.notPermitted': 'You do not have permission for this.',

  // --- Sign in --------------------------------------------------------
  'auth.signIn': 'Sign in',
  'auth.title': 'Sign in',
  'auth.subtitle': 'Enforcement officers of Metropolitan Corporation Quetta.',
  'auth.username': 'Username',
  'auth.usernameHint': 'e.g. magistrate',
  'auth.usernameRequired': 'Enter your username',
  'auth.password': 'Password',
  'auth.passwordRequired': 'Enter your password',
  'auth.deviceName': 'This device',
  'auth.deviceNameHint': 'e.g. Samsung A15 — enforcement jeep',
  'auth.deviceNameHelp': 'You will see this name if you ever need to revoke a lost handset.',
  'auth.deviceNameRequired': 'Name this device',
  'auth.failed': 'Those details were not accepted. Check them and try again — five failed attempts locks the account for 15 minutes.',
  'auth.signOut': 'Sign out',
  'auth.signOutConfirm': 'Sign out of this device? Anything still waiting to sync will stay on the handset.',

  // --- Change password ------------------------------------------------
  'password.title': 'Change your password',
  'password.forced': 'Your password must be changed before you can use the app.',
  'password.current': 'Current password',
  'password.new': 'New password',
  'password.confirm': 'Confirm new password',
  'password.mismatch': 'The two passwords do not match',
  'password.tooShort': 'Use at least 8 characters',
  'password.changed': 'Password changed. Please sign in again with the new one.',

  // --- The officer's posting -------------------------------------------
  'today.noPosting': 'You have no area posting',

  // --- Defaulters -----------------------------------------------------
  'defaulters.title': 'Defaulters',
  'defaulters.subtitle': '{count} accounts · {amount} outstanding',
  'defaulters.searchHint': 'Shop, allottee or property code',
  'defaulters.sortAmount': 'Largest owed',
  'defaulters.sortAge': 'Longest unpaid',
  'defaulters.sortName': 'Allottee A–Z',
  'defaulters.filterAll': 'All',
  'defaulters.filterSealed': 'Sealed',
  'defaulters.filterNotSealed': 'Not sealed',
  'defaulters.neverPaid': 'Never paid — needs a visit',
  'defaulters.behind': '{count} months behind',
  'defaulters.behindOne': '1 month behind',
  'defaulters.lastPaid': 'Last paid {date}',
  'defaulters.monthlyRent': 'Monthly rent',
  'defaulters.outstanding': 'Outstanding',
  'defaulters.timesRent': '{times}× the monthly rent',
  'defaulters.currentDue': 'This month',
  'defaulters.arrearsDue': 'Arrears',
  'defaulters.surchargeDue': 'Surcharge',
  'defaulters.sealedAlready': 'Sealed',
  'defaulters.openCase': 'Open the case',
  'defaulters.noCase': 'No enforcement case yet',
  'defaulters.empty': 'Nothing outstanding in your areas',
  'defaulters.emptyHelp': 'Every account in your posting is up to date.',
  'defaulters.noMobile': 'No mobile number on the register',

  // --- Cases ----------------------------------------------------------
  'cases.title': 'Cases',
  'cases.filterOpen': 'Open',
  'cases.filterOverdue': 'Visit overdue',
  'cases.filterAll': 'All',
  'cases.caseNo': 'Case {no}',
  'cases.caseNoLabel': 'Case number',
  'cases.unpaidMonthsLabel': 'Months unpaid',
  'cases.nextVisitLabel': 'Next visit',
  'cases.openedOnLabel': 'Opened',
  'cases.closedOnLabel': 'Closed',
  'cases.openedOn': 'Opened {date}',
  'cases.nextVisit': 'Next visit {date}',
  'cases.noNextVisit': 'No visit scheduled',
  'cases.visitOverdue': 'Visit overdue',
  'cases.unpaidMonths': '{count} months unpaid',
  'cases.sealed': 'Shop is sealed',
  'cases.timeline': 'What has been done',
  'cases.timelineEmpty': 'Nothing recorded on this case yet',
  'cases.timelineEmptyHelp': 'Record a visit and it will appear here, newest first.',
  'cases.recordAction': 'Record a visit',
  'cases.sealShop': 'Seal the shop',
  'cases.releaseSeal': 'Release the seal',
  'cases.imposeFine': 'Impose a fine',
  'cases.closeCase': 'Close the case',
  'cases.empty': 'No enforcement cases in your areas',
  'cases.emptyHelp': 'Cases opened against a shop in your posting appear here.',
  'cases.amounts': 'Amounts on this case',
  'cases.closedOn': 'Closed {date}',
  'cases.closingRemarks': 'Closing remarks',
  'cases.openCaseForProperty': 'Open an enforcement case',
  'cases.stayOrderWarning':
      'A court stay order is live on this property. Enforcement is suspended — do not seal it.',

  // --- Recording an action --------------------------------------------
  'action.title': 'Record a visit',
  'action.type': 'What was done',
  'action.typeRequired': 'Choose what was done',
  'action.date': 'When it happened',
  'action.dateHelp': 'A past date is accepted; a future one is not.',
  'action.witness': 'Witness name',
  'action.photo': 'Photograph',
  'action.photoHelp': 'Take one photograph of what you are recording.',
  'action.photoRequired': 'A photograph is required before this can be submitted.',
  'action.signature': 'Witness signature',
  'action.takePhoto': 'Take a photograph',
  'action.retakePhoto': 'Retake',
  'action.removePhoto': 'Remove',
  'action.uploading': 'Uploading…',
  'action.uploaded': 'Photograph stored on the server',
  'action.pendingUpload': 'Held on this handset until there is signal',
  'action.location': 'Location',
  'action.locationFixing': 'Getting a GPS fix…',
  'action.locationFix': 'Fix to {accuracy} m',
  'action.locationNone': 'No fix — the record will carry no coordinates',
  'action.locationRetry': 'Get a fix',
  'action.saved': 'Recorded.',
  'action.savedAlready': 'Already recorded — this was a retry, nothing new was created.',
  'action.queued': 'No signal. Saved on this handset and it will sync on its own.',

  // --- Seal and release -----------------------------------------------
  'seal.title': 'Seals',
  'seal.confirmSealTitle': 'Seal this shop?',
  'seal.confirmSealBody':
      'Shop {shop} — {allottee}. Sealing closes the shop until MCQ releases it.',
  'seal.confirmSeal': 'Seal the shop',
  'seal.confirmReleaseTitle': 'Release this seal?',
  'seal.confirmReleaseBody':
      'Shop {shop} — {allottee}. Releasing lets the shop trade again and gives up MCQ\'s leverage.',
  'seal.confirmRelease': 'Release the seal',
  'seal.reason': 'Reason',
  'seal.reasonRequired': 'Say why the shop is being sealed',
  'seal.sealedOn': 'Sealed {date}',
  'seal.releasedOn': 'Released {date}',
  'seal.sealed': 'Sealed',
  'seal.released': 'Released',
  'seal.done': 'Shop sealed.',
  'seal.releaseDone': 'Seal released.',
  'seal.empty': 'No seals in your areas',
  'seal.emptyHelp': 'Shops you seal appear here until they are released.',
  'seal.cannotRelease': 'Cannot be released yet',

  // --- Fines ----------------------------------------------------------
  'fines.title': 'Fines',
  'fines.impose': 'Impose a fine',
  'fines.confirmTitle': 'Impose this fine?',
  'fines.confirmBody':
      'Shop {shop} — {payer}. A challan for {amount} is raised at once and a payment link is sent by SMS. It cannot be withdrawn from the handset.',
  'fines.type': 'Offence',
  'fines.typeRequired': 'Choose the offence',
  'fines.amount': 'Fine amount',
  'fines.amountRequired': 'Enter the amount',
  'fines.amountFormat': 'Enter an amount like 4500 or 4500.00',
  'fines.legalProvision': 'Provision of law',
  'fines.legalProvisionHint': 'e.g. Section 96, Balochistan LG Act 2010',
  'fines.legalProvisionHelp':
      'A fine with no section of law named is unenforceable in court. This is required.',
  'fines.legalProvisionRequired': 'Name the provision of law',
  'fines.offenderSection': 'Who is being fined',
  'fines.offenderWhy':
      'Nobody holds this unit, so there is no allottee to bill. Name the person being fined — they receive the challan and the payment link by SMS.',
  'fines.offenderName': 'Offender\'s name',
  'fines.offenderNameRequired': 'Name the person being fined',
  'fines.offenderMobile': 'Offender\'s mobile number',
  'fines.offenderMobileRequired': 'The payment link is sent to this number',
  'fines.offenderMobileFormat': 'Enter an 11-digit number starting 03, e.g. 03009876543',
  'fines.billedToAllottee': 'The allottee holding this unit will be billed and sent the link.',
  'fines.imposed': 'Fine imposed.',
  'fines.challanRaised': 'Challan {no} raised for {amount}.',
  'fines.smsSent': 'A payment link was sent to {mobile}. Tell them to check their phone.',
  'fines.smsNotSent': 'No payment link went out. Report this before you leave the shop.',
  'fines.requiresApproval': 'Needs approval — not yet effective',
  'fines.awaitingApproval': 'Awaiting approval',
  'fines.empty': 'No fines in your areas',
  'fines.emptyHelp': 'Fines you impose appear here.',

  // --- Property lookup ------------------------------------------------
  'property.title': 'Find a shop',
  'property.searchHint': 'Property code, shop number or allottee',
  'property.searchPrompt': 'What are you standing in front of?',
  'property.searchPromptHelp': 'Search by the property code on the unit, its shop number, or the allottee\'s name.',
  'property.empty': 'Nothing matched that',
  'property.emptyHelp': 'Check the code, or search by the allottee\'s name instead.',
  'property.profile': 'Shop',
  'property.code': 'Property code',
  'property.shopNo': 'Shop number',
  'property.area': 'Area',
  'property.market': 'Market',
  'property.category': 'Kind of unit',
  'property.allottee': 'Allottee',
  'property.noAllottee': 'Nobody holds this unit',
  'property.allotment': 'Allotment',
  'property.monthlyRent': 'Monthly rent',
  'property.balance': 'What this shop owes',
  'property.challans': 'Challans',
  'property.payments': 'Payments',
  'property.recordInspection': 'Record an inspection',
  'property.inspections': 'Inspections',
  'property.mobile': 'Mobile',

  // --- Inspections ----------------------------------------------------
  'inspection.title': 'Record an inspection',
  'inspection.type': 'Kind of inspection',
  'inspection.findings': 'What you found',
  'inspection.findingsRequired': 'Write what you found',
  'inspection.saved': 'Inspection recorded.',
  'inspection.empty': 'No inspections recorded on this unit',

  // --- Challans -------------------------------------------------------
  'challan.no': 'Challan {no}',
  'challan.dueOn': 'Due {date}',
  'challan.payable': 'Payable now',
  'challan.separateDebt': 'A fine is a separate debt from the rent. Either can be paid without the other.',

  // --- Legal ----------------------------------------------------------
  'legal.title': 'Court cases',
  'legal.cases': 'Cases',
  'legal.hearings': 'Hearings',
  'legal.diary': 'Diary',
  'legal.nextHearing': 'Next hearing {date}',
  'legal.stayLive': 'Live stay order — enforcement suspended',
  'legal.empty': 'No court cases in your areas',
  'legal.emptyHelp': 'Cases filed against or by MCQ on your shops appear here.',
  'legal.readOnly': 'Read only. Legal branch maintains these records.',

  // --- Offline queue --------------------------------------------------
  'queue.title': 'Waiting to sync',
  'queue.pending': 'Waiting for signal',
  'queue.sending': 'Sending…',
  'queue.conflict': 'Needs your attention',
  'queue.failed': 'Did not send',
  'queue.synced': 'Sent',
  'queue.count': '{count} waiting',
  'queue.syncNow': 'Send now',
  'queue.retry': 'Send again',
  'queue.discard': 'Discard this record',
  'queue.discardConfirm':
      'Discard what you recorded for shop {shop} — {allottee}? It will not be sent and cannot be recovered.',
  'queue.recordedAt': 'Recorded {time} on this handset',
  'queue.conflictHelp':
      'The state of the case changed before this reached the server. Read what the server said and decide what to do.',
  'queue.empty': 'Nothing waiting',
  'queue.emptyHelp': 'Everything you have recorded has reached the server.',
  'queue.itemAction': 'Visit recorded',
  'queue.itemSeal': 'Shop sealed',
  'queue.itemRelease': 'Seal released',
  'queue.itemFine': 'Fine imposed',

  // --- Settings -------------------------------------------------------
  'settings.title': 'Settings',
  'settings.language': 'Language',
  'settings.darkMode': 'Dark screen (easier at night)',
  'settings.languageEnglish': 'English',
  'settings.languageUrdu': 'اردو',
  'settings.officer': 'Officer',
  'settings.employeeNo': 'Employee number',
  'settings.designation': 'Designation',
  'settings.postings': 'Areas you are posted to',
  'settings.device': 'This device',
  'settings.tokenExpires': 'Sign-in expires {date}',
  'settings.tokenExpiresLabel': 'Sign-in expires',
  'settings.changePassword': 'Change password',
  'settings.about': 'About',
  'settings.version': 'Version {version}',

  // --- Navigation -----------------------------------------------------
  'nav.defaulters': 'Defaulters',
  'nav.find': 'Find',
  'nav.more': 'More',
  // --- Navigation -----------------------------------------------------
  'nav.home': 'Home',
  'nav.round': 'Round',

  // --- The beat (home screen) ------------------------------------------
  'beat.goodMorning': 'Good morning',
  'beat.goodAfternoon': 'Good afternoon',
  'beat.goodEvening': 'Good evening',
  'beat.allAreas': 'All areas',
  'beat.noPostingChip': 'No area posting',
  'beat.noPosting': 'You have no area posting',
  'beat.noPostingHelp':
      'Nothing is assigned to you yet, so there are no figures to show. Ask the Estate Branch to record your posting.',
  'beat.couldNotLoad': 'Your beat did not load',
  'beat.noQueues': 'Nothing is waiting',
  'beat.noQueuesHelp': 'The server sent no work queues for your areas today.',
  'beat.quickActions': 'Quick actions',
  'beat.generatedAt': 'Figures as at {time}',

  // --- The six queue tiles ---------------------------------------------
  // MCQ wrote these labels. The raw key — `follow_ups_due` — is a database
  // word and is never shown to an officer.
  'queue.defaulters': 'Shops behind on payment',
  'queue.defaultersSub': 'in your areas',
  'queue.defaultersClear': 'Nobody is behind today',
  'queue.followUps': 'Promises to chase',
  'queue.followUpsSub': 'due today or overdue',
  'queue.followUpsClear': 'Nothing to chase today',
  'queue.awaitingUnseal': 'Ready to unseal',
  'queue.awaitingUnsealSub': 'fine has been paid',
  'queue.awaitingUnsealClear': 'Nothing waiting to unseal',
  'queue.sealedShops': 'Shops you have sealed',
  'queue.sealedShopsSub': 'currently closed',
  'queue.sealedShopsClear': 'No shop of yours is sealed',
  'queue.openCases': 'Open cases',
  'queue.openCasesSub': 'in your areas',
  'queue.openCasesClear': 'No case is open',
  'queue.assignedToMe': 'Assigned to you',
  'queue.assignedToMeSub': 'from the taxation branch',
  'queue.assignedToMeClear': 'Nothing assigned to you',
  'queue.unknown': 'Work queue',
  'queue.unknownSub': 'in your areas',
  'queue.unknownClear': 'Nothing here today',

  // --- The card ---------------------------------------------------------
  'card.noTenant': 'No current tenant',
  'card.vacant': 'Vacant',
  'card.agreement': 'Agreement {no}',
  'card.daysOverdue': '{days} days overdue',
  'card.monthsBehind': '{months} months behind',
  'card.neverPaid': 'Never paid',
  'card.sealed': 'Sealed · {seal}',
  'card.sealedPlain': 'Sealed',
  'card.caseOpen': 'Case #{id} open',
  'card.promised': 'Promised {date} · {days} days left',
  'card.promisedToday': 'Promised today',
  'card.promiseBroken': 'Promise broken · {days} days ago',
  'card.promiseBrokenToday': 'Promise broken today',
  'card.revisit': 'Revisit {date}',
  'card.owes': 'Owes',
  'card.settled': 'Settled',
  'card.moreSignals': '{n} more',

  // --- Defaulters -------------------------------------------------------
  'defaulters.count': '{n} shops',
  'defaulters.allClear': 'Nobody is past due',
  'defaulters.allClearHelp':
      'No shop in your areas is behind on payment today. Good morning.',
  'defaulters.noMatch': 'Nothing matched',
  'defaulters.noMatchHelp':
      'Try a different name, shop number or property code.',
  'defaulters.clearFilters': 'Clear filters',
  'defaulters.filter.all': 'All',
  'defaulters.filter.neverPaid': 'Never paid',
  'defaulters.filter.promiseBroken': 'Promise broken',
  'defaulters.filter.sealed': 'Sealed',

  // --- Today's round ----------------------------------------------------
  'round.title': 'Today\u2019s round',
  'round.subtitle': 'The shops worth walking to',
  'round.shops': '{n} shops',
  'round.brokenPromises': '{n} broken promises',
  'round.neverPaid': '{n} never paid',
  'round.sealed': '{n} sealed',
  'round.stopsNote': 'The five worth calling on first.',
  'round.walked': 'Called on',
  'round.markWalked': 'Mark called on',
  'round.start': 'Start round',
  'round.stopOf': 'Stop {n} of {total}',
  'round.doneHere': 'Done here',
  'round.openProfile': 'Open profile',
  'round.progress': '{walked} of {total} stops called on',
  'round.complete': 'Round complete',
  'round.completeHelp': 'You have called on every stop. Well walked.',
  'round.nothingToWalk': 'No round today',
  'round.nothingToWalkHelp':
      'No shop in your areas is behind enough to be worth a visit right now.',

  // --- Follow-ups -------------------------------------------------------
  'followUps.title': 'Promises to chase',
  'followUps.short': 'Promises',
  'followUps.tabAll': 'Everything',
  'followUps.tabDue': 'Due now',
  'followUps.tabUpcoming': 'Upcoming',
  'followUps.sectionOverdue': 'Overdue',
  'followUps.sectionToday': 'Due today',
  'followUps.sectionUpcoming': 'Upcoming',
  'followUps.brokenDaysAgo': 'Promise broken {days} days ago',
  'followUps.promisedToday': 'Promised today',
  'followUps.dueInDays': 'Due in {days} days',
  'followUps.visitOverdue': 'Revisit {days} days overdue',
  'followUps.visitToday': 'Revisit due today',
  'followUps.visitInDays': 'Revisit in {days} days',
  'followUps.atPromise': 'When he promised',
  'followUps.now': 'Now',
  'followUps.hasComeDown': 'The balance has come down since he promised',
  'followUps.hasNotMoved': 'The balance has not moved since he promised',
  'followUps.hasGoneUp': 'The balance has risen since he promised',
  'followUps.escalate': 'What next',
  'followUps.none': 'No promises on file',
  'followUps.noneDue': 'Nothing to chase today',
  'followUps.noneHelp':
      'Take a promise from a shopkeeper and it appears here on the day it falls due.',

  // --- Seals and the unseal queue ---------------------------------------
  'seals.title': 'Seals',
  'seals.tabAll': 'All sealed',
  'seals.tabReady': 'Ready to unseal',
  'seals.readyBanner': 'Ready to unseal',
  'seals.stillSealed': 'Still sealed',
  'seals.release': 'Release the seal',
  'seals.sealedOn': 'Sealed {date}',
  'seals.finesPaid': '{n} fines paid',
  'seals.finesUnpaid': '{n} fines unpaid',
  'seals.owedNow': 'Owed now',
  'seals.arrearsDoNotGate':
      'The fine is paid. Arrears still standing do not hold the shutter closed.',
  'seals.none': 'You have sealed nothing',
  'seals.noneHelp':
      'Shops you seal appear here until the seal is released.',
  'seals.noneReady': 'Nothing waiting to unseal',
  'seals.noneReadyHelp':
      'A sealed shop appears here once its fine has been paid.',
  'seal.unsealReason': 'Why the seal is coming off',
  'seal.unsealReasonHint': 'e.g. Fine paid in full, receipt MCQ-RC-…',

  // --- Find a shop ------------------------------------------------------
  'find.title': 'Find a shop',
  'find.hint': 'Name, shop number, property code or mobile',
  'find.tabBehind': 'Behind on payment',
  'find.tabAll': 'All shops',
  'find.results': '{n} found',
  'find.noMatch': 'Nothing matched',
  'find.noMatchHelp':
      'Try a shop number, a property code or part of a name.',
  'find.noMatchTryAll':
      'This searches only shops that owe money. Try all shops in your areas.',
  'find.recent': 'Recent searches',
  'find.clearRecent': 'Clear',
  'find.startTyping': 'Find any shop in your areas',
  'find.startTypingHelp':
      'Search by name, shop number, property code, agreement number or mobile. Vacant units are included.',

  // --- My work ----------------------------------------------------------
  'activity.title': 'My work',
  'activity.short': 'My work',
  'activity.summaryTitle': 'Last {days} days',
  'activity.days': '{n} days',
  'activity.since': 'Since {date}',
  'activity.visits': 'Visits',
  'activity.fines': 'Fines imposed',
  'activity.sealed': 'Shops sealed',
  'activity.released': 'Seals released',
  // The server's own label. Never "You recovered" — a payment cannot
  // honestly be attributed to a visit.
  'activity.collected': 'Collected in your areas',
  'activity.collectedNote':
      'What came in from your areas over this period. It is not attributed to your visits.',
  'activity.receipts': '{n} receipts',
  'activity.finesAmount': '{amount} in fines',
  'activity.breakdown': 'What you did',
  'activity.empty': 'Nothing recorded yet',
  'activity.emptyHelp':
      'Visits, warnings, fines and seals you record will be counted here.',

  // --- The map ----------------------------------------------------------
  'map.title': 'Map of your beat',
  'map.subtitle': '{n} shops on the map',
  'map.missing': '{n} shops have no location recorded',
  'map.openFull': 'Open map',
  'map.openProfile': 'Open profile',
  'map.nearMe': 'Near me',
  'map.owingOnly': 'Owing only',
  'map.noPins': 'Nothing to map',
  'map.noPinsHelp':
      'No shop in your areas has a location recorded yet.',
  'map.couldNotLoad': 'The map did not load',
  'map.state.owing': 'Owes money',
  'map.state.sealed': 'Sealed',
  'map.state.current': 'Up to date',
  'map.state.vacant': 'Vacant',

  // --- The shopkeeper profile -------------------------------------------
  'profile.title': 'Shopkeeper',
  'profile.sms': 'Message',
  'profile.copied': 'Copied',
  'profile.noContact': 'No mobile number or CNIC on file.',
  'profile.nothingStanding': 'No seal, no open case, no promise standing.',
  'profile.promiseStanding': 'Promise standing',
  'profile.promiseBroken': 'Promise broken',
  'profile.owesNow': 'Owes right now',
  'profile.nobodyHolds': 'Nobody holds this unit',
  'profile.lastPaid': 'Last paid {date}',
  'profile.lastPaymentUnknown': 'No payment date on file',
  'profile.rentAndFinesSeparate':
      'A fine is a separate debt from the rent. Paying one does not settle the other.',
  'profile.facts': 'The unit',
  'profile.agreementNo': 'Agreement number',
  'profile.propertyCode': 'Property code',
  'profile.shopNo': 'Shop number',
  'profile.market': 'Market',
  'profile.area': 'Area',
  'profile.category': 'Category',
  'profile.monthlyRent': 'Monthly rent',
  'profile.status': 'Status',
  'profile.obligations': 'What is owed',
  'profile.obligationsNote':
      'Rent and fines are separate debts and are never added together.',
  'profile.timeline': 'What has happened',
  'profile.promisesMade': 'Has promised to pay {n} times',
  'profile.noActionsYet': 'Nothing has been recorded on this case yet.',
  'profile.noCaseNoTimeline':
      'No case is open, so there is nothing to show yet.',
  'profile.couldNotLoad': 'This shop did not load',
  'profile.escalate': 'Time to escalate',
  'profile.escalateHelp':
      'He has promised {n} times and the balance has not been settled. A fine or a seal is the next step.',

  // --- The action sheet -------------------------------------------------
  'actions.title': 'Actions',
  'actions.recordVisit': 'Record a visit',
  'actions.recordVisitHelp': 'You called at the shop.',
  'actions.giveWarning': 'Give a warning',
  'actions.giveWarningHelp': 'Verbal, or a final warning.',
  'actions.takePromise': 'Take a promise to pay',
  'actions.takePromiseHelp':
      'He names a date. It appears on his card and in your chase queue.',
  'actions.setReminder': 'Set a reminder to revisit',
  'actions.setReminderHelp': 'Come back on a date you choose.',
  'actions.imposeFine': 'Impose a fine',
  'actions.imposeFineHelp':
      'A challan and a payment link go to the allottee by SMS.',
  'actions.imposeFineOffenderHelp':
      'Nobody holds this unit — you will name who is being fined.',
  'actions.openCase': 'Open a case',
  'actions.openCaseHelp': 'Start a recovery file against this agreement.',
  'actions.openCaseConfirm': 'Open an enforcement case against {shop}?',
  'actions.caseOpened': 'Case opened.',
  'actions.caseAlreadyOpen': 'A case was already open for this agreement.',
  'actions.sealShop': 'Seal the shop',
  'actions.sealShopHelp':
      'Closes the business. Needs a reason and a photograph.',
  'actions.releaseSeal': 'Release the seal',
  'actions.releaseSealHelp': 'Opens the shop again.',
  'actions.stayBlocks':
      'A court stay order is in force on this property. Sealing and fining are blocked.',
  'actions.nonePermitted':
      'You do not hold the permissions for any action on this shop.',
  'actions.noCaseYet':
      'No case is open for this shop, so there is nothing to record against yet.',

  // --- Recording an action ----------------------------------------------
  'action.promisedDate': 'Date he promised to pay',
  'action.promisedDateHelp': 'The date the shopkeeper named.',
  'action.revisitDate': 'Date to come back',
  'action.revisitDateHelp': 'You will see this on his card.',
  'action.chooseDate': 'Choose a date',

  // --- Dates, in the words a shopkeeper uses ----------------------------
  'date.inOneWeek': 'In one week',
  'date.inTenDays': 'In ten days',
  'date.endOfMonth': 'End of this month',
  'date.endOfNextMonth': 'End of next month',
  'date.pickAnother': 'Choose another date',

  // --- Lists ------------------------------------------------------------
  'list.couldNotLoad': 'This did not load',
  'list.nothingHere': 'Nothing here',

  // --- Cases from the taxation branch -----------------------------------
  'cases.assignedTitle': 'Assigned to you',
  'cases.assignedBadge': 'Assigned by the Taxation Branch',
  'cases.assignedHelp':
      'These cases were sent to you by the taxation branch.',
  'cases.noneAssigned': 'Nothing assigned to you',
  'cases.noneAssignedHelp':
      'Cases the taxation branch sends you will appear here.',

  // --- The fine result --------------------------------------------------
  'fines.amountImposed': 'Fine imposed',
  'fines.challanNo': 'Challan number',
  'fines.consumerNo': 'Consumer Number',
  'fines.offenderCnic': 'Offender\u2019s CNIC',
  'fines.sendOnWhatsApp': 'Send on WhatsApp',
  'fines.sharePaymentLink': 'Share the payment link',
  'fines.shareMessage':
      'Metropolitan Corporation Quetta: a fine of {amount} has been imposed. Consumer Number {consumer}. Pay here: {link}',
  'settings.darkModeHelp': 'Field officers use this app at night.',
  'settings.themeSystem': 'Automatic',
  'settings.themeLight': 'Light',
  'settings.themeDark': 'Dark',
  'settings.textSize': 'Text size',
  'settings.textSize.0': 'Normal',
  'settings.textSize.1': 'Large',
  'settings.textSize.2': 'Largest',
  'action.signatureHelp': 'Ask the witness to sign here. Optional, and worth taking.',
  'action.signatureTake': 'Take a witness signature',
  'action.signatureClear': 'Clear',
  'action.signatureRedo': 'Sign again',
  'password.forcedTitle': 'One thing first',
  'password.changedTitle': 'Password changed',
  'password.revokesEverything':
      'Changing your password signs you out of every device you have signed in on, including this one. You will sign in again with the new password.',
  'password.strengthNone': 'Use at least 8 characters.',
  'password.strengthWeak': 'Weak — add length, a capital and a digit.',
  'password.strengthFair': 'Fair — a little longer would be better.',
  'password.strengthStrong': 'Strong.',
  'actions.stayTitle': 'A court stay is in force',

  // --- Charts ----------------------------------------------------------
  'chart.showTable': 'Show the figures',
  'chart.showChart': 'Show the chart',
  'chart.paid': 'Paid',
  'chart.due': 'Due',
  'chart.other': 'Other actions',

  // --- Dashboard sections ----------------------------------------------
  'beat.yourWork': 'Your work',
  'beat.yourWorkSub': 'What you have done, and what it sat behind',
  'beat.queuesTitle': 'What needs doing',
  'beat.queuesSub': 'Every tile opens the list behind it',

  // --- Activity report --------------------------------------------------
  'activity.breakdownSub': 'Ordered from the gentlest action to the hardest',
  'activity.shareTitle': 'Share of the month',
  'activity.shareSub': 'Which actions the period was made of',
  'activity.actions': 'actions',

  // --- Tabs -------------------------------------------------------------
  'profile.tabOverview': 'Overview',
  'profile.tabMoney': 'What is owed',
  'profile.tabHistory': 'History',
  'queue.tabWaiting': 'Waiting to send',
  'queue.tabAttention': 'Needs attention',

  // --- Common -----------------------------------------------------------
  'common.viewList': 'Open the list',
  'common.filters': 'Filters',

};
