Feature: Reading list requirements
  Preconditions: app launched with a local store; importer is deterministic and offline-safe.
  Each requirement ID maps to an executable automated test unless explicitly marked MANUAL.

  Scenario: [BOOK-ADD-01] Add a valid title
    Given an empty reading list
    When I add the book "Dune"
    Then the reading list contains "Dune"

  Scenario: [BOOK-VALID-01] Reject a blank title
    Given an empty reading list
    When I add a blank title
    Then the validation error is "Title is required"

  Scenario: [BOOK-SEARCH-01] Search case-insensitively
    Given the reading list contains "Dune"
    When I search for "dUnE"
    Then one matching book is found

  Scenario: [IMPORT-01] Display controlled import error
    Given an empty reading list
    When I request an import error
    Then the import fails with "Import service returned an error"

  Scenario: [WID-ADD-01] Add book through visible controls
    Given the reading-list screen is visible
    When I submit a valid title
    Then the book appears in the list (automated widget test)

  Scenario: [GUI-01] Exercise the running app and capture evidence
    Given the app is launched on Android emulator
    When I enter and submit a book using stable keys
    Then the rendered list contains the book and a screenshot is captured

  Scenario: [PER-01] Restore data from local persistent storage
    Given a book has been written to Android SharedPreferences
    When the app process is restarted
    Then the same book is restored from disk (CI device test)

  Scenario: [SVC-01] Handle service outcomes
    Given a controlled importer
    When success, error, timeout and offline modes are requested
    Then each result follows its documented service contract (automated test)

  Scenario: [MANUAL-01] Check accessibility with a screen reader
    Given the app is installed on a physical device
    When a tester navigates all controls using TalkBack or VoiceOver
    Then labels and focus order are reviewed and recorded manually
