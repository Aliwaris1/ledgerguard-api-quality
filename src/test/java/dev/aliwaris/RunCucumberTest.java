package dev.aliwaris;
import org.junit.platform.suite.api.*;
@Suite @IncludeEngines("cucumber") @SelectClasspathResource("features")
@ConfigurationParameter(key="cucumber.glue",value="dev.aliwaris.steps")
@ConfigurationParameter(key="cucumber.plugin",value="pretty,html:target/cucumber.html,json:target/cucumber.json,junit:target/cucumber.xml")
public class RunCucumberTest {}
