package dev.aliwaris.steps;
import dev.aliwaris.helpers.*;
import io.cucumber.java.en.*;
import static org.junit.jupiter.api.Assertions.*;
public class WorkflowSteps {
 private final TestContext ctx;private final ApiClient api;
 public WorkflowSteps(TestContext ctx,ApiClient api){this.ctx=ctx;this.api=api;}
 @Given("the idempotency key is {string}") public void key(String key){ctx.key=key;}
 @When("I send {word} to {string} with body:") public void request(String method,String path,String body){api.send(method,path,body);}
 @When("I send {word} to {string}") public void request(String method,String path){api.send(method,path,"");}
 @Then("the status is {int}") public void status(int code){ctx.response.then().statusCode(code).contentType("application/json");}
 @Then("the field {string} equals {string}") public void field(String path,String value){assertEquals(ctx.expand(value),ctx.response.jsonPath().getString(path));}
 @Then("the field {string} is {int}") public void number(String path,int value){assertEquals(value,ctx.response.jsonPath().getInt(path));}
 @Then("I save {string} as {string}") public void save(String path,String name){String value=ctx.response.jsonPath().getString(path);assertNotNull(value);assertFalse(value.isBlank());ctx.values.put(name,value);}
}
