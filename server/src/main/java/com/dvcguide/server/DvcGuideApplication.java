package com.dvcguide.server;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class DvcGuideApplication {

    public static void main(String[] args) {
        SpringApplication.run(DvcGuideApplication.class, args);
    }
}
