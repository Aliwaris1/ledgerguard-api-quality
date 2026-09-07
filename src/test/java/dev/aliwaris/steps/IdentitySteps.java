package dev.aliwaris.steps;
import dev.aliwaris.helpers.*;
import io.cucumber.java.*;
import io.cucumber.java.en.*;
public class IdentitySteps {
 private final TestContext ctx; private final ApiClient api;
 public IdentitySteps(TestContext ctx,ApiClient api){this.ctx=ctx;this.api=api;}
 @BeforeAll public static void start() throws Exception {TestContext.start();}
 @AfterAll public static void stop(){TestContext.stop();}
 @Given("I am authenticated as {string}") public void authenticated(String user){api.login(user,"demo-password");ctx.response.then().statusCode(200);ctx.token=ctx.response.jsonPath().getString("token");}
 @Given("I have no access token") public void anonymous(){ctx.token="";}
 @When("I sign in as {string} with password {string}") public void login(String user,String password){api.login(user,password);}
 @Then("an access token is returned") public void token(){org.junit.jupiter.api.Assertions.assertTrue(ctx.response.jsonPath().getString("token").length()>=32);}
}
