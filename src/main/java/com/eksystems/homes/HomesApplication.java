package com.eksystems.homes;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
@MapperScan("com.eksystems.homes.**.mapper")
public class HomesApplication {

	public static void main(String[] args) {
		SpringApplication.run(HomesApplication.class, args);
	}

}
