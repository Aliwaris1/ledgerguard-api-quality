@payments
Feature: Account balances and atomic transfer lifecycle

  @positive
  Scenario: Transfer and reversal conserve total money
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "source"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "target"
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": 10000}
      """
    Then the status is 200
    Given the idempotency key is "payment-1"
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${source}", "targetId": "${target}", "amountCents": 2500}
      """
    Then the status is 201
    And I save "id" as "transfer"
    And the field "status" equals "SETTLED"
    When I send GET to "/accounts/${source}"
    Then the status is 200
    And the field "balanceCents" is 7500
    When I send GET to "/accounts/${target}"
    Then the status is 200
    And the field "balanceCents" is 2500
    When I send GET to "/transfers/${transfer}"
    Then the status is 200
    And the field "status" equals "SETTLED"
    When I send GET to "/transfers"
    Then the status is 200
    And the field "items.size()" is 1
    When I send POST to "/transfers/${transfer}/reverse" with body:
      """
      {}
      """
    Then the status is 200
    And the field "status" equals "REVERSED"
    When I send GET to "/accounts/${source}"
    Then the status is 200
    And the field "balanceCents" is 10000
    When I send GET to "/accounts/${target}"
    Then the status is 200
    And the field "balanceCents" is 0

  @positive
  Scenario: Replayed transfers do not charge twice
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "source"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "target"
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": 10000}
      """
    Then the status is 200
    Given the idempotency key is "payment-1"
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${source}", "targetId": "${target}", "amountCents": 2500}
      """
    Then the status is 201
    And I save "id" as "transfer"
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${source}", "targetId": "${target}", "amountCents": 2500}
      """
    Then the status is 200
    And the field "id" equals "${transfer}"
    When I send GET to "/accounts/${source}"
    Then the status is 200
    And the field "balanceCents" is 7500
    When I send GET to "/transfers"
    Then the status is 200
    And the field "items.size()" is 1

  @positive
  Scenario: Accounts are listed only for the current owner
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "source"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "target"
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": 10000}
      """
    Then the status is 200
    When I send GET to "/accounts"
    Then the status is 200
    And the field "items.size()" is 2
    Given I am authenticated as "bob"
    When I send GET to "/accounts"
    Then the status is 200
    And the field "items.size()" is 0

  @negative
  Scenario: Insufficient funds leave both balances untouched
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "source"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "target"
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": 10000}
      """
    Then the status is 200
    Given the idempotency key is "large"
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${source}", "targetId": "${target}", "amountCents": 10001}
      """
    Then the status is 409
    And the field "error" equals "INSUFFICIENT_FUNDS"
    When I send GET to "/accounts/${source}"
    Then the status is 200
    And the field "balanceCents" is 10000
    When I send GET to "/accounts/${target}"
    Then the status is 200
    And the field "balanceCents" is 0

  @negative
  Scenario: Invalid transfer amount 0 is rejected
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "source"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "target"
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": 10000}
      """
    Then the status is 200
    Given the idempotency key is "invalid"
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${source}", "targetId": "${target}", "amountCents": 0}
      """
    Then the status is 422
    And the field "error" equals "INVALID_AMOUNT"
    When I send GET to "/accounts/${source}"
    Then the status is 200
    And the field "balanceCents" is 10000

  @negative
  Scenario: Invalid transfer amount -1 is rejected
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "source"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "target"
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": 10000}
      """
    Then the status is 200
    Given the idempotency key is "invalid"
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${source}", "targetId": "${target}", "amountCents": -1}
      """
    Then the status is 422
    And the field "error" equals "INVALID_AMOUNT"
    When I send GET to "/accounts/${source}"
    Then the status is 200
    And the field "balanceCents" is 10000

  @negative
  Scenario: Invalid transfer amount 1.5 is rejected
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "source"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "target"
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": 10000}
      """
    Then the status is 200
    Given the idempotency key is "invalid"
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${source}", "targetId": "${target}", "amountCents": 1.5}
      """
    Then the status is 422
    And the field "error" equals "INVALID_AMOUNT"
    When I send GET to "/accounts/${source}"
    Then the status is 200
    And the field "balanceCents" is 10000

  @negative
  Scenario: Invalid funding cannot change the balance
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "source"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "target"
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": 10000}
      """
    Then the status is 200
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": -10}
      """
    Then the status is 422
    And the field "error" equals "INVALID_AMOUNT"
    When I send GET to "/accounts/${source}"
    Then the status is 200
    And the field "balanceCents" is 10000

  @negative
  Scenario: Currency mismatch is rejected
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "source"
    When I send POST to "/accounts" with body:
      """
      {"currency": "USD"}
      """
    Then the status is 201
    And I save "id" as "target"
    Given the idempotency key is "fx"
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${source}", "targetId": "${target}", "amountCents": 2500}
      """
    Then the status is 422
    And the field "error" equals "CURRENCY_MISMATCH"

  @negative
  Scenario: Unsupported account currency is rejected
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "XYZ"}
      """
    Then the status is 422
    And the field "error" equals "INVALID_CURRENCY"

  @negative
  Scenario: A transfer cannot target its own source account
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "source"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "target"
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": 10000}
      """
    Then the status is 200
    Given the idempotency key is "same"
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${source}", "targetId": "${source}", "amountCents": 2500}
      """
    Then the status is 422
    And the field "error" equals "SAME_ACCOUNT"

  @negative
  Scenario: Foreign account access and funding are forbidden
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "source"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "target"
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": 10000}
      """
    Then the status is 200
    Given I am authenticated as "bob"
    When I send GET to "/accounts/${source}"
    Then the status is 403
    And the field "error" equals "FORBIDDEN"
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": 10}
      """
    Then the status is 403
    Given the idempotency key is "foreign"
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${source}", "targetId": "${target}", "amountCents": 2500}
      """
    Then the status is 403

  @negative
  Scenario: Foreign transfers cannot be read or reversed
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "source"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "target"
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": 10000}
      """
    Then the status is 200
    Given the idempotency key is "payment-1"
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${source}", "targetId": "${target}", "amountCents": 2500}
      """
    Then the status is 201
    And I save "id" as "transfer"
    Given I am authenticated as "bob"
    When I send GET to "/transfers"
    Then the status is 200
    And the field "items.size()" is 0
    When I send GET to "/transfers/${transfer}"
    Then the status is 403
    When I send POST to "/transfers/${transfer}/reverse" with body:
      """
      {}
      """
    Then the status is 403

  @negative
  Scenario: A reused key cannot change transfer amount
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "source"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "target"
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": 10000}
      """
    Then the status is 200
    Given the idempotency key is "payment-1"
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${source}", "targetId": "${target}", "amountCents": 2500}
      """
    Then the status is 201
    And I save "id" as "transfer"
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${source}", "targetId": "${target}", "amountCents": 500}
      """
    Then the status is 409
    And the field "error" equals "IDEMPOTENCY_CONFLICT"

  @negative
  Scenario: A reversal cannot credit money twice
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "source"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "target"
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": 10000}
      """
    Then the status is 200
    Given the idempotency key is "payment-1"
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${source}", "targetId": "${target}", "amountCents": 2500}
      """
    Then the status is 201
    And I save "id" as "transfer"
    When I send POST to "/transfers/${transfer}/reverse" with body:
      """
      {}
      """
    Then the status is 200
    When I send POST to "/transfers/${transfer}/reverse" with body:
      """
      {}
      """
    Then the status is 409
    And the field "error" equals "ALREADY_REVERSED"
    When I send GET to "/accounts/${source}"
    Then the status is 200
    And the field "balanceCents" is 10000

  @negative
  Scenario: Reversal fails when transferred funds have been spent
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "source"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "target"
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": 10000}
      """
    Then the status is 200
    Given the idempotency key is "payment-1"
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${source}", "targetId": "${target}", "amountCents": 2500}
      """
    Then the status is 201
    And I save "id" as "transfer"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "third"
    Given the idempotency key is "spend"
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${target}", "targetId": "${third}", "amountCents": 2500}
      """
    Then the status is 201
    When I send POST to "/transfers/${transfer}/reverse" with body:
      """
      {}
      """
    Then the status is 409
    And the field "error" equals "INSUFFICIENT_REVERSAL_FUNDS"
    When I send GET to "/accounts/${source}"
    Then the status is 200
    And the field "balanceCents" is 7500

  @negative
  Scenario: Transfers require an idempotency key
    Given I am authenticated as "alice"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "source"
    When I send POST to "/accounts" with body:
      """
      {"currency": "EUR"}
      """
    Then the status is 201
    And I save "id" as "target"
    When I send POST to "/accounts/${source}/fund" with body:
      """
      {"amountCents": 10000}
      """
    Then the status is 200
    When I send POST to "/transfers" with body:
      """
      {"sourceId": "${source}", "targetId": "${target}", "amountCents": 2500}
      """
    Then the status is 400
    And the field "error" equals "IDEMPOTENCY_KEY_REQUIRED"
