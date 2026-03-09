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
        try {
            return "Request served by: " + InetAddress.getLocalHost().getHostName();
        } catch (Exception e) {
            return "Request served by: unknown host";
        }
    }
}
