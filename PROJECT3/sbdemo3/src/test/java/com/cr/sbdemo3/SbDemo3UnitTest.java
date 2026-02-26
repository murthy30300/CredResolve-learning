package com.cr.sbdemo3;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import static org.junit.jupiter.api.Assertions.*;

class SbDemo3UnitTest {

    @Test
    @DisplayName("Basic sanity check - true is true")
    void basicSanityTest() {
        assertTrue(true);
    }

    @Test
    @DisplayName("String should not be null or empty")
    void stringNotNullTest() {
        String value = "hello";
        assertNotNull(value);
        assertFalse(value.isEmpty());
    }

    @Test
    @DisplayName("Math calculation check")
    void mathTest() {
        int result = 10 + 5;
        assertEquals(15, result);
    }
}
