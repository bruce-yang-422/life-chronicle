/// 生命典藏模式的層級與操作權限（企劃書第 9 節、9.3 權限矩陣）。
///
/// 所有寫入（介面操作、匯入、批次處理）都必須經過本類別檢查，
/// 不依賴各畫面自行判斷。
library;

/// 檔案的典藏狀態。
enum ArchiveState {
  /// 一般模式。
  normal,

  /// 生命典藏模式。
  lifeArchive,
}

/// 內容所屬層級。
enum ContentLayer {
  /// 原始生命紀錄層。
  original,

  /// 後續追憶層。
  remembrance,
}

/// 操作被拒絕的原因（由介面層對應為 l10n 文字）。
enum PermissionDeniedReason {
  /// 生命典藏期間，原始生命紀錄層唯讀。
  originalIsReadOnly,

  /// 後續追憶層內容的作者不得為主角本人。
  subjectCannotAuthorRemembrance,
}

class PermissionDeniedException implements Exception {
  const PermissionDeniedException(this.reason);

  final PermissionDeniedReason reason;

  @override
  String toString() => 'PermissionDeniedException(${reason.name})';
}

abstract final class LayerPolicy {
  /// 新增內容的層級：只看加入當下的典藏狀態，與內容時間無關（企劃書 9.1）。
  static ContentLayer layerForNewContent(ArchiveState state) => switch (state) {
    ArchiveState.normal => ContentLayer.original,
    ArchiveState.lifeArchive => ContentLayer.remembrance,
  };

  /// 是否可修改或刪除某層級的既有內容（含軟刪除、復原、永久刪除）。
  ///
  /// - 原始生命紀錄層：只有一般模式可以。
  /// - 後續追憶層：兩種模式都可以，修改後仍為後續追憶層。
  static bool canModify(ContentLayer layer, ArchiveState state) =>
      switch (layer) {
        ContentLayer.original => state == ArchiveState.normal,
        ContentLayer.remembrance => true,
      };

  static void ensureCanModify(ContentLayer layer, ArchiveState state) {
    if (!canModify(layer, state)) {
      throw const PermissionDeniedException(
        PermissionDeniedReason.originalIsReadOnly,
      );
    }
  }

  /// 作者是否可為主角本人：只有原始生命紀錄層可以。
  static bool canAuthor(ContentLayer layer, {required bool authorIsSubject}) =>
      !(authorIsSubject && layer == ContentLayer.remembrance);

  static void ensureCanAuthor(
    ContentLayer layer, {
    required bool authorIsSubject,
  }) {
    if (!canAuthor(layer, authorIsSubject: authorIsSubject)) {
      throw const PermissionDeniedException(
        PermissionDeniedReason.subjectCannotAuthorRemembrance,
      );
    }
  }
}
