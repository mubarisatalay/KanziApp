package com.kanzi.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * KanziApp backend entry point.
 */
@SpringBootApplication
@EnableScheduling
@ConfigurationPropertiesScan
public class KanziApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(KanziApiApplication.class, args);
    }
}
