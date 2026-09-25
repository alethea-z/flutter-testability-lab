Feature: Reading list
  Requirements are executable BDD scenarios; each scenario ID maps to test/bdd_test.dart.

  Scenario: [BOOK-ADD-01] Add a valid book
    Given an empty reading list
    When I add the book "Dune"
    Then the reading list contains "Dune"

  Scenario: [BOOK-VALID-01] Reject a blank title
    Given an empty reading list
    When I add a blank title
    Then the validation error is "Title is required"

  Scenario: [BOOK-SEARCH-01] Search without case sensitivity
    Given the reading list contains "Dune"
    When I search for "dUnE"
    Then one matching book is found

  Scenario: [IMPORT-01] Import returns controlled service error
    Given an empty reading list
    When I request an import error
    Then the import fails with "Import service returned an error"
