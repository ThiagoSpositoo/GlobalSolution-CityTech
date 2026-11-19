package br.com.fiap.citytech;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class CityTechJavaApplication {

	public static void main(String[] args) {
		SpringApplication.run(CityTechJavaApplication.class, args);
	}

}
