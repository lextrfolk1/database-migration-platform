package com.lextr.migrator;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DatabaseMigratorApplication {
    public static void main(String[] args) throws ClassNotFoundException {

        SpringApplication.run(DatabaseMigratorApplication.class, args);
    }
}