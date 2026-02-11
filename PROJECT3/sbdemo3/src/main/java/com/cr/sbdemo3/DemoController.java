package com.cr.sbdemo3;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController("/")
public class DemoController {
    @GetMapping("/")
    public int getDemo(){
        return 5;
    }
}
