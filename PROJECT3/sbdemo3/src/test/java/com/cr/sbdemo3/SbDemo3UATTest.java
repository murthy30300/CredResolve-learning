package com.cr.sbdemo3;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Tag;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.beans.factory.annotation.Autowired;

import static org.junit.jupiter.api.Assertions.*;

@Tag("UAT")
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class SbDemo3UATTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    @DisplayName("UAT: Application context loads successfully")
    void applicationContextLoads() {
        // If this runs, Spring Boot started correctly
        assertTrue(true);
    }

    @Test
    @DisplayName("UAT: Health endpoint should return 200")
    void healthEndpointTest() {
        ResponseEntity<String> response = restTemplate
            .getForEntity("http://localhost:" + port + "/actuator/health", String.class);
        assertEquals(HttpStatus.OK, response.getStatusCode());
    }

    @Test
    @DisplayName("UAT: Main endpoint should be reachable")
    void mainEndpointTest() {
        ResponseEntity<String> response = restTemplate
            .getForEntity("http://localhost:" + port + "/jnk", String.class);
        // Just checking it's not a server error
        assertNotEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
    }
}
