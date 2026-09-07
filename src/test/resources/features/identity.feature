@identity
Feature: Authentication and tenant isolation
  @positive
  Scenario: Valid credentials create a session
    When I sign in as "alice" with password "demo-password"
    Then the status is 200
    And an access token is returned

  @negative
  Scenario Outline: Invalid credentials are rejected
    When I sign in as "<user>" with password "<password>"
    Then the status is 401
    And the field "error" equals "INVALID_CREDENTIALS"
    Examples:
      | user    | password      |
      | alice   | wrong         |
      | unknown | demo-password |

  @negative
  Scenario: Protected resources require authentication
    Given I have no access token
    When I send GET to "/accounts"
    Then the status is 401
    And the field "error" equals "UNAUTHORIZED"

  @negative
  Scenario: An unknown resource is not found
    Given I am authenticated as "alice"
    When I send GET to "/missing"
    Then the status is 404
    And the field "error" equals "NOT_FOUND"
