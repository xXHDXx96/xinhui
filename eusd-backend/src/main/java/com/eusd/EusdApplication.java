package com.eusd;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;
@SpringBootApplication
@EnableScheduling
@EnableAsync
@EnableCaching
public class EusdApplication {
    public static void main(String[] args) {
        SpringApplication.run(EusdApplication.class, args);
        System.out.println("=== eUSD Backend started on http://localhost:18080 ===");
    }
}
