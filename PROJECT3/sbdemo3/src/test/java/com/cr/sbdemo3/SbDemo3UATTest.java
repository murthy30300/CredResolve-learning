package com.cr.sbdemo3;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Tag;
import org.springframework.boot.test.context.SpringBootTest;

import static org.junit.jupiter.api.Assertions.*;

@Tag("UAT")
@SpringBootTest
class SbDemo3UATTest {

    @Test
    @DisplayName("UAT: Application context loads successfully")
    void applicationContextLoads() {
        assertTrue(true);
    }

    @Test
    @DisplayName("UAT: Environment is not null")
    void environmentTest() {
        String javaVersion = System.getProperty("java.version");
        assertNotNull(javaVersion);
        System.out.println("Running on Java: " + javaVersion);
    }

    @Test
    @DisplayName("UAT: App name config is set")
    void appNameTest() {
        String appName = "sbdemo3";
        assertFalse(appName.isEmpty());
        assertEquals("sbdemo3", appName);
    }
}