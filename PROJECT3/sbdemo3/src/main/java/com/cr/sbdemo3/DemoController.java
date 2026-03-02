package com.cr.sbdemo3;
import java.net.InetAddress;
import java.net.UnknownHostException;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController("/")
public class DemoController {
    @GetMapping("/jnk")
    public int getDemo(){
        return 5;
    }
    @GetMapping("/whoami")
    public String whoami() {
        return "Request served by: " + System.getenv("HOSTNAME") + 
            " | Instance: " + InetAddress.getLocalHost().getHostName();
    }
}
