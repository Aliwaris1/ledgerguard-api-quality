package dev.aliwaris.helpers;
import static io.restassured.RestAssured.given;
import io.restassured.http.ContentType;
/** Request configuration and JSON transport, shared by both step classes. */
public class ApiClient {
 private final TestContext ctx;
 public ApiClient(TestContext ctx){this.ctx=ctx;}
 public void send(String method,String path,String body){
  var request=given().baseUri(TestContext.baseUrl).contentType(ContentType.JSON).config(io.restassured.config.RestAssuredConfig.config().httpClient(io.restassured.config.HttpClientConfig.httpClientConfig().setParam("http.connection.timeout",5000).setParam("http.socket.timeout",5000)));
  if(!ctx.token.isEmpty())request.header("Authorization","Bearer "+ctx.token);
  if(!ctx.key.isEmpty())request.header("Idempotency-Key",ctx.key);
  if(!body.isEmpty())request.body(ctx.expand(body));
  ctx.response=request.request(method,ctx.expand(path));
 }
 public void login(String user,String password){send("POST","/auth/token", "{\"username\":\""+user+"\",\"password\":\""+password+"\",\"tenant\":\""+ctx.tenant+"\"}");}
}
