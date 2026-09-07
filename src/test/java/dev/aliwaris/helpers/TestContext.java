package dev.aliwaris.helpers;
import java.util.*;
import java.io.*;
import java.util.concurrent.*;
import io.restassured.response.Response;
/** PicoContainer creates one context per scenario. No mutable scenario globals. */
public class TestContext {
 public String tenant=UUID.randomUUID().toString(), token="", key="";
 public Response response;
 public final Map<String,String> values=new HashMap<>();
 private static Process server;
 public static String baseUrl;
 public String expand(String text){for(var e:values.entrySet()) text=text.replace("${"+e.getKey()+"}",e.getValue());return text;}
 public static void start() throws Exception {
  baseUrl=System.getProperty("baseUrl"); if(baseUrl!=null) return;
  server=new ProcessBuilder(System.getProperty("python","python3"),"fixture/server.py","--port","0").redirectError(ProcessBuilder.Redirect.INHERIT).start();
  var future=CompletableFuture.supplyAsync(()->{try{return new BufferedReader(new InputStreamReader(server.getInputStream())).readLine();}catch(IOException e){throw new RuntimeException(e);}});
  try {String port=future.get(15,TimeUnit.SECONDS);Integer.parseInt(port);baseUrl="http://127.0.0.1:"+port;}catch(Exception e){stop();throw e;}
 }
 public static void stop(){if(server!=null){server.destroy();try{if(!server.waitFor(5,TimeUnit.SECONDS))server.destroyForcibly();}catch(InterruptedException e){Thread.currentThread().interrupt();}}}
}
