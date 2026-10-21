// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get timelineUnavailableFilter =>
      'Selected data is currently unavailable';

  @override
  String get appTitle => 'Life Chronicle';

  @override
  String get navTimeline => 'Timeline';

  @override
  String get navSearch => 'Search';

  @override
  String get navNewEvent => 'New Entry';

  @override
  String get navStories => 'Topics';

  @override
  String get navBackup => 'Backup';

  @override
  String timeQuarterFull(String year, String quarter) {
    return 'Q$quarter $year';
  }

  @override
  String timeHalfYearFull(String year, String half) {
    String _temp0 = intl.Intl.selectLogic(half, {'first': 'H1', 'other': 'H2'});
    return '$_temp0 $year';
  }

  @override
  String timeYearFull(String year) {
    return '$year';
  }

  @override
  String timeApproxYear(String year) {
    return 'c. $year';
  }

  @override
  String timeRangeYearsFull(String start, String end) {
    return '$start–$end';
  }

  @override
  String timeRangeYearsList(String start, String end) {
    return '$start–$end';
  }

  @override
  String timeRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String timeRelativeAfter(String title) {
    return 'After $title';
  }

  @override
  String timeRelativeBefore(String title) {
    return 'Before $title';
  }

  @override
  String timeRelativeDuring(String title) {
    return 'During $title';
  }

  @override
  String get timeDeletedReference => '(reference entry unavailable)';

  @override
  String timeAgeEstimate(String age) {
    return 'About age $age';
  }

  @override
  String get timeUnknown => 'Date unknown';

  @override
  String timeListDay(String month, String day) {
    return '$month/$day';
  }

  @override
  String timeListMonth(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': 'Jan',
      '2': 'Feb',
      '3': 'Mar',
      '4': 'Apr',
      '5': 'May',
      '6': 'Jun',
      '7': 'Jul',
      '8': 'Aug',
      '9': 'Sep',
      '10': 'Oct',
      '11': 'Nov',
      '12': 'Dec',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String timeListQuarter(String quarter) {
    return 'Q$quarter';
  }

  @override
  String timeListHalfYear(String half) {
    String _temp0 = intl.Intl.selectLogic(half, {'first': 'H1', 'other': 'H2'});
    return '$_temp0';
  }

  @override
  String get timeListYearOnly => 'Month unknown';

  @override
  String get timelineOldestFirst => 'Old → New';

  @override
  String get timelineThisYear => 'Back to this year';

  @override
  String timelineCount(int count) {
    return '$count entries';
  }

  @override
  String get timelineNewestFirst => 'New → Old';

  @override
  String get timelineChooseYear => 'Choose year';

  @override
  String timelineYearCount(int count, String year) {
    return '$year · $count entries';
  }

  @override
  String get timelineEmpty => 'No entries yet. Start with New Entry.';

  @override
  String get timelineRetry => 'Retry';

  @override
  String get timelineLoadError => 'Could not load the timeline. Please retry.';

  @override
  String get timelineAll => 'Any';

  @override
  String get timelineOriginal => 'Original life record';

  @override
  String timelineMatches(int matched, int total) {
    return '$matched / $total entries match';
  }

  @override
  String get timelineFilter => 'Filter';

  @override
  String get timelineApply => 'Apply';

  @override
  String get timelinePlace => 'Place';

  @override
  String get timelineCategory => 'Category';

  @override
  String get timelinePerson => 'Person';

  @override
  String get timelineLayer => 'Record layer';

  @override
  String get timelineRemembrance => 'Remembrance';

  @override
  String get timelineTag => 'Tag';

  @override
  String get timelineLifePeriod => 'Life stage';

  @override
  String get timelineClear => 'Clear filters';

  @override
  String get timelineDemo => 'Demo data';

  @override
  String get timelineCompact => 'Compact list';

  @override
  String timelineAttachments(int count) {
    return '$count attachments';
  }

  @override
  String get timelineEnterYear => 'Enter year';

  @override
  String get timelineCancel => 'Cancel';

  @override
  String get timelineGenerate => 'Generate';

  @override
  String timelineDemoTitle(int number) {
    return 'Demo entry $number';
  }

  @override
  String timelineDemoCount(int count) {
    return 'Add $count demo entries';
  }

  @override
  String get timelinePreferencesError =>
      'Could not read or save display preferences. Check device storage.';

  @override
  String get timelineCards => 'Cards';

  @override
  String timelineDemoConfirm(int count) {
    return 'Add $count demo entries to this database. Existing entries are kept. Use a test device.';
  }

  @override
  String get timelineDemoCategory => 'Demo';

  @override
  String get timelineBrandEnglish => 'Life Chronicle';

  @override
  String get editorName => 'Event name';

  @override
  String get editorWhen => 'When it happened';

  @override
  String get editorNarrative => 'Narrative';

  @override
  String get editorAttachments => 'Add attachments';

  @override
  String get editorAdvanced => 'Advanced editing';

  @override
  String get editorSave => 'Save event';

  @override
  String get editorEdit => 'Edit event';

  @override
  String get editorRequired => 'Enter an event name';

  @override
  String get editorError =>
      'Could not save. Your draft is retained. Please retry.';

  @override
  String get editorDraftError =>
      'Could not read or save the draft. Please retry.';

  @override
  String get editorRestored => 'Your unsaved draft has been restored';

  @override
  String get editorDiscard => 'Discard draft';

  @override
  String get editorDiscardConfirm => 'Discard unsaved changes?';

  @override
  String get editorCategory => 'Category';

  @override
  String get editorPlace => 'Place';

  @override
  String get editorPeople => 'People';

  @override
  String get editorAddPerson => 'Add person';

  @override
  String get editorTags => 'Tags (separated by commas)';

  @override
  String get editorPrivacy => 'Privacy';

  @override
  String get editorNormal => 'Normal';

  @override
  String get editorPrivate => 'Private';

  @override
  String get editorRelated => 'Related events';

  @override
  String get editorAddSection => 'Add section';

  @override
  String get editorSectionTitle => 'Section title (optional)';

  @override
  String get editorRemoveSection => 'Delete section';

  @override
  String get editorMoveUp => 'Move up';

  @override
  String get editorMoveDown => 'Move down';

  @override
  String get editorCustomSection => 'Custom heading';

  @override
  String get sectionCause => 'Cause';

  @override
  String get sectionProcess => 'What happened';

  @override
  String get sectionResult => 'Outcome';

  @override
  String get sectionFeeling => 'Feelings at the time';

  @override
  String get sectionDifficulty => 'Difficulties';

  @override
  String get sectionInsight => 'Insight';

  @override
  String get sectionPeople => 'People involved';

  @override
  String get sectionScene => 'Scene';

  @override
  String get sectionWords => 'Memorable words';

  @override
  String get pickerPrecision => 'Time precision';

  @override
  String get pickerYear => 'Year';

  @override
  String get pickerHalf => 'Half year';

  @override
  String get pickerQuarter => 'Quarter';

  @override
  String get pickerMonth => 'Month';

  @override
  String get pickerDay => 'Day';

  @override
  String get pickerApprox => 'Approximate year';

  @override
  String get pickerRange => 'Time range';

  @override
  String get pickerRelative => 'Relative event';

  @override
  String get pickerAge => 'Estimated age';

  @override
  String get pickerUnknown => 'Unknown time';

  @override
  String get pickerStart => 'Start';

  @override
  String get pickerEnd => 'End';

  @override
  String get pickerBefore => 'Before';

  @override
  String get pickerAfter => 'After';

  @override
  String get pickerDuring => 'During';

  @override
  String get pickerInvalid => 'Check the time values and range order';

  @override
  String get pickerApply => 'Apply time';

  @override
  String get detailMissing => 'This event is unavailable or deleted';

  @override
  String get detailRecorded => 'Record created';

  @override
  String get detailReflections => 'Later reflections';

  @override
  String get detailAddReflection => 'Add reflection';

  @override
  String get detailSaveReflection => 'Save reflection';

  @override
  String get detailAuthorSelf => 'Me';

  @override
  String detailReflectionYear(String year) {
    return 'Added in $year';
  }

  @override
  String get detailMedia => 'Attachments';

  @override
  String get detailOpen => 'Open attachment';

  @override
  String get detailRemoveAttachment => 'Remove attachment reference';

  @override
  String get detailRemembrance => 'Remembrance';

  @override
  String get attachmentPlan => 'Import full copies';

  @override
  String attachmentPlanBody(
    int count,
    String size,
    String added,
    String free,
    int duplicates,
  ) {
    return '$count files\nOriginal size: $size\nEstimated added storage: $added\nAvailable: $free\nExisting copies: $duplicates\nOriginal files are retained. If any file fails, the entire batch is cancelled and can be retried.';
  }

  @override
  String get attachmentImport => 'Import attachments';

  @override
  String get attachmentError =>
      'Import failed. No files in this batch were saved. Originals are retained. Please retry.';

  @override
  String get attachmentNoSpace =>
      'Not enough device storage. At least 500 MB must remain after adding files. Compress or deselect files; existing content and originals are preserved.';

  @override
  String get attachmentVideoUnsupported => 'Videos are not supported';

  @override
  String attachmentStaticImageOnly(String name) {
    return '$name: Only the still image will be saved. The video portion will be excluded.';
  }

  @override
  String get attachmentTypeUnverified =>
      'Media tracks could not be verified. Check the file integrity or choose another file';

  @override
  String attachmentExcludedFile(String name, String reason) {
    return 'Excluded: $name ($reason)';
  }

  @override
  String attachmentRejectedImport(String reason) {
    return 'File type validation failed. The batch was not saved. $reason';
  }

  @override
  String attachmentQuotaExceeded(String excess) {
    return 'Attachments are limited to 25 MB per entry. The selection exceeds this by $excess MB. The batch was not saved. Select fewer attachments and try again; existing attachments and source files are preserved.';
  }

  @override
  String get attachmentCancel => 'Cancel import';

  @override
  String attachmentProgress(int done, int total) {
    return '$done of $total bytes processed';
  }

  @override
  String get attachmentUnavailable =>
      'Could not open the attachment. Check the file or choose a supported app';

  @override
  String get attachmentWarehouse => 'Attachment warehouse';

  @override
  String get attachmentUnreferenced => 'Unreferenced copies';

  @override
  String get attachmentClean => 'Delete copies permanently';

  @override
  String attachmentCleanConfirm(String size) {
    return 'Delete only unreferenced app copies ($size) permanently? Original files are retained.';
  }

  @override
  String get attachmentEmpty => 'No unreferenced copies';

  @override
  String get searchQuery =>
      'Search titles, narratives, people, places, tags or attachments';

  @override
  String get searchFrom => 'From year (optional)';

  @override
  String get searchTo => 'To year (optional)';

  @override
  String get searchAction => 'Search';

  @override
  String get searchNoResults => 'No matching events';

  @override
  String get searchInvalid =>
      'Years must be 1–9999 and the start must not be later than the end';

  @override
  String get searchPrivate => 'Private event';

  @override
  String detailPlaceLabel(String place) {
    return 'Place: $place';
  }

  @override
  String editorTimeValue(String time) {
    return 'When it happened: $time';
  }

  @override
  String get detailSelectEvent => 'Select an event to read its story';

  @override
  String get recycleTitle => 'Recently deleted';

  @override
  String get recycleEmpty => 'No deleted events';

  @override
  String get recycleRestore => 'Restore event';

  @override
  String get recyclePurge => 'Delete permanently';

  @override
  String get recyclePurgeConfirm =>
      'Permanently delete event content and attachment references. This cannot be undone. Originals remain available; unused copies can be cleaned in the attachment warehouse.';

  @override
  String get recyclePreserve =>
      'The title will be kept. Remembrance content will remain available.';

  @override
  String get recycleDelete => 'Move to recently deleted';

  @override
  String get recycleUndo => 'Undo';

  @override
  String get recycleView => 'View retained content';

  @override
  String recycleDeletedTitle(String title) {
    return 'Original event “$title” was deleted';
  }

  @override
  String get backupExport => 'Export ZIP backup';

  @override
  String get backupImport => 'Import and restore ZIP';

  @override
  String get backupVerify => 'Verify existing backup';

  @override
  String get backupMedia => 'Include attachment files';

  @override
  String get backupScope => 'Choose backup scope';

  @override
  String backupPlan(String required, String free, String count) {
    return 'Estimated space required: $required\nAvailable space: $free\nEvents: $count\nSave a copy through system sharing after completion.';
  }

  @override
  String get backupProgress => 'Processing and verifying archive';

  @override
  String get backupShare => 'Share or save ZIP and checksum sidecar';

  @override
  String get backupSuccess =>
      'Backup complete. The ZIP was reopened and every file verified.';

  @override
  String get backupVerified => 'All files passed verification';

  @override
  String get backupFailure =>
      'Archive processing failed. Existing data was preserved. Check space, format, and file integrity.';

  @override
  String get backupLast => 'Last completed and verified backup';

  @override
  String get backupConflict => 'Resolve differences for matching IDs';

  @override
  String get backupKeep => 'Keep current data';

  @override
  String get backupUseArchive => 'Use archived content';

  @override
  String get backupRestoreConfirm =>
      'Restore the verified archive? Conflicting IDs follow your choices. Attachments without files are marked unavailable.';

  @override
  String get backupRestoreDone => 'Restore verification report';

  @override
  String backupReport(
    String inserted,
    String replaced,
    String skipped,
    String excluded,
    String extras,
  ) {
    return 'Added: $inserted\nReplaced: $replaced\nSkipped: $skipped\nIntentionally excluded attachment files: $excluded\nExtra files ignored: $extras';
  }

  @override
  String get backupNewFormat =>
      'Some newer format data is not recognized. Only known fields will be restored.';

  @override
  String get backupReadme =>
      '# Life Chronicle archive\n\nExtract all files and open index.html in a browser, or read markdown/timeline.md. Saved attachment files are in media/.\n\nJSON in data/ is the authoritative source. Markdown and HTML are reading copies. Edits to reading copies are not imported. Table fields are described in schema/data.schema.json. Time payloads preserve input precision; sort_start and sort_end are for ordering only.\n\nTimestamps include a timezone. SHA256SUMS.txt covers every file except itself. The external sidecar verifies the whole ZIP.\n\nSave the ZIP and its sidecar on another device. Uninstalling the app may delete private backups.\n';

  @override
  String get archiveTimeLabel => 'Time';

  @override
  String get archiveLayerLabel => 'Content layer';

  @override
  String get archiveAuthorLabel => 'Author';

  @override
  String get securityTitle => 'Security';

  @override
  String get securityUnlock => 'Unlock';

  @override
  String get securityPassword => 'App password or family code';

  @override
  String get securityAppPassword =>
      'App password (at least six letters or digits)';

  @override
  String get securityNative => 'Use device authentication';

  @override
  String get securityReason => 'Authenticate to open Life Chronicle';

  @override
  String get securityPrivateEvent => 'Private event';

  @override
  String get securityPrivateUnlock => 'Authenticate to view private content';

  @override
  String get securityFailed =>
      'Authentication was not completed. Check your password or use another method.';

  @override
  String securityPaused(String seconds) {
    return 'Too many failed attempts. Wait $seconds seconds before trying again.';
  }

  @override
  String get securityAppLock => 'Lock app on opening';

  @override
  String get securityProtectPrivate => 'Protect private events';

  @override
  String get securityPasswordOnly => 'Require app password for private events';

  @override
  String get securityHidePreview => 'Hide app preview in recents';

  @override
  String get securityFamilyPrivate =>
      'Allow family code to open private events';

  @override
  String get securityTimeout => 'Automatic lock timeout';

  @override
  String get securityImmediate => 'Immediately';

  @override
  String get securityMinute => '1 minute';

  @override
  String get securityFiveMinutes => '5 minutes';

  @override
  String get securitySetup => 'Set up app password and backup codes';

  @override
  String get securityConsequences =>
      'If you forget your password, use device authentication to reset it first. Use your recovery code if that is unavailable. If neither works, the app cannot recover your password. Recovery codes reset your password; family codes let family open the app. Keep external ZIP backups. App lock does not protect exported files.';

  @override
  String get securityRecovery => 'Recovery code';

  @override
  String get securityFamily => 'Family code';

  @override
  String get securityCopyConfirm =>
      'I have written down and safely stored the displayed codes';

  @override
  String get securitySave => 'Save security settings';

  @override
  String get securityForgot => 'Forgot app password';

  @override
  String get securityReset => 'Reset app password';

  @override
  String get securityRegenerateRecovery =>
      'Generate new recovery code (invalidates old code)';

  @override
  String get securityRegenerateFamily =>
      'Generate new family code (invalidates old code)';

  @override
  String get securityFamilyDenied =>
      'Family mode cannot view or change security settings. Private content follows the owner’s settings.';

  @override
  String get securityFamilyName => 'Family';

  @override
  String get securityLockNow => 'Lock now';

  @override
  String get securityStorageError =>
      'Security settings could not be read. Retry; content remains hidden until authentication is completed.';

  @override
  String get locationCurrent => 'Use current location';

  @override
  String get locationMapPick => 'Choose a point on the map';

  @override
  String get locationRadius => 'Radius (meters, optional)';

  @override
  String get locationInvalid => 'Enter valid coordinates and a positive radius';

  @override
  String get locationUnavailable =>
      'Location or map is unavailable. You can continue with a text location.';

  @override
  String locationCoordinates(String latitude, String longitude) {
    return 'Latitude: $latitude  Longitude: $longitude';
  }

  @override
  String get locationDragPin => 'Drag the pin or tap the map to choose a point';

  @override
  String get locationOffline =>
      'Map tiles require a network connection. You can still save a text location or use current location.';

  @override
  String get locationOpenMap => 'Open in device map app';

  @override
  String get locationSave => 'Use this location';

  @override
  String get locationOsmAttribution => '© OpenStreetMap contributors';

  @override
  String get locationOsmCopyright => 'OpenStreetMap copyright information';

  @override
  String get locationPhotoSuggestion =>
      'This photo includes capture coordinates. Use them as the event location?';

  @override
  String get locationUsePhoto => 'Use photo capture location';

  @override
  String get locationAwaitGps =>
      'Obtaining GPS location. You can continue filling other fields';

  @override
  String get mdBold => 'Bold';

  @override
  String get mdItalic => 'Italic';

  @override
  String get mdPreview => 'Preview';

  @override
  String get mdEdit => 'Edit source';

  @override
  String get mdEmptyPreview => 'Write something to preview it.';

  @override
  String get mdHint =>
      'Markdown supports bold, tables, lists, quotes and code. Use your phone keyboard for emoji.';

  @override
  String get mdAttachmentImage => 'Add images as attachments';

  @override
  String get mdLinkCopied => 'Link copied';

  @override
  String get mdTable => 'Insert table';

  @override
  String get mdTableTemplate =>
      '| Column one | Column two |\n| --- | --- |\n| Content | Content |';

  @override
  String get displaySettings => 'Settings';

  @override
  String get timeZoneSetting => 'Date, time and time zone';

  @override
  String get timeZoneHelp =>
      'Choose the time zone for recorded, reflection, attachment and deletion times. Event dates and approximate times stay unchanged.';

  @override
  String get timestampPattern => 'MMM d, y, h:mm a';

  @override
  String get zoneSystem => 'Use phone time zone';

  @override
  String get zoneTaipei => 'Taipei';

  @override
  String get zoneTokyo => 'Tokyo';

  @override
  String get zoneShanghai => 'Shanghai';

  @override
  String get zoneHongKong => 'Hong Kong';

  @override
  String get zoneSingapore => 'Singapore';

  @override
  String get zoneSydney => 'Sydney';

  @override
  String get zoneLondon => 'London';

  @override
  String get zoneParis => 'Paris';

  @override
  String get zoneNewYork => 'New York';

  @override
  String get zoneLosAngeles => 'Los Angeles';

  @override
  String get zoneUtc => 'Coordinated Universal Time (UTC)';

  @override
  String get mdHeading => 'Heading level';

  @override
  String mdHeadingLevel(int level) {
    return 'Heading $level';
  }

  @override
  String get mdBullets => 'Bulleted list';

  @override
  String get mdNumbers => 'Numbered list';

  @override
  String get mdIndent => 'Indent (nested list)';

  @override
  String get mdOutdent => 'Outdent';

  @override
  String get mdCode => 'Inline code';

  @override
  String get mdLink => 'Insert link';

  @override
  String get mdLinkText => 'Link text';

  @override
  String get mdLinkUrl => 'URL (https://)';

  @override
  String get mdLinkInvalid => 'Enter link text and a valid http or https URL.';

  @override
  String get mdInsert => 'Insert';

  @override
  String get pickerChooseYear => 'Choose year';

  @override
  String get pickerChooseDate => 'Choose date';

  @override
  String get elapsedToday => 'Today';

  @override
  String get elapsedThisMonth => 'This month';

  @override
  String get elapsedThisYear => 'This year';

  @override
  String get elapsedIncludesToday => 'Period includes today';

  @override
  String get elapsedUnknown => 'Time ago unknown';

  @override
  String elapsedRange(int start, int end) {
    return '$start–$end';
  }

  @override
  String elapsedApprox(String text) {
    return 'About $text';
  }

  @override
  String elapsedDaysAgo(String count) {
    String _temp0 = intl.Intl.selectLogic(count, {'1': 'day', 'other': 'days'});
    return '$count $_temp0 ago';
  }

  @override
  String elapsedMonthsAgo(String count) {
    String _temp0 = intl.Intl.selectLogic(count, {
      '1': 'month',
      'other': 'months',
    });
    return '$count $_temp0 ago';
  }

  @override
  String elapsedYearsAgo(String count) {
    String _temp0 = intl.Intl.selectLogic(count, {
      '1': 'year',
      'other': 'years',
    });
    return '$count $_temp0 ago';
  }

  @override
  String elapsedDaysFuture(String count) {
    String _temp0 = intl.Intl.selectLogic(count, {'1': 'day', 'other': 'days'});
    return 'In $count $_temp0';
  }

  @override
  String elapsedMonthsFuture(String count) {
    String _temp0 = intl.Intl.selectLogic(count, {
      '1': 'month',
      'other': 'months',
    });
    return 'In $count $_temp0';
  }

  @override
  String elapsedYearsFuture(String count) {
    String _temp0 = intl.Intl.selectLogic(count, {
      '1': 'year',
      'other': 'years',
    });
    return 'In $count $_temp0';
  }

  @override
  String get restoreIntro =>
      'Select a ZIP to verify it and review differences. Your data stays unchanged until you confirm restoration.';

  @override
  String get restoreSelect => 'Select ZIP backup';

  @override
  String get restorePreview => 'Restore preview';

  @override
  String get restoreApply => 'Confirm restore';

  @override
  String get restoreChooseAll =>
      'Choose a version for every conflict before restoring.';

  @override
  String get restoreDifferentSubject =>
      'This backup belongs to another person. Restore it into an empty app; existing life records cannot be merged across people. Your data is unchanged.';

  @override
  String get restoreInvalidSubject =>
      'The backup does not contain a valid single person, self author, and archive settings.';

  @override
  String get restoreChanged =>
      'Your data changed after the preview. Select the backup again and review the updated differences.';

  @override
  String get restoreCancelled => 'Restore cancelled. Your data is unchanged.';

  @override
  String get restoreExcluded =>
      'This backup intentionally omits some attachment files, which cannot be opened after restoration.';

  @override
  String get restoreExtraFiles => 'These extra files will be ignored:';

  @override
  String get restoreEmpty => 'Not set';

  @override
  String get restoreYes => 'Yes';

  @override
  String get restoreNo => 'No';

  @override
  String restoreLocalValue(String value) {
    return 'Current: $value';
  }

  @override
  String restoreArchiveValue(String value) {
    return 'Backup: $value';
  }

  @override
  String restoreCount(String name, int count) {
    return '$name: $count records';
  }

  @override
  String restoreConflictNumber(String name, int count) {
    return 'Conflict $count · $name';
  }

  @override
  String restoreTable(String table) {
    String _temp0 = intl.Intl.selectLogic(table, {
      'subjects': 'Person',
      'authors': 'Authors',
      'archive_sessions': 'Archive sessions',
      'archive_settings': 'Archive settings',
      'places': 'Places',
      'people': 'People',
      'tags': 'Tags',
      'events': 'Events',
      'event_sections': 'Narrative sections',
      'life_periods': 'Life periods',
      'event_life_periods': 'Life period links',
      'reflections': 'Reflections',
      'stories': 'Stories',
      'story_events': 'Story links',
      'blobs': 'Attachment files',
      'attachments': 'Attachments',
      'event_tags': 'Event tags',
      'event_people': 'Event people links',
      'event_links': 'Related event links',
      'change_history': 'Change history',
      'other': 'Other records',
    });
    return '$_temp0';
  }

  @override
  String restoreField(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'display_name': 'Name',
      'birth_date': 'Birth date',
      'death_date': 'Death date',
      'title': 'Title',
      'content_md': 'Content',
      'time_payload': 'Event time',
      'category': 'Category',
      'privacy': 'Privacy',
      'created_at': 'Created',
      'updated_at': 'Updated',
      'recorded_at': 'Recorded',
      'deleted_at': 'Deleted',
      'purged_at': 'Permanently deleted',
      'layer': 'Layer',
      'author_id': 'Author',
      'event_id': 'Event',
      'subject_id': 'Person',
      'place_id': 'Place',
      'person_id': 'Participant',
      'tag_id': 'Tag',
      'life_period_id': 'Life period',
      'story_id': 'Story',
      'blob_id': 'Attachment file',
      'event_a_id': 'Related event',
      'event_b_id': 'Related event',
      'archive_session_id': 'Archive session',
      'current_session_id': 'Current archive session',
      'role': 'Role',
      'is_subject_self': 'Self author',
      'mode': 'Archive mode',
      'activated_at': 'Activated',
      'deactivated_at': 'Ended',
      'activated_by': 'Activated by',
      'deactivated_by': 'Ended by',
      'sort_start': 'Sort range start',
      'sort_end': 'Sort range end',
      'manual_order': 'Manual order',
      'position': 'Position',
      'suggestion_key': 'Section suggestion',
      'type': 'Type',
      'start_time': 'Start time',
      'end_time': 'End time',
      'organization': 'Organization',
      'provenance': 'Provenance',
      'sha256': 'File checksum',
      'byte_size': 'File size',
      'media_type': 'Media type',
      'path': 'File location',
      'verify_status': 'Verification status',
      'original_filename': 'Original filename',
      'captured_at': 'Captured',
      'captured_latitude': 'Capture latitude',
      'captured_longitude': 'Capture longitude',
      'imported_at': 'Imported',
      'storage_mode': 'Storage mode',
      'name': 'Name',
      'name_key': 'Normalized name',
      'latitude': 'Latitude',
      'longitude': 'Longitude',
      'radius_m': 'Radius (meters)',
      'label': 'Label',
      'operation': 'Operation',
      'timestamp': 'Recorded',
      'entity_id': 'Changed record',
      'other': 'Other field',
    });
    return '$_temp0';
  }

  @override
  String restoreMediaTotals(int count, String size) {
    return 'Attachments after restoration: $count; available attachment files: $size (shared files counted once)';
  }

  @override
  String get archiveCoordinates => 'Coordinates (latitude, longitude)';

  @override
  String get archiveRadius => 'Radius (meters)';

  @override
  String get archiveCaptured => 'Captured';

  @override
  String get archiveImported => 'Imported';

  @override
  String get archiveFilename => 'Original filename';

  @override
  String get archiveExcludedMedia =>
      'This attachment file is not included and cannot be opened from this archive';

  @override
  String get archiveDeletedReference => 'Original event deleted';

  @override
  String get archivePeople => 'People';

  @override
  String get archiveTags => 'Tags';

  @override
  String get archivePeriods => 'Life periods';

  @override
  String restoreReuseId(String sourceId, String localId) {
    return 'This name already exists. Archive ID: $sourceId; local ID: $localId. Choose which content to keep. Imported references will use the local ID.';
  }

  @override
  String get backupMediaNotice =>
      'Attachment names and records are kept, but files are omitted and cannot be opened after restoration.';

  @override
  String get backupNoMedia => 'There are no attachment files.';

  @override
  String backupScopeSummary(String scope, int count) {
    return 'Scope: $scope; $count attachment files excluded';
  }

  @override
  String get backupScopeFull => 'Full backup';

  @override
  String get backupScopeNoMedia => 'Without attachment files';

  @override
  String get backupScopeCustom => 'Custom export selection';

  @override
  String get editorGroupBasics => 'Event details';

  @override
  String get editorGroupPeople => 'People and tags';

  @override
  String get editorGroupOptions => 'Privacy and connections';

  @override
  String get editorGroupNarrative => 'Notes and attachments';

  @override
  String get storiesCreate => 'New Smart Topic';

  @override
  String get storiesEdit => 'Edit Topic';

  @override
  String get storiesTitle => 'Topic name';

  @override
  String get storiesEmpty =>
      'Combine tags to browse related entries automatically.';

  @override
  String get storiesEmptyEvents =>
      'No matching entries yet. Results update as entries and tags change.';

  @override
  String get storiesEvents => 'Matching entries';

  @override
  String get storiesAddEvents => 'Choose entries';

  @override
  String get storiesRemoveEvent => 'Remove from story';

  @override
  String get storiesSave => 'Save Topic';

  @override
  String get storiesDelete => 'Delete Topic';

  @override
  String get storiesDeleteConfirm =>
      'Delete this topic? Entries, tags, and attachments will be kept.';

  @override
  String get storiesError =>
      'Unable to save the topic. Check that its tags exist and editing is allowed.';

  @override
  String get storiesMissing => 'This topic no longer exists.';

  @override
  String get storiesReadOnly =>
      'Original topic settings are read-only while Life Archive is active.';

  @override
  String get storiesDeletedEvent => 'Entry is in Recently Deleted';

  @override
  String storiesCount(int count) {
    return '$count matching entries';
  }

  @override
  String get themesMode => 'Include condition';

  @override
  String get themesAll => 'Match all (AND)';

  @override
  String get themesAny => 'Match any (OR)';

  @override
  String get themesInclude => 'Include tags (choose at least one)';

  @override
  String get themesExclude => 'Exclude tags (optional)';

  @override
  String get themesAutoUpdate =>
      'Matches update automatically. Exclusions take priority. Private entries and Recently Deleted are excluded.';

  @override
  String get themesChooseTag => 'Choose at least one tag to include.';

  @override
  String get themesMissingTag => 'Removed tag';

  @override
  String get themesSearchTags => 'Search tags';

  @override
  String get themesNoTags =>
      'Add tags to entries before creating a smart topic.';

  @override
  String get themesLegacy =>
      'This is a legacy manual story. Saving tag conditions converts it to a smart topic and keeps the original entries.';

  @override
  String get backupSplit => 'Archive parts';

  @override
  String get backupNoSplit => 'Single ZIP (ZIP64 supported)';

  @override
  String backupPartLimit(String size) {
    return 'At most $size per part';
  }

  @override
  String get backupSplitNotice =>
      'Each part is an independent ZIP. Select all ZIPs together to restore; extract them into the same folder to read. Attachments stay whole. Increase the limit or use a single ZIP if one attachment is too large.';

  @override
  String get backupPartTooSmall =>
      'An attachment or the first part\'s text exceeds the part limit. Increase the limit, exclude oversized attachments, or use a single ZIP.';

  @override
  String backupMissingParts(String names) {
    return 'Incomplete archive. Missing:\n$names\nSelect all ZIPs from the same backup together. Existing data is unchanged.';
  }

  @override
  String backupPartCount(int count) {
    return '$count ZIP parts. Sharing includes all parts, checksum sidecars and a size/hash index.';
  }

  @override
  String get backupSplitReadme =>
      '\n## Using archive parts\n\nEach part is an independent ZIP. The first holds all text, JSON and the manifest; later parts hold media. Keep every ZIP and its .sha256 sidecar. The .parts.json index records each filename, byte size and SHA-256. Extract all parts into the same folder for offline reading, verifying each part\'s SHA256SUMS.txt separately. Select all ZIPs together, in any order, to restore or verify in the app. Missing parts prevent any database writes.\n';

  @override
  String get backupExcludePrivate => 'Exclude private entries';

  @override
  String get backupExcludePrivateNotice =>
      'Private entries, sections, reflections, title snapshots and exclusive attachments are omitted. Files shared with normal entries are kept. Unreferenced files follow the attachment switch. Device data stays intact.';

  @override
  String backupPrivateExcluded(int events, int media) {
    return 'Excluded $events private entries and $media exclusive attachment files.';
  }

  @override
  String get editorBodyLabel => 'Body';

  @override
  String get editorBodyHint =>
      'Start writing what happened, how you felt, or what you want to remember…';

  @override
  String get editorSectionHint =>
      'For example: The day we first met (optional)';

  @override
  String get editorDragSection => 'Drag to reorder sections';

  @override
  String editorDragSectionNumber(int number) {
    return 'Drag section $number to reorder';
  }

  @override
  String attachmentQuotaPreview(String used, String pending, String remaining) {
    return 'Used $used MB / 25 MB\nTo add $pending MB\nRemaining after saving $remaining MB';
  }

  @override
  String get attachmentSingleOverLimit =>
      'This file exceeds the 25 MB per-entry limit. Reduce its size before adding it.';

  @override
  String attachmentFileDescription(String type, int bytes, String mb) {
    return '$type · $bytes B ($mb MB)';
  }

  @override
  String get photoHigh => 'High · 4096 px';

  @override
  String get photoStandard => 'Standard · 3072 px';

  @override
  String get photoCompact => 'Compact · 2048 px';

  @override
  String get photoOriginal => 'Original';

  @override
  String get photoCompressed => 'Compressed';

  @override
  String get photoCompare => 'Compare original and compressed';

  @override
  String get photoCompressAll => 'Compress all photos';

  @override
  String get photoUseCompact => 'Use compact preset';

  @override
  String get photoAutomaticCompression =>
      'The original does not fit the remaining quota; the default compression preset was selected.';

  @override
  String get photoOriginalSmaller =>
      'The original is smaller; keep the original.';

  @override
  String get photoLossless => 'Lossless';

  @override
  String get photoCompressionError =>
      'This photo could not be processed. Choose the original, another photo, or cancel.';

  @override
  String photoDimensions(int width, int height) {
    return '$width × $height px';
  }

  @override
  String photoCompressionResult(
    int width,
    int height,
    String mb,
    String quality,
  ) {
    return 'Compressed: $width × $height px · $mb MB · Quality $quality';
  }

  @override
  String get appSettings => 'Settings';

  @override
  String get photoSaveSettings => 'Photo saving';

  @override
  String get photoAlwaysCompress => 'Always default to compression';

  @override
  String get photoDefaultHelp =>
      'When off, prefer originals and use the default compression preset if they do not fit. You can change each photo during import.';

  @override
  String get photoDefaultPreset => 'Default compression preset';

  @override
  String get photoRemoveGps => 'Remove location when compressing';

  @override
  String get photoGpsRemovalHelp =>
      'Remove GPS from compressed files only. Capture coordinates remain in the database for place suggestions. A larger result is kept to preserve this choice, subject to the entry quota.';

  @override
  String get photoSettingsScope =>
      'These settings affect future imports only. Existing attachments stay intact. Original mode preserves all original data, including location.';

  @override
  String get photoSettingsError =>
      'Could not load or save photo settings. Please retry.';

  @override
  String get photoSettingsRetry => 'Retry';

  @override
  String get photoGpsRemovalNotice =>
      'GPS will be removed from compressed files; original mode retains location.';

  @override
  String attachmentFileProgress(
    String name,
    int done,
    int total,
    int remaining,
  ) {
    return 'Processing: $name\nProcessed $done / $total; $remaining remaining';
  }

  @override
  String get photoPreviewUnavailable =>
      'Photo preview is unavailable. You can still save the attachment or cancel.';

  @override
  String attachmentUsage(String used, int count) {
    return '$used MB / 25 MB used · $count attachments';
  }

  @override
  String attachmentRemaining(String remaining) {
    return '$remaining MB remaining';
  }

  @override
  String attachmentPendingUsage(String size, int count) {
    return 'Pending: $size MB · $count attachments (included in remaining capacity)';
  }

  @override
  String get attachmentQuotaLow =>
      'Capacity is running low. Consider compressing photos.';

  @override
  String attachmentUsageOverLimit(String excess) {
    return '$excess MB over capacity. Reduce pending attachments; existing content is preserved.';
  }

  @override
  String get attachmentUsageUnavailable =>
      'Attachment capacity is unavailable. Reopen this page; saving still checks the limit.';

  @override
  String get backupIncludePrivate => 'Include private entries';

  @override
  String get backupPrivateScopeHint =>
      'Uses entry privacy settings, including their sections and attachments.';

  @override
  String get backupAdvanced => 'Advanced options';

  @override
  String get backupContinue => 'Next';

  @override
  String get backupStart => 'Start backup';

  @override
  String backupAttachmentTotals(int count, String size) {
    return 'Attachment files: $count · $size (shared files counted once)';
  }

  @override
  String backupContentsSummary(int events, int files) {
    return '$events entries · $files attachment files';
  }

  @override
  String get backupPrivateIncluded =>
      'Private entries and their attachments are included.';

  @override
  String get backupSizeNotice =>
      'This estimates required space. The final ZIP size is shown after completion.';

  @override
  String get attachmentSpaceReserve =>
      'Not enough device storage. At least 500 MB must remain after adding files. Compress or deselect files; existing content and originals are preserved.';

  @override
  String get storageLoading => 'Checking storage…';

  @override
  String get storageUnavailable =>
      'Storage information is temporarily unavailable.';

  @override
  String get storageApp => 'App storage used';

  @override
  String get storageFree => 'Device storage available';

  @override
  String get storageEstimate =>
      'Current estimates include the app, data and cache. They differ from the sum of entry attachment quotas.';

  @override
  String get storageRefresh => 'Refresh';

  @override
  String get storageDismiss => 'Dismiss storage warning';

  @override
  String storageLow(String free) {
    return 'Device storage remaining: $free, below 1 GB. Consider freeing space. You can still write text.';
  }
}
